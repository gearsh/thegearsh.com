import { jsonResponse, corsPreflightResponse } from '../../auth-utils.js';
import { requireFounder } from '../../founder-auth.js';

export async function onRequestPatch(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const artistId = context.params.id;
    const body = await context.request.json();
    const action = String(body.action || '').trim().toLowerCase();
    const now = new Date().toISOString();

    const profile = await context.env.DB.prepare(`
      SELECT ap.id AS artist_id, u.id AS user_id, u.display_name, u.is_verified, u.is_active
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.id = ? OR u.id = ?
    `).bind(artistId, artistId).first();

    if (!profile) {
      return jsonResponse({ success: false, error: 'Artist not found' }, 404);
    }

    if (action === 'approve') {
      await context.env.DB.prepare(`
        UPDATE users SET is_verified = 1, is_active = 1, updated_at = ? WHERE id = ?
      `).bind(now, profile.user_id).run();
    } else if (action === 'remove') {
      await context.env.DB.prepare(`
        UPDATE users SET is_active = 0, updated_at = ? WHERE id = ?
      `).bind(now, profile.user_id).run();
      await context.env.DB.prepare(`
        UPDATE services SET is_active = 0 WHERE artist_id = ?
      `).bind(profile.artist_id).run();
    } else if (action === 'restore') {
      await context.env.DB.prepare(`
        UPDATE users SET is_active = 1, updated_at = ? WHERE id = ?
      `).bind(now, profile.user_id).run();
    } else if (action === 'unverify') {
      await context.env.DB.prepare(`
        UPDATE users SET is_verified = 0, updated_at = ? WHERE id = ?
      `).bind(now, profile.user_id).run();
    } else {
      return jsonResponse({
        success: false,
        error: 'Invalid action. Use approve, remove, restore, or unverify.',
      }, 400);
    }

    const updated = await context.env.DB.prepare(`
      SELECT u.id, u.display_name, u.is_verified, u.is_active
      FROM users u WHERE u.id = ?
    `).bind(profile.user_id).first();

    return jsonResponse({
      success: true,
      message: 'Artist listing updated',
      data: {
        artist_id: profile.artist_id,
        name: updated.display_name,
        is_verified: Boolean(updated.is_verified),
        is_active: Boolean(updated.is_active),
        action,
      },
    });
  } catch (err) {
    console.error('Founder artist update error:', err);
    return jsonResponse({ success: false, error: 'Failed to update artist' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
