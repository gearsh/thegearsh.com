/**
 * Client-side marketplace category shortcuts (mirrors API taxonomy).
 */
(function (global) {
  'use strict';

  var FEATURED = [
    { id: 'recording-studios', title: 'Recording', icon: 'ti ti-microphone-2', placeholder: 'Find a studio session' },
    { id: 'beat-makers', title: 'Beat Production', icon: 'ti ti-wave-sine', placeholder: 'Find a beat' },
    { id: 'mixing-engineers', title: 'Mixing', icon: 'ti ti-adjustments-horizontal', placeholder: 'Find mixing' },
    { id: 'mastering-engineers', title: 'Mastering', icon: 'ti ti-volume', placeholder: 'Find mastering' },
    { id: 'feature-artists', title: 'Collaborations', icon: 'ti ti-star', placeholder: 'Find a feature verse' },
    { id: 'vocal-coaching', title: 'Lessons', icon: 'ti ti-school', placeholder: 'Find a lesson' },
    { id: 'photographers', title: 'Photography', icon: 'ti ti-camera', placeholder: 'Find a photographer' },
    { id: 'videographers', title: 'Videography', icon: 'ti ti-video', placeholder: 'Find a videographer' },
  ];

  var HERO_PLACEHOLDERS = [
    'Find a beat',
    'Find a feature verse',
    'Find a producer',
    'Find mixing under R500',
    'Find a vocal coach',
    'Find a photographer',
    'Find mastering',
    'Find a recording session',
  ];

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function categorySearchUrl(categoryId, query) {
    var url = '/search?marketplace=' + encodeURIComponent(categoryId);
    if (query) url += '&q=' + encodeURIComponent(query);
    return url;
  }

  global.GearshMarketplace = {
    FEATURED: FEATURED,
    HERO_PLACEHOLDERS: HERO_PLACEHOLDERS,
    escapeHtml: escapeHtml,
    categorySearchUrl: categorySearchUrl,
  };
})(typeof window !== 'undefined' ? window : this);
