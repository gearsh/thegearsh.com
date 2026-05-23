import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureOnboardingTables } from '../onboarding-utils.js';

export async function onRequestGet(context) {
  try {
    await ensureOnboardingTables(context.env.DB);
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const result = await context.env.DB.prepare(`
      SELECT
        u.id,
        u.email,
        u.display_name,
        u.username,
        u.phone,
        u.location,
        u.onboarding_status,
        u.is_verified,
        u.created_at,
        ap.category,
        ap.hourly_rate
      FROM users u
      LEFT JOIN artist_profiles ap ON ap.user_id = u.id
      WHERE u.user_type = 'artist'
        AND (u.onboarding_status = 'pending' OR (u.is_verified = 0 AND u.onboarding_status = 'complete'))
      ORDER BY u.created_at DESC
      LIMIT 100
    `).all();

    return jsonResponse({ success: true, data: result.results || [] });
  } catch (err) {
    console.error('Founder verification queue error:', err);
    return jsonResponse({ success: false, error: 'Failed to load verification queue' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
