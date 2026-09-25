const { readFileSync } = require('node:fs');
const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp, query, orderBy, runTransaction } = require('firebase/firestore');
let env;
const code = 'TANA-' + 'A'.repeat(32);
const otherCode = 'TANA-' + 'B'.repeat(32);
const db = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const member = (role = 'member') => ({ displayName: 'Family', role, joinedAt: serverTimestamp() });
const store = { name: 'スーパー', mapWidth: 12, mapHeight: 16 };
const item = (uid = 'owner') => ({ name: '牛乳', addedByUid: uid, createdAt: Timestamp.now(), categoryId: 'dairy', isPurchased: false, purchasedByUid: null, purchasedAt: null });
const shelf = { type: 'shelf', x: 0, y: 0, width: 3, height: 1, label: null, categoryIds: ['dairy'] };
async function create(uid = 'owner', hid = 'home', invite = code) {
  const client = db(uid);
  const batch = writeBatch(client);
  batch.set(doc(client, 'households', hid), { name: '家', createdByUid: uid, inviteCode: invite, createdAt: serverTimestamp() });
  batch.set(doc(client, 'households', hid, 'members', uid), member('owner'));
  batch.set(doc(client, 'householdInvites', invite), { householdId: hid });
  batch.set(doc(client, 'users', uid), { householdId: hid });
  return batch.commit();
}
function join(uid = 'guest', hid = 'home', invite = code, role = 'member') {
  const client = db(uid);
  const batch = writeBatch(client);
  batch.set(doc(client, 'households', hid, 'members', uid), { ...member(role), inviteCode: invite });
  batch.set(doc(client, 'users', uid), { householdId: hid });
  return batch.commit();
}
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-tanago', firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 } });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

test('atomic create and invitation join work; read only after membership', async () => {
  await assertSucceeds(create());
  const guest = db('guest');
  await assertSucceeds(getDoc(doc(guest, 'householdInvites', code)));
  await assertFails(getDoc(doc(guest, 'households/home')));
  await assertSucceeds(join());
  await assertSucceeds(getDoc(doc(guest, 'households/home')));
  await assertSucceeds(getDocs(collection(guest, 'households/home/members')));
  assert.equal((await getDoc(doc(db('owner'), 'households/home/members/owner'))).data().role, 'owner');
});

test('deny anonymous clients, other users, household search and invite enumeration', async () => {
  await create();
  for (const uid of [null, 'outsider']) {
    const client = db(uid);
    for (const path of ['users/owner', 'households/home', 'households/home/members/owner', 'households/home/shoppingLists/active/items/i', 'households/home/stores/s', 'households/home/stores/s/mapObjects/o']) {
      await assertFails(getDoc(doc(client, path)));
      await assertFails(setDoc(doc(client, path), {}));
      await assertFails(deleteDoc(doc(client, path)));
    }
    await assertFails(getDocs(collection(client, 'households')));
    await assertFails(getDocs(collection(client, 'householdInvites')));
  }
  await assertFails(getDoc(doc(db(), 'householdInvites', code)));
  await assertSucceeds(getDoc(doc(db('outsider'), 'users/outsider')));
  await assertFails(getDoc(doc(db('outsider'), 'householdInvites/TANA-1234')));
});

test('deny membership forgery, missing atomic writes and ownership escalation', async () => {
  await create();
  await assertFails(join('guest', 'home', otherCode));
  await assertFails(join('guest', 'home', code, 'owner'));
  await assertFails(setDoc(doc(db('guest'), 'households/home/members/guest'), { ...member(), inviteCode: code }));
  await assertFails(setDoc(doc(db('guest'), 'users/guest'), { householdId: 'home' }));
  await assertSucceeds(join());
  await assertFails(updateDoc(doc(db('guest'), 'households/home/members/guest'), { role: 'owner' }));
  await assertFails(updateDoc(doc(db('guest'), 'households/home'), { name: 'hijacked' }));
  await assertSucceeds(updateDoc(doc(db('owner'), 'households/home'), { name: '新しい家' }));
  await assertFails(join('owner'));
  await assertFails(deleteDoc(doc(db('owner'), 'users/owner')));
});

