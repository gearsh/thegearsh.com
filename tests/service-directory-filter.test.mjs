import test from 'node:test';
import assert from 'node:assert/strict';
import filter from '../web/service-directory-filter.js';

const fixtures = [
  { name: 'DJ Myles', category: 'DJ', genreSlug: 'amapiano' },
  { name: 'Photo One', category: 'Photography', genreSlug: 'creative-arts' },
  { name: 'Video One', category: 'Videography', genreSlug: 'creative-arts' },
  { name: 'Singer One', category: 'Singer', genreSlug: 'afropop' },
  { name: 'Producer One', category: 'Music Producer', genreSlug: 'creative-arts' },
  { name: 'Host One', category: 'MC & Host', genreSlug: 'other' },
  { name: 'Fashion One', category: 'Fashion Designer', genreSlug: 'creative-arts' },
];
const expected = {
  djs: ['DJ Myles'],
  photography: ['Photo One'],
  videography: ['Video One'],
  music: ['DJ Myles', 'Singer One', 'Producer One'],
  'mcs-hosts': ['Host One'],
  'more-creative': ['Fashion One'],
};
for (const [service, names] of Object.entries(expected)) {
  test('homepage tile ' + service + ' only shows matching artists', () => {
    assert.equal(filter.isValid(service), true);
    assert.deepEqual(fixtures.filter(c => filter.matches(c, service)).map(c => c.name), names);
  });
}
test('unknown service filter never silently displays unrelated artists', () => {
  assert.equal(filter.isValid('anything'), false);
  assert.equal(filter.matches(fixtures[0], 'anything'), false);
});
test('all and missing service preserve the unfiltered artist directory', () => {
  assert.equal(fixtures.filter(c => filter.matches(c, 'all')).length, fixtures.length);
  assert.equal(fixtures.filter(c => filter.matches(c, undefined)).length, fixtures.length);
});
test('empty categories return no invented artist records', () => {
  assert.deepEqual([{category:'Tattoo Artist'}].filter(c => filter.matches(c, 'photography')), []);
});
