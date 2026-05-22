import { jsonResponse, corsPreflightResponse, hashPassword } from '../auth-utils.js';
import {
  verifyFounderAccessKey,
  getFounderEmails,
  findUserForFounderLogin,
} from '../founder-auth.js';

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const email = String(body.email || '').trim();
    const accessKey = String(body.access_key || body.accessKey || '');
    const newPassword = String(body.new_password || body.password || '');

    if (!email || !newPassword) {
      return jsonResponse({ success: false, error: 'Email and new password are required' }, 400);
    }

    if (newPassword.length < 8) {
      return jsonResponse({ success: false, error: 'Password must be at least 8 characters' }, 400);
    }

    if (!verifyFounderAccessKey(context.env, accessKey)) {
      return jsonResponse({ success: false, error: 'Invalid founder access key' }, 403);
    }

    const founderEmails = getFounderEmails(context.env);
    if (!founderEmails.includes(email.toLowerCase())) {
      return jsonResponse({
        success: false,
        error: 'Password reset is only allowed for the founder email',
      }, 403);
    }

    const user = await findUserForFounderLogin(context.env.DB, email);
    if (!user) {
      return jsonResponse({
        success: false,
        error: 'No Gearsh account found for this email. Sign up at join-gig.html first.',
      }, 404);
    }

    const passwordHash = await hashPassword(newPassword);
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      UPDATE users
      SET password_hash = ?, user_type = 'admin', is_active = 1, updated_at = ?
      WHERE id = ?
    `).bind(passwordHash, now, user.id).run();

    return jsonResponse({
      success: true,
      message: 'Password updated. You can now sign in to Gearsh Command.',
      data: { email: user.email },
    });
  } catch (err) {
    console.error('Founder reset password error:', err);
    return jsonResponse({ success: false, error: 'Failed to reset password' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
