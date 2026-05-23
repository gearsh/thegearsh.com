import {
  hashPassword,
  generateToken,
  ensureAuthTables,
  jsonResponse,
  parseToken,
  slugifyUsername,
  ensureUniqueUsername,
  isValidUsername,
  buildProfileUrl,
  categoryFromSkills,
  parseSkills,
} from './auth-utils.js';

export async function ensureOnboardingTables(db) {
  await ensureAuthTables(db);

  const alters = [
    `ALTER TABLE users ADD COLUMN email_verified INTEGER DEFAULT 0`,
    `ALTER TABLE users ADD COLUMN phone_verified INTEGER DEFAULT 0`,
    `ALTER TABLE users ADD COLUMN onboarding_status TEXT DEFAULT 'draft'`,
    `ALTER TABLE artist_profiles ADD COLUMN hourly_rate REAL`,
    `ALTER TABLE artist_profiles ADD COLUMN availability_json TEXT`,
  ];
  for (const sql of alters) {
    try { await db.prepare(sql).run(); } catch (_) {}
  }

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS verification_codes (
      target TEXT NOT NULL,
      channel TEXT NOT NULL,
      code TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      PRIMARY KEY (target, channel)
    )
  `).run();
}

export async function requireUser(context) {
  const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
  if (!userId) return { error: jsonResponse({ success: false, error: 'Please sign in to continue' }, 401) };
  return { userId };
}

export function otpCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

export async function storeCode(db, target, channel, code) {
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
  const now = new Date().toISOString();
  await db.prepare(`
    INSERT INTO verification_codes (target, channel, code, expires_at, created_at)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(target, channel) DO UPDATE SET
      code = excluded.code,
      expires_at = excluded.expires_at,
      created_at = excluded.created_at
  `).bind(target, channel, code, expiresAt, now).run();
  return expiresAt;
}

export async function verifyStoredCode(db, target, channel, code) {
  const row = await db.prepare(`
    SELECT code, expires_at FROM verification_codes
    WHERE target = ? AND channel = ?
  `).bind(target, channel).first();
  if (!row) return false;
  if (new Date(row.expires_at).getTime() < Date.now()) return false;
  return String(row.code) === String(code).trim();
}

export async function sendEmailCode(env, email, code, name) {
  const RESEND_API_KEY = env.RESEND_API_KEY;
  if (!RESEND_API_KEY) {
    console.log(`Email verification code for ${email}: ${code}`);
    return { sent: false, demo: true };
  }
  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: env.EMAIL_FROM || 'Gearsh <onboarding@resend.dev>',
        to: [email],
        subject: 'Verify your Gearsh email',
        html: `<p>Hi ${name || 'there'},</p><p>Your Gearsh verification code is <strong>${code}</strong>. It expires in 15 minutes.</p>`,
      }),
    });
    return { sent: true, demo: false };
  } catch (err) {
    console.error('Email send error:', err);
    return { sent: false, demo: true };
  }
}

export async function sendWelcomeEmail(env, email, name, profileUrl) {
  const RESEND_API_KEY = env.RESEND_API_KEY;
  const link = profileUrl ? `https://thegearsh.com${profileUrl}` : 'https://thegearsh.com/artist-dashboard.html';
  if (!RESEND_API_KEY) {
    console.log(`Welcome email for ${email}: ${link}`);
    return { sent: false };
  }
  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: env.EMAIL_FROM || 'Gearsh <onboarding@resend.dev>',
        to: [email],
        subject: 'Welcome to Gearsh — your profile is under review',
        html: `<p>Hi ${name},</p><p>Thanks for joining Gearsh. Your artist profile has been submitted for review. We'll notify you when you're live on the marketplace.</p><p><a href="${link}">View your booking link</a></p><p>— The Gearsh team</p>`,
      }),
    });
    return { sent: true };
  } catch (err) {
    console.error('Welcome email error:', err);
    return { sent: false };
  }
}

