// Shared email auth utilities for Cloudflare D1

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-founder-key',
  'Content-Type': 'application/json',
};

export function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

export function corsPreflightResponse() {
  return new Response(null, { headers: corsHeaders });
}

export async function hashPassword(password) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + 'gearsh_salt_2025');
  const hash = await crypto.subtle.digest('SHA-256', data);
  return btoa(String.fromCharCode(...new Uint8Array(hash)));
}

export async function verifyPassword(password, hash) {
  const computed = await hashPassword(password);
  return computed === hash;
}

export function generateToken(userId) {
  const payload = {
    userId,
    exp: Date.now() + 7 * 24 * 60 * 60 * 1000,
  };
  return btoa(JSON.stringify(payload));
}

export function parseToken(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  try {
    const payload = JSON.parse(atob(authHeader.slice(7)));
    if (!payload.userId || !payload.exp || payload.exp < Date.now()) return null;
    return payload.userId;
  } catch (_) {
    return null;
  }
}

export function unauthorizedResponse(message = 'Unauthorized') {
  return jsonResponse({ success: false, error: message }, 401);
}

export function parseSkills(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [String(parsed)];
  } catch (_) {
    return String(value).split(',').map(function(s) { return s.trim(); }).filter(Boolean);
  }
}

export function categoryFromSkills(skillSet) {
  const skills = parseSkills(skillSet);
  return skills[0] || 'Services';
}

const RESERVED_USERNAMES = new Set([
  'admin', 'api', 'app', 'artist', 'artists', 'book', 'booking', 'bookings',
  'dashboard', 'discover', 'help', 'home', 'join', 'login', 'logout', 'privacy',
  'profile', 'register', 'search', 'settings', 'signup', 'terms', 'www',
]);

export function slugifyUsername(input) {
  if (!input) return '';
  return String(input)
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9_-]+/g, '-')
    .replace(/^[-_]+|[-_]+$/g, '')
    .replace(/[-_]{2,}/g, '-')
    .slice(0, 32);
}

export function isValidUsername(username) {
  if (!username || username.length < 3 || username.length > 32) return false;
  if (!/^[a-z0-9][a-z0-9_-]*[a-z0-9]$/.test(username) && !/^[a-z0-9]{3,32}$/.test(username)) {
    return false;
  }
  return !RESERVED_USERNAMES.has(username);
}

export async function ensureUniqueUsername(db, base) {
  let username = slugifyUsername(base);
  if (!username || username.length < 3) username = 'artist';
  if (!isValidUsername(username)) username = 'artist';

  let candidate = username;
  let attempt = 0;
  while (attempt < 100) {
    const existing = await db.prepare(
      `SELECT id FROM users WHERE LOWER(username) = LOWER(?)`
    ).bind(candidate).first();
    if (!existing) return candidate;
    attempt += 1;
    candidate = `${username}${attempt}`;
    if (candidate.length > 32) {
      candidate = `${username.slice(0, Math.max(3, 32 - String(attempt).length))}${attempt}`;
    }
  }
  return `${username.slice(0, 24)}${Date.now().toString(36).slice(-4)}`;
}

export function buildProfileUrl(username) {
  if (!username) return null;
  return `/book/${encodeURIComponent(String(username).toLowerCase())}`;
}

export function isArtistId(value) {
  return /^artist_/i.test(String(value || ''));
}

export async function resolveArtistProfile(db, identifier) {
  const value = String(identifier || '').trim();
  if (!value) return null;

  return db.prepare(`
    SELECT
      ap.id AS artist_id,
      u.id AS user_id,
      u.username,
      u.display_name AS artist_name,
      u.phone AS artist_phone
    FROM artist_profiles ap
    JOIN users u ON ap.user_id = u.id
    WHERE u.is_active = 1 AND (ap.id = ? OR LOWER(u.username) = LOWER(?))
    LIMIT 1
  `).bind(value, value).first();
}

export async function ensureArtistUsername(db, userId, fallbackName) {
  const user = await db.prepare(
    `SELECT username FROM users WHERE id = ?`
  ).bind(userId).first();
  if (user?.username) return user.username;

  const username = await ensureUniqueUsername(db, fallbackName || 'artist');
  const updatedAt = new Date().toISOString();
  await db.prepare(
    `UPDATE users SET username = ?, updated_at = ? WHERE id = ?`
  ).bind(username, updatedAt, userId).run();
  return username;
}

export async function findUserByIdentifier(db, identifier) {
  const value = identifier.trim();
  const isEmail = value.includes('@');

  if (isEmail) {
    return db.prepare(
      `SELECT id, email, password_hash, user_type, first_name, last_name,
              display_name, profile_picture_url, is_verified, username
       FROM users
       WHERE LOWER(email) = LOWER(?) AND is_active = 1`
    ).bind(value).first();
  }

  return db.prepare(
    `SELECT id, email, password_hash, user_type, first_name, last_name,
            display_name, profile_picture_url, is_verified, username
     FROM users
     WHERE (username = ? OR LOWER(email) = LOWER(?)) AND is_active = 1`
  ).bind(value, value).first();
}

export async function ensureAuthTables(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      user_type TEXT NOT NULL DEFAULT 'client',
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      display_name TEXT,
      username TEXT,
      profile_picture_url TEXT,
      phone TEXT,
      location TEXT,
      country TEXT DEFAULT 'South Africa',
      bio TEXT,
      firebase_uid TEXT,
      is_verified INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  try {
    await db.prepare(`ALTER TABLE users ADD COLUMN username TEXT`).run();
  } catch (_) {
    // Column may already exist
  }

  try {
    await db.prepare(`ALTER TABLE users ADD COLUMN firebase_uid TEXT`).run();
  } catch (_) {}

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS password_resets (
      email TEXT PRIMARY KEY,
      token TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  `).run();
}

export function formatUserResponse(user, token, artistProfile = null) {
  return {
    user_id: user.id,
    email: user.email,
    user_type: user.user_type,
    first_name: user.first_name,
    last_name: user.last_name,
    display_name: user.display_name,
    username: user.username,
    profile_picture_url: user.profile_picture_url,
    is_verified: Boolean(user.is_verified),
    artist_profile: artistProfile,
    token,
  };
}
