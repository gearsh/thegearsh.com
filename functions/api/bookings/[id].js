// PATCH /api/bookings/:id — update booking status (accept/decline/complete/cancel)
import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from '../auth-utils.js';
import { ensureMarketplaceTables } from '../db-schema.js';

const ALLOWED_STATUSES = new Set([
  'pending', 'confirmed', 'cancelled', 'completed', 'disputed',
]);

const TRANSITIONS = {
  pending: new Set(['confirmed', 'cancelled']),
  confirmed: new Set(['completed', 'cancelled', 'disputed']),
  completed: new Set([]),
  cancelled: new Set([]),
  disputed: new Set(['completed', 'cancelled']),
};

async function getArtistProfileId(db, userId) {
  const row = await db.prepare(
    `SELECT id FROM artist_profiles WHERE user_id = ?`
  ).bind(userId).first();
  return row?.id || null;
}

async function canModifyBooking(db, user, booking) {
  if (user.user_type === 'admin') return true;
  if (booking.client_id === user.id) return true;
  const artistProfileId = await getArtistProfileId(db, user.id);
  return artistProfileId && booking.artist_id === artistProfileId;
}

export async function onRequestPatch(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const bookingId = context.params.id;
    const body = await context.request.json();
    const nextStatus = String(body.status || '').trim().toLowerCase();
    const action = String(body.action || '').trim().toLowerCase();

    let status = nextStatus;
    if (!status && action === 'accept') status = 'confirmed';
    if (!status && action === 'decline') status = 'cancelled';
    if (!status && action === 'complete') status = 'completed';
    if (!status && action === 'cancel') status = 'cancelled';

    if (!ALLOWED_STATUSES.has(status)) {
      return jsonResponse({ success: false, error: 'Invalid booking status' }, 400);
    }

    const booking = await context.env.DB.prepare(
      `SELECT * FROM bookings WHERE id = ?`
    ).bind(bookingId).first();

    if (!booking) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    const allowed = await canModifyBooking(context.env.DB, auth.user, booking);
    if (!allowed) {
      return jsonResponse({ success: false, error: 'Not allowed to update this booking' }, 403);
    }

    const currentStatus = booking.status || 'pending';
    const validNext = TRANSITIONS[currentStatus] || new Set();
    if (!validNext.has(status) && auth.user.user_type !== 'admin') {
      return jsonResponse({
        success: false,
        error: `Cannot change booking from ${currentStatus} to ${status}`,
      }, 400);
    }

    if (status === 'confirmed' && booking.client_id === auth.user.id) {
      return jsonResponse({ success: false, error: 'Only the artist can confirm bookings' }, 403);
    }

    const now = new Date().toISOString();

    const updates = ['status = ?', 'updated_at = ?'];
    const binds = [status, now];

    if (body.quote_amount !== undefined) {
      updates.push('quote_amount = ?', 'total_price = ?');
      binds.push(Number(body.quote_amount), Number(body.quote_amount));
    }
    if (body.deposit_amount !== undefined) {
      updates.push('deposit_amount = ?');
      binds.push(Number(body.deposit_amount));
    }

    binds.push(bookingId);
    await context.env.DB.prepare(`
      UPDATE bookings SET ${updates.join(', ')} WHERE id = ?
    `).bind(...binds).run();

    if (status === 'completed') {
      await context.env.DB.prepare(`
        INSERT INTO escrow_ledger (id, booking_id, event_type, amount, note, created_by, created_at)
        VALUES (?, ?, 'release', ?, 'Booking completed', ?, ?)
      `).bind(
        `escrow_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
        bookingId,
        booking.total_price,
        auth.user.id,
        now
      ).run();
    }

    if (status === 'cancelled') {
      await context.env.DB.prepare(`
        INSERT INTO escrow_ledger (id, booking_id, event_type, amount, note, created_by, created_at)
        VALUES (?, ?, 'refund', ?, 'Booking cancelled', ?, ?)
      `).bind(
        `escrow_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
        bookingId,
        booking.total_price,
        auth.user.id,
        now
      ).run();
    }

    const updated = await context.env.DB.prepare(`
      SELECT
        b.*,
        u_client.display_name as client_name,
        u_artist.display_name as artist_name,
        s.name as service_name
      FROM bookings b
      JOIN users u_client ON b.client_id = u_client.id
      JOIN artist_profiles ap ON b.artist_id = ap.id
      JOIN users u_artist ON ap.user_id = u_artist.id
      LEFT JOIN services s ON b.service_id = s.id
      WHERE b.id = ?
    `).bind(bookingId).first();

    return jsonResponse({ success: true, data: updated });
  } catch (err) {
    console.error('Booking patch error:', err);
    return jsonResponse({ success: false, error: 'Failed to update booking' }, 500);
  }
}

export async function onRequestGet(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const bookingId = context.params.id;
    const booking = await context.env.DB.prepare(`
      SELECT
        b.*,
        u_client.display_name as client_name,
        u_artist.display_name as artist_name,
        u_artist.profile_picture_url as artist_image,
        s.name as service_name
      FROM bookings b
      JOIN users u_client ON b.client_id = u_client.id
      JOIN artist_profiles ap ON b.artist_id = ap.id
      JOIN users u_artist ON ap.user_id = u_artist.id
      LEFT JOIN services s ON b.service_id = s.id
      WHERE b.id = ?
    `).bind(bookingId).first();

    if (!booking) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    const allowed = await canModifyBooking(context.env.DB, auth.user, booking);
    if (!allowed) {
      return jsonResponse({ success: false, error: 'Not allowed to view this booking' }, 403);
    }

    return jsonResponse({ success: true, data: booking });
  } catch (err) {
    console.error('Booking get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load booking' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
