// GET/POST /api/activity/:id/comments

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from '../../auth-utils.js';
import { ensureActivityTables } from '../../activity-schema.js';
import { relativeTime } from '../../activity-seed.js';

function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

export async function onRequestGet(context) {
  try {
    const activityId = context.params.id;
    if (String(activityId).startsWith('seed_')) {
      return jsonResponse({ success: true, data: { comments: [] } });
    }

    await ensureActivityTables(context.env.DB);

    const result = await context.env.DB.prepare(`
      SELECT c.id, c.body, c.created_at, u.display_name AS author_name, u.profile_picture_url
      FROM activity_comments c
      JOIN users u ON u.id = c.user_id
      WHERE c.activity_id = ?
      ORDER BY c.created_at DESC
      LIMIT 50
    `).bind(activityId).all();

    const comments = (result.results || []).map(function(row) {
      return {
        id: row.id,
        body: row.body,
        author_name: row.author_name || 'User',
        author_image: row.profile_picture_url || '',
        created_at: row.created_at,
        relative_time: relativeTime(row.created_at),
      };
    });

    return jsonResponse({ success: true, data: { comments } });
  } catch (err) {
    console.error('Comments GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load comments' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const activityId = context.params.id;
    const body = await context.request.json();
    const text = String(body.body || '').trim();

    if (!text || text.length > 500) {
      return jsonResponse({ success: false, error: 'Comment required (max 500 chars)' }, 400);
    }

    if (String(activityId).startsWith('seed_')) {
      return jsonResponse({
        success: true,
        data: {
          comment: {
            id: 'seed_comment',
            body: text,
            author_name: 'You',
            relative_time: 'Just now',
          },
          demo: true,
        },
      });
    }

    await ensureActivityTables(context.env.DB);

    const activity = await context.env.DB.prepare(
      'SELECT id, comment_count FROM artist_activities WHERE id = ?'
    ).bind(activityId).first();

    if (!activity) {
      return jsonResponse({ success: false, error: 'Activity not found' }, 404);
    }

    const commentId = newId('comment');
    await context.env.DB.prepare(`
      INSERT INTO activity_comments (id, activity_id, user_id, body) VALUES (?, ?, ?, ?)
    `).bind(commentId, activityId, userId, text).run();

    const count = Number(activity.comment_count || 0) + 1;
    await context.env.DB.prepare(
      'UPDATE artist_activities SET comment_count = ?, updated_at = datetime(\'now\') WHERE id = ?'
    ).bind(count, activityId).run();

    const user = await context.env.DB.prepare(
      'SELECT display_name, profile_picture_url FROM users WHERE id = ?'
    ).bind(userId).first();

    return jsonResponse({
      success: true,
      data: {
        comment: {
          id: commentId,
          body: text,
          author_name: user?.display_name || 'You',
          author_image: user?.profile_picture_url || '',
          relative_time: 'Just now',
        },
        comment_count: count,
      },
    }, 201);
  } catch (err) {
    console.error('Comments POST error:', err);
    return jsonResponse({ success: false, error: 'Failed to post comment' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
