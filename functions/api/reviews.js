// POST /api/reviews - Create a new review (authenticated, client-only)
// GET /api/reviews?artist_id=xxx - Get reviews for an artist

import { parseToken, unauthorizedResponse } from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    const reviewerId = await parseToken(
      context.request.headers.get('Authorization'),
      context.env,
    );
    if (!reviewerId) return unauthorizedResponse('Authentication required');

    const body = await context.request.json();
    const { booking_id, artist_id, rating, comment } = body;

    if (!booking_id || !artist_id || !rating) {
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

    const numericRating = Number(rating);
    if (!Number.isFinite(numericRating) || numericRating < 1 || numericRating > 5) {
      return new Response(JSON.stringify({
        success: false,
        error: "Rating must be a number between 1 and 5"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
    }

    const booking = await context.env.DB.prepare(`
      SELECT id, status, client_id, artist_id FROM bookings WHERE id = ?
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

    if (booking.client_id !== reviewerId) {
      return new Response(JSON.stringify({
        success: false,
        error: "Only the client on this booking can leave a review"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 403,
      });
    }

    if (String(booking.status).toLowerCase() !== 'completed') {
      return new Response(JSON.stringify({
        success: false,
        error: "You can only review a booking that has been completed"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
    }

    if (booking.artist_id && booking.artist_id !== artist_id) {
      return new Response(JSON.stringify({
        success: false,
        error: "artist_id does not match the booking"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 400,
      });
    }
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

    const reviewArtistId = booking.artist_id || artist_id;
    const cleanComment = comment ? String(comment).slice(0, 2000) : null;

    await context.env.DB.prepare(`
      INSERT INTO reviews (id, booking_id, reviewer_id, artist_id, rating, comment)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(reviewId, booking_id, reviewerId, reviewArtistId, numericRating, cleanComment).run();

    const ratingStats = await context.env.DB.prepare(`
      SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews
      FROM reviews
      WHERE artist_id = ? AND is_visible = 1
    `).bind(reviewArtistId).first();

    await context.env.DB.prepare(`
      UPDATE artist_profiles
      SET avg_rating = ?, total_reviews = ?
      WHERE id = ?
    `).bind(
      ratingStats.avg_rating || numericRating,
      ratingStats.total_reviews || 1,
      reviewArtistId
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

