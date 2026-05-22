// GET /api/artists/feed — categorized artist rows for the homepage

import { parseSkills, buildProfileUrl } from '../auth-utils.js';
import { seedRixElton } from '../demo-artists.js';

const SA_COUNTRIES = new Set([
  'south africa',
  'za',
  'rsa',
]);

function normalizeCountry(value) {
  return String(value || '').trim().toLowerCase();
}

function isLocal(artist) {
  return SA_COUNTRIES.has(normalizeCountry(artist.country));
}

function isInternational(artist) {
  const country = normalizeCountry(artist.country);
  return country && !SA_COUNTRIES.has(country);
}

function daysSince(dateValue) {
  if (!dateValue) return Number.POSITIVE_INFINITY;
  const created = new Date(dateValue);
  if (Number.isNaN(created.getTime())) return Number.POSITIVE_INFINITY;
  return (Date.now() - created.getTime()) / (1000 * 60 * 60 * 24);
}

function mapArtist(artist) {
  return {
    ...artist,
    profile_url: buildProfileUrl(artist.username),
    skills: parseSkills(artist.skills),
    is_verified: Boolean(artist.is_verified),
    is_trending: Boolean(artist.is_trending),
    rating: Number(artist.rating || 0),
    review_count: Number(artist.review_count || 0),
    total_bookings: Number(artist.total_bookings || 0),
  };
}

function uniqueById(artists) {
  const seen = new Set();
  return artists.filter(function(artist) {
    if (!artist.artist_id || seen.has(artist.artist_id)) return false;
    seen.add(artist.artist_id);
    return true;
  });
}

function takeUnique(artists, limit) {
  return uniqueById(artists).slice(0, limit);
}

function buildCategories(artists) {
  const all = artists.map(mapArtist);
  const newest = takeUnique(
    [...all].sort(function(a, b) {
      return new Date(b.profile_created_at || b.user_created_at || 0)
        - new Date(a.profile_created_at || a.user_created_at || 0);
    }).filter(function(artist) {
      return daysSince(artist.profile_created_at || artist.user_created_at) <= 90;
    }).concat(
      [...all].sort(function(a, b) {
        return new Date(b.profile_created_at || b.user_created_at || 0)
          - new Date(a.profile_created_at || a.user_created_at || 0);
      })
    ),
    12
  );

  const mostBooked = takeUnique(
    [...all].sort(function(a, b) {
      return b.total_bookings - a.total_bookings || b.review_count - a.review_count;
    }).filter(function(artist) { return artist.total_bookings > 0; })
      .concat([...all].sort(function(a, b) { return b.total_bookings - a.total_bookings; })),
    12
  );

  const mostPopular = takeUnique(
    [...all].sort(function(a, b) {
      return b.review_count - a.review_count
        || b.rating - a.rating
        || b.total_bookings - a.total_bookings;
    }),
    12
  );

  const local = takeUnique(
    all.filter(isLocal).sort(function(a, b) {
      return b.total_bookings - a.total_bookings || b.rating - a.rating;
    }),
    12
  );

  const international = takeUnique(
    all.filter(isInternational).sort(function(a, b) {
      return b.rating - a.rating || b.review_count - a.review_count;
    }),
    12
  );

  const trending = takeUnique(
    all.filter(function(artist) { return artist.is_trending; })
      .concat([...all].sort(function(a, b) {
        return b.review_count - a.review_count || b.total_bookings - a.total_bookings;
      })),
    12
  );

  const topRated = takeUnique(
    [...all]
      .filter(function(artist) { return artist.rating >= 4 && artist.review_count > 0; })
      .sort(function(a, b) { return b.rating - a.rating || b.review_count - a.review_count; })
      .concat([...all].sort(function(a, b) { return b.rating - a.rating; })),
    12
  );

  const verified = takeUnique(
    all.filter(function(artist) { return artist.is_verified; })
      .sort(function(a, b) { return b.total_bookings - a.total_bookings; })
      .concat(all),
    12
  );

  const rising = takeUnique(
    all.filter(function(artist) {
      return artist.total_bookings > 0 && artist.total_bookings <= 5;
    }).sort(function(a, b) {
      return new Date(b.profile_created_at || b.user_created_at || 0)
        - new Date(a.profile_created_at || a.user_created_at || 0);
    }).concat(newest),
    12
  );

  return [
    {
      id: 'new',
      title: 'New artists',
      subtitle: 'Fresh talent that just joined Gearsh',
      icon: 'ti ti-sparkles',
      artists: newest,
    },
    {
      id: 'most-booked',
      title: 'Most booked',
      subtitle: 'Artists clients keep coming back to',
      icon: 'ti ti-calendar-check',
      artists: mostBooked,
    },
    {
      id: 'most-popular',
      title: 'Most popular',
      subtitle: 'Highest demand across the platform',
      icon: 'ti ti-flame',
      artists: mostPopular,
    },
    {
      id: 'local',
      title: 'Local',
      subtitle: 'Book talent near you in South Africa',
      icon: 'ti ti-map-pin',
      artists: local,
    },
    {
      id: 'international',
      title: 'International',
      subtitle: 'Global artists ready to perform worldwide',
      icon: 'ti ti-world',
      artists: international,
    },
    {
      id: 'trending',
      title: 'Trending now',
      subtitle: 'Hot picks getting attention right now',
      icon: 'ti ti-trending-up',
      artists: trending,
    },
    {
      id: 'top-rated',
      title: 'Top rated',
      subtitle: 'Five-star favourites from clients',
      icon: 'ti ti-star',
      artists: topRated,
    },
    {
      id: 'verified',
      title: 'Verified pros',
      subtitle: 'Trusted, verified profiles you can book with confidence',
      icon: 'ti ti-rosette-discount-check',
      artists: verified,
    },
    {
      id: 'rising',
      title: 'Rising stars',
      subtitle: 'Newcomers landing their first bookings',
      icon: 'ti ti-rocket',
      artists: rising,
    },
  ];
}

export async function onRequestGet(context) {
  try {
    try {
      const rix = await context.env.DB.prepare(
        `SELECT id FROM users WHERE LOWER(username) = 'rixelton' LIMIT 1`
      ).first();
      if (!rix) await seedRixElton(context.env.DB);
    } catch (seedErr) {
      console.error('Demo artist seed skipped:', seedErr);
    }

    const query = `
      SELECT
        ap.id as artist_id,
        u.id as user_id,
        u.display_name as name,
        u.username,
        u.profile_picture_url as image,
        u.bio,
        u.location,
        u.country,
        u.created_at as user_created_at,
        u.is_verified,
        ap.category,
        ap.genre,
        ap.base_rate,
        ap.total_bookings,
        ap.avg_rating as rating,
        ap.total_reviews as review_count,
        ap.is_trending,
        ap.skills,
        ap.created_at as profile_created_at,
        (SELECT MIN(s.price) FROM services s WHERE s.artist_id = ap.id AND s.is_active = 1) AS min_price
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE u.is_active = 1
    `;

    const result = await context.env.DB.prepare(query).all();
    const categories = buildCategories(result.results || []);

    return new Response(JSON.stringify({
      success: true,
      data: { categories },
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      status: 200,
    });
  } catch (err) {
    console.error('Artist feed error:', err);
    return new Response(JSON.stringify({
      success: false,
      error: 'Failed to load artist feed',
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      status: 500,
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
