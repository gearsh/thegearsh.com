// GET /api/lessons/mine — lessons the user booked (sent) and lessons they teach (received).

import { corsPreflightResponse, jsonResponse, requireAuth } from '../auth-utils.js';
import { ensureLessonTables } from '../lessons-utils.js';

function mapRow(row, role) {
  return {
    id: row.id,
    role: role,
    student_id: row.student_id,
    tutor_id: row.tutor_id,
    tutor_username: row.tutor_username,
    tutor_name: row.tutor_name,
    student_name: row.student_name || null,
    discipline: row.discipline,
    lesson_title: row.lesson_title,
    level: row.level,
    format: row.format,
    location: row.location,
    hourly_rate: row.hourly_rate,
    duration_hours: row.duration_hours,
    sessions: row.sessions,
    preferred_times: row.preferred_times,
    message: row.message,
    status: row.status,
    created_at: row.created_at,
  };
}

export async function onRequestGet(context) {
  try {
    await ensureLessonTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const sent = await context.env.DB.prepare(`
      SELECT * FROM lesson_bookings WHERE student_id = ? ORDER BY created_at DESC LIMIT 100
    `).bind(auth.userId).all();

    const received = await context.env.DB.prepare(`
      SELECT lb.*, u.display_name AS student_name
      FROM lesson_bookings lb
      LEFT JOIN users u ON lb.student_id = u.id
      WHERE lb.tutor_id = ? ORDER BY lb.created_at DESC LIMIT 100
    `).bind(auth.userId).all();

    return jsonResponse({
      success: true,
      data: {
        sent: (sent.results || []).map(function (r) { return mapRow(r, 'student'); }),
        received: (received.results || []).map(function (r) { return mapRow(r, 'tutor'); }),
      },
    });
  } catch (err) {
    console.error('Lessons mine error:', err);
    return jsonResponse({ success: false, error: 'Failed to load your lessons' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
