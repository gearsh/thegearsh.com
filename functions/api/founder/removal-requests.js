import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureRemovalRequestsTable } from '../claim-profile-utils.js';

export async function onRequestGet(context) {
  try {
    await ensureRemovalRequestsTable(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const status = String(url.searchParams.get('status') || 'pending').toLowerCase();

    const result = await context.env.DB.prepare(`
      SELECT
        id, user_id, username, display_name, requester_email, reason,
        status, created_at, reviewed_at, notes
      FROM profile_removal_requests
      WHERE status = ?
      ORDER BY created_at DESC
      LIMIT 100
    `).bind(status).all();

    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Founder removal requests error:', err);
    return jsonResponse({ success: false, error: 'Failed to load removal requests' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    await ensureRemovalRequestsTable(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const requestId = String(body.request_id || body.id || '').trim();
    const action = String(body.action || '').trim().toLowerCase();
    const notes = String(body.notes || '').trim() || null;
    const now = new Date().toISOString();

    if (!requestId || !action) {
      return jsonResponse({ success: false, error: 'request_id and action are required' }, 400);
    }

    const request = await context.env.DB.prepare(`
      SELECT * FROM profile_removal_requests WHERE id = ?
    `).bind(requestId).first();

    if (!request) {
      return jsonResponse({ success: false, error: 'Removal request not found' }, 404);
    }

    if (request.status !== 'pending') {
      return jsonResponse({ success: false, error: 'This request has already been reviewed' }, 409);
    }

    if (action === 'approve') {
      await context.env.DB.prepare(`
        UPDATE users
        SET is_active = 0, is_verified = 0, claim_token = NULL, updated_at = ?
        WHERE id = ?
      `).bind(now, request.user_id).run();

      const profile = await context.env.DB.prepare(`
        SELECT id FROM artist_profiles WHERE user_id = ?
      `).bind(request.user_id).first();

      if (profile) {
        await context.env.DB.prepare(`
          UPDATE services SET is_active = 0 WHERE artist_id = ?
        `).bind(profile.id).run();
      }

      await context.env.DB.prepare(`
        INSERT INTO removed_listings (username, removed_at, reason)
        VALUES (?, ?, ?)
        ON CONFLICT(username) DO UPDATE SET
          removed_at = excluded.removed_at,
          reason = excluded.reason
      `).bind(String(request.username).toLowerCase(), now, request.reason || 'Artist requested removal').run();

      await context.env.DB.prepare(`
        UPDATE profile_removal_requests
        SET status = 'approved', reviewed_at = ?, notes = ?
        WHERE id = ?
      `).bind(now, notes, requestId).run();
    } else if (action === 'dismiss') {
      await context.env.DB.prepare(`
        UPDATE profile_removal_requests
        SET status = 'dismissed', reviewed_at = ?, notes = ?
        WHERE id = ?
      `).bind(now, notes, requestId).run();
    } else {
      return jsonResponse({
        success: false,
        error: 'Invalid action. Use approve or dismiss.',
      }, 400);
    }

    return jsonResponse({
      success: true,
      message: action === 'approve' ? 'Listing removed from Gearsh' : 'Removal request dismissed',
      data: { request_id: requestId, action, status: action === 'approve' ? 'approved' : 'dismissed' },
    });
  } catch (err) {
    console.error('Founder removal request update error:', err);
    return jsonResponse({ success: false, error: 'Failed to update removal request' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
