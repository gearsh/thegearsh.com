// POST /api/upload-activity-media — upload images for activity posts

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from './auth-utils.js';

const MAX_BASE64_BYTES = 5 * 1024 * 1024;
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

export async function onRequestPost(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const body = await context.request.json();
    const { image_data, mime_type } = body || {};

    if (!image_data || typeof image_data !== 'string') {
      return jsonResponse({ success: false, error: 'image_data is required' }, 400);
    }
    if (image_data.length > MAX_BASE64_BYTES) {
      return jsonResponse({ success: false, error: 'Image too large (max ~4MB)' }, 413);
    }

    const mime = (mime_type || 'image/jpeg').toLowerCase();
    if (!ALLOWED_MIME.has(mime)) {
      return jsonResponse({ success: false, error: 'Unsupported image type' }, 415);
    }

    const extension = mime === 'image/png' ? 'png' : mime === 'image/webp' ? 'webp' : 'jpg';
    const filename = `activity_${userId}_${Date.now()}.${extension}`;

    let imageBuffer;
    try {
      imageBuffer = Uint8Array.from(atob(image_data), function(c) { return c.charCodeAt(0); });
    } catch (_) {
      return jsonResponse({ success: false, error: 'Invalid base64 image data' }, 400);
    }

    if (context.env.PROFILE_IMAGES) {
      await context.env.PROFILE_IMAGES.put(filename, imageBuffer, {
        httpMetadata: { contentType: mime },
      });
      const mediaUrl = `https://images.thegearsh.com/profiles/${filename}`;
      return jsonResponse({ success: true, data: { media_url: mediaUrl, filename } });
    }

    const dataUrl = `data:${mime};base64,${image_data}`;
    return jsonResponse({ success: true, data: { media_url: dataUrl, filename } });
  } catch (err) {
    console.error('Activity media upload error:', err);
    return jsonResponse({ success: false, error: 'Upload failed' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
