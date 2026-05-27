// GET /api/master-profile/:username — public master profile

import { jsonResponse, corsPreflightResponse, resolveArtistProfile } from '../auth-utils.js';
import { ensureMasterProfileColumns, isMasterProfile } from '../master-profile-schema.js';
import { mapMasterProfileResponse, GEARSH_DEFAULT, GEARSH_USERNAME } from '../master-profile-data.js';
import { seedGearshMasterProfile } from '../master-profile-seed.js';

function parseJson(value, fallback) {
  try { return JSON.parse(value || ''); } catch (_) { return fallback; }
}

export async function onRequestGet(context) {
  try {
    const username = String(context.params.username || '').toLowerCase().replace(/^@/, '');
    if (!username) {
      return jsonResponse({ success: false, error: 'Profile not found' }, 404);
    }

    await ensureMasterProfileColumns(context.env.DB);

    if (username === GEARSH_USERNAME) {
      await seedGearshMasterProfile(context.env.DB).catch(function () {});
    }

    let resolved = await resolveArtistProfile(context.env.DB, username);
    if (!resolved && username === GEARSH_USERNAME) {
      await seedGearshMasterProfile(context.env.DB);
      resolved = await resolveArtistProfile(context.env.DB, username);
    }

    if (!resolved) {
      if (username === GEARSH_USERNAME) {
        return jsonResponse({
          success: true,
          data: mapMasterProfileResponse(null, GEARSH_DEFAULT.services, GEARSH_DEFAULT),
        });
      }
      return jsonResponse({ success: false, error: 'Master profile not found' }, 404);
    }

    const row = await context.env.DB.prepare(`
      SELECT
        ap.id AS artist_id,
        u.id AS user_id,
        u.username,
        u.display_name AS name,
        u.profile_picture_url AS image,
        u.bio,
        u.location,
        u.country,
        u.is_verified,
        ap.category,
        ap.tagline,
        ap.cover_image_url,
        ap.long_bio,
        ap.stats_json,
        ap.testimonials_json,
        ap.portfolio_projects_json,
        ap.availability_json,
        ap.profile_type,
        ap.avg_rating AS rating,
        ap.total_reviews AS review_count,
        ap.total_bookings,
        ap.skills,
        ap.social_links
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.id = ? AND u.is_active = 1
    `).bind(resolved.artist_id).first();

    if (!row || (!isMasterProfile(row) && username !== GEARSH_USERNAME)) {
      return jsonResponse({ success: false, error: 'Master profile not found' }, 404);
    }

    const servicesResult = await context.env.DB.prepare(`
      SELECT id, name, description, price, duration_hours, delivery_days,
             deliverables, is_featured, sort_order
      FROM services
      WHERE artist_id = ? AND is_active = 1
      ORDER BY is_featured DESC, sort_order ASC, price ASC
    `).bind(resolved.artist_id).all();

    const services = (servicesResult.results || []).map(function (s) {
      return {
        id: s.id,
        name: s.name,
        description: s.description,
        price: Number(s.price),
        duration_hours: s.duration_hours ? Number(s.duration_hours) : null,
        delivery_days: s.delivery_days ? Number(s.delivery_days) : null,
        deliverables: parseJson(s.deliverables, []),
        is_featured: Boolean(s.is_featured),
      };
    });

    const profile = mapMasterProfileResponse(row, services, {
      skills: parseJson(row.skills, GEARSH_DEFAULT.skills),
      social_links: parseJson(row.social_links, GEARSH_DEFAULT.social_links),
    });

    return jsonResponse({ success: true, data: profile });
  } catch (err) {
    console.error('Master profile GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load profile' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
