import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { DatabaseSync } from 'node:sqlite';
import { onRequestPost as signup } from '../functions/api/signup.js';
import { onRequestPost as login } from '../functions/api/login.js';

function harness(response) {
  let submit, destination;
  const values = { 'first-name': 'Gearsh', 'last-name': 'Awards Demo', email: 'DEMO@example.invalid', password: 'test-password-123', 'confirm-password': 'test-password-123' };
  const fields = Object.fromEntries(Object.entries(values).map(([id, value]) => [id, { value, focus() {} }]));
  fields['client-signup-form'] = { reportValidity: () => true, addEventListener: (_, callback) => { submit = callback; } };
  fields['signup-btn'] = { disabled: false };
  fields['signup-error'] = { style: {} };
  const storage = new Map([['gearsh_artist_id', 'old-artist']]);
  const calls = [];
  vm.runInNewContext(readFileSync(new URL('../web/client-signup.js', import.meta.url), 'utf8'), {
    document: { getElementById: id => fields[id] },
    fetch: async (url, options) => { calls.push({url, body: JSON.parse(options.body)}); return response; },
    GearshAuth: { clearSession: () => storage.clear(), setRemember() {} },
    localStorage: { setItem: (k, v) => storage.set(k, v) },
    window: { location: { replace: value => { destination = value; } } }
  });
  return { fields, calls, storage, submit: () => submit({preventDefault() {}}), destination: () => destination };
}
test('client signup stores the session, clears artist state and opens talent search', async () => {
  const h = harness({ok: true, json: async () => ({success: true, data: {token: 'test-token', user_id: 'client-1', display_name: 'Gearsh Awards Demo'}})});
  await h.submit();
  assert.equal(h.calls[0].url, '/api/signup');
  assert.equal(h.calls[0].body.user_type, 'client');
  assert.equal(h.calls[0].body.email, 'demo@example.invalid');
  assert.equal(h.storage.get('gearsh_user_type'), 'client');
  assert.equal(h.storage.has('gearsh_artist_id'), false);
  assert.equal(h.destination(), '/search');
});
test('mismatched passwords do not submit', async () => {
  const h = harness(); h.fields['confirm-password'].value = 'different';
  await h.submit(); assert.equal(h.calls.length, 0);
  assert.match(h.fields['signup-error'].textContent, /do not match/);
});
test('duplicate email error stays visible and allows retry', async () => {
  const h = harness({ok: false, json: async () => ({success: false, error: 'This email is already registered. Please sign in.'})});
  await h.submit(); assert.match(h.fields['signup-error'].textContent, /already registered/);
  assert.equal(h.fields['signup-btn'].disabled, false); assert.equal(h.destination(), undefined);
});
test('non-JSON service error is explained', async () => {
  const h = harness({ok: false, json: async () => { throw new Error('invalid JSON'); }});
  await h.submit(); assert.match(h.fields['signup-error'].textContent, /temporarily unavailable/);
});
test('client can register and sign back in without an artist profile', async () => {
  const sqlite = new DatabaseSync(':memory:');
  const db = { prepare(sql) {
    const run = (values = []) => ({meta: {changes: sqlite.prepare(sql).run(...values).changes}});
    return {run: async () => run(), bind(...values) { return {run: async () => run(values), first: async () => sqlite.prepare(sql).get(...values) || null, all: async () => ({results: sqlite.prepare(sql).all(...values)})}; }};
  }};
  const env = {DB: db, JWT_SECRET: 'test-only-secret-for-client-signup-test'};
  const context = body => ({env, request: new Request('https://example.invalid/api/signup', {method: 'POST', body: JSON.stringify(body)})});
  const details = {first_name: 'Gearsh', last_name: 'Awards Demo', email: 'demo@example.invalid', password: 'test-password-123', user_type: 'client'};
  try {
    const registered = await signup(context(details));
    const result = await registered.json();
    assert.equal(registered.status, 201, JSON.stringify(result));
    assert.equal(result.data.user_type, 'client'); assert.equal(result.data.artist_id, null);
    assert.equal(sqlite.prepare("SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name='artist_profiles'").get().n, 0);
    const duplicate = await signup(context(details)); assert.equal(duplicate.status, 409);
    const signedIn = await login(context({identifier: details.email, password: details.password}));
    const session = await signedIn.json();
    assert.equal(signedIn.status, 200, JSON.stringify(session));
    assert.equal(session.data.user_type, 'client'); assert.ok(session.data.token);
  } finally { sqlite.close(); }
});
