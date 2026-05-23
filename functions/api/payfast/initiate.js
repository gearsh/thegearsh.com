// POST /api/payfast/initiate — server-side PayFast payment params
import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from '../auth-utils.js';
import { ensureMarketplaceTables } from '../db-schema.js';
import {
  getPayfastConfig,
  buildSignature,
  PLATFORM_FEE_RATE,
} from '../payfast-utils.js';

export async function onRequestPost(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const bookingId = String(body.booking_id || '').trim();
    if (!bookingId) {
      return jsonResponse({ success: false, error: 'booking_id is required' }, 400);
    }

    const booking = await context.env.DB.prepare(`
      SELECT b.*, u.email, u.first_name, u.last_name, u.display_name
      FROM bookings b
      JOIN users u ON b.client_id = u.id
      WHERE b.id = ?
    `).bind(bookingId).first();

    if (!booking) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    if (booking.client_id !== auth.userId) {
      return jsonResponse({ success: false, error: 'Not your booking' }, 403);
    }

    const config = getPayfastConfig(context.env);
    const subtotal = Number(booking.total_price || 0);
    const serviceFee = Math.round(subtotal * PLATFORM_FEE_RATE * 100) / 100;
    const amount = Math.round((subtotal + serviceFee) * 100) / 100;
    const origin = new URL(context.request.url).origin;

    const paymentData = {
      merchant_id: config.merchantId,
      merchant_key: config.merchantKey,
      return_url: body.return_url || `${origin}/my-bookings`,
      cancel_url: body.cancel_url || `${origin}/booking-flow/${booking.artist_id}`,
      notify_url: `${origin}/api/payfast/notify`,
      name_first: booking.first_name || 'Client',
      name_last: booking.last_name || 'User',
      email_address: booking.email,
      m_payment_id: bookingId,
      amount: amount.toFixed(2),
      item_name: body.item_name || `Gearsh booking ${bookingId}`,
      item_description: body.item_description || booking.event_location || 'Artist booking',
    };

    paymentData.signature = buildSignature(paymentData, config.passphrase);

    const paymentId = `pay_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO payments (id, booking_id, amount, platform_fee, status, currency, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'pending', 'ZAR', ?, ?)
    `).bind(paymentId, bookingId, amount, serviceFee, now, now).run();

    await context.env.DB.prepare(`
      INSERT INTO escrow_ledger (id, booking_id, payment_id, event_type, amount, note, created_by, created_at)
      VALUES (?, ?, ?, 'hold', ?, 'Payment initiated', ?, ?)
    `).bind(
      `escrow_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
      bookingId,
      paymentId,
      amount,
      auth.userId,
      now
    ).run();

    return jsonResponse({
      success: true,
      data: {
        payment_id: paymentId,
        process_url: config.processUrl,
        fields: paymentData,
        amount,
        platform_fee: serviceFee,
      },
    });
  } catch (err) {
    console.error('PayFast initiate error:', err);
    return jsonResponse({ success: false, error: 'Failed to initiate payment' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
