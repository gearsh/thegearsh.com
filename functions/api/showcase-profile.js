import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';
import { buildProfileUrl } from './auth-utils.js';

/** Published SA booking fees (Briefly.co.za, celebrity agencies, 2025–2026). */
export const VERIFIED_BOOKING_RATES = {
  'tyla': 15000000,
  'black-coffee': 5500000,
  'shimza': 350000,
  'kabza-de-small': 300000,
  'cassper-nyovest': 207000,
  'nasty-c': 100000,
  'kwesta': 85000,
  'dj-maphorisa': 75000,
  'sho-madjozi': 70000,
  'dj-zinhle': 70000,
  'king-monada': 50000,
  'prince-kaybee': 50000,
  'a-reece': 50000,
  'focalistic': 30000,
  'master-kg': 120000,
  'uncle-waffles': 85000,
  'emtee': 65000,
  'blxckie': 55000,
  'sjava': 75000,
  'makhadzi': 80000,
  'the-kiffness': 45000,
  'lloyiso': 40000,
  'sun-el-musician': 55000,
  'kamo-mphela': 45000,
  'big-zulu': 55000,
  'shekhinah': 65000,
  'elaine': 55000,
  'nomcebo-zikode': 90000,
  'kelly-khumalo': 75000,
  'benjamin-dube': 85000,
  'joyous-celebration': 65000,
  'seether': 350000,
  'die-antwoord': 250000,
  'yung-swiss': 35000,
  'rixelton': 2000,
  'zj90': 3500,
  'empress-ngqama': 4500,
  'dripmaker': 3500,
  'yde': 3000,
  'scotts-maphuma': 2500,
};

/** Solo portrait overrides — prefer headshots over crowd / duo shots. */
export const SOLO_PORTRAIT_IMAGES = {
  'kabza-de-small': 'assets/images/artists/P9-Kabza-de-Small.webp',
  'cassper-nyovest': 'assets/images/artists/cassper.png',
  'nasty-c': 'assets/images/artists/nastyc.png',
  'dj-maphorisa': 'assets/images/artists/maphorisa.png',
  'black-coffee': 'assets/images/artists/coffee.png',
  'shimza': 'assets/images/artists/shimza.jpg',
  'tyla': 'assets/images/artists/tyla.jpg',
  'a-reece': 'assets/images/artists/a-reece.png',
  'kwesta': 'assets/images/artists/kwesta.png',
  'focalistic': 'assets/images/artists/focalistic.png',
  'sho-madjozi': 'assets/images/artists/sho.png',
  'dj-zinhle': 'assets/images/artists/zinhle_dj.png',
  'prince-kaybee': 'assets/images/artists/majorl.png',
  'king-monada': 'assets/images/artists/game.png',
  'emtee': 'assets/images/artists/emtee.webp',
  'uncle-waffles': 'assets/images/artists/waffles.png',
  'master-kg': 'assets/images/artists/kg.png',
  'blxckie': 'assets/images/artists/blxckie.png',
  'sjava': 'assets/images/artists/sjava.png',
  'makhadzi': 'assets/images/artists/makhadzi.png',
  'kelvin-momo': 'assets/images/artists/kelvin-momo.png',
  'mr-jazziq': 'assets/images/artists/jazziq.png',
  'major-league-djz': 'assets/images/artists/majorl.png',
  'vigro-deep': 'assets/images/artists/vigro.png',
  'felo-le-tee': 'assets/images/artists/felo-le-tee.png',
  'sun-el-musician': 'assets/images/artists/sony.png',
  'caiiro': 'assets/images/artists/caiiro.png',
  'oscar-mbo': 'assets/images/artists/mbo.png',
  'busta-929': 'assets/images/artists/busta.png',
  'mellow-sleazy': 'assets/images/artists/mellows.png',
  'mawhoo': 'assets/images/artists/mawhoo.png',
  'aymos': 'assets/images/artists/aymos.png',
  'kamo-mphela': 'assets/images/artists/kamo.png',
  'pabi-cooper': 'assets/images/artists/pabicooper.png',
  'nkosazana-daughter': 'assets/images/artists/nkosazanadaughter.png',
  'zee-nxumalo': 'assets/images/artists/zee.png',
  'kharishma': 'assets/images/artists/kharishma.png',
  'babalwa-m': 'assets/images/artists/babalwa.png',
  'dj-stokie': 'assets/images/artists/stokie.png',
  'big-zulu': 'assets/images/artists/bigzulu.png',
  'usimamane': 'assets/images/artists/usimamane.png',
  'blaq-diamond': 'assets/images/artists/blaq.png',
  'boohle': 'assets/images/artists/boohle.png',
  'the-kiffness': 'assets/images/artists/kiffness.png',
  'lloyiso': 'assets/images/artists/lloyiso.png',
  'seether': 'assets/images/artists/seether.png',
  'die-antwoord': 'assets/images/artists/antwoord.png',
  'yung-swiss': 'assets/images/artists/yung-swiss.jpg',
  'rixelton': 'assets/images/artists/rixelton.jpg',
  'empress-ngqama': 'assets/images/artists/empress-ngqama.jpg',
  'dripmaker': 'assets/images/artists/dripmaker.png',
  'yde': 'assets/images/artists/yde.png',
  'scotts-maphuma': 'assets/images/artists/scotts.png',
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

function isDjCategory(category) {
  const value = String(category || '').toLowerCase();
  return value.includes('dj') || value.includes('amapiano') || value.includes('house');
}

export function buildShowcaseServices(artist, fee) {
  const price = Number(fee || getBookingFee(artist));
  const category = artist.category || 'Live Performance';
  const dj = isDjCategory(category);

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
    is_claimable: true,
    availability_status: 'available',
    skills: Array.isArray(artist.skills) ? artist.skills : [artist.category],
    portfolio_urls: buildShowcasePortfolio(artist),
    social_links: {},
    services: buildShowcaseServices(artist, fee),
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
    await db.prepare(`
      INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `).bind(
      service.id,
      artistId,
      service.name,
      service.description,
      service.price,
      service.duration_hours,
      now
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
