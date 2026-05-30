import { corsPreflightResponse, jsonResponse } from '../../auth-utils.js';
import { requireFounder } from '../../founder-auth.js';
import { ensureRenovationTables } from '../../renovation-schema.js';
import { ensureContentSeeded } from '../../content-seed.js';

function newId() {
  return `clog_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

async function loadDraft(db) {
  await ensureRenovationTables(db);
  await ensureContentSeeded(db);
  return db.prepare(`SELECT * FROM content_draft WHERE id = 'draft'`).first();
}

async function loadLive(db) {
  await ensureRenovationTables(db);
  await ensureContentSeeded(db);
  return db.prepare(`SELECT * FROM content_live WHERE id = 'live'`).first();
}

export async function onRequestPost(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const draft = await loadDraft(context.env.DB);
    const live = await loadLive(context.env.DB);
    const now = new Date().toISOString();
    const nextVersion = (live.version || 1) + 1;

    await context.env.DB.prepare(`
      UPDATE content_live SET copy_json = ?, theme_json = ?, version = ?, published_at = ?, updated_at = ?
      WHERE id = 'live'
    `).bind(draft.copy_json, draft.theme_json, nextVersion, now, now).run();

    await context.env.DB.prepare(`
      INSERT INTO content_publish_log (id, from_version, to_version, action, created_by, created_at)
      VALUES (?, ?, ?, 'publish', 'founder', ?)
    `).bind(newId(), live.version || 1, nextVersion, now).run();

    return jsonResponse({
      success: true,
      data: { version: nextVersion, published_at: now },
    });
  } catch (err) {
    console.error('Content publish error:', err);
    return jsonResponse({ success: false, error: 'Failed to publish content' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
