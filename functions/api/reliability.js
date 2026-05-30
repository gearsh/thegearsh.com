// POST /api/reliability/events — record private reliability event (auth)
// GET  /api/reliability/me — current user's index (artist/client own data)

import { corsPreflightResponse, jsonResponse, requireAuth } from './auth-utils.js';
import { recordReliabilityEvent, getReliabilityIndex } from './reliability-utils.js';

export async function onRequestGet(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const userId = url.pathname.endsWith('/me') ? auth.userId : auth.userId;

    const index = await getReliabilityIndex(context.env.DB, userId);
    return jsonResponse({ success: true, data: index || null });
  } catch (err) {
    console.error('Reliability read error:', err);
    return jsonResponse({ success: false, error: 'Failed to load reliability index' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const eventType = String(body.event_type || '').trim();
    if (!eventType) {
      return jsonResponse({ success: false, error: 'event_type is required' }, 400);
    }

    const targetUserId = body.user_id && auth.user.user_type === 'admin'
      ? String(body.user_id)
      : auth.userId;

    const eventId = await recordReliabilityEvent(context.env.DB, {
      userId: targetUserId,
      userRole: body.user_role || auth.user.user_type || 'artist',
      eventType,
      bookingId: body.booking_id || null,
      metadata: body.metadata || null,
    });

    return jsonResponse({ success: true, data: { event_id: eventId } }, 201);
  } catch (err) {
    console.error('Reliability event error:', err);
    return jsonResponse({ success: false, error: 'Failed to record event' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
