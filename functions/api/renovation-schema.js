// Runtime schema for renovation features: Content Engine + Reliability Index

export async function ensureRenovationTables(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS content_live (
      id TEXT PRIMARY KEY DEFAULT 'live',
      copy_json TEXT NOT NULL DEFAULT '{}',
      theme_json TEXT NOT NULL DEFAULT '{}',
      version INTEGER NOT NULL DEFAULT 1,
      published_at TEXT,
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS content_draft (
      id TEXT PRIMARY KEY DEFAULT 'draft',
      copy_json TEXT NOT NULL DEFAULT '{}',
      theme_json TEXT NOT NULL DEFAULT '{}',
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS content_publish_log (
      id TEXT PRIMARY KEY,
      from_version INTEGER,
      to_version INTEGER NOT NULL,
      action TEXT NOT NULL CHECK(action IN ('publish', 'rollback')),
      created_by TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS reliability_indices (
      user_id TEXT PRIMARY KEY REFERENCES users(id),
      user_role TEXT NOT NULL DEFAULT 'artist',
      total_bookings INTEGER DEFAULT 0,
      completed_bookings INTEGER DEFAULT 0,
      cancelled_bookings INTEGER DEFAULT 0,
      disputed_bookings INTEGER DEFAULT 0,
      rescheduled_bookings INTEGER DEFAULT 0,
      on_time_arrivals INTEGER DEFAULT 0,
      late_arrivals INTEGER DEFAULT 0,
      no_shows INTEGER DEFAULT 0,
      completion_rate REAL DEFAULT 0,
      cancellation_rate REAL DEFAULT 0,
      dispute_rate REAL DEFAULT 0,
      last_updated TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS reliability_events (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      event_type TEXT NOT NULL,
      booking_id TEXT,
      metadata TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_reliability_events_user ON reliability_events(user_id);
  `).run();

  try {
    await db.prepare(`ALTER TABLE users ADD COLUMN active_perspective TEXT DEFAULT 'client'`).run();
  } catch (_) {}
}
