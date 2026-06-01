// GET /api/collaboration-settings — current artist's collaboration profile (pricing/types/availability)
// PUT /api/collaboration-settings — upsert the current artist's collaboration profile

import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from './auth-utils.js';
import {
  ensureCollaborationTables,
  AVAILABILITY_STATUSES,
  isValidCollaborationType,
  parseJsonArray,
  COLLABORATION_TYPES,
} from './collaboration-utils.js';

function shapeSettings(row) {
  if (!row) {
    return {
      available_status: 'available',
      collaboration_fee: null,
      feature_fee: null,
      appearance_fee: null,
      hourly_rate: null,
      project_rate: null,
      hide_pricing: false,
      quote_only: false,
      enabled_types: COLLABORATION_TYPES.map(function (t) { return t.id; }),
      response_time: null,
      configured: false,
    };
  }
  return {
    available_status: row.available_status || 'available',
    collaboration_fee: row.collaboration_fee,
    feature_fee: row.feature_fee,
    appearance_fee: row.appearance_fee,
    hourly_rate: row.hourly_rate,
    project_rate: row.project_rate,
    hide_pricing: Boolean(row.hide_pricing),
    quote_only: Boolean(row.quote_only),
    enabled_types: parseJsonArray(row.enabled_types),
    response_time: row.response_time,
    configured: true,
  };
}

export async function onRequestGet(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const row = await context.env.DB.prepare(
      `SELECT * FROM collaboration_profiles WHERE user_id = ?`
    ).bind(auth.userId).first();

    return jsonResponse({
      success: true,
      data: {
        settings: shapeSettings(row),
        types: COLLABORATION_TYPES,
        availability_options: AVAILABILITY_STATUSES,
      },
    });
  } catch (err) {
    console.error('Collaboration settings get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load settings' }, 500);
  }
}

function numOrNull(value) {
  if (value == null || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? n : null;
}

export async function onRequestPut(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(function () { return {}; });

    let availability = String(body.available_status || 'available').toLowerCase();
    if (AVAILABILITY_STATUSES.indexOf(availability) === -1) availability = 'available';

    const enabledTypes = Array.isArray(body.enabled_types)
      ? body.enabled_types.filter(isValidCollaborationType)
      : [];

    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO collaboration_profiles (
        user_id, available_status, collaboration_fee, feature_fee, appearance_fee,
        hourly_rate, project_rate, hide_pricing, quote_only, enabled_types, response_time, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(user_id) DO UPDATE SET
        available_status = excluded.available_status,
        collaboration_fee = excluded.collaboration_fee,
        feature_fee = excluded.feature_fee,
        appearance_fee = excluded.appearance_fee,
        hourly_rate = excluded.hourly_rate,
        project_rate = excluded.project_rate,
        hide_pricing = excluded.hide_pricing,
        quote_only = excluded.quote_only,
        enabled_types = excluded.enabled_types,
        response_time = excluded.response_time,
        updated_at = excluded.updated_at
    `).bind(
      auth.userId,
      availability,
      numOrNull(body.collaboration_fee),
      numOrNull(body.feature_fee),
      numOrNull(body.appearance_fee),
      numOrNull(body.hourly_rate),
      numOrNull(body.project_rate),
      body.hide_pricing ? 1 : 0,
      body.quote_only ? 1 : 0,
      JSON.stringify(enabledTypes),
      body.response_time ? String(body.response_time).slice(0, 60) : null,
      now
    ).run();

    return jsonResponse({ success: true, data: { saved: true } });
  } catch (err) {
    console.error('Collaboration settings put error:', err);
    return jsonResponse({ success: false, error: 'Failed to save settings' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
