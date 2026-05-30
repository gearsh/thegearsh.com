// GET /api/session — validate bearer token and return current user
import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  ensureAuthTables,
  getArtistProfileSummary,
  resolveUserRoles,
  resolveActivePerspective,
} from './auth-utils.js';
import { ensureOnboardingTables } from './onboarding-utils.js';
import { ensureRenovationTables } from './renovation-schema.js';

export async function onRequestGet(context) {
  try {
    await ensureAuthTables(context.env.DB);
    await ensureOnboardingTables(context.env.DB);
    await ensureRenovationTables(context.env.DB);
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    const user = await context.env.DB.prepare(`
      SELECT id, email, user_type, display_name, first_name, username, is_verified, onboarding_status, active_perspective
      FROM users
      WHERE id = ? AND (is_active = 1 OR user_type = 'admin')
    `).bind(userId).first();

    if (!user) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    const artistProfile = await getArtistProfileSummary(context.env.DB, user.id);
    const hasArtistDashboard = Boolean(artistProfile);
    const roles = await resolveUserRoles(context.env.DB, user);
    const activePerspective = resolveActivePerspective(user, roles, hasArtistDashboard);

    return jsonResponse({
      success: true,
      data: {
        user_id: user.id,
        email: user.email,
        user_type: user.user_type,
        roles,
        active_perspective: activePerspective,
        display_name: user.display_name,
        username: user.username,
        is_verified: Boolean(user.is_verified),
        onboarding_status: user.onboarding_status || null,
        has_artist_dashboard: hasArtistDashboard,
      },
    });
  } catch (err) {
    console.error('Session error:', err);
    return jsonResponse({ success: false, error: 'Session check failed' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
