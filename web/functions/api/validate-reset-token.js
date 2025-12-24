// validate-reset-token.js - Cloudflare Pages Function
export async function onRequestPost(context) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const data = await context.request.json();
    const { token, email } = data;

    if (!token || !email) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Token and email are required' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Check if token exists and is valid
    const resetRecord = await context.env.DB.prepare(
      'SELECT * FROM password_resets WHERE email = ? AND token = ?'
    ).bind(email, token).first();

    if (!resetRecord) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Invalid reset link' }),
        { headers: corsHeaders, status: 404 }
      );
    }

    // Check if token has expired
    const expiresAt = new Date(resetRecord.expires_at);
    if (new Date() > expiresAt) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Reset link has expired' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    return new Response(
      JSON.stringify({ valid: true }),
      { headers: corsHeaders, status: 200 }
    );

  } catch (err) {
    console.error('Error validating reset token:', err);
    return new Response(
      JSON.stringify({ valid: false, error: 'Failed to validate token' }),
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

