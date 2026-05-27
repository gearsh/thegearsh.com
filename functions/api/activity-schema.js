// Runtime D1 schema for Artist Activity Feed

export async function ensureActivityTables(db) {
  if (!db) return;

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS artist_follows (
      id TEXT PRIMARY KEY,
      follower_user_id TEXT NOT NULL,
      artist_id TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(follower_user_id, artist_id)
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS artist_activities (
      id TEXT PRIMARY KEY,
      artist_id TEXT NOT NULL,
      author_user_id TEXT NOT NULL,
      activity_type TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      location TEXT,
      venue TEXT,
      event_date TEXT,
      media_urls TEXT DEFAULT '[]',
      metadata_json TEXT DEFAULT '{}',
      is_public INTEGER DEFAULT 1,
      like_count INTEGER DEFAULT 0,
      comment_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS activity_likes (
      id TEXT PRIMARY KEY,
      activity_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(activity_id, user_id)
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS activity_comments (
      id TEXT PRIMARY KEY,
      activity_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      body TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_artist_follows_artist ON artist_follows(artist_id)
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_artist_follows_follower ON artist_follows(follower_user_id)
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_artist_activities_artist ON artist_activities(artist_id, created_at DESC)
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_activity_likes_activity ON activity_likes(activity_id)
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_activity_comments_activity ON activity_comments(activity_id, created_at DESC)
  `).run();
}
