// GET /api/escrow/:bookingId — escrow ledger summary for a booking

import { corsPreflightResponse, jsonResponse, requireAuth } from '../auth-utils.js';
import { ensureMarketplaceTables } from '../db-schema.js';

async function getArtistProfileId(db, userId) {
  const row = await db.prepare(`SELECT id FROM artist_profiles WHERE user_id = ?`).bind(userId).first();
  return row?.id || null;
}

async function canViewEscrow(db, user, booking) {
  if (user.user_type === 'admin') return true;
  if (booking.client_id === user.id) return true;
  const artistProfileId = await getArtistProfileId(db, user.id);
  return artistProfileId && booking.artist_id === artistProfileId;
}

function computeEscrowStatus(ledger, payment) {
  if (!ledger.length && !payment) return 'pending';
  const holds = ledger.filter((e) => e.event_type === 'hold').reduce((s, e) => s + e.amount, 0);
  const releases = ledger.filter((e) => e.event_type === 'release').reduce((s, e) => s + e.amount, 0);
  const refunds = ledger.filter((e) => e.event_type === 'refund' || e.event_type === 'partial_refund')
    .reduce((s, e) => s + e.amount, 0);

  if (payment?.status === 'refunded' || refunds >= holds) return 'refunded';
  if (releases >= holds && holds > 0) return 'released';
  if (payment?.status === 'complete' || holds > 0) return 'funded';
  return 'pending';
}

export async function onRequestGet(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const bookingId = context.params.bookingId;
    const booking = await context.env.DB.prepare(
      `SELECT * FROM bookings WHERE id = ?`
    ).bind(bookingId).first();

    if (!booking) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    const allowed = await canViewEscrow(context.env.DB, auth.user, booking);
    if (!allowed) {
      return jsonResponse({ success: false, error: 'Not allowed to view escrow' }, 403);
    }

    const [ledgerResult, payment] = await Promise.all([
      context.env.DB.prepare(`
        SELECT * FROM escrow_ledger WHERE booking_id = ? ORDER BY created_at ASC
      `).bind(bookingId).all(),
      context.env.DB.prepare(`
        SELECT * FROM payments WHERE booking_id = ? ORDER BY created_at DESC LIMIT 1
      `).bind(bookingId).first(),
    ]);

    const ledger = ledgerResult.results || [];
    const held = ledger.filter((e) => e.event_type === 'hold').reduce((s, e) => s + Number(e.amount || 0), 0);
    const released = ledger.filter((e) => e.event_type === 'release').reduce((s, e) => s + Number(e.amount || 0), 0);
    const refunded = ledger.filter((e) => e.event_type === 'refund' || e.event_type === 'partial_refund')
      .reduce((s, e) => s + Number(e.amount || 0), 0);

    return jsonResponse({
      success: true,
      data: {
        booking_id: bookingId,
        booking_status: booking.status,
        currency: payment?.currency || 'ZAR',
        total_held: held,
        total_released: released,
        total_refunded: refunded,
        remaining: Math.max(0, held - released - refunded),
        status: computeEscrowStatus(ledger, payment),
        payment: payment || null,
        ledger,
      },
    });
  } catch (err) {
    console.error('Escrow read error:', err);
    return jsonResponse({ success: false, error: 'Failed to load escrow' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
