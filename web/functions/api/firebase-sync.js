// POST /api/firebase-sync - sync Firebase Auth users with D1 database
//
// Security: requires a verified Firebase ID token in the Authorization header.
// If FIREBASE_PROJECT_ID is not configured the endpoint refuses to run so it
// cannot be used to forge accounts.

const FIREBASE_KEYS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

const KEY_CACHE = { keys: null, expiresAt: 0 };

async function fetchFirebaseKeys() {
  const now = Date.now();
  if (KEY_CACHE.keys && now < KEY_CACHE.expiresAt) return KEY_CACHE.keys;
  const res = await fetch(FIREBASE_KEYS_URL);
  if (!res.ok) throw new Error('Failed to fetch Firebase certs');
  const cacheControl = res.headers.get('cache-control') || '';
  const maxAgeMatch = cacheControl.match(/max-age=(\d+)/);
  const ttl = maxAgeMatch ? parseInt(maxAgeMatch[1], 10) * 1000 : 60 * 60 * 1000;
  KEY_CACHE.keys = await res.json();
  KEY_CACHE.expiresAt = now + ttl;
  return KEY_CACHE.keys;
}

function base64UrlDecode(value) {
  const padded = value.replace(/-/g, '+').replace(/_/g, '/');
  const pad = padded.length % 4 === 0 ? '' : '='.repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function pemToArrayBuffer(pem) {
  const stripped = pem
    .replace(/-----BEGIN CERTIFICATE-----/, '')
    .replace(/-----END CERTIFICATE-----/, '')
    .replace(/\s+/g, '');
  const binary = atob(stripped);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function verifyFirebaseToken(token, projectId) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  const headerJson = new TextDecoder().decode(base64UrlDecode(parts[0]));
  const payloadJson = new TextDecoder().decode(base64UrlDecode(parts[1]));
  let header;
  let payload;
  try {
    header = JSON.parse(headerJson);
    payload = JSON.parse(payloadJson);
  } catch (_) {
    return null;
  }

  if (header.alg !== 'RS256' || !header.kid) return null;
  if (!payload || !payload.sub || !payload.iss || !payload.aud) return null;
  if (payload.aud !== projectId) return null;
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) return null;

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < now) return null;
  if (payload.iat && payload.iat > now + 300) return null;

  const keys = await fetchFirebaseKeys();
  const pem = keys[header.kid];
  if (!pem) return null;

  // Firebase publishes X.509 certificates; we cannot import them directly via
  // SubtleCrypto. Cloudflare Workers do not ship X.509 parsing in the standard
  // crypto API, so we fall back to importing the embedded SPKI using the JOSE
  // helper provided by the runtime when available. If unavailable, refuse.
  if (typeof crypto.subtle.importKey !== 'function') return null;

  try {
    const cryptoKey = await crypto.subtle.importKey(
      'spki',
      extractSpkiFromCert(pemToArrayBuffer(pem)),
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['verify'],
    );

    const signature = base64UrlDecode(parts[2]);
    const data = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', cryptoKey, signature, data);
    return valid ? payload : null;
  } catch (_) {
    return null;
  }
}

// Best-effort SPKI extraction from an X.509 certificate ArrayBuffer.
function extractSpkiFromCert(certBytes) {
  const bytes = new Uint8Array(certBytes);
  // Search for SubjectPublicKeyInfo OID prefix for rsaEncryption.
  const marker = [0x30, 0x82];
  for (let i = 0; i < bytes.length - 14; i += 1) {
    if (
      bytes[i] === marker[0]
      && bytes[i + 1] === marker[1]
      && bytes[i + 4] === 0x30
      && bytes[i + 5] === 0x0d
      && bytes[i + 6] === 0x06
      && bytes[i + 7] === 0x09
      && bytes[i + 8] === 0x2a
      && bytes[i + 9] === 0x86
      && bytes[i + 10] === 0x48
      && bytes[i + 11] === 0x86
      && bytes[i + 12] === 0xf7
    ) {
      return bytes.buffer.slice(i, i + 4 + ((bytes[i + 2] << 8) | bytes[i + 3]));
    }
  }
  throw new Error('SPKI not found in certificate');
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Vary': 'Origin',
    'Content-Type': 'application/json',
  };
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders() });
}

