// Shared helpers for gig ticketing
import { hashPassword } from './auth-utils.js';
import { PLATFORM_FEE_RATE } from './payfast-utils.js';

export function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

export function slugifyEvent(title) {
  const base = String(title || 'event')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48) || 'event';
  return base + '-' + Math.random().toString(36).slice(2, 7);
}

export async function ensureUniqueEventSlug(db, title) {
  let slug = slugifyEvent(title);
  let attempt = 0;
  while (attempt < 20) {
    const existing = await db.prepare('SELECT id FROM gig_events WHERE slug = ?').bind(slug).first();
    if (!existing) return slug;
    attempt += 1;
    slug = slugifyEvent(title);
  }
  return slug;
}

export function generateTicketCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'GRS-';
  for (let i = 0; i < 8; i += 1) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

export function buildQrPayload(ticketCode, eventId, orderId) {
  return JSON.stringify({
    v: 1,
    code: ticketCode,
    event_id: eventId,
    order_id: orderId,
    issued: new Date().toISOString(),
  });
}

export function calcPlatformFee(subtotal) {
  return Math.round(Number(subtotal || 0) * PLATFORM_FEE_RATE * 100) / 100;
}

export function calcOrderTotal(subtotal, discount) {
  const net = Math.max(0, Number(subtotal || 0) - Number(discount || 0));
  const fee = calcPlatformFee(net);
  const total = Math.round((net + fee) * 100) / 100;
  return { subtotal: Number(subtotal || 0), discount: Number(discount || 0), platform_fee: fee, total };
}

export async function getOrCreateBuyerUser(db, { name, email, phone, userId }) {
  if (userId) {
    const user = await db.prepare(`
      SELECT id, email, first_name, last_name, display_name, phone
      FROM users WHERE id = ? AND is_active = 1
    `).bind(userId).first();
    if (user) return user;
  }

  const buyerName = String(name || '').trim();
  const buyerEmail = String(email || '').trim().toLowerCase();
  const buyerPhone = String(phone || '').trim();
  if (!buyerName || !buyerEmail) {
    throw new Error('Name and email are required for checkout');
  }

  let client = await db.prepare(`
    SELECT id, email, first_name, last_name, display_name, phone
    FROM users WHERE email = ? AND is_active = 1
  `).bind(buyerEmail).first();

  if (client) return client;

  const clientId = newId('client');
  const passwordHash = await hashPassword('guest_' + Date.now());
  const nameParts = buyerName.split(/\s+/);
  const firstName = nameParts[0] || 'Guest';
  const lastName = nameParts.slice(1).join(' ') || 'Fan';
  const now = new Date().toISOString();

  await db.prepare(`
    INSERT INTO users (
      id, email, password_hash, user_type, first_name, last_name,
      display_name, phone, is_verified, is_active, created_at, updated_at
    ) VALUES (?, ?, ?, 'client', ?, ?, ?, ?, 0, 1, ?, ?)
  `).bind(clientId, buyerEmail, passwordHash, firstName, lastName, buyerName, buyerPhone || null, now, now).run();

  return {
    id: clientId,
    email: buyerEmail,
    first_name: firstName,
    last_name: lastName,
    display_name: buyerName,
    phone: buyerPhone,
  };
}

export async function reserveTicketInventory(db, ticketTypeId, quantity) {
  const qty = Number(quantity);
  if (!qty || qty < 1) return { ok: false, error: 'Invalid quantity' };

  const result = await db.prepare(`
    UPDATE gig_ticket_types
    SET quantity_reserved = quantity_reserved + ?
    WHERE id = ?
      AND is_active = 1
      AND (quantity_sold + quantity_reserved + ?) <= quantity_total
  `).bind(qty, ticketTypeId, qty).run();

  if (!result.meta || result.meta.changes !== 1) {
    return { ok: false, error: 'Not enough tickets available' };
  }
  return { ok: true };
}

export async function releaseTicketInventory(db, ticketTypeId, quantity) {
  const qty = Number(quantity);
  await db.prepare(`
    UPDATE gig_ticket_types
    SET quantity_reserved = CASE WHEN quantity_reserved - ? < 0 THEN 0 ELSE quantity_reserved - ? END
    WHERE id = ?
  `).bind(qty, qty, ticketTypeId).run();
}

