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
import {
  guardMessage,
  leakageNudge,
  isContactUnlocked,
} from '../../message-guard.js';

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

    const result = await context.env.DB.prepare(`
      SELECT m.id, m.sender_id, m.message, m.attachment_url, m.is_read, m.flagged, m.created_at,
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
        flagged: Boolean(row.flagged),
        timestamp: row.created_at,
        is_read: Boolean(row.is_read),
      };
    });

    return jsonResponse({
      success: true,
      data: messages,
      contact_unlocked: isContactUnlocked(collab.status),
    });
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
    const rawText = String(body.message || body.text || '').trim();
    const attachment = body.attachment_url ? String(body.attachment_url).slice(0, 1000) : null;
    if (!rawText && !attachment) {
      return jsonResponse({ success: false, error: 'Message content is required' }, 400);
    }

    // Anti-leakage: redact contact/payment details until the deal is paid on Gearsh.
    const unlocked = isContactUnlocked(collab.status);
    const guard = guardMessage(rawText, unlocked);
    const storedText = guard.text;

    // The other participant is the receiver. May be null if the recipient is an
    // unclaimed showcase profile — the message is still stored for when they join.
    let receiverId = null;
    if (collab.requester_id === auth.userId) receiverId = collab.recipient_id;
    else receiverId = collab.requester_id;

    const id = newId('cmsg');
    const now = new Date().toISOString();
    await context.env.DB.prepare(`
      INSERT INTO collaboration_messages (id, collaboration_id, sender_id, receiver_id, message, attachment_url, is_read, flagged, flag_reasons, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?)
    `).bind(
      id, collab.id, auth.userId, receiverId, storedText || '', attachment,
      guard.flagged ? 1 : 0,
      guard.flagged ? JSON.stringify(guard.reasons) : null,
      now
    ).run();

    // Log circumvention attempts for founder review (best-effort).
    if (guard.flagged) {
      try {
        await context.env.DB.prepare(`
          INSERT INTO collaboration_flags (id, collaboration_id, message_id, sender_id, reasons, excerpt, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `).bind(
          newId('flag'), collab.id, id, auth.userId,
          JSON.stringify(guard.reasons),
          rawText.slice(0, 280),
          now
        ).run();
      } catch (e) { console.warn('flag log failed:', e && e.message); }
    }

    return jsonResponse({
      success: true,
      data: {
        id: id,
        sender: 'me',
        text: storedText,
        attachment_url: attachment,
        flagged: guard.flagged,
        timestamp: now,
      },
      redacted: guard.redacted,
      notice: guard.redacted ? leakageNudge(guard.reasons) : '',
      contact_unlocked: unlocked,
    }, 201);
  } catch (err) {
    console.error('Collaboration messages post error:', err);
    return jsonResponse({ success: false, error: 'Failed to send message' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
