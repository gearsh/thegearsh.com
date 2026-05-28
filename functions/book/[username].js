// GET /book/:username — shareable booking link with Open Graph preview for X/social

import {
  buildSharePageHtml,
  htmlResponse,
  resolveMediaUrl,
  DEFAULT_OG_IMAGE,
} from '../_og-utils.js';
import { resolveArtistProfile } from '../api/auth-utils.js';
import {
  findShowcaseArtist,
  resolveShowcaseImage,
  buildShowcaseArtistResponse,
} from '../api/showcase-profile.js';

async function loadArtistMeta(db, username) {
  const resolved = await resolveArtistProfile(db, username);
  if (resolved) {
    const row = await db.prepare(`
      SELECT
        u.display_name AS name,
        u.bio,
        u.profile_picture_url AS image,
        ap.category
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      WHERE ap.id = ?
      LIMIT 1
    `).bind(resolved.artist_id).first();
    if (row) return row;
  }

  const showcase = findShowcaseArtist(username);
  if (!showcase) return null;

  const data = buildShowcaseArtistResponse(showcase);
  return {
    name: data.name,
    bio: data.bio,
    image: data.image || resolveShowcaseImage(showcase),
    category: data.category,
  };
}

export async function onRequest(context) {
  const username = String(context.params.username || '').trim().toLowerCase();
  if (!username) {
    return Response.redirect(new URL('/book-gig', context.request.url), 302);
  }

  const shareUrl = new URL(`/book/${encodeURIComponent(username)}`, context.request.url).toString();
  const redirectUrl = new URL('/book-gig', context.request.url);
  redirectUrl.searchParams.set('artist', username);

  let title = `Book ${username} | Gearsh`;
  let description = 'Book South African artists directly on Gearsh. Secure booking, transparent pricing.';
  let image = DEFAULT_OG_IMAGE;

  try {
    const artist = await loadArtistMeta(context.env.DB, username);
    if (artist) {
      title = `Book ${artist.name} | Gearsh`;
      description = artist.bio || `Book ${artist.name}${artist.category ? ` (${artist.category})` : ''} for your next event on Gearsh.`;
      image = resolveMediaUrl(context.request, artist.image);
    }
  } catch (err) {
    console.error('Share page artist lookup failed:', err);
  }

  return htmlResponse(buildSharePageHtml({
    title,
    description: description.slice(0, 200),
    url: shareUrl,
    image,
    redirectUrl: redirectUrl.toString(),
  }));
}
