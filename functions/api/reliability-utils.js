// Private reliability index — ops-only metrics, never public labels

import { ensureRenovationTables } from './renovation-schema.js';

const EVENT_MAP = {
  booking_completed: { field: 'completed_bookings', incTotal: true },
  booking_cancelled: { field: 'cancelled_bookings', incTotal: true },
  booking_disputed: { field: 'disputed_bookings', incTotal: false },
  booking_rescheduled: { field: 'rescheduled_bookings', incTotal: false },
  arrived_on_time: { field: 'on_time_arrivals', incTotal: false },
  arrived_late: { field: 'late_arrivals', incTotal: false },
  no_show: { field: 'no_shows', incTotal: false },
};

function newId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

function recalcRates(index) {
  const total = index.total_bookings || 0;
  return {
    completion_rate: total > 0 ? (index.completed_bookings / total) * 100 : 0,
    cancellation_rate: total > 0 ? (index.cancelled_bookings / total) * 100 : 0,
    dispute_rate: total > 0 ? (index.disputed_bookings / total) * 100 : 0,
  };
}

export async function recordReliabilityEvent(db, {
  userId,
  userRole = 'artist',
  eventType,
  bookingId = null,
  metadata = null,
}) {
  await ensureRenovationTables(db);

  const eventId = newId('rix');
  const now = new Date().toISOString();
  const metaJson = metadata ? JSON.stringify(metadata) : null;

  await db.prepare(`
    INSERT INTO reliability_events (id, user_id, event_type, booking_id, metadata, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `).bind(eventId, userId, eventType, bookingId, metaJson, now).run();

  let index = await db.prepare(
    `SELECT * FROM reliability_indices WHERE user_id = ?`
  ).bind(userId).first();

  if (!index) {
    await db.prepare(`
      INSERT INTO reliability_indices (user_id, user_role, last_updated)
      VALUES (?, ?, ?)
    `).bind(userId, userRole, now).run();
    index = {
      user_id: userId,
      user_role: userRole,
      total_bookings: 0,
      completed_bookings: 0,
      cancelled_bookings: 0,
      disputed_bookings: 0,
      rescheduled_bookings: 0,
      on_time_arrivals: 0,
      late_arrivals: 0,
      no_shows: 0,
    };
  }

  const rule = EVENT_MAP[eventType];
  if (rule) {
    const updates = { ...index };
    updates[rule.field] = (updates[rule.field] || 0) + 1;
    if (rule.incTotal) {
      updates.total_bookings = (updates.total_bookings || 0) + 1;
    }
    const rates = recalcRates(updates);
    await db.prepare(`
      UPDATE reliability_indices SET
        total_bookings = ?,
        completed_bookings = ?,
        cancelled_bookings = ?,
        disputed_bookings = ?,
        rescheduled_bookings = ?,
        on_time_arrivals = ?,
        late_arrivals = ?,
        no_shows = ?,
        completion_rate = ?,
        cancellation_rate = ?,
        dispute_rate = ?,
        last_updated = ?
      WHERE user_id = ?
    `).bind(
      updates.total_bookings || 0,
      updates.completed_bookings || 0,
      updates.cancelled_bookings || 0,
      updates.disputed_bookings || 0,
      updates.rescheduled_bookings || 0,
      updates.on_time_arrivals || 0,
      updates.late_arrivals || 0,
      updates.no_shows || 0,
      rates.completion_rate,
      rates.cancellation_rate,
      rates.dispute_rate,
      now,
      userId,
    ).run();
  }

  return eventId;
}

export async function getReliabilityIndex(db, userId) {
  await ensureRenovationTables(db);
  return db.prepare(`SELECT * FROM reliability_indices WHERE user_id = ?`).bind(userId).first();
}
