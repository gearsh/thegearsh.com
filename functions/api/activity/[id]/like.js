// POST /api/activity/:id/like — toggle like
// GET /api/activity/:id/comments — list comments
// POST handled in comments file for POST comment

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from '../../auth-utils.js';
import { ensureActivityTables } from '../../activity-schema.js';

function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const activityId = context.params.id;
    if (String(activityId).startsWith('seed_')) {
      return jsonResponse({
        success: true,
        data: { liked: true, like_count: 1, demo: true },
      });
    }

    await ensureActivityTables(context.env.DB);

    const activity = await context.env.DB.prepare(
      'SELECT id, like_count FROM artist_activities WHERE id = ?'
    ).bind(activityId).first();

    if (!activity) {
      return jsonResponse({ success: false, error: 'Activity not found' }, 404);
    }

    const existing = await context.env.DB.prepare(
      'SELECT id FROM activity_likes WHERE activity_id = ? AND user_id = ?'
    ).bind(activityId, userId).first();

    let liked = false;
    let likeCount = Number(activity.like_count || 0);

    if (existing) {
      await context.env.DB.prepare('DELETE FROM activity_likes WHERE id = ?').bind(existing.id).run();
      likeCount = Math.max(0, likeCount - 1);
      await context.env.DB.prepare(
        'UPDATE artist_activities SET like_count = ?, updated_at = datetime(\'now\') WHERE id = ?'
      ).bind(likeCount, activityId).run();
    } else {
      await context.env.DB.prepare(
        'INSERT INTO activity_likes (id, activity_id, user_id) VALUES (?, ?, ?)'
      ).bind(newId('like'), activityId, userId).run();
      likeCount += 1;
      liked = true;
      await context.env.DB.prepare(
        'UPDATE artist_activities SET like_count = ?, updated_at = datetime(\'now\') WHERE id = ?'
      ).bind(likeCount, activityId).run();
    }

    return jsonResponse({
      success: true,
      data: { liked, like_count: likeCount },
    });
  } catch (err) {
    console.error('Like toggle error:', err);
    return jsonResponse({ success: false, error: 'Failed to update like' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
