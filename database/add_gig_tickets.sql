-- Gig ticketing: events, ticket types, orders, instances, promo, waitlist
-- Runtime mirror: functions/api/tickets-schema.js

CREATE TABLE IF NOT EXISTS gig_events (
  id TEXT PRIMARY KEY,
  artist_id TEXT NOT NULL REFERENCES artist_profiles(id) ON DELETE CASCADE,
  author_user_id TEXT NOT NULL REFERENCES users(id),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  venue TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT DEFAULT 'South Africa',
  starts_at TEXT NOT NULL,
  ends_at TEXT,
  timezone TEXT DEFAULT 'Africa/Johannesburg',
  flyer_url TEXT,
  lineup_json TEXT DEFAULT '[]',
  capacity INTEGER DEFAULT 0,
  currency TEXT DEFAULT 'ZAR',
  visibility TEXT DEFAULT 'public' CHECK(visibility IN ('public', 'followers')),
  refund_policy TEXT,
  status TEXT DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'sold_out', 'cancelled', 'completed')),
  sales_start_at TEXT,
  sales_end_at TEXT,
  activity_id TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS gig_ticket_types (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES gig_events(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  tier_kind TEXT DEFAULT 'general' CHECK(tier_kind IN (
    'general', 'early_bird', 'vip', 'table', 'meet_greet', 'addon'
  )),
  description TEXT,
  price REAL NOT NULL,
  currency TEXT DEFAULT 'ZAR',
  quantity_total INTEGER NOT NULL,
  quantity_sold INTEGER DEFAULT 0,
  quantity_reserved INTEGER DEFAULT 0,
  max_per_order INTEGER DEFAULT 10,
  sort_order INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS gig_promo_codes (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES gig_events(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  discount_type TEXT DEFAULT 'percent' CHECK(discount_type IN ('percent', 'fixed')),
  discount_value REAL NOT NULL,
  max_uses INTEGER DEFAULT 0,
  uses_count INTEGER DEFAULT 0,
  valid_from TEXT,
  valid_until TEXT,
  is_active INTEGER DEFAULT 1,
  UNIQUE(event_id, code)
);

CREATE TABLE IF NOT EXISTS ticket_orders (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES gig_events(id),
  buyer_user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT DEFAULT 'pending_payment' CHECK(status IN (
    'pending_payment', 'paid', 'cancelled', 'refunded', 'expired'
  )),
  subtotal REAL NOT NULL,
  discount REAL DEFAULT 0,
  platform_fee REAL DEFAULT 0,
  total REAL NOT NULL,
  currency TEXT DEFAULT 'ZAR',
  promo_code TEXT,
  buyer_name TEXT,
  buyer_email TEXT,
  buyer_phone TEXT,
  expires_at TEXT,
  paid_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ticket_order_items (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES ticket_orders(id) ON DELETE CASCADE,
  ticket_type_id TEXT NOT NULL REFERENCES gig_ticket_types(id),
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  line_total REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS ticket_instances (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES ticket_orders(id),
  order_item_id TEXT NOT NULL REFERENCES ticket_order_items(id),
  event_id TEXT NOT NULL REFERENCES gig_events(id),
  ticket_type_id TEXT NOT NULL REFERENCES gig_ticket_types(id),
  ticket_code TEXT UNIQUE NOT NULL,
  holder_name TEXT,
  holder_email TEXT,
  status TEXT DEFAULT 'valid' CHECK(status IN ('valid', 'used', 'cancelled', 'transferred')),
  qr_payload TEXT NOT NULL,
  checked_in_at TEXT,
  transferred_to TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ticket_payments (
  id TEXT PRIMARY KEY,
  ticket_order_id TEXT NOT NULL REFERENCES ticket_orders(id),
  payfast_payment_id TEXT,
  amount REAL NOT NULL,
  platform_fee REAL DEFAULT 0,
  status TEXT DEFAULT 'pending',
  currency TEXT DEFAULT 'ZAR',
  raw_payload TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS gig_waitlist (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES gig_events(id) ON DELETE CASCADE,
  user_id TEXT,
  email TEXT NOT NULL,
  phone TEXT,
  quantity INTEGER DEFAULT 1,
  notified INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_gig_events_artist ON gig_events(artist_id, starts_at);
CREATE INDEX IF NOT EXISTS idx_gig_events_slug ON gig_events(slug);
CREATE INDEX IF NOT EXISTS idx_gig_events_status ON gig_events(status, starts_at);
CREATE INDEX IF NOT EXISTS idx_gig_ticket_types_event ON gig_ticket_types(event_id);
CREATE INDEX IF NOT EXISTS idx_ticket_orders_buyer ON ticket_orders(buyer_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_orders_event ON ticket_orders(event_id);
CREATE INDEX IF NOT EXISTS idx_ticket_instances_code ON ticket_instances(ticket_code);
CREATE INDEX IF NOT EXISTS idx_ticket_instances_order ON ticket_instances(order_id);
CREATE INDEX IF NOT EXISTS idx_gig_waitlist_event ON gig_waitlist(event_id);
