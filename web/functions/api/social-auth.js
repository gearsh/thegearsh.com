// social-auth.js - Cloudflare Pages Function for Google/Apple Sign-In
export async function onRequestPost(context) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const data = await context.request.json();

    console.log('Social auth request:', JSON.stringify({
      email: data.email,
      provider: data.provider,
      has_id_token: !!data.id_token,
    }));

    const { email, first_name, last_name, photo_url, provider, provider_id, id_token } = data;

    // Validate required fields
    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    if (!provider || !['google', 'apple'].includes(provider)) {
      return new Response(
        JSON.stringify({ error: 'Invalid provider' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // TODO: Verify the ID token with Google/Apple
    // For production, you should verify the token:
    // - Google: https://oauth2.googleapis.com/tokeninfo?id_token=<token>
    // - Apple: Verify JWT signature with Apple's public keys

    // Check if user already exists
    let existingUser = await context.env.DB.prepare(
      'SELECT * FROM signups WHERE email = ?'
    ).bind(email).first();

    let isNewUser = false;

    if (existingUser) {
      // Update existing user with social provider info
      await context.env.DB.prepare(`
        UPDATE signups
        SET social_provider = ?,
            social_provider_id = ?,
            photo_url = COALESCE(?, photo_url)
        WHERE email = ?
      `).bind(provider, provider_id, photo_url, email).run();

    } else {
      // Create new user
      isNewUser = true;

      const user_name = email.split('@')[0];
      const created_date = new Date().toISOString();

      // Check if social columns exist, add them if not
      try {
        await context.env.DB.prepare(`
          ALTER TABLE signups ADD COLUMN social_provider TEXT
        `).run();
      } catch (e) {
        // Column might already exist
      }

      try {
        await context.env.DB.prepare(`
          ALTER TABLE signups ADD COLUMN social_provider_id TEXT
        `).run();
      } catch (e) {
        // Column might already exist
      }

      try {
        await context.env.DB.prepare(`
          ALTER TABLE signups ADD COLUMN photo_url TEXT
        `).run();
      } catch (e) {
        // Column might already exist
      }

      await context.env.DB.prepare(`
        INSERT INTO signups (
          user_name, first_name, surname, email, user_type,
          country, created_date, social_provider, social_provider_id, photo_url
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        user_name,
        first_name || '',
        last_name || '',
        email,
        'fan', // Default user type for social sign-in
        'South Africa',
        created_date,
        provider,
        provider_id,
        photo_url
      ).run();
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        is_new_user: isNewUser,
        message: isNewUser ? 'Account created successfully' : 'Signed in successfully',
        user: {
          email,
          first_name: first_name || existingUser?.first_name,
          last_name: last_name || existingUser?.surname,
          photo_url: photo_url || existingUser?.photo_url,
          provider,
        }
      }),
      { headers: corsHeaders, status: isNewUser ? 201 : 200 }
    );

  } catch (err) {
    console.error('Social auth error:', err.message, err.stack);

    return new Response(
      JSON.stringify({
        error: 'Authentication failed. Please try again.',
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

