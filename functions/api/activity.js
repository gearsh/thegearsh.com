// POST /api/activity — create activity (authenticated artist)
// GET /api/activity?mine=1 — artist's own activities including private

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from '../auth-utils.js';
import { ensureActivityTables } from '../activity-schema.js';
import { mapActivityRow } from '../activity-seed.js';

const VALID_TYPES = new Set([
  'gig', 'collaboration', 'photoshoot', 'studio', 'travel', 'press', 'milestone', 'custom',
]);

function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

async function getArtistProfileForUser(db, userId) {
  return db.prepare(`
    SELECT ap.id AS artist_id, u.username, u.display_name AS artist_name, u.profile_picture_url, u.is_verified
    FROM artist_profiles ap
    JOIN users u ON ap.user_id = u.id
    WHERE ap.user_id = ?
  `).bind(userId).first();
}

export async function onRequestGet(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const url = new URL(context.request.url);
    if (url.searchParams.get('mine') !== '1') {
      return jsonResponse({ success: false, error: 'Use /api/activity/following for following feed' }, 400);
    }

    await ensureActivityTables(context.env.DB);
    const profile = await getArtistProfileForUser(context.env.DB, userId);
    if (!profile) {
      return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
    }

    const result = await context.env.DB.prepare(`
      SELECT * FROM artist_activities
      WHERE artist_id = ?
      ORDER BY created_at DESC
      LIMIT 50
    `).bind(profile.artist_id).all();

    const artistMeta = {
      artist_id: profile.artist_id,
      username: profile.username,
      name: profile.artist_name,
      image: profile.profile_picture_url,
      is_verified: Boolean(profile.is_verified),
    };

    const activities = (result.results || []).map(function(row) {
      return mapActivityRow(row, artistMeta, userId, new Set());
    });

    return jsonResponse({ success: true, data: { activities } });
  } catch (err) {
    console.error('Activity mine GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load activities' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    await ensureActivityTables(context.env.DB);
    const profile = await getArtistProfileForUser(context.env.DB, userId);
    if (!profile) {
      return jsonResponse({ success: false, error: 'Only artists can post activity' }, 403);
    }

    const body = await context.request.json();
    const activityType = String(body.activity_type || 'custom').toLowerCase();
    const title = String(body.title || '').trim();

    if (!VALID_TYPES.has(activityType)) {
      return jsonResponse({ success: false, error: 'Invalid activity type' }, 400);
    }
    if (!title || title.length > 200) {
      return jsonResponse({ success: false, error: 'Title is required (max 200 chars)' }, 400);
    }

    const mediaUrls = Array.isArray(body.media_urls)
      ? body.media_urls.filter(Boolean).slice(0, 8)
      : [];
    const metadata = body.metadata && typeof body.metadata === 'object' ? body.metadata : {};
    const isPublic = body.is_public === false ? 0 : 1;
    const id = newId('act');
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO artist_activities (
        id, artist_id, author_user_id, activity_type, title, description,
        location, venue, event_date, media_urls, metadata_json, is_public,
        like_count, comment_count, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?, ?)
    `).bind(
      id,
      profile.artist_id,
      userId,
      activityType,
      title,
      String(body.description || '').trim().slice(0, 2000),
      String(body.location || '').trim().slice(0, 120),
      String(body.venue || '').trim().slice(0, 120),
      body.event_date ? String(body.event_date).slice(0, 10) : null,
      JSON.stringify(mediaUrls),
      JSON.stringify(metadata),
      isPublic,
      now,
      now,
    ).run();

    const row = await context.env.DB.prepare('SELECT * FROM artist_activities WHERE id = ?').bind(id).first();
    const artistMeta = {
      artist_id: profile.artist_id,
      username: profile.username,
      name: profile.artist_name,
      image: profile.profile_picture_url,
      is_verified: Boolean(profile.is_verified),
    };

    return jsonResponse({
      success: true,
      data: { activity: mapActivityRow(row, artistMeta, userId, new Set()) },
    }, 201);
  } catch (err) {
    console.error('Activity POST error:', err);
    return jsonResponse({ success: false, error: 'Failed to create activity' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
