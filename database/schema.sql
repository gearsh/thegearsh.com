-- Gearsh MVP Database Schema for Cloudflare D1

-- Users table (both artists and clients)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK(user_type IN ('artist', 'client', 'admin')),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  display_name TEXT,
  profile_picture_url TEXT,
  phone TEXT,
  location TEXT,
  country TEXT DEFAULT 'South Africa',
  bio TEXT,
  is_verified INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Artists profile (extends users)
CREATE TABLE IF NOT EXISTS artist_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  genre TEXT,
  base_rate REAL,
  hourly_rate REAL,
  availability_status TEXT DEFAULT 'available',
  years_experience INTEGER,
  portfolio_urls TEXT, -- JSON array
  social_links TEXT, -- JSON object
  skills TEXT, -- JSON array
  is_trending INTEGER DEFAULT 0,
  total_bookings INTEGER DEFAULT 0,
  avg_rating REAL DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Services offered by artists
CREATE TABLE IF NOT EXISTS services (
  id TEXT PRIMARY KEY,
  artist_id TEXT NOT NULL REFERENCES artist_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  duration_hours REAL,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL REFERENCES users(id),
  artist_id TEXT NOT NULL REFERENCES artist_profiles(id),
  service_id TEXT REFERENCES services(id),
  event_date TEXT NOT NULL,
  event_time TEXT,
  event_location TEXT,
  event_type TEXT,
  duration_hours REAL,
  total_price REAL NOT NULL,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'confirmed', 'cancelled', 'completed', 'disputed')),
  notes TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
  id TEXT PRIMARY KEY,
  booking_id TEXT UNIQUE NOT NULL REFERENCES bookings(id),
  reviewer_id TEXT NOT NULL REFERENCES users(id),
  artist_id TEXT NOT NULL REFERENCES artist_profiles(id),
  rating REAL NOT NULL CHECK(rating >= 1 AND rating <= 5),
  comment TEXT,
  is_visible INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL REFERENCES users(id),
  receiver_id TEXT NOT NULL REFERENCES users(id),
  booking_id TEXT REFERENCES bookings(id),
  content TEXT NOT NULL,
  is_read INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);


-- Search index for artists (FTS5)
CREATE VIRTUAL TABLE IF NOT EXISTS artists_search USING fts5(
  user_id,
  display_name,
  bio,
  category,
  genre,
  location,
  skills,
  content='artist_profiles'
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_artist_profiles_category ON artist_profiles(category);
CREATE INDEX IF NOT EXISTS idx_artist_profiles_rating ON artist_profiles(avg_rating);
CREATE INDEX IF NOT EXISTS idx_bookings_client ON bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_artist ON bookings(artist_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_reviews_artist ON reviews(artist_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);

-- Signups table (for user registration before full account activation)
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

