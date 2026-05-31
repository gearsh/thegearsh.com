// POST /api/upload-profile-photo - Upload user profile photo (Bearer token required)

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from './auth-utils.js';

const MAX_BASE64_BYTES = 4 * 1024 * 1024;
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

function stripBase64Payload(value) {
  const raw = String(value || '').trim();
  const match = raw.match(/^data:[^;]+;base64,(.+)$/i);
  return match ? match[1].trim() : raw;
}

function detectMimeFromBase64(base64) {
  const head = String(base64 || '').slice(0, 16);
  if (head.startsWith('/9j/')) return 'image/jpeg';
  if (head.startsWith('iVBORw0KGgo')) return 'image/png';
  if (head.startsWith('UklGR')) return 'image/webp';
  return '';
}

function normalizeMime(mimeType, base64) {
  let mime = String(mimeType || '').trim().toLowerCase();
  if (mime === 'image/jpg' || mime === 'image/pjpeg') mime = 'image/jpeg';
  if (!mime || mime === 'application/octet-stream') {
    mime = detectMimeFromBase64(base64) || 'image/jpeg';
  }
  return mime;
}

function parsePortfolioUrls(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return String(value).split(',').map(function (s) { return s.trim(); }).filter(Boolean);
  }
}

async function appendPortfolioUrl(db, userId, photoUrl) {
  const profile = await db.prepare(`
    SELECT id, portfolio_urls FROM artist_profiles WHERE user_id = ?
  `).bind(userId).first();
  if (!profile) return;
  const urls = parsePortfolioUrls(profile.portfolio_urls);
  urls.push(photoUrl);
  await db.prepare(`
    UPDATE artist_profiles SET portfolio_urls = ?, updated_at = datetime('now')
    WHERE user_id = ?
  `).bind(JSON.stringify(urls), userId).run();
}

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(
      context.request.headers.get('Authorization'),
      context.env,
    );

    if (!userId) {
      return unauthorizedResponse('Authentication required');
    }

    const body = await context.request.json();
    const { image_data, mime_type, type } = body || {};

    if (!image_data || typeof image_data !== 'string') {
      return jsonResponse({ success: false, error: 'image_data is required' }, 400);
    }

    const base64 = stripBase64Payload(image_data);
    if (!base64) {
      return jsonResponse({ success: false, error: 'Invalid base64 image data' }, 400);
    }
    if (base64.length > MAX_BASE64_BYTES) {
      return jsonResponse({ success: false, error: 'Image too large (max ~3MB). Try a smaller photo.' }, 413);
    }

    const mime = normalizeMime(mime_type, base64);
    if (mime === 'image/heic' || mime === 'image/heif') {
      return jsonResponse({
        success: false,
        error: 'HEIC photos are not supported. Change camera settings to JPEG or pick a JPG/PNG.',
      }, 415);
    }
    if (!ALLOWED_MIME.has(mime)) {
      return jsonResponse({ success: false, error: 'Unsupported image type. Use JPG, PNG, or WebP.' }, 415);
    }

    const extension = mime === 'image/png'
      ? 'png'
      : mime === 'image/webp'
        ? 'webp'
        : 'jpg';
    const prefix = type === 'portfolio' ? 'portfolio' : 'profile';
    const filename = `${prefix}_${userId}_${Date.now()}.${extension}`;

    let imageBuffer;
    try {
      imageBuffer = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    } catch (_) {
      return jsonResponse({ success: false, error: 'Invalid base64 image data' }, 400);
    }

    if (context.env.PROFILE_IMAGES) {
      await context.env.PROFILE_IMAGES.put(filename, imageBuffer, {
        httpMetadata: { contentType: mime },
      });
      const photoUrl = `https://images.thegearsh.com/profiles/${filename}`;

      if (type === 'portfolio') {
        await appendPortfolioUrl(context.env.DB, userId, photoUrl);
      } else {
        await context.env.DB.prepare(`
          UPDATE users SET profile_picture_url = ?, updated_at = datetime('now')
          WHERE id = ?
        `).bind(photoUrl, userId).run();
      }

      return jsonResponse({
        success: true,
        data: { photo_url: photoUrl, filename },
      });
    }

    const dataUrl = `data:${mime};base64,${base64}`;
    if (type === 'portfolio') {
      await appendPortfolioUrl(context.env.DB, userId, dataUrl);
    } else {
      await context.env.DB.prepare(`
        UPDATE users SET profile_picture_url = ?, updated_at = datetime('now')
        WHERE id = ?
      `).bind(dataUrl, userId).run();
    }

    return jsonResponse({
      success: true,
      data: {
        photo_url: dataUrl,
        message: 'Stored inline (R2 not configured)',
      },
    });
  } catch (err) {
    console.error('Error uploading profile photo:', err);
    return jsonResponse({ success: false, error: 'Failed to upload photo' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
