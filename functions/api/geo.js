// GET /api/geo — approximate visitor location from Cloudflare request metadata

import { corsPreflightResponse, jsonResponse } from './auth-utils.js';

export async function onRequestGet(context) {
  const cf = context.request.cf || {};
  const lat = parseFloat(cf.latitude);
  const lng = parseFloat(cf.longitude);

  return jsonResponse({
    success: true,
    data: {
      lat: Number.isFinite(lat) ? lat : null,
      lng: Number.isFinite(lng) ? lng : null,
      city: cf.city || null,
      region: cf.region || cf.regionCode || null,
      country: cf.country || null,
      timezone: cf.timezone || null,
      source: 'cloudflare',
    },
  });
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
