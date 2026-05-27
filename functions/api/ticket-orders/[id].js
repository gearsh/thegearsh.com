// GET /api/ticket-orders/:id — order status + tickets when paid

import { parseToken, jsonResponse, corsPreflightResponse, unauthorizedResponse } from '../auth-utils.js';
import { ensureTicketsTables } from '../tickets-schema.js';
import { expireStaleOrders } from '../tickets-utils.js';

export async function onRequestGet(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    await expireStaleOrders(context.env.DB);

    const orderId = context.params.id;
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);

    const order = await context.env.DB.prepare(`
      SELECT o.*, e.title AS event_title, e.slug AS event_slug, e.starts_at, e.venue, e.city,
             e.flyer_url, u.username AS artist_username, u.display_name AS artist_name
      FROM ticket_orders o
      JOIN gig_events e ON e.id = o.event_id
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE o.id = ?
    `).bind(orderId).first();

    if (!order) {
      return jsonResponse({ success: false, error: 'Order not found' }, 404);
    }

    const url = new URL(context.request.url);
    const publicToken = url.searchParams.get('token');
    const isOwner = userId && userId === order.buyer_user_id;

    if (!isOwner && publicToken !== orderId.slice(-8)) {
      if (!userId) return unauthorizedResponse();
      const artist = await context.env.DB.prepare(`
        SELECT ap.id FROM artist_profiles ap
        JOIN gig_events e ON e.artist_id = ap.id
        WHERE ap.user_id = ? AND e.id = ?
      `).bind(userId, order.event_id).first();
      if (!artist) return jsonResponse({ success: false, error: 'Not authorized' }, 403);
    }

    const items = await context.env.DB.prepare(`
      SELECT oi.*, tt.name AS tier_name, tt.tier_kind
      FROM ticket_order_items oi
      JOIN gig_ticket_types tt ON tt.id = oi.ticket_type_id
      WHERE oi.order_id = ?
    `).bind(orderId).all();

    let tickets = [];
    if (order.status === 'paid') {
      const ticketRows = await context.env.DB.prepare(`
        SELECT ti.*, tt.name AS tier_name
        FROM ticket_instances ti
        JOIN gig_ticket_types tt ON tt.id = ti.ticket_type_id
        WHERE ti.order_id = ?
        ORDER BY ti.created_at ASC
      `).bind(orderId).all();
      tickets = (ticketRows.results || []).map(function(t) {
        return {
          id: t.id,
          ticket_code: t.ticket_code,
          tier_name: t.tier_name,
          status: t.status,
          qr_payload: t.qr_payload,
          url: '/ticket/' + t.ticket_code,
        };
      });
    }

    return jsonResponse({
      success: true,
      data: {
        order: {
          id: order.id,
          status: order.status,
          subtotal: Number(order.subtotal),
          discount: Number(order.discount),
          platform_fee: Number(order.platform_fee),
          total: Number(order.total),
          currency: order.currency,
          buyer_name: order.buyer_name,
          buyer_email: order.buyer_email,
          expires_at: order.expires_at,
          paid_at: order.paid_at,
          event: {
            id: order.event_id,
            title: order.event_title,
            slug: order.event_slug,
            starts_at: order.starts_at,
            venue: order.venue,
            city: order.city,
            flyer_url: order.flyer_url,
            artist_name: order.artist_name,
            artist_username: order.artist_username,
            url: '/gig/' + order.event_slug,
          },
          items: (items.results || []).map(function(i) {
            return {
              ticket_type_id: i.ticket_type_id,
              tier_name: i.tier_name,
              tier_kind: i.tier_kind,
              quantity: i.quantity,
              unit_price: Number(i.unit_price),
              line_total: Number(i.line_total),
            };
          }),
          tickets,
        },
      },
    });
  } catch (err) {
    console.error('Ticket order GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load order' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
