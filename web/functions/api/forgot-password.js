// forgot-password.js - Cloudflare Pages Function
export async function onRequestPost(context) {
  // Set CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const data = await context.request.json();
    const { email } = data;

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Check if user exists in database
    const userQuery = await context.env.DB.prepare(
      'SELECT email, first_name FROM signups WHERE email = ?'
    ).bind(email).first();

    if (!userQuery) {
      // For security, don't reveal if email exists or not
      // Still return success to prevent email enumeration attacks
      return new Response(
        JSON.stringify({
          success: true,
          message: 'If an account exists with this email, a reset link has been sent.'
        }),
        { headers: corsHeaders, status: 200 }
      );
    }

    // Generate a password reset token
    const resetToken = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 3600000).toISOString(); // 1 hour expiry

    // Store the reset token in database
    try {
      // Try to create table if it doesn't exist
      await context.env.DB.prepare(`
        CREATE TABLE IF NOT EXISTS password_resets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          token TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      `).run();

      // Insert or update the reset token
      await context.env.DB.prepare(`
        INSERT INTO password_resets (email, token, expires_at, created_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(email) DO UPDATE SET
          token = excluded.token,
          expires_at = excluded.expires_at,
          created_at = excluded.created_at
      `).bind(email, resetToken, expiresAt, new Date().toISOString()).run();
    } catch (dbError) {
      console.error('Database error:', dbError);
      return new Response(
        JSON.stringify({ error: 'Failed to process request. Please try again.' }),
        { headers: corsHeaders, status: 500 }
      );
    }

    // Build reset URL - using the web app URL
    const resetUrl = `https://thegearsh-com.pages.dev/reset-password?token=${resetToken}&email=${encodeURIComponent(email)}`;

    // Send email using Resend
    const RESEND_API_KEY = context.env.RESEND_API_KEY;
    let emailSent = false;
    let emailError = null;
    let emailResult = null;

    if (RESEND_API_KEY) {
      try {
        const emailResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${RESEND_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            // Use Resend's default sender for free tier, or your verified domain
            from: context.env.EMAIL_FROM || 'Gearsh <onboarding@resend.dev>',
            to: [email],
            subject: 'Reset Your Gearsh Password',
            html: `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
              </head>
              <body style="margin: 0; padding: 0; background-color: #020617; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #020617;">
                  <tr>
                    <td align="center" style="padding: 40px 20px;">
                      <table role="presentation" width="100%" style="max-width: 600px; background-color: #0F172A; border-radius: 16px; overflow: hidden;">
                        <!-- Header -->
                        <tr>
                          <td style="padding: 40px 40px 20px; text-align: center;">
                            <h1 style="margin: 0; color: #0EA5E9; font-size: 28px; font-weight: bold;">Gearsh</h1>
                          </td>
                        </tr>
                        <!-- Content -->
                        <tr>
                          <td style="padding: 20px 40px;">
                            <h2 style="margin: 0 0 20px; color: #ffffff; font-size: 24px;">Reset Your Password</h2>
                            <p style="margin: 0 0 16px; color: #94a3b8; font-size: 16px; line-height: 1.6;">
                              Hi ${userQuery.first_name || 'there'},
                            </p>
                            <p style="margin: 0 0 24px; color: #94a3b8; font-size: 16px; line-height: 1.6;">
                              We received a request to reset your password for your Gearsh account. Click the button below to create a new password:
                            </p>
                            <!-- Button -->
                            <table role="presentation" cellspacing="0" cellpadding="0" style="margin: 0 auto 24px;">
                              <tr>
                                <td style="border-radius: 12px; background: linear-gradient(to right, #0EA5E9, #06B6D4);">
                                  <a href="${resetUrl}" target="_blank" style="display: inline-block; padding: 16px 32px; color: #ffffff; font-size: 16px; font-weight: 600; text-decoration: none;">
                                    Reset Password
                                  </a>
                                </td>
                              </tr>
                            </table>
                            <p style="margin: 0 0 16px; color: #64748b; font-size: 14px; line-height: 1.6;">
                              This link will expire in <strong style="color: #94a3b8;">1 hour</strong>.
                            </p>
                            <p style="margin: 0; color: #64748b; font-size: 14px; line-height: 1.6;">
                              If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.
                            </p>
                          </td>
                        </tr>
                        <!-- Footer -->
                        <tr>
                          <td style="padding: 30px 40px; border-top: 1px solid #1e293b;">
                            <p style="margin: 0; color: #475569; font-size: 12px; text-align: center;">
                              © ${new Date().getFullYear()} Gearsh. All rights reserved.<br>
                              Book DJs, Photographers & Creative Talent
                            </p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </body>
              </html>
            `,
          }),
        });

        emailResult = await emailResponse.json();

        if (!emailResponse.ok) {
          console.error('Resend API error:', emailResult);
          emailError = emailResult.message || JSON.stringify(emailResult);
        } else {
          emailSent = true;
          console.log('Password reset email sent successfully to:', email, 'Result:', emailResult);
        }
      } catch (err) {
        console.error('Error sending email:', err);
        emailError = err.message;
      }
    } else {
      emailError = 'RESEND_API_KEY not configured';
      console.log('RESEND_API_KEY not configured. Reset URL:', resetUrl);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'If an account exists with this email, a reset link has been sent.',
        debug: {
          emailSent,
          emailError,
          emailId: emailResult?.id,
          apiKeyConfigured: !!RESEND_API_KEY
        }
      }),
      { headers: corsHeaders, status: 200 }
    );

  } catch (err) {
    console.error('Error in forgot-password:', err);
    return new Response(
      JSON.stringify({ error: 'Failed to process password reset request' }),
      { headers: corsHeaders, status: 500 }
    );
  }
}

// Handle OPTIONS for CORS preflight
export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}

