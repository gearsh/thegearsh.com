/**
 * Gearsh location — local-first artist sorting (browser geolocation + Cloudflare geo).
 */
(function (global) {
  'use strict';

  var CACHE_KEY = 'gearsh_loc_v2';
  var position = null;
  var label = '';
  var initPromise = null;

  var CITY_DISPLAY_ALIASES = {
    'makhado': 'Louis Trichardt',
    'louis trichardt': 'Louis Trichardt',
  };

  var SA_PLACES = [
    { keys: ['johannesburg', 'joburg', 'jhb', 'sandton', 'midrand', 'randburg', 'roodepoort'], lat: -26.2041, lng: 28.0473, label: 'Johannesburg' },
    { keys: ['soweto'], lat: -26.2678, lng: 27.8585, label: 'Soweto' },
    { keys: ['tembisa', 'alexandra'], lat: -25.9969, lng: 28.2294, label: 'Tembisa' },
    { keys: ['pretoria', 'tshwane', 'centurion', 'menlyn'], lat: -25.7479, lng: 28.2293, label: 'Pretoria' },
    { keys: ['cape town', 'cpt', 'bellville', 'stellenbosch'], lat: -33.9249, lng: 18.4241, label: 'Cape Town' },
    { keys: ['durban', 'dbn', 'umhlanga', 'pinetown'], lat: -29.8587, lng: 31.0218, label: 'Durban' },
    { keys: ['port elizabeth', 'gqeberha', 'pe'], lat: -33.9608, lng: 25.6022, label: 'Gqeberha' },
    { keys: ['east london'], lat: -33.0153, lng: 27.9116, label: 'East London' },
    { keys: ['bloemfontein', 'mangaung'], lat: -29.0852, lng: 26.1596, label: 'Bloemfontein' },
    { keys: ['polokwane'], lat: -23.9045, lng: 29.4689, label: 'Polokwane' },
    { keys: ['louis trichardt', 'makhado', 'soutpansberg'], lat: -23.0435, lng: 29.9038, label: 'Louis Trichardt' },
    { keys: ['tzaneen'], lat: -23.8335, lng: 30.1635, label: 'Tzaneen' },
    { keys: ['thohoyandou'], lat: -22.9706, lng: 30.4388, label: 'Thohoyandou' },
    { keys: ['musina'], lat: -22.3456, lng: 30.0417, label: 'Musina' },
    { keys: ['limpopo'], lat: -23.9045, lng: 29.4689, label: 'Limpopo' },
    { keys: ['nelspruit', 'mbombela'], lat: -25.4653, lng: 30.9703, label: 'Mbombela' },
    { keys: ['mpumalanga', 'witbank', 'emalahleni'], lat: -25.8728, lng: 29.2332, label: 'Mpumalanga' },
    { keys: ['rustenburg'], lat: -25.6672, lng: 27.2423, label: 'Rustenburg' },
    { keys: ['north west', 'mahikeng'], lat: -25.8654, lng: 25.6444, label: 'Mahikeng' },
    { keys: ['kimberley', 'northern cape'], lat: -28.7282, lng: 24.7499, label: 'Kimberley' },
    { keys: ['pietermaritzburg', 'pmg'], lat: -29.6006, lng: 30.3794, label: 'Pietermaritzburg' },
    { keys: ['george', 'garden route', 'knysna'], lat: -33.9648, lng: 22.4617, label: 'George' },
    { keys: ['gauteng'], lat: -26.2708, lng: 28.1123, label: 'Gauteng' },
    { keys: ['western cape'], lat: -33.2278, lng: 21.8569, label: 'Western Cape' },
    { keys: ['kwazulu-natal', 'kzn'], lat: -28.5306, lng: 30.8958, label: 'KwaZulu-Natal' },
    { keys: ['eastern cape'], lat: -32.2968, lng: 26.4194, label: 'Eastern Cape' },
    { keys: ['free state'], lat: -28.4541, lng: 26.7968, label: 'Free State' },
    { keys: ['south africa', 'za', 'rsa'], lat: -28.4793, lng: 24.6727, label: 'South Africa' },
  ];

  function normalizePlaceText(value) {
    return String(value || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  }

  function titleCaseWords(value) {
    return String(value || '').replace(/\b\w/g, function (c) { return c.toUpperCase(); });
  }

  function normalizeCityLabel(raw) {
    var value = String(raw || '').trim();
    if (!value) return '';
    var key = normalizePlaceText(value);
    if (CITY_DISPLAY_ALIASES[key]) return CITY_DISPLAY_ALIASES[key];
    if (key === 'south africa' || key === 'za' || key === 'rsa') return 'South Africa';
    return titleCaseWords(value);
  }

  function isSouthAfricaCountry(country) {
    var c = normalizePlaceText(country);
    return c === 'south africa' || c === 'za' || c === 'rsa';
  }

  function resolvePlaceCoords(location, country) {
    var hay = normalizePlaceText([location, country].filter(Boolean).join(' '));
    if (!hay) return null;
    var best = null;
    SA_PLACES.forEach(function (place) {
      place.keys.forEach(function (key) {
        if (hay.indexOf(key) !== -1 && (!best || key.length > best.key.length)) {
          best = { lat: place.lat, lng: place.lng, key: key };
        }
      });
    });
    return best ? { lat: best.lat, lng: best.lng } : null;
  }

  function resolveLabelFromCoords(lat, lng) {
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return '';
    var best = null;
    var bestKm = Infinity;
    SA_PLACES.forEach(function (place) {
      var km = haversineKm(lat, lng, place.lat, place.lng);
      if (km < bestKm) {
        bestKm = km;
        best = place;
      }
    });
    if (!best || bestKm > 120) return '';
    return best.label || titleCaseWords(best.keys[0]);
  }

  function haversineKm(lat1, lng1, lat2, lng2) {
    var toRad = function (deg) { return deg * Math.PI / 180; };
    var dLat = toRad(lat2 - lat1);
    var dLng = toRad(lng2 - lng1);
    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
      + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  function readCache() {
    try {
      var raw = sessionStorage.getItem(CACHE_KEY);
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (parsed && Number.isFinite(parsed.lat) && Number.isFinite(parsed.lng)) return parsed;
    } catch (_) {}
    return null;
  }

  function writeCache(data) {
    try {
      sessionStorage.setItem(CACHE_KEY, JSON.stringify(data));
    } catch (_) {}
  }

  function requestBrowserPosition(timeoutMs) {
    return new Promise(function (resolve, reject) {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation unavailable'));
        return;
      }
      var done = false;
      var timer = setTimeout(function () {
        if (done) return;
        done = true;
        reject(new Error('Geolocation timeout'));
      }, timeoutMs || 8000);

      navigator.geolocation.getCurrentPosition(
        function (pos) {
          if (done) return;
          done = true;
          clearTimeout(timer);
          resolve({
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            source: 'browser',
          });
        },
        function () {
          if (done) return;
          done = true;
          clearTimeout(timer);
          reject(new Error('Geolocation denied'));
        },
        { enableHighAccuracy: false, maximumAge: 300000, timeout: timeoutMs || 8000 }
      );
    });
  }

  async function fetchCloudflareGeo() {
    var res = await fetch('/api/geo', { headers: { Accept: 'application/json' } });
    var data = await res.json();
    if (!res.ok || !data.success || !data.data) return null;
    var d = data.data;
    if (!Number.isFinite(d.lat) || !Number.isFinite(d.lng)) return null;
    var cityLabel = normalizeCityLabel(d.city)
      || normalizeCityLabel(d.region)
      || resolveLabelFromCoords(d.lat, d.lng)
      || normalizeCityLabel(d.country);
    return {
      lat: d.lat,
      lng: d.lng,
      label: cityLabel,
      source: 'cloudflare',
    };
  }

  function pickLabelForPosition(lat, lng, cfGeo) {
    var fromCoords = resolveLabelFromCoords(lat, lng);
    if (cfGeo && cfGeo.label) {
      var cfDistance = haversineKm(lat, lng, cfGeo.lat, cfGeo.lng);
      if (cfDistance <= 80) return cfGeo.label;
    }
    return fromCoords || (cfGeo && cfGeo.label) || '';
  }

  async function init() {
    if (position) return position;
    if (initPromise) return initPromise;

    initPromise = (async function () {
      var cached = readCache();
      if (cached) {
        position = { lat: cached.lat, lng: cached.lng };
        label = normalizeCityLabel(cached.label) || resolveLabelFromCoords(cached.lat, cached.lng);
        return position;
      }

      var cfGeo = null;
      try {
        cfGeo = await fetchCloudflareGeo();
      } catch (_) {}

      if (cfGeo) {
        position = { lat: cfGeo.lat, lng: cfGeo.lng };
        label = cfGeo.label || resolveLabelFromCoords(cfGeo.lat, cfGeo.lng);
        writeCache({ lat: position.lat, lng: position.lng, label: label, source: cfGeo.source });
      }

      try {
        var precise = await requestBrowserPosition(6000);
        position = { lat: precise.lat, lng: precise.lng };
        label = pickLabelForPosition(precise.lat, precise.lng, cfGeo);
        writeCache({ lat: position.lat, lng: position.lng, label: label, source: precise.source });
      } catch (_) {}

      if (!label && position) {
        label = resolveLabelFromCoords(position.lat, position.lng);
      }

      return position;
    })();

    return initPromise;
  }

  function hasPosition() {
    return !!(position && Number.isFinite(position.lat) && Number.isFinite(position.lng));
  }

  function locationLabel() {
    return label || '';
  }

  function artistsNearLabel() {
    var place = locationLabel();
    return place ? ('Artists close to ' + place) : 'Browse artists';
  }

  function sortNearLabel() {
    var place = locationLabel();
    return place ? ('Closest to ' + place) : 'Closest first';
  }

  function artistDistanceKm(artist) {
    if (!hasPosition()) return null;
    var coords = resolvePlaceCoords(artist.location, artist.country);
    if (!coords) {
      if (artist.country && !isSouthAfricaCountry(artist.country)) return 12000;
      return null;
    }
    return Math.round(haversineKm(position.lat, position.lng, coords.lat, coords.lng));
  }

  function formatDistanceKm(km) {
    if (km == null || !Number.isFinite(km)) return '';
    var place = locationLabel();
    if (km < 1) return place ? ('In ' + place) : 'Nearby';
    return Math.round(km) + ' km away';
  }

  function enrichCard(card) {
    if (!card) return card;
    var km = artistDistanceKm(card);
    if (km == null) return card;
    card.distance_km = km;
    card.distance_label = formatDistanceKm(km);
    return card;
  }

  function enrichCards(cards) {
    return (cards || []).map(function (card) { return enrichCard(Object.assign({}, card)); });
  }

  function compare(a, b) {
    if (!hasPosition()) return 0;
    var da = artistDistanceKm(a);
    var db = artistDistanceKm(b);
    if (da != null && db != null && da !== db) return da - db;
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    var saA = isSouthAfricaCountry(a.country) || resolvePlaceCoords(a.location, a.country);
    var saB = isSouthAfricaCountry(b.country) || resolvePlaceCoords(b.location, b.country);
    if (saA && !saB) return -1;
    if (!saA && saB) return 1;
    return 0;
  }

  global.GearshLocation = {
    init: init,
    hasPosition: hasPosition,
    locationLabel: locationLabel,
    artistsNearLabel: artistsNearLabel,
    sortNearLabel: sortNearLabel,
    artistDistanceKm: artistDistanceKm,
    formatDistanceKm: formatDistanceKm,
    enrichCard: enrichCard,
    enrichCards: enrichCards,
    compare: compare,
    resolvePlaceCoords: resolvePlaceCoords,
  };
})(typeof window !== 'undefined' ? window : this);
