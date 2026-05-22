import { jsonResponse, corsPreflightResponse, parseSkills, buildProfileUrl } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';

export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const q = (url.searchParams.get('q') || '').trim();
    const status = url.searchParams.get('status') || 'all';
    const limit = Math.min(parseInt(url.searchParams.get('limit') || '50', 10), 100);

    let query = `
      SELECT
        ap.id AS artist_id,
        u.id AS user_id,
        u.email,
        u.display_name AS name,
        u.username,
        u.phone,
        u.location,
        u.country,
        u.is_verified,
        u.is_active,
        u.created_at,
        ap.category,
        ap.genre,
        ap.skills,
        ap.total_bookings,
        ap.avg_rating AS rating,
        ap.total_reviews AS review_count,
        ap.base_rate,
        (SELECT MIN(s.price) FROM services s WHERE s.artist_id = ap.id AND s.is_active = 1) AS min_price
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE 1 = 1
    `;
    const params = [];

    if (status === 'active') {
      query += ' AND u.is_active = 1';
    } else if (status === 'inactive') {
      query += ' AND u.is_active = 0';
    } else if (status === 'pending') {
      query += ' AND u.is_active = 1 AND u.is_verified = 0';
    } else if (status === 'verified') {
      query += ' AND u.is_verified = 1';
    }

    if (q) {
      query += ` AND (
        LOWER(u.display_name) LIKE LOWER(?)
        OR LOWER(u.email) LIKE LOWER(?)
        OR LOWER(u.username) LIKE LOWER(?)
        OR LOWER(u.location) LIKE LOWER(?)
        OR LOWER(u.country) LIKE LOWER(?)
        OR LOWER(ap.category) LIKE LOWER(?)
        OR LOWER(ap.genre) LIKE LOWER(?)
        OR LOWER(ap.skills) LIKE LOWER(?)
      )`;
      const like = '%' + q + '%';
      params.push(like, like, like, like, like, like, like, like);
    }

    query += ' ORDER BY u.created_at DESC LIMIT ?';
    params.push(limit);

    const result = await context.env.DB.prepare(query).bind(...params).all();
    const artists = (result.results || []).map(function(row) {
      return {
        ...row,
        skills: parseSkills(row.skills),
        is_verified: Boolean(row.is_verified),
        is_active: Boolean(row.is_active),
        profile_url: buildProfileUrl(row.username),
      };
    });

    return jsonResponse({
      success: true,
      data: artists,
      meta: { count: artists.length, query: q, status },
    });
  } catch (err) {
    console.error('Founder artists error:', err);
    return jsonResponse({ success: false, error: 'Failed to search artists' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