export async function onRequestPost(context) {
  const { request, env } = context;

  try {
    const authHeader = request.headers.get('Authorization') || '';
    if (!authHeader.startsWith('Bearer ')) {
      return jsonResponse({ success: false, error: 'Authorization required' }, 401);
    }

    const projectId = env.FIREBASE_PROJECT_ID;
    if (!projectId) {
      return jsonResponse(
        { success: false, error: 'Firebase auth is not configured on this server' },
        503,
      );
    }

    const token = authHeader.slice(7).trim();
    const payload = await verifyFirebaseToken(token, projectId);
    if (!payload) {
      return jsonResponse({ success: false, error: 'Invalid Firebase token' }, 401);
    }

    const body = await request.json();
    const { username, first_name, last_name, photo_url, provider, provider_id, is_new_user } =
      body || {};

    const firebase_uid = payload.sub;
    const email = (payload.email || body?.email || '').toLowerCase();
    if (!email) {
      return jsonResponse({ success: false, error: 'Email is required' }, 400);
    }

    const existingUser = await env.DB.prepare(
      'SELECT id, email, username FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    if (existingUser) {
      await env.DB.prepare(`
        UPDATE users SET
          email = ?,
          photo_url = COALESCE(?, photo_url),
          updated_at = datetime('now')
        WHERE firebase_uid = ?
      `).bind(email, photo_url || null, firebase_uid).run();

      return jsonResponse({
        success: true,
        message: 'User synced successfully',
        user: {
          id: existingUser.id,
          email: existingUser.email,
          username: existingUser.username,
          is_new_user: false,
        },
      });
    }

    const existingByEmail = await env.DB.prepare(
      'SELECT id, email, username FROM users WHERE LOWER(email) = LOWER(?)'
    ).bind(email).first();

    if (existingByEmail) {
      await env.DB.prepare(`
        UPDATE users SET
          firebase_uid = ?,
          provider = COALESCE(?, provider),
          provider_id = COALESCE(?, provider_id),
          photo_url = COALESCE(?, photo_url),
          updated_at = datetime('now')
        WHERE LOWER(email) = LOWER(?)
      `).bind(
        firebase_uid,
        provider || null,
        provider_id || null,
        photo_url || null,
        email,
      ).run();

      return jsonResponse({
        success: true,
        message: 'Account linked to Firebase',
        user: {
          id: existingByEmail.id,
          email: existingByEmail.email,
          username: existingByEmail.username,
          is_new_user: false,
        },
      });
    }

    if (!is_new_user) {
      return jsonResponse({ success: false, error: 'User not found' }, 404);
    }

    let finalUsername = (username || email.split('@')[0] || 'user').toLowerCase();
    finalUsername = finalUsername.replace(/[^a-z0-9_-]+/g, '-').slice(0, 32) || 'user';

    const usernameExists = await env.DB.prepare(
      'SELECT id FROM users WHERE LOWER(username) = LOWER(?)'
    ).bind(finalUsername).first();

    if (usernameExists) {
      finalUsername = `${finalUsername.slice(0, 28)}${Math.floor(Math.random() * 9999)}`;
    }

    await env.DB.prepare(`
      INSERT INTO users (
        firebase_uid,
        email,
        username,
        first_name,
        last_name,
        photo_url,
        provider,
        provider_id,
        role,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'user', datetime('now'), datetime('now'))
    `).bind(
      firebase_uid,
      email,
      finalUsername,
      first_name || '',
      last_name || '',
      photo_url || null,
      provider || 'email',
      provider_id || null,
    ).run();

    const newUser = await env.DB.prepare(
      'SELECT id, email, username FROM users WHERE firebase_uid = ?'
    ).bind(firebase_uid).first();

    return jsonResponse({
      success: true,
      message: 'User created successfully',
      user: {
        id: newUser?.id,
        email,
        username: finalUsername,
        is_new_user: true,
      },
    }, 201);
  } catch (error) {
    console.error('Firebase sync error:', error);
    return jsonResponse({ success: false, error: 'Internal server error' }, 500);
  }
}

export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: corsHeaders() });
}
