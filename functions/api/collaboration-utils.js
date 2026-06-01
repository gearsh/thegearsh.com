// Shared helpers for the artist-to-artist collaboration system.
//
// Collaborations let one artist book another for features, production, songwriting,
// visual art, performances, content, and other creative services. Requests can target
// a registered artist (recipient_id set) or an unclaimed showcase profile
// (recipient_username only) — the latter surfaces to the artist once they claim.

import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';
import { findShowcaseArtist, getBookingFee } from './showcase-profile.js';

export const COLLABORATION_TYPES = [
  { id: 'music_feature', label: 'Music Feature', icon: 'ti-microphone' },
  { id: 'songwriting', label: 'Songwriting', icon: 'ti-pencil' },
  { id: 'production', label: 'Production', icon: 'ti-adjustments' },
  { id: 'visual_art', label: 'Visual Art Commission', icon: 'ti-palette' },
  { id: 'graphic_design', label: 'Graphic Design', icon: 'ti-vector' },
  { id: 'photography', label: 'Photography', icon: 'ti-camera' },
  { id: 'videography', label: 'Videography', icon: 'ti-video' },
  { id: 'dance', label: 'Dance Collaboration', icon: 'ti-yoga' },
  { id: 'event_appearance', label: 'Event Appearance', icon: 'ti-calendar-star' },
  { id: 'content', label: 'Content Collaboration', icon: 'ti-device-tv' },
  { id: 'brand', label: 'Brand Collaboration', icon: 'ti-building-store' },
  { id: 'mentorship', label: 'Mentorship', icon: 'ti-school' },
];

const COLLABORATION_TYPE_IDS = new Set(COLLABORATION_TYPES.map(function (t) { return t.id; }));

export function isValidCollaborationType(value) {
  return COLLABORATION_TYPE_IDS.has(String(value || ''));
}

export const COLLABORATION_STATUSES = [
  'pending', 'reviewing', 'negotiating', 'accepted', 'in_progress', 'completed', 'cancelled', 'declined',
];

export const AVAILABILITY_STATUSES = ['available', 'limited', 'fully_booked'];

export function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

// ---------------------------------------------------------------------------
// Estimated collaboration pricing
// ---------------------------------------------------------------------------

// Derive a tiered estimate from whatever signals we have about an artist. Shown as
// "Estimated Collaboration Fee" until the artist claims and sets real pricing.
export function estimateCollaborationFee(signals) {
  const s = signals || {};
  const hourly = Number(s.hourlyRate || s.hourly_rate || 0);
  const hours = Number(s.masteryHours || s.mastery_hours || 0);
  const bookings = Number(s.totalBookings || s.total_bookings || 0);
  const followers = Number(s.followers || 0);

  let tier;
  if (hourly > 0) {
    if (hourly >= 50000) tier = 'premium';
    else if (hourly >= 10000) tier = 'established';
    else if (hourly >= 2000) tier = 'growing';
    else tier = 'emerging';
  } else {
    let score = 0;
    if (hours >= 7500) score += 4;
    else if (hours >= 3000) score += 3;
    else if (hours >= 800) score += 2;
    else if (hours > 0) score += 1;
    if (bookings >= 50) score += 3;
    else if (bookings >= 15) score += 2;
    else if (bookings >= 3) score += 1;
    if (followers >= 500000) score += 3;
    else if (followers >= 50000) score += 2;
    else if (followers >= 5000) score += 1;

    if (score >= 8) tier = 'premium';
    else if (score >= 5) tier = 'established';
    else if (score >= 2) tier = 'growing';
    else tier = 'emerging';
  }

  const ranges = {
    emerging: { min: 500, max: 2000, label: 'Emerging Artist', custom: false },
    growing: { min: 2000, max: 10000, label: 'Growing Artist', custom: false },
    established: { min: 10000, max: 50000, label: 'Established Artist', custom: false },
    premium: { min: 50000, max: null, label: 'Premium Artist', custom: true },
  };

  const r = ranges[tier];
  return {
    tier: tier,
    tier_label: r.label,
    min: r.min,
    max: r.max,
    custom: r.custom,
    display: r.custom
      ? 'Custom Quote'
      : 'R' + r.min.toLocaleString('en-ZA') + ' – R' + r.max.toLocaleString('en-ZA'),
    estimated: true,
  };
}

