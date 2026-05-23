// POST /api/payfast/notify — PayFast ITN webhook
import { jsonResponse } from '../auth-utils.js';
import { ensureMarketplaceTables } from '../db-schema.js';
import {
  getPayfastConfig,
  verifyPayfastSignature,
  validateItnWithPayfast,
  parseFormBody,
} from '../payfast-utils.js';

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

    const bookingId = String(payload.m_payment_id || '');
    const paymentStatus = String(payload.payment_status || '').toUpperCase();
    const payfastPaymentId = String(payload.pf_payment_id || '');

    if (!bookingId) {
      return new Response('OK', { status: 200 });
    }

    const now = new Date().toISOString();
    const amount = Number(payload.amount_gross || payload.amount || 0);

    const payment = await context.env.DB.prepare(`
      SELECT id, status FROM payments WHERE booking_id = ? ORDER BY created_at DESC LIMIT 1
    `).bind(bookingId).first();

    if (payment && payment.status === 'complete') {
      return new Response('OK', { status: 200 });
    }

    if (paymentStatus === 'COMPLETE') {
      if (payment) {
        await context.env.DB.prepare(`
          UPDATE payments
          SET status = 'complete', payfast_payment_id = ?, raw_payload = ?, updated_at = ?
          WHERE id = ?
        `).bind(payfastPaymentId, JSON.stringify(payload), now, payment.id).run();
      }

      await context.env.DB.prepare(`
        UPDATE bookings SET status = 'confirmed', updated_at = ? WHERE id = ? AND status = 'pending'
      `).bind(now, bookingId).run();
    } else if (paymentStatus === 'FAILED' || paymentStatus === 'CANCELLED') {
      if (payment) {
        await context.env.DB.prepare(`
          UPDATE payments SET status = 'failed', raw_payload = ?, updated_at = ? WHERE id = ?
        `).bind(JSON.stringify(payload), now, payment.id).run();
      }
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
