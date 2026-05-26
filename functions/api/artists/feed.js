// GET /api/artists/feed — categorized artist rows for the homepage

import { parseSkills, buildProfileUrl } from '../auth-utils.js';
import { seedShowcaseArtistsBatch, SA_SHOWCASE_ARTISTS } from '../sa-showcase-artists.js';
import { GENRE_FEED_CATEGORIES, resolveArtistGenreSlug } from '../sa-showcase-data.js';

const showcaseByUsername = new Map(
  SA_SHOWCASE_ARTISTS.map(function(artist) {
    return [String(artist.username || '').toLowerCase(), artist];
  })
);

function applyShowcaseMastery(artist) {
  const entry = showcaseByUsername.get(String(artist.username || '').toLowerCase());
  const listedHours = Number(entry?.masteryHours || 0);
  const liveHours = Number(artist.mastery_hours || 0);
  if (listedHours > liveHours) {
    return { ...artist, mastery_hours: listedHours };
  }
  return artist;
}

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
    mastery_hours: Math.round(Number(artist.mastery_hours || 0)),
  };
}

function compareByMastery(a, b) {
  const hoursA = Number(a.mastery_hours || 0);
  const hoursB = Number(b.mastery_hours || 0);
  if (hoursB !== hoursA) return hoursB - hoursA;
  return b.rating - a.rating
    || b.review_count - a.review_count
    || b.total_bookings - a.total_bookings;
}

function masteryBadge(hours) {
  if (hours >= 10000) return 'Legend';
  if (hours >= 5000) return 'Expert';
  if (hours >= 100) return 'Rising';
  return null;
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

function artistGenreSlug(artist) {
  if (artist.genreSlug) return artist.genreSlug;
  return resolveArtistGenreSlug(artist.category, artist.genre);
}

function buildCategories(artists) {
  const all = artists.map(mapArtist);

  return GENRE_FEED_CATEGORIES.map(function(section) {
    if (section.id === 'mastery-legends') {
      return {
        ...section,
        artists: takeUnique([...all].sort(compareByMastery), 16),
      };
    }

    if (section.id.indexOf('genre-') === 0) {
      const slug = section.id.slice(6);
      const filtered = all.filter(function(artist) {
        return artistGenreSlug(artist) === slug;
      });
      return {
        ...section,
        artists: takeUnique(filtered.sort(compareByMastery), 16),
      };
    }

    return { ...section, artists: [] };
  }).filter(function(section) {
    return section.artists && section.artists.length > 0;
  });
}

export async function onRequestGet(context) {
  try {
    try {
      await seedShowcaseArtistsBatch(context.env.DB, 15);
    } catch (seedErr) {
      console.error('Showcase artist batch seed skipped:', seedErr);
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
        (SELECT MIN(s.price) FROM services s WHERE s.artist_id = ap.id AND s.is_active = 1) AS min_price,
        COALESCE((
          SELECT SUM(COALESCE(b.duration_hours, 0))
          FROM bookings b
          WHERE b.artist_id = ap.id AND b.status = 'completed'
        ), 0) AS mastery_hours
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE u.is_active = 1
    `;

    const result = await context.env.DB.prepare(query).all();
    const artists = (result.results || []).map(applyShowcaseMastery);
    const categories = buildCategories(artists);

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
