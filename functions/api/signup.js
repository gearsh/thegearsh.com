// POST /api/signup - Register a new user (simplified signup endpoint)
import {
  hashPassword,
  generateToken,
  ensureAuthTables,
  jsonResponse,
  corsPreflightResponse,
  categoryFromSkills,
  parseSkills,
  slugifyUsername,
  ensureUniqueUsername,
  buildProfileUrl,
  isValidUsername,
} from './auth-utils.js';

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    console.log("Signup request received:", JSON.stringify(body));

    const {
      email,
      password,
      first_name,
      last_name,
      user_type = 'client',
      phone,
      location,
      country = 'South Africa',
      user_name,
      username,
      stage_name,
      skill_set,
      starting_price,
      date_of_birth,
      gender
    } = body;

    let chosenUsername = (username || user_name || '').trim() || null;
    let firstName = (first_name || '').trim();
    let lastName = (last_name || '').trim();
    const stageName = (stage_name || '').trim();

    if (user_type === 'artist' && stageName) {
      firstName = stageName;
      lastName = '—';
      if (!chosenUsername) chosenUsername = stageName;
    }

    // Validate required fields
    if (!email || !password || !firstName || !lastName) {
      return jsonResponse({
        success: false,
        error: "Please fill in all required fields"
      }, 400);
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return jsonResponse({
        success: false,
        error: "Please enter a valid email address"
      }, 400);
    }

    // Validate password length
    if (password.length < 6) {
      return jsonResponse({
        success: false,
        error: "Password must be at least 6 characters long"
      }, 400);
    }

    try {
      await ensureAuthTables(context.env.DB);
      console.log("Tables ensured");
    } catch (tableErr) {
      console.error("Table creation error:", tableErr);
      // Continue anyway - tables might already exist
    }

    // Check if email already exists
    try {
      const existing = await context.env.DB.prepare(
        `SELECT id FROM users WHERE email = ?`
      ).bind(email.toLowerCase()).first();

      if (existing) {
        return jsonResponse({
          success: false,
          error: "This email is already registered. Please sign in or use a different email."
        }, 409);
      }
    } catch (checkErr) {
      console.error("Email check error:", checkErr);
      // Continue - table might not exist yet
    }

    if (user_type === 'artist') {
      const slugBase = chosenUsername || stageName || email.split('@')[0];
      chosenUsername = slugifyUsername(slugBase);
      if (!isValidUsername(chosenUsername)) {
        chosenUsername = await ensureUniqueUsername(context.env.DB, slugBase);
      } else {
        const taken = await context.env.DB.prepare(
          `SELECT id FROM users WHERE LOWER(username) = LOWER(?)`
        ).bind(chosenUsername).first();
        if (taken) {
          chosenUsername = await ensureUniqueUsername(context.env.DB, slugBase);
        }
      }
    } else if (chosenUsername) {
      chosenUsername = slugifyUsername(chosenUsername) || null;
    }

    // Generate user ID and hash password
    const userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const passwordHash = await hashPassword(password);
    const displayName = user_type === 'artist' && stageName ? stageName : `${firstName} ${lastName}`.trim();
    const createdAt = new Date().toISOString();

    console.log("Inserting user:", userId, email.toLowerCase());

    // Insert user with explicit values
    try {
      await context.env.DB.prepare(`
        INSERT INTO users (
          id, email, password_hash, user_type, first_name, last_name,
          display_name, username, phone, location, country, bio, is_verified, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, ?, ?)
      `).bind(
        userId,
        email.toLowerCase(),
        passwordHash,
        user_type,
        firstName,
        lastName,
        displayName,
        chosenUsername,
        phone || null,
        location || null,
        country,
        skill_set || null,
        createdAt,
        createdAt
      ).run();

      console.log("User inserted successfully");
    } catch (insertErr) {
      console.error("Insert error:", insertErr.message);
      return jsonResponse({
        success: false,
        error: "Failed to create account. Please try again.",
        debug: insertErr.message
      }, 500);
    }

    let artistId = null;

    // If user is an artist, create artist profile
    if (user_type === 'artist') {
      try {
        artistId = `artist_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const category = categoryFromSkills(skill_set);
        const baseRate = starting_price ? Number(starting_price) : null;
        await context.env.DB.prepare(`
          INSERT INTO artist_profiles (id, user_id, category, skills, base_rate, availability_status, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, 'available', ?, ?)
        `).bind(artistId, userId, category, skill_set || null, baseRate, createdAt, createdAt).run();

        const skills = parseSkills(skill_set);
        const isCarWash = skills.some(function(s) { return s.toLowerCase().includes('car wash'); });
        const price = baseRate || (isCarWash ? 200 : 500);
        const serviceName = isCarWash ? 'Mobile car wash' : (category + ' booking');
        const serviceDesc = isCarWash
          ? 'Professional mobile car wash at your location.'
          : ('Book ' + displayName + ' for your next event.');

        const serviceId = `svc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        await context.env.DB.prepare(`
          INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
          VALUES (?, ?, ?, ?, ?, ?, 1, ?)
        `).bind(
          serviceId,
          artistId,
          serviceName,
          serviceDesc,
          price,
          isCarWash ? 1 : 2,
          createdAt
        ).run();

        if (isCarWash) {
          const extras = [
            { name: 'Full valet wash', description: 'Exterior wash, interior vacuum, and tyre shine.', price: Math.round(price * 1.6), hours: 1.5 },
            { name: 'Interior detail', description: 'Deep interior clean and dashboard polish.', price: Math.round(price * 2.2), hours: 2 },
          ];
          for (const extra of extras) {
            const extraId = `svc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            await context.env.DB.prepare(`
              INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
              VALUES (?, ?, ?, ?, ?, ?, 1, ?)
            `).bind(extraId, artistId, extra.name, extra.description, extra.price, extra.hours, createdAt).run();
          }
        }

        console.log("Artist profile created");
      } catch (artistErr) {
        console.error("Artist profile error:", artistErr);
        // Don't fail the signup if artist profile fails
      }
    }

    // Generate token
    const token = generateToken(userId);

    return jsonResponse({
      success: true,
      message: "Account created successfully!",
      data: {
        user_id: userId,
        email: email.toLowerCase(),
        user_type,
        first_name: firstName,
        last_name: lastName,
        display_name: displayName,
        artist_id: artistId,
        username: chosenUsername,
        profile_url: artistId && chosenUsername ? buildProfileUrl(chosenUsername) : null,
        token
      }
    }, 201);

  } catch (err) {
    console.error("Signup error:", err);
    return jsonResponse({
      success: false,
      error: "Registration failed. Please try again.",
      details: err.message
    }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
