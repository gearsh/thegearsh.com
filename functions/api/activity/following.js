// GET /api/activity/following — unified feed from followed artists

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
  buildProfileUrl,
} from '../auth-utils.js';
import { ensureActivityTables } from '../activity-schema.js';
import { mapActivityRow } from '../activity-seed.js';

export async function onRequestGet(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const url = new URL(context.request.url);
    const cursor = url.searchParams.get('cursor');
    const limit = Math.min(30, Math.max(1, Number(url.searchParams.get('limit') || 10)));

    await ensureActivityTables(context.env.DB);

    let query = `
      SELECT
        aa.*,
        u.username,
        u.display_name AS artist_name,
        u.profile_picture_url,
        u.is_verified
      FROM artist_activities aa
      JOIN artist_follows af ON af.artist_id = aa.artist_id
      JOIN artist_profiles ap ON ap.id = aa.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE af.follower_user_id = ? AND aa.is_public = 1
    `;
    const binds = [userId];

    if (cursor) {
      query += ' AND aa.created_at < ?';
      binds.push(cursor);
    }

    query += ' ORDER BY aa.created_at DESC LIMIT ?';
    binds.push(limit + 1);

    const result = await context.env.DB.prepare(query).bind(...binds).all();
    const rows = result.results || [];
    let nextCursor = null;
    if (rows.length > limit) {
      nextCursor = rows[limit - 1].created_at;
      rows.length = limit;
    }

    const activityIds = rows.map(function(r) { return r.id; });
    let likedIds = new Set();
    if (activityIds.length) {
      const placeholders = activityIds.map(function() { return '?'; }).join(',');
      const likes = await context.env.DB.prepare(
        'SELECT activity_id FROM activity_likes WHERE user_id = ? AND activity_id IN (' + placeholders + ')'
      ).bind(userId, ...activityIds).all();
      likedIds = new Set((likes.results || []).map(function(r) { return r.activity_id; }));
    }

    const activities = rows.map(function(row) {
      const artistMeta = {
        artist_id: row.artist_id,
        username: row.username,
        name: row.artist_name,
        image: row.profile_picture_url,
        is_verified: Boolean(row.is_verified),
        profile_url: buildProfileUrl(row.username),
      };
      return mapActivityRow(row, artistMeta, userId, likedIds);
    });

    return jsonResponse({
      success: true,
      data: {
        activities,
        next_cursor: nextCursor,
      },
    });
  } catch (err) {
    console.error('Following feed error:', err);
    return jsonResponse({ success: false, error: 'Failed to load following feed' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
