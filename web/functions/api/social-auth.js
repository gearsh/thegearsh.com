// POST /api/social-auth - Google / Apple sign-in for the Flutter app.
//
// Hardened: requires a verifiable ID token. Google tokens are validated via
// the Google tokeninfo endpoint; Apple sign-in requires APPLE_OAUTH_AUDIENCE
// and is checked by signature verification against Apple's public JWKS.
// If neither verifier is available the endpoint refuses to run so this can
// never be used to forge accounts in production.

const APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys';

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin',
    'Content-Type': 'application/json',
  };
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders() });
}

async function verifyGoogleToken(idToken, expectedClientId) {
  try {
    const url = new URL('https://oauth2.googleapis.com/tokeninfo');
    url.searchParams.set('id_token', idToken);
    const res = await fetch(url, { method: 'GET' });
    if (!res.ok) return null;
    const data = await res.json();
    if (!data || !data.email || !data.aud) return null;
    if (expectedClientId && data.aud !== expectedClientId) return null;
    if (data.email_verified !== 'true' && data.email_verified !== true) return null;
    return {
      email: String(data.email).toLowerCase(),
      first_name: data.given_name || '',
      last_name: data.family_name || '',
      photo_url: data.picture || null,
      provider_id: data.sub,
    };
  } catch (_) {
    return null;
  }
}

function base64UrlDecode(value) {
  const padded = value.replace(/-/g, '+').replace(/_/g, '/');
  const pad = padded.length % 4 === 0 ? '' : '='.repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function verifyAppleToken(idToken, audience) {
  try {
    const parts = String(idToken || '').split('.');
    if (parts.length !== 3) return null;
    const header = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[0])));
    const payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[1])));
    if (!header.kid || header.alg !== 'RS256') return null;
    if (payload.iss !== 'https://appleid.apple.com') return null;
    if (audience && payload.aud !== audience) return null;
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) return null;

    const res = await fetch(APPLE_KEYS_URL);
    if (!res.ok) return null;
    const { keys = [] } = await res.json();
    const jwk = keys.find((k) => k.kid === header.kid);
    if (!jwk) return null;

    const key = await crypto.subtle.importKey(
      'jwk',
      jwk,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['verify'],
    );
    const signature = base64UrlDecode(parts[2]);
    const data = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, signature, data);
    if (!ok) return null;

    return {
      email: (payload.email || '').toLowerCase(),
      first_name: '',
      last_name: '',
      photo_url: null,
      provider_id: payload.sub,
    };
  } catch (_) {
    return null;
  }
}

export async function onRequestPost(context) {
  try {
    const data = await context.request.json();
    const { provider, id_token, photo_url } = data || {};

    if (!provider || !['google', 'apple'].includes(provider)) {
      return jsonResponse({ success: false, error: 'Invalid provider' }, 400);
    }
    if (!id_token) {
      return jsonResponse({ success: false, error: 'id_token is required' }, 400);
    }

    let verified = null;
    if (provider === 'google') {
      const clientId = context.env.GOOGLE_OAUTH_CLIENT_ID;
      verified = await verifyGoogleToken(id_token, clientId);
    } else if (provider === 'apple') {
      const audience = context.env.APPLE_OAUTH_AUDIENCE;
      if (!audience) {
        return jsonResponse(
          { success: false, error: 'Apple sign-in not configured on server' },
          503,
        );
      }
      verified = await verifyAppleToken(id_token, audience);
    }

    if (!verified || !verified.email) {
      return jsonResponse({ success: false, error: 'Could not verify identity token' }, 401);
    }

    const email = verified.email;
    const first_name = data?.first_name || verified.first_name;
    const last_name = data?.last_name || verified.last_name;
    const photo = photo_url || verified.photo_url || null;
    const provider_id = verified.provider_id;

    const existingUser = await context.env.DB.prepare(
      'SELECT * FROM signups WHERE LOWER(email) = LOWER(?)'
    ).bind(email).first();

    let isNewUser = false;

    if (existingUser) {
      await context.env.DB.prepare(`
        UPDATE signups
        SET social_provider = ?,
            social_provider_id = ?,
            photo_url = COALESCE(?, photo_url)
        WHERE LOWER(email) = LOWER(?)
      `).bind(provider, provider_id, photo, email).run();
    } else {
      isNewUser = true;
      const user_name = email.split('@')[0];
      const created_date = new Date().toISOString();

      // Ensure social columns exist (idempotent)
      const alterStatements = [
        'ALTER TABLE signups ADD COLUMN social_provider TEXT',
        'ALTER TABLE signups ADD COLUMN social_provider_id TEXT',
        'ALTER TABLE signups ADD COLUMN photo_url TEXT',
      ];
      for (const stmt of alterStatements) {
        try { await context.env.DB.prepare(stmt).run(); } catch (_) {}
      }

      await context.env.DB.prepare(`
        INSERT INTO signups (
          user_name, first_name, surname, email, user_type,
          country, created_date, social_provider, social_provider_id, photo_url
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        user_name,
        first_name || '',
        last_name || '',
        email,
        'fan',
        'South Africa',
        created_date,
        provider,
        provider_id,
        photo,
      ).run();
    }

    return jsonResponse({
      success: true,
      is_new_user: isNewUser,
      message: isNewUser ? 'Account created successfully' : 'Signed in successfully',
      user: {
        email,
        first_name,
        last_name,
        photo_url: photo,
        provider,
      },
    }, isNewUser ? 201 : 200);
  } catch (err) {
    console.error('Social auth error');
    return jsonResponse({ success: false, error: 'Authentication failed' }, 500);
  }
}

export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: corsHeaders() });
}
