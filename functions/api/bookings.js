// POST /api/bookings - Create a new booking
// GET /api/bookings - Get user's bookings

export async function onRequestPost(context) {
  try {
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
      notes
    } = body;

    // Validate required fields
    if (!client_id || !artist_id || !event_date || !total_price) {
      return new Response(JSON.stringify({
        success: false,
        error: "Missing required fields"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
    }

    // Generate booking ID
    const bookingId = `book_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const insertQuery = `
      INSERT INTO bookings (
        id, client_id, artist_id, service_id, event_date, event_time,
        event_location, event_type, duration_hours, total_price, notes, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `;

    await context.env.DB.prepare(insertQuery)
      .bind(
        bookingId,
        client_id,
        artist_id,
        service_id || null,
        event_date,
        event_time || null,
        event_location || null,
        event_type || null,
        duration_hours || null,
        total_price,
        notes || null
      )
      .run();

    // Update artist's total bookings
    await context.env.DB.prepare(`
      UPDATE artist_profiles
      SET total_bookings = total_bookings + 1
      WHERE id = ?
    `).bind(artist_id).run();

    return new Response(JSON.stringify({
      success: true,
      data: {
        booking_id: bookingId,
        status: 'pending'
      }
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 201,
    });
  } catch (err) {
    console.error("Error creating booking:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to create booking"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 500,
    });
  }
}

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const userId = url.searchParams.get('user_id');
    const userType = url.searchParams.get('user_type') || 'client';
    const status = url.searchParams.get('status');

    if (!userId) {
      return new Response(JSON.stringify({
        success: false,
        error: "user_id is required"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
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
      // Get artist profile ID first
      const artistProfile = await context.env.DB.prepare(
        `SELECT id FROM artist_profiles WHERE user_id = ?`
      ).bind(userId).first();

      if (artistProfile) {
        query += ` AND b.artist_id = ?`;
        params.push(artistProfile.id);
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

    return new Response(JSON.stringify({
      success: true,
      data: result.results || []
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200,
    });
  } catch (err) {
    console.error("Error fetching bookings:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to fetch bookings"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 500,
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

