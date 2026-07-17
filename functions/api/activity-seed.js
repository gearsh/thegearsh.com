/**
 * Curated activity seed for showcase artists when D1 has no posts yet.
 * Keys: lowercase username slug.
 */

export const ACTIVITY_TYPE_LABELS = {
  gig: 'Live / Upcoming',
  collaboration: 'Feature / Collab',
  photoshoot: 'Photoshoot',
  studio: 'Studio Session',
  travel: 'On Tour',
  press: 'Press / Media',
  milestone: 'Milestone',
  custom: 'Update',
};

export const ACTIVITY_SEED_BY_USERNAME = {
  shimza: [
    {
      id: 'seed_shimza_1',
      activity_type: 'gig',
      title: 'Headline set at Ultra South Africa',
      description: 'Closing the main stage with a two-hour Afro-tech journey. Cape Town, you showed out.',
      location: 'Cape Town, South Africa',
      venue: 'Cape Town Stadium',
      event_date: '2026-04-12',
      media_urls: ['assets/images/artists/shimza.jpg'],
      like_count: 284,
      comment_count: 41,
      created_at: '2026-04-13T10:00:00Z',
    },
    {
      id: 'seed_shimza_2',
      activity_type: 'collaboration',
      title: 'Festival-season remix out now',
      description: 'Dropping a reworked club cut built for festival season. Link in bio on all platforms.',
      location: 'Johannesburg, South Africa',
      media_urls: ['assets/images/artists/shimza.jpg'],
      like_count: 512,
      comment_count: 88,
      created_at: '2026-04-28T14:30:00Z',
    },
    {
      id: 'seed_shimza_3',
      activity_type: 'photoshoot',
      title: 'Press shoot for GQ South Africa',
      description: 'Behind the lens day in Sandton. Suiting up for the summer festival cover story.',
      location: 'Sandton, Johannesburg',
      media_urls: ['assets/images/artists/shimza.jpg'],
      like_count: 193,
      comment_count: 22,
      created_at: '2026-05-08T09:15:00Z',
    },
  ],
};

export function getSeedActivities(username) {
  const key = String(username || '').trim().toLowerCase();
  return ACTIVITY_SEED_BY_USERNAME[key] || [];
}

export function relativeTime(iso) {
  if (!iso) return '';
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return '';
  const diff = Math.max(0, Date.now() - then);
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return mins + 'm ago';
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return hrs + 'h ago';
  const days = Math.floor(hrs / 24);
  if (days === 1) return 'Yesterday';
  if (days < 7) return days + 'd ago';
  try {
    return new Date(iso).toLocaleDateString('en-ZA', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch (_) {
    return '';
  }
}

export function parseJsonArray(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

export function mapActivityRow(row, artistMeta, viewerUserId, likedIds) {
  if (!row) return null;
  const media = parseJsonArray(row.media_urls);
  let metadata = {};
  try {
    metadata = row.metadata_json ? JSON.parse(row.metadata_json) : {};
  } catch (_) {
    metadata = {};
  }

  return {
    id: row.id,
    activity_type: row.activity_type,
    type_label: ACTIVITY_TYPE_LABELS[row.activity_type] || 'Update',
    title: row.title,
    description: row.description || '',
    location: row.location || '',
    venue: row.venue || '',
    event_date: row.event_date || '',
    media_urls: media,
    metadata,
    is_public: Boolean(row.is_public),
    like_count: Number(row.like_count || 0),
    comment_count: Number(row.comment_count || 0),
    created_at: row.created_at,
    relative_time: relativeTime(row.created_at),
    liked_by_viewer: likedIds ? likedIds.has(row.id) : false,
    artist: artistMeta || null,
  };
}

export function mapSeedActivity(item, artistMeta) {
  return {
    ...item,
    type_label: ACTIVITY_TYPE_LABELS[item.activity_type] || 'Update',
    relative_time: relativeTime(item.created_at),
    is_public: true,
    liked_by_viewer: false,
    metadata: item.metadata || {},
    artist: artistMeta || null,
  };
}
