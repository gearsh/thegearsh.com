// POST /api/reset-password
import {
  corsPreflightResponse,
  jsonResponse,
  hashPassword,
} from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    const { token, email, password } = await context.request.json();

    if (!token || !email || !password) {
      return jsonResponse(
        { success: false, error: 'Token, email, and password are required' },
        400
      );
    }

    if (password.length < 8) {
      return jsonResponse(
        { success: false, error: 'Password must be at least 8 characters' },
        400
      );
    }

    const resetRecord = await context.env.DB.prepare(
      'SELECT * FROM password_resets WHERE LOWER(email) = LOWER(?) AND token = ?'
    ).bind(email, token).first();

    if (!resetRecord) {
      return jsonResponse(
        { success: false, error: 'Invalid or expired reset link' },
        404
      );
    }

    if (new Date() > new Date(resetRecord.expires_at)) {
      await context.env.DB.prepare(
        'DELETE FROM password_resets WHERE LOWER(email) = LOWER(?)'
      ).bind(email).run();

      return jsonResponse(
        { success: false, error: 'Reset link has expired. Please request a new one.' },
        400
      );
    }

    const passwordHash = await hashPassword(password);

    await context.env.DB.prepare(
      'UPDATE users SET password_hash = ?, updated_at = datetime(\'now\') WHERE LOWER(email) = LOWER(?)'
    ).bind(passwordHash, email).run();

    await context.env.DB.prepare(
      'DELETE FROM password_resets WHERE LOWER(email) = LOWER(?)'
    ).bind(email).run();

    return jsonResponse({
      success: true,
      message: 'Password has been reset successfully',
    });
  } catch (err) {
    console.error('Reset password error:', err);
    return jsonResponse({ success: false, error: 'Failed to reset password' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
