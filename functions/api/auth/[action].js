// POST /api/auth/register | /api/auth/login
import {
  corsPreflightResponse,
  jsonResponse,
  hashPassword,
  verifyPassword,
  passwordNeedsRehash,
  generateToken,
  findUserByIdentifier,
  ensureAuthTables,
  formatUserResponse,
} from '../auth-utils.js';

export async function onRequestPost(context) {
  try {
    const url = new URL(context.request.url);
    const action = url.pathname.split('/').pop();
    const body = await context.request.json();

    await ensureAuthTables(context.env.DB);

    if (action === 'register') {
      return await handleRegister(context, body);
    }
    if (action === 'login') {
      return await handleLogin(context, body);
    }

    return jsonResponse({ success: false, error: 'Invalid action' }, 400);
  } catch (err) {
    console.error('Auth error:', err);
    return jsonResponse({ success: false, error: 'Authentication failed' }, 500);
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
    country = 'South Africa',
    user_name,
    username,
    skill_set,
  } = body;

  const chosenUsername = (username || user_name || '').trim() || null;

  if (!email || !password || !first_name || !last_name) {
    return jsonResponse(
      { success: false, error: 'Please fill in all required fields (email, password, first name, last name)' },
      400
    );
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return jsonResponse({ success: false, error: 'Please enter a valid email address' }, 400);
  }

  if (password.length < 6) {
    return jsonResponse({ success: false, error: 'Password must be at least 6 characters long' }, 400);
  }

  try {
    const existing = await context.env.DB.prepare(
      `SELECT id FROM users WHERE LOWER(email) = LOWER(?)`
    ).bind(email).first();

    if (existing) {
      return jsonResponse(
        { success: false, error: 'This email is already registered. Please sign in or use a different email.' },
        409
      );
    }

    const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const passwordHash = await hashPassword(password);
    const displayName = `${first_name} ${last_name}`;

    await context.env.DB.prepare(`
      INSERT INTO users (
        id, email, password_hash, user_type, first_name, last_name,
        display_name, username, phone, location, country
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      email.toLowerCase(),
      passwordHash,
      user_type,
      first_name,
      last_name,
      displayName,
      chosenUsername,
      phone || null,
      location || null,
      country
    ).run();

    if (user_type === 'artist') {
      const artistId = `artist_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      await context.env.DB.prepare(`
        INSERT INTO artist_profiles (id, user_id, category, skills, availability_status)
        VALUES (?, ?, 'DJ', ?, 'available')
      `).bind(artistId, userId, skill_set || null).run();
    }

    const token = await generateToken(userId, context.env);

    return jsonResponse({
      success: true,
      message: 'Account created successfully!',
      data: formatUserResponse(
        {
          id: userId,
          email: email.toLowerCase(),
          user_type,
          first_name,
          last_name,
          display_name: displayName,
          username: chosenUsername,
          profile_picture_url: null,
          is_verified: 0,
        },
        token
      ),
    }, 201);
  } catch (dbError) {
    console.error('Database error during registration:', dbError);
    return jsonResponse({ success: false, error: 'Registration failed. Please try again later.' }, 500);
  }
}

async function handleLogin(context, body) {
  const identifier = (body.identifier || body.email || '').trim();
  const { password } = body;

  if (!identifier || !password) {
    return jsonResponse({ success: false, error: 'Email/username and password required' }, 400);
  }

  const user = await findUserByIdentifier(context.env.DB, identifier);
  if (!user) {
    return jsonResponse({ success: false, error: 'Invalid credentials' }, 401);
  }

  const isValid = await verifyPassword(password, user.password_hash);
  if (!isValid) {
    return jsonResponse({ success: false, error: 'Invalid credentials' }, 401);
  }

  if (passwordNeedsRehash(user.password_hash)) {
    const newHash = await hashPassword(password);
    await context.env.DB.prepare(
      `UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?`
    ).bind(newHash, new Date().toISOString(), user.id).run();
  }

  let artistProfile = null;
  if (user.user_type === 'artist') {
    artistProfile = await context.env.DB.prepare(
      `SELECT id, category, avg_rating, total_bookings FROM artist_profiles WHERE user_id = ?`
    ).bind(user.id).first();
  }

  const token = await generateToken(user.id, context.env);

  return jsonResponse({
    success: true,
    data: formatUserResponse(user, token, artistProfile),
  });
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
