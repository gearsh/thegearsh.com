/**
 * Marketplace service discovery — DB + showcase listings.
 */
import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';
import { buildShowcaseServices, resolveShowcaseImage } from './showcase-profile.js';
import { buildProfileUrl } from './auth-utils.js';
import {
  getCategoryById,
  inferMarketplaceCategory,
  categoryMatchesQuery,
} from './marketplace-categories.js';
import { ensureMarketplaceColumns } from './marketplace-schema.js';
import { artistDistanceKm } from './location-utils.js';

function parseSkills(raw) {
  if (Array.isArray(raw)) return raw;
  try { return JSON.parse(raw || '[]'); } catch (_) { return []; }
}

function formatPrice(amount) {
  const value = Number(amount || 0);
  if (!value) return '';
  return 'from R' + value.toLocaleString('en-ZA');
}

function serviceBookUrl(username, serviceId) {
  if (!username) return null;
  var base = '/book-gig?artist=' + encodeURIComponent(String(username).toLowerCase());
  if (serviceId) base += '&service=' + encodeURIComponent(serviceId);
  return base;
}

function mapDbRow(row) {
  const categoryId = row.marketplace_category || inferMarketplaceCategory(row.name + ' ' + (row.description || ''));
  const cat = getCategoryById(categoryId);
  return {
    id: row.id,
    name: row.name,
    description: row.description || '',
    price: Number(row.price || 0),
    price_label: formatPrice(row.price),
    price_type: row.price_type || 'fixed',
    duration_hours: row.duration_hours ? Number(row.duration_hours) : null,
    delivery_days: row.delivery_days ? Number(row.delivery_days) : null,
    marketplace_category: categoryId,
    category_title: cat ? cat.title : 'Creative Service',
    category_short: cat ? (cat.shortTitle || cat.title) : 'Service',
    category_icon: cat ? cat.icon : 'ti ti-tag',
    group_id: cat ? cat.groupId : null,
    is_featured: Boolean(row.is_featured),
    provider_name: row.provider_name,
    provider_username: row.username,
    provider_image: row.provider_image,
    provider_location: row.location || '',
    provider_country: row.country || 'South Africa',
    rating: Number(row.rating || 0),
    review_count: Number(row.review_count || 0),
    availability_status: row.availability_status || 'available',
    artist_id: row.artist_id,
    book_url: serviceBookUrl(row.username, row.id),
    profile_url: row.username ? buildProfileUrl(row.username) : null,
    is_showcase: false,
    distance_km: row.distance_km != null ? row.distance_km : null,
  };
}

function mapShowcaseService(artist, service, index) {
  const categoryId = service.marketplace_category
    || inferMarketplaceCategory(service.name + ' ' + (service.description || ''), inferFromArtist(artist));
  const cat = getCategoryById(categoryId);
  const id = service.id || ('svc_showcase_' + artist.username + '_' + (index + 1));
  return {
    id: id,
    name: service.name,
    description: service.description || '',
    price: Number(service.price || 0),
    price_label: formatPrice(service.price),
    price_type: service.price_type || 'fixed',
    duration_hours: service.duration_hours ? Number(service.duration_hours) : null,
    delivery_days: service.delivery_days || null,
    marketplace_category: categoryId,
    category_title: cat ? cat.title : 'Creative Service',
    category_short: cat ? (cat.shortTitle || cat.title) : 'Service',
    category_icon: cat ? cat.icon : 'ti ti-tag',
    group_id: cat ? cat.groupId : null,
    is_featured: Boolean(service.is_featured),
    provider_name: artist.name,
    provider_username: artist.username,
    provider_image: resolveShowcaseImage(artist),
    provider_location: artist.location || '',
    provider_country: artist.country || 'South Africa',
    rating: 4.8,
    review_count: Math.max(8, Math.round(Number(artist.masteryHours || 0) / 200)),
    availability_status: String(artist.status || 'active') === 'unavailable' ? 'unavailable' : 'available',
    artist_id: 'artist_demo_' + String(artist.username).replace(/[^a-z0-9]+/gi, '_'),
    book_url: serviceBookUrl(artist.username, id),
    profile_url: buildProfileUrl(artist.username),
    is_showcase: true,
    distance_km: null,
  };
}

