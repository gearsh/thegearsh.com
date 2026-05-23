// POST /api/upload-profile-photo - Upload user profile photo (Bearer token or firebase_uid)

import { parseToken, jsonResponse, corsPreflightResponse } from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    const { firebase_uid, image_data, mime_type, type } = body;

    let userId = firebase_uid || await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId || !image_data) {
      return jsonResponse({ success: false, error: 'Missing required fields' }, 400);
    }

    const mime = mime_type || 'image/jpeg';
    const extension = mime === 'image/png' ? 'png' : 'jpg';
    const prefix = type === 'portfolio' ? 'portfolio' : 'profile';
    const filename = `${prefix}_${userId}_${Date.now()}.${extension}`;
    const imageBuffer = Uint8Array.from(atob(image_data), function(c) { return c.charCodeAt(0); });

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
