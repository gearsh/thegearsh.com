// POST /api/update-profile - update profile data for the authenticated user

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from './auth-utils.js';

const ALLOWED_USER_TYPES = new Set(['fan', 'client', 'artist']);

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(
      context.request.headers.get('Authorization'),
      context.env,
    );

    if (!userId) {
      return unauthorizedResponse('Authentication required');
    }

    const body = await context.request.json();
    const {
      user_type,
      contact_number,
      country,
      location,
      skill_set,
      date_of_birth,
      gender,
    } = body || {};

    if (user_type && !ALLOWED_USER_TYPES.has(user_type)) {
      return jsonResponse({ success: false, error: 'Invalid user_type' }, 400);
    }

    const existingUser = await context.env.DB.prepare(
      `SELECT id FROM users WHERE id = ? AND is_active = 1`,
    ).bind(userId).first();

    if (!existingUser) {
      return jsonResponse({ success: false, error: 'User not found' }, 404);
    }

    await context.env.DB.prepare(`
      UPDATE users SET
        user_type = COALESCE(?, user_type),
        phone = COALESCE(?, phone),
        country = COALESCE(?, country),
        location = COALESCE(?, location),
        skill_set = COALESCE(?, skill_set),
        date_of_birth = COALESCE(?, date_of_birth),
        gender = COALESCE(?, gender),
        updated_at = datetime('now')
      WHERE id = ?
    `).bind(
      user_type || null,
      contact_number || null,
      country || null,
      location || null,
      skill_set || null,
      date_of_birth || null,
      gender || null,
      userId,
    ).run();

    return jsonResponse({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Update profile error:', error);
    return jsonResponse({ success: false, error: 'Failed to update profile' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
