// GET  /api/collaborations/:id/review — reviews on a completed collaboration
// POST /api/collaborations/:id/review — leave a review (participants, once each)

import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from '../../auth-utils.js';
import {
  ensureCollaborationTables,
  userOnCollaboration,
  newId,
} from '../../collaboration-utils.js';

async function loadCollab(db, id) {
  return db.prepare(
    `SELECT id, requester_id, recipient_id, status FROM collaboration_requests WHERE id = ?`
  ).bind(id).first();
}

export async function onRequestGet(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const collab = await loadCollab(context.env.DB, context.params.id);
    if (!collab || !userOnCollaboration(collab, auth.userId)) {
      return jsonResponse({ success: false, error: 'Collaboration not found' }, 404);
    }

    const rows = await context.env.DB.prepare(`
      SELECT r.*, u.display_name AS reviewer_name, u.profile_picture_url AS reviewer_image
      FROM collaboration_reviews r
      LEFT JOIN users u ON r.reviewer_id = u.id
      WHERE r.collaboration_id = ?
      ORDER BY r.created_at DESC
    `).bind(collab.id).all();

    return jsonResponse({ success: true, data: rows.results || [] });
  } catch (err) {
    console.error('Collaboration review get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load reviews' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const collab = await loadCollab(context.env.DB, context.params.id);
    if (!collab || !userOnCollaboration(collab, auth.userId)) {
      return jsonResponse({ success: false, error: 'Collaboration not found' }, 404);
    }
    if (collab.status !== 'completed') {
      return jsonResponse({ success: false, error: 'You can only review a completed collaboration' }, 400);
    }

    const body = await context.request.json().catch(function () { return {}; });
    const rating = Number(body.rating);
    if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
      return jsonResponse({ success: false, error: 'Rating must be between 1 and 5' }, 400);
    }

    const existing = await context.env.DB.prepare(
      `SELECT id FROM collaboration_reviews WHERE collaboration_id = ? AND reviewer_id = ?`
    ).bind(collab.id, auth.userId).first();
    if (existing) {
      return jsonResponse({ success: false, error: 'You already reviewed this collaboration' }, 409);
    }

    const revieweeId = collab.requester_id === auth.userId ? collab.recipient_id : collab.requester_id;
    const id = newId('crev');
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO collaboration_reviews (id, collaboration_id, reviewer_id, reviewee_id, rating, review, would_again, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      id,
      collab.id,
      auth.userId,
      revieweeId,
      Math.round(rating),
      body.review ? String(body.review).slice(0, 2000) : null,
      body.would_again === false || body.would_again === 0 ? 0 : 1,
      now
    ).run();

    return jsonResponse({ success: true, data: { review_id: id } }, 201);
  } catch (err) {
    console.error('Collaboration review post error:', err);
    return jsonResponse({ success: false, error: 'Failed to submit review' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
