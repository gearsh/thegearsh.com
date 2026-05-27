// POST /api/ticket-orders — create pending order + reserve inventory
// GET /api/ticket-orders?event_id= — artist sales summary

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from './auth-utils.js';
import { ensureTicketsTables } from './tickets-schema.js';
import {
  newId,
  getOrCreateBuyerUser,
  reserveTicketInventory,
  releaseTicketInventory,
  validatePromoCode,
  calcOrderTotal,
  expireStaleOrders,
} from './tickets-utils.js';

export async function onRequestPost(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    await expireStaleOrders(context.env.DB);

    const body = await context.request.json();
    const eventId = String(body.event_id || '').trim();
    const items = Array.isArray(body.items) ? body.items : [];

    if (!eventId || !items.length) {
      return jsonResponse({ success: false, error: 'Event and ticket selection required' }, 400);
    }

    const event = await context.env.DB.prepare(`
      SELECT * FROM gig_events WHERE id = ? AND status IN ('published', 'sold_out')
    `).bind(eventId).first();

    if (!event) {
      return jsonResponse({ success: false, error: 'Event not available for ticket sales' }, 404);
    }

    const now = new Date().toISOString();
    if (event.sales_start_at && event.sales_start_at > now) {
      return jsonResponse({ success: false, error: 'Ticket sales have not started yet' }, 400);
    }
    if (event.sales_end_at && event.sales_end_at < now) {
      return jsonResponse({ success: false, error: 'Ticket sales have ended' }, 400);
    }

    const authUserId = await parseToken(context.request.headers.get('Authorization'), context.env);
    let buyer;
    try {
      buyer = await getOrCreateBuyerUser(context.env.DB, {
        userId: authUserId,
        name: body.buyer_name,
        email: body.buyer_email,
        phone: body.buyer_phone,
      });
    } catch (buyerErr) {
      return jsonResponse({ success: false, error: buyerErr.message }, 400);
    }

    const reserved = [];
    let subtotal = 0;
    const orderItems = [];

    for (const item of items) {
      const typeId = String(item.ticket_type_id || '').trim();
      const qty = Number(item.quantity || 0);
      if (!typeId || qty < 1) continue;

      const ticketType = await context.env.DB.prepare(`
        SELECT * FROM gig_ticket_types WHERE id = ? AND event_id = ? AND is_active = 1
      `).bind(typeId, eventId).first();

      if (!ticketType) {
        for (const r of reserved) await releaseTicketInventory(context.env.DB, r.id, r.qty);
        return jsonResponse({ success: false, error: 'Invalid ticket type' }, 400);
      }

      if (qty > Number(ticketType.max_per_order || 10)) {
        for (const r of reserved) await releaseTicketInventory(context.env.DB, r.id, r.qty);
        return jsonResponse({
          success: false,
          error: 'Maximum ' + ticketType.max_per_order + ' tickets per order for ' + ticketType.name,
        }, 400);
      }

      const reserveResult = await reserveTicketInventory(context.env.DB, typeId, qty);
      if (!reserveResult.ok) {
        for (const r of reserved) await releaseTicketInventory(context.env.DB, r.id, r.qty);
        return jsonResponse({ success: false, error: reserveResult.error || 'Sold out' }, 409);
      }

      reserved.push({ id: typeId, qty });
      const lineTotal = Number(ticketType.price) * qty;
      subtotal += lineTotal;
      orderItems.push({
        id: newId('ordi'),
        ticket_type_id: typeId,
        quantity: qty,
        unit_price: Number(ticketType.price),
        line_total: lineTotal,
        name: ticketType.name,
      });
    }

    if (!orderItems.length) {
      return jsonResponse({ success: false, error: 'Select at least one ticket' }, 400);
    }

    const promoResult = await validatePromoCode(
      context.env.DB,
      eventId,
      body.promo_code,
      subtotal
    );
    if (promoResult.error) {
      for (const r of reserved) await releaseTicketInventory(context.env.DB, r.id, r.qty);
      return jsonResponse({ success: false, error: promoResult.error }, 400);
    }

    const totals = calcOrderTotal(subtotal, promoResult.discount || 0);
    const orderId = newId('tord');
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    const buyerName = buyer.display_name || (buyer.first_name + ' ' + buyer.last_name).trim();

    await context.env.DB.prepare(`
      INSERT INTO ticket_orders (
        id, event_id, buyer_user_id, status, subtotal, discount, platform_fee, total,
        currency, promo_code, buyer_name, buyer_email, buyer_phone, expires_at, created_at, updated_at
      ) VALUES (?, ?, ?, 'pending_payment', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      orderId,
      eventId,
      buyer.id,
      totals.subtotal,
      totals.discount,
      totals.platform_fee,
      totals.total,
      event.currency || 'ZAR',
      promoResult.promo ? String(body.promo_code || '').trim().toUpperCase() : null,
      buyerName,
      buyer.email,
      body.buyer_phone || buyer.phone || null,
      expiresAt,
      now,
      now
    ).run();

    for (const item of orderItems) {
      await context.env.DB.prepare(`
        INSERT INTO ticket_order_items (id, order_id, ticket_type_id, quantity, unit_price, line_total)
        VALUES (?, ?, ?, ?, ?, ?)
      `).bind(item.id, orderId, item.ticket_type_id, item.quantity, item.unit_price, item.line_total).run();
    }

    return jsonResponse({
      success: true,
      data: {
        order_id: orderId,
        expires_at: expiresAt,
        subtotal: totals.subtotal,
        discount: totals.discount,
        platform_fee: totals.platform_fee,
        total: totals.total,
        currency: event.currency || 'ZAR',
        buyer_user_id: buyer.id,
        items: orderItems.map(function(i) {
          return {
            ticket_type_id: i.ticket_type_id,
            name: i.name,
            quantity: i.quantity,
            unit_price: i.unit_price,
            line_total: i.line_total,
          };
        }),
      },
    }, 201);
  } catch (err) {
    console.error('Ticket order POST error:', err);
    return jsonResponse({ success: false, error: 'Could not create order' }, 500);
  }
}

export async function onRequestGet(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    await ensureTicketsTables(context.env.DB);
    const url = new URL(context.request.url);
    const eventId = url.searchParams.get('event_id');
    if (!eventId) {
      return jsonResponse({ success: false, error: 'event_id required' }, 400);
    }

    const profile = await context.env.DB.prepare(`
      SELECT ap.id AS artist_id FROM artist_profiles ap WHERE ap.user_id = ?
    `).bind(userId).first();
    if (!profile) {
      return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
    }

    const event = await context.env.DB.prepare(`
      SELECT id, title FROM gig_events WHERE id = ? AND artist_id = ?
    `).bind(eventId, profile.artist_id).first();
    if (!event) {
      return jsonResponse({ success: false, error: 'Event not found' }, 404);
    }

    const summary = await context.env.DB.prepare(`
      SELECT
        COUNT(DISTINCT o.id) AS orders,
        COUNT(DISTINCT o.buyer_user_id) AS unique_buyers,
        COALESCE(SUM(CASE WHEN o.status = 'paid' THEN o.total ELSE 0 END), 0) AS revenue,
        COALESCE(SUM(CASE WHEN o.status = 'paid' THEN oi.quantity ELSE 0 END), 0) AS tickets_sold
      FROM ticket_orders o
      LEFT JOIN ticket_order_items oi ON oi.order_id = o.id
      WHERE o.event_id = ?
    `).bind(eventId).first();

    return jsonResponse({
      success: true,
      data: {
        event_id: eventId,
        title: event.title,
        orders: Number(summary?.orders || 0),
        unique_buyers: Number(summary?.unique_buyers || 0),
        revenue: Number(summary?.revenue || 0),
        tickets_sold: Number(summary?.tickets_sold || 0),
      },
    });
  } catch (err) {
    console.error('Ticket orders GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load sales data' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
