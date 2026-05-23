// GET /api/conversations — booking-scoped message threads for current user
// POST /api/conversations — create/open thread by booking_id
import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from './auth-utils.js';

async function userArtistProfileId(db, userId) {
  const row = await db.prepare(
    `SELECT id FROM artist_profiles WHERE user_id = ?`
  ).bind(userId).first();
  return row?.id || null;
}

async function userCanAccessBooking(db, userId, bookingId) {
  const booking = await db.prepare(
    `SELECT client_id, artist_id FROM bookings WHERE id = ?`
  ).bind(bookingId).first();
  if (!booking) return false;
  if (booking.client_id === userId) return true;
  const artistProfileId = await userArtistProfileId(db, userId);
  return artistProfileId && booking.artist_id === artistProfileId;
}

export async function onRequestGet(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const artistProfileId = await userArtistProfileId(context.env.DB, auth.userId);

    const result = await context.env.DB.prepare(`
      SELECT
        b.id AS booking_id,
        b.event_date,
        b.status AS booking_status,
        u_client.display_name AS client_name,
        u_artist.display_name AS artist_name,
        u_artist.profile_picture_url AS artist_image,
        (
          SELECT content FROM messages m
          WHERE m.booking_id = b.id
          ORDER BY m.created_at DESC LIMIT 1
        ) AS last_message,
        (
          SELECT created_at FROM messages m
          WHERE m.booking_id = b.id
          ORDER BY m.created_at DESC LIMIT 1
        ) AS last_message_at,
        (
          SELECT COUNT(*) FROM messages m
          WHERE m.booking_id = b.id AND m.receiver_id = ? AND m.is_read = 0
        ) AS unread_count
      FROM bookings b
      JOIN users u_client ON b.client_id = u_client.id
      JOIN artist_profiles ap ON b.artist_id = ap.id
      JOIN users u_artist ON ap.user_id = u_artist.id
      WHERE b.client_id = ? OR ap.user_id = ?
      ORDER BY COALESCE(last_message_at, b.created_at) DESC
      LIMIT 50
    `).bind(auth.userId, auth.userId, auth.userId).all();

    const conversations = (result.results || []).map(function(row) {
      return {
        id: row.booking_id,
        booking_id: row.booking_id,
        artist_name: row.artist_name,
        artist_image: row.artist_image,
        client_name: row.client_name,
        last_message: row.last_message || 'No messages yet',
        timestamp: row.last_message_at || row.event_date,
        unread: Number(row.unread_count || 0),
        booking_status: row.booking_status,
      };
    });

    return jsonResponse({ success: true, data: conversations });
  } catch (err) {
    console.error('Conversations list error:', err);
    return jsonResponse({ success: false, error: 'Failed to load conversations' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const bookingId = String(body.booking_id || '').trim();
    if (!bookingId) {
      return jsonResponse({ success: false, error: 'booking_id is required' }, 400);
    }

    const allowed = await userCanAccessBooking(context.env.DB, auth.userId, bookingId);
    if (!allowed) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    return jsonResponse({ success: true, data: { booking_id: bookingId } });
  } catch (err) {
    console.error('Conversation open error:', err);
    return jsonResponse({ success: false, error: 'Failed to open conversation' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
