import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { seedRixElton } from '../demo-artists.js';

export async function onRequestPost(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(function() { return {}; });
    const artist = String(body.artist || 'rixelton').toLowerCase();

    if (artist !== 'rixelton') {
      return jsonResponse({ success: false, error: 'Only the Rix Elton demo profile is supported right now' }, 400);
    }

    const result = await seedRixElton(context.env.DB);

    return jsonResponse({
      success: true,
      message: result.seeded
        ? 'Rix Elton demo profile is live and bookable at R2,000/hour.'
        : 'Rix Elton has already claimed this profile — demo seed skipped.',
      data: result,
    });
  } catch (err) {
    console.error('Seed demo artist error:', err);
    return jsonResponse({ success: false, error: 'Failed to seed demo artist' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