export async function registerArtist(context, body) {
  const email = String(body.email || '').trim().toLowerCase();
  const password = String(body.password || '');
  if (!email || !password) {
    return jsonResponse({ success: false, error: 'Email and password are required' }, 400);
  }
  if (password.length < 8) {
    return jsonResponse({ success: false, error: 'Password must be at least 8 characters' }, 400);
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return jsonResponse({ success: false, error: 'Enter a valid email address' }, 400);
  }

  await ensureOnboardingTables(context.env.DB);
  const existing = await context.env.DB.prepare(
    `SELECT id FROM users WHERE LOWER(email) = LOWER(?)`
  ).bind(email).first();
  if (existing) {
    return jsonResponse({ success: false, error: 'This email is already registered. Sign in instead.' }, 409);
  }

  const userId = `user_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
  const now = new Date().toISOString();
  const passwordHash = await hashPassword(password);
  await context.env.DB.prepare(`
    INSERT INTO users (
      id, email, password_hash, user_type, first_name, last_name, display_name,
      is_verified, is_active, email_verified, phone_verified, onboarding_status, created_at, updated_at
    ) VALUES (?, ?, ?, 'artist', 'Artist', '—', 'New Artist', 0, 1, 0, 0, 'draft', ?, ?)
  `).bind(userId, email, passwordHash, now, now).run();

  const artistId = `artist_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
  await context.env.DB.prepare(`
    INSERT INTO artist_profiles (id, user_id, category, skills, availability_status, created_at, updated_at)
    VALUES (?, ?, 'Services', '[]', 'available', ?, ?)
  `).bind(artistId, userId, now, now).run();

  const code = otpCode();
  await storeCode(context.env.DB, email, 'email', code);
  const emailResult = await sendEmailCode(context.env, email, code, 'Artist');

  const token = await generateToken(userId, context.env);
  return jsonResponse({
    success: true,
    message: 'Account created. Check your email for a verification code.',
    data: {
      user_id: userId,
      artist_id: artistId,
      email,
      token,
      demo_code: emailResult.demo ? code : undefined,
    },
  }, 201);
}

export async function verifyEmail(context, body) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const code = String(body.code || '').trim();
  const user = await context.env.DB.prepare(
    `SELECT id, email FROM users WHERE id = ?`
  ).bind(auth.userId).first();
  if (!user) return jsonResponse({ success: false, error: 'User not found' }, 404);
  const ok = await verifyStoredCode(context.env.DB, user.email, 'email', code);
  if (!ok) return jsonResponse({ success: false, error: 'Invalid or expired code' }, 400);
  await context.env.DB.prepare(`
    UPDATE users SET email_verified = 1, updated_at = ? WHERE id = ?
  `).bind(new Date().toISOString(), auth.userId).run();
  return jsonResponse({ success: true, message: 'Email verified' });
}

export async function resendEmailCode(context) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const user = await context.env.DB.prepare(
    `SELECT email, display_name FROM users WHERE id = ?`
  ).bind(auth.userId).first();
  if (!user) return jsonResponse({ success: false, error: 'User not found' }, 404);
  const code = otpCode();
  await storeCode(context.env.DB, user.email, 'email', code);
  const emailResult = await sendEmailCode(context.env, user.email, code, user.display_name);
  return jsonResponse({
    success: true,
    message: 'Verification code sent',
    data: { demo_code: emailResult.demo ? code : undefined },
  });
}

export async function sendPhoneCode(context, body) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const phone = String(body.phone || '').replace(/\s/g, '');
  if (!phone || phone.length < 9) {
    return jsonResponse({ success: false, error: 'Enter a valid phone number' }, 400);
  }
  const code = otpCode();
  await storeCode(context.env.DB, phone, 'phone', code);
  await context.env.DB.prepare(`
    UPDATE users SET phone = ?, updated_at = ? WHERE id = ?
  `).bind(phone, new Date().toISOString(), auth.userId).run();
  console.log(`Phone verification code for ${phone}: ${code}`);
  return jsonResponse({
    success: true,
    message: 'Verification code sent',
    data: { demo_code: code },
  });
}

