// Shared email auth utilities for Cloudflare D1

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-founder-key, x-api-key',
  'Vary': 'Origin',
  'Content-Type': 'application/json',
};

const LEGACY_SALT = 'gearsh_salt_2025';
const PBKDF2_ITERATIONS = 100000;

export function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

export function corsPreflightResponse() {
  return new Response(null, { headers: corsHeaders });
}

export function safeErrorResponse(error, status = 500) {
  const message = typeof error === 'string' ? error : 'Internal server error';
  return jsonResponse({ success: false, error: message }, status);
}

function bytesToBase64(bytes) {
  return btoa(String.fromCharCode(...new Uint8Array(bytes)));
}

function base64UrlEncode(bytes) {
  return bytesToBase64(bytes)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function base64UrlDecode(value) {
  const padded = value.replace(/-/g, '+').replace(/_/g, '/');
  const pad = padded.length % 4 === 0 ? '' : '='.repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function getJwtSecret(env) {
  const secret = env?.JWT_SECRET || env?.AUTH_SECRET;
  if (secret && String(secret).length >= 16) return secret;
  if ((env?.NODE_ENV || env?.ENVIRONMENT) === 'production') {
    throw new Error('JWT_SECRET not configured');
  }
  return 'gearsh-dev-secret-change-in-production';
}

function allowLegacyTokens(env) {
  const value = String(env?.ALLOW_LEGACY_TOKENS || '').toLowerCase();
  return value === '1' || value === 'true' || value === 'yes';
}

export function isFounderRequest(request, env) {
  const provided = request.headers.get('x-founder-key') || '';
  const expected = env?.FOUNDER_ACCESS_KEY || '';
  if (!expected) return false;
  if (provided.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < provided.length; i += 1) {
    diff |= provided.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return diff === 0;
}

export function requireFounder(context) {
  if (!isFounderRequest(context.request, context.env)) {
    return unauthorizedResponse('Founder access required');
  }
  return null;
}

async function importHmacKey(secret) {
  return crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

async function legacyHashPassword(password) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + LEGACY_SALT);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return btoa(String.fromCharCode(...new Uint8Array(hash)));
}

export async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  );
  const derived = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt,
      iterations: PBKDF2_ITERATIONS,
      hash: 'SHA-256',
    },
    keyMaterial,
    256
  );
  return `pbkdf2:${bytesToBase64(salt)}:${bytesToBase64(derived)}`;
}

export async function verifyPassword(password, storedHash) {
  if (!storedHash) return false;
  if (String(storedHash).startsWith('pbkdf2:')) {
    const parts = String(storedHash).split(':');
    if (parts.length !== 3) return false;
    const salt = Uint8Array.from(atob(parts[1]), function(c) { return c.charCodeAt(0); });
    const expected = Uint8Array.from(atob(parts[2]), function(c) { return c.charCodeAt(0); });
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password),
      'PBKDF2',
      false,
      ['deriveBits']
    );
    const derived = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        salt,
        iterations: PBKDF2_ITERATIONS,
        hash: 'SHA-256',
      },
      keyMaterial,
      256
    );
    const actual = new Uint8Array(derived);
    if (actual.length !== expected.length) return false;
    let diff = 0;
    for (let i = 0; i < actual.length; i += 1) {
      diff |= actual[i] ^ expected[i];
    }
    return diff === 0;
  }
  const computed = await legacyHashPassword(password);
  const a = String(computed);
  const b = String(storedHash);
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

export function passwordNeedsRehash(storedHash) {
  return !String(storedHash || '').startsWith('pbkdf2:');
}

