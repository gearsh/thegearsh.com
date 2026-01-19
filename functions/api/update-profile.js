// POST /api/update-profile - Update user profile

export async function onRequestPost(context) {
  try {
    const corsHeaders = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    const body = await context.request.json();
    const {
      firebase_uid,
      first_name,
      last_name,
      username,
      phone,
      location,
      bio,
    } = body;

    if (!firebase_uid) {
      return new Response(JSON.stringify({
        success: false,
        error: "Missing firebase_uid"
      }), {
        headers: corsHeaders,
        status: 400,
      });
    }

    // Check if user exists
    const existingUser = await context.env.DB.prepare(
      "SELECT id FROM users WHERE id = ?"
    ).bind(firebase_uid).first();

    if (existingUser) {
      // Update existing user
      const updateQuery = `
        UPDATE users SET
          first_name = COALESCE(?, first_name),
          last_name = COALESCE(?, last_name),
          display_name = COALESCE(?, display_name),
          phone = COALESCE(?, phone),
          location = COALESCE(?, location),
          bio = COALESCE(?, bio),
          updated_at = datetime('now')
        WHERE id = ?
      `;

      await context.env.DB.prepare(updateQuery)
        .bind(
          first_name || null,
          last_name || null,
          username || null,
          phone || null,
          location || null,
          bio || null,
          firebase_uid
        )
        .run();
    } else {
      // Create new user
      const insertQuery = `
        INSERT INTO users (id, email, password_hash, user_type, first_name, last_name, display_name, phone, location, bio)
        VALUES (?, ?, '', 'client', ?, ?, ?, ?, ?, ?)
      `;

      await context.env.DB.prepare(insertQuery)
        .bind(
          firebase_uid,
          `${firebase_uid}@firebase.gearsh.com`,
          first_name || '',
          last_name || '',
          username || '',
          phone || '',
          location || '',
          bio || ''
        )
        .run();
    }

    return new Response(JSON.stringify({
      success: true,
      data: {
        message: "Profile updated successfully"
      }
    }), {
      headers: corsHeaders,
      status: 200,
    });
  } catch (err) {
    console.error("Error updating profile:", err);
    return new Response(JSON.stringify({
      success: false,
      error: "Failed to update profile"
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
