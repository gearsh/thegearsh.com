// POST /api/booking-request — guest booking request for a public gig profile
import {
  hashPassword,
  jsonResponse,
  corsPreflightResponse,
  resolveArtistProfile,
} from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const {
      artist_id,
      artist_username,
      client_name,
      client_phone,
      client_email,
      event_date,
      event_location,
      venue,
      service_id,
      notes,
      project_brief,
      preferred_dates,
      preferred_time,
    } = body;

    const artistIdentifier = artist_id || artist_username;
    const venueName = String(event_location || venue || '').trim() || 'Remote / Online';

    if (!artistIdentifier || !client_name || !client_phone || !event_date) {
      return jsonResponse({
        success: false,
        error: 'Please fill in your name, phone, date, and select a provider.',
      }, 400);
    }

    const artistProfile = await resolveArtistProfile(context.env.DB, artistIdentifier);

    if (!artistProfile) {
      return jsonResponse({ success: false, error: 'Gig profile not found.' }, 404);
    }

    const resolvedArtistId = artistProfile.artist_id;

    let totalPrice = 0;
    if (service_id) {
      const service = await context.env.DB.prepare(`
        SELECT id, price, name FROM services
        WHERE id = ? AND artist_id = ? AND is_active = 1
      `).bind(service_id, resolvedArtistId).first();
      if (!service) {
        return jsonResponse({ success: false, error: 'Selected service not found.' }, 404);
      }
      totalPrice = Number(service.price || 0);
    }

    const phoneDigits = String(client_phone).replace(/\D/g, '');
    const guestEmail = (client_email || `guest_${phoneDigits || Date.now()}@gearsh.guest`).toLowerCase();
    let client = await context.env.DB.prepare(`
      SELECT id FROM users WHERE email = ? AND is_active = 1
    `).bind(guestEmail).first();

    if (!client) {
      const clientId = `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const passwordHash = await hashPassword(`guest_${Date.now()}`);
      const nameParts = String(client_name).trim().split(/\s+/);
      const firstName = nameParts[0] || 'Guest';
      const lastName = nameParts.slice(1).join(' ') || 'Client';
      const createdAt = new Date().toISOString();

      await context.env.DB.prepare(`
        INSERT INTO users (
          id, email, password_hash, user_type, first_name, last_name,
          display_name, phone, is_verified, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, 'client', ?, ?, ?, ?, 0, 1, ?, ?)
      `).bind(
        clientId,
        guestEmail,
        passwordHash,
        firstName,
        lastName,
        client_name.trim(),
        client_phone.trim(),
        createdAt,
        createdAt
      ).run();
      client = { id: clientId };
    }

    const bookingId = `book_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const brief = String(project_brief || notes || '').trim() || null;
    const prefDates = preferred_dates
      ? (Array.isArray(preferred_dates) ? JSON.stringify(preferred_dates) : String(preferred_dates))
      : null;
    const combinedNotes = [
      brief,
      preferred_time ? 'Preferred time: ' + preferred_time : null,
    ].filter(Boolean).join('\n\n') || null;

    await context.env.DB.prepare(`
      INSERT INTO bookings (
        id, client_id, artist_id, service_id, event_date, event_location, event_time,
        total_price, notes, project_brief, preferred_dates, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', datetime('now'), datetime('now'))
    `).bind(
      bookingId,
      client.id,
      resolvedArtistId,
      service_id || null,
      event_date,
      venueName,
      preferred_time || null,
      totalPrice,
      combinedNotes,
      brief,
      prefDates
    ).run();

    return jsonResponse({
      success: true,
      message: 'Booking request sent! The provider will confirm with you soon.',
      data: {
        booking_id: bookingId,
        artist_name: artistProfile.artist_name,
        artist_phone: artistProfile.artist_phone,
      },
    }, 201);
  } catch (err) {
    console.error('Booking request error:', err);
    return jsonResponse({ success: false, error: 'Could not send booking request.' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
