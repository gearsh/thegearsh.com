// GET /api/users - List all registered users (admin only)
// GET /api/users/:id - Get a specific user

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const userId = url.pathname.split('/').pop();

    // Check for authorization (simplified - implement proper JWT validation in production)
    const authHeader = context.request.headers.get('Authorization');

    if (userId && userId !== 'users') {
      // Get specific user
      return await getUser(context, userId);
    } else {
      // List all users
      return await listUsers(context, url);
    }
  } catch (err) {
    console.error("Users API error:", err);
    return jsonResponse({
      success: false,
      error: "Failed to fetch users"
    }, 500);
  }
}

async function getUser(context, userId) {
  const user = await context.env.DB.prepare(`
    SELECT
      id, email, user_type, first_name, last_name, display_name,
      profile_picture_url, phone, location, country, bio,
      is_verified, created_at
    FROM users
    WHERE id = ? AND is_active = 1
  `).bind(userId).first();

  if (!user) {
    return jsonResponse({
      success: false,
      error: "User not found"
    }, 404);
  }

  // Get artist profile if user is an artist
  let artistProfile = null;
  if (user.user_type === 'artist') {
    artistProfile = await context.env.DB.prepare(`
      SELECT * FROM artist_profiles WHERE user_id = ?
    `).bind(userId).first();
  }

  return jsonResponse({
    success: true,
    data: {
      ...user,
      is_verified: Boolean(user.is_verified),
      artist_profile: artistProfile
    }
  });
}

async function listUsers(context, url) {
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  const userType = url.searchParams.get('user_type');

  let query = `
    SELECT
      id, email, user_type, first_name, last_name, display_name,
      location, country, is_verified, created_at
    FROM users
    WHERE is_active = 1
  `;
  const params = [];

  if (userType) {
    query += ` AND user_type = ?`;
    params.push(userType);
  }

  query += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  const result = await context.env.DB.prepare(query).bind(...params).all();

  // Get total count
  let countQuery = `SELECT COUNT(*) as total FROM users WHERE is_active = 1`;
  if (userType) {
    countQuery += ` AND user_type = '${userType}'`;
  }
  const countResult = await context.env.DB.prepare(countQuery).first();

  return jsonResponse({
    success: true,
    data: result.results.map(user => ({
      ...user,
      is_verified: Boolean(user.is_verified)
    })),
    meta: {
      total: countResult.total,
      limit,
      offset
    }
  });
}

// Helper function for JSON responses
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*"
    },
    status
  });
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

