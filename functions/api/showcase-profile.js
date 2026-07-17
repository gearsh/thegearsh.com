import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';
import { buildProfileUrl } from './auth-utils.js';
import { inferMarketplaceCategory } from './marketplace-categories.js';

/** Verified booking fees for Gearsh roster artists. */
export const VERIFIED_BOOKING_RATES = {
  'rixelton': 2000,
  'vanz': 200,
  'zj90': 3500,
  'empress-ngqama': 4500,
  'dripmaker': 3500,
  'yde': 3000,
};

/** Solo portrait overrides — prefer headshots over crowd / duo shots. */
export const SOLO_PORTRAIT_IMAGES = {
  'rixelton': 'assets/images/artists/rixelton.jpg',
  'vanz': 'assets/images/artists/vanz.jpg',
  'empress-ngqama': 'assets/images/artists/empress-ngqama.jpg',
  'dripmaker': 'assets/images/artists/dripmaker.png',
  'yde': 'assets/images/artists/yde.png',
  'zj90': 'assets/images/artists/ZJ90.jpg',
};

const showcaseByUsername = new Map(
  SA_SHOWCASE_ARTISTS.map(function(artist) {
    return [String(artist.username || '').toLowerCase(), artist];
  })
);

export function findShowcaseArtist(identifier) {
  const key = String(identifier || '').trim().toLowerCase();
  if (!key) return null;
  return showcaseByUsername.get(key) || null;
}

export function resolveShowcaseImage(artist) {
  const username = String(artist.username || '').toLowerCase();
  return SOLO_PORTRAIT_IMAGES[username] || artist.image || null;
}

export function getBookingFee(artist) {
  const username = String(artist.username || '').toLowerCase();
  if (VERIFIED_BOOKING_RATES[username]) {
    return VERIFIED_BOOKING_RATES[username];
  }

  const hours = Number(artist.masteryHours || 0);
  if (hours >= 10000) return 500000;
  if (hours >= 7500) return 150000;
  if (hours >= 5000) return 75000;
  if (hours >= 3000) return 45000;
  if (hours >= 1000) return 25000;
  return 12000;
}

/** Lowest showcase service tier — used for homepage/listing cards. */
export function getShowcaseMinPrice(artist, fee) {
  if (Array.isArray(artist.bookingServices) && artist.bookingServices.length) {
    return Math.min.apply(null, artist.bookingServices.map(function (s) {
      return Number(s.price || 0);
    }).filter(function (p) { return p > 0; }));
  }
  const price = Number(fee || getBookingFee(artist));
  const mult = isDjCategory(artist.category) ? 0.35 : 0.45;
  return Math.round(price * mult);
}

function isDjCategory(category) {
  const value = String(category || '').toLowerCase();
  return value.includes('dj') || value.includes('amapiano') || value.includes('house');
}

function isCreativeArtsCategory(category) {
  const value = String(category || '').toLowerCase();
  return ['fashion', 'photography', 'makeup', 'tattoo', 'hair', 'videography', 'styling', 'visual',
    'music video', 'video production', 'music producer', 'post-production', 'film director', 'editing']
    .some(function(token) { return value.includes(token); });
}

