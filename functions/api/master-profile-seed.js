// Seed @gearsh master profile into D1
import { hashPassword } from './auth-utils.js';
import { ensureMasterProfileColumns } from './master-profile-schema.js';
import { GEARSH_DEFAULT, GEARSH_USERNAME, buildAvailabilitySlots } from './master-profile-data.js';

function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

/** Ensure @gearsh username is linked to the founder account for public sign-in */
export async function ensureGearshLoginReady(db, env) {
  await ensureMasterProfileColumns(db);

  const founderRaw = env?.FOUNDER_EMAIL || env?.ADMIN_EMAIL || 'nhlanhla@thegearsh.com';
  const founderEmail = String(founderRaw).split(',')[0].trim().toLowerCase();
  const now = new Date().toISOString();

  let user = await db.prepare(`
    SELECT id, username, email, password_hash FROM users
    WHERE LOWER(username) = ? OR LOWER(email) = ?
    ORDER BY CASE WHEN LOWER(username) = ? THEN 0 ELSE 1 END
    LIMIT 1
  `).bind(GEARSH_USERNAME, founderEmail, GEARSH_USERNAME).first();

  if (!user) {
    await seedGearshMasterProfile(db, founderEmail);
    user = await db.prepare(`
      SELECT id, username, email, password_hash FROM users
      WHERE LOWER(username) = ? OR LOWER(email) = ?
      LIMIT 1
    `).bind(GEARSH_USERNAME, founderEmail).first();
  }

  if (user && user.username?.toLowerCase() !== GEARSH_USERNAME) {
    await db.prepare(`
      UPDATE users SET username = ?, display_name = COALESCE(display_name, ?),
        is_verified = 1, is_active = 1, updated_at = ?
      WHERE id = ?
    `).bind(GEARSH_USERNAME, GEARSH_DEFAULT.name, now, user.id).run();
  }

  const bootstrapPassword = env?.GEARSH_LOGIN_PASSWORD;
  if (bootstrapPassword && user) {
    const passwordHash = await hashPassword(String(bootstrapPassword));
    await db.prepare(`
      UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?
    `).bind(passwordHash, now, user.id).run();
  }

  await seedGearshMasterProfile(db, founderEmail);
  return user;
}

export async function seedGearshMasterProfile(db, founderEmail) {
  await ensureMasterProfileColumns(db);

  const email = (founderEmail || 'nhlanhla@thegearsh.com').toLowerCase();
  let user = await db.prepare(`
    SELECT id, username FROM users WHERE LOWER(username) = ? OR LOWER(email) = ?
  `).bind(GEARSH_USERNAME, email).first();

  const now = new Date().toISOString();

  if (!user) {
    const userId = newId('user');
    const passwordHash = await hashPassword('gearsh_seed_' + Date.now());
    await db.prepare(`
      INSERT INTO users (
        id, email, password_hash, user_type, first_name, last_name, display_name,
        username, bio, location, country, profile_picture_url, is_verified, is_active,
        created_at, updated_at
      ) VALUES (?, ?, ?, 'admin', 'The', 'Gearsh', ?, ?, ?, ?, ?, ?, 1, 1, ?, ?)
    `).bind(
      userId,
      email,
      passwordHash,
      GEARSH_DEFAULT.name,
      GEARSH_USERNAME,
      GEARSH_DEFAULT.bio,
      GEARSH_DEFAULT.location,
      GEARSH_DEFAULT.country,
      GEARSH_DEFAULT.image,
      now,
      now
    ).run();
    user = { id: userId, username: GEARSH_USERNAME };
  } else if (!user.username || user.username.toLowerCase() !== GEARSH_USERNAME) {
    await db.prepare(`
      UPDATE users SET username = ?, display_name = ?, is_verified = 1, user_type = 'admin', updated_at = ?
      WHERE id = ?
    `).bind(GEARSH_USERNAME, GEARSH_DEFAULT.name, now, user.id).run();
    user.username = GEARSH_USERNAME;
  }

  let profile = await db.prepare(`
    SELECT id FROM artist_profiles WHERE user_id = ?
  `).bind(user.id).first();

  if (!profile) {
    const artistId = newId('artist');
    await db.prepare(`
      INSERT INTO artist_profiles (
        id, user_id, category, skills, base_rate, hourly_rate, availability_status,
        profile_type, tagline, cover_image_url, long_bio, stats_json, testimonials_json,
        portfolio_projects_json, availability_json, is_trending, total_bookings,
        avg_rating, total_reviews, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, 'available', 'master', ?, ?, ?, ?, ?, ?, ?, 1, 52, 5, 4, ?, ?)
    `).bind(
      artistId,
      user.id,
      GEARSH_DEFAULT.category,
      JSON.stringify(GEARSH_DEFAULT.skills),
      2500,
      2500,
      GEARSH_DEFAULT.tagline,
      GEARSH_DEFAULT.cover_image_url,
      GEARSH_DEFAULT.long_bio,
      JSON.stringify(GEARSH_DEFAULT.stats),
      JSON.stringify(GEARSH_DEFAULT.testimonials),
      JSON.stringify(GEARSH_DEFAULT.portfolio_projects),
      JSON.stringify({ slots: buildAvailabilitySlots() }),
      now,
      now
    ).run();
    profile = { id: artistId };
  } else {
    await db.prepare(`
      UPDATE artist_profiles SET
        profile_type = 'master',
        tagline = ?,
        cover_image_url = ?,
        long_bio = ?,
        stats_json = ?,
        testimonials_json = ?,
        portfolio_projects_json = ?,
        availability_json = ?,
        category = ?,
        updated_at = ?
      WHERE id = ?
    `).bind(
      GEARSH_DEFAULT.tagline,
      GEARSH_DEFAULT.cover_image_url,
      GEARSH_DEFAULT.long_bio,
      JSON.stringify(GEARSH_DEFAULT.stats),
      JSON.stringify(GEARSH_DEFAULT.testimonials),
      JSON.stringify(GEARSH_DEFAULT.portfolio_projects),
      JSON.stringify({ slots: buildAvailabilitySlots() }),
      GEARSH_DEFAULT.category,
      now,
      profile.id
    ).run();
  }

  for (let i = 0; i < GEARSH_DEFAULT.services.length; i += 1) {
    const svc = GEARSH_DEFAULT.services[i];
    const existing = await db.prepare(`
      SELECT id FROM services WHERE artist_id = ? AND name = ?
    `).bind(profile.id, svc.name).first();

    if (!existing) {
      await db.prepare(`
        INSERT INTO services (
          id, artist_id, name, description, price, duration_hours, delivery_days,
          deliverables, is_featured, sort_order, is_active, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
      `).bind(
        svc.id || newId('svc'),
        profile.id,
        svc.name,
        svc.description,
        svc.price,
        svc.duration_hours || null,
        svc.delivery_days || null,
        JSON.stringify(svc.deliverables || []),
        svc.is_featured ? 1 : 0,
        i,
        now
      ).run();
    }
  }

  return { user_id: user.id, artist_id: profile.id, username: GEARSH_USERNAME };
}
