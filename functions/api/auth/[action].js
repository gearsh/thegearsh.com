// POST /api/auth/register - Register a new user
// POST /api/auth/login - Login user

export async function onRequestPost(context) {
  try {
    const url = new URL(context.request.url);
    const action = url.pathname.split('/').pop();
    const body = await context.request.json();

    if (action === 'register') {
      return await handleRegister(context, body);
    } else if (action === 'login') {
      return await handleLogin(context, body);
    }

    return new Response(JSON.stringify({
      success: false,
      error: "Invalid action"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400,
    });
  } catch (err) {
    console.error("Auth error:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Authentication failed"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 500,
    });
  }
}

async function handleRegister(context, body) {
  const {
    email,
    password,
    first_name,
    last_name,
    user_type = 'client',
    phone,
    location,
    country = 'South Africa'
  } = body;

  // Validate required fields
  if (!email || !password || !first_name || !last_name) {
    return new Response(JSON.stringify({
      success: false,
      error: "Please fill in all required fields (email, password, first name, last name)"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400,
    });
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return new Response(JSON.stringify({
      success: false,
      error: "Please enter a valid email address"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400,
    });
  }

  // Validate password length
  if (password.length < 6) {
    return new Response(JSON.stringify({
      success: false,
      error: "Password must be at least 6 characters long"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400,
    });
  }

  try {
    // Check if email already exists
    const existing = await context.env.DB.prepare(
      `SELECT id FROM users WHERE email = ?`
    ).bind(email.toLowerCase()).first();

    if (existing) {
      return new Response(JSON.stringify({
        success: false,
        error: "This email is already registered. Please sign in or use a different email."
      }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        status: 409,
      });
    }

    // Generate user ID and hash password
    const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const passwordHash = await hashPassword(password);
    const displayName = `${first_name} ${last_name}`;

    // Insert user
    await context.env.DB.prepare(`
      INSERT INTO users (id, email, password_hash, user_type, first_name, last_name, display_name, phone, location, country)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      email.toLowerCase(),
      passwordHash,
      user_type,
      first_name,
      last_name,
      displayName,
      phone || null,
      location || null,
      country
    ).run();

    // If user is an artist, create artist profile
    if (user_type === 'artist') {
      const artistId = `artist_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      await context.env.DB.prepare(`
        INSERT INTO artist_profiles (id, user_id, category, availability_status)
        VALUES (?, ?, 'DJ', 'available')
      `).bind(artistId, userId).run();
    }

    // Generate token
    const token = generateToken(userId);

    return new Response(JSON.stringify({
      success: true,
      message: "Account created successfully!",
      data: {
        user_id: userId,
        email: email.toLowerCase(),
        user_type,
        first_name,
        last_name,
        display_name: displayName,
        token
      }
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 201,
    });
  } catch (dbError) {
    console.error("Database error during registration:", dbError);
    return new Response(JSON.stringify({
      success: false,
      error: "Registration failed. Please try again later."
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 500,
    });
  }
}

async function handleLogin(context, body) {
  const { email, password } = body;

  if (!email || !password) {
    return new Response(JSON.stringify({
      success: false,
      error: "Email and password required"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400,
    });
  }

  // Find user
  const user = await context.env.DB.prepare(`
    SELECT id, email, password_hash, user_type, first_name, last_name,
           display_name, profile_picture_url, is_verified
    FROM users
    WHERE email = ? AND is_active = 1
  `).bind(email).first();

  if (!user) {
    return new Response(JSON.stringify({
      success: false,
      error: "Invalid credentials"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 401,
    });
  }

  // Verify password
  const isValid = await verifyPassword(password, user.password_hash);
  if (!isValid) {
    return new Response(JSON.stringify({
      success: false,
      error: "Invalid credentials"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 401,
    });
  }

  // Generate token
  const token = generateToken(user.id);

  // Get artist profile if applicable
  let artistProfile = null;
  if (user.user_type === 'artist') {
    artistProfile = await context.env.DB.prepare(`
      SELECT id, category, avg_rating, total_bookings
      FROM artist_profiles
      WHERE user_id = ?
    `).bind(user.id).first();
  }

  return new Response(JSON.stringify({
    success: true,
    data: {
      user_id: user.id,
      email: user.email,
      user_type: user.user_type,
      first_name: user.first_name,
      last_name: user.last_name,
      display_name: user.display_name,
      profile_picture_url: user.profile_picture_url,
      is_verified: Boolean(user.is_verified),
      artist_profile: artistProfile,
      token
    }
  }), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*"
    },
    status: 200,
  });
}

// Simple password hashing (use bcrypt or similar in production)
async function hashPassword(password) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + 'gearsh_salt_2025');
  const hash = await crypto.subtle.digest('SHA-256', data);
  return btoa(String.fromCharCode(...new Uint8Array(hash)));
}

async function verifyPassword(password, hash) {
  const computed = await hashPassword(password);
  return computed === hash;
}

// Simple token generation (use JWT in production)
function generateToken(userId) {
  const payload = {
    userId,
    exp: Date.now() + (7 * 24 * 60 * 60 * 1000) // 7 days
  };
  return btoa(JSON.stringify(payload));
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

