// The Gearsh App - web/functions/api/firebase-sync.js
// Cloudflare Worker to sync Firebase Auth users with D1 database

export async function onRequestPost(context) {
  const { request, env } = context;

  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Content-Type': 'application/json',
  };

  try {
    const body = await request.json();
    const {
      firebase_uid,
      email,
      username,
      first_name,
      last_name,
      photo_url,
      provider,
      provider_id,
      is_new_user,
    } = body;

    // Validate required fields
    if (!firebase_uid || !email) {
      return new Response(
        JSON.stringify({ error: 'Firebase UID and email are required' }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Optional: Verify Firebase ID token
    // This would require the Firebase Admin SDK or a JWT verification library
    // For now, we trust the request if it has the correct structure
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Authorization required' }),
        { status: 401, headers: corsHeaders }
      );
    }

    // Check if user exists by Firebase UID
    const existingUser = await env.DB.prepare(
      'SELECT id, email, username FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    if (existingUser) {
      // Update existing user
      await env.DB.prepare(`
        UPDATE users SET
          email = ?,
          photo_url = COALESCE(?, photo_url),
          updated_at = datetime('now')
        WHERE firebase_uid = ?
      `).bind(email, photo_url, firebase_uid).run();

      return new Response(
        JSON.stringify({
          success: true,
          message: 'User synced successfully',
          user: {
            id: existingUser.id,
            email: existingUser.email,
            username: existingUser.username,
            is_new_user: false,
          },
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    // Check if email already exists (for migration from non-Firebase auth)
    const existingByEmail = await env.DB.prepare(
      'SELECT id, email, username FROM users WHERE email = ?'
    ).bind(email).first();

    if (existingByEmail) {
      // Link existing account to Firebase
      await env.DB.prepare(`
        UPDATE users SET
          firebase_uid = ?,
          provider = COALESCE(?, provider),
          provider_id = COALESCE(?, provider_id),
          photo_url = COALESCE(?, photo_url),
          updated_at = datetime('now')
        WHERE email = ?
      `).bind(firebase_uid, provider, provider_id, photo_url, email).run();

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Account linked to Firebase',
          user: {
            id: existingByEmail.id,
            email: existingByEmail.email,
            username: existingByEmail.username,
            is_new_user: false,
          },
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    // Create new user
    if (!is_new_user) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: corsHeaders }
      );
    }

    // Generate a unique username if not provided
    let finalUsername = username || email.split('@')[0];

    // Check if username exists, append random numbers if so
    const usernameExists = await env.DB.prepare(
      'SELECT id FROM users WHERE username = ?'
    ).bind(finalUsername).first();

    if (usernameExists) {
      finalUsername = `${finalUsername}${Math.floor(Math.random() * 9999)}`;
    }

    // Insert new user
    const result = await env.DB.prepare(`
      INSERT INTO users (
        firebase_uid,
        email,
        username,
        first_name,
        last_name,
        photo_url,
        provider,
        provider_id,
        role,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'user', datetime('now'), datetime('now'))
    `).bind(
      firebase_uid,
      email,
      finalUsername,
      first_name || '',
      last_name || '',
      photo_url || null,
      provider || 'email',
      provider_id || null
    ).run();

    // Get the created user
    const newUser = await env.DB.prepare(
      'SELECT id, email, username FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    return new Response(
      JSON.stringify({
        success: true,
        message: 'User created successfully',
        user: {
          id: newUser?.id,
          email: email,
          username: finalUsername,
          is_new_user: true,
        },
      }),
      { status: 201, headers: corsHeaders }
    );

  } catch (error) {
    console.error('Firebase sync error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: corsHeaders }
    );
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

