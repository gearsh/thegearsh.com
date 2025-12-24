// GET /api/health - Health check endpoint

export async function onRequestGet(context) {
  try {
    // Try to ping the database
    let dbStatus = 'unknown';
    try {
      await context.env.DB.prepare('SELECT 1').first();
      dbStatus = 'connected';
    } catch (e) {
      dbStatus = 'error: ' + e.message;
    }

    return new Response(JSON.stringify({
      success: true,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: dbStatus,
      version: '1.0.0'
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200,
    });
  } catch (err) {
    return new Response(JSON.stringify({
      success: false,
      status: 'unhealthy',
      error: err.message
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 500,
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}

