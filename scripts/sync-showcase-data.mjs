/**
 * Sync functions/api/sa-showcase-data.js → web/sa-showcase-data.js
 * Keeps homepage/search showcase in lockstep with the API source of truth.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const srcPath = path.join(root, 'functions/api/sa-showcase-data.js');
const destPath = path.join(root, 'web/sa-showcase-data.js');

let src = fs.readFileSync(srcPath, 'utf8');

src = src.replace(
  /^\/\/[^\n]*\n/,
  '// Auto-synced from functions/api/sa-showcase-data.js — run: node scripts/sync-showcase-data.mjs\n'
);

src = src
  .replace(/^export const SA_SHOWCASE_ARTISTS/m, 'const SA_SHOWCASE_ARTISTS')
  .replace(/^export const PRIORITY_SHOWCASE_USERNAMES/m, 'var PRIORITY_SHOWCASE_USERNAMES')
  .replace(/^export const GENRE_FEATURED_ORDER/m, 'var GENRE_FEATURED_ORDER')
  .replace(/^export const GENRE_FEED_CATEGORIES/m, 'var GENRE_FEED_CATEGORIES')
  .replace(/^export const SHOWCASE/m, 'var SHOWCASE')
  .replace(/^export function /gm, 'function ');

fs.writeFileSync(destPath, src);
console.log('Synced showcase data → web/sa-showcase-data.js');
