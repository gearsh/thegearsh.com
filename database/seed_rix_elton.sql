-- Demo artist: Rix Elton (R2,000/hour, claimable profile)
-- Prefer the live founder seed API or homepage feed auto-seed instead of running this manually.

INSERT OR IGNORE INTO users (
  id, email, password_hash, user_type, first_name, last_name, display_name, username,
  profile_picture_url, location, country, bio, is_verified, is_active, is_demo, claim_token, created_at, updated_at
) VALUES (
  'user_demo_rixelton',
  'unclaimed+rixelton@thegearsh.com',
  'PLACEHOLDER_HASH',
  'artist',
  'Rix Elton',
  '—',
  'Rix Elton',
  'rixelton',
  'assets/images/artists/rixelton.jpg',
  'Johannesburg',
  'South Africa',
  'A rising Amapiano DJ and producer known for deep log drum grooves and crowd-moving sets.',
  1,
  1,
  1,
  'RIX-SET-CLAIM-CODE',
  datetime('now'),
  datetime('now')
);

INSERT OR IGNORE INTO artist_profiles (
  id, user_id, category, skills, base_rate, hourly_rate, availability_status, is_trending, created_at, updated_at
) VALUES (
  'artist_demo_rixelton',
  'user_demo_rixelton',
  'Amapiano DJ',
  '["Amapiano", "DJ", "Producer"]',
  2000,
  2000,
  'available',
  1,
  datetime('now'),
  datetime('now')
);
