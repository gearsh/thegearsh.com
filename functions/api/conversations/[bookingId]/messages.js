// GET/POST /api/conversations/:bookingId/messages
import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from '../../auth-utils.js';
import { guardMessage, leakageNudge } from '../../message-guard.js';

// A booking's deal is locked-in once it's paid (PayFast notify sets 'confirmed').
const BOOKING_UNLOCKED_STATUSES = new Set(['confirmed', 'completed', 'in_progress', 'paid']);
function bookingContactUnlocked(status) {
  return BOOKING_UNLOCKED_STATUSES.has(String(status || ''));
}

async function userArtistProfileId(db, userId) {
  const row = await db.prepare(
    `SELECT id FROM artist_profiles WHERE user_id = ?`
  ).bind(userId).first();
  return row?.id || null;
}

async function getBookingParticipants(db, bookingId) {
  return db.prepare(`
    SELECT b.client_id, b.status, ap.user_id AS artist_user_id
    FROM bookings b
    JOIN artist_profiles ap ON b.artist_id = ap.id
    WHERE b.id = ?
  `).bind(bookingId).first();
}

async function userCanAccessBooking(db, userId, bookingId) {
  const booking = await getBookingParticipants(db, bookingId);
  if (!booking) return null;
  if (booking.client_id === userId) return booking;
  if (booking.artist_user_id === userId) return booking;
  return null;
}

export async function onRequestGet(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const bookingId = context.params.bookingId;
    const booking = await userCanAccessBooking(context.env.DB, auth.userId, bookingId);
    if (!booking) {
      return jsonResponse({ success: false, error: 'Conversation not found' }, 404);
    }

    const result = await context.env.DB.prepare(`
      SELECT
        m.id,
        m.sender_id,
        m.receiver_id,
        m.content,
        m.is_read,
        m.created_at,
        u.display_name AS sender_name
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.booking_id = ?
      ORDER BY m.created_at ASC
      LIMIT 200
    `).bind(bookingId).all();

    await context.env.DB.prepare(`
      UPDATE messages SET is_read = 1
      WHERE booking_id = ? AND receiver_id = ?
    `).bind(bookingId, auth.userId).run();

    const messages = (result.results || []).map(function(row) {
      return {
        id: row.id,
        sender: row.sender_id === auth.userId ? 'me' : 'them',
        sender_id: row.sender_id,
        text: row.content,
        timestamp: row.created_at,
        sender_name: row.sender_name,
        is_read: Boolean(row.is_read),
      };
    });

    return jsonResponse({ success: true, data: messages });
  } catch (err) {
    console.error('Messages get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load messages' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const bookingId = context.params.bookingId;
    const booking = await userCanAccessBooking(context.env.DB, auth.userId, bookingId);
    if (!booking) {
      return jsonResponse({ success: false, error: 'Conversation not found' }, 404);
    }

    const body = await context.request.json();
    const rawContent = String(body.content || body.text || '').trim();
    if (!rawContent) {
      return jsonResponse({ success: false, error: 'Message content is required' }, 400);
    }

    // Anti-leakage: hide contact/payment details until the booking is paid on Gearsh.
    const unlocked = bookingContactUnlocked(booking.status);
    const guard = guardMessage(rawContent, unlocked);
    const content = guard.text;

    const receiverId = auth.userId === booking.client_id
      ? booking.artist_user_id
      : booking.client_id;

    const messageId = `msg_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO messages (id, sender_id, receiver_id, booking_id, content, is_read, created_at)
      VALUES (?, ?, ?, ?, ?, 0, ?)
    `).bind(messageId, auth.userId, receiverId, bookingId, content, now).run();

    return jsonResponse({
      success: true,
      data: {
        id: messageId,
        sender: 'me',
        text: content,
        timestamp: now,
      },
      redacted: guard.redacted,
      notice: guard.redacted ? leakageNudge(guard.reasons) : '',
      contact_unlocked: unlocked,
    }, 201);
  } catch (err) {
    console.error('Messages post error:', err);
    return jsonResponse({ success: false, error: 'Failed to send message' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
