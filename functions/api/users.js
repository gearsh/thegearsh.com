// GET /api/users         - List all registered users (founder-only)
// GET /api/users/:id     - Get a specific user (self or founder)

import {
  corsHeaders,
  corsPreflightResponse,
  jsonResponse,
  parseToken,
  isFounderRequest,
  unauthorizedResponse,
} from './auth-utils.js';

const ALLOWED_USER_TYPES = new Set(['fan', 'client', 'artist', 'admin']);

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const pathTail = url.pathname.split('/').filter(Boolean).pop();

    if (pathTail && pathTail !== 'users') {
      return await getUser(context, pathTail);
    }

    if (!isFounderRequest(context.request, context.env)) {
      return unauthorizedResponse('Founder access required');
    }

    return await listUsers(context, url);
  } catch (err) {
    console.error('Users API error:', err);
    return jsonResponse({ success: false, error: 'Failed to fetch users' }, 500);
  }
}

async function getUser(context, userId) {
  const founder = isFounderRequest(context.request, context.env);
  if (!founder) {
    const requesterId = await parseToken(
      context.request.headers.get('Authorization'),
      context.env,
    );
    if (!requesterId || requesterId !== userId) {
      return unauthorizedResponse('Not allowed to view this user');
    }
  }

  const user = await context.env.DB.prepare(`
    SELECT
      id, email, user_type, first_name, last_name, display_name,
      profile_picture_url, phone, location, country, bio,
      is_verified, created_at
    FROM users
    WHERE id = ? AND is_active = 1
  `).bind(userId).first();

  if (!user) {
    return jsonResponse({ success: false, error: 'User not found' }, 404);
  }

  let artistProfile = null;
  if (user.user_type === 'artist') {
    artistProfile = await context.env.DB.prepare(
      `SELECT * FROM artist_profiles WHERE user_id = ?`,
    ).bind(userId).first();
  }

  return jsonResponse({
    success: true,
    data: {
      ...user,
      is_verified: Boolean(user.is_verified),
      artist_profile: artistProfile,
    },
  });
}

async function listUsers(context, url) {
  const rawLimit = parseInt(url.searchParams.get('limit') || '50', 10);
  const rawOffset = parseInt(url.searchParams.get('offset') || '0', 10);
  const limit = Number.isFinite(rawLimit) ? Math.min(Math.max(rawLimit, 1), 200) : 50;
  const offset = Number.isFinite(rawOffset) ? Math.max(rawOffset, 0) : 0;
  const userType = url.searchParams.get('user_type');

  const params = [];
  let query = `
    SELECT
      id, email, user_type, first_name, last_name, display_name,
      location, country, is_verified, created_at
    FROM users
    WHERE is_active = 1
  `;
  let countQuery = `SELECT COUNT(*) as total FROM users WHERE is_active = 1`;

  if (userType) {
    if (!ALLOWED_USER_TYPES.has(userType)) {
      return jsonResponse({ success: false, error: 'Invalid user_type' }, 400);
    }
    query += ` AND user_type = ?`;
    countQuery += ` AND user_type = ?`;
    params.push(userType);
  }

  query += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;

  const listStmt = context.env.DB.prepare(query).bind(...params, limit, offset);
  const countStmt = userType
    ? context.env.DB.prepare(countQuery).bind(userType)
    : context.env.DB.prepare(countQuery);

  const [result, countResult] = await Promise.all([listStmt.all(), countStmt.first()]);

  return jsonResponse({
    success: true,
    data: (result.results || []).map((user) => ({
      ...user,
      is_verified: Boolean(user.is_verified),
    })),
    meta: { total: countResult.total, limit, offset },
  });
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
