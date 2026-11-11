/**
 * Matches the six homepage booking categories against actual creative profile
 * categories. No guessed service listings and no account/data mutations.
 */
(function(root, factory) {
  var api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.GearshServiceFilter = api;
})(typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : null), function() {
  'use strict';
  var names = {
    djs: 'DJs',
    photography: 'Photography',
    videography: 'Videography',
    music: 'Music',
    'mcs-hosts': 'MCs & Hosts',
    'more-creative': 'More creative work'
  };
  function normal(value) { return String(value || '').toLowerCase().replace(/[_-]+/g, ' ').trim(); }
  function matches(card, service) {
    if (!service || service === 'all') return true;
    if (!names[service] || !card) return false;
    var category = normal(card.category);
    var genre = normal(card.genre);
    var slug = normal(card.genreSlug);
    // Category is the authoritative classification; genre describes music styles
    // and can include irrelevant location text.
    var dj = /\bdj\b|disc jockey|turntablist|selector/.test(category);
    var photo = /photograph|photo studio|portrait photographer/.test(category);
    var video = /videograph|video production|film|cinematograph|video editor|post production/.test(category);
    var host = /\bmc\b|master of ceremon|host|presenter|comedian|public speaker/.test(category);
    var musician = /music|musician|singer|vocal|rapper|\brap\b|hip hop|producer|recording|studio|beatmaker|beat maker|band|gospel|afropop|r&b|afro soul|instrumentalist|songwriter/.test(category);
    var musicGenre = /^(amapiano|hip hop|house|afropop|gospel|xigaza lekompo|maskandi|gqom)$/.test(slug) ||
      /\bamapiano\b|\bhip hop\b|\bgospel\b|\bafropop\b|\bmaskandi\b/.test(genre);
    if (service === 'djs') return dj;
    if (service === 'photography') return photo;
    if (service === 'videography') return video;
    if (service === 'mcs-hosts') return host;
    if (service === 'music') return musician || musicGenre || dj;
    return !(dj || photo || video || host || musician || musicGenre);
  }
  return {
    isValid: function(service) { return Object.prototype.hasOwnProperty.call(names, service); },
    label: function(service) { return names[service] || 'All artists'; },
    matches: matches
  };
});
