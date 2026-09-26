// 100 South African artists, listed for discovery, claimable later via claim-profile

/** Featured profiles seeded on every feed load (before batch seed). */
export const PRIORITY_SHOWCASE_USERNAMES = ['vanz', 'rixelton', 'sir-lsg', 'sol-phenduka'];

export const SA_SHOWCASE_ARTISTS = [
  {
    name: 'ZJ90',
    username: 'zj90',
    image: 'assets/images/artists/ZJ90.jpg',
    category: 'DJ',
    genre: 'House · Amapiano',
    genreSlug: 'amapiano',
    location: 'Johannesburg',
    country: 'South Africa',
    masteryHours: 120,
    badge: 'Rising',
    badgeClass: 'fb-rise',
    hourlyRate: 3500,
    bio: 'ZJ90 is live on Gearsh. Claim this profile to manage bookings and payments.',
    skills: ['Amapiano', 'DJ', 'Live Performance'],
  },
  {
    name: 'Rix Elton',
    username: 'rixelton',
    image: 'assets/images/artists/rixelton.jpg',
    category: 'Amapiano DJ',
    genre: 'Amapiano DJ · Johannesburg',
    genreSlug: 'amapiano',
    location: 'Johannesburg',
    country: 'South Africa',
    masteryHours: 50,
    badge: 'Listed',
    badgeClass: 'fb-new',
    hourlyRate: 2000,
    bio: 'Rix Elton is live on Gearsh. Claim this profile to manage bookings and payments.',
    skills: ['Amapiano', 'DJ', 'Live Performance'],
  },
  {
    name: 'Vanz',
    username: 'vanz',
    image: 'assets/images/artists/vanz.jpg',
    category: 'Recording Studio',
    genre: 'Recording · Mixing · Mastering · NEXTWAV REC',
    genreSlug: 'creative-arts',
    location: 'South Africa',
    country: 'South Africa',
    phone: '+27739614039',
    masteryHours: 80,
    badge: 'Listed',
    badgeClass: 'fb-new',
    hourlyRate: 200,
    bio: 'NEXTWAV REC — Sonics From A Different Dimension. Professional recording, beat production, mixing & mastering by Vanz (@KillaBeatz99). Bookings are confirmed through Gearsh. T&Cs apply — beat sales are non-exclusive unless a license is purchased.',
    skills: ['Recording', 'Beat Production', 'Mixing', 'Mastering', 'Music Production'],
    bookingServices: [
      {
        name: 'Own Beat — Highschool Student Session',
        description: 'Recording session on your own beat. Highschool student rate at NEXTWAV REC.',
        price: 200,
        duration_hours: 2,
      },
      {
        name: 'Own Beat — Individual Session + Arrangement',
        description: 'Individual recording session on your beat with full arrangement.',
        price: 350,
        duration_hours: 2,
      },
      {
        name: 'Regular Beat — Individual Session + Arrangement',
        description: 'Individual session on a regular beat with arrangement included.',
        price: 500,
        duration_hours: 3,
      },
      {
        name: 'Custom Made Beat Package',
        description: 'Recording sessions + beat session + arrangement. Custom beat built for your track.',
        price: 800,
        duration_hours: 4,
      },
      {
        name: 'Ultimate Package',
        description: 'Recording sessions + beat sessions + arrangement — full NEXTWAV REC production package.',
        price: 1000,
        duration_hours: 6,
      },
      {
        name: 'Mixing — 1 to 10 Stems',
        description: 'Professional mix for projects with up to 10 stems.',
        price: 200,
        duration_hours: 2,
      },
      {
        name: 'Mixing — 11 to 20 Stems',
        description: 'Professional mix for projects with 11–20 stems.',
        price: 300,
        duration_hours: 2,
      },
      {
        name: 'Mixing — 21 to 30 Stems',
        description: 'Professional mix for projects with 21–30 stems.',
        price: 400,
        duration_hours: 3,
      },
      {
        name: 'Mixing — 31 to 40 Stems',
        description: 'Professional mix for projects with 31–40 stems.',
        price: 500,
        duration_hours: 3,
      },
      {
        name: 'Mixing — 41 to 50 Stems',
        description: 'Professional mix for projects with 41–50 stems.',
        price: 600,
        duration_hours: 4,
      },
      {
        name: 'Mixing — 51+ Stems',
        description: 'Professional mix for large sessions with 51 or more stems.',
        price: 700,
        duration_hours: 4,
      },
      {
        name: 'Mastering',
        description: 'Final polish and loudness optimisation for release-ready audio.',
        price: 300,
        duration_hours: 1,
      },
    ],
  },
  {
    name: 'Sir LSG',
    username: 'sir-lsg',
    image: 'assets/images/artists/artists.png',
    category: 'Producer & DJ',
    genre: 'Soulful House · Afro House · Johannesburg',
    genreSlug: 'house',
    location: 'Johannesburg',
    country: 'South Africa',
    masteryHours: 7200,
    badge: 'Expert',
    badgeClass: 'fb-feat',
    hourlyRate: 45000,
    bio: 'Lesego Sefako — award-winning soulful house producer, DJ, and curator behind Bread4Soul Sessions. Known for Moving Circles and global hits including Sax in the City. Claim this profile to manage bookings and payments, or request removal if you prefer not to be listed.',
    skills: ['Soulful House', 'Production', 'DJ', 'Live Performance', 'Remix'],
    bookingServices: [
      {
        name: 'DJ Set — Club / Event',
        description: 'Soulful and Afro house set for clubs, festivals, and private events.',
        price: 45000,
        duration_hours: 2,
      },
      {
        name: 'Production — Original or Remix',
        description: 'Custom production or remix in Sir LSG’s soulful house style.',
        price: 25000,
        delivery_days: 21,
      },
      {
        name: 'Live Performance — Bread4Soul style',
        description: 'Live soulful house performance with keys and vocalists (venue-dependent).',
        price: 85000,
        duration_hours: 2,
      },
    ],
  },
  {
    name: 'Sol',
    username: 'sol-phenduka',
    image: 'assets/images/artists/artists.png',
    category: 'DJ',
    genre: 'Hip-Hop · Amapiano · Johannesburg',
    genreSlug: 'hip-hop',
    location: 'Johannesburg',
    country: 'South Africa',
    phone: '+27817432499',
    masteryHours: 8000,
    badge: 'Expert',
    badgeClass: 'fb-feat',
    hourlyRate: 35000,
    bio: 'Sol Phenduka — DJ and co-host of Podcast and Chill with MacG (@podcastwithmacg), SA’s number-one podcast. Book Sol for club, festival, and private DJ sets. Claim this profile to manage bookings and payments, or request removal if you prefer not to be listed.',
    skills: ['DJ', 'Hip-Hop', 'Amapiano', 'Live Performance', 'Podcast Host'],
    bookingServices: [
      {
        name: 'DJ Set — Club / Event',
        description: 'Hip-hop and amapiano set for clubs, festivals, and private events.',
        price: 35000,
        duration_hours: 2,
      },
      {
        name: 'Corporate / Brand Event',
        description: 'DJ set or hosted appearance for corporate functions and brand activations.',
        price: 55000,
        duration_hours: 3,
      },
      {
        name: 'Private Party',
        description: 'Curated DJ set for birthdays, launches, and private celebrations.',
        price: 45000,
        duration_hours: 3,
      },
    ],
  },
  {
    name: 'Empress Ngqama',
    username: 'empress-ngqama',
    image: 'assets/images/artists/empress-ngqama.jpg',
    category: 'Afro-Soul',
    genre: 'Afro-Soul · Reggae',
    genreSlug: 'afropop',
    location: 'Eastern Cape',
    country: 'South Africa',
    masteryHours: 95,
    badge: 'Listed',
    badgeClass: 'fb-new',
    hourlyRate: 4500,
    bio: 'Empress Ngqama is live on Gearsh. Claim this profile to manage bookings and payments.',
    skills: ['Afro-Soul', 'Live Performance'],
  },
  {
    name: 'Dripmaker',
    username: 'dripmaker',
    image: 'assets/images/artists/dripmaker.png',
    category: 'Fashion',
    genre: 'Fashion · Thohoyandou',
    genreSlug: 'creative-arts',
    location: 'Thohoyandou',
    country: 'South Africa',
    masteryHours: 180,
    badge: 'Rising',
    badgeClass: 'fb-rise',
    hourlyRate: 3500,
    bio: 'Dripmaker is live on Gearsh. Claim this profile to manage bookings and payments.',
    skills: ['Fashion', 'Live Performance'],
  },
  {
    name: 'Y.D.E',
    username: 'yde',
    image: 'assets/images/artists/yde.png',
    category: 'Hip Hop',
    genre: 'Hip Hop · Louis Trichardt',
    genreSlug: 'hip-hop',
    location: 'Louis Trichardt',
    country: 'South Africa',
    masteryHours: 0,
    badge: 'Listed',
    badgeClass: 'fb-new',
    hourlyRate: 3000,
    bio: 'Y.D.E is live on Gearsh. Claim this profile to manage bookings and payments.',
    skills: ['Hip Hop', 'Rap', 'Live Performance'],
  },
];

