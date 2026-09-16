(function () {
  'use strict';

  function findArtist(slug) {
    var list = typeof SA_SHOWCASE_ARTISTS !== 'undefined' ? SA_SHOWCASE_ARTISTS : [];
    var key = String(slug || '').trim().toLowerCase();
    return list.find(function (item) {
      return String(item.username || '').toLowerCase() === key;
    }) || null;
  }

  function toProfile(item) {
    return {
      artist_id: 'showcase-' + String(item.username || item.name).toLowerCase(),
      username: item.username,
      name: item.name,
      image: item.image,
      bio: item.bio,
      location: item.location,
      country: item.country,
      category: item.category,
      genre: item.genre,
      skills: item.skills || [],
      portfolio_urls: item.portfolio_urls || [],
      services: (item.bookingServices || []).map(function (service, index) {
        return {
          id: 'showcase-' + String(item.username || item.name).toLowerCase() + '-' + index,
          name: service.name,
          description: service.description || '',
          price: Number(service.price || 0),
          duration_hours: service.duration_hours
        };
      }),
      is_verified: false,
      is_claimable: true,
      is_demo: true,
      claim_url: 'claim-profile.html?artist=' + encodeURIComponent(String(item.username || '').toLowerCase()),
      availability_status: 'available'
    };
  }

  function boot() {
    if (typeof SA_SHOWCASE_ARTISTS === 'undefined') return;
    var params = new URLSearchParams(window.location.search);
    var slug = params.get('artist') || params.get('username');
    if (!slug) return;
    var item = findArtist(slug);
    if (!item || typeof renderProfile !== 'function') return;

    var error = document.getElementById('error');
    var content = document.getElementById('content');
    if (!content) return;

    renderProfile(toProfile(item));
    if (error) error.style.display = 'none';
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { setTimeout(boot, 0); });
  } else {
    setTimeout(boot, 0);
  }
})();
