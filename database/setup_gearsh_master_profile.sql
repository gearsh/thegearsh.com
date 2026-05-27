-- Seed @gearsh Master Profile for The Gearsh founder
-- Run in Cloudflare D1 → gearsh_db → Console (after add_master_profile.sql)

UPDATE users
SET
  username = 'gearsh',
  display_name = 'The Gearsh',
  first_name = 'The',
  last_name = 'Gearsh',
  bio = 'Founder and lead builder at Gearsh. I ship websites, mobile apps, AI automations, and full platforms.',
  is_verified = 1,
  user_type = 'admin',
  updated_at = datetime('now')
WHERE LOWER(email) = LOWER('nhlanhla@thegearsh.com');

UPDATE artist_profiles
SET
  profile_type = 'master',
  category = 'Tech & Product',
  tagline = 'Building Africa''s next tech empires from the home office',
  cover_image_url = '/icons/og-image.png',
  long_bio = 'The Gearsh is the founder and lead tech builder behind Gearsh — the platform connecting South African artists, fans, and bookers.',
  stats_json = '{"projects_completed":52,"clients_served":38,"hours_coded":12400,"response_time":"< 24 hrs","satisfaction":"98%"}',
  availability_status = 'available',
  is_trending = 1,
  total_bookings = 52,
  avg_rating = 5,
  total_reviews = 4,
  updated_at = datetime('now')
WHERE user_id = (
  SELECT id FROM users WHERE LOWER(username) = 'gearsh' OR LOWER(email) = LOWER('nhlanhla@thegearsh.com')
);
