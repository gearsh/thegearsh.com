// POST /api/bookings - Create a new booking
// GET /api/bookings - Get user's bookings

import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
  parseToken,
} from './auth-utils.js';
import { ensureMarketplaceTables } from './db-schema.js';

export async function onRequestPost(context) {
  try {
    await ensureMarketplaceTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const {
      client_id,
      artist_id,
      service_id,
      event_date,
      event_time,
      event_location,
      event_type,
      duration_hours,
      total_price,
      notes,
    } = body;

    const clientId = client_id || auth.userId;
    if (clientId !== auth.userId && auth.user.user_type !== 'admin') {
      return jsonResponse({ success: false, error: 'Cannot create booking for another user' }, 403);
    }

    if (!artist_id || !event_date || !total_price) {
      return jsonResponse({ success: false, error: 'Missing required fields' }, 400);
    }

    const bookingId = `book_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    await context.env.DB.prepare(`
      INSERT INTO bookings (
        id, client_id, artist_id, service_id, event_date, event_time,
        event_location, event_type, duration_hours, total_price, notes, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `).bind(
      bookingId,
      clientId,
      artist_id,
      service_id || null,
      event_date,
      event_time || null,
      event_location || null,
      event_type || null,
      duration_hours || null,
      total_price,
      notes || null
    ).run();

    await context.env.DB.prepare(`
      UPDATE artist_profiles
      SET total_bookings = total_bookings + 1
      WHERE id = ?
    `).bind(artist_id).run();

    return jsonResponse({
      success: true,
      data: { booking_id: bookingId, status: 'pending' },
    }, 201);
  } catch (err) {
    console.error('Error creating booking:', err);
    return jsonResponse({ success: false, error: 'Failed to create booking' }, 500);
  }
}

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    let userId = url.searchParams.get('user_id');
    const userType = url.searchParams.get('user_type') || 'client';
    const status = url.searchParams.get('status');

    const tokenUserId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (tokenUserId) {
      userId = tokenUserId;
    }

    if (!userId) {
      return jsonResponse({ success: false, error: 'user_id is required' }, 400);
    }

    let query = `
      SELECT
        b.*,
        u_client.display_name as client_name,
        u_artist.display_name as artist_name,
        u_artist.profile_picture_url as artist_image,
        ap.category as artist_category,
        s.name as service_name
      FROM bookings b
      JOIN users u_client ON b.client_id = u_client.id
      JOIN artist_profiles ap ON b.artist_id = ap.id
      JOIN users u_artist ON ap.user_id = u_artist.id
      LEFT JOIN services s ON b.service_id = s.id
      WHERE 1=1
    `;

    const params = [];

    if (userType === 'artist') {
      const artistProfile = await context.env.DB.prepare(
        `SELECT id FROM artist_profiles WHERE user_id = ?`
      ).bind(userId).first();

      if (artistProfile) {
        query += ` AND b.artist_id = ?`;
        params.push(artistProfile.id);
      } else {
        return jsonResponse({ success: true, data: [] });
      }
    } else {
      query += ` AND b.client_id = ?`;
      params.push(userId);
    }

    if (status) {
      query += ` AND b.status = ?`;
      params.push(status);
    }

    query += ` ORDER BY b.event_date DESC`;

    const result = await context.env.DB.prepare(query).bind(...params).all();

    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Error fetching bookings:', err);
    return jsonResponse({ success: false, error: 'Failed to fetch bookings' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
