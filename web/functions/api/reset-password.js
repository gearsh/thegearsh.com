// reset-password.js - Cloudflare Pages Function
export async function onRequestPost(context) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const data = await context.request.json();
    const { token, email, password } = data;

    if (!token || !email || !password) {
      return new Response(
        JSON.stringify({ error: 'Token, email, and password are required' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    if (password.length < 6) {
      return new Response(
        JSON.stringify({ error: 'Password must be at least 6 characters' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Verify the reset token
    const resetRecord = await context.env.DB.prepare(
      'SELECT * FROM password_resets WHERE email = ? AND token = ?'
    ).bind(email, token).first();

    if (!resetRecord) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired reset link' }),
        { headers: corsHeaders, status: 404 }
      );
    }

    // Check if token has expired
    const expiresAt = new Date(resetRecord.expires_at);
    if (new Date() > expiresAt) {
      // Delete expired token
      await context.env.DB.prepare(
        'DELETE FROM password_resets WHERE email = ?'
      ).bind(email).run();

      return new Response(
        JSON.stringify({ error: 'Reset link has expired. Please request a new one.' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Hash the new password (using Web Crypto API)
    const encoder = new TextEncoder();
    const passwordData = encoder.encode(password);
    const hashBuffer = await crypto.subtle.digest('SHA-256', passwordData);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const passwordHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // Update the user's password
    await context.env.DB.prepare(
      'UPDATE signups SET password_hash = ? WHERE email = ?'
    ).bind(passwordHash, email).run();

    // Delete the used reset token
    await context.env.DB.prepare(
      'DELETE FROM password_resets WHERE email = ?'
    ).bind(email).run();

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Password has been reset successfully'
      }),
      { headers: corsHeaders, status: 200 }
    );

  } catch (err) {
    console.error('Error in reset-password:', err);
    return new Response(
      JSON.stringify({ error: 'Failed to reset password' }),
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

