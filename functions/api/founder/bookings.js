import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureMarketplaceTables } from '../db-schema.js';

export async function onRequestGet(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const status = url.searchParams.get('status');
    const limit = Math.min(Number(url.searchParams.get('limit') || 50), 200);

    let query = `
      SELECT
        b.*,
        u_client.display_name AS client_name,
        u_client.email AS client_email,
        u_artist.display_name AS artist_name,
        s.name AS service_name
      FROM bookings b
      JOIN users u_client ON b.client_id = u_client.id
      JOIN artist_profiles ap ON b.artist_id = ap.id
      JOIN users u_artist ON ap.user_id = u_artist.id
      LEFT JOIN services s ON b.service_id = s.id
      WHERE 1=1
    `;
    const params = [];
    if (status) {
      query += ` AND b.status = ?`;
      params.push(status);
    }
    query += ` ORDER BY b.created_at DESC LIMIT ?`;
    params.push(limit);

    const result = await context.env.DB.prepare(query).bind(...params).all();
    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Founder bookings error:', err);
    return jsonResponse({ success: false, error: 'Failed to load bookings' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const bookingId = String(body.booking_id || '').trim();
    const status = String(body.status || '').trim().toLowerCase();
    if (!bookingId || !status) {
      return jsonResponse({ success: false, error: 'booking_id and status required' }, 400);
    }

    const now = new Date().toISOString();
    await context.env.DB.prepare(
      `UPDATE bookings SET status = ?, updated_at = ? WHERE id = ?`
    ).bind(status, now, bookingId).run();

    return jsonResponse({ success: true, data: { booking_id: bookingId, status } });
  } catch (err) {
    console.error('Founder booking patch error:', err);
    return jsonResponse({ success: false, error: 'Failed to update booking' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