export const GENRE_FEATURED_ORDER = {
  'hip-hop': ['yde'],
  'creative-arts': ['vanz', 'dripmaker'],
  'amapiano': ['rixelton', 'zj90'],
};

/** Generic placeholder paths. artists using these sink in feed ordering. */
const PLACEHOLDER_IMAGE_MARKERS = [
  '/artists.png',
  'artists/artists.png',
  'icon-512',
  '/icons/icon',
];

export function isPlaceholderImage(path) {
  const value = String(path || '').toLowerCase();
  if (!value) return true;
  return PLACEHOLDER_IMAGE_MARKERS.some(function(marker) {
    return value.includes(marker);
  });
}

export function artistHasSoloPortrait(artist) {
  if (!artist) return false;
  if (artist.has_solo_portrait === true) return true;
  if (artist.has_solo_portrait === false) return false;
  return !isPlaceholderImage(artist.image);
}

export function compareArtistsForGenre(genreSlug, a, b) {
  const order = GENRE_FEATURED_ORDER[genreSlug] || [];
  const usernameA = String(a.username || '').toLowerCase();
  const usernameB = String(b.username || '').toLowerCase();
  const rankA = order.indexOf(usernameA);
  const rankB = order.indexOf(usernameB);
  const featuredA = rankA >= 0 ? rankA : order.length;
  const featuredB = rankB >= 0 ? rankB : order.length;

  if (featuredA !== featuredB) return featuredA - featuredB;

  const soloA = artistHasSoloPortrait(a) ? 1 : 0;
  const soloB = artistHasSoloPortrait(b) ? 1 : 0;
  if (soloB !== soloA) return soloB - soloA;

  const hoursA = Number(a.mastery_hours ?? a.masteryHours ?? 0);
  const hoursB = Number(b.mastery_hours ?? b.masteryHours ?? 0);
  if (hoursB !== hoursA) return hoursB - hoursA;

  if (a.bookable !== b.bookable) return a.bookable ? -1 : 1;

  return Number(b.rating || 0) - Number(a.rating || 0)
    || Number(b.review_count || 0) - Number(a.review_count || 0)
    || Number(b.total_bookings || 0) - Number(a.total_bookings || 0);
}

