// signup.js - Cloudflare Pages Function
export async function onRequestPost(context) {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const data = await context.request.json();

    // Log incoming data for debugging
    console.log('Signup request received:', JSON.stringify(data));

    // Map fields from Flutter app format to database format
    const user_name = data.user_name || data.email?.split('@')[0] || '';
    const first_name = data.first_name || '';
    const surname = data.last_name || data.surname || '';
    const email = data.email || '';
    const contact_number = data.phone || data.contact_number || '';
    const user_type = data.user_type?.toLowerCase() || 'fan';
    const country = data.country || 'South Africa';
    const location = data.location || '';
    const skill_set = data.skill_set || '';
    const date_of_birth = data.date_of_birth || null;
    const gender = data.gender || null;
    const created_date = data.created_date || new Date().toISOString();
    const password = data.password || '';

    // Validate required fields
    if (!email) {
      return new Response(JSON.stringify({ error: 'Email is required' }), {
        headers: corsHeaders,
        status: 400,
      });
    }

    if (!password || password.length < 6) {
      return new Response(JSON.stringify({ error: 'Password must be at least 6 characters' }), {
        headers: corsHeaders,
        status: 400,
      });
    }

    // Check if email already exists
    const existingUser = await context.env.DB.prepare(
      'SELECT email FROM signups WHERE email = ?'
    ).bind(email).first();

    if (existingUser) {
      return new Response(JSON.stringify({ error: 'Email already registered' }), {
        headers: corsHeaders,
        status: 409,
      });
    }

    // Hash the password
    const encoder = new TextEncoder();
    const passwordData = encoder.encode(password);
    const hashBuffer = await crypto.subtle.digest('SHA-256', passwordData);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const password_hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    const stmt = context.env.DB.prepare(`
      INSERT INTO signups (
        user_name, first_name, surname, email, contact_number, user_type,
        country, location, skill_set, date_of_birth, gender, created_date, password_hash
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    await stmt
      .bind(
        user_name,
        first_name,
        surname,
        email,
        contact_number,
        user_type,
        country,
        location,
        skill_set,
        date_of_birth,
        gender,
        created_date,
        password_hash
      )
      .run();

    console.log('User registered successfully:', email);

    return new Response(JSON.stringify({ success: true, message: 'Account created successfully' }), {
      headers: corsHeaders,
      status: 201,
    });
  } catch (err) {
    console.error('Error inserting user:', err.message, err.stack);

    // Check for specific database errors
    if (err.message?.includes('UNIQUE constraint failed')) {
      return new Response(JSON.stringify({ error: 'Email already registered' }), {
        headers: corsHeaders,
        status: 409,
      });
    }

    return new Response(JSON.stringify({
      error: 'Failed to create account. Please try again.',
      debug: err.message
    }), {
      headers: corsHeaders,
      status: 500,
    });
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
