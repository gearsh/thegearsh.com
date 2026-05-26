// GET /api/health - Health check endpoint

export async function onRequestGet(context) {
  try {
    let dbStatus = 'unknown';
    try {
      await context.env.DB.prepare('SELECT 1').first();
      dbStatus = 'connected';
    } catch (_) {
      dbStatus = 'error';
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
  } catch (_) {
    return new Response(JSON.stringify({
      success: false,
      status: 'unhealthy',
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

