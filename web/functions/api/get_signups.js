// GET /api/get_signups - founder/admin export of artist signups
//
// Requires either x-founder-key (matching FOUNDER_ACCESS_KEY) or
// x-api-key (matching SIGNUPS_API_KEY). Never serves data without auth.

function constantTimeEquals(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

export async function onRequestGet(context) {
  try {
    const founderExpected = context.env.FOUNDER_ACCESS_KEY || '';
    const apiKeyExpected = context.env.SIGNUPS_API_KEY || '';
    const providedFounder = context.request.headers.get('x-founder-key') || '';
    const providedApi = context.request.headers.get('x-api-key') || '';

    const okFounder = founderExpected && constantTimeEquals(providedFounder, founderExpected);
    const okApi = apiKeyExpected && constantTimeEquals(providedApi, apiKeyExpected);

    if (!okFounder && !okApi) {
      return new Response(JSON.stringify({ success: false, error: 'Unauthorized' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 401,
      });
    }

    const { results } = await context.env.DB.prepare(
      `SELECT * FROM signups WHERE user_type = ?`
    ).bind('artist').all();

    return new Response(JSON.stringify({ success: true, count: results.length, data: results }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err) {
    console.error('Error querying signups');
    return new Response(JSON.stringify({ success: false, error: 'Failed to query signups' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
}