export const GENRE_FEED_CATEGORIES = [
  {
    id: 'mastery-legends',
    title: 'Mastery legends',
    subtitle: 'Top artists. 10,000 hours of craft and countless stages',
    icon: 'ti ti-crown',
  },
  {
    id: 'genre-amapiano',
    title: 'Amapiano',
    subtitle: 'Log drums, soulful keys, and SA\'s biggest sound',
    icon: 'ti ti-piano',
  },
  {
    id: 'genre-hip-hop',
    title: 'Hip Hop',
    subtitle: 'Bars, flow, and culture from Pretoria to Durban',
    icon: 'ti ti-microphone',
  },
  {
    id: 'genre-house',
    title: 'House & Afro House',
    subtitle: 'From township clubs to global dance floors',
    icon: 'ti ti-vinyl',
  },
  {
    id: 'genre-afropop',
    title: 'Afropop & R&B',
    subtitle: 'Melody, soul, and African pop excellence',
    icon: 'ti ti-heart',
  },
  {
    id: 'genre-gospel',
    title: 'Gospel',
    subtitle: 'Praise, worship, and inspiration',
    icon: 'ti ti-pray',
  },
  {
    id: 'genre-xigaza-lekompo',
    title: 'Xigaza & Lekompo',
    subtitle: 'Limpopo street sound. Polokwane, Sekhukhune, Giyani',
    icon: 'ti ti-flame',
  },
  {
    id: 'genre-maskandi',
    title: 'Maskandi & Traditional',
    subtitle: 'Roots, culture, and storytelling',
    icon: 'ti ti-feather',
  },
  {
    id: 'genre-gqom',
    title: 'Gqom & Dance',
    subtitle: 'Hard beats built for the dancefloor',
    icon: 'ti ti-bolt',
  },
  {
    id: 'genre-creative-arts',
    title: 'Creative & event arts',
    subtitle: 'Music videos, producers, fashion, photo, makeup, tattoos, and visual culture',
    icon: 'ti ti-palette',
  },
  {
    id: 'genre-other',
    title: 'More genres',
    subtitle: 'Rock, comedy, tech, and beyond',
    icon: 'ti ti-stars',
  },
];

