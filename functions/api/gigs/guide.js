// GET /api/gigs/guide — Gig Guide discovery hub with filters

import { parseToken, jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { ensureTicketsTables } from '../tickets-schema.js';
import { ensureActivityTables } from '../activity-schema.js';
import { mapTicketTypeRow, mapGuideCard, expireStaleOrders } from '../tickets-utils.js';
import { seedGuideGigsIfEmpty } from './guide-seed.js';

function weekendRange() {
  const now = new Date();
  const day = now.getDay();
  const daysUntilFri = (5 - day + 7) % 7 || 7;
  const fri = new Date(now);
  fri.setDate(fri.getDate() + (day <= 5 && day >= 5 ? 0 : daysUntilFri));
  fri.setHours(0, 0, 0, 0);
  const sun = new Date(fri);
  sun.setDate(sun.getDate() + 2);
  sun.setHours(23, 59, 59, 999);
  return { start: fri.toISOString(), end: sun.toISOString() };
}

async function loadEventCards(db, rows) {
  const cards = [];
  for (const row of rows) {
    const types = await db.prepare(`
      SELECT * FROM gig_ticket_types WHERE event_id = ? AND is_active = 1 ORDER BY sort_order, price
    `).bind(row.id).all();
    const ticketTypes = (types.results || []).map(mapTicketTypeRow);
    cards.push(mapGuideCard(row, {
      id: row.artist_id,
      username: row.username,
      name: row.artist_name,
      image: row.profile_picture_url,
      is_verified: Boolean(row.is_verified),
      profile_url: row.username ? '/book/' + row.username : null,
    }, ticketTypes));
  }
  return cards;
}

export async function onRequestGet(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    await ensureActivityTables(context.env.DB);
    await expireStaleOrders(context.env.DB);
    // Seeding is best-effort — never let it break the guide.
    try {
      await seedGuideGigsIfEmpty(context.env.DB);
    } catch (seedErr) {
      console.error('Gig guide seed skipped:', seedErr);
    }

    const url = new URL(context.request.url);
    const q = String(url.searchParams.get('q') || '').trim().toLowerCase();
    const city = String(url.searchParams.get('city') || '').trim();
    const category = String(url.searchParams.get('category') || 'all').toLowerCase();
    const filter = String(url.searchParams.get('filter') || '').toLowerCase();
    const offset = Math.max(0, Number(url.searchParams.get('offset') || 0));
    const limit = Math.min(50, Math.max(1, Number(url.searchParams.get('limit') || 24)));
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);

    let query = `
      SELECT e.*, ap.id AS artist_id, u.username, u.display_name AS artist_name,
             u.profile_picture_url, u.is_verified,
             (SELECT COALESCE(SUM(t.quantity_sold), 0) FROM gig_ticket_types t WHERE t.event_id = e.id) AS tickets_sold
      FROM gig_events e
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE e.status IN ('published', 'sold_out') AND e.visibility = 'public'
    `;
    const binds = [];

    if (category && category !== 'all') {
      query += ' AND LOWER(COALESCE(e.category, \'music\')) = ?';
      binds.push(category);
    }
    if (city) {
      query += ' AND LOWER(e.city) LIKE ?';
      binds.push('%' + city.toLowerCase() + '%');
    }
    if (q) {
      query += ' AND (LOWER(e.title) LIKE ? OR LOWER(e.city) LIKE ? OR LOWER(u.display_name) LIKE ? OR LOWER(e.venue) LIKE ?)';
      const like = '%' + q + '%';
      binds.push(like, like, like, like);
    }
    if (filter === 'weekend') {
      const range = weekendRange();
      query += ' AND e.starts_at >= ? AND e.starts_at <= ?';
      binds.push(range.start, range.end);
    }
    if (filter === 'following' && userId) {
      query += ` AND e.artist_id IN (SELECT artist_id FROM artist_follows WHERE follower_user_id = ?)`;
      binds.push(userId);
    }

    let orderBy = 'e.is_featured DESC, e.starts_at ASC';
    if (filter === 'popular') orderBy = 'tickets_sold DESC, e.starts_at ASC';

    query += ` ORDER BY ${orderBy} LIMIT ? OFFSET ?`;
    binds.push(limit + 1, offset);

    const rows = await context.env.DB.prepare(query).bind(...binds).all();
    let results = rows.results || [];
    const hasMore = results.length > limit;
    if (hasMore) results = results.slice(0, limit);

    let cards = await loadEventCards(context.env.DB, results);

    if (filter === 'free') {
      cards = cards.filter(function (c) { return c.is_free; });
    }
    if (filter === 'vip') {
      cards = cards.filter(function (c) { return c.has_vip && !c.sold_out; });
    }

    const featuredRows = await context.env.DB.prepare(`
      SELECT e.*, ap.id AS artist_id, u.username, u.display_name AS artist_name,
             u.profile_picture_url, u.is_verified, 0 AS tickets_sold
      FROM gig_events e
      JOIN artist_profiles ap ON ap.id = e.artist_id
      JOIN users u ON u.id = ap.user_id
      WHERE e.status = 'published' AND e.is_featured = 1
      ORDER BY e.starts_at ASC LIMIT 5
    `).all();
    const featured = await loadEventCards(context.env.DB, featuredRows.results || []);

    let following = [];
    if (userId) {
      const followRows = await context.env.DB.prepare(`
        SELECT e.*, ap.id AS artist_id, u.username, u.display_name AS artist_name,
               u.profile_picture_url, u.is_verified, 0 AS tickets_sold
        FROM gig_events e
        JOIN artist_profiles ap ON ap.id = e.artist_id
        JOIN users u ON u.id = ap.user_id
        JOIN artist_follows f ON f.artist_id = e.artist_id AND f.follower_user_id = ?
        WHERE e.status IN ('published', 'sold_out')
        ORDER BY e.starts_at ASC LIMIT 8
      `).bind(userId).all();
      following = await loadEventCards(context.env.DB, followRows.results || []);
    }

    const cities = await context.env.DB.prepare(`
      SELECT DISTINCT city FROM gig_events WHERE status = 'published' ORDER BY city LIMIT 20
    `).all();

    return jsonResponse({
      success: true,
      data: {
        events: cards,
        featured,
        following,
        cities: (cities.results || []).map(function (r) { return r.city; }),
        has_more: hasMore,
        next_offset: offset + limit,
      },
    });
  } catch (err) {
    console.error('Gig guide GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load gig guide' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