export async function generateToken(userId, env) {
  const header = base64UrlEncode(new TextEncoder().encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
  const payload = base64UrlEncode(new TextEncoder().encode(JSON.stringify({
    userId,
    exp: Date.now() + 7 * 24 * 60 * 60 * 1000,
    iat: Date.now(),
  })));
  const unsigned = `${header}.${payload}`;
  const key = await importHmacKey(getJwtSecret(env));
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${base64UrlEncode(signature)}`;
}

function parseLegacyToken(token) {
  try {
    const payload = JSON.parse(atob(token));
    if (!payload.userId || !payload.exp || payload.exp < Date.now()) return null;
    return payload.userId;
  } catch (_) {
    return null;
  }
}

async function parseJwtToken(token, env) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  const unsigned = `${parts[0]}.${parts[1]}`;
  let key;
  try {
    key = await importHmacKey(getJwtSecret(env));
  } catch (_) {
    return null;
  }
  const signature = base64UrlDecode(parts[2]);
  const valid = await crypto.subtle.verify(
    'HMAC',
    key,
    signature,
    new TextEncoder().encode(unsigned)
  );
  if (!valid) return null;
  const payloadJson = new TextDecoder().decode(base64UrlDecode(parts[1]));
  const payload = JSON.parse(payloadJson);
  if (!payload.userId || !payload.exp || payload.exp < Date.now()) return null;
  return payload.userId;
}

export async function parseToken(authHeader, env) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice(7).trim();
  if (!token) return null;
  if (token.includes('.')) {
    const jwtUserId = await parseJwtToken(token, env);
    if (jwtUserId) return jwtUserId;
  }
  if (!allowLegacyTokens(env)) return null;
  return parseLegacyToken(token);
}

export function unauthorizedResponse(message = 'Unauthorized') {
  return jsonResponse({ success: false, error: message }, 401);
}

export async function requireAuth(context) {
  const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
  if (!userId) {
    return { error: unauthorizedResponse() };
  }
  const user = await context.env.DB.prepare(`
    SELECT id, email, user_type, first_name, last_name, display_name, username, is_verified, is_active
    FROM users
    WHERE id = ? AND is_active = 1
  `).bind(userId).first();
  if (!user) {
    return { error: unauthorizedResponse('User not found') };
  }
  return { userId, user };
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
  if (!skills.length) return 'Services';
  const first = String(skills[0]).toLowerCase();
  if (first.includes('tech artist') || first === 'tech') return 'Tech artist';
  if (first.includes('car wash')) return 'Car wash';
  return skills[0];
}

const RESERVED_USERNAMES = new Set([
  'admin', 'api', 'app', 'artist', 'artists', 'book', 'booking', 'bookings',
  'dashboard', 'discover', 'gearsh', 'help', 'home', 'join', 'login', 'logout', 'privacy',
  'profile', 'register', 'search', 'settings', 'signup', 'terms', 'www', 'sign-in',
  'thegearsh', 'gearsh-god',
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

/** Strip @handle prefix; distinguish emails from usernames like @gearsh */
export function normalizeLoginIdentifier(raw) {
  let value = String(raw || '').trim();
  if (value.startsWith('@')) {
    value = value.slice(1).trim();
  }
  const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  return { value, isEmail };
}

export async function findUserByIdentifier(db, identifier) {
  const { value, isEmail } = normalizeLoginIdentifier(identifier);
  if (!value) return null;
  const activeClause = `(is_active = 1 OR user_type = 'admin')`;
  const fullColumns = `id, email, password_hash, user_type, first_name, last_name,
            display_name, profile_picture_url, is_verified, username, is_active`;
  const baseColumns = `id, email, password_hash, user_type, first_name, last_name,
            display_name, profile_picture_url, is_verified, is_active`;

  try {
    if (isEmail) {
      return db.prepare(
        `SELECT ${fullColumns} FROM users WHERE LOWER(email) = LOWER(?) AND ${activeClause}`
      ).bind(value).first();
    }

    return db.prepare(
      `SELECT ${fullColumns}
       FROM users
       WHERE (LOWER(username) = LOWER(?) OR LOWER(email) = LOWER(?))
         AND ${activeClause}`
    ).bind(value, value).first();
  } catch (err) {
    if (isEmail) {
      return db.prepare(
        `SELECT ${baseColumns} FROM users WHERE LOWER(email) = LOWER(?) AND ${activeClause}`
      ).bind(value).first();
    }

    return db.prepare(
      `SELECT ${baseColumns} FROM users WHERE LOWER(email) = LOWER(?) AND ${activeClause}`
    ).bind(value, value).first();
  }
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
  } catch (_) {}

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

export async function getArtistProfileSummary(db, userId) {
  try {
    return await db.prepare(
      `SELECT id, category, avg_rating, total_bookings
       FROM artist_profiles WHERE user_id = ?`
    ).bind(userId).first();
  } catch (_) {
    return null;
  }
}

/** Where static web should send the user after sign-in. */
export function resolvePostLoginPath(user, hasArtistProfile) {
  const username = String(user.username || '').toLowerCase();
  if (username === 'gearsh' && hasArtistProfile) {
    return '/artist-dashboard.html';
  }
  if (hasArtistProfile || user.user_type === 'artist') {
    return '/artist-dashboard.html';
  }
  if (user.user_type === 'admin') {
    return '/gearsh-god.html';
  }
  return '/';
}

/** Unified multi-role model: one account may act as client and artist. */
export async function resolveUserRoles(db, user) {
  const roles = new Set();
  if (user.user_type === 'admin') roles.add('admin');
  roles.add('client');
  const profile = await getArtistProfileSummary(db, user.id);
  if (profile || user.user_type === 'artist') roles.add('artist');
  return Array.from(roles);
}

export function resolveActivePerspective(user, roles, hasArtistProfile) {
  const stored = user.active_perspective;
  if (stored && roles.includes(stored)) return stored;
  if (hasArtistProfile || user.user_type === 'artist') return 'artist';
  if (user.user_type === 'admin') return 'admin';
  return 'client';
}

export async function formatUserResponse(db, user, token, artistProfile = null) {
  const hasArtistProfile = Boolean(artistProfile && artistProfile.id);
  const roles = db ? await resolveUserRoles(db, user) : ['client'];
  const activePerspective = resolveActivePerspective(user, roles, hasArtistProfile);
  return {
    user_id: user.id,
    email: user.email,
    user_type: user.user_type,
    roles,
    active_perspective: activePerspective,
    first_name: user.first_name,
    last_name: user.last_name,
    display_name: user.display_name,
    username: user.username,
    profile_picture_url: user.profile_picture_url,
    is_verified: Boolean(user.is_verified),
    artist_profile: artistProfile,
    has_artist_dashboard: hasArtistProfile,
    redirect_path: resolvePostLoginPath(user, hasArtistProfile),
    token,
  };
}
