// POST /api/artists/:id/follow — follow or unfollow artist
// GET /api/artists/:id/follow — follow status

import {
  parseToken,
  resolveArtistProfile,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from '../../auth-utils.js';
import { findShowcaseArtist } from '../../showcase-profile.js';
import { ensureActivityTables } from '../../activity-schema.js';

function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

async function followerCount(db, artistId) {
  const row = await db.prepare(
    'SELECT COUNT(*) AS count FROM artist_follows WHERE artist_id = ?'
  ).bind(artistId).first();
  return Number(row?.count || 0);
}

export async function onRequestGet(context) {
  try {
    const viewerUserId = await parseToken(context.request.headers.get('Authorization'), context.env);
    const identifier = context.params.id;
    const resolved = await resolveArtistProfile(context.env.DB, identifier);
    const showcase = findShowcaseArtist(identifier);

    if (!resolved && !showcase) {
      return jsonResponse({ success: false, error: 'Artist not found' }, 404);
    }

    await ensureActivityTables(context.env.DB);

    if (!resolved) {
      return jsonResponse({
        success: true,
        data: {
          is_following: false,
          follower_count: 0,
          requires_auth: !viewerUserId,
        },
      });
    }

    let isFollowing = false;
    if (viewerUserId) {
      const row = await context.env.DB.prepare(`
        SELECT id FROM artist_follows
        WHERE follower_user_id = ? AND artist_id = ?
      `).bind(viewerUserId, resolved.artist_id).first();
      isFollowing = Boolean(row);
    }

    return jsonResponse({
      success: true,
      data: {
        is_following: isFollowing,
        follower_count: await followerCount(context.env.DB, resolved.artist_id),
        requires_auth: !viewerUserId,
      },
    });
  } catch (err) {
    console.error('Follow status error:', err);
    return jsonResponse({ success: false, error: 'Failed to load follow status' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const viewerUserId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!viewerUserId) return unauthorizedResponse();

    const identifier = context.params.id;
    const resolved = await resolveArtistProfile(context.env.DB, identifier);
    if (!resolved) {
      return jsonResponse({ success: false, error: 'Artist must have a live profile to follow' }, 404);
    }

    if (resolved.user_id === viewerUserId) {
      return jsonResponse({ success: false, error: 'You cannot follow yourself' }, 400);
    }

    await ensureActivityTables(context.env.DB);

    const body = await context.request.json().catch(function() { return {}; });
    const action = String(body.action || 'toggle').toLowerCase();

    const existing = await context.env.DB.prepare(`
      SELECT id FROM artist_follows WHERE follower_user_id = ? AND artist_id = ?
    `).bind(viewerUserId, resolved.artist_id).first();

    let isFollowing = Boolean(existing);

    if (action === 'unfollow' || (action === 'toggle' && existing)) {
      if (existing) {
        await context.env.DB.prepare('DELETE FROM artist_follows WHERE id = ?').bind(existing.id).run();
      }
      isFollowing = false;
    } else if (!existing) {
      await context.env.DB.prepare(`
        INSERT INTO artist_follows (id, follower_user_id, artist_id) VALUES (?, ?, ?)
      `).bind(newId('follow'), viewerUserId, resolved.artist_id).run();
      isFollowing = true;
    }

    return jsonResponse({
      success: true,
      data: {
        is_following: isFollowing,
        follower_count: await followerCount(context.env.DB, resolved.artist_id),
      },
    });
  } catch (err) {
    console.error('Follow POST error:', err);
    return jsonResponse({ success: false, error: 'Failed to update follow' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
