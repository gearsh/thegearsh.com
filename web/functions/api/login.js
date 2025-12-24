// login.js - Cloudflare Pages Function
export async function onRequestPost(context) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const data = await context.request.json();
    // Support both 'identifier' (new) and 'email' (legacy) fields
    const identifier = data.identifier || data.email;
    const { password } = data;

    // Validate required fields
    if (!identifier || !password) {
      return new Response(
        JSON.stringify({ error: 'Username/email and password are required' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Check if identifier is an email (contains @) or username
    const isEmail = identifier.includes('@');

    // Find user by email or username
    let user;
    if (isEmail) {
      user = await context.env.DB.prepare(
        'SELECT * FROM signups WHERE email = ?'
      ).bind(identifier).first();
    } else {
      user = await context.env.DB.prepare(
        'SELECT * FROM signups WHERE user_name = ?'
      ).bind(identifier).first();
    }

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Invalid username/email or password' }),
        { headers: corsHeaders, status: 401 }
      );
    }

    // Hash the provided password and compare
    const encoder = new TextEncoder();
    const passwordData = encoder.encode(password);
    const hashBuffer = await crypto.subtle.digest('SHA-256', passwordData);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const passwordHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    if (user.password_hash !== passwordHash) {
      return new Response(
        JSON.stringify({ error: 'Invalid username/email or password' }),
        { headers: corsHeaders, status: 401 }
      );
    }

    // Login successful
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Login successful',
        user: {
          email: user.email,
          username: user.user_name,
          first_name: user.first_name,
          last_name: user.surname,
          user_type: user.user_type,
        }
      }),
      { headers: corsHeaders, status: 200 }
    );

  } catch (err) {
    console.error('Login error:', err.message, err.stack);

    return new Response(
      JSON.stringify({
        error: 'Login failed. Please try again.',
        debug: err.message
      }),
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