export async function verifyPhone(context, body) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const phone = String(body.phone || '').replace(/\s/g, '');
  const code = String(body.code || '').trim();
  const ok = await verifyStoredCode(context.env.DB, phone, 'phone', code);
  if (!ok) return jsonResponse({ success: false, error: 'Invalid or expired code' }, 400);
  await context.env.DB.prepare(`
    UPDATE users SET phone = ?, phone_verified = 1, updated_at = ? WHERE id = ?
  `).bind(phone, new Date().toISOString(), auth.userId).run();
  return jsonResponse({ success: true, message: 'Phone verified' });
}

export async function saveProfile(context, body) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const now = new Date().toISOString();
  const {
    stage_name,
    username,
    bio,
    location,
    country,
    category,
    skills,
    hourly_rate,
    profile_photo,
    portfolio,
    availability,
    social_links,
  } = body;

  const user = await context.env.DB.prepare(
    `SELECT id, username, display_name FROM users WHERE id = ?`
  ).bind(auth.userId).first();
  if (!user) return jsonResponse({ success: false, error: 'User not found' }, 404);

  let chosenUsername = user.username;
  if (username || stage_name) {
    const base = username || stage_name || user.display_name;
    let candidate = slugifyUsername(base);
    if (!isValidUsername(candidate)) {
      candidate = await ensureUniqueUsername(context.env.DB, base);
    } else {
      const taken = await context.env.DB.prepare(
        `SELECT id FROM users WHERE LOWER(username) = LOWER(?) AND id != ?`
      ).bind(candidate, auth.userId).first();
      if (taken) candidate = await ensureUniqueUsername(context.env.DB, base);
    }
    chosenUsername = candidate;
  }

  const displayName = stage_name || user.display_name;
  await context.env.DB.prepare(`
    UPDATE users SET
      display_name = COALESCE(?, display_name),
      first_name = COALESCE(?, first_name),
      username = COALESCE(?, username),
      bio = COALESCE(?, bio),
      location = COALESCE(?, location),
      country = COALESCE(?, country),
      profile_picture_url = COALESCE(?, profile_picture_url),
      updated_at = ?
    WHERE id = ?
  `).bind(
    stage_name ? displayName : null,
    stage_name ? displayName : null,
    chosenUsername !== user.username ? chosenUsername : null,
    bio !== undefined ? (bio || null) : null,
    location !== undefined ? (location || null) : null,
    country !== undefined ? (country || null) : null,
    profile_photo || null,
    now,
    auth.userId
  ).run();

  const skillValue = skills !== undefined
    ? (Array.isArray(skills) ? JSON.stringify(skills) : skills)
    : null;
  const cat = category || (skillValue ? categoryFromSkills(skillValue) : null);
  const portfolioJson = portfolio !== undefined ? JSON.stringify(portfolio || []) : null;
  const socialJson = social_links !== undefined ? JSON.stringify(social_links || {}) : null;
  const availabilityJson = availability !== undefined ? JSON.stringify(availability || {}) : null;

  await context.env.DB.prepare(`
    UPDATE artist_profiles SET
      category = COALESCE(?, category),
      skills = COALESCE(?, skills),
      base_rate = COALESCE(?, base_rate),
      hourly_rate = COALESCE(?, hourly_rate),
      portfolio_urls = COALESCE(?, portfolio_urls),
      social_links = COALESCE(?, social_links),
      availability_json = COALESCE(?, availability_json),
      updated_at = ?
    WHERE user_id = ?
  `).bind(
    cat,
    skillValue,
    hourly_rate != null ? Number(hourly_rate) : null,
    hourly_rate != null ? Number(hourly_rate) : null,
    portfolioJson,
    socialJson,
    availabilityJson,
    now,
    auth.userId
  ).run();

  if (hourly_rate != null) {
    const profile = await context.env.DB.prepare(
      `SELECT id FROM artist_profiles WHERE user_id = ?`
    ).bind(auth.userId).first();
    if (profile) {
      const existingSvc = await context.env.DB.prepare(
        `SELECT id FROM services WHERE artist_id = ? LIMIT 1`
      ).bind(profile.id).first();
      const price = Number(hourly_rate);
      const svcName = (cat || 'Gig') + ' booking';
      if (!existingSvc) {
        await context.env.DB.prepare(`
          INSERT INTO services (id, artist_id, name, description, price, duration_hours, is_active, created_at)
          VALUES (?, ?, ?, ?, ?, 1, 1, ?)
        `).bind(
          `svc_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
          profile.id,
          svcName,
          `Book ${displayName} on Gearsh`,
          price,
          now
        ).run();
      } else {
        await context.env.DB.prepare(`
          UPDATE services SET price = ?, name = COALESCE(?, name) WHERE id = ?
        `).bind(price, svcName, existingSvc.id).run();
      }
    }
  }

  return jsonResponse({
    success: true,
    message: 'Profile saved',
    data: {
      username: chosenUsername,
      profile_url: buildProfileUrl(chosenUsername),
      display_name: displayName,
    },
  });
}

export async function getPreview(context) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const row = await context.env.DB.prepare(`
    SELECT
      u.display_name AS name, u.username, u.bio, u.location, u.country,
      u.profile_picture_url AS image, u.phone, u.email_verified, u.phone_verified,
      u.onboarding_status,
      ap.category, ap.skills, ap.hourly_rate, ap.base_rate,
      ap.portfolio_urls, ap.social_links, ap.availability_json
    FROM users u
    LEFT JOIN artist_profiles ap ON ap.user_id = u.id
    WHERE u.id = ?
  `).bind(auth.userId).first();
  if (!row) return jsonResponse({ success: false, error: 'Profile not found' }, 404);
  return jsonResponse({
    success: true,
    data: {
      ...row,
      profile_url: buildProfileUrl(row.username),
      skills: parseSkills(row.skills),
      portfolio_urls: row.portfolio_urls ? JSON.parse(row.portfolio_urls) : [],
      social_links: row.social_links ? JSON.parse(row.social_links) : {},
      availability: row.availability_json ? JSON.parse(row.availability_json) : {},
      email_verified: Boolean(row.email_verified),
      phone_verified: Boolean(row.phone_verified),
    },
  });
}

export async function submitForReview(context) {
  const auth = await requireUser(context);
  if (auth.error) return auth.error;
  const user = await context.env.DB.prepare(`
    SELECT u.id, u.email, u.display_name, u.username, u.email_verified, u.phone_verified
    FROM users u WHERE u.id = ?
  `).bind(auth.userId).first();
  if (!user) return jsonResponse({ success: false, error: 'User not found' }, 404);
  if (!user.email_verified) {
    return jsonResponse({ success: false, error: 'Please verify your email first' }, 400);
  }
  if (!user.phone_verified) {
    return jsonResponse({ success: false, error: 'Please verify your phone number first' }, 400);
  }
  if (!user.display_name || user.display_name === 'New Artist') {
    return jsonResponse({ success: false, error: 'Please complete your profile first' }, 400);
  }

  const now = new Date().toISOString();
  await context.env.DB.prepare(`
    UPDATE users SET onboarding_status = 'pending', is_verified = 0, is_active = 1, updated_at = ?
    WHERE id = ?
  `).bind(now, auth.userId).run();

  const profileUrl = buildProfileUrl(user.username);
  const welcome = await sendWelcomeEmail(context.env, user.email, user.display_name, profileUrl);

  return jsonResponse({
    success: true,
    message: 'Profile submitted for review. Welcome email sent.',
    data: {
      onboarding_status: 'pending',
      profile_url: profileUrl,
      welcome_email_sent: welcome.sent,
    },
  });
}
