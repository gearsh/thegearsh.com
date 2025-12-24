// GET /api/artists/[id] - Get single artist by ID

export async function onRequestGet(context) {
  try {
    const artistId = context.params.id;

    const query = `
      SELECT
        ap.id as artist_id,
        u.id as user_id,
        u.display_name as name,
        u.first_name,
        u.last_name,
        u.email,
        u.profile_picture_url as image,
        u.bio,
        u.location,
        u.country,
        u.phone,
        u.is_verified,
        ap.category,
        ap.genre,
        ap.base_rate,
        ap.hourly_rate,
        ap.avg_rating as rating,
        ap.total_reviews as review_count,
        ap.total_bookings,
        ap.is_trending,
        ap.skills,
        ap.portfolio_urls,
        ap.social_links,
        ap.years_experience,
        ap.availability_status
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.id = ? AND u.is_active = 1
    `;

    const artist = await context.env.DB.prepare(query).bind(artistId).first();

    if (!artist) {
      return new Response(JSON.stringify({
        success: false,
        error: "Artist not found"
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 404,
      });
    }

    // Get services
    const servicesQuery = `
      SELECT id, name, description, price, duration_hours
      FROM services
      WHERE artist_id = ? AND is_active = 1
    `;
    const services = await context.env.DB.prepare(servicesQuery).bind(artistId).all();

    // Get reviews
    const reviewsQuery = `
      SELECT
        r.id,
        r.rating,
        r.comment,
        r.created_at,
        u.display_name as reviewer_name,
        u.profile_picture_url as reviewer_image
      FROM reviews r
      JOIN users u ON r.reviewer_id = u.id
      WHERE r.artist_id = ? AND r.is_visible = 1
      ORDER BY r.created_at DESC
      LIMIT 10
    `;
    const reviews = await context.env.DB.prepare(reviewsQuery).bind(artistId).all();

    // Parse JSON fields
    const artistData = {
      ...artist,
      skills: artist.skills ? JSON.parse(artist.skills) : [],
      portfolio_urls: artist.portfolio_urls ? JSON.parse(artist.portfolio_urls) : [],
      social_links: artist.social_links ? JSON.parse(artist.social_links) : {},
      is_verified: Boolean(artist.is_verified),
      is_trending: Boolean(artist.is_trending),
      services: services.results || [],
      reviews: reviews.results || [],
    };

    return new Response(JSON.stringify({
      success: true,
      data: artistData
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200,
    });
  } catch (err) {
    console.error("Error fetching artist:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to fetch artist"
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
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

