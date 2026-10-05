import { corsPreflightResponse, jsonResponse, hashPassword, ensureAuthTables } from './auth-utils.js';
import { hashResetToken } from './password-reset-utils.js';

export async function onRequestPost(context) {
  try {
    const { token, password } = await context.request.json();
    if (typeof token !== 'string' || !/^[0-9a-f-]{36}$/i.test(token)) {
      return jsonResponse({ success: false, error: 'Invalid or expired reset link.' }, 400);
    }
    if (typeof password !== 'string' || password.length < 8 || password.length > 128) {
      return jsonResponse({ success: false, error: 'Use a password between 8 and 128 characters.' }, 400);
    }
    if (!context.env.DB) return jsonResponse({ success: false, error: 'Password reset is temporarily unavailable.' }, 503);

    await ensureAuthTables(context.env.DB);
    const tokenHash = await hashResetToken(token);
    const now = new Date().toISOString();
    const record = await context.env.DB.prepare(
      'SELECT email FROM password_resets WHERE (token = ? OR token = ?) AND expires_at > ? LIMIT 1'
    ).bind(tokenHash, token, now).first();
    if (!record) return jsonResponse({ success: false, error: 'Invalid or expired reset link.' }, 400);

    const passwordHash = await hashPassword(password);
    const results = await context.env.DB.batch([
      context.env.DB.prepare(`UPDATE users SET password_hash = ?, updated_at = ?
        WHERE LOWER(email) = LOWER((SELECT email FROM password_resets
          WHERE email = ? AND (token = ? OR token = ?) AND expires_at > ?))`)
        .bind(passwordHash, now, record.email, tokenHash, token, now),
      context.env.DB.prepare('DELETE FROM password_resets WHERE email = ? AND (token = ? OR token = ?)')
        .bind(record.email, tokenHash, token),
    ]);
    if (!results[0]?.meta?.changes) {
      return jsonResponse({ success: false, error: 'Invalid or expired reset link.' }, 400);
    }
    return jsonResponse({ success: true, message: 'Password updated. You can sign in now.' });
  } catch (error) {
    console.error('Reset password error:', error);
    return jsonResponse({ success: false, error: 'Could not reset your password. Please try again.' }, 500);
  }
}

export async function onRequestOptions() { return corsPreflightResponse(); }
