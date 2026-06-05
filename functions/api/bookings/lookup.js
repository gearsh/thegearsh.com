// GET /api/bookings/lookup?id=&email= — guest view of a booking (email must match client)

import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const id = String(url.searchParams.get('id') || '').trim();
    const email = String(url.searchParams.get('email') || '').trim().toLowerCase();
    if (!id || !email) {
      return jsonResponse({ success: false, error: 'id and email are required' }, 400);
    }

    const row = await context.env.DB.prepare(`
      SELECT
        b.id, b.event_date, b.event_time, b.event_location, b.total_price, b.status, b.notes,
        u_artist.display_name AS artist_name,
        u_client.email AS client_email,
        s.name AS service_name
      FROM bookings b
      JOIN users u_client ON b.client_id = u_client.id
      JOIN artist_profiles ap ON b.artist_id = ap.id
      JOIN users u_artist ON ap.user_id = u_artist.id
      LEFT JOIN services s ON b.service_id = s.id
      WHERE b.id = ?
    `).bind(id).first();

    if (!row || String(row.client_email || '').toLowerCase() !== email) {
      return jsonResponse({ success: false, error: 'Booking not found' }, 404);
    }

    return jsonResponse({
      success: true,
      data: {
        id: row.id,
        event_date: row.event_date,
        event_time: row.event_time,
        event_location: row.event_location,
        total_price: row.total_price,
        status: row.status,
        artist_name: row.artist_name,
        service_name: row.service_name,
        notes: row.notes,
        payable: row.status === 'accepted' && Number(row.total_price || 0) > 0,
      },
    });
  } catch (err) {
    console.error('Booking lookup error:', err);
    return jsonResponse({ success: false, error: 'Failed to load booking' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
