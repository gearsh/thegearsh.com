// GET /api/founder/x-followers?username=thegearsh&pages=2
//
// Founder-only. Pulls the followers of a Gearsh X account, flags likely artists
// from their bios/links, and cross-references the SA showcase list so you can see
// which of your X followers are artists (and which are already on Gearsh).
//
// Requires the X_BEARER_TOKEN secret (X API v2, Basic tier or above).

import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import {
  lookupXUser,
  fetchFollowers,
  classifyFollowers,
  normalizeHandle,
} from '../x-utils.js';

const DEFAULT_USERNAME = 'thegearsh';

export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const token = context.env.X_BEARER_TOKEN;
    if (!token) {
      return jsonResponse({
        success: false,
        error: 'X_BEARER_TOKEN is not configured. Add it with: '
          + 'npx wrangler pages secret put X_BEARER_TOKEN',
      }, 503);
    }

    const url = new URL(context.request.url);
    const username = normalizeHandle(url.searchParams.get('username') || DEFAULT_USERNAME);
    const pages = Number(url.searchParams.get('pages') || 1);

    const xUser = await lookupXUser(username, token);
    const { followers, pagesFetched, hasMore } = await fetchFollowers(xUser.id, token, {
      maxPages: pages,
    });

    const artists = classifyFollowers(followers);
    const alreadyOnGearsh = artists.filter(function (a) { return a.already_on_gearsh; });
    const newProspects = artists.filter(function (a) { return !a.already_on_gearsh; });

    return jsonResponse({
      success: true,
      data: {
        account: { username: xUser.username, x_id: xUser.id, name: xUser.name },
        scanned: followers.length,
        pages_fetched: pagesFetched,
        has_more: hasMore,
        artist_count: artists.length,
        already_on_gearsh_count: alreadyOnGearsh.length,
        new_prospect_count: newProspects.length,
        artists: artists,
      },
    });
  } catch (err) {
    console.error('X followers scan error:', err);

    if (err.code === 'rate_limited') {
      return jsonResponse({
        success: false,
        error: err.message,
        reset_at: err.resetAt || null,
      }, 429);
    }
    if (err.code === 'auth') {
      return jsonResponse({
        success: false,
        error: 'X API rejected the token. Check X_BEARER_TOKEN and that the plan allows follower reads.',
      }, 502);
    }
    if (err.code === 'not_found') {
      return jsonResponse({ success: false, error: err.message }, 404);
    }
    return jsonResponse({
      success: false,
      error: err.message || 'Failed to scan X followers',
    }, 502);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
