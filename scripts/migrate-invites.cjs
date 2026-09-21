// Admin-only migration. Defaults to an audit/dry run; never logs invite tokens.
const { randomBytes } = require('node:crypto');
const { initializeApp, applicationDefault, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

async function auditMemberships(db) {
  const [users, households, members] = await Promise.all([
    db.collection('users').get(), db.collection('households').get(), db.collectionGroup('members').get(),
  ]);
  const userHomes = new Map(users.docs.map(d => [d.id, d.data().householdId]));
  const homes = new Map(households.docs.map(d => [d.id, d.data()]));
  const membership = new Map();
  const problems = [];
  for (const member of members.docs) {
    const parts = member.ref.path.split('/');
    if (parts.length !== 4 || parts[0] !== 'households') continue;
    const [, hid, , uid] = parts;
    membership.set(`${hid}/${uid}`, member.data());
    if (!homes.has(hid) || userHomes.get(uid) !== hid) problems.push(`membership mismatch: ${member.ref.path}`);
    if (!['owner', 'member'].includes(member.data().role)) problems.push(`invalid role: ${member.ref.path}`);
    if (member.data().role === 'owner' && homes.get(hid)?.createdByUid !== uid) problems.push(`unexpected owner: ${member.ref.path}`);
  }
  for (const [uid, hid] of userHomes) {
    if (hid != null && (!homes.has(hid) || !membership.has(`${hid}/${uid}`))) problems.push(`missing household/member: users/${uid}`);
  }
  for (const [hid, home] of homes) {
    if (membership.get(`${hid}/${home.createdByUid}`)?.role !== 'owner') problems.push(`missing owner: households/${hid}`);
  }
  if (problems.length) throw new Error(`Resolve membership inconsistencies before migrating:\n${problems.join('\n')}`);
  return households.docs.map(d => d.ref);
}

async function migrateHousehold(db, reference, apply) {
  return db.runTransaction(async tx => {
    const household = await tx.get(reference);
    const oldCode = household.data().inviteCode;
    const oldRef = typeof oldCode === 'string' && !oldCode.includes('/') && oldCode.length
      ? db.collection('householdInvites').doc(oldCode) : null;
    const oldInvite = oldRef ? await tx.get(oldRef) : null;
    if (/^TANA-[0-9A-F]{32}$/.test(oldCode) && oldInvite?.data()?.householdId === reference.id) return 'unchanged';
    if (!apply) return 'would-migrate';
    const newCode = 'TANA-' + randomBytes(16).toString('hex').toUpperCase();
    // create() fails on collision rather than replacing another household's code.
    tx.create(db.collection('householdInvites').doc(newCode), { householdId: reference.id });
    tx.update(reference, { inviteCode: newCode });
    if (oldInvite?.data()?.householdId === reference.id) tx.delete(oldRef);
    return 'migrated';
  });
}

async function main() {
  const args = process.argv.slice(2);
  const projectIndex = args.indexOf('--project');
  const project = projectIndex >= 0 ? args[projectIndex + 1] : null;
  if (!project || project.startsWith('--')) throw new Error('Usage: node scripts/migrate-invites.cjs --project PROJECT_ID [--apply]');
  const apply = args.includes('--apply');
  const app = initializeApp({ projectId: project, ...(process.env.FIRESTORE_EMULATOR_HOST ? {} : { credential: applicationDefault() }) });
  try {
    const db = getFirestore(app);
    const households = await auditMemberships(db);
    const counts = {};
    for (const reference of households) {
      const status = await migrateHousehold(db, reference, apply);
      counts[status] = (counts[status] || 0) + 1;
    }
    console.log(JSON.stringify({ project, apply, households: households.length, counts }));
  } finally { await deleteApp(app); }
}
if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
module.exports = { auditMemberships, migrateHousehold };
