// GET /api/gigs/events/:slug — public event detail with ticket availability

import { parseToken, jsonResponse, corsPreflightResponse } from '../../auth-utils.js';
import { ensureTicketsTables } from '../../tickets-schema.js';
import {
  mapTicketTypeRow,
  mapPublicEvent,
  expireStaleOrders,
} from '../../tickets-utils.js';

export async function onRequestGet(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    await expireStaleOrders(context.env.DB);

    const slug = context.params.slug;
    if (!slug) {
      return jsonResponse({ success: false, error: 'Event not found' }, 404);
    }

    const row = await context.env.DB.prepare(`
      SELECT e.*, u.username, u.display_name AS artist_name, u.profile_picture_url, u.is_verified,
             ap.id AS profile_artist_id
      FROM gig_events e
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE e.slug = ?
    `).bind(slug).first();

    if (!row) {
      return jsonResponse({ success: false, error: 'Event not found' }, 404);
    }

    if (row.status === 'draft') {
      const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
      if (!userId || userId !== row.author_user_id) {
        return jsonResponse({ success: false, error: 'Event not found' }, 404);
      }
    }

    if (row.visibility === 'followers' && row.status !== 'draft') {
      const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
      if (!userId) {
        return jsonResponse({ success: false, error: 'Sign in to view this event' }, 403);
      }
      const follow = await context.env.DB.prepare(`
        SELECT id FROM artist_follows WHERE follower_user_id = ? AND artist_id = ?
      `).bind(userId, row.artist_id).first();
      if (!follow && userId !== row.author_user_id) {
        return jsonResponse({ success: false, error: 'This event is for approved followers only' }, 403);
      }
    }

    const types = await context.env.DB.prepare(`
      SELECT * FROM gig_ticket_types
      WHERE event_id = ? AND is_active = 1
      ORDER BY sort_order ASC, price ASC
    `).bind(row.id).all();

    const ticketTypes = (types.results || []).map(mapTicketTypeRow);
    const totalRemaining = ticketTypes.reduce(function(sum, t) { return sum + t.quantity_remaining; }, 0);
    const now = new Date().toISOString();
    const salesOpen = (!row.sales_start_at || row.sales_start_at <= now)
      && (!row.sales_end_at || row.sales_end_at >= now)
      && row.status === 'published'
      && totalRemaining > 0;

    const event = mapPublicEvent(row, {
      id: row.artist_id,
      username: row.username,
      name: row.artist_name,
      image: row.profile_picture_url,
      is_verified: Boolean(row.is_verified),
      profile_url: row.username ? '/book/' + row.username : null,
    }, ticketTypes);

    event.sales_open = salesOpen;
    event.total_remaining = totalRemaining;
    event.is_sold_out = totalRemaining <= 0 && row.status === 'published';

    const stats = await context.env.DB.prepare(`
      SELECT COUNT(DISTINCT o.buyer_user_id) AS buyers,
             COALESCE(SUM(oi.quantity), 0) AS tickets_sold
      FROM ticket_orders o
      JOIN ticket_order_items oi ON oi.order_id = o.id
      WHERE o.event_id = ? AND o.status = 'paid'
    `).bind(row.id).first();

    event.stats = {
      buyers: Number(stats?.buyers || 0),
      tickets_sold: Number(stats?.tickets_sold || 0),
    };

    return jsonResponse({ success: true, data: { event } });
  } catch (err) {
    console.error('Gig event detail error:', err);
    return jsonResponse({ success: false, error: 'Failed to load event' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
