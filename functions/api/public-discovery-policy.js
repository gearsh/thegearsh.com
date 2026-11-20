// Public discovery visibility is independent of account ownership or booking history.
// These are explicit test display names observed in the November 2026 discovery audit.
// Do not infer "test" from a person's category, missing photo, or unusual name.
const TEST_DISPLAY_NAMES = new Set([
  'revamp signup check',
  'revamp browser check',
]);

function normalized(value) {
  return String(value || '').trim().toLowerCase().replace(/\s+/g, ' ');
}

export function isPublicDiscoveryCandidate(artist) {
  if (!artist) return false;
  // This safeguard is deliberately narrow. Legitimate business creatives and
  // similarly named performers must not be removed by a broad keyword rule.
  return !TEST_DISPLAY_NAMES.has(normalized(artist.name));
}

export function uniquePublicArtists(artists) {
  const seenArtists = new Set();
  return (artists || []).filter(function (artist) {
    if (!isPublicDiscoveryCandidate(artist)) return false;
    const artistId = String(artist.artist_id || '').trim();
    if (artistId && seenArtists.has(artistId)) return false;
    if (artistId) seenArtists.add(artistId);
    return true;
  });
}
