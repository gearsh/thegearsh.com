// POST /api/payfast/notify — PayFast ITN webhook
import { jsonResponse } from '../auth-utils.js';
import { ensureMarketplaceTables } from '../db-schema.js';
import { ensureTicketsTables } from '../tickets-schema.js';
import {
  getPayfastConfig,
  verifyPayfastSignature,
  validateItnWithPayfast,
  parseFormBody,
} from '../payfast-utils.js';
import { fulfillTicketOrder, cancelTicketOrder } from '../tickets-utils.js';

function isTicketOrderId(id) {
  return String(id || '').startsWith('tord_');
}

async function handleTicketNotify(db, orderId, paymentStatus, payfastPaymentId, payload) {
  await ensureTicketsTables(db);

  if (paymentStatus === 'COMPLETE') {
    await fulfillTicketOrder(db, orderId, payfastPaymentId, payload);
    return;
  }

  if (paymentStatus === 'FAILED' || paymentStatus === 'CANCELLED') {
    const payment = await db.prepare(`
      SELECT id FROM ticket_payments WHERE ticket_order_id = ? ORDER BY created_at DESC LIMIT 1
    `).bind(orderId).first();

    const now = new Date().toISOString();
    if (payment) {
      await db.prepare(`
        UPDATE ticket_payments SET status = 'failed', raw_payload = ?, updated_at = ? WHERE id = ?
      `).bind(JSON.stringify(payload), now, payment.id).run();
    }
    await cancelTicketOrder(db, orderId);
  }
}

export function matchesBookingPayment(payment, payload, merchantId) {
  const paidCents = Math.round(Number(payload.amount_gross) * 100);
  return payment && payment.status === 'pending' &&
    payload.merchant_id === merchantId &&
    Number.isFinite(paidCents) && paidCents > 0 &&
    paidCents === Math.round(Number(payment.amount) * 100);
}

export async function handleBookingNotify(db, paymentRef, paymentStatus, payfastPaymentId, payload, merchantId) {
  const now = new Date().toISOString();
  // Older checkouts used the booking ID as reference. New checkouts use the
  // unique payment ID so a delayed webhook cannot confirm a later attempt.
  const payment = await db.prepare(`
    SELECT id, booking_id, amount, status, payfast_payment_id FROM payments
    WHERE id = ? OR booking_id = ? ORDER BY created_at DESC LIMIT 1
  `).bind(paymentRef, paymentRef).first();

  if (payment && payment.status === 'complete' &&
      payment.payfast_payment_id === payfastPaymentId) {
    return;
  }
  if (!matchesBookingPayment(payment, payload, merchantId)) {
    throw new Error('Booking payment does not match pending amount or merchant');
  }
  const bookingId = payment.booking_id;

  if (paymentStatus === 'COMPLETE') {
    const prior = await db.prepare(`SELECT id FROM payments WHERE booking_id = ? AND status = 'complete' LIMIT 1`).bind(bookingId).first();
    if (prior) throw new Error('Booking already has a confirmed payment');
    const booking = await db.prepare(`SELECT status FROM bookings WHERE id = ?`).bind(bookingId).first();
    if (!booking || booking.status !== 'accepted') throw new Error('Booking is not payable');
    await db.batch([db.prepare(`
        UPDATE payments
        SET status = 'complete', payfast_payment_id = ?, raw_payload = ?, updated_at = ?
        WHERE id = ? AND status = 'pending'
      `).bind(payfastPaymentId, JSON.stringify(payload), now, payment.id), db.prepare(`
      INSERT INTO escrow_ledger (id, booking_id, payment_id, event_type, amount, note, created_by, created_at)
      VALUES (?, ?, ?, 'hold', ?, 'PayFast payment confirmed', ?, ?)
    `).bind(`escrow_${payment.id}`, bookingId, payment.id, payment.amount, bookingId, now), db.prepare(`
      UPDATE bookings SET status = 'confirmed', updated_at = ? WHERE id = ? AND status IN ('pending', 'accepted')
    `).bind(now, bookingId)]);
  } else if (paymentStatus === 'FAILED' || paymentStatus === 'CANCELLED') {
    if (payment) {
      await db.prepare(`
        UPDATE payments SET status = 'failed', raw_payload = ?, updated_at = ? WHERE id = ?
      `).bind(JSON.stringify(payload), now, payment.id).run();
    }
  }
}

export async function onRequestPost(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const rawBody = await context.request.text();
    const payload = parseFormBody(rawBody);
    const config = getPayfastConfig(context.env);

    if (!verifyPayfastSignature(payload, config.passphrase)) {
      console.error('PayFast ITN signature mismatch');
      return new Response('INVALID', { status: 400 });
    }

    const valid = await validateItnWithPayfast(context.env, rawBody);
    if (!valid) {
      console.error('PayFast ITN validation failed');
      return new Response('INVALID', { status: 400 });
    }

    const paymentRef = String(payload.m_payment_id || '');
    const paymentStatus = String(payload.payment_status || '').toUpperCase();
    const payfastPaymentId = String(payload.pf_payment_id || '');

    if (!paymentRef) {
      return new Response('OK', { status: 200 });
    }

    if (isTicketOrderId(paymentRef)) {
      await handleTicketNotify(context.env.DB, paymentRef, paymentStatus, payfastPaymentId, payload);
    } else {
      await handleBookingNotify(context.env.DB, paymentRef, paymentStatus, payfastPaymentId, payload, config.merchantId);
    }

    return new Response('OK', { status: 200 });
  } catch (err) {
    console.error('PayFast notify error:', err);
    return new Response('ERROR', { status: 500 });
  }
}

export async function onRequestGet() {
  return jsonResponse({ success: true, message: 'PayFast notify endpoint ready' });
}
