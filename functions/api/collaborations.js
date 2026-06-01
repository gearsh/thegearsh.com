// GET  /api/collaborations?box=sent|received|active|completed  — my collaborations
// POST /api/collaborations                                     — create a request

import {
  corsPreflightResponse,
  jsonResponse,
  requireAuth,
} from './auth-utils.js';
import {
  ensureCollaborationTables,
  isValidCollaborationType,
  resolveRecipient,
  parseJsonArray,
  newId,
} from './collaboration-utils.js';

const ACTIVE_STATUSES = ['reviewing', 'negotiating', 'accepted', 'in_progress'];

function shape(row, userId) {
  return {
    id: row.id,
    direction: row.requester_id === userId ? 'sent' : 'received',
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
    requester_name: row.requester_name,
    requester_image: row.requester_image,
    recipient_name: row.recipient_name,
    recipient_username: row.recipient_username,
    recipient_image: row.recipient_image,
    counterpart_name: row.requester_id === userId
      ? (row.recipient_name || row.recipient_username)
      : (row.requester_name || 'Artist'),
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export async function onRequestGet(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const url = new URL(context.request.url);
    const box = String(url.searchParams.get('box') || 'all').toLowerCase();

    let where = '(c.requester_id = ? OR c.recipient_id = ?)';
    const params = [auth.userId, auth.userId];

    if (box === 'sent') {
      where = 'c.requester_id = ?';
      params.length = 0;
      params.push(auth.userId);
    } else if (box === 'received') {
      where = 'c.recipient_id = ?';
      params.length = 0;
      params.push(auth.userId);
    } else if (box === 'active') {
      where = '(c.requester_id = ? OR c.recipient_id = ?) AND c.status IN (' +
        ACTIVE_STATUSES.map(function () { return '?'; }).join(',') + ')';
      params.push.apply(params, ACTIVE_STATUSES);
    } else if (box === 'completed') {
      where = '(c.requester_id = ? OR c.recipient_id = ?) AND c.status = ?';
      params.push('completed');
    }

    const stmt = context.env.DB.prepare(`
      SELECT
        c.*,
        ureq.display_name AS requester_name,
        ureq.profile_picture_url AS requester_image,
        urec.display_name AS recipient_display,
        urec.profile_picture_url AS recipient_image
      FROM collaboration_requests c
      LEFT JOIN users ureq ON c.requester_id = ureq.id
      LEFT JOIN users urec ON c.recipient_id = urec.id
      WHERE ${where}
      ORDER BY c.updated_at DESC
      LIMIT 100
    `);
    const rows = await stmt.bind.apply(stmt, params).all();

    const data = (rows.results || []).map(function (row) {
      if (!row.recipient_name && row.recipient_display) row.recipient_name = row.recipient_display;
      return shape(row, auth.userId);
    });

    return jsonResponse({ success: true, data: data });
  } catch (err) {
    console.error('Collaborations list error:', err);
    return jsonResponse({ success: false, error: 'Failed to load collaborations' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    await ensureCollaborationTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(function () { return {}; });
    const projectName = String(body.project_name || '').trim();
    const type = String(body.collaboration_type || '').trim();
    const recipientUsername = String(body.recipient_username || body.recipient || '').trim();

    if (!projectName) {
      return jsonResponse({ success: false, error: 'Project name is required' }, 400);
    }
    if (!isValidCollaborationType(type)) {
      return jsonResponse({ success: false, error: 'Choose a valid collaboration type' }, 400);
    }
    if (!recipientUsername) {
      return jsonResponse({ success: false, error: 'Recipient artist is required' }, 400);
    }

    const recipient = await resolveRecipient(context.env.DB, recipientUsername);
    if (!recipient) {
      return jsonResponse({ success: false, error: 'That artist could not be found on Gearsh' }, 404);
    }
    if (recipient.recipient_id && recipient.recipient_id === auth.userId) {
      return jsonResponse({ success: false, error: 'You cannot send a collaboration request to yourself' }, 400);
    }

    const budget = body.budget != null && body.budget !== '' ? Number(body.budget) : null;
    if (budget != null && (!Number.isFinite(budget) || budget < 0)) {
      return jsonResponse({ success: false, error: 'Budget must be a positive number' }, 400);
    }

    const refLinks = Array.isArray(body.reference_links)
      ? body.reference_links.filter(Boolean).slice(0, 10)
      : parseJsonArray(body.reference_links);

    const id = newId('collab');
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO collaboration_requests (
        id, requester_id, recipient_id, recipient_username, recipient_name,
        project_name, collaboration_type, budget, currency, description,
        deadline, reference_links, deliverables, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ZAR', ?, ?, ?, ?, 'pending', ?, ?)
    `).bind(
      id,
      auth.userId,
      recipient.recipient_id,
      recipient.recipient_username,
      recipient.recipient_name,
      projectName.slice(0, 160),
      type,
      budget,
      body.description ? String(body.description).slice(0, 4000) : null,
      body.deadline ? String(body.deadline).slice(0, 40) : null,
      JSON.stringify(refLinks),
      body.deliverables ? String(body.deliverables).slice(0, 2000) : null,
      now,
      now
    ).run();

    return jsonResponse({
      success: true,
      data: {
        id: id,
        status: 'pending',
        recipient_claimed: recipient.claimed,
        message: recipient.claimed
          ? 'Request sent. ' + recipient.recipient_name + ' will be notified.'
          : recipient.recipient_name + ' has not claimed their Gearsh profile yet — your request is saved and will reach them the moment they join.',
      },
    }, 201);
  } catch (err) {
    console.error('Collaboration create error:', err);
    return jsonResponse({ success: false, error: 'Failed to create collaboration request' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
