/**
 * Gearsh Creative Services Marketplace — category taxonomy.
 * Services are indexed by marketplace_category (leaf slug).
 */

export const MARKETPLACE_GROUPS = [
  {
    id: 'music-production',
    title: 'Music Production',
    icon: 'ti ti-music',
    categories: [
      { id: 'beat-makers', title: 'Beat Makers', shortTitle: 'Beats', icon: 'ti ti-wave-sine', keywords: ['beat', 'instrumental', 'type beat', 'custom beat'] },
      { id: 'producers', title: 'Producers', shortTitle: 'Production', icon: 'ti ti-adjustments', keywords: ['producer', 'production', 'arrangement', 'package'] },
      { id: 'songwriters', title: 'Songwriters', shortTitle: 'Songwriting', icon: 'ti ti-pencil', keywords: ['songwriter', 'songwriting', 'lyrics', 'topline'] },
      { id: 'arrangers', title: 'Arrangers', shortTitle: 'Arrangement', icon: 'ti ti-layout-grid', keywords: ['arranger', 'arrangement', 'orchestration'] },
    ],
  },
  {
    id: 'audio-services',
    title: 'Audio Services',
    icon: 'ti ti-headphones',
    categories: [
      { id: 'recording-studios', title: 'Recording Studios', shortTitle: 'Recording', icon: 'ti ti-microphone-2', keywords: ['recording', 'studio', 'session', 'vocals', 'tracking'] },
      { id: 'recording-engineers', title: 'Recording Engineers', shortTitle: 'Engineering', icon: 'ti ti-device-speaker', keywords: ['recording engineer', 'tracking engineer'] },
      { id: 'mixing-engineers', title: 'Mixing Engineers', shortTitle: 'Mixing', icon: 'ti ti-adjustments-horizontal', keywords: ['mix', 'mixing', 'stems', 'stem'] },
      { id: 'mastering-engineers', title: 'Mastering Engineers', shortTitle: 'Mastering', icon: 'ti ti-volume', keywords: ['master', 'mastering', 'loudness', 'final polish'] },
    ],
  },
  {
    id: 'artist-services',
    title: 'Artist Services',
    icon: 'ti ti-microphone',
    categories: [
      { id: 'feature-artists', title: 'Feature Artists', shortTitle: 'Features', icon: 'ti ti-star', keywords: ['feature', 'verse', 'collab', 'guest'] },
      { id: 'session-musicians', title: 'Session Musicians', shortTitle: 'Session', icon: 'ti ti-guitar-pick', keywords: ['session musician', 'instrumentalist', 'live band'] },
      { id: 'vocalists', title: 'Vocalists', shortTitle: 'Vocals', icon: 'ti ti-microphone', keywords: ['vocalist', 'singer', 'vocals', 'backing vocals'] },
      { id: 'djs', title: 'DJs', shortTitle: 'DJs', icon: 'ti ti-vinyl', keywords: ['dj', 'club set', 'festival set', 'live set'] },
    ],
  },
  {
    id: 'visual-content',
    title: 'Visual Content',
    icon: 'ti ti-camera',
    categories: [
      { id: 'videographers', title: 'Videographers', shortTitle: 'Video', icon: 'ti ti-video', keywords: ['video', 'videographer', 'music video', 'filming'] },
      { id: 'photographers', title: 'Photographers', shortTitle: 'Photo', icon: 'ti ti-camera', keywords: ['photo', 'photographer', 'shoot', 'portrait'] },
      { id: 'cover-designers', title: 'Cover Designers', shortTitle: 'Cover Art', icon: 'ti ti-photo', keywords: ['cover art', 'cover design', 'artwork', 'single cover'] },
      { id: 'graphic-designers', title: 'Graphic Designers', shortTitle: 'Design', icon: 'ti ti-palette', keywords: ['graphic design', 'branding', 'logo', 'visual'] },
    ],
  },
  {
    id: 'education',
    title: 'Education',
    icon: 'ti ti-school',
    categories: [
      { id: 'music-teachers', title: 'Music Teachers', shortTitle: 'Lessons', icon: 'ti ti-book', keywords: ['music teacher', 'music lesson', 'lesson'] },
      { id: 'instrument-lessons', title: 'Instrument Lessons', shortTitle: 'Instruments', icon: 'ti ti-piano', keywords: ['guitar lesson', 'piano lesson', 'drum lesson', 'instrument'] },
      { id: 'vocal-coaching', title: 'Vocal Coaching', shortTitle: 'Vocal Coach', icon: 'ti ti-microphone', keywords: ['vocal coach', 'vocal coaching', 'voice training', 'singing lesson'] },
      { id: 'production-coaching', title: 'Production Coaching', shortTitle: 'Prod Coaching', icon: 'ti ti-sliders', keywords: ['production coaching', 'beat making lesson', 'studio coaching', 'daw'] },
    ],
  },
  {
    id: 'marketing',
    title: 'Marketing',
    icon: 'ti ti-speakerphone',
    categories: [
      { id: 'social-promotion', title: 'Social Media Promotion', shortTitle: 'Social', icon: 'ti ti-brand-instagram', keywords: ['social media', 'promotion', 'instagram', 'tiktok'] },
      { id: 'playlist-promotion', title: 'Playlist Promotion', shortTitle: 'Playlists', icon: 'ti ti-playlist', keywords: ['playlist', 'spotify', 'streaming promo'] },
      { id: 'branding-services', title: 'Branding Services', shortTitle: 'Branding', icon: 'ti ti-badge', keywords: ['branding', 'brand identity', 'press kit'] },
    ],
  },
];