function inferFromArtist(artist) {
  const skills = (artist.skills || []).join(' ').toLowerCase();
  const category = String(artist.category || '').toLowerCase();
  if (category.indexOf('dj') !== -1) return 'djs';
  if (skills.indexOf('master') !== -1) return 'mastering-engineers';
  if (skills.indexOf('mix') !== -1) return 'mixing-engineers';
  if (skills.indexOf('record') !== -1) return 'recording-studios';
  if (skills.indexOf('beat') !== -1) return 'beat-makers';
  if (category.indexOf('photo') !== -1) return 'photographers';
  if (category.indexOf('video') !== -1) return 'videographers';
  return inferMarketplaceCategory(category + ' ' + skills);
}

function buildShowcaseListings() {
  const listings = [];
  SA_SHOWCASE_ARTISTS.forEach(function (artist) {
    if (String(artist.status || 'active') === 'unavailable') return;
    const services = buildShowcaseServices(artist, artist.hourlyRate || 0);
    services.forEach(function (service, index) {
      listings.push(mapShowcaseService(artist, service, index));
    });
  });
  return listings;
}

function matchesFilters(service, filters) {
  const q = String(filters.query || '').trim().toLowerCase();
  if (q) {
    const hay = [
      service.name,
      service.description,
      service.provider_name,
      service.provider_location,
      service.category_title,
      service.marketplace_category,
    ].join(' ').toLowerCase();
    const priceMatch = q.match(/under\s+r?\s*(\d+)/i) || q.match(/below\s+r?\s*(\d+)/i);
    if (priceMatch && Number(service.price) > Number(priceMatch[1])) return false;
    if (!priceMatch && hay.indexOf(q) === -1 && !categoryMatchesQuery(service.marketplace_category, q)) {
      return false;
    }
  }

  if (filters.category && filters.category !== 'all') {
    if (service.marketplace_category !== filters.category) return false;
  }

  if (filters.minPrice > 0 && Number(service.price) < Number(filters.minPrice)) return false;
  if (filters.maxPrice > 0 && Number(service.price) > Number(filters.maxPrice)) return false;

  if (filters.location) {
    const loc = String(filters.location).toLowerCase();
    const providerLoc = String(service.provider_location || '').toLowerCase();
    if (providerLoc.indexOf(loc) === -1) return false;
  }

  if (filters.availableOnly && service.availability_status === 'unavailable') return false;

  return true;
}

function sortServices(list, sortBy, lat, lng) {
  const sorted = list.slice();
  sorted.sort(function (a, b) {
    if (sortBy === 'price_low') return Number(a.price) - Number(b.price);
    if (sortBy === 'price_high') return Number(b.price) - Number(a.price);
    if (sortBy === 'rating') return Number(b.rating) - Number(a.rating) || Number(b.review_count) - Number(a.review_count);

    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      const da = a.distance_km;
      const db = b.distance_km;
      if (da != null && db != null && da !== db) return da - db;
      if (da != null && db == null) return -1;
      if (da == null && db != null) return 1;
    }

    if (a.is_featured !== b.is_featured) return a.is_featured ? -1 : 1;
    return Number(b.review_count) - Number(a.review_count)
      || Number(b.rating) - Number(a.rating)
      || Number(a.price) - Number(b.price);
  });
  return sorted;
}

