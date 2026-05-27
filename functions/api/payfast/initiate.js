// POST /api/payfast/initiate — server-side PayFast payment params
import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
  parseToken,
} from '../auth-utils.js';
import { ensureMarketplaceTables } from '../db-schema.js';
import { ensureTicketsTables } from '../tickets-schema.js';
import {
  getPayfastConfig,
  buildSignature,
  PLATFORM_FEE_RATE,
} from '../payfast-utils.js';
import { newId, expireStaleOrders } from '../tickets-utils.js';

async function initiateBookingPayment(context, auth, body) {
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

  const paymentId = newId('pay');
  const now = new Date().toISOString();

  await context.env.DB.prepare(`
    INSERT INTO payments (id, booking_id, amount, platform_fee, status, currency, created_at, updated_at)
    VALUES (?, ?, ?, ?, 'pending', 'ZAR', ?, ?)
  `).bind(paymentId, bookingId, amount, serviceFee, now, now).run();

  await context.env.DB.prepare(`
    INSERT INTO escrow_ledger (id, booking_id, payment_id, event_type, amount, note, created_by, created_at)
    VALUES (?, ?, ?, 'hold', ?, 'Payment initiated', ?, ?)
  `).bind(
    newId('escrow'),
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
}

async function initiateTicketPayment(context, body) {
  await ensureTicketsTables(context.env.DB);
  await expireStaleOrders(context.env.DB);

  const orderId = String(body.ticket_order_id || '').trim();
  if (!orderId) {
    return jsonResponse({ success: false, error: 'ticket_order_id is required' }, 400);
  }

  const order = await context.env.DB.prepare(`
    SELECT o.*, e.title AS event_title, e.slug AS event_slug
    FROM ticket_orders o
    JOIN gig_events e ON e.id = o.event_id
    WHERE o.id = ?
  `).bind(orderId).first();

  if (!order) {
    return jsonResponse({ success: false, error: 'Order not found' }, 404);
  }

  if (order.status !== 'pending_payment') {
    return jsonResponse({ success: false, error: 'Order is no longer payable' }, 400);
  }

  if (order.expires_at && order.expires_at < new Date().toISOString()) {
    return jsonResponse({ success: false, error: 'Order expired. Please start again.' }, 410);
  }

  const authUserId = await parseToken(context.request.headers.get('Authorization'), context.env);
  if (authUserId && authUserId !== order.buyer_user_id) {
    return jsonResponse({ success: false, error: 'Not your order' }, 403);
  }

  const config = getPayfastConfig(context.env);
  const amount = Number(order.total || 0);
  const origin = new URL(context.request.url).origin;
  const nameParts = String(order.buyer_name || 'Guest Fan').trim().split(/\s+/);

  const paymentData = {
    merchant_id: config.merchantId,
    merchant_key: config.merchantKey,
    return_url: body.return_url || `${origin}/ticket-success?order=${orderId}`,
    cancel_url: body.cancel_url || `${origin}/gig/${order.event_slug}`,
    notify_url: `${origin}/api/payfast/notify`,
    name_first: nameParts[0] || 'Guest',
    name_last: nameParts.slice(1).join(' ') || 'Fan',
    email_address: order.buyer_email,
    m_payment_id: orderId,
    amount: amount.toFixed(2),
    item_name: body.item_name || `Tickets: ${order.event_title}`,
    item_description: body.item_description || 'Gearsh event tickets',
  };

  paymentData.signature = buildSignature(paymentData, config.passphrase);

  const paymentId = newId('tpay');
  const now = new Date().toISOString();

  await context.env.DB.prepare(`
    INSERT INTO ticket_payments (id, ticket_order_id, amount, platform_fee, status, currency, created_at, updated_at)
    VALUES (?, ?, ?, ?, 'pending', ?, ?, ?)
  `).bind(
    paymentId,
    orderId,
    amount,
    Number(order.platform_fee || 0),
    order.currency || 'ZAR',
    now,
    now
  ).run();

  return jsonResponse({
    success: true,
    data: {
      payment_id: paymentId,
      process_url: config.processUrl,
      fields: paymentData,
      amount,
      platform_fee: Number(order.platform_fee || 0),
      order_id: orderId,
    },
  });
}

export async function onRequestPost(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const body = await context.request.json();

    if (body.ticket_order_id) {
      return initiateTicketPayment(context, body);
    }

    const auth = await requireAuth(context);
    if (auth.error) return auth.error;
    return initiateBookingPayment(context, auth, body);
  } catch (err) {
    console.error('PayFast initiate error:', err);
    return jsonResponse({ success: false, error: 'Failed to initiate payment' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
