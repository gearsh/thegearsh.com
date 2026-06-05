// GET  /api/session — validate bearer token and return current user
// POST /api/session — refresh token (extends stay signed in)
import {
  parseToken,
  parseTokenForRefresh,
  generateToken,
  jsonResponse,
  corsPreflightResponse,
  ensureAuthTables,
  getArtistProfileSummary,
  resolveUserRoles,
  resolveActivePerspective,
} from './auth-utils.js';
import { ensureOnboardingTables } from './onboarding-utils.js';
import { ensureRenovationTables } from './renovation-schema.js';

async function loadSessionUser(db, userId) {
  const user = await db.prepare(`
    SELECT id, email, user_type, display_name, first_name, username, is_verified, onboarding_status, active_perspective
    FROM users
    WHERE id = ? AND (is_active = 1 OR user_type = 'admin')
  `).bind(userId).first();

  if (!user) return null;

  const artistProfile = await getArtistProfileSummary(db, user.id);
  const hasArtistDashboard = Boolean(artistProfile);
  const roles = await resolveUserRoles(db, user);
  const activePerspective = resolveActivePerspective(user, roles, hasArtistDashboard);

  return {
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
    redirect_path: hasArtistDashboard || user.user_type === 'artist'
      ? '/artist-dashboard.html'
      : (user.user_type === 'admin' ? '/gearsh-god.html' : '/'),
  };
}

export async function onRequestGet(context) {
  try {
    await ensureAuthTables(context.env.DB);
    await ensureOnboardingTables(context.env.DB);
    await ensureRenovationTables(context.env.DB);
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    const data = await loadSessionUser(context.env.DB, userId);
    if (!data) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    return jsonResponse({ success: true, data });
  } catch (err) {
    console.error('Session error:', err);
    return jsonResponse({ success: false, error: 'Session check failed' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    await ensureAuthTables(context.env.DB);
    await ensureOnboardingTables(context.env.DB);
    await ensureRenovationTables(context.env.DB);

    const body = await context.request.json().catch(function () { return {}; });
    const remember = body.remember !== false;
    const authHeader = context.request.headers.get('Authorization');

    let userId = await parseToken(authHeader, context.env);
    if (!userId) {
      userId = await parseTokenForRefresh(authHeader, context.env);
    }
    if (!userId) {
      return jsonResponse({ success: false, error: 'Session expired — sign in again' }, 401);
    }

    const data = await loadSessionUser(context.env.DB, userId);
    if (!data) {
      return jsonResponse({ success: false, error: 'Not signed in' }, 401);
    }

    data.token = await generateToken(userId, context.env, { remember });

    return jsonResponse({ success: true, data });
  } catch (err) {
    console.error('Session refresh error:', err);
    return jsonResponse({ success: false, error: 'Could not refresh session' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
