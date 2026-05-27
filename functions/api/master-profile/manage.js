// PATCH /api/master-profile/manage — update master profile (owner/admin only)

import { jsonResponse, corsPreflightResponse, requireAuth } from '../auth-utils.js';
import { ensureMasterProfileColumns, isMasterProfile } from '../master-profile-schema.js';
import { GEARSH_USERNAME } from '../master-profile-data.js';

export async function onRequestPatch(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    await ensureMasterProfileColumns(context.env.DB);

    const profile = await context.env.DB.prepare(`
      SELECT ap.id AS artist_id, ap.profile_type, u.username, u.id AS user_id
      FROM artist_profiles ap
      JOIN users u ON u.id = ap.user_id
      WHERE ap.user_id = ?
    `).bind(auth.userId).first();

    const isGearsh = profile && profile.username?.toLowerCase() === GEARSH_USERNAME;
    const isAdmin = auth.user.user_type === 'admin';
    const isMaster = profile && isMasterProfile(profile);

    if (!profile || (!isMaster && !isGearsh && !isAdmin)) {
      return jsonResponse({ success: false, error: 'Master profile access required' }, 403);
    }

    const body = await context.request.json();
    const now = new Date().toISOString();

    if (body.user && typeof body.user === 'object') {
      const u = body.user;
      await context.env.DB.prepare(`
        UPDATE users SET
          display_name = COALESCE(?, display_name),
          bio = COALESCE(?, bio),
          profile_picture_url = COALESCE(?, profile_picture_url),
          location = COALESCE(?, location),
          updated_at = ?
        WHERE id = ?
      `).bind(
        u.name || u.display_name || null,
        u.bio || null,
        u.image || u.profile_picture_url || null,
        u.location || null,
        now,
        auth.userId
      ).run();
    }

    if (body.profile && typeof body.profile === 'object') {
      const p = body.profile;
      await context.env.DB.prepare(`
        UPDATE artist_profiles SET
          tagline = COALESCE(?, tagline),
          cover_image_url = COALESCE(?, cover_image_url),
          long_bio = COALESCE(?, long_bio),
          stats_json = COALESCE(?, stats_json),
          testimonials_json = COALESCE(?, testimonials_json),
          portfolio_projects_json = COALESCE(?, portfolio_projects_json),
          availability_json = COALESCE(?, availability_json),
          profile_type = 'master',
          updated_at = ?
        WHERE id = ?
      `).bind(
        p.tagline || null,
        p.cover_image_url || null,
        p.long_bio || null,
        p.stats ? JSON.stringify(p.stats) : null,
        p.testimonials ? JSON.stringify(p.testimonials) : null,
        p.portfolio_projects ? JSON.stringify(p.portfolio_projects) : null,
        p.availability ? JSON.stringify(p.availability) : null,
        now,
        profile.artist_id
      ).run();
    }

    return jsonResponse({ success: true, message: 'Profile updated' });
  } catch (err) {
    console.error('Master profile PATCH error:', err);
    return jsonResponse({ success: false, error: 'Failed to update profile' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
