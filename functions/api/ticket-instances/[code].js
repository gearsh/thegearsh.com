// GET /api/ticket-instances/:code — public ticket view for QR / print

import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { ensureTicketsTables } from '../tickets-schema.js';

export async function onRequestGet(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    const code = String(context.params.code || '').trim().toUpperCase();

    const row = await context.env.DB.prepare(`
      SELECT ti.*, tt.name AS tier_name,
             e.title, e.slug, e.starts_at, e.venue, e.city, e.flyer_url,
             u.display_name AS artist_name, u.username AS artist_username,
             o.status AS order_status, o.paid_at
      FROM ticket_instances ti
      JOIN ticket_orders o ON o.id = ti.order_id
      JOIN gig_events e ON e.id = ti.event_id
      JOIN gig_ticket_types tt ON tt.id = ti.ticket_type_id
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE ti.ticket_code = ?
    `).bind(code).first();

    if (!row || row.order_status !== 'paid') {
      return jsonResponse({ success: false, error: 'Ticket not found' }, 404);
    }

    return jsonResponse({
      success: true,
      data: {
        ticket: {
          ticket_code: row.ticket_code,
          status: row.status,
          tier_name: row.tier_name,
          holder_name: row.holder_name,
          qr_payload: row.qr_payload,
          checked_in_at: row.checked_in_at,
          event: {
            title: row.title,
            slug: row.slug,
            starts_at: row.starts_at,
            venue: row.venue,
            city: row.city,
            flyer_url: row.flyer_url,
            artist_name: row.artist_name,
            artist_username: row.artist_username,
          },
          paid_at: row.paid_at,
        },
      },
    });
  } catch (err) {
    console.error('Ticket instance GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load ticket' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
