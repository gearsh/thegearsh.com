import { corsPreflightResponse, jsonResponse, ensureAuthTables } from './auth-utils.js';
import { escapeHtml, hashResetToken, resetBaseUrl } from './password-reset-utils.js';

const publicMessage = 'If an account exists with that email, we will send a reset link.';

export async function onRequestPost(context) {
  try {
    const { email } = await context.request.json();
    const address = String(email || '').trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(address) || address.length > 254) {
      return jsonResponse({ success: false, error: 'Enter a valid email address.' }, 400);
    }
    if (!context.env.DB || !context.env.RESEND_API_KEY) {
      console.error('Password reset unavailable: database or email provider is not configured');
      return jsonResponse({ success: false, error: 'Password reset email is temporarily unavailable. Please try again later.' }, 503);
    }

    await ensureAuthTables(context.env.DB);
    const user = await context.env.DB.prepare(
      'SELECT email, first_name FROM users WHERE LOWER(email) = ? LIMIT 1'
    ).bind(address).first();
    if (!user) return jsonResponse({ success: true, message: publicMessage });

    const token = crypto.randomUUID();
    const tokenHash = await hashResetToken(token);
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 60 * 60 * 1000).toISOString();
    await context.env.DB.prepare(`
      INSERT INTO password_resets (email, token, expires_at, created_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(email) DO UPDATE SET token = excluded.token,
        expires_at = excluded.expires_at, created_at = excluded.created_at
    `).bind(user.email, tokenHash, expiresAt, now.toISOString()).run();

    const link = `${resetBaseUrl(context.request)}/reset-password?token=${encodeURIComponent(token)}`;
    let sent = false;
    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${context.env.RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: context.env.EMAIL_FROM || 'Gearsh <onboarding@resend.dev>',
          to: [user.email],
          subject: 'Reset your Gearsh password',
          html: `<p>Hi ${escapeHtml(user.first_name || 'there')},</p><p>Use this link to reset your Gearsh password. It expires in one hour.</p><p><a href="${escapeHtml(link)}">Reset password</a></p><p>If you did not request this, you can ignore this email.</p>`,
        }),
      });
      sent = response.ok;
      if (!sent) console.error('Password reset email provider returned', response.status);
    } catch (error) {
      console.error('Password reset email request failed', error);
    }
    if (!sent) {
      await context.env.DB.prepare('DELETE FROM password_resets WHERE email = ? AND token = ?').bind(user.email, tokenHash).run();
      return jsonResponse({ success: false, error: 'We could not send a reset email right now. Please try again later.' }, 503);
    }
    return jsonResponse({ success: true, message: publicMessage });
  } catch (error) {
    console.error('Forgot password error:', error);
    return jsonResponse({ success: false, error: 'Password reset is temporarily unavailable.' }, 500);
  }
}

export async function onRequestOptions() { return corsPreflightResponse(); }