export async function confirmTicketInventory(db, ticketTypeId, quantity) {
  const qty = Number(quantity);
  await db.prepare(`
    UPDATE gig_ticket_types
    SET quantity_sold = quantity_sold + ?,
        quantity_reserved = CASE WHEN quantity_reserved - ? < 0 THEN 0 ELSE quantity_reserved - ? END
    WHERE id = ?
  `).bind(qty, qty, qty, ticketTypeId).run();
}

export async function validatePromoCode(db, eventId, code, subtotal) {
  if (!code) return { discount: 0, promo: null };
  const promo = await db.prepare(`
    SELECT * FROM gig_promo_codes
    WHERE event_id = ? AND UPPER(code) = UPPER(?) AND is_active = 1
  `).bind(eventId, String(code).trim()).first();

  if (!promo) return { error: 'Invalid promo code' };

  const now = new Date().toISOString();
  if (promo.valid_from && promo.valid_from > now) return { error: 'Promo code not active yet' };
  if (promo.valid_until && promo.valid_until < now) return { error: 'Promo code expired' };
  if (promo.max_uses > 0 && promo.uses_count >= promo.max_uses) return { error: 'Promo code fully redeemed' };

  let discount = 0;
  if (promo.discount_type === 'percent') {
    discount = Math.round(Number(subtotal) * Number(promo.discount_value) / 100 * 100) / 100;
  } else {
    discount = Math.min(Number(subtotal), Number(promo.discount_value));
  }
  return { discount, promo };
}

