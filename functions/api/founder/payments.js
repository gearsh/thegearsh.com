import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureMarketplaceTables } from '../db-schema.js';
import { ARTIST_FEE_RATE } from '../payfast-utils.js';

export function reconciliationRow(row) {
  const cents = (value) => Math.round(Number(value || 0) * 100);
  const gross = cents(row.amount);
  const subtotal = cents(row.total_price);
  const artistFee = Math.round(subtotal * ARTIST_FEE_RATE);
  const recordedRefund = cents(row.recorded_refund);
  const recordedRelease = cents(row.recorded_release);
  return {
    booking_id: row.booking_id,
    payment_id: row.payment_id,
    payfast_payment_id: row.payfast_payment_id,
    booking_status: row.booking_status,
    gross_collected: gross / 100,
    artist_share_if_fully_payable: Math.max(0, subtotal - artistFee) / 100,
    ledger_refund: recordedRefund / 100,
    ledger_release: recordedRelease / 100,
    gross_less_recorded_refunds_and_transfers: Math.max(0, gross - recordedRefund - recordedRelease) / 100,
    requires_external_verification: true,
  };
}

export async function onRequestGet(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const result = await context.env.DB.prepare(`
      SELECT
        p.*,
        b.event_date,
        b.status AS booking_status,
        u.display_name AS client_name
      FROM payments p
      JOIN bookings b ON p.booking_id = b.id
      JOIN users u ON b.client_id = u.id
      ORDER BY p.created_at DESC
      LIMIT 100
    `).all();

    const escrow = await context.env.DB.prepare(`
      SELECT event_type, SUM(amount) AS total
      FROM escrow_ledger
      GROUP BY event_type
    `).all();

    // An internal ledger cannot prove an external refund or bank transfer.
    // This queue gives operations the PayFast ID and amounts to reconcile to
    // processor statements and beneficiary bank evidence outside the app.
    const outstanding = await context.env.DB.prepare(`
      SELECT p.id AS payment_id, p.booking_id, p.payfast_payment_id,
             p.amount, b.total_price, b.status AS booking_status,
             COALESCE(SUM(CASE WHEN e.event_type IN ('refund', 'partial_refund') THEN e.amount ELSE 0 END), 0) AS recorded_refund,
             COALESCE(SUM(CASE WHEN e.event_type = 'release' THEN e.amount ELSE 0 END), 0) AS recorded_release
      FROM payments p JOIN bookings b ON b.id = p.booking_id
      LEFT JOIN escrow_ledger e ON e.payment_id = p.id
      WHERE p.status = 'complete'
      GROUP BY p.id, p.booking_id, p.payfast_payment_id, p.amount, b.total_price, b.status
      ORDER BY p.created_at DESC LIMIT 100
    `).all();

    return jsonResponse({
      success: true,
      data: {
        payments: result.results || [],
        escrow_summary: escrow.results || [],
        reconciliation_queue: (outstanding.results || []).map(reconciliationRow),
      },
    });
  } catch (err) {
    console.error('Founder payments error:', err);
    return jsonResponse({ success: false, error: 'Failed to load payments' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
