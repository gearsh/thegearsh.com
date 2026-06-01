// GET /api/collaborators?q=&type=&limit= — artists available for collaboration,
// with estimated fees and curated sections for the hub + homepage.

import { corsPreflightResponse, jsonResponse } from './auth-utils.js';
import { resolveShowcaseImage, getBookingFee } from './showcase-profile.js';
import {
  SA_SHOWCASE_ARTISTS,
  estimateCollaborationFee,
} from './collaboration-utils.js';

function toCard(artist) {
  const fee = estimateCollaborationFee({
    hourlyRate: getBookingFee(artist),
    masteryHours: artist.masteryHours,
  });
  return {
    name: artist.name,
    username: artist.username,
    image: resolveShowcaseImage(artist) || artist.image || 'assets/images/artists/artists.png',
    category: artist.category,
    genre: artist.genre,
    location: artist.location,
    country: artist.country,
    mastery_hours: artist.masteryHours || 0,
    badge: artist.badge,
    estimated_fee: fee,
    availability: 'available',
    profile_url: '/book/' + encodeURIComponent(artist.username),
  };
}

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const q = String(url.searchParams.get('q') || '').trim().toLowerCase();
    const type = String(url.searchParams.get('type') || '').trim().toLowerCase();
    const limit = Math.min(Number(url.searchParams.get('limit') || 60), 120);

    let pool = SA_SHOWCASE_ARTISTS.slice();

    if (q) {
      pool = pool.filter(function (a) {
        return (
          String(a.name || '').toLowerCase().includes(q) ||
          String(a.username || '').toLowerCase().includes(q) ||
          String(a.genre || '').toLowerCase().includes(q) ||
          String(a.category || '').toLowerCase().includes(q) ||
          String(a.location || '').toLowerCase().includes(q)
        );
      });
    }

    if (type) {
      // Loose match collaboration type → artist category/genre keywords.
      const map = {
        music_feature: ['dj', 'amapiano', 'house', 'gospel', 'hip', 'afro', 'vocal', 'rnb', 'soul', 'kwaito', 'maskandi', 'jazz', 'lekompo'],
        production: ['producer', 'production', 'beat', 'dj'],
        songwriting: ['songwriter', 'vocal', 'gospel', 'soul'],
        event_appearance: ['dj', 'live', 'performance', 'band'],
        dance: ['dance', 'choreo'],
        photography: ['photo', 'visual'],
        videography: ['video', 'film', 'content'],
        graphic_design: ['design', 'graphic', 'visual'],
        visual_art: ['art', 'visual', 'paint'],
        content: ['content', 'creator', 'video'],
        brand: ['brand', 'influenc'],
        mentorship: [],
      };
      const keywords = map[type] || [];
      if (keywords.length) {
        pool = pool.filter(function (a) {
          const hay = (String(a.category || '') + ' ' + String(a.genre || '') + ' ' + (a.skills || []).join(' ')).toLowerCase();
          return keywords.some(function (k) { return hay.includes(k); });
        });
      }
    }

    const cards = pool.slice(0, limit).map(toCard);

    const byHours = SA_SHOWCASE_ARTISTS.slice().sort(function (a, b) {
      return (b.masteryHours || 0) - (a.masteryHours || 0);
    });

    const sections = {
      trending: byHours.filter(function (a) { return a.large || a.badge === 'Legend' || a.badge === 'Expert'; }).slice(0, 8).map(toCard),
      most_booked: byHours.slice(0, 8).map(toCard),
      recently_available: SA_SHOWCASE_ARTISTS.filter(function (a) {
        return a.badge === 'Listed' || a.badge === 'Rising' || a.badgeClass === 'fb-new';
      }).slice(0, 8).map(toCard),
    };

    return jsonResponse({
      success: true,
      data: {
        artists: cards,
        total: pool.length,
        sections: sections,
      },
    });
  } catch (err) {
    console.error('Collaborators browse error:', err);
    return jsonResponse({ success: false, error: 'Failed to load collaborators' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
