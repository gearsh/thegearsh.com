// Browser-level verification of the actual production CSS cascade.
// Run after Cloudflare's deploy completes; fail rather than claiming success
// when visitors still see a dark, transparent or unstyled header.
import { chromium } from 'playwright';

const url = process.env.HEADER_CHECK_URL || 'https://thegearsh.com/';
const expected = 'rgb(0, 191, 255)';
const white = 'rgb(255, 255, 255)';
const retries = 3;
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const chromePath = process.env.CHROME_BIN;
if (!chromePath) throw new Error('CHROME_BIN not set; use the preinstalled system Chrome on GitHub runners');
const browser = await chromium.launch({ headless: true, executablePath: chromePath, args: ['--no-sandbox'] });
let lastFailure = null;
let verified = false;
try {
  for (let attempt = 1; attempt <= retries; attempt++) {
    let failures = [];
    for (const viewport of [{width: 1440, height: 900}, {width: 390, height: 844}]) {
      const context = await browser.newContext({ viewport, ignoreHTTPSErrors: false });
      const page = await context.newPage();
      try {
        // Unique URL avoids HTML/CDN cache hits; context clears browser caches.
        const address = new URL(url);
        address.searchParams.set('verify_header', process.env.GITHUB_SHA?.slice(0, 8) || Date.now().toString());
        address.searchParams.set('attempt', String(attempt));
        const response = await page.goto(address.toString(), { waitUntil: 'domcontentloaded', timeout: 16000 });
        if (!response || !response.ok()) throw new Error('Homepage HTTP ' + (response?.status() ?? 'missing'));
        await page.locator('.gh-header').waitFor({ state: 'visible', timeout: 9000 });
        const result = await page.evaluate(() => {
          const header = document.querySelector('.gh-header');
          const book = document.getElementById('gh-book');
          const brand = document.querySelector('.gh-brand');
          const menu = header?.querySelector('.gh-row > .gh-icon');
          const color = el => el ? getComputedStyle(el).color : 'MISSING';
          const bg = el => el ? getComputedStyle(el).backgroundColor : 'MISSING';
          const styleLinks = [...document.querySelectorAll('link[rel="stylesheet"]')]
            .map(el => el.href).filter(src => src.includes('site-header.css'));
          const scriptSrcs = [...document.querySelectorAll('script[src]')]
            .map(el => el.src).filter(src => src.includes('site-header.js'));
          return {
            page: location.href, headerBackground: bg(header), headerText: color(header),
            brand: color(brand), menu: color(menu), bookText: color(book),
            bookBackground: bg(book), bookPresent: Boolean(book),
            scriptSrcs, styleLinks,
          };
        });
        console.log(JSON.stringify({ attempt, viewport: viewport.width, ...result }));
        if (result.headerBackground !== expected) failures.push(viewport.width + ': header=' + result.headerBackground);
        if (result.bookBackground !== expected) failures.push(viewport.width + ': Book background=' + result.bookBackground);
        if (result.brand !== white) failures.push(viewport.width + ': brand text=' + result.brand);
        if (result.bookText !== white) failures.push(viewport.width + ': Book text=' + result.bookText);
        if (result.menu !== white) failures.push(viewport.width + ': menu icon=' + result.menu);
        if (!result.scriptSrcs.length || !result.styleLinks.length) failures.push(viewport.width + ': shared header assets missing');
      } catch (error) {
        failures.push(viewport.width + ': ' + error.message);
      } finally {
        await context.close();
      }
    }
    if (!failures.length) {
      console.log('PASS: production header and Book button match DeepSkyBlue/white at desktop and mobile widths.');
      verified = true;
      break;
    }
    lastFailure = failures.join('; ');
    console.error('Attempt ' + attempt + ' failed: ' + lastFailure);
    if (attempt < retries) await sleep(12000);
  }
  if (!verified) {
    // Assigning 1 only when the loop did not break on a passing attempt.
    process.exitCode = 1;
  }
} finally {
  await browser.close();
}
