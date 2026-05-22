// POST /api/login — email or username + password
import {
  corsPreflightResponse,
  jsonResponse,
  verifyPassword,
  generateToken,
  findUserByIdentifier,
  buildProfileUrl,
  ensureArtistUsername,
  ensureAuthTables,
} from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    if (!context.env.DB) {
      return jsonResponse({ success: false, error: 'Database not configured' }, 500);
    }

    await ensureAuthTables(context.env.DB);

    const body = await context.request.json();
    const identifier = (body.identifier || body.email || '').trim();
    const { password } = body;

    if (!identifier || !password) {
      return jsonResponse(
        { success: false, error: 'Email/username and password are required' },
        400
      );
    }

    const user = await findUserByIdentifier(context.env.DB, identifier);
    if (!user) {
      return jsonResponse({ success: false, error: 'Invalid credentials' }, 401);
    }

    const valid = await verifyPassword(password, user.password_hash);
    if (!valid) {
      return jsonResponse({ success: false, error: 'Invalid credentials' }, 401);
    }

    let artistProfile = null;
    let profileUrl = null;
    let artistUsername = user.username || null;
    if (user.user_type === 'artist') {
      try {
        artistProfile = await context.env.DB.prepare(
          `SELECT id, category, avg_rating, total_bookings
           FROM artist_profiles WHERE user_id = ?`
        ).bind(user.id).first();
        artistUsername = await ensureArtistUsername(
          context.env.DB,
          user.id,
          user.display_name || user.first_name
        );
        profileUrl = buildProfileUrl(artistUsername);
      } catch (artistErr) {
        console.error('Artist profile load failed:', artistErr);
      }
    }

    const token = generateToken(user.id);

    return jsonResponse({
      success: true,
      message: 'Login successful',
      data: {
        user_id: user.id,
        email: user.email,
        user_type: user.user_type,
        first_name: user.first_name,
        last_name: user.last_name,
        display_name: user.display_name,
        username: artistUsername,
        profile_picture_url: user.profile_picture_url,
        is_verified: Boolean(user.is_verified),
        artist_profile: artistProfile,
        profile_url: profileUrl,
        token,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return jsonResponse(
      { success: false, error: 'Login failed. Please try again.' },
      500
    );
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
