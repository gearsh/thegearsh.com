import { hashPassword, buildProfileUrl } from './auth-utils.js';

export const RIX_ELTON = {
  userId: 'user_demo_rixelton',
  artistId: 'artist_demo_rixelton',
  username: 'rixelton',
  displayName: 'Rix Elton',
  placeholderEmail: 'unclaimed+rixelton@thegearsh.com',
  location: 'Johannesburg',
  country: 'South Africa',
  category: 'Amapiano DJ',
  skills: '["Amapiano", "DJ", "Producer"]',
  bio: 'A rising Amapiano DJ and producer known for deep log drum grooves and crowd-moving sets. Available for clubs, festivals and private events.',
  image: 'assets/images/artists/rixelton.jpg',
  hourlyRate: 2000,
};

export async function ensureDemoColumns(db) {
  try {
    await db.prepare(`ALTER TABLE users ADD COLUMN claim_token TEXT`).run();
  } catch (_) {}
  try {
    await db.prepare(`ALTER TABLE users ADD COLUMN is_demo INTEGER DEFAULT 0`).run();
  } catch (_) {}
}

function isPlaceholderEmail(email) {
  return String(email || '').toLowerCase().startsWith('unclaimed+');
}

export async function seedRixElton(db) {
  await ensureDemoColumns(db);

  const existing = await db.prepare(`
    SELECT id, email, claim_token, username
    FROM users
    WHERE id = ? OR LOWER(username) = ?
    LIMIT 1
  `).bind(RIX_ELTON.userId, RIX_ELTON.username).first();

  if (existing && !isPlaceholderEmail(existing.email)) {
    return {
      seeded: false,
      reason: 'claimed',
      username: existing.username || RIX_ELTON.username,
      profile_url: buildProfileUrl(existing.username || RIX_ELTON.username),
      claim_url: null,
      claim_code: null,
    };
  }

  const now = new Date().toISOString();
  const claimToken = existing?.claim_token || `RIX-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
  const passwordHash = await hashPassword(`demo_unclaimed_${RIX_ELTON.userId}`);

  if (existing) {
    await db.prepare(`
      UPDATE users
      SET email = ?, password_hash = ?, user_type = 'artist', first_name = ?, last_name = ?,
          display_name = ?, username = ?, profile_picture_url = ?, phone = NULL, location = ?,
          country = ?, bio = ?, is_verified = 1, is_active = 1, is_demo = 1,
          claim_token = ?, updated_at = ?
      WHERE id = ?
    `).bind(
      RIX_ELTON.placeholderEmail,
      passwordHash,
      RIX_ELTON.displayName,
      '—',
      RIX_ELTON.displayName,
      RIX_ELTON.username,
      RIX_ELTON.image,
      RIX_ELTON.location,
      RIX_ELTON.country,
      RIX_ELTON.bio,
      claimToken,
      now,
      existing.id
    ).run();
  } else {
    await db.prepare(`
      INSERT INTO users (
        id, email, password_hash, user_type, first_name, last_name, display_name, username,
        profile_picture_url, location, country, bio, is_verified, is_active, is_demo,
        claim_token, created_at, updated_at
      ) VALUES (?, ?, ?, 'artist', ?, '—', ?, ?, ?, ?, ?, ?, 1, 1, 1, ?, ?, ?)
    `).bind(
      RIX_ELTON.userId,
      RIX_ELTON.placeholderEmail,
      passwordHash,
      RIX_ELTON.displayName,
      RIX_ELTON.displayName,
      RIX_ELTON.username,
      RIX_ELTON.image,
      RIX_ELTON.location,
      RIX_ELTON.country,
      RIX_ELTON.bio,
      claimToken,
      now,
      now
    ).run();
  }

  const profileExists = await db.prepare(`
    SELECT id FROM artist_profiles WHERE id = ? OR user_id = ?
  `).bind(RIX_ELTON.artistId, RIX_ELTON.userId).first();

  if (profileExists) {
    await db.prepare(`
      UPDATE artist_profiles
      SET category = ?, skills = ?, base_rate = ?, hourly_rate = ?,
          availability_status = 'available', is_trending = 1, updated_at = ?
      WHERE id = ?
    `).bind(
      RIX_ELTON.category,
      RIX_ELTON.skills,
      RIX_ELTON.hourlyRate,
      RIX_ELTON.hourlyRate,
      now,
      profileExists.id
    ).run();
  } else {
    await db.prepare(`
      INSERT INTO artist_profiles (
        id, user_id, category, skills, base_rate, hourly_rate,
        availability_status, is_trending, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, 'available', 1, ?, ?)
    `).bind(
      RIX_ELTON.artistId,
      RIX_ELTON.userId,
      RIX_ELTON.category,
      RIX_ELTON.skills,
      RIX_ELTON.hourlyRate,
      RIX_ELTON.hourlyRate,
      now,
      now
    ).run();
  }

  const artistId = profileExists?.id || RIX_ELTON.artistId;
  await db.prepare(`DELETE FROM services WHERE artist_id = ?`).bind(artistId).run();

  const services = [
    {
      name: 'DJ set (1 hour)',
      description: 'High-energy Amapiano DJ set — R2,000 per hour.',
      price: RIX_ELTON.hourlyRate,
      hours: 1,
    },
    {
      name: 'Club set (2 hours)',
      description: 'Two-hour club or lounge set tailored to your crowd.',
      price: RIX_ELTON.hourlyRate * 2,
      hours: 2,
    },
    {
      name: 'Private event (4 hours)',
      description: 'Full private event performance with custom playlist.',
      price: RIX_ELTON.hourlyRate * 4,
      hours: 4,
    },
  ];

  for (const service of services) {
    const serviceId = `svc_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
    await db.prepare(`
      INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `).bind(serviceId, artistId, service.name, service.description, service.price, service.hours, now).run();
  }

  return {
    seeded: true,
    reason: existing ? 'updated' : 'created',
    username: RIX_ELTON.username,
    profile_url: buildProfileUrl(RIX_ELTON.username),
    claim_url: `/claim-profile.html?artist=${RIX_ELTON.username}`,
    claim_code: claimToken,
    hourly_rate: RIX_ELTON.hourlyRate,
  };
}
