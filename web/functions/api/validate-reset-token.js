import { corsPreflightResponse, jsonResponse } from './auth-utils.js';
import { hashResetToken } from './password-reset-utils.js';

export async function onRequestPost(context) {
  try {
    const { token } = await context.request.json();
    if (typeof token !== 'string' || !/^[0-9a-f-]{36}$/i.test(token)) {
      return jsonResponse({ valid: false }, 400);
    }
    if (!context.env.DB) return jsonResponse({ valid: false }, 503);
    const tokenHash = await hashResetToken(token);
    const record = await context.env.DB.prepare(
      'SELECT email FROM password_resets WHERE (token = ? OR token = ?) AND expires_at > ? LIMIT 1'
    ).bind(tokenHash, token, new Date().toISOString()).first();
    return jsonResponse({ valid: Boolean(record) }, record ? 200 : 400);
  } catch (error) {
    console.error('Reset token validation failed:', error);
    return jsonResponse({ valid: false }, 500);
  }
}

export async function onRequestOptions() { return corsPreflightResponse(); }