function buildCreativeServices(artist, price) {
  const category = String(artist.category || '').toLowerCase();
  const username = artist.username;

  if (category.includes('fashion') || category.includes('styling')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Personal styling session',
        description: 'One-on-one styling consult for events, shoots, or wardrobe refreshes.',
        price: Math.round(price * 0.4),
        duration_hours: 2,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Red carpet / event styling',
        description: 'Full look curation for premieres, launches, and awards shows.',
        price: Math.round(price * 0.7),
        duration_hours: 4,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Custom wardrobe build',
        description: 'End-to-end wardrobe direction — fittings, sourcing, and final delivery.',
        price,
        duration_hours: 8,
      },
    ];
  }

  if (category.includes('photograph')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Portrait / headshot session',
        description: 'Studio or location portraits for artists, brands, and campaigns.',
        price: Math.round(price * 0.45),
        duration_hours: 2,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Event photography (half day)',
        description: 'Live event coverage for launches, gigs, and corporate functions.',
        price: Math.round(price * 0.75),
        duration_hours: 4,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Full-day campaign shoot',
        description: 'Complete creative direction, shooting, and handoff of selects.',
        price,
        duration_hours: 8,
      },
    ];
  }

  if (category.includes('makeup')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Event glam',
        description: 'Makeup for red carpets, parties, and on-camera appearances.',
        price: Math.round(price * 0.45),
        duration_hours: 1.5,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Bridal / special occasion',
        description: 'Trial, day-of glam, and touch-ups for weddings and milestones.',
        price: Math.round(price * 0.75),
        duration_hours: 3,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Music video / on-set glam',
        description: 'Full-day on-set makeup for shoots, performances, and content days.',
        price,
        duration_hours: 8,
      },
    ];
  }

  if (category.includes('tattoo')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Custom design consult',
        description: 'Concept sketch and placement planning for your next piece.',
        price: Math.round(price * 0.35),
        duration_hours: 1,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Tattoo session (2 hours)',
        description: 'Standard session for medium-sized custom work.',
        price: Math.round(price * 0.65),
        duration_hours: 2,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Full-day tattoo booking',
        description: 'Extended session for larger pieces — quote includes design time.',
        price,
        duration_hours: 6,
      },
    ];
  }

  if (category.includes('hair')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Event hair styling',
        description: 'Red carpet, party, and performance-ready hair.',
        price: Math.round(price * 0.45),
        duration_hours: 1.5,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Bridal hair',
        description: 'Trial, styling, and day-of support for weddings.',
        price: Math.round(price * 0.75),
        duration_hours: 3,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Wig install / full glam',
        description: 'Custom install, styling, and finishing for shoots or events.',
        price,
        duration_hours: 4,
      },
    ];
  }

  if (category.includes('music video') || category.includes('video production')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Treatment & pre-production',
        description: 'Creative concept, shot list, and production planning for your visual.',
        price: Math.round(price * 0.25),
        duration_hours: 4,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Single-day music video shoot',
        description: 'On-set direction, camera, and production for one performance or narrative video.',
        price: Math.round(price * 0.65),
        duration_hours: 10,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Full music video package',
        description: 'End-to-end production — shoot, edit, grade, and final delivery.',
        price,
        duration_hours: 16,
      },
    ];
  }

  if (category.includes('music producer') || category === 'producer') {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Custom beat / topline session',
        description: 'Original production session tailored to your sound and reference.',
        price: Math.round(price * 0.35),
        duration_hours: 3,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Production day (half day)',
        description: 'In-studio beat making, arrangement, and rough mix for one record.',
        price: Math.round(price * 0.65),
        duration_hours: 5,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Full production package',
        description: 'Complete production, vocal production, and mix-ready export.',
        price,
        duration_hours: 8,
      },
    ];
  }

  if (category.includes('video')) {
    return [
      {
        id: `svc_showcase_${username}_1`,
        name: 'Social content shoot',
        description: 'Short-form reels and campaign clips for artists and brands.',
        price: Math.round(price * 0.4),
        duration_hours: 2,
      },
      {
        id: `svc_showcase_${username}_2`,
        name: 'Event highlight reel',
        description: 'Same-day or next-day edit for launches, gigs, and festivals.',
        price: Math.round(price * 0.7),
        duration_hours: 4,
      },
      {
        id: `svc_showcase_${username}_3`,
        name: 'Music video day rate',
        description: 'Full production day — directing, shooting, and handoff of rushes.',
        price,
        duration_hours: 10,
      },
    ];
  }

  return [
    {
      id: `svc_showcase_${username}_1`,
      name: 'Creative consult',
      description: 'Discovery session for your event, shoot, or campaign.',
      price: Math.round(price * 0.4),
      duration_hours: 1,
    },
    {
      id: `svc_showcase_${username}_2`,
      name: 'Half-day booking',
      description: 'On-site creative support for events and productions.',
      price: Math.round(price * 0.7),
      duration_hours: 4,
    },
    {
      id: `svc_showcase_${username}_3`,
      name: 'Full-day booking',
      description: 'Complete creative coverage — travel quoted separately.',
      price,
      duration_hours: 8,
    },
  ];
}

