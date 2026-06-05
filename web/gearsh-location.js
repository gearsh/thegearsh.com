/**
 * Gearsh location — local-first artist sorting (browser geolocation + Cloudflare geo).
 */
(function (global) {
  'use strict';

  var CACHE_KEY = 'gearsh_loc_v1';
  var position = null;
  var label = '';
  var initPromise = null;

  var SA_PLACES = [
    { keys: ['johannesburg', 'joburg', 'jhb', 'sandton', 'midrand', 'randburg', 'roodepoort'], lat: -26.2041, lng: 28.0473 },
    { keys: ['soweto', 'tembisa', 'alexandra'], lat: -26.2678, lng: 27.8585 },
    { keys: ['pretoria', 'tshwane', 'centurion', 'menlyn'], lat: -25.7479, lng: 28.2293 },
    { keys: ['cape town', 'cpt', 'bellville', 'stellenbosch'], lat: -33.9249, lng: 18.4241 },
    { keys: ['durban', 'dbn', 'umhlanga', 'pinetown'], lat: -29.8587, lng: 31.0218 },
    { keys: ['port elizabeth', 'gqeberha', 'pe'], lat: -33.9608, lng: 25.6022 },
    { keys: ['east london'], lat: -33.0153, lng: 27.9116 },
    { keys: ['bloemfontein', 'mangaung'], lat: -29.0852, lng: 26.1596 },
    { keys: ['polokwane', 'limpopo', 'tzaneen', 'thohoyandou', 'musina'], lat: -23.9045, lng: 29.4689 },
    { keys: ['nelspruit', 'mbombela', 'mpumalanga', 'witbank', 'emalahleni'], lat: -25.4653, lng: 30.9703 },
    { keys: ['rustenburg', 'north west', 'mahikeng'], lat: -25.6672, lng: 27.2423 },
    { keys: ['kimberley', 'northern cape'], lat: -28.7282, lng: 24.7499 },
    { keys: ['pietermaritzburg', 'pmg'], lat: -29.6006, lng: 30.3794 },
    { keys: ['george', 'garden route', 'knysna'], lat: -33.9648, lng: 22.4617 },
    { keys: ['gauteng'], lat: -26.2708, lng: 28.1123 },
    { keys: ['western cape'], lat: -33.2278, lng: 21.8569 },
    { keys: ['kwazulu-natal', 'kzn'], lat: -28.5306, lng: 30.8958 },
    { keys: ['eastern cape'], lat: -32.2968, lng: 26.4194 },
    { keys: ['free state'], lat: -28.4541, lng: 26.7968 },
    { keys: ['south africa', 'za', 'rsa'], lat: -28.4793, lng: 24.6727 }
  ];

  function normalizePlaceText(value) {
    return String(value || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
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
            label: 'Your location',
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
    return {
      lat: d.lat,
      lng: d.lng,
      label: [d.city, d.region].filter(Boolean).join(', ') || d.country || 'Near you',
      source: 'cloudflare',
    };
  }

  async function init() {
    if (position) return position;
    if (initPromise) return initPromise;

    initPromise = (async function () {
      var cached = readCache();
      if (cached) {
        position = { lat: cached.lat, lng: cached.lng };
        label = cached.label || 'Near you';
        return position;
      }

      var cfGeo = null;
      try {
        cfGeo = await fetchCloudflareGeo();
      } catch (_) {}

      if (cfGeo) {
        position = { lat: cfGeo.lat, lng: cfGeo.lng };
        label = cfGeo.label;
        writeCache({ lat: position.lat, lng: position.lng, label: label, source: cfGeo.source });
      }

      try {
        var precise = await requestBrowserPosition(6000);
        position = { lat: precise.lat, lng: precise.lng };
        label = precise.label;
        writeCache({ lat: position.lat, lng: position.lng, label: label, source: precise.source });
      } catch (_) {}

      return position;
    })();

    return initPromise;
  }

  function hasPosition() {
    return !!(position && Number.isFinite(position.lat) && Number.isFinite(position.lng));
  }

  function locationLabel() {
    return label || 'Near you';
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
    if (km < 1) return 'Near you';
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
    artistDistanceKm: artistDistanceKm,
    formatDistanceKm: formatDistanceKm,
    enrichCard: enrichCard,
    enrichCards: enrichCards,
    compare: compare,
    resolvePlaceCoords: resolvePlaceCoords,
  };
})(typeof window !== 'undefined' ? window : this);
