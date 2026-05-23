import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureMarketplaceTables } from '../db-schema.js';

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

    return jsonResponse({
      success: true,
      data: {
        payments: result.results || [],
        escrow_summary: escrow.results || [],
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
