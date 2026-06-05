// GET /api/marketplace/services — discover creative services

import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { searchMarketplaceServices, getFeaturedMarketplaceServices } from '../marketplace-service-utils.js';

function parseFilters(url) {
  return {
    query: url.searchParams.get('q') || url.searchParams.get('query') || '',
    category: url.searchParams.get('category') || url.searchParams.get('marketplace') || 'all',
    minPrice: parseFloat(url.searchParams.get('minPrice') || url.searchParams.get('min_price') || '0'),
    maxPrice: parseFloat(url.searchParams.get('maxPrice') || url.searchParams.get('max_price') || '0'),
    location: url.searchParams.get('location') || '',
    sortBy: url.searchParams.get('sort') || url.searchParams.get('sortBy') || 'relevance',
    limit: parseInt(url.searchParams.get('limit') || '24', 10),
    offset: parseInt(url.searchParams.get('offset') || '0', 10),
    userLat: parseFloat(url.searchParams.get('lat') || ''),
    userLng: parseFloat(url.searchParams.get('lng') || ''),
    availableOnly: url.searchParams.get('available') === '1',
  };
}

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);

    if (url.searchParams.get('featured') === '1') {
      const featured = await getFeaturedMarketplaceServices(context, {
        limit: parseInt(url.searchParams.get('limit') || '12', 10),
      });
      return jsonResponse({ success: true, data: featured }, 200, {
        'Cache-Control': 'public, max-age=120, stale-while-revalidate=300',
      });
    }

    const filters = parseFilters(url);
    const result = await searchMarketplaceServices(context, filters);
    return jsonResponse({ success: true, data: result.services, meta: result.meta });
  } catch (err) {
    console.error('Marketplace services error:', err);
    return jsonResponse({ success: false, error: 'Could not load services' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const result = await searchMarketplaceServices(context, {
      query: body.query || body.q || '',
      category: body.category || body.marketplace || 'all',
      minPrice: body.minPrice || body.min_price || 0,
      maxPrice: body.maxPrice || body.max_price || 0,
      location: body.location || '',
      sortBy: body.sortBy || body.sort || 'relevance',
      limit: body.limit || 24,
      offset: body.offset || 0,
      userLat: body.userLat || body.lat,
      userLng: body.userLng || body.lng,
      availableOnly: Boolean(body.availableOnly || body.available),
    });
    return jsonResponse({ success: true, data: result.services, meta: result.meta });
  } catch (err) {
    console.error('Marketplace services POST error:', err);
    return jsonResponse({ success: false, error: 'Search failed' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
