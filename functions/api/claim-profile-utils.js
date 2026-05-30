export async function ensureRemovalRequestsTable(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS profile_removal_requests (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      username TEXT NOT NULL,
      display_name TEXT,
      requester_email TEXT NOT NULL,
      reason TEXT,
      status TEXT DEFAULT 'pending',
      created_at TEXT NOT NULL,
      reviewed_at TEXT,
      notes TEXT
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS removed_listings (
      username TEXT PRIMARY KEY,
      removed_at TEXT NOT NULL,
      reason TEXT
    )
  `).run();
}

export function newRemovalRequestId() {
  return `rm_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
}

export async function getRemovedUsernames(db) {
  const rows = await db.prepare(`
    SELECT LOWER(username) AS username FROM removed_listings
  `).all();
  return new Set((rows.results || []).map(function (row) { return row.username; }));
}

export async function isUsernameRemoved(db, username) {
  const row = await db.prepare(`
    SELECT username FROM removed_listings WHERE LOWER(username) = LOWER(?)
  `).bind(username).first();
  return Boolean(row);
}

export async function getPendingRemovalRequest(db, userId) {
  return db.prepare(`
    SELECT id, status, created_at
    FROM profile_removal_requests
    WHERE user_id = ? AND status = 'pending'
    ORDER BY created_at DESC
    LIMIT 1
  `).bind(userId).first();
}
