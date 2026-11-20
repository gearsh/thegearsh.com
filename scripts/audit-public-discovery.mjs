// Read-only, metadata-only audit of production discovery API responses.
// Run: node scripts/audit-public-discovery.mjs [https://www.thegearsh.com]
// Never dump image data, email, phone, or user IDs in logs.
const origin = (process.argv[2] || 'https://www.thegearsh.com').replace(/\/$/, '');
const targets = [
  'Revamp Signup Check',
  'Revamp Browser Check',
  'Hvdini Mxgic',
  'DJELLE',
  'Adinkra Media Pty LTD',
  'Hot pepper carwash',
  'The Gearsh',
];
const norm = s => String(s || '').trim().toLowerCase().replace(/\s+/g, ' ');
async function get(path) {
  const response = await fetch(origin + path, { headers: { accept: 'application/json', 'cache-control': 'no-cache' } });
  if (!response.ok) throw new Error(path + ' HTTP ' + response.status);
  const json = await response.json();
  if (!json || json.success !== true) throw new Error(path + ' missing success=true');
  return json;
}
const feed = await get('/api/artists/feed');
const categories = feed.data?.categories;
if (!Array.isArray(categories)) throw new Error('Unexpected feed categories shape');
const raw = categories.flatMap(category => (category.artists || []).map(artist => ({
  artist_id: String(artist.artist_id || ''),
  user_id: String(artist.user_id || ''),
  username: String(artist.username || ''),
  name: String(artist.name || ''),
  category: category.id,
})));
const unique = new Map();
for (const item of raw) {
  const key = item.artist_id || item.username || norm(item.name);
  if (key && !unique.has(key)) unique.set(key, item);
}
const list = [];
for (let offset = 0; offset <= 2000; offset += 100) {
  const page = await get('/api/artists?limit=100&offset=' + offset);
  if (!Array.isArray(page.data)) throw new Error('Unexpected artists list shape');
  list.push(...page.data);
  if (page.data.length < 100) break;
  if (offset === 2000) throw new Error('Pagination safety limit reached');
}
const presence = rows => Object.fromEntries(targets.map(name => [
  name, rows.filter(row => norm(row.name || row.artist_name) === norm(name)).length,
]));
const tally = new Map();
for (const a of raw) {
  const key = a.artist_id || a.username || norm(a.name);
  if (key) tally.set(key, (tally.get(key) || 0) + 1);
}
console.log(JSON.stringify({
  origin, checkedAt: new Date().toISOString(),
  categories: categories.map(c => ({ id: c.id, rows: (c.artists || []).length })),
  feedRowsAcrossCategories: raw.length,
  distinctFeedKeys: unique.size,
  repeatedFeedKeysAcrossCategories: [...tally.values()].filter(n => n > 1).length,
  artistListRows: list.length,
  targetPresenceInFeed: presence([...unique.values()]),
  targetPresenceInArtistList: presence(list),
}, null, 2));
