import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class D1Mock {
  constructor() { this.sqlite = new DatabaseSync(':memory:'); }
  prepare(sql) {
    const statement = this.sqlite.prepare(sql);
    return {
      bind(...values) {
        return {
          first: async () => statement.get(...values) || null,
          run: async () => ({ meta: { changes: statement.run(...values).changes } }),
        };
      },
      run: async () => ({ meta: { changes: statement.run().changes } }),
    };
  }
  async batch(statements) {
    this.sqlite.exec('BEGIN');
    try {
      const results = [];
      for (const statement of statements) results.push(await statement.run());
      this.sqlite.exec('COMMIT');
      return results;
    } catch (error) { this.sqlite.exec('ROLLBACK'); throw error; }
  }
}

for (const directory of ['../web/functions/api', '../functions/api']) {
  test(`password recovery works in ${directory}`, async () => {
    const { onRequestPost: requestReset } = await import(`${directory}/forgot-password.js`);
    const { onRequestPost: validate } = await import(`${directory}/validate-reset-token.js`);
    const { onRequestPost: reset } = await import(`${directory}/reset-password.js`);
    const { ensureAuthTables, verifyPassword } = await import(`${directory}/auth-utils.js`);
    const db = new D1Mock();
    await ensureAuthTables(db);
    db.sqlite.prepare(`INSERT INTO users (id,email,password_hash,user_type,first_name,last_name)
      VALUES ('test','artist@example.invalid','old','artist','Artist','Test')`).run();
    const env = { DB: db, RESEND_API_KEY: 'test-key' };
    const context = (path, body, e = env) => ({
      env: e, request: new Request(`https://website-revamp-v1.thegearsh-com.pages.dev${path}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body)
      })
    });
    const missing = await requestReset(context('/api/forgot-password', { email: 'artist@example.invalid' }, { DB: db }));
    assert.equal(missing.status, 503);

    const sent = [];
    const originalFetch = globalThis.fetch;
    globalThis.fetch = async (_url, options) => { sent.push(JSON.parse(options.body)); return { ok: true, status: 200 }; };
    try {
      const unknown = await requestReset(context('/api/forgot-password', { email: 'unknown@example.invalid' }));
      assert.equal(unknown.status, 200);
      assert.equal(sent.length, 0);
      const result = await requestReset(context('/api/forgot-password', { email: 'artist@example.invalid' }));
      assert.equal(result.status, 200);
      assert.equal(sent.length, 1);
      const link = sent[0].html.match(/https:\/\/[^"<]+/)[0];
      const token = new URL(link).searchParams.get('token');
      assert.equal(new URL(link).pathname, '/reset-password');
      assert.match(token, /^[0-9a-f-]{36}$/);
      const record = db.sqlite.prepare('SELECT token FROM password_resets WHERE email = ?').get('artist@example.invalid');
      assert.notEqual(record.token, token);
      assert.equal(record.token.length, 64);

      const valid = await validate(context('/api/validate-reset-token', { token }));
      assert.equal((await valid.json()).valid, true);
      const changed = await reset(context('/api/reset-password', { token, password: 'NewPassword123' }));
      assert.equal(changed.status, 200);
      const user = db.sqlite.prepare('SELECT password_hash FROM users WHERE id = ?').get('test');
      assert.equal(await verifyPassword('NewPassword123', user.password_hash), true);
      assert.equal((await (await validate(context('/api/validate-reset-token', { token }))).json()).valid, false);
      assert.equal((await reset(context('/api/reset-password', { token, password: 'AgainPassword123' }))).status, 400);

      await requestReset(context('/api/forgot-password', { email: 'artist@example.invalid' }));
      const expiredLink = sent[1].html.match(/https:\/\/[^"<]+/)[0];
      const expiredToken = new URL(expiredLink).searchParams.get('token');
      db.sqlite.prepare('UPDATE password_resets SET expires_at = ? WHERE email = ?').run('2000-01-01T00:00:00.000Z', 'artist@example.invalid');
      assert.equal((await (await validate(context('/api/validate-reset-token', { token: expiredToken }))).json()).valid, false);
    } finally { globalThis.fetch = originalFetch; }
  });
}
