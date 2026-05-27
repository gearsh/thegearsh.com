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

async function handleBookingNotify(db, bookingId, paymentStatus, payfastPaymentId, payload) {
  const now = new Date().toISOString();
  const amount = Number(payload.amount_gross || payload.amount || 0);

  const payment = await db.prepare(`
    SELECT id, status FROM payments WHERE booking_id = ? ORDER BY created_at DESC LIMIT 1
  `).bind(bookingId).first();

  if (payment && payment.status === 'complete') {
    return;
  }

  if (paymentStatus === 'COMPLETE') {
    if (payment) {
      await db.prepare(`
        UPDATE payments
        SET status = 'complete', payfast_payment_id = ?, raw_payload = ?, updated_at = ?
        WHERE id = ?
      `).bind(payfastPaymentId, JSON.stringify(payload), now, payment.id).run();
    }

    await db.prepare(`
      UPDATE bookings SET status = 'confirmed', updated_at = ? WHERE id = ? AND status = 'pending'
    `).bind(now, bookingId).run();
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
      await handleBookingNotify(context.env.DB, paymentRef, paymentStatus, payfastPaymentId, payload);
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
