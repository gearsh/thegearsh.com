import { jsonResponse, corsPreflightResponse, parseSkills, buildProfileUrl } from '../auth-utils.js';
import { requireFounder, COMMISSION_RATE } from '../founder-auth.js';

async function safeAll(db, query, params) {
  try {
    const stmt = db.prepare(query);
    const result = params ? await stmt.bind(...params).all() : await stmt.all();
    return result.results || [];
  } catch (_) {
    return [];
  }
}

async function safeFirst(db, query, params) {
  try {
    const stmt = db.prepare(query);
    const result = params ? await stmt.bind(...params).first() : await stmt.first();
    return result || null;
  } catch (_) {
    return null;
  }
}

export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;

    const db = context.env.DB;

    const counts = await safeFirst(db, `
      SELECT
        SUM(CASE WHEN user_type = 'artist' THEN 1 ELSE 0 END) AS artists,
        SUM(CASE WHEN user_type = 'client' THEN 1 ELSE 0 END) AS clients,
        SUM(CASE WHEN user_type = 'admin' THEN 1 ELSE 0 END) AS admins,
        COUNT(*) AS total_users,
        SUM(CASE WHEN is_verified = 1 AND user_type = 'artist' THEN 1 ELSE 0 END) AS verified_artists,
        SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS inactive_users
      FROM users
    `);

    const signupsToday = await safeFirst(db, `
      SELECT COUNT(*) AS count FROM users
      WHERE date(created_at) = date('now')
    `);

    const signupsWeek = await safeFirst(db, `
      SELECT COUNT(*) AS count FROM users
      WHERE datetime(created_at) >= datetime('now', '-7 days')
    `);

    const bookingStats = await safeFirst(db, `
      SELECT
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
        SUM(CASE WHEN status = 'completed' THEN COALESCE(total_price, 0) ELSE 0 END) AS gross_revenue
      FROM bookings
    `);

    const grossRevenue = Number(bookingStats?.gross_revenue || 0);
    const commissionEarned = Math.round(grossRevenue * COMMISSION_RATE * 100) / 100;

    const countries = await safeAll(db, `
      SELECT COALESCE(NULLIF(country, ''), 'Unknown') AS label, COUNT(*) AS count
      FROM users
      WHERE user_type = 'artist'
      GROUP BY label
      ORDER BY count DESC
      LIMIT 12
    `);

    const categories = await safeAll(db, `
      SELECT COALESCE(NULLIF(ap.category, ''), 'Uncategorised') AS label, COUNT(*) AS count
      FROM artist_profiles ap
      JOIN users u ON ap.user_id = u.id
      GROUP BY label
      ORDER BY count DESC
      LIMIT 12
    `);

    const recentSignups = await safeAll(db, `
      SELECT
        u.id, u.email, u.display_name, u.user_type, u.country, u.location,
        u.phone, u.is_verified, u.is_active, u.created_at, u.username,
        ap.id AS artist_id, ap.category, ap.skills, ap.total_bookings
      FROM users u
      LEFT JOIN artist_profiles ap ON ap.user_id = u.id
      ORDER BY u.created_at DESC
      LIMIT 25
    `);

    const recentBookings = await safeAll(db, `
      SELECT
        b.id, b.status, b.total_price, b.event_date, b.event_location, b.created_at,
        ua.display_name AS artist_name, uc.display_name AS client_name
      FROM bookings b
      LEFT JOIN artist_profiles ap ON b.artist_id = ap.id
      LEFT JOIN users ua ON ap.user_id = ua.id
      LEFT JOIN users uc ON b.client_id = uc.id
      ORDER BY b.created_at DESC
      LIMIT 20
    `);

    const legacySignups = await safeAll(db, `
      SELECT id, email, user_name, first_name, surname, country, location, skill_set, user_type, created_date
      FROM signups
      ORDER BY created_date DESC
      LIMIT 15
    `);

    const signupsMapped = recentSignups.map(function(row) {
      return {
        ...row,
        is_verified: Boolean(row.is_verified),
        is_active: Boolean(row.is_active),
        skills: parseSkills(row.skills),
        profile_url: row.username ? buildProfileUrl(row.username) : null,
        source: 'users',
      };
    });

    return jsonResponse({
      success: true,
      data: {
        overview: {
          total_users: Number(counts?.total_users || 0),
          artists: Number(counts?.artists || 0),
          clients: Number(counts?.clients || 0),
          verified_artists: Number(counts?.verified_artists || 0),
          inactive_users: Number(counts?.inactive_users || 0),
          signups_today: Number(signupsToday?.count || 0),
          signups_this_week: Number(signupsWeek?.count || 0),
        },
        bookings: {
          total: Number(bookingStats?.total_bookings || 0),
          pending: Number(bookingStats?.pending || 0),
          confirmed: Number(bookingStats?.confirmed || 0),
          completed: Number(bookingStats?.completed || 0),
          cancelled: Number(bookingStats?.cancelled || 0),
          gross_revenue: grossRevenue,
          commission_rate: COMMISSION_RATE,
          commission_earned: commissionEarned,
        },
        breakdown: {
          countries,
          categories,
        },
        recent_signups: signupsMapped,
        legacy_signups: legacySignups,
        recent_bookings: recentBookings,
      },
    });
  } catch (err) {
    console.error('Founder stats error:', err);
    return jsonResponse({ success: false, error: 'Failed to load founder stats' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
