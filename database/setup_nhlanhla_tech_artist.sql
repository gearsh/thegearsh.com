-- Set up Nhlanhla as a Tech artist on Gearsh (apps, websites, bots).
-- Run in Cloudflare D1 → gearsh_db → Console.

UPDATE users
SET
  user_type = 'artist',
  display_name = 'Nhlanhla',
  first_name = 'Nhlanhla',
  username = 'nhlanhla',
  bio = 'Tech artist — I build apps, websites, bots, and automations for businesses and creators.',
  is_active = 1,
  updated_at = datetime('now')
WHERE LOWER(email) = LOWER('nhlanhla@thegearsh.com');

UPDATE artist_profiles
SET
  category = 'Tech artist',
  skills = '["Tech artist"]',
  base_rate = 3500,
  hourly_rate = 3500,
  availability_status = 'available',
  updated_at = datetime('now')
WHERE user_id = (
  SELECT id FROM users WHERE LOWER(email) = LOWER('nhlanhla@thegearsh.com')
);

INSERT INTO artist_profiles (
  id, user_id, category, skills, base_rate, hourly_rate, availability_status, created_at, updated_at
)
SELECT
  'artist_' || substr(hex(randomblob(8)), 1, 16),
  u.id,
  'Tech artist',
  '["Tech artist"]',
  3500,
  3500,
  'available',
  datetime('now'),
  datetime('now')
FROM users u
WHERE LOWER(u.email) = LOWER('nhlanhla@thegearsh.com')
  AND NOT EXISTS (
    SELECT 1 FROM artist_profiles ap WHERE ap.user_id = u.id
  );

INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
SELECT
  'svc_nhlanhla_web_' || substr(hex(randomblob(4)), 1, 8),
  ap.id,
  'Website design & build',
  'Custom website for your brand or business — design, build, and launch with Nhlanhla.',
  3500,
  8,
  1,
  datetime('now')
FROM artist_profiles ap
JOIN users u ON u.id = ap.user_id
WHERE LOWER(u.email) = LOWER('nhlanhla@thegearsh.com')
  AND NOT EXISTS (
    SELECT 1 FROM services s
    WHERE s.artist_id = ap.id AND s.name = 'Website design & build'
  );

INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
SELECT
  'svc_nhlanhla_app_' || substr(hex(randomblob(4)), 1, 8),
  ap.id,
  'Mobile & web app',
  'End-to-end app development — mobile, web, or both.',
  8750,
  24,
  1,
  datetime('now')
FROM artist_profiles ap
JOIN users u ON u.id = ap.user_id
WHERE LOWER(u.email) = LOWER('nhlanhla@thegearsh.com')
  AND NOT EXISTS (
    SELECT 1 FROM services s
    WHERE s.artist_id = ap.id AND s.name = 'Mobile & web app'
  );

INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
SELECT
  'svc_nhlanhla_bot_' || substr(hex(randomblob(4)), 1, 8),
  ap.id,
  'Bots & automation',
  'Chatbots, workflow automation, and custom integrations.',
  5250,
  12,
  1,
  datetime('now')
FROM artist_profiles ap
JOIN users u ON u.id = ap.user_id
WHERE LOWER(u.email) = LOWER('nhlanhla@thegearsh.com')
  AND NOT EXISTS (
    SELECT 1 FROM services s
    WHERE s.artist_id = ap.id AND s.name = 'Bots & automation'
  );
