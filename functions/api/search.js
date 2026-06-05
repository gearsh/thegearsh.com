// POST /api/search - Search artists with filters
// GET  /api/search?q=...&genre=...&sort=...

import {
  artistDistanceKm,
  compareArtistsByDistance,
} from './location-utils.js';

export async function onRequestGet(context) {
  const url = new URL(context.request.url);
  const body = {
    query: url.searchParams.get('q') || '',
    categories: url.searchParams.get('category') ? [url.searchParams.get('category')] : [],
    minRating: parseFloat(url.searchParams.get('minRating') || '0'),
    verified: url.searchParams.get('verified') === 'true',
    sortBy: url.searchParams.get('sort') || 'relevance',
    limit: parseInt(url.searchParams.get('limit') || '50', 10),
    offset: parseInt(url.searchParams.get('offset') || '0', 10),
    userLat: parseFloat(url.searchParams.get('lat') || ''),
    userLng: parseFloat(url.searchParams.get('lng') || ''),
  };
  return runSearch(context, body);
}

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    return runSearch(context, body);
  } catch (err) {
    console.error("Error searching artists:", err);
    return searchError();
  }
}

async function runSearch(context, body) {
  try {
    const {
      query = '',
      categories = [],
      minRating = 0,
      maxPrice,
      minPrice = 0,
      verified = false,
      sortBy = 'relevance',
      limit = 50,
      offset = 0,
      userLat,
      userLng,
    } = body;

    const lat = Number(userLat);
    const lng = Number(userLng);
    let resolvedLat = lat;
    let resolvedLng = lng;

    if (!Number.isFinite(resolvedLat) || !Number.isFinite(resolvedLng)) {
      const cf = context.request.cf || {};
      const cfLat = parseFloat(cf.latitude);
      const cfLng = parseFloat(cf.longitude);
      if (Number.isFinite(cfLat) && Number.isFinite(cfLng)) {
        resolvedLat = cfLat;
        resolvedLng = cfLng;
      }
    }

    const sortNearby = Number.isFinite(resolvedLat) && Number.isFinite(resolvedLng);

    let sql = `
      SELECT
        ap.id as artist_id,
        u.id as user_id,
        u.display_name as name,
        u.username,
        u.profile_picture_url as image,
        u.bio,
        u.location,
        u.country,
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
      case 'nearby':
        sql += ` ORDER BY ap.is_trending DESC, ap.avg_rating DESC, ap.total_reviews DESC`;
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
        relevance_score: score,
        distance_km: sortNearby
          ? artistDistanceKm(artist, resolvedLat, resolvedLng)
          : null,
      };
    });

    if (sortNearby && (sortBy === 'nearby' || sortBy === 'relevance' || !query)) {
      artists.sort(function (a, b) {
        return compareArtistsByDistance(a, b, resolvedLat, resolvedLng)
          || (b.relevance_score || 0) - (a.relevance_score || 0);
      });
    }

    // Sort by relevance score if sorting by relevance with a query
    if (sortBy === 'relevance' && query && !sortNearby) {
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
    return searchError();
  }
}

function searchError() {
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

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

