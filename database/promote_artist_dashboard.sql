-- Restore artist dashboard access when login sends you to the homepage.
-- Run in Cloudflare D1 → gearsh_db → Console.
-- Replace the email below with your account email.

-- 1) Ensure the account is marked as an artist
UPDATE users
SET user_type = 'artist', is_active = 1, updated_at = datetime('now')
WHERE LOWER(email) = LOWER('nhlanhla@thegearsh.com');

-- 2) Create an artist profile if missing (required for mastery hours dashboard)
INSERT INTO artist_profiles (
  id, user_id, category, skills, availability_status, created_at, updated_at
)
SELECT
  'artist_' || substr(hex(randomblob(8)), 1, 16),
  u.id,
  'Performer',
  '[]',
  'available',
  datetime('now'),
  datetime('now')
FROM users u
WHERE LOWER(u.email) = LOWER('nhlanhla@thegearsh.com')
  AND NOT EXISTS (
    SELECT 1 FROM artist_profiles ap WHERE ap.user_id = u.id
  );
