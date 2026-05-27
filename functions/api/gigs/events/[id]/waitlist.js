// POST /api/gigs/events/:id/waitlist — join waitlist when sold out

import { parseToken, jsonResponse, corsPreflightResponse } from '../../../auth-utils.js';
import { ensureTicketsTables } from '../../../tickets-schema.js';
import { newId } from '../../../tickets-utils.js';

export async function onRequestPost(context) {
  try {
    await ensureTicketsTables(context.env.DB);
    const eventId = context.params.id;
    const body = await context.request.json();
    const email = String(body.email || '').trim().toLowerCase();
    const phone = String(body.phone || '').trim();
    const quantity = Math.max(1, Number(body.quantity || 1));

    if (!email) {
      return jsonResponse({ success: false, error: 'Email is required' }, 400);
    }

    const event = await context.env.DB.prepare(`
      SELECT id, title, status FROM gig_events WHERE id = ? AND status IN ('published', 'sold_out')
    `).bind(eventId).first();

    if (!event) {
      return jsonResponse({ success: false, error: 'Event not found' }, 404);
    }

    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    const existing = await context.env.DB.prepare(`
      SELECT id FROM gig_waitlist WHERE event_id = ? AND LOWER(email) = LOWER(?)
    `).bind(eventId, email).first();

    if (existing) {
      return jsonResponse({ success: true, data: { message: 'You are already on the waitlist' } });
    }

    await context.env.DB.prepare(`
      INSERT INTO gig_waitlist (id, event_id, user_id, email, phone, quantity)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(newId('wait'), eventId, userId || null, email, phone || null, quantity).run();

    return jsonResponse({
      success: true,
      data: { message: 'You are on the waitlist. We will notify you if tickets become available.' },
    }, 201);
  } catch (err) {
    console.error('Waitlist POST error:', err);
    return jsonResponse({ success: false, error: 'Could not join waitlist' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