export function buildShowcaseServices(artist, fee) {
  if (Array.isArray(artist.bookingServices) && artist.bookingServices.length) {
    return artist.bookingServices.map(function (service, index) {
      const category = service.marketplace_category
        || inferMarketplaceCategory(service.name + ' ' + (service.description || ''));
      return {
        id: service.id || `svc_showcase_${artist.username}_${index + 1}`,
        name: service.name,
        description: service.description || '',
        price: Number(service.price),
        duration_hours: Number(service.duration_hours || 2),
        marketplace_category: category,
        price_type: service.price_type || 'fixed',
      };
    });
  }

  const price = Number(fee || getBookingFee(artist));
  const category = artist.category || 'Live Performance';
  const dj = isDjCategory(category);
  const creative = isCreativeArtsCategory(category);

  if (creative) {
    return buildCreativeServices(artist, price);
  }

  if (dj) {
    return [
      {
        id: `svc_showcase_${artist.username}_1`,
        name: 'Club DJ set (1 hour)',
        description: 'High-energy DJ set tailored to your crowd.',
        price: Math.round(price * 0.35),
        duration_hours: 1,
      },
      {
        id: `svc_showcase_${artist.username}_2`,
        name: 'Festival / event set (2 hours)',
        description: 'Full headline DJ performance for clubs, festivals, or private events.',
        price: Math.round(price * 0.65),
        duration_hours: 2,
      },
      {
        id: `svc_showcase_${artist.username}_3`,
        name: 'Private booking (full show)',
        description: 'Complete live performance — travel and production quoted separately.',
        price,
        duration_hours: 3,
      },
    ];
  }

  return [
    {
      id: `svc_showcase_${artist.username}_1`,
      name: 'Live performance (30 min)',
      description: 'Short headline set for corporate events, launches, and private functions.',
      price: Math.round(price * 0.45),
      duration_hours: 0.5,
    },
    {
      id: `svc_showcase_${artist.username}_2`,
      name: 'Live performance (45 min)',
      description: 'Standard festival or event set with full live vocals.',
      price: Math.round(price * 0.75),
      duration_hours: 0.75,
    },
    {
      id: `svc_showcase_${artist.username}_3`,
      name: 'Headline show (full booking)',
      description: 'Complete headline performance — fees vary by venue, travel, and production.',
      price,
      duration_hours: 1,
    },
  ];
}

export function buildShowcasePortfolio(artist) {
  const image = resolveShowcaseImage(artist);
  const extras = Array.isArray(artist.portfolio) ? artist.portfolio : [];
  const urls = [image, ...extras].filter(Boolean);
  return [...new Set(urls)];
}

export function buildShowcaseArtistResponse(artist) {
  const fee = getBookingFee(artist);
  const image = resolveShowcaseImage(artist);
  const userId = `user_demo_${String(artist.username).replace(/[^a-z0-9]+/gi, '_')}`;
  const artistId = `artist_demo_${String(artist.username).replace(/[^a-z0-9]+/gi, '_')}`;
  const status = String(artist.status || 'active').toLowerCase();
  const isAvailable = status !== 'unavailable';

  return {
    artist_id: artistId,
    user_id: userId,
    username: artist.username,
    name: artist.name,
    image,
    bio: artist.bio,
    location: artist.location,
    country: artist.country || 'South Africa',
    category: artist.category,
    genre: artist.genre,
    hourly_rate: fee,
    base_rate: fee,
    rating: 4.8,
    review_count: Math.max(12, Math.round(Number(artist.masteryHours || 0) / 200)),
    total_bookings: Math.round(Number(artist.masteryHours || 0) / 10),
    mastery_hours: Number(artist.masteryHours || 0),
    is_verified: true,
    is_trending: Number(artist.masteryHours || 0) >= 5000,
    is_demo: true,
    is_claimable: isAvailable,
    is_bookable: isAvailable,
    status: status,
    availability_status: isAvailable ? 'available' : 'unavailable',
    unavailable_reason: isAvailable ? null : 'Currently unavailable for bookings.',
    skills: Array.isArray(artist.skills) ? artist.skills : [artist.category],
    portfolio_urls: buildShowcasePortfolio(artist),
    social_links: {},
    services: isAvailable ? buildShowcaseServices(artist, fee) : [],
    reviews: [],
    profile_url: buildProfileUrl(artist.username),
    claim_url: `/claim-profile.html?artist=${encodeURIComponent(String(artist.username).toLowerCase())}`,
    booking_fee: fee,
    booking_fee_source: VERIFIED_BOOKING_RATES[String(artist.username || '').toLowerCase()]
      ? 'published'
      : 'estimated',
  };
}

export async function seedShowcaseServices(db, artistId, artist, fee) {
  const now = new Date().toISOString();
  await db.prepare(`DELETE FROM services WHERE artist_id = ?`).bind(artistId).run();

  for (const service of buildShowcaseServices(artist, fee)) {
    const category = service.marketplace_category
      || inferMarketplaceCategory(service.name + ' ' + (service.description || ''));
    await db.prepare(`
      INSERT INTO services (
        id, artist_id, name, description, price, duration_hours, is_active, created_at,
        marketplace_category, price_type, search_keywords
      ) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)
    `).bind(
      service.id,
      artistId,
      service.name,
      service.description,
      service.price,
      service.duration_hours,
      now,
      category,
      service.price_type || 'fixed',
      [service.name, category, service.description].filter(Boolean).join(' ').toLowerCase()
    ).run();
  }
}

export async function seedShowcasePortfolio(db, artistId, artist) {
  const portfolio = JSON.stringify(buildShowcasePortfolio(artist));
  const now = new Date().toISOString();
  await db.prepare(`
    UPDATE artist_profiles
    SET portfolio_urls = ?, updated_at = ?
    WHERE id = ?
  `).bind(portfolio, now, artistId).run();
}
