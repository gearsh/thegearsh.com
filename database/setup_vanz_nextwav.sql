-- Vanz / NEXTWAV REC — recording studio services (matches studio rate card).
-- Prefer seeding via Gearsh Command: POST /api/founder/seed-demo-artist { "artist": "vanz" }
-- Or run after adding vanz to sa-showcase-data.js and deploying.

-- Verify after seed:
-- SELECT u.username, s.name, s.price FROM services s
-- JOIN artist_profiles ap ON ap.id = s.artist_id
-- JOIN users u ON u.id = ap.user_id
-- WHERE LOWER(u.username) = 'vanz' ORDER BY s.price;
