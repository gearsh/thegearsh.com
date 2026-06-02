// Demo gigs for Gig Guide when no events exist yet
import { newId, ensureUniqueEventSlug } from '../tickets-utils.js';
import { ensureTicketsTables } from '../tickets-schema.js';
import { hashPassword } from '../auth-utils.js';

// Resolve an artist to anchor the demo gigs to. Prefer the Gearsh house account,
// then any existing artist, and finally create a Gearsh host artist so the guide
// is never empty on a fresh database.
async function resolveSeedArtist(db) {
  const gearsh = await db.prepare(`
    SELECT ap.id AS artist_id, u.id AS user_id
    FROM artist_profiles ap JOIN users u ON u.id = ap.user_id
    WHERE LOWER(u.username) = 'gearsh' OR LOWER(u.email) LIKE '%thegearsh%'
    LIMIT 1
  `).first();
  if (gearsh) return gearsh;

  const any = await db.prepare(`
    SELECT ap.id AS artist_id, u.id AS user_id
    FROM artist_profiles ap JOIN users u ON u.id = ap.user_id
    LIMIT 1
  `).first();
  if (any) return any;

  return createHostArtist(db);
}

// Create a stable Gearsh host user + artist profile to own demo gigs.
async function createHostArtist(db) {
  const userId = 'user_gearsh_gigs_host';
  const artistId = 'artist_gearsh_gigs_host';
  const email = 'gigs-host@thegearsh.com';
  const now = new Date().toISOString();

  try {
    const passwordHash = await hashPassword('host_' + Date.now() + Math.random());
    await db.prepare(`
      INSERT OR IGNORE INTO users (
        id, email, password_hash, user_type, first_name, last_name,
        display_name, username, is_verified, is_active, created_at, updated_at
      ) VALUES (?, ?, ?, 'artist', 'Gearsh', 'Live', 'Gearsh', 'gearsh', 1, 1, ?, ?)
    `).bind(userId, email, passwordHash, now, now).run();
  } catch (_) { /* user may already exist */ }

  // Resolve the actual user id (our id, or a pre-existing row with that email).
  let user = await db.prepare(`SELECT id FROM users WHERE id = ?`).bind(userId).first();
  if (!user) user = await db.prepare(`SELECT id FROM users WHERE email = ?`).bind(email).first();
  if (!user) return null;

  try {
    await db.prepare(`
      INSERT OR IGNORE INTO artist_profiles (id, user_id, category, genre, availability_status, created_at, updated_at)
      VALUES (?, ?, 'Live Performance', 'Multi-genre', 'available', ?, ?)
    `).bind(artistId, user.id, now, now).run();
  } catch (_) { /* profile may already exist */ }

  const profile = await db.prepare(
    `SELECT id AS artist_id, user_id FROM artist_profiles WHERE user_id = ? LIMIT 1`
  ).bind(user.id).first();
  return profile || null;
}

const DEMO_GIGS = [
  { title: 'Amapiano Sundays', city: 'Johannesburg', venue: 'Zone 6 Venue', category: 'music', days: 7, price: 250, featured: 1 },
  { title: 'Cape Town Jazz Night', city: 'Cape Town', venue: 'Green Point Stadium Lawn', category: 'music', days: 14, price: 350, featured: 1 },
  { title: 'Durban Beach Fest', city: 'Durban', venue: 'Suncoast', category: 'festival', days: 21, price: 180, featured: 1 },
  { title: 'Gearsh Tech Build Day', city: 'Online', venue: 'Virtual', category: 'tech', days: 10, price: 0, featured: 0, artist: 'gearsh' },
  { title: 'Gqom Nation Live', city: 'Pretoria', venue: 'Sun Arena', category: 'music', days: 28, price: 299, featured: 0 },
  { title: 'Heritage Cultural Expo', city: 'Bloemfontein', venue: 'Loch Logan', category: 'cultural', days: 35, price: 120, featured: 0 },
  { title: 'VIP House Session', city: 'Sandton', venue: 'Taboo Nightclub', category: 'music', days: 5, price: 450, vip: 1200, featured: 0 },
  { title: 'Limpopo Xigaza Showcase', city: 'Polokwane', venue: 'Meropa Casino', category: 'cultural', days: 12, price: 150, featured: 0 },
];

export async function seedGuideGigsIfEmpty(db) {
  await ensureTicketsTables(db);
  const count = await db.prepare(`
    SELECT COUNT(*) AS c FROM gig_events WHERE status IN ('published', 'sold_out')
  `).first();
  if (Number(count?.c || 0) > 0) return false;

  const artist = await resolveSeedArtist(db);
  if (!artist) return false;

  const now = Date.now();
  for (const gig of DEMO_GIGS) {
    const slug = await ensureUniqueEventSlug(db, gig.title);
    const starts = new Date(now + gig.days * 86400000);
    starts.setHours(20, 0, 0, 0);
    const eventId = newId('evt');
    const iso = starts.toISOString();

    await db.prepare(`
      INSERT INTO gig_events (
        id, artist_id, author_user_id, slug, title, description, venue, city, country,
        starts_at, flyer_url, category, is_featured, currency, status, visibility,
        sales_start_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'South Africa', ?, ?, ?, ?, 'ZAR', 'published', 'public', datetime('now'), datetime('now'), datetime('now'))
    `).bind(
      eventId,
      artist.artist_id,
      artist.user_id,
      slug,
      gig.title,
      'Live on Gearsh. Get your tickets now.',
      gig.venue,
      gig.city,
      iso,
      '/icons/og-image.png',
      gig.category,
      gig.featured ? 1 : 0
    ).run();

    await db.prepare(`
      INSERT INTO gig_ticket_types (id, event_id, name, tier_kind, price, quantity_total, sort_order, is_active)
      VALUES (?, ?, 'General Admission', 'general', ?, 500, 0, 1)
    `).bind(newId('tktp'), eventId, gig.price).run();

    if (gig.vip) {
      await db.prepare(`
        INSERT INTO gig_ticket_types (id, event_id, name, tier_kind, price, quantity_total, sort_order, is_active)
        VALUES (?, ?, 'VIP', 'vip', ?, 80, 1, 1)
      `).bind(newId('tktp'), eventId, gig.vip).run();
    }
  }
  return true;
}
