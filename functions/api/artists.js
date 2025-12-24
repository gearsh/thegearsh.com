// GET /api/artists - List all artists with optional filters
// GET /api/artists?category=DJ&minRating=4.0&verified=true

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const category = url.searchParams.get('category');
    const minRating = url.searchParams.get('minRating');
    const verified = url.searchParams.get('verified');
    const limit = url.searchParams.get('limit') || 50;
    const offset = url.searchParams.get('offset') || 0;

    let query = `
      SELECT
        ap.id as artist_id,
        u.id as user_id,
        u.display_name as name,
        u.profile_picture_url as image,
        u.bio,
        u.location,
        u.is_verified,
        ap.category,
        ap.genre,
        ap.base_rate,
        ap.hourly_rate,
        ap.avg_rating as rating,
        ap.total_reviews as review_count,
        ap.is_trending,
        ap.skills,
        ap.years_experience
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE u.is_active = 1
    `;

    const params = [];

    if (category) {
      query += ` AND ap.category = ?`;
      params.push(category);
    }

    if (minRating) {
      query += ` AND ap.avg_rating >= ?`;
      params.push(parseFloat(minRating));
    }

    if (verified === 'true') {
      query += ` AND u.is_verified = 1`;
    }

    query += ` ORDER BY ap.avg_rating DESC, ap.total_reviews DESC LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), parseInt(offset));

    const stmt = context.env.DB.prepare(query);
    const result = await stmt.bind(...params).all();

    // Parse JSON fields
    const artists = result.results.map(artist => ({
      ...artist,
      skills: artist.skills ? JSON.parse(artist.skills) : [],
      is_verified: Boolean(artist.is_verified),
      is_trending: Boolean(artist.is_trending),
    }));

    return new Response(JSON.stringify({
      success: true,
      data: artists,
      meta: {
        total: artists.length,
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
    console.error("Error fetching artists:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to fetch artists"
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