/** Homepage featured category shortcuts */
export const FEATURED_MARKETPLACE_SLUGS = [
  'recording-studios',
  'beat-makers',
  'mixing-engineers',
  'mastering-engineers',
  'feature-artists',
  'vocal-coaching',
  'photographers',
  'videographers',
];

const CATEGORY_BY_ID = {};
const CATEGORY_LIST = [];

MARKETPLACE_GROUPS.forEach(function (group) {
  group.categories.forEach(function (cat) {
    const entry = {
      ...cat,
      groupId: group.id,
      groupTitle: group.title,
      groupIcon: group.icon,
    };
    CATEGORY_BY_ID[cat.id] = entry;
    CATEGORY_LIST.push(entry);
  });
});

export function getMarketplaceCategories() {
  return CATEGORY_LIST.slice();
}

export function getMarketplaceGroups() {
  return MARKETPLACE_GROUPS.map(function (g) {
    return {
      id: g.id,
      title: g.title,
      icon: g.icon,
      categories: g.categories.map(function (c) {
        return { id: c.id, title: c.title, shortTitle: c.shortTitle, icon: c.icon };
      }),
    };
  });
}

export function getFeaturedCategories() {
  return FEATURED_MARKETPLACE_SLUGS.map(function (id) {
    return CATEGORY_BY_ID[id];
  }).filter(Boolean);
}

export function getCategoryById(id) {
  return CATEGORY_BY_ID[String(id || '').trim()] || null;
}

export function inferMarketplaceCategory(text, fallback) {
  const hay = String(text || '').toLowerCase();
  if (!hay) return fallback || 'producers';

  let best = null;
  let bestScore = 0;

  CATEGORY_LIST.forEach(function (cat) {
    (cat.keywords || []).forEach(function (keyword) {
      if (hay.indexOf(keyword) !== -1 && keyword.length > bestScore) {
        bestScore = keyword.length;
        best = cat.id;
      }
    });
  });

  if (best) return best;

  if (fallback) return fallback;
  if (hay.indexOf('mix') !== -1) return 'mixing-engineers';
  if (hay.indexOf('master') !== -1) return 'mastering-engineers';
  if (hay.indexOf('record') !== -1 || hay.indexOf('session') !== -1) return 'recording-studios';
  if (hay.indexOf('beat') !== -1) return 'beat-makers';
  if (hay.indexOf('photo') !== -1) return 'photographers';
  if (hay.indexOf('video') !== -1) return 'videographers';
  if (hay.indexOf('lesson') !== -1 || hay.indexOf('coach') !== -1) return 'vocal-coaching';
  if (hay.indexOf('dj') !== -1) return 'djs';
  return 'producers';
}

export function categoryMatchesQuery(categoryId, query) {
  const cat = getCategoryById(categoryId);
  if (!cat || !query) return true;
  const q = String(query).toLowerCase();
  if (cat.title.toLowerCase().indexOf(q) !== -1) return true;
  if (cat.shortTitle && cat.shortTitle.toLowerCase().indexOf(q) !== -1) return true;
  return (cat.keywords || []).some(function (k) { return q.indexOf(k) !== -1 || k.indexOf(q) !== -1; });
}
