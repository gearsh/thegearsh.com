// POST /api/forgot-password
import {
  corsPreflightResponse,
  jsonResponse,
  ensureAuthTables,
  findUserByIdentifier,
} from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    const { email } = await context.request.json();

    if (!email) {
      return jsonResponse({ success: false, error: 'Email is required' }, 400);
    }

    await ensureAuthTables(context.env.DB);

    const user = await findUserByIdentifier(context.env.DB, email.trim());

    if (!user) {
      return jsonResponse({
        success: true,
        message: 'If an account exists with this email, a reset link has been sent.',
      });
    }

    const resetToken = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 3600000).toISOString();

    await context.env.DB.prepare(`
      INSERT INTO password_resets (email, token, expires_at, created_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(email) DO UPDATE SET
        token = excluded.token,
        expires_at = excluded.expires_at,
        created_at = excluded.created_at
    `).bind(user.email, resetToken, expiresAt, new Date().toISOString()).run();

    const resetUrl = `https://thegearsh.com/reset-password?token=${resetToken}&email=${encodeURIComponent(user.email)}`;

    const RESEND_API_KEY = context.env.RESEND_API_KEY;
    if (RESEND_API_KEY) {
      try {
        await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${RESEND_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: context.env.EMAIL_FROM || 'Gearsh <onboarding@resend.dev>',
            to: [user.email],
            subject: 'Reset Your Gearsh Password',
            html: `
              <p>Hi ${user.first_name || 'there'},</p>
              <p>Click the link below to reset your password (expires in 1 hour):</p>
              <p><a href="${resetUrl}">${resetUrl}</a></p>
              <p>If you did not request this, you can ignore this email.</p>
            `,
          }),
        });
      } catch (emailErr) {
        console.error('Resend error:', emailErr);
      }
    } else {
      console.warn('Password reset email not sent: RESEND_API_KEY not configured');
    }

    return jsonResponse({
      success: true,
      message: 'If an account exists with this email, a reset link has been sent.',
    });
  } catch (err) {
    console.error('Forgot password error:', err);
    return jsonResponse({ success: false, error: 'Failed to process request.' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
