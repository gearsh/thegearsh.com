// POST /api/upload-profile-photo - Upload user profile photo (Bearer token required)

import {
  parseToken,
  jsonResponse,
  corsPreflightResponse,
  unauthorizedResponse,
} from './auth-utils.js';

const MAX_BASE64_BYTES = 4 * 1024 * 1024;
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

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
    if (image_data.length > MAX_BASE64_BYTES) {
      return jsonResponse({ success: false, error: 'Image too large (max ~3MB)' }, 413);
    }

    const mime = (mime_type || 'image/jpeg').toLowerCase();
    if (!ALLOWED_MIME.has(mime)) {
      return jsonResponse({ success: false, error: 'Unsupported image type' }, 415);
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
      imageBuffer = Uint8Array.from(atob(image_data), (c) => c.charCodeAt(0));
    } catch (_) {
      return jsonResponse({ success: false, error: 'Invalid base64 image data' }, 400);
    }

    if (context.env.PROFILE_IMAGES) {
      await context.env.PROFILE_IMAGES.put(filename, imageBuffer, {
        httpMetadata: { contentType: mime },
      });
      const photoUrl = `https://images.thegearsh.com/profiles/${filename}`;

      if (type !== 'portfolio') {
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

    const dataUrl = `data:${mime};base64,${image_data}`;
    if (type !== 'portfolio') {
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
