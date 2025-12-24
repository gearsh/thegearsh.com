// The Gearsh App - web/functions/api/update-profile.js
// Cloudflare Worker to update user profile data

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
    // Verify authorization
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Authorization required' }),
        { status: 401, headers: corsHeaders }
      );
    }

    const body = await request.json();
    const {
      firebase_uid,
      user_type,
      contact_number,
      country,
      location,
      skill_set,
      date_of_birth,
      gender,
    } = body;

    if (!firebase_uid) {
      return new Response(
        JSON.stringify({ error: 'Firebase UID is required' }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Check if user exists
    const existingUser = await env.DB.prepare(
      'SELECT id FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    if (!existingUser) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: corsHeaders }
      );
    }

    // Update user profile
    await env.DB.prepare(`
      UPDATE users SET
        user_type = COALESCE(?, user_type),
        phone = COALESCE(?, phone),
        country = COALESCE(?, country),
        location = COALESCE(?, location),
        skill_set = COALESCE(?, skill_set),
        date_of_birth = COALESCE(?, date_of_birth),
        gender = COALESCE(?, gender),
        updated_at = datetime('now')
      WHERE firebase_uid = ?
    `).bind(
      user_type,
      contact_number,
      country,
      location,
      skill_set,
      date_of_birth,
      gender,
      firebase_uid
    ).run();

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Profile updated successfully',
      }),
      { status: 200, headers: corsHeaders }
    );

  } catch (error) {
    console.error('Update profile error:', error);
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

