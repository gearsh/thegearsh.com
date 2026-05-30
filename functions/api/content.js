// Content Engine — JSON copy & theme (public read)
// GET /api/content          — full bundle (copy + theme + version)
// GET /api/content/copy     — copy tree only
// GET /api/content/theme    — theme tokens only

import { corsPreflightResponse, jsonResponse } from './auth-utils.js';
import { ensureRenovationTables } from './renovation-schema.js';
import { ensureContentSeeded, DEFAULT_COPY, DEFAULT_THEME } from './content-seed.js';

async function loadLiveContent(db) {
  await ensureRenovationTables(db);
  await ensureContentSeeded(db);

  const row = await db.prepare(`SELECT * FROM content_live WHERE id = 'live'`).first();
  if (!row) {
    return { copy: DEFAULT_COPY, theme: DEFAULT_THEME, version: 1 };
  }

  let copy = DEFAULT_COPY;
  let theme = DEFAULT_THEME;
  try { copy = JSON.parse(row.copy_json); } catch (_) {}
  try { theme = JSON.parse(row.theme_json); } catch (_) {}

  return {
    copy,
    theme,
    version: row.version || 1,
    published_at: row.published_at,
  };
}

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const path = url.pathname.replace(/\/+$/, '');
    const content = await loadLiveContent(context.env.DB);

    if (path.endsWith('/copy')) {
      const locale = url.searchParams.get('locale') || 'en';
      return jsonResponse({
        success: true,
        data: { locale, copy: content.copy, version: content.version },
      });
    }

    if (path.endsWith('/theme')) {
      return jsonResponse({
        success: true,
        data: { theme: content.theme, version: content.version },
      });
    }

    return jsonResponse({ success: true, data: content });
  } catch (err) {
    console.error('Content read error:', err);
    return jsonResponse({ success: false, error: 'Failed to load content' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