// ---------------------------------------------------------------------------
// Schema
// ---------------------------------------------------------------------------

export async function ensureCollaborationTables(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS collaboration_requests (
      id TEXT PRIMARY KEY,
      requester_id TEXT NOT NULL,
      recipient_id TEXT,
      recipient_username TEXT,
      recipient_name TEXT,
      project_name TEXT NOT NULL,
      collaboration_type TEXT NOT NULL,
      budget REAL,
      currency TEXT DEFAULT 'ZAR',
      description TEXT,
      deadline TEXT,
      reference_links TEXT,
      deliverables TEXT,
      status TEXT DEFAULT 'pending',
      agreed_amount REAL,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS collaboration_offers (
      id TEXT PRIMARY KEY,
      request_id TEXT NOT NULL,
      from_id TEXT NOT NULL,
      amount REAL NOT NULL,
      notes TEXT,
      status TEXT DEFAULT 'proposed',
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS collaboration_messages (
      id TEXT PRIMARY KEY,
      collaboration_id TEXT NOT NULL,
      sender_id TEXT NOT NULL,
      receiver_id TEXT,
      message TEXT NOT NULL,
      attachment_url TEXT,
      is_read INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS collaboration_reviews (
      id TEXT PRIMARY KEY,
      collaboration_id TEXT NOT NULL,
      reviewer_id TEXT NOT NULL,
      reviewee_id TEXT NOT NULL,
      rating INTEGER NOT NULL,
      review TEXT,
      would_again INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS collaboration_profiles (
      user_id TEXT PRIMARY KEY,
      available_status TEXT DEFAULT 'available',
      collaboration_fee REAL,
      feature_fee REAL,
      appearance_fee REAL,
      hourly_rate REAL,
      project_rate REAL,
      hide_pricing INTEGER DEFAULT 0,
      quote_only INTEGER DEFAULT 0,
      enabled_types TEXT,
      response_time TEXT,
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_collab_requester ON collaboration_requests(requester_id)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_collab_recipient ON collaboration_requests(recipient_id)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_collab_recipient_username ON collaboration_requests(recipient_username)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_collab_offers_request ON collaboration_offers(request_id)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_collab_messages ON collaboration_messages(collaboration_id)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_collab_reviews ON collaboration_reviews(collaboration_id)`).run();
}

// ---------------------------------------------------------------------------
// Resolution + access helpers
// ---------------------------------------------------------------------------

// Resolve a target artist by username to a user account (if claimed) plus display name.
export async function resolveRecipient(db, username) {
  const handle = String(username || '').trim().toLowerCase();
  if (!handle) return null;

  const user = await db.prepare(`
    SELECT id, display_name, first_name, last_name, username
    FROM users WHERE LOWER(username) = ? AND is_active = 1
  `).bind(handle).first();

  if (user) {
    return {
      recipient_id: user.id,
      recipient_username: user.username || handle,
      recipient_name: user.display_name || [user.first_name, user.last_name].filter(Boolean).join(' ') || handle,
      claimed: true,
    };
  }

  const showcase = findShowcaseArtist(handle);
  if (showcase) {
    return {
      recipient_id: null,
      recipient_username: showcase.username,
      recipient_name: showcase.name,
      claimed: false,
    };
  }

  return null;
}

// Estimate fee for a username from showcase data (used by browse + profile cards).
export function estimateFeeForUsername(username) {
  const showcase = findShowcaseArtist(username);
  if (!showcase) return estimateCollaborationFee({});
  return estimateCollaborationFee({
    hourlyRate: getBookingFee(showcase),
    masteryHours: showcase.masteryHours,
  });
}

export function parseJsonArray(value) {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return String(value).split(',').map(function (s) { return s.trim(); }).filter(Boolean);
  }
}

// Whether the user is a participant (requester or recipient) on a collaboration.
export function userOnCollaboration(collab, userId) {
  if (!collab) return false;
  return collab.requester_id === userId || collab.recipient_id === userId;
}

export { SA_SHOWCASE_ARTISTS };
