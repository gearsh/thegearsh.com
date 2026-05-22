-- Promote a user to Gearsh founder/admin (run once in D1 for your account)
-- Replace the email below with your founder login email, then also set
-- FOUNDER_EMAIL and FOUNDER_ACCESS_KEY in Cloudflare Pages environment variables.

-- UPDATE users SET user_type = 'admin' WHERE LOWER(email) = LOWER('you@yourdomain.com');
