import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { seedRixElton } from '../demo-artists.js';
import { seedShowcaseArtist } from '../sa-showcase-artists.js';
import { findShowcaseArtist } from '../showcase-profile.js';

export async function onRequestPost(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(function () { return {}; });
    const artistSlug = String(body.artist || 'rixelton').toLowerCase();

    let result;
    let displayName = artistSlug;
    let hourlyRate = null;

    if (artistSlug === 'rixelton') {
      result = await seedRixElton(context.env.DB);
      displayName = 'Rix Elton';
      hourlyRate = result.hourly_rate || 2000;
    } else {
      const showcase = findShowcaseArtist(artistSlug);
      if (!showcase) {
        return jsonResponse({
          success: false,
          error: `Unknown claimable artist "${artistSlug}". Add them to sa-showcase-data.js first.`,
        }, 404);
      }
      displayName = showcase.name;
      hourlyRate = showcase.hourlyRate || null;
      result = await seedShowcaseArtist(context.env.DB, showcase);
    }

    const username = result.username || artistSlug;
    const claimUrl = result.claim_url || `/claim-profile.html?artist=${encodeURIComponent(username)}`;
    const removalUrl = `${claimUrl}${claimUrl.includes('?') ? '&' : '?'}mode=removal`;

    return jsonResponse({
      success: true,
      message: result.seeded
        ? `${displayName} is live and bookable on Gearsh.`
        : result.reason === 'claimed'
          ? `${displayName} has already claimed this profile — seed skipped.`
          : `${displayName} profile refreshed.`,
      data: {
        ...result,
        display_name: displayName,
        username,
        hourly_rate: hourlyRate,
        claim_url: claimUrl,
        removal_url: removalUrl,
        booking_url: `/book-gig?artist=${encodeURIComponent(username)}`,
        share_url: `/book/${encodeURIComponent(username)}`,
      },
    });
  } catch (err) {
    console.error('Seed demo artist error:', err);
    return jsonResponse({ success: false, error: 'Failed to seed claimable artist' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
