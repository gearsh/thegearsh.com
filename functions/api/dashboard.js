// GET /api/dashboard — authenticated artist dashboard data
import {
  parseToken,
  unauthorizedResponse,
  jsonResponse,
  corsPreflightResponse,
  buildProfileUrl,
  ensureArtistUsername,
} from './auth-utils.js';

function masteryTier(hours) {
  if (hours >= 10000) {
    return { id: 'legend', label: 'Legend', range: '10,000+ hrs', icon: 'crown' };
  }
    if (hours >= 5000) {
    return { id: 'expert', label: 'Expert', range: '5,000 to 9,999 hrs', icon: 'star' };
  }
  if (hours >= 100) {
    return { id: 'rising', label: 'Rising', range: '100 to 4,999 hrs', icon: 'rocket' };
  }
  return { id: 'newcomer', label: 'Newcomer', range: '0 to 99 hrs', icon: 'seedling' };
}

function parsePortfolioUrls(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return String(value).split(',').map(function(s) { return s.trim(); }).filter(Boolean);
  }
}

function buildChecklist(user, artistProfile, services) {
  const portfolio = parsePortfolioUrls(artistProfile?.portfolio_urls);
  const profileComplete = Boolean(
    user.bio && user.phone && user.profile_picture_url && user.location
  );
  const verificationPending = user.onboarding_status === 'pending' && !user.is_verified;

  return [
    {
      id: 'profile',
      title: 'Complete your profile',
      description: 'Add your bio, photo, and contact details so clients know who you are.',
      action: 'Edit profile',
      completed: profileComplete,
    },
    {
      id: 'portfolio',
      title: 'Upload portfolio',
      description: 'Show clients your best work. Photos, videos, and past gigs.',
      action: 'Add photos',
      completed: portfolio.length > 0,
    },
    {
      id: 'services',
      title: 'Set services & pricing',
      description: 'Define what you offer and your rates so clients can book you.',
      action: 'Add services',
      completed: services.length > 0,
    },
    {
      id: 'verified',
      title: 'Get verified',
      description: verificationPending
        ? 'Your profile is under review. We typically approve within 24–48 hours.'
        : 'Verified artists get 3× more bookings. Submit when your profile, portfolio, and services are ready.',
      action: user.is_verified ? 'Verified' : (verificationPending ? 'Under review' : 'Submit'),
      completed: Boolean(user.is_verified),
      pending: verificationPending,
    },
  ];
}

export async function onRequestGet(context) {
  try {
    const userId = await parseToken(context.request.headers.get('Authorization'), context.env);
    if (!userId) return unauthorizedResponse();

    const user = await context.env.DB.prepare(`
      SELECT
        id, email, user_type, first_name, last_name, display_name, username,
        profile_picture_url, phone, location, country, bio, is_verified,
        email_verified, phone_verified, onboarding_status, created_at
      FROM users
      WHERE id = ? AND is_active = 1
    `).bind(userId).first();

    if (!user) return unauthorizedResponse('User not found');

    const artistProfile = await context.env.DB.prepare(`
      SELECT *
      FROM artist_profiles
      WHERE user_id = ?
    `).bind(userId).first();

    if (!artistProfile) {
      if (user.user_type === 'artist') {
        return jsonResponse({
          success: false,
          error: 'Artist profile not found. Complete signup at /join-gig.html',
        }, 404);
      }
      return jsonResponse({ success: false, error: 'Artist dashboard only' }, 403);
    }

    const servicesResult = await context.env.DB.prepare(`
      SELECT id, name, description, price, duration_hours, is_active, created_at
      FROM services
      WHERE artist_id = ? AND is_active = 1
      ORDER BY created_at DESC
    `).bind(artistProfile.id).all();

    const bookingsResult = await context.env.DB.prepare(`
      SELECT
        b.id, b.event_date, b.event_time, b.event_location, b.event_type,
        b.duration_hours, b.total_price, b.status, b.notes, b.created_at,
        u.display_name AS client_name,
        s.name AS service_name
      FROM bookings b
      JOIN users u ON b.client_id = u.id
      LEFT JOIN services s ON b.service_id = s.id
      WHERE b.artist_id = ?
      ORDER BY b.event_date DESC, b.created_at DESC
      LIMIT 50
    `).bind(artistProfile.id).all();

    const statsRow = await context.env.DB.prepare(`
      SELECT
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN status IN ('accepted', 'confirmed', 'completed') THEN 1 ELSE 0 END) AS active_bookings,
        SUM(CASE WHEN status = 'completed' THEN COALESCE(total_price, 0) ELSE 0 END) AS earnings,
        SUM(CASE WHEN status = 'completed' THEN COALESCE(duration_hours, 0) ELSE 0 END) AS mastery_hours
      FROM bookings
      WHERE artist_id = ?
    `).bind(artistProfile.id).first();

    const services = servicesResult.results || [];
    const bookings = bookingsResult.results || [];
    const masteryHours = Math.round(Number(statsRow?.mastery_hours || 0));
    const tier = masteryTier(masteryHours);
    const checklist = buildChecklist(user, artistProfile, services);
    const checklistComplete = checklist.filter(function(item) { return item.completed; }).length;
    const username = await ensureArtistUsername(
      context.env.DB,
      userId,
      user.display_name || user.first_name
    );

    const activity = bookings.slice(0, 5).map(function(booking) {
      return {
        id: booking.id,
        type: 'booking',
        title: booking.client_name + ': ' + (booking.service_name || booking.event_type || 'Booking request'),
        subtitle: booking.event_date +
          (booking.event_time ? ' · ' + booking.event_time : '') +
          (booking.event_location ? ' · ' + booking.event_location : ''),
        status: booking.status,
        created_at: booking.created_at,
      };
    });

    return jsonResponse({
      success: true,
      data: {
        user: {
          ...user,
          username,
          is_verified: Boolean(user.is_verified),
          email_verified: Boolean(user.email_verified),
          phone_verified: Boolean(user.phone_verified),
          onboarding_status: user.onboarding_status || 'draft',
        },
        artist_profile: {
          ...artistProfile,
          is_trending: Boolean(artistProfile.is_trending),
        },
        stats: {
          bookings: Number(statsRow?.total_bookings || 0),
          active_bookings: Number(statsRow?.active_bookings || 0),
          earnings: Number(statsRow?.earnings || 0),
          profile_views: 0,
          mastery_hours: masteryHours,
        },
        mastery: {
          ...tier,
          hours: masteryHours,
          intro_discount: tier.id === 'newcomer' ? 80 : 0,
        },
        checklist,
        checklist_complete: checklistComplete,
        checklist_total: checklist.length,
        profile_url: buildProfileUrl(username),
        bookings,
        services,
        activity,
      },
    });
  } catch (err) {
    console.error('Dashboard API error:', err);
    return jsonResponse({ success: false, error: 'Failed to load dashboard' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
