// Shared helpers for the X (Twitter) API + artist classification.
//
// Used by founder tooling to pull the followers of a Gearsh-owned X account,
// flag likely artists from their bios, and cross-reference the SA showcase list.
//
// Requires the Cloudflare secret X_BEARER_TOKEN (X API v2, Basic tier or above).
// Set it with: npx wrangler pages secret put X_BEARER_TOKEN

import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';

const X_API_BASE = 'https://api.twitter.com/2';

// Words/phrases in a bio (or name) that strongly suggest the account is an artist.
const ARTIST_KEYWORDS = [
  'musician', 'producer', 'beatmaker', 'beat maker', 'singer', 'songwriter',
  'vocalist', 'rapper', 'mc ', 'emcee', 'dj', 'deejay', 'artist', 'recording artist',
  'instrumentalist', 'guitarist', 'pianist', 'keyboardist', 'drummer', 'bassist',
  'saxophonist', 'trumpeter', 'violinist', 'composer', 'sound engineer',
  'mix engineer', 'mastering', 'band', 'group', 'choir', 'duo', 'gospel',
  'amapiano', 'gqom', 'afrohouse', 'afro house', 'afrobeat', 'afro beat',
  'afro pop', 'afropop', 'hip hop', 'hip-hop', 'kwaito', 'maskandi', 'jazz',
  'rnb', 'r&b', 'soul', 'house music', 'live performer', 'performing artist',
  'for bookings', 'booking', 'new music', 'out now', 'streaming now',
];

// Links that almost always mean "this is an artist".
const ARTIST_LINK_HINTS = [
  'spotify.com', 'soundcloud.com', 'audiomack.com', 'music.apple.com',
  'youtube.com/channel', 'youtu.be', 'boomplay', 'bandcamp.com', 'deezer.com',
  'tidal.com', 'linktr.ee', 'fanlink', 'distrokid', 'songwhip',
];

// ---------------------------------------------------------------------------
// Normalization + showcase index
// ---------------------------------------------------------------------------

export function normalizeHandle(value) {
  return String(value || '').trim().replace(/^@+/, '').toLowerCase();
}

