// filepath: functions/signup-worker/scripts/fix-detect-libc.js
// Ensures detect-libc index.d.ts exports are initialized to string literals.
// Run automatically as a postinstall script to make the fix persistent.

const fs = require('fs');
const path = require('path');

function patchDetectLibc(baseDir) {
  const target = path.join(baseDir, 'node_modules', 'detect-libc', 'index.d.ts');
  if (!fs.existsSync(target)) {
    console.log('[fix-detect-libc] detect-libc not found at', target);
    return;
  }

  let src = fs.readFileSync(target, 'utf8');
  const before = src;

  src = src.replace(/export\s+const\s+GLIBC\s*:\s*['\"]glibc['\"];?/g, "export const GLIBC = 'glibc';");
  src = src.replace(/export\s+const\s+MUSL\s*:\s*['\"]musl['\"];?/g, "export const MUSL = 'musl';");

  if (src !== before) {
    fs.writeFileSync(target, src, 'utf8');
    console.log('[fix-detect-libc] Patched', target);
  } else {
    console.log('[fix-detect-libc] No changes needed for', target);
  }
}

// Try to patch from the script location (functions/signup-worker/scripts)
const repoRoot = path.resolve(__dirname, '..');
patchDetectLibc(repoRoot);

// Also try current working directory as a fallback (useful if npm runs from project root)
patchDetectLibc(process.cwd());

console.log('[fix-detect-libc] Done.');

