// PATCH /api/users/perspective — switch active client/artist perspective

import { corsPreflightResponse, jsonResponse, requireAuth } from '../auth-utils.js';
import { ensureRenovationTables } from '../renovation-schema.js';
import { resolveUserRoles } from '../auth-utils.js';

export async function onRequestPatch(context) {
  try {
    await ensureRenovationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const perspective = String(body.perspective || '').trim().toLowerCase();
    if (!['client', 'artist', 'admin'].includes(perspective)) {
      return jsonResponse({ success: false, error: 'Invalid perspective' }, 400);
    }

    const roles = await resolveUserRoles(context.env.DB, auth.user);
    if (!roles.includes(perspective)) {
      return jsonResponse({ success: false, error: 'Perspective not available for this account' }, 403);
    }

    const now = new Date().toISOString();
    await context.env.DB.prepare(`
      UPDATE users SET active_perspective = ?, updated_at = ? WHERE id = ?
    `).bind(perspective, now, auth.userId).run();

    return jsonResponse({ success: true, data: { active_perspective: perspective } });
  } catch (err) {
    console.error('Perspective update error:', err);
    return jsonResponse({ success: false, error: 'Failed to update perspective' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
