// GET   /api/founder/leakage-flags — circumvention attempts caught in messaging
// PATCH /api/founder/leakage-flags — mark a flag resolved { id }
//
// Founder-only. Surfaces artists trying to take deals off-platform so the team can
// nudge, warn, or suspend repeat offenders.

import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureCollaborationTables } from '../collaboration-utils.js';

export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    await ensureCollaborationTables(context.env.DB);
    const db = context.env.DB;

    const url = new URL(context.request.url);
    const showResolved = url.searchParams.get('all') === '1';

    const where = showResolved ? '' : 'WHERE f.resolved = 0';
    const result = await db.prepare(`
      SELECT f.id, f.collaboration_id, f.message_id, f.sender_id, f.reasons,
             f.excerpt, f.resolved, f.created_at,
             u.display_name AS sender_name, u.username AS sender_username
      FROM collaboration_flags f
      LEFT JOIN users u ON f.sender_id = u.id
      ${where}
      ORDER BY f.created_at DESC
      LIMIT 200
    `).all();

    const flags = (result.results || []).map(function (row) {
      let reasons = [];
      try { reasons = JSON.parse(row.reasons || '[]'); } catch (_) { reasons = []; }
      return {
        id: row.id,
        collaboration_id: row.collaboration_id,
        message_id: row.message_id,
        sender_id: row.sender_id,
        sender_name: row.sender_name || 'Unknown',
        sender_username: row.sender_username || null,
        reasons: reasons,
        excerpt: row.excerpt || '',
        resolved: Boolean(row.resolved),
        created_at: row.created_at,
      };
    });

    // Repeat-offender tally for quick triage.
    const offenders = {};
    flags.forEach(function (f) {
      if (f.resolved) return;
      offenders[f.sender_id] = offenders[f.sender_id] || { name: f.sender_name, count: 0 };
      offenders[f.sender_id].count += 1;
    });

    return jsonResponse({
      success: true,
      data: flags,
      unresolved: flags.filter(function (f) { return !f.resolved; }).length,
      repeat_offenders: Object.keys(offenders)
        .map(function (id) { return { sender_id: id, name: offenders[id].name, count: offenders[id].count }; })
        .filter(function (o) { return o.count >= 2; })
        .sort(function (a, b) { return b.count - a.count; }),
    });
  } catch (err) {
    console.error('leakage-flags get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load flags' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(function () { return {}; });
    const id = String(body.id || '').trim();
    if (!id) return jsonResponse({ success: false, error: 'id is required' }, 400);

    await context.env.DB.prepare(
      `UPDATE collaboration_flags SET resolved = 1 WHERE id = ?`
    ).bind(id).run();

    return jsonResponse({ success: true });
  } catch (err) {
    console.error('leakage-flags patch error:', err);
    return jsonResponse({ success: false, error: 'Failed to update flag' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
