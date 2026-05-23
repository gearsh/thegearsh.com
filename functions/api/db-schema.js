// Runtime D1 schema helpers for marketplace tables

export async function ensureMarketplaceTables(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS payments (
      id TEXT PRIMARY KEY,
      booking_id TEXT NOT NULL REFERENCES bookings(id),
      payfast_payment_id TEXT,
      amount REAL NOT NULL,
      platform_fee REAL DEFAULT 0,
      status TEXT DEFAULT 'pending'
        CHECK(status IN ('pending', 'complete', 'failed', 'refunded', 'cancelled')),
      currency TEXT DEFAULT 'ZAR',
      raw_payload TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS escrow_ledger (
      id TEXT PRIMARY KEY,
      booking_id TEXT NOT NULL REFERENCES bookings(id),
      payment_id TEXT REFERENCES payments(id),
      event_type TEXT NOT NULL
        CHECK(event_type IN ('hold', 'release', 'refund', 'partial_refund')),
      amount REAL NOT NULL,
      note TEXT,
      created_by TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS disputes (
      id TEXT PRIMARY KEY,
      booking_id TEXT NOT NULL REFERENCES bookings(id),
      reporter_id TEXT NOT NULL REFERENCES users(id),
      subject TEXT NOT NULL,
      description TEXT,
      severity TEXT DEFAULT 'medium'
        CHECK(severity IN ('low', 'medium', 'high', 'critical')),
      status TEXT DEFAULT 'open'
        CHECK(status IN ('open', 'investigating', 'resolved', 'closed')),
      resolution_notes TEXT,
      assigned_to TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_escrow_booking ON escrow_ledger(booking_id);
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_disputes_booking ON disputes(booking_id);
  `).run();
  await db.prepare(`
    CREATE INDEX IF NOT EXISTS idx_messages_booking ON messages(booking_id);
  `).run();
}
