// GET /api/gigs/events — public published events
// POST /api/gigs/events — create event (artist auth)

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from '../auth-utils.js';
import { ensureTicketsTables } from '../tickets-schema.js';
import {
  newId,
  ensureUniqueEventSlug,
  mapTicketTypeRow,
  mapPublicEvent,
  createGigActivityPost,
} from '../tickets-utils.js';

const TIER_KINDS = new Set([
  'general', 'early_bird', 'vip', 'table', 'meet_greet', 'addon',
]);

async function getArtistProfileForUser(db, userId) {
  return db.prepare(`
    SELECT ap.id AS artist_id, u.id AS user_id, u.username, u.display_name AS artist_name,
           u.profile_picture_url, u.is_verified
    FROM artist_profiles ap
    JOIN users u ON ap.user_id = u.id
    WHERE ap.user_id = ?
  `).bind(userId).first();
}

export async function onRequestGet(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    const url = new URL(context.request.url);
    const artistId = url.searchParams.get('artist_id');
    const mine = url.searchParams.get('mine') === '1';
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);

    if (mine) {
      if (!userId) return unauthorizedResponse();
      const profile = await getArtistProfileForUser(context.env.DB, userId);
      if (!profile) {
        return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
      }
      const rows = await context.env.DB.prepare(`
        SELECT e.*, (
          SELECT COALESCE(SUM(quantity_sold), 0) FROM gig_ticket_types t WHERE t.event_id = e.id
        ) AS tickets_sold,
        (
          SELECT COALESCE(SUM(tt.price * tt.quantity_sold), 0) FROM gig_ticket_types tt WHERE tt.event_id = e.id
        ) AS gross_revenue
        FROM gig_events e
        WHERE e.artist_id = ?
        ORDER BY e.starts_at DESC
      `).bind(profile.artist_id).all();

      return jsonResponse({
        success: true,
        data: {
          events: (rows.results || []).map(function(row) {
            return {
              id: row.id,
              slug: row.slug,
              title: row.title,
              venue: row.venue,
              city: row.city,
              starts_at: row.starts_at,
              status: row.status,
              flyer_url: row.flyer_url,
              tickets_sold: Number(row.tickets_sold || 0),
              gross_revenue: Number(row.gross_revenue || 0),
              url: '/gig/' + row.slug,
            };
          }),
        },
      });
    }

    let query = `
      SELECT e.*, u.username, u.display_name AS artist_name, u.profile_picture_url, u.is_verified
      FROM gig_events e
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE e.status = 'published'
    `;
    const binds = [];
    if (artistId) {
      query += ' AND e.artist_id = ?';
      binds.push(artistId);
    }
    query += ' ORDER BY e.starts_at ASC LIMIT 50';

    const stmt = context.env.DB.prepare(query);
    const rows = binds.length ? await stmt.bind(...binds).all() : await stmt.all();

    const events = [];
    for (const row of rows.results || []) {
      const types = await context.env.DB.prepare(`
        SELECT * FROM gig_ticket_types WHERE event_id = ? AND is_active = 1 ORDER BY sort_order, price
      `).bind(row.id).all();
      events.push(mapPublicEvent(row, {
        id: row.artist_id,
        username: row.username,
        name: row.artist_name,
        image: row.profile_picture_url,
        is_verified: Boolean(row.is_verified),
        profile_url: row.username ? '/book/' + row.username : null,
      }, (types.results || []).map(mapTicketTypeRow)));
    }

    return jsonResponse({ success: true, data: { events } });
  } catch (err) {
    console.error('Gig events GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load events' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    await ensureTicketsTables(context.env.DB);
    const profile = await getArtistProfileForUser(context.env.DB, userId);
    if (!profile) {
      return jsonResponse({ success: false, error: 'Only artists can create ticketed gigs' }, 403);
    }

    const body = await context.request.json();
    const title = String(body.title || '').trim();
    const venue = String(body.venue || '').trim();
    const city = String(body.city || '').trim();
    const startsAt = String(body.starts_at || '').trim();

    if (!title || !venue || !city || !startsAt) {
      return jsonResponse({
        success: false,
        error: 'Title, venue, city, and start date/time are required',
      }, 400);
    }

    const ticketTypes = Array.isArray(body.ticket_types) ? body.ticket_types : [];
    if (!ticketTypes.length) {
      return jsonResponse({ success: false, error: 'Add at least one ticket type' }, 400);
    }

    const eventId = newId('evt');
    const slug = body.slug ? String(body.slug).trim().toLowerCase() : await ensureUniqueEventSlug(context.env.DB, title);
    const now = new Date().toISOString();
    const publish = body.publish !== false;
    const currency = String(body.currency || 'ZAR').toUpperCase();

    await context.env.DB.prepare(`
      INSERT INTO gig_events (
        id, artist_id, author_user_id, slug, title, description, venue, city, country,
        starts_at, ends_at, timezone, flyer_url, lineup_json, capacity, currency,
        visibility, refund_policy, category, status, sales_start_at, sales_end_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      eventId,
      profile.artist_id,
      userId,
      slug,
      title,
      String(body.description || '').trim() || null,
      venue,
      city,
      String(body.country || 'South Africa').trim(),
      startsAt,
      body.ends_at || null,
      body.timezone || 'Africa/Johannesburg',
      body.flyer_url || null,
      JSON.stringify(Array.isArray(body.lineup) ? body.lineup : []),
      Number(body.capacity || 0),
      currency,
      body.visibility === 'followers' ? 'followers' : 'public',
      String(body.refund_policy || '').trim() || null,
      String(body.category || 'music').toLowerCase(),
      publish ? 'published' : 'draft',
      body.sales_start_at || now,
      body.sales_end_at || null,
      now,
      now
    ).run();

    let sortOrder = 0;
    for (const tier of ticketTypes) {
      const name = String(tier.name || '').trim();
      const price = Number(tier.price);
      const qty = Number(tier.quantity_total);
      if (!name || !price || price < 0 || !qty || qty < 1) {
        return jsonResponse({ success: false, error: 'Each ticket type needs name, price, and quantity' }, 400);
      }
      const tierKind = TIER_KINDS.has(String(tier.tier_kind || '').toLowerCase())
        ? String(tier.tier_kind).toLowerCase()
        : 'general';
      await context.env.DB.prepare(`
        INSERT INTO gig_ticket_types (
          id, event_id, name, tier_kind, description, price, currency,
          quantity_total, max_per_order, sort_order, is_active
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
      `).bind(
        newId('tktp'),
        eventId,
        name,
        tierKind,
        String(tier.description || '').trim() || null,
        price,
        tier.currency || currency,
        qty,
        Number(tier.max_per_order || 10),
        sortOrder
      ).run();
      sortOrder += 1;
    }

    const promoCodes = Array.isArray(body.promo_codes) ? body.promo_codes : [];
    for (const promo of promoCodes) {
      const code = String(promo.code || '').trim();
      if (!code) continue;
      await context.env.DB.prepare(`
        INSERT INTO gig_promo_codes (
          id, event_id, code, discount_type, discount_value, max_uses, valid_from, valid_until
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        newId('promo'),
        eventId,
        code.toUpperCase(),
        promo.discount_type === 'fixed' ? 'fixed' : 'percent',
        Number(promo.discount_value || 0),
        Number(promo.max_uses || 0),
        promo.valid_from || null,
        promo.valid_until || null
      ).run();
    }

    let activityId = null;
    if (publish && body.post_to_feed !== false) {
      activityId = await createGigActivityPost(context.env.DB, {
        id: eventId,
        artist_id: profile.artist_id,
        author_user_id: userId,
        title,
        description: body.description,
        city,
        venue,
        starts_at: startsAt,
        flyer_url: body.flyer_url,
        slug,
      }, profile);
    }

    return jsonResponse({
      success: true,
      data: {
        event_id: eventId,
        slug,
        activity_id: activityId,
        url: '/gig/' + slug,
      },
    }, 201);
  } catch (err) {
    console.error('Gig events POST error:', err);
    return jsonResponse({ success: false, error: 'Failed to create event' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
