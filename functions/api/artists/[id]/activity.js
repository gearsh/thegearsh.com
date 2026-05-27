// GET /api/artists/:id/activity — public artist activity feed (paginated)

import {
  parseToken,
  resolveArtistProfile,
  jsonResponse,
  corsPreflightResponse,
  buildProfileUrl,
} from '../../auth-utils.js';
import { findShowcaseArtist, resolveShowcaseImage } from '../../showcase-profile.js';
import { ensureActivityTables } from '../../activity-schema.js';
import {
  getSeedActivities,
  mapActivityRow,
  mapSeedActivity,
} from '../../activity-seed.js';

function artistHeaderFromRow(row, showcase) {
  const name = row?.artist_name || showcase?.name || 'Artist';
  const username = row?.username || showcase?.username || '';
  const image = row?.profile_picture_url || resolveShowcaseImage(showcase) || '';
  return {
    artist_id: row?.artist_id || showcase?.username,
    username,
    name,
    image,
    is_verified: Boolean(row?.is_verified || showcase?.verified),
    profile_url: buildProfileUrl(username),
    follower_count: Number(row?.follower_count || 0),
    is_following: Boolean(row?.is_following),
  };
}

async function getLikedIds(db, userId, activityIds) {
  if (!userId || !activityIds.length) return new Set();
  const placeholders = activityIds.map(function() { return '?'; }).join(',');
  const result = await db.prepare(
    'SELECT activity_id FROM activity_likes WHERE user_id = ? AND activity_id IN (' + placeholders + ')'
  ).bind(userId, ...activityIds).all();
  return new Set((result.results || []).map(function(r) { return r.activity_id; }));
}

export async function onRequestGet(context) {
  try {
    const identifier = context.params.id;
    const url = new URL(context.request.url);
    const cursor = url.searchParams.get('cursor');
    const limit = Math.min(30, Math.max(1, Number(url.searchParams.get('limit') || 10)));
    const viewerUserId = await parseToken(context.request.headers.get('Authorization'), context.env);

    const showcase = findShowcaseArtist(identifier);
    let resolved = await resolveArtistProfile(context.env.DB, identifier);

    if (!resolved && !showcase) {
      return jsonResponse({ success: false, error: 'Artist not found' }, 404);
    }

    const username = resolved?.username || showcase?.username || identifier;
    const artistId = resolved?.artist_id || null;

    await ensureActivityTables(context.env.DB);

    let headerRow = null;
    if (artistId) {
      headerRow = await context.env.DB.prepare(`
        SELECT
          ap.id AS artist_id,
          u.username,
          u.display_name AS artist_name,
          u.profile_picture_url,
          u.is_verified,
          (SELECT COUNT(*) FROM artist_follows af WHERE af.artist_id = ap.id) AS follower_count,
          CASE WHEN ? IS NULL THEN 0 ELSE (
            SELECT COUNT(*) FROM artist_follows af2
            WHERE af2.artist_id = ap.id AND af2.follower_user_id = ?
          ) END AS is_following
        FROM artist_profiles ap
        JOIN users u ON ap.user_id = u.id
        WHERE ap.id = ?
      `).bind(viewerUserId, viewerUserId, artistId).first();
    }

    const artistMeta = artistHeaderFromRow(headerRow, showcase);
    let items = [];
    let nextCursor = null;

    if (artistId) {
      let query = `
        SELECT *
        FROM artist_activities
        WHERE artist_id = ? AND is_public = 1
      `;
      const binds = [artistId];

      if (cursor) {
        query += ' AND created_at < ?';
        binds.push(cursor);
      }

      query += ' ORDER BY created_at DESC LIMIT ?';
      binds.push(limit + 1);

      const result = await context.env.DB.prepare(query).bind(...binds).all();
      const rows = result.results || [];
      if (rows.length > limit) {
        nextCursor = rows[limit - 1].created_at;
        rows.length = limit;
      }

      const likedIds = await getLikedIds(
        context.env.DB,
        viewerUserId,
        rows.map(function(r) { return r.id; })
      );

      items = rows.map(function(row) {
        return mapActivityRow(row, artistMeta, viewerUserId, likedIds);
      });
    }

    if (!items.length) {
      const seed = getSeedActivities(username).slice(0, limit);
      items = seed.map(function(item) {
        return mapSeedActivity(item, artistMeta);
      });
    }

    const highlights = items.slice(0, 6).map(function(item) {
      return {
        id: item.id,
        activity_type: item.activity_type,
        type_label: item.type_label,
        title: item.title,
        media_url: (item.media_urls && item.media_urls[0]) || artistMeta.image,
      };
    });

    return jsonResponse({
      success: true,
      data: {
        artist: artistMeta,
        highlights,
        activities: items,
        next_cursor: nextCursor,
      },
    });
  } catch (err) {
    console.error('Artist activity feed error:', err);
    return jsonResponse({ success: false, error: 'Failed to load activity feed' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
