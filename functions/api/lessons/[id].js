// GET   /api/lessons/:id        — lesson detail (participants only)
// PATCH /api/lessons/:id         — update status { action }
//   tutor:   accept | decline | schedule | complete
//   student: cancel
//   either:  complete (after scheduled)

import { corsPreflightResponse, jsonResponse, requireAuth } from '../auth-utils.js';
import { ensureLessonTables, userOnLesson } from '../lessons-utils.js';

async function load(db, id) {
  return db.prepare(`SELECT * FROM lesson_bookings WHERE id = ?`).bind(id).first();
}

const TRANSITIONS = {
  accept: { from: ['pending'], to: 'accepted', role: 'tutor' },
  decline: { from: ['pending', 'accepted'], to: 'declined', role: 'tutor' },
  schedule: { from: ['pending', 'accepted'], to: 'scheduled', role: 'tutor' },
  complete: { from: ['scheduled', 'accepted'], to: 'completed', role: 'any' },
  cancel: { from: ['pending', 'accepted', 'scheduled'], to: 'cancelled', role: 'any' },
};

export async function onRequestGet(context) {
  try {
    await ensureLessonTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const row = await load(context.env.DB, context.params.id);
    if (!row || !userOnLesson(row, auth.userId)) {
      return jsonResponse({ success: false, error: 'Lesson not found' }, 404);
    }
    return jsonResponse({ success: true, data: row });
  } catch (err) {
    console.error('Lesson get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load lesson' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    await ensureLessonTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const row = await load(context.env.DB, context.params.id);
    if (!row || !userOnLesson(row, auth.userId)) {
      return jsonResponse({ success: false, error: 'Lesson not found' }, 404);
    }

    const body = await context.request.json().catch(function () { return {}; });
    const action = String(body.action || '').trim();
    const t = TRANSITIONS[action];
    if (!t) return jsonResponse({ success: false, error: 'Unknown action' }, 400);

    const isTutor = row.tutor_id === auth.userId;
    const isStudent = row.student_id === auth.userId;
    if (t.role === 'tutor' && !isTutor) {
      return jsonResponse({ success: false, error: 'Only the tutor can do that' }, 403);
    }
    if (action === 'cancel' && !isStudent && !isTutor) {
      return jsonResponse({ success: false, error: 'Not allowed' }, 403);
    }
    if (t.from.indexOf(row.status) === -1) {
      return jsonResponse({ success: false, error: 'Cannot ' + action + ' a ' + row.status + ' lesson' }, 409);
    }

    const now = new Date().toISOString();
    if (action === 'schedule' && body.scheduled_time) {
      await context.env.DB.prepare(
        `UPDATE lesson_bookings SET status = ?, preferred_times = ?, updated_at = ? WHERE id = ?`
      ).bind(t.to, String(body.scheduled_time).slice(0, 300), now, row.id).run();
    } else {
      await context.env.DB.prepare(
        `UPDATE lesson_bookings SET status = ?, updated_at = ? WHERE id = ?`
      ).bind(t.to, now, row.id).run();
    }

    return jsonResponse({ success: true, data: { id: row.id, status: t.to } });
  } catch (err) {
    console.error('Lesson patch error:', err);
    return jsonResponse({ success: false, error: 'Failed to update lesson' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
