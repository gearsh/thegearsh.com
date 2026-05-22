// Founder / super-admin access control

import {
  parseToken,
  unauthorizedResponse,
  jsonResponse,
  verifyPassword,
  findUserByIdentifier,
  generateToken,
} from './auth-utils.js';

export const COMMISSION_RATE = 0.126;

export function getFounderEmails(env) {
  const raw = env.FOUNDER_EMAIL || env.ADMIN_EMAIL || '';
  return raw.split(',').map(function(email) {
    return email.trim().toLowerCase();
  }).filter(Boolean);
}

export function verifyFounderAccessKey(env, key) {
  const required = env.FOUNDER_ACCESS_KEY;
  if (!required) return Boolean(key);
  return String(key || '') === required;
}

export function isFounderUser(user, env) {
  if (!user) return false;
  if (user.user_type === 'admin') return true;
  const emails = getFounderEmails(env);
  if (!emails.length) return false;
  return emails.includes(String(user.email || '').toLowerCase());
}

export async function findUserForFounderLogin(db, identifier) {
  const value = identifier.trim();
  const isEmail = value.includes('@');
  if (isEmail) {
    return db.prepare(`
      SELECT id, email, password_hash, user_type, first_name, last_name,
             display_name, profile_picture_url, is_verified, username, is_active
      FROM users
      WHERE LOWER(email) = LOWER(?)
    `).bind(value).first();
  }
  return db.prepare(`
    SELECT id, email, password_hash, user_type, first_name, last_name,
           display_name, profile_picture_url, is_verified, username, is_active
    FROM users
    WHERE username = ? OR LOWER(email) = LOWER(?)
  `).bind(value, value).first();
}

export async function requireFounder(context) {
  const accessKey = context.request.headers.get('x-founder-key') || '';
  if (!verifyFounderAccessKey(context.env, accessKey)) {
    return { error: jsonResponse({ success: false, error: 'Invalid founder access key' }, 403) };
  }

  const userId = parseToken(context.request.headers.get('Authorization'));
  if (!userId) {
    return { error: unauthorizedResponse('Founder session required') };
  }

  const user = await context.env.DB.prepare(`
    SELECT id, email, user_type, first_name, last_name, display_name, username, is_active
    FROM users WHERE id = ?
  `).bind(userId).first();

  if (!user) {
    return { error: unauthorizedResponse('User not found') };
  }

  if (!isFounderUser(user, context.env)) {
    return { error: jsonResponse({ success: false, error: 'Founder access only' }, 403) };
  }

  return { user };
}

export async function founderLogin(context, body) {
  const email = String(body.email || body.identifier || '').trim();
  const password = String(body.password || '');
  const accessKey = String(body.access_key || body.accessKey || '');

  if (!email || !password) {
    return jsonResponse({ success: false, error: 'Email and password are required' }, 400);
  }

  if (!verifyFounderAccessKey(context.env, accessKey)) {
    return jsonResponse({ success: false, error: 'Invalid founder access key' }, 403);
  }

  const user = await findUserForFounderLogin(context.env.DB, email);
  if (!user) {
    return jsonResponse({ success: false, error: 'Invalid credentials' }, 401);
  }

  if (!isFounderUser(user, context.env)) {
    return jsonResponse({
      success: false,
      error: 'This account is not authorized as Gearsh founder/admin',
    }, 403);
  }

  const valid = await verifyPassword(password, user.password_hash);
  if (!valid) {
    return jsonResponse({ success: false, error: 'Invalid credentials' }, 401);
  }

  const token = generateToken(user.id);
  return jsonResponse({
    success: true,
    message: 'Welcome, founder',
    data: {
      user_id: user.id,
      email: user.email,
      display_name: user.display_name || user.first_name,
      token,
    },
  });
}
