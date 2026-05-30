import {
  corsPreflightResponse,
  jsonResponse,
} from '../auth-utils.js';
import { ensureDemoColumns } from '../demo-artists.js';
import {
  ensureRemovalRequestsTable,
  getPendingRemovalRequest,
  newRemovalRequestId,
} from '../claim-profile-utils.js';

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const username = String(body.username || body.artist || '').trim();
    const email = String(body.email || body.requester_email || '').trim().toLowerCase();
    const claimCode = String(body.claim_code || body.claimCode || '').trim().toUpperCase();
    const reason = String(body.reason || '').trim() || null;

    if (!username || !email || !claimCode) {
      return jsonResponse({
        success: false,
        error: 'Artist username, your email, and the private claim code are required',
      }, 400);
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return jsonResponse({ success: false, error: 'Please enter a valid email address' }, 400);
    }

    await ensureRemovalRequestsTable(context.env.DB);
    await ensureDemoColumns(context.env.DB);

    const user = await context.env.DB.prepare(`
      SELECT id, display_name, username, claim_token, is_active
      FROM users
      WHERE LOWER(username) = LOWER(?)
      LIMIT 1
    `).bind(username).first();

    if (!user || !user.claim_token) {
      return jsonResponse({
        success: false,
        error: 'This profile is not available for removal requests, or has already been claimed.',
      }, 404);
    }

    if (String(user.claim_token).toUpperCase() !== claimCode) {
      return jsonResponse({ success: false, error: 'Invalid claim code' }, 403);
    }

    const pending = await getPendingRemovalRequest(context.env.DB, user.id);
    if (pending) {
      return jsonResponse({
        success: true,
        message: 'Your removal request is already under review. We will email you once it is processed.',
        data: {
          request_id: pending.id,
          status: 'pending',
          submitted_at: pending.created_at,
        },
      });
    }

    const now = new Date().toISOString();
    const requestId = newRemovalRequestId();

    await context.env.DB.prepare(`
      INSERT INTO profile_removal_requests (
        id, user_id, username, display_name, requester_email, reason, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
    `).bind(
      requestId,
      user.id,
      user.username,
      user.display_name,
      email,
      reason,
      now,
    ).run();

    return jsonResponse({
      success: true,
      message: 'Removal request submitted. We will review it and remove your listing from Gearsh if confirmed.',
      data: {
        request_id: requestId,
        status: 'pending',
        submitted_at: now,
      },
    });
  } catch (err) {
    console.error('Profile removal request error:', err);
    return jsonResponse({ success: false, error: 'Failed to submit removal request' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
