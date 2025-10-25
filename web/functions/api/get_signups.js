// filepath: c:\Users\admin\StudioProjects\thegearsh.com\web\functions\api\get_signups.js
// Returns signups from D1 filtered to user_type = 'artist'
export async function onRequestGet(context) {
  try {
    // Optional API key protection: if SIGNUPS_API_KEY is set in the environment,
    // require callers to send the same key in the `x-api-key` request header.
    const requiredKey = context.env.SIGNUPS_API_KEY;
    if (requiredKey) {
      const provided = context.request.headers.get('x-api-key') || '';
      if (provided !== requiredKey) {
        return new Response(JSON.stringify({ success: false, error: 'Unauthorized' }), {
          headers: { 'Content-Type': 'application/json' },
          status: 401,
        });
      }
    }
    // Adjust the SQL as needed (select specific columns, add ORDER BY, pagination, etc.)
    const stmt = context.env.DB.prepare(`
      SELECT * FROM signups WHERE user_type = ?
    `);

    const { results } = await stmt.bind('artist').all();

    return new Response(JSON.stringify({ success: true, count: results.length, data: results }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err) {
    console.error('Error querying signups:', err);
    return new Response(JSON.stringify({ success: false, error: 'Failed to query signups' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
}
