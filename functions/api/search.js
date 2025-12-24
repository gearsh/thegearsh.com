// POST /api/search - Search artists with filters

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const {
      query = '',
      categories = [],
      minRating = 0,
      maxPrice,
      minPrice = 0,
      verified = false,
      sortBy = 'relevance',
      limit = 50,
      offset = 0
    } = body;

    let sql = `
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
        ap.avg_rating as rating,
        ap.total_reviews as review_count,
        ap.is_trending,
        ap.skills
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE u.is_active = 1
    `;

    const params = [];

    // Text search
    if (query && query.trim()) {
      const searchTerm = `%${query.toLowerCase()}%`;
      sql += ` AND (
        LOWER(u.display_name) LIKE ? OR
        LOWER(u.bio) LIKE ? OR
        LOWER(ap.category) LIKE ? OR
        LOWER(ap.genre) LIKE ? OR
        LOWER(u.location) LIKE ?
      )`;
      params.push(searchTerm, searchTerm, searchTerm, searchTerm, searchTerm);
    }

    // Category filter
    if (categories.length > 0) {
      const placeholders = categories.map(() => '?').join(',');
      sql += ` AND ap.category IN (${placeholders})`;
      params.push(...categories);
    }

    // Rating filter
    if (minRating > 0) {
      sql += ` AND ap.avg_rating >= ?`;
      params.push(minRating);
    }

    // Price filter
    if (minPrice > 0) {
      sql += ` AND ap.base_rate >= ?`;
      params.push(minPrice);
    }
    if (maxPrice) {
      sql += ` AND ap.base_rate <= ?`;
      params.push(maxPrice);
    }

    // Verified filter
    if (verified) {
      sql += ` AND u.is_verified = 1`;
    }

    // Sorting
    switch (sortBy) {
      case 'rating':
        sql += ` ORDER BY ap.avg_rating DESC`;
        break;
      case 'price_low':
        sql += ` ORDER BY ap.base_rate ASC`;
        break;
      case 'price_high':
        sql += ` ORDER BY ap.base_rate DESC`;
        break;
      case 'popular':
        sql += ` ORDER BY ap.total_reviews DESC`;
        break;
      default:
        // Relevance - prioritize trending, rating, reviews
        sql += ` ORDER BY ap.is_trending DESC, ap.avg_rating DESC, ap.total_reviews DESC`;
    }

    sql += ` LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const result = await context.env.DB.prepare(sql).bind(...params).all();

    // Calculate relevance scores
    const artists = result.results.map(artist => {
      let score = 0;
      const queryLower = query.toLowerCase();

      if (query) {
        // Name matching
        if (artist.name?.toLowerCase() === queryLower) score += 100;
        else if (artist.name?.toLowerCase().includes(queryLower)) score += 80;

        // Category matching
        if (artist.category?.toLowerCase() === queryLower) score += 60;

        // Bio matching
        if (artist.bio?.toLowerCase().includes(queryLower)) score += 20;

        // Location matching
        if (artist.location?.toLowerCase().includes(queryLower)) score += 25;
      }

      // Boosts
      score += (artist.rating || 0) * 5;
      if (artist.is_verified) score += 15;
      score += (artist.review_count || 0) * 0.1;
      if (artist.is_trending) score += 20;

      return {
        ...artist,
        skills: artist.skills ? JSON.parse(artist.skills) : [],
        is_verified: Boolean(artist.is_verified),
        is_trending: Boolean(artist.is_trending),
        relevance_score: score
      };
    });

    // Sort by relevance score if sorting by relevance
    if (sortBy === 'relevance' && query) {
      artists.sort((a, b) => b.relevance_score - a.relevance_score);
    }

    return new Response(JSON.stringify({
      success: true,
      data: artists,
      meta: {
        query,
        total: artists.length,
        limit,
        offset
      }
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200,
    });
  } catch (err) {
    console.error("Error searching artists:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Search failed"
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
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