function slugifyName(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

// Index showcase artists by both their slug-username and their normalized name
// so an X follower can be matched on either.
const showcaseIndex = (function buildShowcaseIndex() {
  const byKey = new Map();
  SA_SHOWCASE_ARTISTS.forEach(function (artist) {
    const nameKey = slugifyName(artist.name);
    const userKey = slugifyName(artist.username);
    if (nameKey) byKey.set(nameKey, artist);
    if (userKey) byKey.set(userKey, artist);
  });
  return byKey;
})();

export function matchShowcaseArtist(profile) {
  const candidates = [
    slugifyName(profile.name),
    slugifyName(profile.username),
  ];
  for (let i = 0; i < candidates.length; i += 1) {
    const key = candidates[i];
    if (key && showcaseIndex.has(key)) {
      const artist = showcaseIndex.get(key);
      return { username: artist.username, name: artist.name };
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Artist classification
// ---------------------------------------------------------------------------

export function scoreArtist(profile) {
  const bio = String(profile.description || '').toLowerCase();
  const name = String(profile.name || '').toLowerCase();
  const haystack = name + ' ' + bio;
  const reasons = [];
  let score = 0;

  ARTIST_KEYWORDS.forEach(function (word) {
    if (haystack.includes(word)) {
      score += 2;
      reasons.push('keyword:' + word.trim());
    }
  });

  const entities = profile.entities || {};
  const urls = (entities.url && entities.url.urls) || [];
  const descUrls = (entities.description && entities.description.urls) || [];
  const allUrls = urls.concat(descUrls);
  allUrls.forEach(function (u) {
    const expanded = String(u.expanded_url || u.display_url || '').toLowerCase();
    ARTIST_LINK_HINTS.forEach(function (hint) {
      if (expanded.includes(hint)) {
        score += 3;
        reasons.push('link:' + hint);
      }
    });
  });

  // De-duplicate reasons for a cleaner report.
  const uniqueReasons = Array.from(new Set(reasons));
  return { score: score, reasons: uniqueReasons, isArtist: score >= 2 };
}

// ---------------------------------------------------------------------------
// X API client
// ---------------------------------------------------------------------------

async function xApiGet(path, token) {
  const res = await fetch(X_API_BASE + path, {
    headers: {
      Authorization: 'Bearer ' + token,
      'Content-Type': 'application/json',
    },
  });

  if (res.status === 429) {
    const reset = res.headers.get('x-rate-limit-reset');
    const err = new Error('X API rate limit reached. Try again later.');
    err.code = 'rate_limited';
    err.resetAt = reset ? Number(reset) * 1000 : null;
    throw err;
  }

  const data = await res.json().catch(function () { return {}; });
  if (!res.ok) {
    const detail = (data && (data.detail || data.title)) || ('HTTP ' + res.status);
    const err = new Error('X API error: ' + detail);
    err.code = res.status === 401 || res.status === 403 ? 'auth' : 'api';
    err.status = res.status;
    throw err;
  }
  return data;
}

export async function lookupXUser(username, token) {
  const handle = normalizeHandle(username);
  const data = await xApiGet('/users/by/username/' + encodeURIComponent(handle), token);
  if (!data.data || !data.data.id) {
    const err = new Error('X user @' + handle + ' not found.');
    err.code = 'not_found';
    throw err;
  }
  return data.data;
}

// Fetch followers, paginating up to `maxPages` (each page up to 1000 accounts).
// X read caps are tight, so callers should keep maxPages small.
export async function fetchFollowers(userId, token, options) {
  const opts = options || {};
  const maxPages = Math.max(1, Math.min(Number(opts.maxPages || 1), 15));
  const userFields = [
    'name', 'username', 'description', 'location', 'verified',
    'public_metrics', 'profile_image_url', 'url', 'entities',
  ].join(',');

  const followers = [];
  let nextToken = null;
  let pages = 0;

  do {
    let path = '/users/' + encodeURIComponent(userId) + '/followers'
      + '?max_results=1000&user.fields=' + userFields;
    if (nextToken) path += '&pagination_token=' + encodeURIComponent(nextToken);

    const page = await xApiGet(path, token);
    if (Array.isArray(page.data)) {
      page.data.forEach(function (u) { followers.push(u); });
    }
    nextToken = (page.meta && page.meta.next_token) || null;
    pages += 1;
  } while (nextToken && pages < maxPages);

  return { followers: followers, pagesFetched: pages, hasMore: Boolean(nextToken) };
}

// Run the full pipeline: classify every follower and split out likely artists.
export function classifyFollowers(followers) {
  const artists = [];

  followers.forEach(function (profile) {
    const verdict = scoreArtist(profile);
    const showcaseMatch = matchShowcaseArtist(profile);
    if (!verdict.isArtist && !showcaseMatch) return;

    artists.push({
      x_id: profile.id,
      handle: profile.username,
      name: profile.name,
      bio: profile.description || '',
      location: profile.location || '',
      verified: Boolean(profile.verified),
      followers: (profile.public_metrics && profile.public_metrics.followers_count) || 0,
      profile_image_url: profile.profile_image_url || '',
      artist_score: verdict.score,
      match_reasons: verdict.reasons,
      showcase_match: showcaseMatch,
      already_on_gearsh: Boolean(showcaseMatch),
    });
  });

  // Highest-confidence artists first; already-listed showcase names bubble up.
  artists.sort(function (a, b) {
    if (a.already_on_gearsh !== b.already_on_gearsh) {
      return a.already_on_gearsh ? -1 : 1;
    }
    return b.artist_score - a.artist_score;
  });

  return artists;
}
