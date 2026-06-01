// GET  /api/collaborations/:id/messages — thread for a collaboration (participants only)
// POST /api/collaborations/:id/messages — send a message (text + optional attachment_url)

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
    `SELECT id, requester_id, recipient_id FROM collaboration_requests WHERE id = ?`
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

    const result = await context.env.DB.prepare(`
      SELECT m.id, m.sender_id, m.message, m.attachment_url, m.is_read, m.created_at,
             u.display_name AS sender_name
      FROM collaboration_messages m
      LEFT JOIN users u ON m.sender_id = u.id
      WHERE m.collaboration_id = ?
      ORDER BY m.created_at ASC
      LIMIT 300
    `).bind(collab.id).all();

    await context.env.DB.prepare(
      `UPDATE collaboration_messages SET is_read = 1 WHERE collaboration_id = ? AND receiver_id = ?`
    ).bind(collab.id, auth.userId).run();

    const messages = (result.results || []).map(function (row) {
      return {
        id: row.id,
        sender: row.sender_id === auth.userId ? 'me' : 'them',
        sender_id: row.sender_id,
        sender_name: row.sender_name,
        text: row.message,
        attachment_url: row.attachment_url || null,
        timestamp: row.created_at,
        is_read: Boolean(row.is_read),
      };
    });

    return jsonResponse({ success: true, data: messages });
  } catch (err) {
    console.error('Collaboration messages get error:', err);
    return jsonResponse({ success: false, error: 'Failed to load messages' }, 500);
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

    const body = await context.request.json().catch(function () { return {}; });
    const text = String(body.message || body.text || '').trim();
    const attachment = body.attachment_url ? String(body.attachment_url).slice(0, 1000) : null;
    if (!text && !attachment) {
      return jsonResponse({ success: false, error: 'Message content is required' }, 400);
    }

    // The other participant is the receiver. May be null if the recipient is an
    // unclaimed showcase profile — the message is still stored for when they join.
    let receiverId = null;
    if (collab.requester_id === auth.userId) receiverId = collab.recipient_id;
    else receiverId = collab.requester_id;

    const id = newId('cmsg');
    const now = new Date().toISOString();
    await context.env.DB.prepare(`
      INSERT INTO collaboration_messages (id, collaboration_id, sender_id, receiver_id, message, attachment_url, is_read, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 0, ?)
    `).bind(id, collab.id, auth.userId, receiverId, text || '', attachment, now).run();

    return jsonResponse({
      success: true,
      data: { id: id, sender: 'me', text: text, attachment_url: attachment, timestamp: now },
    }, 201);
  } catch (err) {
    console.error('Collaboration messages post error:', err);
    return jsonResponse({ success: false, error: 'Failed to send message' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
