import { corsPreflightResponse, jsonResponse } from '../../auth-utils.js';
import { requireFounder } from '../../founder-auth.js';
import { ensureRenovationTables } from '../../renovation-schema.js';
import { ensureContentSeeded, DEFAULT_COPY, DEFAULT_THEME } from '../../content-seed.js';

function newId() {
  return `clog_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

export async function onRequestPost(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(() => ({}));
    const targetVersion = Number(body.version || 0);

    await ensureRenovationTables(context.env.DB);
    await ensureContentSeeded(context.env.DB);

    const live = await context.env.DB.prepare(
      `SELECT * FROM content_live WHERE id = 'live'`
    ).first();

    if (targetVersion > 0 && targetVersion >= (live.version || 1)) {
      return jsonResponse({ success: false, error: 'Cannot rollback to current or future version' }, 400);
    }

    const now = new Date().toISOString();
    const copyJson = live.copy_json;
    const themeJson = live.theme_json;

    // Rollback restores live into draft; ops re-publish after edits if needed
    await context.env.DB.prepare(`
      UPDATE content_draft SET copy_json = ?, theme_json = ?, updated_at = ? WHERE id = 'draft'
    `).bind(copyJson, themeJson, now).run();

    if (targetVersion === 0) {
      const defaults = JSON.stringify(DEFAULT_COPY);
      const defaultTheme = JSON.stringify(DEFAULT_THEME);
      await context.env.DB.prepare(`
        UPDATE content_live SET copy_json = ?, theme_json = ?, version = 1, published_at = ?, updated_at = ?
        WHERE id = 'live'
      `).bind(defaults, defaultTheme, now, now).run();
    }

    await context.env.DB.prepare(`
      INSERT INTO content_publish_log (id, from_version, to_version, action, created_by, created_at)
      VALUES (?, ?, ?, 'rollback', 'founder', ?)
    `).bind(newId(), live.version || 1, targetVersion || 1, now).run();

    return jsonResponse({ success: true, data: { rolled_back_to: targetVersion || 1 } });
  } catch (err) {
    console.error('Content rollback error:', err);
    return jsonResponse({ success: false, error: 'Failed to rollback content' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
