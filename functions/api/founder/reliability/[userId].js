// GET /api/founder/reliability/:userId — ops-only reliability view

import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { getReliabilityIndex } from '../reliability-utils.js';

export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const userId = context.params.userId;
    const [index, events] = await Promise.all([
      getReliabilityIndex(context.env.DB, userId),
      context.env.DB.prepare(`
        SELECT * FROM reliability_events WHERE user_id = ? ORDER BY created_at DESC LIMIT 50
      `).bind(userId).all(),
    ]);

    return jsonResponse({
      success: true,
      data: {
        index: index || null,
        events: events.results || [],
        concerning: index
          ? (index.no_shows > 2 || index.cancellation_rate > 30 || index.dispute_rate > 20)
          : false,
      },
    });
  } catch (err) {
    console.error('Founder reliability error:', err);
    return jsonResponse({ success: false, error: 'Failed to load reliability' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
