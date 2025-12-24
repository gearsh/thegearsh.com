// POST /api/reviews - Create a new review
// GET /api/reviews?artist_id=xxx - Get reviews for an artist

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const { booking_id, reviewer_id, artist_id, rating, comment } = body;

    // Validate required fields
    if (!booking_id || !reviewer_id || !artist_id || !rating) {
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

    // Validate rating
    if (rating < 1 || rating > 5) {
      return new Response(JSON.stringify({
        success: false,
        error: "Rating must be between 1 and 5"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
    }

    // Check if booking exists and is completed
    const booking = await context.env.DB.prepare(`
      SELECT id, status, client_id FROM bookings WHERE id = ?
    `).bind(booking_id).first();

    if (!booking) {
      return new Response(JSON.stringify({
        success: false,
        error: "Booking not found"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 404,
      });
    }

    // Check if review already exists
    const existingReview = await context.env.DB.prepare(`
      SELECT id FROM reviews WHERE booking_id = ?
    `).bind(booking_id).first();

    if (existingReview) {
      return new Response(JSON.stringify({
        success: false,
        error: "Review already exists for this booking"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 409,
      });
    }

    // Generate review ID
    const reviewId = `rev_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Insert review
    await context.env.DB.prepare(`
      INSERT INTO reviews (id, booking_id, reviewer_id, artist_id, rating, comment)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(reviewId, booking_id, reviewer_id, artist_id, rating, comment || null).run();

    // Update artist's average rating
    const ratingStats = await context.env.DB.prepare(`
      SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews
      FROM reviews
      WHERE artist_id = ? AND is_visible = 1
    `).bind(artist_id).first();

    await context.env.DB.prepare(`
      UPDATE artist_profiles
      SET avg_rating = ?, total_reviews = ?
      WHERE id = ?
    `).bind(
      ratingStats.avg_rating || rating,
      ratingStats.total_reviews || 1,
      artist_id
    ).run();

    return new Response(JSON.stringify({
      success: true,
      data: { review_id: reviewId }
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 201,
    });
  } catch (err) {
    console.error("Error creating review:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to create review"
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
    const artistId = url.searchParams.get('artist_id');
    const limit = url.searchParams.get('limit') || 20;
    const offset = url.searchParams.get('offset') || 0;

    if (!artistId) {
      return new Response(JSON.stringify({
        success: false,
        error: "artist_id is required"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
    }

    const query = `
      SELECT
        r.id,
        r.rating,
        r.comment,
        r.created_at,
        u.display_name as reviewer_name,
        u.first_name,
        u.last_name,
        u.profile_picture_url as reviewer_image
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      WHERE r.artist_id = ? AND r.is_visible = 1
      ORDER BY r.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const result = await context.env.DB.prepare(query)
      .bind(artistId, parseInt(limit), parseInt(offset))
      .all();

    // Get total count
    const countResult = await context.env.DB.prepare(`
      SELECT COUNT(*) as total FROM reviews WHERE artist_id = ? AND is_visible = 1
    `).bind(artistId).first();

    return new Response(JSON.stringify({
      success: true,
      data: result.results || [],
      meta: {
        total: countResult.total,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200,
    });
  } catch (err) {
    console.error("Error fetching reviews:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to fetch reviews"
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

