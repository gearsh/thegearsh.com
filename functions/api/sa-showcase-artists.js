import { hashPassword, buildProfileUrl } from './auth-utils.js';
import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';
import { ensureDemoColumns } from './demo-artists.js';

function isPlaceholderEmail(email) {
  return String(email || '').toLowerCase().startsWith('unclaimed+');
}

function slugToId(prefix, username) {
  return `${prefix}_${String(username || '').replace(/[^a-z0-9]+/gi, '_')}`;
}

function claimTokenFor(username) {
  const code = String(username || 'artist')
    .replace(/[^a-z0-9]+/gi, '')
    .slice(0, 4)
    .toUpperCase();
  return `CLM-${code}-${crypto.randomUUID().slice(0, 6).toUpperCase()}`;
}

export async function seedShowcaseArtist(db, artist) {
  await ensureDemoColumns(db);

  const userId = slugToId('user_demo', artist.username);
  const artistId = slugToId('artist_demo', artist.username);
  const placeholderEmail = `unclaimed+${artist.username}@thegearsh.com`;
  const skillsJson = JSON.stringify(artist.skills || [artist.category]);

  const existing = await db.prepare(`
    SELECT id, email, claim_token, username
    FROM users
    WHERE LOWER(username) = LOWER(?) OR id = ?
    LIMIT 1
  `).bind(artist.username, userId).first();

  if (existing && !isPlaceholderEmail(existing.email)) {
    return {
      seeded: false,
      reason: 'claimed',
      username: existing.username || artist.username,
    };
  }

  const now = new Date().toISOString();
  const claimToken = existing?.claim_token || claimTokenFor(artist.username);
  const passwordHash = await hashPassword(`demo_unclaimed_${userId}`);
  const resolvedUserId = existing?.id || userId;

  if (existing) {
    await db.prepare(`
      UPDATE users
      SET email = ?, password_hash = ?, user_type = 'artist', first_name = ?, last_name = ?,
          display_name = ?, username = ?, profile_picture_url = ?, phone = NULL, location = ?,
          country = ?, bio = ?, is_verified = 1, is_active = 1, is_demo = 1,
          claim_token = ?, updated_at = ?
      WHERE id = ?
    `).bind(
      placeholderEmail,
      passwordHash,
      artist.name,
      '—',
      artist.name,
      artist.username,
      artist.image,
      artist.location,
      artist.country || 'South Africa',
      artist.bio,
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
      userId,
      placeholderEmail,
      passwordHash,
      artist.name,
      artist.name,
      artist.username,
      artist.image,
      artist.location,
      artist.country || 'South Africa',
      artist.bio,
      claimToken,
      now,
      now
    ).run();
  }

  const profileExists = await db.prepare(`
    SELECT id FROM artist_profiles WHERE id = ? OR user_id = ?
  `).bind(artistId, resolvedUserId).first();

  const hourlyRate = Number(artist.hourlyRate || 5000);
  const isTrending = Number(artist.masteryHours || 0) >= 5000 ? 1 : 0;

  if (profileExists) {
    await db.prepare(`
      UPDATE artist_profiles
      SET category = ?, genre = ?, skills = ?, base_rate = ?, hourly_rate = ?,
          availability_status = 'available', is_trending = ?, updated_at = ?
      WHERE id = ?
    `).bind(
      artist.category,
      artist.genre,
      skillsJson,
      hourlyRate,
      hourlyRate,
      isTrending,
      now,
      profileExists.id
    ).run();
  } else {
    await db.prepare(`
      INSERT INTO artist_profiles (
        id, user_id, category, genre, skills, base_rate, hourly_rate,
        availability_status, is_trending, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'available', ?, ?, ?)
    `).bind(
      artistId,
      resolvedUserId,
      artist.category,
      artist.genre,
      skillsJson,
      hourlyRate,
      hourlyRate,
      isTrending,
      now,
      now
    ).run();
  }

  return {
    seeded: true,
    username: artist.username,
    profile_url: buildProfileUrl(artist.username),
    claim_url: `/claim-profile.html?artist=${artist.username}`,
    claim_code: claimToken,
  };
}

export async function seedShowcaseArtists(db) {
  const results = { created: 0, updated: 0, claimed: 0, failed: 0 };

  for (const artist of SA_SHOWCASE_ARTISTS) {
    try {
      const result = await seedShowcaseArtist(db, artist);
      if (result.reason === 'claimed') results.claimed += 1;
      else if (result.seeded) results.created += 1;
    } catch (err) {
      console.error(`Showcase seed failed for ${artist.username}:`, err);
      results.failed += 1;
    }
  }

  return results;
}

export { SA_SHOWCASE_ARTISTS };
