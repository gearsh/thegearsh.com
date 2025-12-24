-- Migration: Add signups and password_resets tables
-- Run this with: wrangler d1 execute gearsh_db --file="database/add_signups_table.sql" --remote

-- Signups table (for user registration)
CREATE TABLE IF NOT EXISTS signups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_name TEXT,
  first_name TEXT NOT NULL,
  surname TEXT,
  email TEXT UNIQUE NOT NULL,
  contact_number TEXT,
  user_type TEXT DEFAULT 'fan',
  country TEXT DEFAULT 'South Africa',
  location TEXT,
  skill_set TEXT,
  date_of_birth TEXT,
  gender TEXT,
  password_hash TEXT,
  created_date TEXT DEFAULT (datetime('now')),
  is_verified INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_signups_email ON signups(email);

-- Password resets table
CREATE TABLE IF NOT EXISTS password_resets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  token TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

