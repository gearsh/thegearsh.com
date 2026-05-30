// Founder Content Engine admin — draft, publish, rollback
// GET  /api/founder/content
// PUT  /api/founder/content/draft
// POST /api/founder/content/publish
// POST /api/founder/content/rollback

import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';
import { requireFounder } from '../founder-auth.js';
import { ensureRenovationTables } from '../renovation-schema.js';
import { ensureContentSeeded, DEFAULT_COPY, DEFAULT_THEME } from '../content-seed.js';

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

export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const [draft, live, history] = await Promise.all([
      loadDraft(context.env.DB),
      loadLive(context.env.DB),
      context.env.DB.prepare(`
        SELECT * FROM content_publish_log ORDER BY created_at DESC LIMIT 20
      `).all(),
    ]);

    return jsonResponse({
      success: true,
      data: {
        draft: {
          copy: JSON.parse(draft.copy_json || '{}'),
          theme: JSON.parse(draft.theme_json || '{}'),
          updated_at: draft.updated_at,
        },
        live: {
          copy: JSON.parse(live.copy_json || '{}'),
          theme: JSON.parse(live.theme_json || '{}'),
          version: live.version,
          published_at: live.published_at,
        },
        history: history.results || [],
      },
    });
  } catch (err) {
    console.error('Founder content read error:', err);
    return jsonResponse({ success: false, error: 'Failed to load content admin' }, 500);
  }
}

export async function onRequestPut(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json();
    const now = new Date().toISOString();
    const draft = await loadDraft(context.env.DB);

    const copyJson = body.copy !== undefined
      ? JSON.stringify(body.copy)
      : draft.copy_json;
    const themeJson = body.theme !== undefined
      ? JSON.stringify(body.theme)
      : draft.theme_json;

    await context.env.DB.prepare(`
      UPDATE content_draft SET copy_json = ?, theme_json = ?, updated_at = ? WHERE id = 'draft'
    `).bind(copyJson, themeJson, now).run();

    return jsonResponse({ success: true, data: { updated_at: now } });
  } catch (err) {
    console.error('Founder content draft error:', err);
    return jsonResponse({ success: false, error: 'Failed to save draft' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
