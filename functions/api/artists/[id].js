// GET /api/artists/[id] - Get single artist by profile ID or username

import { parseSkills, resolveArtistProfile } from '../auth-utils.js';
import { ensureDemoColumns } from '../demo-artists.js';
import { seedShowcaseArtist } from '../sa-showcase-artists.js';
import {
  findShowcaseArtist,
  buildShowcaseArtistResponse,
  getBookingFee,
  resolveShowcaseImage,
  buildShowcasePortfolio,
  buildShowcaseServices,
} from '../showcase-profile.js';

function enrichFromShowcase(artistData, showcase) {
  const fee = getBookingFee(showcase);
  const image = resolveShowcaseImage(showcase);

  if (!artistData.image) artistData.image = image;
  if (!artistData.bio && showcase.bio) artistData.bio = showcase.bio;
  if (!artistData.genre && showcase.genre) artistData.genre = showcase.genre;

  const portfolio = artistData.portfolio_urls?.length
    ? artistData.portfolio_urls
    : buildShowcasePortfolio(showcase);
  artistData.portfolio_urls = portfolio;

  if (!artistData.services?.length) {
    artistData.services = buildShowcaseServices(showcase, fee);
  }

  artistData.hourly_rate = fee;
  artistData.base_rate = fee;
  artistData.booking_fee = fee;
  artistData.mastery_hours = Number(showcase.masteryHours || artistData.mastery_hours || 0);
  return artistData;
}

export async function onRequestGet(context) {
  try {
    await ensureDemoColumns(context.env.DB);
    const identifier = context.params.id;
    const showcase = findShowcaseArtist(identifier);
    let resolved = await resolveArtistProfile(context.env.DB, identifier);

    if (!resolved && showcase) {
      await seedShowcaseArtist(context.env.DB, showcase);
      resolved = await resolveArtistProfile(context.env.DB, identifier);
    }

    if (!resolved) {
      if (showcase) {
        return new Response(JSON.stringify({
          success: true,
          data: buildShowcaseArtistResponse(showcase),
        }), {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
          status: 200,
        });
      }

      return new Response(JSON.stringify({
        success: false,
        error: 'Artist not found',
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 404,
      });
    }

    const artistId = resolved.artist_id;

    const query = `
      SELECT
        ap.id as artist_id,
        u.id as user_id,
        u.username,
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
        ap.availability_status,
        u.claim_token,
        u.is_demo
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.id = ? AND u.is_active = 1
    `;

    const artist = await context.env.DB.prepare(query).bind(artistId).first();

    if (!artist) {
      if (showcase) {
        return new Response(JSON.stringify({
          success: true,
          data: buildShowcaseArtistResponse(showcase),
        }), {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
          status: 200,
        });
      }

      return new Response(JSON.stringify({
        success: false,
        error: 'Artist not found',
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 404,
      });
    }

    const servicesQuery = `
      SELECT id, name, description, price, duration_hours
      FROM services
      WHERE artist_id = ? AND is_active = 1
    `;
    const services = await context.env.DB.prepare(servicesQuery).bind(artistId).all();

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

    const artistData = {
      ...artist,
      profile_url: artist.username ? `/book/${encodeURIComponent(String(artist.username).toLowerCase())}` : null,
      claim_url: artist.claim_token ? `/claim-profile.html?artist=${encodeURIComponent(String(artist.username).toLowerCase())}` : null,
      is_claimable: Boolean(artist.claim_token),
      is_demo: Boolean(artist.is_demo),
      skills: parseSkills(artist.skills),
      portfolio_urls: artist.portfolio_urls ? JSON.parse(artist.portfolio_urls) : [],
      social_links: artist.social_links ? JSON.parse(artist.social_links) : {},
      is_verified: Boolean(artist.is_verified),
      is_trending: Boolean(artist.is_trending),
      services: services.results || [],
      reviews: reviews.results || [],
    };
    delete artistData.claim_token;

    if (showcase) {
      enrichFromShowcase(artistData, showcase);
    }

    return new Response(JSON.stringify({
      success: true,
      data: artistData,
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      status: 200,
    });
  } catch (err) {
    console.error('Error fetching artist:', err);
    return new Response(JSON.stringify({
      success: false,
      error: 'Failed to fetch artist',
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