test('cannot overwrite invite or switch households; only one simultaneous create succeeds', async () => {
  await create();
  await assertSucceeds(create('other', 'other', otherCode));
  await assertFails(join('owner', 'other', otherCode));
  await assertFails(create('owner', 'extra', 'TANA-' + 'C'.repeat(32)));
  await assertFails(setDoc(doc(db('other'), 'householdInvites', code), { householdId: 'other' }));
  const results = await Promise.allSettled([create('racer', 'race1', 'TANA-' + 'D'.repeat(32)), create('racer', 'race2', 'TANA-' + 'E'.repeat(32))]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
});

test('shared shopping items preserve authorship and validate purchase metadata', async () => {
  await create(); await join();
  const owner = db('owner'), guest = db('guest');
  const path = 'households/home/shoppingLists/active/items/i';
  await assertSucceeds(setDoc(doc(owner, path), item()));
  await assertSucceeds(getDocs(query(collection(guest, 'households/home/shoppingLists/active/items'), orderBy('createdAt'))));
  await assertFails(updateDoc(doc(guest, path), { addedByUid: 'guest' }));
  await assertFails(updateDoc(doc(guest, path), { isPurchased: true, purchasedByUid: 'owner', purchasedAt: Timestamp.now() }));
  await assertSucceeds(updateDoc(doc(guest, path), { isPurchased: true, purchasedByUid: 'guest', purchasedAt: Timestamp.now() }));
  await assertSucceeds(updateDoc(doc(owner, path), { categoryId: 'beverages' }));
  await assertFails(updateDoc(doc(owner, path), { isPurchased: false }));
  await assertSucceeds(updateDoc(doc(owner, path), { isPurchased: false, purchasedByUid: null, purchasedAt: null }));
  await assertFails(setDoc(doc(guest, path + '2'), item('owner')));
  await assertFails(setDoc(doc(owner, 'households/home/shoppingLists/private/items/i'), item()));
  await assertSucceeds(deleteDoc(doc(guest, path)));
});

test('map validation and deletion guard prevent orphan writes; 400 deletes fit access limits', async () => {
  await create(); await join();
  const client = db('owner'), guest = db('guest');
  const path = 'households/home/stores/s';
  await assertSucceeds(setDoc(doc(client, path), store));
  await assertSucceeds(getDocs(query(collection(guest, 'households/home/stores'), orderBy('name'))));
  await assertSucceeds(setDoc(doc(guest, path + '/mapObjects/o'), shelf));
  await assertFails(setDoc(doc(guest, path + '/mapObjects/bad'), { ...shelf, x: 12 }));
  await assertFails(setDoc(doc(guest, path + '/mapObjects/bad'), { ...shelf, categoryIds: ['invalid'] }));
  await assertFails(setDoc(doc(guest, 'households/home/stores/missing/mapObjects/o'), shelf));
  const seed = writeBatch(client);
  for (let i = 0; i < 400; i++) seed.set(doc(client, path + '/mapObjects/' + i), shelf);
  await assertSucceeds(seed.commit());
  await assertFails(deleteDoc(doc(client, path)));
  await assertSucceeds(updateDoc(doc(client, path), { deleting: true }));
  await assertFails(updateDoc(doc(client, path), { deleting: false }));
  await assertFails(setDoc(doc(guest, path + '/mapObjects/new'), shelf));
  const batch = writeBatch(client);
  for (let i = 0; i < 400; i++) batch.delete(doc(client, path + '/mapObjects/' + i));
  await assertSucceeds(batch.commit());
  await assertSucceeds(deleteDoc(doc(client, path + '/mapObjects/o')));
  await assertSucceeds(deleteDoc(doc(client, path)));
  await assertFails(setDoc(doc(guest, path + '/mapObjects/new'), shelf));
});

test('transaction edits preserve concurrent changes and do not resurrect deleted items', async () => {
  await create(); await join();
  const owner = db('owner'), guest = db('guest');
  const path = 'households/home/shoppingLists/active/items/i';
  await setDoc(doc(owner, path), item());
  const edit = (client, transform) => runTransaction(client, async tx => {
    const ref = doc(client, path), snapshot = await tx.get(ref);
    if (snapshot.exists()) tx.update(ref, transform(snapshot.data()));
  });
  await Promise.all([
    edit(owner, current => ({ ...current, categoryId: 'beverages' })),
    edit(guest, current => ({ ...current, isPurchased: true, purchasedByUid: 'guest', purchasedAt: Timestamp.now() })),
  ]);
  const result = (await getDoc(doc(owner, path))).data();
  assert.equal(result.categoryId, 'beverages'); assert.equal(result.purchasedByUid, 'guest');
  await deleteDoc(doc(owner, path));
  await edit(owner, current => ({ ...current, categoryId: 'dairy' }));
  assert.equal((await getDoc(doc(owner, path))).exists(), false);
});

test('standalone household/invite/member writes and foreign membership writes are rejected', async () => {
  const client = db('owner');
  await assertFails(setDoc(doc(client, 'households/home'), { name: '家', createdByUid: 'owner', inviteCode: code, createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(client, 'householdInvites', code), { householdId: 'home' }));
  await assertFails(setDoc(doc(client, 'households/home/members/owner'), member('owner')));
  await create();
  const batch = writeBatch(client);
  batch.set(doc(client, 'households/home/members/victim'), { ...member(), inviteCode: code });
  batch.set(doc(client, 'users/victim'), { householdId: 'home' });
  await assertFails(batch.commit());
  await assertFails(updateDoc(doc(client, 'households/home'), { inviteCode: otherCode }));
  await assertFails(deleteDoc(doc(client, 'households/home/members/owner')));
  await assertFails(deleteDoc(doc(client, 'householdInvites', code)));
});

test('a member of another household cannot access this household', async () => {
  await create(); await create('other', 'other', otherCode);
  const client = db('other');
  await assertFails(getDocs(collection(client, 'households/home/members')));
  await assertFails(getDocs(collection(client, 'households/home/shoppingLists/active/items')));
  await assertFails(getDocs(collection(client, 'households/home/stores')));
  await assertFails(getDocs(collection(client, 'households/home/stores/s/mapObjects')));
  await assertFails(setDoc(doc(client, 'households/home/shoppingLists/active/items/i'), item('other')));
  await assertFails(setDoc(doc(client, 'households/home/stores/s'), store));
  await assertFails(setDoc(doc(client, 'households/home/stores/s/mapObjects/o'), shelf));
});

test('members can expand maps to 100 by 100 without shrinking or reviving deleted stores', async () => {
  await create(); await join();
  const path = 'households/home/stores/s';
  const owner = doc(db('owner'), path), guest = doc(db('guest'), path);
  await assertSucceeds(setDoc(owner, store));
  await assertSucceeds(setDoc(doc(db('owner'), path + '/mapObjects/o'), shelf));
  await assertFails(updateDoc(doc(db('outsider'), path), { mapWidth: 100, mapHeight: 100 }));
  await assertFails(updateDoc(guest, { mapWidth: 11 }));
  await assertFails(updateDoc(guest, { mapWidth: 101 }));
  await assertFails(updateDoc(guest, { mapHeight: 32.5 }));
  await assertFails(updateDoc(guest, { name: 'other', mapWidth: 24 }));
  await assertSucceeds(updateDoc(guest, { mapWidth: 100, mapHeight: 100 }));
  await assertSucceeds(updateDoc(doc(db('guest'), path + '/mapObjects/o'), { x: 97, y: 99 }));
  await assertFails(updateDoc(doc(db('guest'), path + '/mapObjects/o'), { x: 98 }));
  await assertFails(updateDoc(guest, { mapHeight: 99 }));
  await assertSucceeds(updateDoc(owner, { deleting: true }));
  await assertFails(updateDoc(guest, { mapWidth: 100, mapHeight: 100, deleting: false }));
});

test('custom categories are household scoped and valid on items and shelves', async () => {
  await create(); await join();
  const client = db('owner'), guest = db('guest');
  const id = 'custom_12345678-1234-4123-8123-123456789012';
  const second = 'custom_12345678-1234-4123-8123-123456789013';
  const path = 'households/home/categoryCatalog/active';
  await assertFails(setDoc(doc(db('outsider'), path), { names: { [id]: '健康食品' }, lastEditedId: id }));
  await assertSucceeds(setDoc(doc(client, path), { names: { [id]: '健康食品' }, lastEditedId: id }));
  await assertSucceeds(getDoc(doc(guest, path)));
  await assertFails(getDoc(doc(db('outsider'), path)));
  // Two names cannot be changed together, and existing categories cannot vanish.
  await assertFails(updateDoc(doc(guest, path), { names: { [id]: '変更', [second]: 'ペット' }, lastEditedId: second }));
  await assertSucceeds(updateDoc(doc(guest, path), { names: { [id]: '健康食品', [second]: 'ペット' }, lastEditedId: second }));
  await assertFails(updateDoc(doc(guest, path), { names: { [second]: 'ペット' }, lastEditedId: second }));
  await assertFails(updateDoc(doc(guest, path), { names: { [id]: '', [second]: 'ペット' }, lastEditedId: id }));
  await assertSucceeds(setDoc(doc(client, 'households/home/shoppingLists/active/items/custom'), { ...item(), categoryId: id }));
  await assertFails(setDoc(doc(client, 'households/home/shoppingLists/active/items/invalid'), { ...item(), categoryId: 'unknown' }));
  await assertSucceeds(setDoc(doc(client, 'households/home/stores/s'), store));
  await assertSucceeds(setDoc(doc(guest, 'households/home/stores/s/mapObjects/custom'), { ...shelf, categoryIds: [id, second, 'dairy'] }));
  await assertFails(setDoc(doc(guest, 'households/home/stores/s/mapObjects/invalid'), { ...shelf, categoryIds: [id, 'unknown'] }));
  await assertFails(deleteDoc(doc(client, path)));
  await assertSucceeds(create('other', 'other', otherCode));
  await assertFails(setDoc(doc(db('other'), 'households/other/shoppingLists/active/items/cross'), { ...item('other'), categoryId: id }));
});

test('members can rename only themselves without changing roles or membership', async () => {
  await create(); await join();
  await assertSucceeds(updateDoc(doc(db('guest'), 'households/home/members/guest'), { displayName: 'あき' }));
  await assertFails(updateDoc(doc(db('guest'), 'households/home/members/owner'), { displayName: '偽名' }));
  await assertFails(updateDoc(doc(db('owner'), 'households/home/members/guest'), { displayName: '上書き' }));
  await assertFails(updateDoc(doc(db('guest'), 'households/home/members/guest'), { displayName: 'あき', role: 'owner' }));
  await assertFails(updateDoc(doc(db('guest'), 'households/home/members/guest'), { displayName: '' }));
  await assertSucceeds(setDoc(doc(db('owner'), 'households/home/shoppingLists/active/items/i'), item()));
  await assertSucceeds(deleteDoc(doc(db('guest'), 'households/home/shoppingLists/active/items/i')));
});
