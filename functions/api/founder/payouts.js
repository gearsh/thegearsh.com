// Founder-only record of an external bank transfer and its reconciliation.
// This endpoint never sends money. Bank transfer execution happens outside Gearsh.
import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureMarketplaceTables } from '../db-schema.js';
import { ARTIST_FEE_RATE } from '../payfast-utils.js';

export function payoutEligibility(row) {
  if (!row || row.payment_status !== 'complete' || row.booking_status !== 'completed') return null;
  if (!row.payfast_payment_id || Number(row.disputes || 0) > 0 || Number(row.refunds || 0) > 0 ||
      Number(row.holds || 0) < Number(row.payment_amount || 0) - 0.005) return null;
  const subtotalCents = Math.round(Number(row.total_price) * 100);
  if (!Number.isSafeInteger(subtotalCents) || subtotalCents <= 0) return null;
  return (subtotalCents - Math.round(subtotalCents * ARTIST_FEE_RATE)) / 100;
}

async function getPayoutContext(db, paymentId) {
  return db.prepare(`
    SELECT p.id AS payment_id, p.booking_id, p.amount AS payment_amount,
           p.status AS payment_status, p.payfast_payment_id,
           b.status AS booking_status, b.total_price,
           (SELECT COUNT(*) FROM disputes d WHERE d.booking_id = b.id
              AND d.status IN ('open', 'investigating')) AS disputes,
           (SELECT COALESCE(SUM(amount), 0) FROM escrow_ledger e WHERE e.payment_id = p.id
              AND e.event_type = 'hold') AS holds,
           (SELECT COALESCE(SUM(amount), 0) FROM escrow_ledger e WHERE e.payment_id = p.id
              AND e.event_type IN ('refund', 'partial_refund')) AS refunds
    FROM payments p JOIN bookings b ON b.id = p.booking_id WHERE p.id = ?
  `).bind(paymentId).first();
}

export async function onRequestGet(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;
    const result = await context.env.DB.prepare(`
      SELECT id, payment_id, booking_id, amount, payfast_settlement_reference,
             bank_transfer_reference, beneficiary_last4, status, bank_statement_reference,
             recorded_by, reconciled_by, created_at, reconciled_at
      FROM payout_reconciliations ORDER BY created_at DESC LIMIT 100
    `).all();
    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Payout reconciliation read error:', err);
    return jsonResponse({ success: false, error: 'Failed to load payout records' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;
    const body = await context.request.json();
    const paymentId = String(body.payment_id || '').trim();
    const settlementRef = String(body.payfast_settlement_reference || '').trim();
    const transferRef = String(body.bank_transfer_reference || '').trim();
    const last4 = String(body.beneficiary_last4 || '').trim();
    if (!paymentId || !settlementRef || !transferRef || !/^\d{4}$/.test(last4) ||
        settlementRef.length > 120 || transferRef.length > 120) {
      return jsonResponse({ success: false, error: 'Payment, PayFast settlement, bank transfer reference and beneficiary last four digits required' }, 400);
    }
    const row = await getPayoutContext(context.env.DB, paymentId);
    const amount = payoutEligibility(row);
    if (amount === null) {
      return jsonResponse({ success: false, error: 'Booking has no verified payable amount or has an open dispute or refund' }, 409);
    }
    const now = new Date().toISOString();
    const result = await context.env.DB.prepare(`
      INSERT OR IGNORE INTO payout_reconciliations
      (id, payment_id, booking_id, amount, payfast_settlement_reference,
       bank_transfer_reference, beneficiary_last4, status, recorded_by, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'awaiting_bank_statement', ?, ?)
    `).bind(`pout_${paymentId}`, paymentId, row.booking_id, amount, settlementRef,
      transferRef, last4, auth.user.id, now).run();
    if (!result.meta?.changes) {
      return jsonResponse({ success: false, error: 'Payment or bank transfer reference already recorded' }, 409);
    }
    return jsonResponse({ success: true, data: { payment_id: paymentId, amount, status: 'awaiting_bank_statement' } }, 201);
  } catch (err) {
    console.error('Payout record error:', err);
    return jsonResponse({ success: false, error: 'Failed to record payout evidence' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;
    const body = await context.request.json();
    const paymentId = String(body.payment_id || '').trim();
    const statementRef = String(body.bank_statement_reference || '').trim();
    if (!paymentId || !statementRef || statementRef.length > 120) {
      return jsonResponse({ success: false, error: 'Payment ID and bank statement reference required' }, 400);
    }
    const record = await context.env.DB.prepare(`
      SELECT * FROM payout_reconciliations WHERE payment_id = ?
    `).bind(paymentId).first();
    if (!record || record.status !== 'awaiting_bank_statement') {
      return jsonResponse({ success: false, error: 'No pending bank transfer to reconcile' }, 409);
    }
    const row = await getPayoutContext(context.env.DB, paymentId);
    if (payoutEligibility(row) !== Number(record.amount)) {
      return jsonResponse({ success: false, error: 'Booking is no longer eligible for reconciliation' }, 409);
    }
    const now = new Date().toISOString();
    await context.env.DB.batch([
      context.env.DB.prepare(`
        UPDATE payout_reconciliations SET status = 'reconciled', bank_statement_reference = ?,
               reconciled_by = ?, reconciled_at = ? WHERE payment_id = ? AND status = 'awaiting_bank_statement'
      `).bind(statementRef, auth.user.id, now, paymentId),
      context.env.DB.prepare(`
        INSERT INTO escrow_ledger (id, booking_id, payment_id, event_type, amount, note, created_by, created_at)
        VALUES (?, ?, ?, 'release', ?, ?, ?, ?)
      `).bind(`escrow_payout_${paymentId}`, record.booking_id, paymentId, record.amount,
        `Bank transfer ${record.bank_transfer_reference}; statement ${statementRef}`, auth.user.id, now),
    ]);
    return jsonResponse({ success: true, data: { payment_id: paymentId, status: 'reconciled', amount: record.amount } });
  } catch (err) {
    console.error('Payout reconciliation error:', err);
    return jsonResponse({ success: false, error: 'Failed to reconcile bank transfer' }, 500);
  }
}

export async function onRequestOptions() { return corsPreflightResponse(); }
