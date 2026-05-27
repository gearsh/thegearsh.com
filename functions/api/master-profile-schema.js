// Runtime D1 schema for Master Profile system

export async function ensureMasterProfileColumns(db) {
  if (!db) return;

  const artistCols = [
    "ALTER TABLE artist_profiles ADD COLUMN profile_type TEXT DEFAULT 'artist'",
    'ALTER TABLE artist_profiles ADD COLUMN tagline TEXT',
    'ALTER TABLE artist_profiles ADD COLUMN cover_image_url TEXT',
    'ALTER TABLE artist_profiles ADD COLUMN long_bio TEXT',
    "ALTER TABLE artist_profiles ADD COLUMN stats_json TEXT DEFAULT '{}'",
    "ALTER TABLE artist_profiles ADD COLUMN testimonials_json TEXT DEFAULT '[]'",
    "ALTER TABLE artist_profiles ADD COLUMN portfolio_projects_json TEXT DEFAULT '[]'",
    "ALTER TABLE artist_profiles ADD COLUMN availability_json TEXT DEFAULT '{}'",
  ];
  for (const sql of artistCols) {
    await db.prepare(sql).run().catch(function () {});
  }

  const serviceCols = [
    "ALTER TABLE services ADD COLUMN deliverables TEXT DEFAULT '[]'",
    'ALTER TABLE services ADD COLUMN delivery_days INTEGER',
    'ALTER TABLE services ADD COLUMN is_featured INTEGER DEFAULT 0',
    'ALTER TABLE services ADD COLUMN sort_order INTEGER DEFAULT 0',
  ];
  for (const sql of serviceCols) {
    await db.prepare(sql).run().catch(function () {});
  }

  const bookingCols = [
    'ALTER TABLE bookings ADD COLUMN project_brief TEXT',
    'ALTER TABLE bookings ADD COLUMN preferred_dates TEXT',
    'ALTER TABLE bookings ADD COLUMN quote_amount REAL',
    'ALTER TABLE bookings ADD COLUMN deposit_amount REAL',
    'ALTER TABLE bookings ADD COLUMN deposit_paid INTEGER DEFAULT 0',
  ];
  for (const sql of bookingCols) {
    await db.prepare(sql).run().catch(function () {});
  }

  await db.prepare(
    'CREATE INDEX IF NOT EXISTS idx_artist_profiles_type ON artist_profiles(profile_type)'
  ).run().catch(function () {});
}

export function isMasterProfile(row) {
  return String(row?.profile_type || '').toLowerCase() === 'master'
    || String(row?.username || '').toLowerCase() === 'gearsh';
}
