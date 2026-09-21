const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { auditMemberships, migrateHousehold } = require('../../scripts/migrate-invites.cjs');
let env, app, db;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-tanago', firestore: { host: '127.0.0.1', port: 8080 } });
  app = initializeApp({ projectId: 'demo-tanago' }, 'migration-tests');
  db = getFirestore(app);
});
after(async () => { await db.terminate(); await deleteApp(app); await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
async function seed() {
  const ref = db.doc('households/legacy');
  await ref.set({ name: '家', createdByUid: 'owner', inviteCode: 'TANA-1234', createdAt: Timestamp.now() });
  await ref.collection('members').doc('owner').set({ displayName: 'A', role: 'owner', joinedAt: Timestamp.now() });
  await db.doc('users/owner').set({ householdId: 'legacy' });
  return ref;
}
test('migration audits, dry-runs, rotates atomically and is idempotent', async () => {
  const ref = await seed();
  assert.equal((await auditMemberships(db)).length, 1);
  assert.equal(await migrateHousehold(db, ref, false), 'would-migrate');
  assert.equal((await ref.get()).data().inviteCode, 'TANA-1234');
  assert.equal(await migrateHousehold(db, ref, true), 'migrated');
  const code = (await ref.get()).data().inviteCode;
  assert.match(code, /^TANA-[0-9A-F]{32}$/);
  assert.equal((await db.doc('householdInvites/' + code).get()).data().householdId, 'legacy');
  assert.equal(await migrateHousehold(db, ref, true), 'unchanged');
  assert.equal((await ref.collection('members').doc('owner').get()).data().role, 'owner');
});
test('migration refuses inconsistent legacy memberships', async () => {
  await seed();
  await db.doc('users/owner').update({ householdId: 'different' });
  await assert.rejects(auditMemberships(db), /membership inconsistencies/);
});
