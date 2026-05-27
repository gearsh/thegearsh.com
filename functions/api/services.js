// GET /api/services — list own services (auth)
// POST /api/services — create service
// PATCH /api/services — update service by id in body
// DELETE /api/services?id= — deactivate service

import {
  jsonResponse,
  corsPreflightResponse,
  requireAuth,
} from './auth-utils.js';
import { ensureMasterProfileColumns } from './master-profile-schema.js';

function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

async function getArtistProfileId(db, userId) {
  const row = await db.prepare(`
    SELECT id FROM artist_profiles WHERE user_id = ?
  `).bind(userId).first();
  return row?.id || null;
}

export async function onRequestGet(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    await ensureMasterProfileColumns(context.env.DB);
    const artistId = await getArtistProfileId(context.env.DB, auth.userId);
    if (!artistId) {
      return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
    }

    const rows = await context.env.DB.prepare(`
      SELECT id, name, description, price, duration_hours, delivery_days,
             deliverables, is_featured, sort_order, is_active, created_at
      FROM services WHERE artist_id = ?
      ORDER BY is_featured DESC, sort_order ASC, created_at DESC
    `).bind(artistId).all();

    const services = (rows.results || []).map(function (s) {
      let deliverables = [];
      try { deliverables = JSON.parse(s.deliverables || '[]'); } catch (_) {}
      return {
        id: s.id,
        name: s.name,
        description: s.description,
        price: Number(s.price),
        duration_hours: s.duration_hours ? Number(s.duration_hours) : null,
        delivery_days: s.delivery_days ? Number(s.delivery_days) : null,
        deliverables,
        is_featured: Boolean(s.is_featured),
        sort_order: Number(s.sort_order || 0),
        is_active: Boolean(s.is_active),
      };
    });

    return jsonResponse({ success: true, data: { services } });
  } catch (err) {
    console.error('Services GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load services' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    await ensureMasterProfileColumns(context.env.DB);
    const artistId = await getArtistProfileId(context.env.DB, auth.userId);
    if (!artistId) {
      return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
    }

    const body = await context.request.json();
    const name = String(body.name || '').trim();
    const price = Number(body.price);
    if (!name || !price || price < 0) {
      return jsonResponse({ success: false, error: 'Name and price are required' }, 400);
    }

    const id = newId('svc');
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO services (
        id, artist_id, name, description, price, duration_hours, delivery_days,
        deliverables, is_featured, sort_order, is_active, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
    `).bind(
      id,
      artistId,
      name,
      String(body.description || '').trim() || null,
      price,
      body.duration_hours ? Number(body.duration_hours) : null,
      body.delivery_days ? Number(body.delivery_days) : null,
      JSON.stringify(Array.isArray(body.deliverables) ? body.deliverables : []),
      body.is_featured ? 1 : 0,
      Number(body.sort_order || 0),
      now
    ).run();

    return jsonResponse({ success: true, data: { id } }, 201);
  } catch (err) {
    console.error('Services POST error:', err);
    return jsonResponse({ success: false, error: 'Failed to create service' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    await ensureMasterProfileColumns(context.env.DB);
    const artistId = await getArtistProfileId(context.env.DB, auth.userId);
    if (!artistId) {
      return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
    }

    const body = await context.request.json();
    const serviceId = String(body.id || '').trim();
    if (!serviceId) {
      return jsonResponse({ success: false, error: 'Service id required' }, 400);
    }

    const existing = await context.env.DB.prepare(`
      SELECT id FROM services WHERE id = ? AND artist_id = ?
    `).bind(serviceId, artistId).first();
    if (!existing) {
      return jsonResponse({ success: false, error: 'Service not found' }, 404);
    }

    await context.env.DB.prepare(`
      UPDATE services SET
        name = COALESCE(?, name),
        description = COALESCE(?, description),
        price = COALESCE(?, price),
        duration_hours = COALESCE(?, duration_hours),
        delivery_days = COALESCE(?, delivery_days),
        deliverables = COALESCE(?, deliverables),
        is_featured = COALESCE(?, is_featured),
        sort_order = COALESCE(?, sort_order),
        is_active = COALESCE(?, is_active)
      WHERE id = ?
    `).bind(
      body.name || null,
      body.description !== undefined ? String(body.description) : null,
      body.price !== undefined ? Number(body.price) : null,
      body.duration_hours !== undefined ? Number(body.duration_hours) : null,
      body.delivery_days !== undefined ? Number(body.delivery_days) : null,
      body.deliverables ? JSON.stringify(body.deliverables) : null,
      body.is_featured !== undefined ? (body.is_featured ? 1 : 0) : null,
      body.sort_order !== undefined ? Number(body.sort_order) : null,
      body.is_active !== undefined ? (body.is_active ? 1 : 0) : null,
      serviceId
    ).run();

    return jsonResponse({ success: true, message: 'Service updated' });
  } catch (err) {
    console.error('Services PATCH error:', err);
    return jsonResponse({ success: false, error: 'Failed to update service' }, 500);
  }
}

export async function onRequestDelete(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const serviceId = url.searchParams.get('id');
    if (!serviceId) {
      return jsonResponse({ success: false, error: 'Service id required' }, 400);
    }

    const artistId = await getArtistProfileId(context.env.DB, auth.userId);
    if (!artistId) {
      return jsonResponse({ success: false, error: 'Artist profile required' }, 403);
    }

    await context.env.DB.prepare(`
      UPDATE services SET is_active = 0 WHERE id = ? AND artist_id = ?
    `).bind(serviceId, artistId).run();

    return jsonResponse({ success: true, message: 'Service removed' });
  } catch (err) {
    console.error('Services DELETE error:', err);
    return jsonResponse({ success: false, error: 'Failed to delete service' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
