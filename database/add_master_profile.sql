-- Master Profile system: extends artist profiles for premium tech providers
-- Runtime mirror: functions/api/master-profile-schema.js

-- Extend artist_profiles for master profile type
ALTER TABLE artist_profiles ADD COLUMN profile_type TEXT DEFAULT 'artist';
ALTER TABLE artist_profiles ADD COLUMN tagline TEXT;
ALTER TABLE artist_profiles ADD COLUMN cover_image_url TEXT;
ALTER TABLE artist_profiles ADD COLUMN long_bio TEXT;
ALTER TABLE artist_profiles ADD COLUMN stats_json TEXT DEFAULT '{}';
ALTER TABLE artist_profiles ADD COLUMN testimonials_json TEXT DEFAULT '[]';
ALTER TABLE artist_profiles ADD COLUMN portfolio_projects_json TEXT DEFAULT '[]';
ALTER TABLE artist_profiles ADD COLUMN availability_json TEXT DEFAULT '{}';

-- Extend services with deliverables and delivery estimates
ALTER TABLE services ADD COLUMN deliverables TEXT DEFAULT '[]';
ALTER TABLE services ADD COLUMN delivery_days INTEGER;
ALTER TABLE services ADD COLUMN is_featured INTEGER DEFAULT 0;
ALTER TABLE services ADD COLUMN sort_order INTEGER DEFAULT 0;

-- Extend bookings with project brief and quote workflow
ALTER TABLE bookings ADD COLUMN project_brief TEXT;
ALTER TABLE bookings ADD COLUMN preferred_dates TEXT;
ALTER TABLE bookings ADD COLUMN quote_amount REAL;
ALTER TABLE bookings ADD COLUMN deposit_amount REAL;
ALTER TABLE bookings ADD COLUMN deposit_paid INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_artist_profiles_type ON artist_profiles(profile_type);
CREATE INDEX IF NOT EXISTS idx_services_featured ON services(artist_id, is_featured, sort_order);