export function resolveArtistGenreSlug(category, genreLabel) {
  const label = String(genreLabel || '').toLowerCase();
  // Xigaza & Lekompo checks run first so 'Bolo House' isn't mis-routed to
  // generic 'house' and 'Bolobedu' is no longer treated as Maskandi.
  if (label.includes('xigaza') || label.includes('lekompo')) return 'xigaza-lekompo';
  if (label.includes('bolobedu') || label.includes('bolo house')) return 'xigaza-lekompo';
  if (label.includes('tsonga') || label.includes('xitsonga') || label.includes('shangaan') || label.includes('shimatsatsa')) return 'xigaza-lekompo';
  if (label.includes('amapiano')) return 'amapiano';
  if (label.includes('hip hop') || label.includes('rap')) return 'hip-hop';
  if (label.includes('house') || label.includes('afro house') || label.startsWith('dj')) return 'house';
  if (label.includes('gospel')) return 'gospel';
  if (label.includes('maskandi')) return 'maskandi';
  if (label.includes('gqom') || label.includes('dance')) return 'gqom';
  if (label.includes('fashion') || label.includes('styling') || label.includes('wardrobe')) return 'creative-arts';
  if (label.includes('photograph') || label.includes('videograph') || label.includes('visual')) return 'creative-arts';
  if (label.includes('makeup') || label.includes('mua') || label.includes('beauty')) return 'creative-arts';
  if (label.includes('tattoo') || label.includes('ink')) return 'creative-arts';
  if (label.includes('hair') || label.includes('barber')) return 'creative-arts';
  if (label.includes('music video') || label.includes('video prod')) return 'creative-arts';
  if (label.includes('post-prod') || label.includes('editing') || label.includes('director')) return 'creative-arts';
  if (label.includes('music prod') || (label.includes('producer') && !label.includes('lekompo'))) return 'creative-arts';
  if (label.includes('recording') || label.includes('mixing') || label.includes('mastering') || label.includes('nextwav')) return 'creative-arts';
  if (['afropop', 'r&b', 'soul', 'acapella', 'pop'].some(function(token) { return label.includes(token); })) return 'afropop';
  const map = {
    'Acapella': 'afropop',
    'Afro House': 'house',
    'Afropop': 'afropop',
    'Amapiano': 'amapiano',
    'Amapiano DJ': 'amapiano',
    'Bolobedu': 'xigaza-lekompo',
    'Bolobedu House': 'xigaza-lekompo',
    'Comedy': 'other',
    'DJ': 'house',
    'Dance': 'gqom',
    'Electronic': 'other',
    'Fashion': 'creative-arts',
    'Folk': 'other',
    'Gospel': 'gospel',
    'Gqom': 'gqom',
    'Hair Stylist': 'creative-arts',
    'Hip Hop': 'hip-hop',
    'House': 'house',
    'Lekompo': 'xigaza-lekompo',
    'Makeup Artist': 'creative-arts',
    'Maskandi': 'maskandi',
    'Music Producer': 'creative-arts',
    'Music Video Production': 'creative-arts',
    'Photography': 'creative-arts',
    'Pop': 'afropop',
    'Post-Production': 'creative-arts',
    'R&B': 'afropop',
    'Rap-Rave': 'hip-hop',
    'Recording Studio': 'creative-arts',
    'Rock': 'other',
    'Shangaan': 'xigaza-lekompo',
    'Styling': 'creative-arts',
    'Tattoo Artist': 'creative-arts',
    'Tsonga': 'xigaza-lekompo',
    'Tsonga Disco': 'xigaza-lekompo',
    'Video Production': 'creative-arts',
    'Videography': 'creative-arts',
    'Visual Art': 'creative-arts',
    'Xigaza': 'xigaza-lekompo',
    'Xitsonga': 'xigaza-lekompo',
    'Xitsonga Traditional': 'xigaza-lekompo',
  };
  return map[String(category || '')] || 'other';
}

export function toMarketingShowcase(artist) {
  return {
    name: artist.name,
    username: artist.username,
    image: artist.image,
    genre: artist.genre,
    category: artist.category,
    genreSlug: artist.genreSlug,
    badge: artist.badge,
    badgeClass: artist.badgeClass,
    masteryHours: artist.masteryHours,
    hourlyRate: artist.hourlyRate,
    large: artist.large || false,
  };
}

export const SHOWCASE = SA_SHOWCASE_ARTISTS.map(toMarketingShowcase);