// POST /api/upload-profile-photo - Upload user profile photo

export async function onRequestPost(context) {
  try {
    // CORS headers
    const corsHeaders = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    const body = await context.request.json();
    const { firebase_uid, image_data, mime_type } = body;

    if (!firebase_uid || !image_data) {
      return new Response(JSON.stringify({
        success: false,
        error: "Missing required fields"
      }), {
        headers: corsHeaders,
        status: 400,
      });
    }

    // Generate unique filename
    const extension = mime_type === 'image/png' ? 'png' : 'jpg';
    const filename = `profile_${firebase_uid}_${Date.now()}.${extension}`;

    // Decode base64 image
    const imageBuffer = Uint8Array.from(atob(image_data), c => c.charCodeAt(0));

    // Upload to R2 bucket (Cloudflare storage)
    if (context.env.PROFILE_IMAGES) {
      await context.env.PROFILE_IMAGES.put(filename, imageBuffer, {
        httpMetadata: {
          contentType: mime_type || 'image/jpeg',
        },
      });

      // Generate public URL
      const photoUrl = `https://images.thegearsh.com/profiles/${filename}`;

      // Update user profile in database
      await context.env.DB.prepare(`
        UPDATE users SET profile_picture_url = ?, updated_at = datetime('now')
        WHERE id = ?
      `).bind(photoUrl, firebase_uid).run();

      return new Response(JSON.stringify({
        success: true,
        data: {
          photo_url: photoUrl,
          filename: filename,
        }
      }), {
        headers: corsHeaders,
        status: 200,
      });
    } else {
      // If R2 not configured, store base64 in database (not recommended for production)
      const photoUrl = `data:${mime_type};base64,${image_data.substring(0, 100)}...`;

      return new Response(JSON.stringify({
        success: true,
        data: {
          photo_url: photoUrl,
          message: "Image storage not configured, using placeholder"
        }
      }), {
        headers: corsHeaders,
        status: 200,
      });
    }
  } catch (err) {
    console.error("Error uploading profile photo:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to upload photo"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      status: 500,
    });
  }
}

// Handle CORS preflight
export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}