export async function searchMarketplaceServices(context, filters) {
  filters = filters || {};
  const limit = Math.min(Math.max(Number(filters.limit) || 24, 1), 100);
  const offset = Math.max(Number(filters.offset) || 0, 0);
  const sortBy = filters.sortBy || 'relevance';

  let lat = Number(filters.userLat);
  let lng = Number(filters.userLng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    const cf = context.request?.cf || {};
    lat = parseFloat(cf.latitude);
    lng = parseFloat(cf.longitude);
  }
  const sortNearby = Number.isFinite(lat) && Number.isFinite(lng);

  const dbServices = [];
  if (context.env?.DB) {
    await ensureMarketplaceColumns(context.env.DB);
    try {
      let sql = `
        SELECT
          s.id, s.name, s.description, s.price, s.duration_hours, s.delivery_days,
          s.marketplace_category, s.price_type, s.is_featured,
          ap.id as artist_id, ap.availability_status,
          ap.avg_rating as rating, ap.total_reviews as review_count,
          u.display_name as provider_name, u.username,
          u.profile_picture_url as provider_image, u.location, u.country
        FROM services s
        JOIN artist_profiles ap ON s.artist_id = ap.id
        JOIN users u ON ap.user_id = u.id
        WHERE s.is_active = 1 AND u.is_active = 1
      `;
      const params = [];

      if (filters.category && filters.category !== 'all') {
        sql += ' AND s.marketplace_category = ?';
        params.push(filters.category);
      }

      if (filters.minPrice > 0) {
        sql += ' AND s.price >= ?';
        params.push(Number(filters.minPrice));
      }
      if (filters.maxPrice > 0) {
        sql += ' AND s.price <= ?';
        params.push(Number(filters.maxPrice));
      }

      if (filters.query && String(filters.query).trim()) {
        const term = '%' + String(filters.query).trim().toLowerCase() + '%';
        sql += ` AND (
          LOWER(s.name) LIKE ? OR LOWER(s.description) LIKE ? OR
          LOWER(u.display_name) LIKE ? OR LOWER(s.search_keywords) LIKE ?
        )`;
        params.push(term, term, term, term);
      }

      sql += ' ORDER BY s.is_featured DESC, s.price ASC LIMIT 200';
      const result = await context.env.DB.prepare(sql).bind(...params).all();
      (result.results || []).forEach(function (row) {
        const mapped = mapDbRow(row);
        if (sortNearby) {
          mapped.distance_km = artistDistanceKm({
            location: mapped.provider_location,
            country: mapped.provider_country,
          }, lat, lng);
        }
        dbServices.push(mapped);
      });
    } catch (err) {
      console.error('Marketplace DB search error:', err);
    }
  }

  const seen = {};
  dbServices.forEach(function (s) {
    seen[s.provider_username + '::' + s.name.toLowerCase()] = s;
  });

  let merged = dbServices.slice();
  buildShowcaseListings().forEach(function (service) {
    const key = service.provider_username + '::' + service.name.toLowerCase();
    if (seen[key]) return;
    if (!matchesFilters(service, filters)) return;
    if (sortNearby) {
      service.distance_km = artistDistanceKm({
        location: service.provider_location,
        country: service.provider_country,
      }, lat, lng);
    }
    merged.push(service);
    seen[key] = service;
  });

  merged = merged.filter(function (s) { return matchesFilters(s, filters); });
  merged = sortServices(merged, sortBy, lat, lng);

  const total = merged.length;
  const page = merged.slice(offset, offset + limit);

  return {
    services: page,
    meta: {
      total,
      limit,
      offset,
      query: filters.query || '',
      category: filters.category || 'all',
      sortBy,
    },
  };
}

export async function getFeaturedMarketplaceServices(context, opts) {
  opts = opts || {};
  const perCategory = Number(opts.perCategory) || 3;
  const categories = opts.categories || [
    'recording-studios', 'beat-makers', 'mixing-engineers', 'mastering-engineers',
  ];

  const sections = [];
  for (const categoryId of categories) {
    const result = await searchMarketplaceServices(context, {
      category: categoryId,
      limit: perCategory,
      sortBy: 'rating',
    });
    if (result.services.length) {
      const cat = getCategoryById(categoryId);
      sections.push({
        category: categoryId,
        title: cat ? cat.title : categoryId,
        icon: cat ? cat.icon : 'ti ti-tag',
        services: result.services,
      });
    }
  }

  const featured = await searchMarketplaceServices(context, {
    limit: Number(opts.limit) || 12,
    sortBy: 'rating',
  });

  return { sections, featured: featured.services };
}

export { formatPrice, serviceBookUrl, inferMarketplaceCategory };
