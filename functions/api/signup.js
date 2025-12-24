// POST /api/signup - Register a new user (simplified signup endpoint)
// This endpoint auto-creates tables if they don't exist for better reliability

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    console.log("Signup request received:", JSON.stringify(body));

    const {
      email,
      password,
      first_name,
      last_name,
      user_type = 'client',
      phone,
      location,
      country = 'South Africa',
      // Additional optional fields
      skill_set,
      date_of_birth,
      gender
    } = body;

    // Validate required fields
    if (!email || !password || !first_name || !last_name) {
      return jsonResponse({
        success: false,
        error: "Please fill in all required fields"
      }, 400);
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return jsonResponse({
        success: false,
        error: "Please enter a valid email address"
      }, 400);
    }

    // Validate password length
    if (password.length < 6) {
      return jsonResponse({
        success: false,
        error: "Password must be at least 6 characters long"
      }, 400);
    }

    // Ensure tables exist
    try {
      await ensureTablesExist(context.env.DB);
      console.log("Tables ensured");
    } catch (tableErr) {
      console.error("Table creation error:", tableErr);
      // Continue anyway - tables might already exist
    }

    // Check if email already exists
    try {
      const existing = await context.env.DB.prepare(
        `SELECT id FROM users WHERE email = ?`
      ).bind(email.toLowerCase()).first();

      if (existing) {
        return jsonResponse({
          success: false,
          error: "This email is already registered. Please sign in or use a different email."
        }, 409);
      }
    } catch (checkErr) {
      console.error("Email check error:", checkErr);
      // Continue - table might not exist yet
    }

    // Generate user ID and hash password
    const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const passwordHash = await hashPassword(password);
    const displayName = `${first_name} ${last_name}`;
    const createdAt = new Date().toISOString();

    console.log("Inserting user:", userId, email.toLowerCase());

    // Insert user with explicit values
    try {
      await context.env.DB.prepare(`
        INSERT INTO users (
          id, email, password_hash, user_type, first_name, last_name,
          display_name, phone, location, country, bio, is_verified, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, ?, ?)
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
        country,
        skill_set || null,
        createdAt,
        createdAt
      ).run();

      console.log("User inserted successfully");
    } catch (insertErr) {
      console.error("Insert error:", insertErr.message);
      return jsonResponse({
        success: false,
        error: "Failed to create account. Please try again.",
        debug: insertErr.message
      }, 500);
    }

    // If user is an artist, create artist profile
    if (user_type === 'artist') {
      try {
        const artistId = `artist_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        await context.env.DB.prepare(`
          INSERT INTO artist_profiles (id, user_id, category, skills, availability_status, created_at, updated_at)
          VALUES (?, ?, 'DJ', ?, 'available', ?, ?)
        `).bind(artistId, userId, skill_set || null, createdAt, createdAt).run();
        console.log("Artist profile created");
      } catch (artistErr) {
        console.error("Artist profile error:", artistErr);
        // Don't fail the signup if artist profile fails
      }
    }

    // Generate token
    const token = generateToken(userId);

    return jsonResponse({
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
    }, 201);

  } catch (err) {
    console.error("Signup error:", err);
    return jsonResponse({
      success: false,
      error: "Registration failed. Please try again.",
      details: err.message
    }, 500);
  }
}

// Ensure required tables exist
async function ensureTablesExist(db) {
  try {
    // Create users table
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        user_type TEXT NOT NULL DEFAULT 'client',
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        display_name TEXT,
        profile_picture_url TEXT,
        phone TEXT,
        location TEXT,
        country TEXT DEFAULT 'South Africa',
        bio TEXT,
        is_verified INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `).run();

    // Create artist_profiles table
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS artist_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT UNIQUE NOT NULL,
        category TEXT DEFAULT 'DJ',
        genre TEXT,
        base_rate REAL,
        hourly_rate REAL,
        availability_status TEXT DEFAULT 'available',
        years_experience INTEGER,
        portfolio_urls TEXT,
        social_links TEXT,
        skills TEXT,
        is_trending INTEGER DEFAULT 0,
        total_bookings INTEGER DEFAULT 0,
        avg_rating REAL DEFAULT 0,
        total_reviews INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `).run();

    // Create index on email for faster lookups
    await db.prepare(`
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)
    `).run();

  } catch (err) {
    console.error("Error creating tables:", err);
    // Tables might already exist, continue
  }
}

// Simple password hashing (use bcrypt or similar in production)
async function hashPassword(password) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + 'gearsh_salt_2025');
  const hash = await crypto.subtle.digest('SHA-256', data);
  return btoa(String.fromCharCode(...new Uint8Array(hash)));
}

// Simple token generation (use JWT in production)
function generateToken(userId) {
  const payload = {
    userId,
    exp: Date.now() + (7 * 24 * 60 * 60 * 1000) // 7 days
  };
  return btoa(JSON.stringify(payload));
}

// Helper function for JSON responses
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization"
    },
    status
  });
}

// Handle preflight requests
export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}

