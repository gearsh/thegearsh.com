-- Artist Activity Feed: follows, posts, engagement
-- Run against gearsh_db or rely on runtime ensureActivityTables() in API.

CREATE TABLE IF NOT EXISTS artist_follows (
  id TEXT PRIMARY KEY,
  follower_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  artist_id TEXT NOT NULL REFERENCES artist_profiles(id) ON DELETE CASCADE,
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(follower_user_id, artist_id)
);

CREATE TABLE IF NOT EXISTS artist_activities (
  id TEXT PRIMARY KEY,
  artist_id TEXT NOT NULL REFERENCES artist_profiles(id) ON DELETE CASCADE,
  author_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL CHECK(activity_type IN (
    'gig', 'collaboration', 'photoshoot', 'studio', 'travel', 'press', 'milestone', 'custom'
  )),
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
);

CREATE TABLE IF NOT EXISTS activity_likes (
  id TEXT PRIMARY KEY,
  activity_id TEXT NOT NULL REFERENCES artist_activities(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(activity_id, user_id)
);

CREATE TABLE IF NOT EXISTS activity_comments (
  id TEXT PRIMARY KEY,
  activity_id TEXT NOT NULL REFERENCES artist_activities(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_artist_follows_artist ON artist_follows(artist_id);
CREATE INDEX IF NOT EXISTS idx_artist_follows_follower ON artist_follows(follower_user_id);
CREATE INDEX IF NOT EXISTS idx_artist_activities_artist ON artist_activities(artist_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_artist_activities_public ON artist_activities(is_public, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_likes_activity ON activity_likes(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_comments_activity ON activity_comments(activity_id, created_at DESC);
