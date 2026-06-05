// GET /api/marketplace/categories

import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';
import { getMarketplaceGroups, getFeaturedCategories } from '../marketplace-categories.js';

export async function onRequestGet() {
  return jsonResponse({
    success: true,
    data: {
      groups: getMarketplaceGroups(),
      featured: getFeaturedCategories(),
    },
  });
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