export async function mintTicketInstances(db, order, items) {
  const tickets = [];
  for (const item of items) {
    for (let i = 0; i < item.quantity; i += 1) {
      let ticketCode = generateTicketCode();
      let attempts = 0;
      while (attempts < 5) {
        const clash = await db.prepare('SELECT id FROM ticket_instances WHERE ticket_code = ?').bind(ticketCode).first();
        if (!clash) break;
        ticketCode = generateTicketCode();
        attempts += 1;
      }
      const ticketId = newId('tkt');
      const qrPayload = buildQrPayload(ticketCode, order.event_id, order.id);
      await db.prepare(`
        INSERT INTO ticket_instances (
          id, order_id, order_item_id, event_id, ticket_type_id,
          ticket_code, holder_name, holder_email, qr_payload
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        ticketId,
        order.id,
        item.id,
        order.event_id,
        item.ticket_type_id,
        ticketCode,
        order.buyer_name,
        order.buyer_email,
        qrPayload
      ).run();
      tickets.push({ id: ticketId, ticket_code: ticketCode, ticket_type_id: item.ticket_type_id });
    }
  }
  return tickets;
}

export async function expireStaleOrders(db) {
  const now = new Date().toISOString();
  const stale = await db.prepare(`
    SELECT o.id, oi.ticket_type_id, oi.quantity
    FROM ticket_orders o
    JOIN ticket_order_items oi ON oi.order_id = o.id
    WHERE o.status = 'pending_payment' AND o.expires_at IS NOT NULL AND o.expires_at < ?
  `).bind(now).all();

  for (const row of stale.results || []) {
    await releaseTicketInventory(db, row.ticket_type_id, row.quantity);
  }

  await db.prepare(`
    UPDATE ticket_orders SET status = 'expired', updated_at = ?
    WHERE status = 'pending_payment' AND expires_at IS NOT NULL AND expires_at < ?
  `).bind(now, now).run();
}

export function mapTicketTypeRow(row) {
  const sold = Number(row.quantity_sold || 0);
  const reserved = Number(row.quantity_reserved || 0);
  const total = Number(row.quantity_total || 0);
  const remaining = Math.max(0, total - sold - reserved);
  return {
    id: row.id,
    name: row.name,
    tier_kind: row.tier_kind,
    description: row.description,
    price: Number(row.price),
    currency: row.currency || 'ZAR',
    quantity_total: total,
    quantity_sold: sold,
    quantity_remaining: remaining,
    max_per_order: Number(row.max_per_order || 10),
    sort_order: Number(row.sort_order || 0),
    is_active: Boolean(row.is_active),
    availability_label: remaining <= 0
      ? 'Sold out'
      : remaining <= 20
        ? 'Only ' + remaining + ' left'
        : remaining + ' available',
  };
}

export function mapGuideCard(row, artist, ticketTypes) {
  const types = ticketTypes || [];
  const prices = types.map(function (t) { return t.price; }).filter(function (p) { return p >= 0; });
  const minPrice = prices.length ? Math.min.apply(null, prices) : null;
  const maxPrice = prices.length ? Math.max.apply(null, prices) : null;
  const remaining = types.reduce(function (sum, t) { return sum + (t.quantity_remaining || 0); }, 0);
  const hasVip = types.some(function (t) {
    return (t.tier_kind === 'vip' || /vip/i.test(t.name)) && t.quantity_remaining > 0;
  });
  const soldOut = remaining <= 0 || row.status === 'sold_out';
  const isFree = minPrice === 0;
  const generalTier = types.find(function (t) {
    return t.tier_kind === 'general' || t.tier_kind === 'early_bird';
  }) || types[0];
  const vipTier = types.find(function (t) {
    return t.tier_kind === 'vip' || /vip/i.test(t.name);
  });

  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    venue: row.venue,
    city: row.city,
    country: row.country,
    starts_at: row.starts_at,
    flyer_url: row.flyer_url || '/icons/og-image.png',
    category: row.category || 'music',
    is_featured: Boolean(row.is_featured),
    status: row.status,
    currency: row.currency || 'ZAR',
    artist: artist,
    price_from: minPrice,
    price_to: maxPrice,
    is_free: isFree,
    has_vip: hasVip,
    sold_out: soldOut,
    tickets_remaining: remaining,
    tickets_sold: types.reduce(function (s, t) { return s + (t.quantity_sold || 0); }, 0),
    availability_label: soldOut ? 'Sold out' : (remaining <= 30 ? 'Only ' + remaining + ' left' : 'Tickets available'),
    general_tier_id: generalTier ? generalTier.id : null,
    vip_tier_id: vipTier && vipTier.quantity_remaining > 0 ? vipTier.id : null,
    url: '/gig/' + row.slug,
    buy_url: '/gig/' + row.slug + '#tickets',
  };
}

export function mapPublicEvent(row, artist, ticketTypes) {
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    description: row.description,
    venue: row.venue,
    city: row.city,
    country: row.country,
    starts_at: row.starts_at,
    ends_at: row.ends_at,
    timezone: row.timezone,
    flyer_url: row.flyer_url,
    lineup: JSON.parse(row.lineup_json || '[]'),
    capacity: Number(row.capacity || 0),
    currency: row.currency || 'ZAR',
    visibility: row.visibility,
    refund_policy: row.refund_policy,
    status: row.status,
    sales_start_at: row.sales_start_at,
    sales_end_at: row.sales_end_at,
    artist: artist || null,
    ticket_types: ticketTypes || [],
    url: '/gig/' + row.slug,
  };
}

export async function fulfillTicketOrder(db, orderId, payfastPaymentId, payload) {
  const order = await db.prepare(`
    SELECT * FROM ticket_orders WHERE id = ?
  `).bind(orderId).first();

  if (!order) return { ok: false, error: 'Order not found' };
  if (order.status === 'paid') return { ok: true, already: true };

  const items = await db.prepare(`
    SELECT * FROM ticket_order_items WHERE order_id = ?
  `).bind(orderId).all();

  const now = new Date().toISOString();

  for (const item of items.results || []) {
    await confirmTicketInventory(db, item.ticket_type_id, item.quantity);
  }

  await db.prepare(`
    UPDATE ticket_orders SET status = 'paid', paid_at = ?, updated_at = ? WHERE id = ?
  `).bind(now, now, orderId).run();

  if (order.promo_code) {
    await db.prepare(`
      UPDATE gig_promo_codes SET uses_count = uses_count + 1
      WHERE event_id = ? AND UPPER(code) = UPPER(?)
    `).bind(order.event_id, order.promo_code).run();
  }

  const tickets = await mintTicketInstances(db, order, items.results || []);

  const payment = await db.prepare(`
    SELECT id FROM ticket_payments WHERE ticket_order_id = ? ORDER BY created_at DESC LIMIT 1
  `).bind(orderId).first();

  if (payment) {
    await db.prepare(`
      UPDATE ticket_payments
      SET status = 'complete', payfast_payment_id = ?, raw_payload = ?, updated_at = ?
      WHERE id = ?
    `).bind(payfastPaymentId || null, JSON.stringify(payload || {}), now, payment.id).run();
  }

  const remaining = await db.prepare(`
    SELECT COALESCE(SUM(quantity_total - quantity_sold - quantity_reserved), 0) AS left_count
    FROM gig_ticket_types WHERE event_id = ? AND is_active = 1
  `).bind(order.event_id).first();

  if (Number(remaining?.left_count || 0) <= 0) {
    await db.prepare(`
      UPDATE gig_events SET status = 'sold_out', updated_at = ? WHERE id = ? AND status = 'published'
    `).bind(now, order.event_id).run();
  }

  try {
    const { ensureActivityTables } = await import('./activity-schema.js');
    await ensureActivityTables(db);
    const event = await db.prepare('SELECT artist_id, title FROM gig_events WHERE id = ?').bind(order.event_id).first();
    if (event) {
      const actId = newId('act');
      await db.prepare(`
        INSERT INTO artist_activities (
          id, artist_id, author_user_id, activity_type, title, description,
          metadata_json, is_public, created_at, updated_at
        ) VALUES (?, ?, ?, 'milestone', ?, ?, ?, 1, ?, ?)
      `).bind(
        actId,
        event.artist_id,
        order.buyer_user_id,
        'New ticket sale',
        (order.buyer_name || 'A fan') + ' bought tickets for ' + event.title,
        JSON.stringify({ order_id: orderId, ticket_count: tickets.length, type: 'ticket_sale' }),
        now,
        now
      ).run();
    }
  } catch (_) {
    /* activity log is best-effort */
  }

  return { ok: true, tickets };
}

export async function cancelTicketOrder(db, orderId) {
  const order = await db.prepare(`
    SELECT * FROM ticket_orders WHERE id = ? AND status = 'pending_payment'
  `).bind(orderId).first();
  if (!order) return;

  const items = await db.prepare(`
    SELECT * FROM ticket_order_items WHERE order_id = ?
  `).bind(orderId).all();

  for (const item of items.results || []) {
    await releaseTicketInventory(db, item.ticket_type_id, item.quantity);
  }

  const now = new Date().toISOString();
  await db.prepare(`
    UPDATE ticket_orders SET status = 'cancelled', updated_at = ? WHERE id = ?
  `).bind(now, orderId).run();
}

export async function createGigActivityPost(db, event, profile) {
  const { ensureActivityTables } = await import('./activity-schema.js');
  await ensureActivityTables(db);
  const activityId = newId('act');
  const now = new Date().toISOString();
  const metadata = {
    event_id: event.id,
    event_slug: event.slug,
    ticket_url: '/gig/' + event.slug,
    has_tickets: true,
  };
  const mediaUrls = event.flyer_url ? [event.flyer_url] : [];

  await db.prepare(`
    INSERT INTO artist_activities (
      id, artist_id, author_user_id, activity_type, title, description,
      location, venue, event_date, media_urls, metadata_json, is_public,
      created_at, updated_at
    ) VALUES (?, ?, ?, 'gig', ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
  `).bind(
    activityId,
    event.artist_id,
    event.author_user_id,
    event.title,
    event.description || 'Tickets on sale now on Gearsh.',
    event.city,
    event.venue,
    event.starts_at,
    JSON.stringify(mediaUrls),
    JSON.stringify(metadata),
    now,
    now
  ).run();

  await db.prepare(`
    UPDATE gig_events SET activity_id = ?, updated_at = ? WHERE id = ?
  `).bind(activityId, now, event.id).run();

  return activityId;
}
