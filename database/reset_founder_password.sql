-- Manual founder password reset for thegearsh@gmail.com
-- Run in Cloudflare D1 → gearsh_db → Console if the reset API is unavailable.
-- Temporary password after running this SQL: Gearsh@Founder2025

UPDATE users
SET
  password_hash = 'dSccmjr5I0B3OPP6CTDh+6Q0ayyunkBXm/FrjyFTu8Y=',
  user_type = 'admin',
  is_active = 1,
  updated_at = datetime('now')
WHERE LOWER(email) = LOWER('thegearsh@gmail.com');

-- If zero rows updated, create a founder account first via join-gig.html,
-- then run this SQL again.
