-- Enable public sign-in as @gearsh on /auth.html
-- Run in Cloudflare D1 → gearsh_db → Console
--
-- Sign in with:
--   Username: @gearsh  (or gearsh)
--   Password: Gearsh@Founder2025
--
-- Change this password immediately after first login.

UPDATE users
SET
  username = 'gearsh',
  display_name = 'The Gearsh',
  password_hash = 'dSccmjr5I0B3OPP6CTDh+6Q0ayyunkBXm/FrjyFTu8Y=',
  user_type = 'admin',
  is_verified = 1,
  is_active = 1,
  updated_at = datetime('now')
WHERE LOWER(email) = LOWER('nhlanhla@thegearsh.com')
   OR LOWER(email) = LOWER('thegearsh@gmail.com')
   OR LOWER(username) = 'gearsh';

-- Optional: set Cloudflare env GEARSH_LOGIN_PASSWORD instead of running this SQL.
