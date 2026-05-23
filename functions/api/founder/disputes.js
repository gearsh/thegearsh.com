import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureMarketplaceTables } from '../db-schema.js';

export async function onRequestGet(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const status = url.searchParams.get('status') || 'open';

    const result = await context.env.DB.prepare(`
      SELECT
        d.*,
        b.event_date,
        b.total_price,
        u.display_name AS reporter_name,
        u.email AS reporter_email
      FROM disputes d
      JOIN bookings b ON d.booking_id = b.id
      JOIN users u ON d.reporter_id = u.id
      WHERE d.status = ?
      ORDER BY d.created_at DESC
      LIMIT 100
    `).bind(status).all();

    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Founder disputes error:', err);
    return jsonResponse({ success: false, error: 'Failed to load disputes' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const disputeId = String(body.dispute_id || '').trim();
    const status = String(body.status || '').trim().toLowerCase();
    const resolutionNotes = String(body.resolution_notes || '').trim();

    if (!disputeId || !status) {
      return jsonResponse({ success: false, error: 'dispute_id and status required' }, 400);
    }

    const now = new Date().toISOString();
    await context.env.DB.prepare(`
      UPDATE disputes
      SET status = ?, resolution_notes = ?, assigned_to = ?, updated_at = ?
      WHERE id = ?
    `).bind(status, resolutionNotes || null, auth.user.id, now, disputeId).run();

    return jsonResponse({ success: true, data: { dispute_id: disputeId, status } });
  } catch (err) {
    console.error('Founder dispute patch error:', err);
    return jsonResponse({ success: false, error: 'Failed to update dispute' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
