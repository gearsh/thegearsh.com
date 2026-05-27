// GET /api/my-tickets — buyer's digital tickets

import { parseToken, jsonResponse, corsPreflightResponse, unauthorizedResponse } from './auth-utils.js';
import { ensureTicketsTables } from './tickets-schema.js';

export async function onRequestGet(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    await ensureTicketsTables(context.env.DB);

    const url = new URL(context.request.url);
    const email = url.searchParams.get('email');

    let buyerClause = 'o.buyer_user_id = ?';
    const binds = [userId];
    if (email) {
      buyerClause = '(o.buyer_user_id = ? OR LOWER(o.buyer_email) = LOWER(?))';
      binds.push(String(email).trim());
    }

    const rows = await context.env.DB.prepare(`
      SELECT ti.id, ti.ticket_code, ti.status, ti.qr_payload, ti.checked_in_at,
             tt.name AS tier_name, tt.tier_kind,
             e.id AS event_id, e.title, e.slug, e.starts_at, e.venue, e.city, e.flyer_url,
             u.display_name AS artist_name, u.username AS artist_username,
             o.id AS order_id, o.paid_at
      FROM ticket_instances ti
      JOIN ticket_orders o ON o.id = ti.order_id
      JOIN gig_events e ON e.id = ti.event_id
      JOIN gig_ticket_types tt ON tt.id = ti.ticket_type_id
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE o.status = 'paid' AND ${buyerClause}
      ORDER BY e.starts_at ASC, ti.created_at ASC
    `).bind(...binds).all();

    const tickets = (rows.results || []).map(function(row) {
      return {
        id: row.id,
        ticket_code: row.ticket_code,
        status: row.status,
        tier_name: row.tier_name,
        tier_kind: row.tier_kind,
        checked_in_at: row.checked_in_at,
        qr_payload: row.qr_payload,
        url: '/ticket/' + row.ticket_code,
        event: {
          id: row.event_id,
          title: row.title,
          slug: row.slug,
          starts_at: row.starts_at,
          venue: row.venue,
          city: row.city,
          flyer_url: row.flyer_url,
          artist_name: row.artist_name,
          artist_username: row.artist_username,
          url: '/gig/' + row.slug,
        },
        order_id: row.order_id,
        paid_at: row.paid_at,
      };
    });

    return jsonResponse({ success: true, data: { tickets } });
  } catch (err) {
    console.error('My tickets GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load tickets' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
