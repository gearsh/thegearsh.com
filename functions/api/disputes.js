// POST /api/disputes — create dispute for a booking
// GET /api/disputes — list disputes for current user
import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from './auth-utils.js';
import { ensureMarketplaceTables } from './db-schema.js';
import { recordReliabilityEvent } from './reliability-utils.js';

export async function onRequestGet(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const result = await context.env.DB.prepare(`
      SELECT d.*, b.event_date, b.total_price
      FROM disputes d
      JOIN bookings b ON d.booking_id = b.id
      WHERE d.reporter_id = ?
      ORDER BY d.created_at DESC
      LIMIT 50
    `).bind(auth.userId).all();

    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Disputes list error:', err);
    return jsonResponse({ success: false, error: 'Failed to load disputes' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const bookingId = String(body.booking_id || '').trim();
    const subject = String(body.subject || '').trim();
    const description = String(body.description || '').trim();
    const severity = String(body.severity || 'medium').toLowerCase();

    if (!bookingId || !subject) {
      return jsonResponse({ success: false, error: 'booking_id and subject are required' }, 400);
    }

    const booking = await context.env.DB.prepare(
      `SELECT client_id, artist_id FROM bookings WHERE id = ?`
    ).bind(bookingId).first();

    if (!booking) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    const disputeId = `dispute_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO disputes (id, booking_id, reporter_id, subject, description, severity, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, 'open', ?, ?)
    `).bind(disputeId, bookingId, auth.userId, subject, description, severity, now, now).run();

    await context.env.DB.prepare(`
      UPDATE bookings SET status = 'disputed', updated_at = ? WHERE id = ?
    `).bind(now, bookingId).run();

    await recordReliabilityEvent(context.env.DB, {
      userId: auth.userId,
      userRole: auth.user.user_type || 'client',
      eventType: 'booking_disputed',
      bookingId,
    });

    const artist = await context.env.DB.prepare(
      `SELECT user_id FROM artist_profiles WHERE id = ?`
    ).bind(booking.artist_id).first();
    if (artist?.user_id && artist.user_id !== auth.userId) {
      await recordReliabilityEvent(context.env.DB, {
        userId: artist.user_id,
        userRole: 'artist',
        eventType: 'booking_disputed',
        bookingId,
      });
    }

    return jsonResponse({ success: true, data: { id: disputeId, status: 'open' } }, 201);
  } catch (err) {
    console.error('Dispute create error:', err);
    return jsonResponse({ success: false, error: 'Failed to create dispute' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
