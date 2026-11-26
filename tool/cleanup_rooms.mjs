import { initializeApp, cert, deleteApp } from 'firebase-admin/app';
import { getDatabase } from 'firebase-admin/database';

const HOUR = 60 * 60 * 1000;
const staleMs = Number(process.env.STALE_HOURS || 24) * HOUR;
const maxAgeMs = 7 * 24 * HOUR;
const dryRun = process.env.DRY_RUN === 'true';

function lastActivity(room) {
  const times = [room.createdAt, room.startAt, room.firstFinishAt];
  for (const p of Object.values(room.players ?? {})) {
    times.push(p.joinedAt, p.lastSeen, p.finishedAt, p.gaveUpAt, p.outAt, p.board?.at);
  }
  return Math.max(0, ...times.filter(Number.isFinite));
}

function isStale(room, now) {
  const idle = now - lastActivity(room);
  const anyOnline = Object.values(room.players ?? {}).some((p) => p.online === true);
  // A player can stay `online` if the server never fired onDisconnect, so very old rooms go regardless.
  return idle > maxAgeMs || (!anyOnline && idle > staleMs);
}

async function main() {
  const app = initializeApp({
    credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
    databaseURL: process.env.FIREBASE_DATABASE_URL,
  });
  const db = getDatabase(app);

  const snapshot = await db.ref('rooms').get();
  const now = Date.now();
  const stale = [];
  snapshot.forEach((child) => {
    if (isStale(child.val(), now)) stale.push(child.key);
  });
  console.log(`Rooms: ${snapshot.numChildren()}, stale: ${stale.length}${dryRun ? ' (dry run)' : ''}`);

  let deleted = 0;
  for (const code of stale) {
    if (dryRun) {
      console.log(`Would delete ${code}`);
      continue;
    }
    // Re-checked inside the transaction: the code may have been taken by a new room since the read.
    const result = await db
      .ref(`rooms/${code}`)
      .transaction((room) => (room === null || isStale(room, Date.now()) ? null : undefined));
    if (result.committed && !result.snapshot.exists()) {
      deleted++;
      console.log(`Deleted ${code}`);
    } else {
      console.log(`Kept ${code}: active again`);
    }
  }
  if (!dryRun) console.log(`Deleted: ${deleted}`);

  await deleteApp(app);
}

await main();
