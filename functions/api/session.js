// GET /api/session — validate bearer token and return current user
import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  ensureAuthTables,
  getArtistProfileSummary,
  resolvePostLoginPath,
} from './auth-utils.js';
import { ensureOnboardingTables } from './onboarding-utils.js';

export async function onRequestGet(context) {
  try {
    await ensureAuthTables(context.env.DB);
    await ensureOnboardingTables(context.env.DB);
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    const user = await context.env.DB.prepare(`
      SELECT id, email, user_type, display_name, first_name, username, is_verified, onboarding_status
      FROM users
      WHERE id = ? AND (is_active = 1 OR user_type = 'admin')
    `).bind(userId).first();

    if (!user) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    const artistProfile = await getArtistProfileSummary(context.env.DB, user.id);
    const hasArtistDashboard = Boolean(artistProfile);

    return jsonResponse({
      success: true,
      data: {
        user_id: user.id,
        email: user.email,
        user_type: user.user_type,
        display_name: user.display_name,
        username: user.username,
        is_verified: Boolean(user.is_verified),
        onboarding_status: user.onboarding_status || null,
        has_artist_dashboard: hasArtistDashboard,
        redirect_path: resolvePostLoginPath(user, hasArtistDashboard),
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
