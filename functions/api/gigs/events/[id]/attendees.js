// GET /api/gigs/events/:id/attendees — artist check-in list + CSV export
// POST check-in via ?ticket_code=

import { parseToken, jsonResponse, corsPreflightResponse, unauthorizedResponse } from '../../../auth-utils.js';
import { ensureTicketsTables } from '../../../tickets-schema.js';

export async function onRequestGet(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    await ensureTicketsTables(context.env.DB);
    const eventId = context.params.id;

    const event = await context.env.DB.prepare(`
      SELECT e.*, ap.user_id AS owner_user_id
      FROM gig_events e
      JOIN artist_profiles ap ON ap.id = e.artist_id
      WHERE e.id = ?
    `).bind(eventId).first();

    if (!event || event.owner_user_id !== userId) {
      return jsonResponse({ success: false, error: 'Not authorized' }, 403);
    }

    const url = new URL(context.request.url);
    const format = url.searchParams.get('format');

    const rows = await context.env.DB.prepare(`
      SELECT ti.ticket_code, ti.holder_name, ti.holder_email, ti.status, ti.checked_in_at,
             tt.name AS tier_name, o.paid_at, o.buyer_phone
      FROM ticket_instances ti
      JOIN ticket_orders o ON o.id = ti.order_id
      JOIN gig_ticket_types tt ON tt.id = ti.ticket_type_id
      WHERE ti.event_id = ? AND o.status = 'paid'
      ORDER BY o.paid_at DESC
    `).bind(eventId).all();

    const attendees = (rows.results || []).map(function(r) {
      return {
        ticket_code: r.ticket_code,
        holder_name: r.holder_name,
        holder_email: r.holder_email,
        tier_name: r.tier_name,
        status: r.status,
        checked_in: Boolean(r.checked_in_at),
        checked_in_at: r.checked_in_at,
        paid_at: r.paid_at,
        phone: r.buyer_phone,
      };
    });

    if (format === 'csv') {
      const header = 'ticket_code,name,email,tier,status,checked_in,paid_at,phone\n';
      const lines = attendees.map(function(a) {
        return [
          a.ticket_code,
          '"' + String(a.holder_name || '').replace(/"/g, '""') + '"',
          a.holder_email || '',
          a.tier_name || '',
          a.status,
          a.checked_in ? 'yes' : 'no',
          a.paid_at || '',
          a.phone || '',
        ].join(',');
      }).join('\n');
      return new Response(header + lines, {
        headers: {
          'Content-Type': 'text/csv; charset=utf-8',
          'Content-Disposition': 'attachment; filename="attendees-' + eventId + '.csv"',
        },
      });
    }

    const stats = {
      total: attendees.length,
      checked_in: attendees.filter(function(a) { return a.checked_in; }).length,
    };

    return jsonResponse({ success: true, data: { attendees, stats, event: { id: event.id, title: event.title } } });
  } catch (err) {
    console.error('Attendees GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load attendees' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    await ensureTicketsTables(context.env.DB);
    const eventId = context.params.id;
    const body = await context.request.json();
    const ticketCode = String(body.ticket_code || '').trim().toUpperCase();

    if (!ticketCode) {
      return jsonResponse({ success: false, error: 'ticket_code required' }, 400);
    }

    const event = await context.env.DB.prepare(`
      SELECT e.*, ap.user_id AS owner_user_id
      FROM gig_events e
      JOIN artist_profiles ap ON ap.id = e.artist_id
      WHERE e.id = ?
    `).bind(eventId).first();

    if (!event || event.owner_user_id !== userId) {
      return jsonResponse({ success: false, error: 'Not authorized' }, 403);
    }

    const ticket = await context.env.DB.prepare(`
      SELECT ti.* FROM ticket_instances ti
      JOIN ticket_orders o ON o.id = ti.order_id
      WHERE ti.ticket_code = ? AND ti.event_id = ? AND o.status = 'paid'
    `).bind(ticketCode, eventId).first();

    if (!ticket) {
      return jsonResponse({ success: false, error: 'Ticket not found' }, 404);
    }
    if (ticket.status === 'used' || ticket.checked_in_at) {
      return jsonResponse({ success: false, error: 'Ticket already checked in', data: { checked_in_at: ticket.checked_in_at } }, 409);
    }

    const now = new Date().toISOString();
    await context.env.DB.prepare(`
      UPDATE ticket_instances SET status = 'used', checked_in_at = ? WHERE id = ?
    `).bind(now, ticket.id).run();

    return jsonResponse({
      success: true,
      data: { ticket_code: ticketCode, checked_in_at: now, holder_name: ticket.holder_name },
    });
  } catch (err) {
    console.error('Check-in POST error:', err);
    return jsonResponse({ success: false, error: 'Check-in failed' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
