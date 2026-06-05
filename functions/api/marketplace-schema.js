// Runtime D1 schema for Creative Services Marketplace

export async function ensureMarketplaceColumns(db) {
  if (!db) return;

  const serviceCols = [
    "ALTER TABLE services ADD COLUMN marketplace_category TEXT",
    "ALTER TABLE services ADD COLUMN price_type TEXT DEFAULT 'fixed'",
    "ALTER TABLE services ADD COLUMN slug TEXT",
    "ALTER TABLE services ADD COLUMN media_json TEXT DEFAULT '[]'",
    "ALTER TABLE services ADD COLUMN search_keywords TEXT",
  ];

  for (const sql of serviceCols) {
    await db.prepare(sql).run().catch(function () {});
  }

  await db.prepare(
    'CREATE INDEX IF NOT EXISTS idx_services_marketplace ON services(marketplace_category, is_active)'
  ).run().catch(function () {});
}

export function slugifyService(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}
