// SA place coordinates for distance sorting from free-text artist locations.

const SA_PLACES = [
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
  { keys: ['south africa', 'za', 'rsa'], lat: -28.4793, lng: 24.6727 },
];

const SA_COUNTRY_TOKENS = new Set(['south africa', 'za', 'rsa']);

export function normalizePlaceText(value) {
  return String(value || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

export function isSouthAfricaCountry(country) {
  return SA_COUNTRY_TOKENS.has(normalizePlaceText(country));
}

export function resolvePlaceCoords(location, country) {
  const hay = normalizePlaceText([location, country].filter(Boolean).join(' '));
  if (!hay) return null;

  let best = null;
  for (const place of SA_PLACES) {
    for (const key of place.keys) {
      if (hay.includes(key) && (!best || key.length > best.key.length)) {
        best = { lat: place.lat, lng: place.lng, key };
      }
    }
  }
  return best ? { lat: best.lat, lng: best.lng } : null;
}

export function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2
    + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function artistDistanceKm(artist, userLat, userLng) {
  if (!Number.isFinite(userLat) || !Number.isFinite(userLng)) return null;
  const coords = resolvePlaceCoords(artist.location, artist.country);
  if (!coords) {
    if (artist.country && !isSouthAfricaCountry(artist.country)) return 12000;
    return null;
  }
  return Math.round(haversineKm(userLat, userLng, coords.lat, coords.lng));
}

export function compareArtistsByDistance(a, b, userLat, userLng) {
  const da = artistDistanceKm(a, userLat, userLng);
  const db = artistDistanceKm(b, userLat, userLng);
  if (da != null && db != null && da !== db) return da - db;
  if (da != null && db == null) return -1;
  if (da == null && db != null) return 1;
  const saA = isSouthAfricaCountry(a.country) || resolvePlaceCoords(a.location, a.country);
  const saB = isSouthAfricaCountry(b.country) || resolvePlaceCoords(b.location, b.country);
  if (saA && !saB) return -1;
  if (!saA && saB) return 1;
  return 0;
}

export function formatDistanceKm(km) {
  if (km == null || !Number.isFinite(km)) return '';
  if (km < 1) return 'Near you';
  if (km < 100) return Math.round(km) + ' km away';
  return Math.round(km) + ' km away';
}
