// POST /api/login — email or username + password
import {
  corsPreflightResponse,
  jsonResponse,
  verifyPassword,
  generateToken,
  hashPassword,
  passwordNeedsRehash,
  findUserByIdentifier,
  buildProfileUrl,
  ensureArtistUsername,
  ensureAuthTables,
  getArtistProfileSummary,
  resolvePostLoginPath,
} from './auth-utils.js';
import { ensureOnboardingTables } from './onboarding-utils.js';

export async function onRequestPost(context) {
  try {
    if (!context.env.DB) {
      return jsonResponse({ success: false, error: 'Database not configured' }, 500);
    }

    await ensureAuthTables(context.env.DB);
    await ensureOnboardingTables(context.env.DB);

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

    if (passwordNeedsRehash(user.password_hash)) {
      const newHash = await hashPassword(password);
      await context.env.DB.prepare(
        `UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?`
      ).bind(newHash, new Date().toISOString(), user.id).run();
    }

    let onboardingStatus = null;
    try {
      const statusRow = await context.env.DB.prepare(
        `SELECT onboarding_status FROM users WHERE id = ?`
      ).bind(user.id).first();
      onboardingStatus = statusRow?.onboarding_status || null;
    } catch (_) {}

    let artistProfile = null;
    let profileUrl = null;
    let artistUsername = user.username || null;
    try {
      artistProfile = await getArtistProfileSummary(context.env.DB, user.id);
      if (artistProfile) {
        artistUsername = await ensureArtistUsername(
          context.env.DB,
          user.id,
          user.display_name || user.first_name
        );
        profileUrl = buildProfileUrl(artistUsername);
      } else if (user.user_type === 'artist') {
        artistUsername = await ensureArtistUsername(
          context.env.DB,
          user.id,
          user.display_name || user.first_name
        );
        profileUrl = buildProfileUrl(artistUsername);
      }
    } catch (artistErr) {
      console.error('Artist profile load failed:', artistErr);
    }

    const hasArtistDashboard = Boolean(artistProfile);
    const token = await generateToken(user.id, context.env);

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
        onboarding_status: onboardingStatus,
        artist_profile: artistProfile,
        profile_url: profileUrl,
        has_artist_dashboard: hasArtistDashboard,
        redirect_path: resolvePostLoginPath(user, hasArtistDashboard),
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
