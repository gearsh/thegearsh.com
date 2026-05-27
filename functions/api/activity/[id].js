// PATCH /api/activity/:id — update visibility or delete
// DELETE /api/activity/:id

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from '../auth-utils.js';
import { ensureActivityTables } from '../activity-schema.js';

async function ownsActivity(db, userId, activityId) {
  const row = await db.prepare(`
    SELECT aa.id
    FROM artist_activities aa
    JOIN artist_profiles ap ON ap.id = aa.artist_id
    WHERE aa.id = ? AND ap.user_id = ?
  `).bind(activityId, userId).first();
  return Boolean(row);
}

export async function onRequestPatch(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const activityId = context.params.id;
    await ensureActivityTables(context.env.DB);

    if (!(await ownsActivity(context.env.DB, userId, activityId))) {
      return jsonResponse({ success: false, error: 'Not authorized' }, 403);
    }

    const body = await context.request.json();
    const isPublic = body.is_public === false ? 0 : 1;

    await context.env.DB.prepare(`
      UPDATE artist_activities SET is_public = ?, updated_at = datetime('now') WHERE id = ?
    `).bind(isPublic, activityId).run();

    return jsonResponse({ success: true, data: { is_public: Boolean(isPublic) } });
  } catch (err) {
    console.error('Activity PATCH error:', err);
    return jsonResponse({ success: false, error: 'Failed to update activity' }, 500);
  }
}

export async function onRequestDelete(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const activityId = context.params.id;
    await ensureActivityTables(context.env.DB);

    if (!(await ownsActivity(context.env.DB, userId, activityId))) {
      return jsonResponse({ success: false, error: 'Not authorized' }, 403);
    }

    await context.env.DB.prepare('DELETE FROM activity_likes WHERE activity_id = ?').bind(activityId).run();
    await context.env.DB.prepare('DELETE FROM activity_comments WHERE activity_id = ?').bind(activityId).run();
    await context.env.DB.prepare('DELETE FROM artist_activities WHERE id = ?').bind(activityId).run();

    return jsonResponse({ success: true, data: { deleted: true } });
  } catch (err) {
    console.error('Activity DELETE error:', err);
    return jsonResponse({ success: false, error: 'Failed to delete activity' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
