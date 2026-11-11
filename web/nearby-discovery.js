/* Gearsh Discover Nearby — consent-based, city/interest discovery. */
(function () {
  'use strict';
  var root = document.getElementById('gearsh-nearby');
  if (!root || !window.GearshLocation) return;
  var city = document.getElementById('nearby-city');
  var status = document.getElementById('nearby-status');
  var cardsEl = document.getElementById('nearby-cards');
  var gps = document.getElementById('nearby-gps');
  var clear = document.getElementById('nearby-clear');
  var interestsEl = document.getElementById('nearby-interests');
  var places = document.getElementById('nearby-places');
  var topics = ['DJs','Music','Photography','Videography','MCs','Production','Design','Dance'];
  var picked = [];
  try { picked = JSON.parse(localStorage.getItem('gearsh_discovery_interests_v1') || '[]'); } catch (_) {}
  if (!Array.isArray(picked)) picked = [];
  picked = picked.filter(function(x) { return topics.includes(x); });
  function esc(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g,function(s) {
      return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[s];
    });
  }
  function renderInterests() {
    interestsEl.innerHTML = topics.map(function(t) {
      return '<button type="button" class="nearby-chip'+(picked.includes(t)?' selected':'')+'" data-interest="'+esc(t)+'" aria-pressed="'+picked.includes(t)+'">'+esc(t)+'</button>';
    }).join('');
  }
  var tags = {
    DJs:['dj','amapiano','house','deejay'], Music:['music','musician','singer','vocal','band','rapper','hip hop'],
    Photography:['photo','portrait'], Videography:['video','film','cinema'],
    MCs:['mc','host','presenter'], Production:['producer','production','beat','mixing','mastering','recording'],
    Design:['design','graphic','fashion'], Dance:['dance','dancer','choreograph']
  };
  function score(a) {
    var hay = [a.name,a.category,a.genre,a.bio,(a.skills||[]).join(' ')].join(' ').toLowerCase();
    var fit = picked.reduce(function(n,t) { return n + (tags[t]||[]).some(function(term){ return hay.includes(term); }) * 10; }, 0);
    var km = GearshLocation.artistDistanceKm(a);
    // Unknown locations are not assumed to be nearby.
    var locationScore = km == null ? -20 : (km <= 30 ? 30 : km <= 100 ? 20 : km <= 250 ? 10 : 0);
    return {fit:fit,km:km,value:fit+locationScore};
  }
  // Only use a photo supplied by this artist's profile. Avoid unrelated stock
  // imagery or guessing portraits based on names.
  function safeArtistImage(a) {
    var value = String(a && a.image || '').trim();
    if (!value) return '';
    if (/^https:\/\/[^\\s]+$/i.test(value)) return value;
    if (/^\/(?!\/)[^\\s]*$/i.test(value)) return value;
    if (/^(?:assets\/|images\/)[^\\s]*$/i.test(value)) return '/' + value;
    if (/^data:image\/(?:png|jpeg|jpg|webp|gif);base64,[a-z0-9+/=]+$/i.test(value)) return value;
    return '';
  }
  function initials(value) {
    return String(value || 'Creative').trim().split(/\s+/).slice(0,2)
      .map(function(part) { return part.charAt(0).toUpperCase(); }).join('');
  }
  function portrait(a) {
    var name = a.name || a.username || 'Creative';
    var src = safeArtistImage(a);
    var fallback = '<span class="nearby-photo-fallback" aria-hidden="true">' + esc(initials(name)) + '</span>';
    return '<span class="nearby-photo">' +
      (src ? '<img class="nearby-portrait" src="'+esc(src)+'" alt="Portrait of '+esc(name)+'" loading="lazy" decoding="async">' : '') +
      fallback + '</span>';
  }
  function link(a) {
    var user = String(a.username||'').trim();
    return user ? '/creative-profile.html?artist='+encodeURIComponent(user) : '/artists';
  }
  async function renderCards() {
    var label = GearshLocation.locationLabel();
    if (label && label !== 'your area') city.value = label;
    status.textContent = label ? 'Creative listings around '+label+' (approximate city-level proximity).' : 'Choose a city or use your location to discover nearby creatives.';
    if (label) {
      var maps = 'https://www.google.com/maps/search/?api=1&query='+encodeURIComponent('attractions live music arts galleries events in '+label);
      places.href = maps;
      places.textContent = 'Explore attractions and arts around '+label+' on Maps';
      places.hidden = false;
    } else { places.hidden = true; }
    if (!label) { cardsEl.innerHTML = '<p class="nearby-empty">Set a location to see creatives near you. Pick interests to personalise the order.</p>'; return; }
    cardsEl.innerHTML = '<p class="nearby-empty">Finding creative listings…</p>';
    try {
      var response = await fetch('/api/artists/feed', { headers: {Accept:'application/json'} });
      if (!response.ok) throw new Error('Feed unavailable');
      var body = await response.json();
      if (!body.success) throw new Error('Feed unavailable');
      var categories = body.data && body.data.categories || [];
      var unique = new Map();
      categories.forEach(function(group) {
        (group.artists || []).forEach(function(a) {
          var key = String(a.artist_id || a.username || '').toLowerCase();
          if (key && !unique.has(key)) unique.set(key,a);
        });
      });
      var rows = Array.from(unique.values()).map(function(a) { return {artist:a,match:score(a)}; });
      // Prioritise selected interests, then proximity. Only display records with usable city locations.
      rows = rows.filter(function(x){return x.match.km !== null && x.match.km <= 250;})
        .sort(function(a,b) { return b.match.value-a.match.value || a.match.km-b.match.km; })
        .slice(0,6);
      if (!rows.length) {
        cardsEl.innerHTML = '<p class="nearby-empty">No listed creatives found within approximately 250 km yet. <a href="/artists">Browse all creatives</a> while Gearsh grows in this area.</p>';
        return;
      }
      cardsEl.innerHTML = rows.map(function(x) {
        var a=x.artist, place=a.location || a.country || 'Location not listed';
        var category=a.category || a.genre || 'Creative';
        return '<a class="nearby-card" href="'+esc(link(a))+'">'+portrait(a)+'<span class="nearby-card-body"><span class="nearby-category">'+esc(category)+'</span><strong>'+esc(a.name||a.username||'Creative')+'</strong><span class="nearby-card-location">'+esc(place)+' · ~'+Math.round(x.match.km)+' km from selected area</span><small>View creative profile →</small></span></a>';
      }).join('');
    } catch (_) {
      cardsEl.innerHTML = '<p class="nearby-empty">Local listings are temporarily unavailable. <a href="/artists">Browse all creatives</a>.</p>';
    }
  }
  cardsEl.addEventListener('error', function(event) {
    var img = event.target;
    if (!img || !img.classList || !img.classList.contains('nearby-portrait')) return;
    // A broken profile-photo URL must not leave an empty or broken image.
    img.remove();
  }, true);
  interestsEl.addEventListener('click',function(e) {
    var button=e.target.closest('[data-interest]');
    if (!button) return;
    var value=button.getAttribute('data-interest');
    picked=picked.includes(value)?picked.filter(function(x){return x!==value;}):picked.concat(value);
    try {localStorage.setItem('gearsh_discovery_interests_v1',JSON.stringify(picked));} catch (_) {}
    renderInterests(); renderCards();
  });
  gps.addEventListener('click', async function() {
    gps.disabled=true; gps.textContent='Locating…';
    try {
      await GearshLocation.requestPreciseLocation();
      renderCards();
    } catch (_) {
      status.textContent='Location access unavailable or declined. Select your city instead.';
    } finally { gps.disabled=false; gps.textContent='Use my location'; }
  });
  city.addEventListener('change',function() {
    if (!GearshLocation.setCity(city.value)) status.textContent='Choose a city from the available suggestions.';
    else renderCards();
  });
  clear.addEventListener('click',function() {
    GearshLocation.clearLocation();
    city.value='';
    renderCards();
  });
  window.addEventListener('gearsh:location-updated',renderCards);
  renderInterests();
  GearshLocation.initFast().then(renderCards).catch(renderCards);
})();