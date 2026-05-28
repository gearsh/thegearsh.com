// GET /act/:id — shareable activity post with Open Graph preview for X/social

import {
  buildSharePageHtml,
  htmlResponse,
  resolveMediaUrl,
  DEFAULT_OG_IMAGE,
} from '../_og-utils.js';
import { ensureActivityTables } from '../api/activity-schema.js';
import {
  ACTIVITY_SEED_BY_USERNAME,
  ACTIVITY_TYPE_LABELS,
  parseJsonArray,
} from '../api/activity-seed.js';
import { findShowcaseArtist, resolveShowcaseImage } from '../api/showcase-profile.js';

function findSeedActivity(activityId) {
  const id = String(activityId || '').trim();
  if (!id) return null;

  for (const [username, items] of Object.entries(ACTIVITY_SEED_BY_USERNAME)) {
    const match = items.find(function(item) { return item.id === id; });
    if (!match) continue;
    const showcase = findShowcaseArtist(username);
    return {
      id: match.id,
      title: match.title,
      description: match.description || '',
      media_urls: match.media_urls || [],
      activity_type: match.activity_type,
      artist_name: showcase?.name || username,
      artist_username: username,
      artist_image: resolveShowcaseImage(showcase) || '',
    };
  }
  return null;
}

async function loadActivityMeta(db, activityId) {
  await ensureActivityTables(db);

  const row = await db.prepare(`
    SELECT
      aa.id,
      aa.title,
      aa.description,
      aa.media_urls,
      aa.activity_type,
      u.display_name AS artist_name,
      u.username AS artist_username,
      u.profile_picture_url AS artist_image
    FROM artist_activities aa
    JOIN artist_profiles ap ON ap.id = aa.artist_id
    JOIN users u ON u.id = ap.user_id
    WHERE aa.id = ? AND aa.is_public = 1
    LIMIT 1
  `).bind(activityId).first();

  if (row) {
    return {
      id: row.id,
      title: row.title,
      description: row.description || '',
      media_urls: parseJsonArray(row.media_urls),
      activity_type: row.activity_type,
      artist_name: row.artist_name,
      artist_username: row.artist_username,
      artist_image: row.artist_image || '',
    };
  }

  return findSeedActivity(activityId);
}

export async function onRequest(context) {
  const activityId = String(context.params.id || '').trim();
  if (!activityId) {
    return Response.redirect(new URL('/', context.request.url), 302);
  }

  const shareUrl = new URL(`/act/${encodeURIComponent(activityId)}`, context.request.url).toString();
  let title = 'Gearsh activity';
  let description = 'Latest from artists on Gearsh.';
  let image = DEFAULT_OG_IMAGE;
  let redirectUrl = new URL('/', context.request.url).toString();

  try {
    const activity = await loadActivityMeta(context.env.DB, activityId);
    if (activity) {
      const typeLabel = ACTIVITY_TYPE_LABELS[activity.activity_type] || 'Update';
      title = `${activity.title} | ${activity.artist_name} on Gearsh`;
      description = activity.description || `${typeLabel} from ${activity.artist_name} on Gearsh.`;
      const media = Array.isArray(activity.media_urls) ? activity.media_urls : [];
      image = resolveMediaUrl(
        context.request,
        media[0] || activity.artist_image || DEFAULT_OG_IMAGE
      );
      if (activity.artist_username) {
        const target = new URL('/book-gig', context.request.url);
        target.searchParams.set('artist', activity.artist_username);
        redirectUrl = target.toString();
      }
    }
  } catch (err) {
    console.error('Activity share page lookup failed:', err);
  }

  return htmlResponse(buildSharePageHtml({
    title,
    description: description.slice(0, 200),
    url: shareUrl,
    image,
    redirectUrl,
    type: 'article',
  }));
}
