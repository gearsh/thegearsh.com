import { corsPreflightResponse } from '../auth-utils.js';
import { founderLogin } from '../founder-auth.js';

export async function onRequestPost(context) {
  try {
    const body = await context.request.json();
    return founderLogin(context, body);
  } catch (err) {
    console.error('Founder login error:', err);
    return new Response(JSON.stringify({ success: false, error: 'Login failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    });
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
