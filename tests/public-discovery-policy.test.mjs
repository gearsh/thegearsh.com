import test from 'node:test';
import assert from 'node:assert/strict';
import { isPublicDiscoveryCandidate, uniquePublicArtists } from '../functions/api/public-discovery-policy.js';

test('named Revamp QA accounts are excluded from public discovery', () => {
  assert.equal(isPublicDiscoveryCandidate({name:'Revamp Signup Check'}), false);
  assert.equal(isPublicDiscoveryCandidate({name:'  revamp  browser  check '}), false);
});

test('business, founder and legitimate creative accounts are not automatically hidden', () => {
  for (const name of ['Hot pepper carwash', 'Adinkra Media Pty LTD', 'The Gearsh', 'Hvdini Mxgic', 'DJELLE', 'Revamp Browser']) {
    assert.equal(isPublicDiscoveryCandidate({name}), true, name);
  }
});

test('deduplicates repeated artist IDs without collapsing separate user-owned profiles', () => {
  const rows = [
    {artist_id:1,user_id:10,name:'DJELLE'},
    {artist_id:1,user_id:10,name:'DJELLE'},
    {artist_id:2,user_id:10,name:'DJELLE'},
    {artist_id:3,user_id:11,name:'King Retro'},
    {artist_id:4,user_id:12,name:'Revamp Signup Check'},
    {artist_id:5,user_id:13,name:'Hot pepper carwash'},
  ];
  const snapshot = JSON.stringify(rows);
  const visible = uniquePublicArtists(rows);
  assert.deepEqual(visible.map(a=>a.artist_id), [1,2,3,5]);
  assert.equal(JSON.stringify(rows), snapshot);
});

test('does not deduplicate different users based on display name', () => {
  assert.equal(uniquePublicArtists([
    {artist_id:1,user_id:10,name:'DJ Name'},
    {artist_id:2,user_id:11,name:'DJ Name'},
  ]).length, 2);
});
