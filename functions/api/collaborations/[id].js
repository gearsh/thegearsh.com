// GET   /api/collaborations/:id          — collaboration detail (participants only)
// PATCH /api/collaborations/:id          — accept | decline | counter | start | complete | cancel

import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from '../auth-utils.js';
import {
  ensureCollaborationTables,
  parseJsonArray,
  userOnCollaboration,
  newId,
} from '../collaboration-utils.js';

async function loadCollaboration(db, id) {
  return db.prepare(`
    SELECT
      c.*,
      ureq.display_name AS requester_name,
      ureq.profile_picture_url AS requester_image,
      urec.display_name AS recipient_display,
      urec.profile_picture_url AS recipient_image
    FROM collaboration_requests c
    LEFT JOIN users ureq ON c.requester_id = ureq.id
    LEFT JOIN users urec ON c.recipient_id = urec.id
    WHERE c.id = ?
  `).bind(id).first();
}

async function loadOffers(db, id) {
  const rows = await db.prepare(`
    SELECT o.*, u.display_name AS from_name
    FROM collaboration_offers o
    LEFT JOIN users u ON o.from_id = u.id
    WHERE o.request_id = ?
    ORDER BY o.created_at ASC
  `).bind(id).all();
  return rows.results || [];
}

function shapeDetail(row, offers, reviews, userId) {
  return {
    id: row.id,
    direction: row.requester_id === userId ? 'sent' : 'received',
    is_recipient: row.recipient_id === userId,
    project_name: row.project_name,
    collaboration_type: row.collaboration_type,
    budget: row.budget,
    agreed_amount: row.agreed_amount,
    currency: row.currency || 'ZAR',
    description: row.description,
    deadline: row.deadline,
    reference_links: parseJsonArray(row.reference_links),
    deliverables: row.deliverables,
    status: row.status,
    requester_id: row.requester_id,
    recipient_id: row.recipient_id,
    requester_name: row.requester_name || 'Artist',
    requester_image: row.requester_image,
    recipient_name: row.recipient_name || row.recipient_display,
    recipient_username: row.recipient_username,
    recipient_image: row.recipient_image,
    counterpart_name: row.requester_id === userId
      ? (row.recipient_name || row.recipient_display || row.recipient_username)
      : (row.requester_name || 'Artist'),
    offers: offers.map(function (o) {
      return {
        id: o.id,
        from_id: o.from_id,
        from_name: o.from_name,
        from_me: o.from_id === userId,
        amount: o.amount,
        notes: o.notes,
        status: o.status,
        created_at: o.created_at,
      };
    }),
    reviewed_by_me: reviews.some(function (r) { return r.reviewer_id === userId; }),
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export async function onRequestGet(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const collab = await loadCollaboration(context.env.DB, context.params.id);
    if (!collab || !userOnCollaboration(collab, auth.userId)) {
      return jsonResponse({ success: false, error: 'Collaboration not found' }, 404);
    }

    const offers = await loadOffers(context.env.DB, collab.id);
    const reviews = (await context.env.DB.prepare(
      `SELECT reviewer_id FROM collaboration_reviews WHERE collaboration_id = ?`
    ).bind(collab.id).all()).results || [];

    return jsonResponse({ success: true, data: shapeDetail(collab, offers, reviews, auth.userId) });
  } catch (err) {
    console.error('Collaboration detail error:', err);
    return jsonResponse({ success: false, error: 'Failed to load collaboration' }, 500);
  }
}

export async function onRequestPatch(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const collab = await loadCollaboration(context.env.DB, context.params.id);
    if (!collab || !userOnCollaboration(collab, auth.userId)) {
      return jsonResponse({ success: false, error: 'Collaboration not found' }, 404);
    }

    const body = await context.request.json().catch(function () { return {}; });
    const action = String(body.action || '').trim().toLowerCase();
    const now = new Date().toISOString();
    const isRecipient = collab.recipient_id === auth.userId;
    const isRequester = collab.requester_id === auth.userId;

    async function setStatus(status, agreedAmount) {
      if (agreedAmount != null) {
        await context.env.DB.prepare(
          `UPDATE collaboration_requests SET status = ?, agreed_amount = ?, updated_at = ? WHERE id = ?`
        ).bind(status, agreedAmount, now, collab.id).run();
      } else {
        await context.env.DB.prepare(
          `UPDATE collaboration_requests SET status = ?, updated_at = ? WHERE id = ?`
        ).bind(status, now, collab.id).run();
      }
    }

    if (action === 'accept') {
      // Recipient accepts the request (optionally locking in the latest offer/budget).
      if (!isRecipient) {
        return jsonResponse({ success: false, error: 'Only the receiving artist can accept' }, 403);
      }
      const agreed = body.amount != null ? Number(body.amount) : (collab.agreed_amount || collab.budget || null);
      await setStatus('accepted', agreed);
      return jsonResponse({ success: true, data: { status: 'accepted', agreed_amount: agreed } });
    }

    if (action === 'decline') {
      if (!isRecipient) {
        return jsonResponse({ success: false, error: 'Only the receiving artist can decline' }, 403);
      }
      await setStatus('declined');
      return jsonResponse({ success: true, data: { status: 'declined' } });
    }

    if (action === 'counter') {
      // Either party proposes a new amount → moves to negotiating.
      const amount = Number(body.amount);
      if (!Number.isFinite(amount) || amount < 0) {
        return jsonResponse({ success: false, error: 'A valid counter amount is required' }, 400);
      }
      const offerId = newId('offer');
      await context.env.DB.prepare(`
        INSERT INTO collaboration_offers (id, request_id, from_id, amount, notes, status, created_at)
        VALUES (?, ?, ?, ?, ?, 'proposed', ?)
      `).bind(offerId, collab.id, auth.userId, amount, body.notes ? String(body.notes).slice(0, 1000) : null, now).run();
      await setStatus('negotiating', amount);
      return jsonResponse({ success: true, data: { status: 'negotiating', offer_id: offerId, amount: amount } });
    }

    if (action === 'start') {
      // Move an accepted collaboration into active work.
      if (collab.status !== 'accepted') {
        return jsonResponse({ success: false, error: 'Only accepted collaborations can be started' }, 400);
      }
      await setStatus('in_progress');
      return jsonResponse({ success: true, data: { status: 'in_progress' } });
    }

    if (action === 'complete') {
      if (collab.status !== 'in_progress' && collab.status !== 'accepted') {
        return jsonResponse({ success: false, error: 'Only active collaborations can be completed' }, 400);
      }
      await setStatus('completed');
      return jsonResponse({ success: true, data: { status: 'completed' } });
    }

    if (action === 'cancel') {
      if (collab.status === 'completed') {
        return jsonResponse({ success: false, error: 'Completed collaborations cannot be cancelled' }, 400);
      }
      if (!isRecipient && !isRequester) {
        return jsonResponse({ success: false, error: 'Not allowed' }, 403);
      }
      await setStatus('cancelled');
      return jsonResponse({ success: true, data: { status: 'cancelled' } });
    }

    if (action === 'reviewing') {
      if (!isRecipient) {
        return jsonResponse({ success: false, error: 'Only the receiving artist can mark as reviewing' }, 403);
      }
      await setStatus('reviewing');
      return jsonResponse({ success: true, data: { status: 'reviewing' } });
    }

    return jsonResponse({ success: false, error: 'Unknown action' }, 400);
  } catch (err) {
    console.error('Collaboration update error:', err);
    return jsonResponse({ success: false, error: 'Failed to update collaboration' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
