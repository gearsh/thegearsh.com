import {
  corsPreflightResponse,
  jsonResponse,
  hashPassword,
  generateToken,
  buildProfileUrl,
  ensureAuthTables,
} from './auth-utils.js';
import { ensureDemoColumns } from './demo-artists.js';
import {
  ensureRemovalRequestsTable,
  getPendingRemovalRequest,
  isUsernameRemoved,
} from './claim-profile-utils.js';

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const username = String(url.searchParams.get('artist') || url.searchParams.get('username') || '').trim();
    if (!username) {
      return jsonResponse({ success: false, error: 'Artist username is required' }, 400);
    }

    await ensureAuthTables(context.env.DB);
    await ensureDemoColumns(context.env.DB);
    await ensureRemovalRequestsTable(context.env.DB);

    const user = await context.env.DB.prepare(`
      SELECT u.id, u.display_name, u.username, u.claim_token, u.email, u.is_demo
      FROM users u
      WHERE LOWER(u.username) = LOWER(?)
      LIMIT 1
    `).bind(username).first();

    if (!user || !user.claim_token) {
      return jsonResponse({
        success: false,
        error: 'This profile is not available to claim, or has already been claimed.',
      }, 404);
    }

    if (await isUsernameRemoved(context.env.DB, username)) {
      return jsonResponse({
        success: false,
        error: 'This profile has been removed from Gearsh.',
      }, 410);
    }

    const pendingRemoval = await getPendingRemovalRequest(context.env.DB, user.id);

    return jsonResponse({
      success: true,
      data: {
        username: user.username,
        display_name: user.display_name,
        claimable: true,
        removal_pending: Boolean(pendingRemoval),
        removal_submitted_at: pendingRemoval?.created_at || null,
      },
    });
  } catch (err) {
    console.error('Claim profile lookup error:', err);
    return jsonResponse({ success: false, error: 'Failed to load claim profile' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const username = String(body.username || body.artist || '').trim();
    const email = String(body.email || '').trim().toLowerCase();
    const password = String(body.password || '');
    const claimCode = String(body.claim_code || body.claimCode || '').trim().toUpperCase();
    const phone = String(body.phone || '').trim() || null;

    if (!username || !email || !password || !claimCode) {
      return jsonResponse({
        success: false,
        error: 'Username, email, password, and claim code are required',
      }, 400);
    }

    if (password.length < 8) {
      return jsonResponse({ success: false, error: 'Password must be at least 8 characters' }, 400);
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return jsonResponse({ success: false, error: 'Please enter a valid email address' }, 400);
    }

    await ensureAuthTables(context.env.DB);
    await ensureDemoColumns(context.env.DB);

    const user = await context.env.DB.prepare(`
      SELECT id, display_name, username, claim_token, email
      FROM users
      WHERE LOWER(username) = LOWER(?)
      LIMIT 1
    `).bind(username).first();

    if (!user || !user.claim_token) {
      return jsonResponse({
        success: false,
        error: 'This profile is not available to claim, or has already been claimed.',
      }, 404);
    }

    if (String(user.claim_token).toUpperCase() !== claimCode) {
      return jsonResponse({ success: false, error: 'Invalid claim code' }, 403);
    }

    const emailTaken = await context.env.DB.prepare(`
      SELECT id FROM users WHERE LOWER(email) = LOWER(?) AND id != ?
    `).bind(email, user.id).first();

    if (emailTaken) {
      return jsonResponse({
        success: false,
        error: 'This email is already registered. Sign in instead, or use a different email.',
      }, 409);
    }

    const now = new Date().toISOString();
    const passwordHash = await hashPassword(password);

    await context.env.DB.prepare(`
      UPDATE users
      SET email = ?, password_hash = ?, phone = ?, claim_token = NULL, is_demo = 0,
          is_verified = 1, is_active = 1, updated_at = ?
      WHERE id = ?
    `).bind(email, passwordHash, phone, now, user.id).run();

    const token = await generateToken(user.id, context.env);

    return jsonResponse({
      success: true,
      message: `Welcome, ${user.display_name}. Your Gearsh profile is now yours.`,
      data: {
        user_id: user.id,
        email,
        display_name: user.display_name,
        username: user.username,
        profile_url: buildProfileUrl(user.username),
        token,
      },
    });
  } catch (err) {
    console.error('Claim profile error:', err);
    return jsonResponse({ success: false, error: 'Failed to claim profile' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
