# Gearsh — World‑Class Site Audit & Hardening

Date: 2026‑05‑27
Scope: production source under `web/` (HTML/JS/CSS), `functions/api/` (Cloudflare Pages Functions), `web/functions/api/` (deploy overrides), `_redirects`, `wrangler.toml`, GitHub Actions deploy. Build output (`build/web/`) is generated and was excluded.

This document records what was audited, what was fixed in this pass, and what is recommended for follow‑up.

---

## 1. Critical — Authentication, Authorization, Injection (FIXED)

| # | Endpoint / Area | Issue | Fix |
|---|---|---|---|
| 1 | `GET /api/users` (`functions/api/users.js`) | Listed all user emails with **no auth check**; mentioned admin-only in a comment only. | Now requires `x-founder-key` matching `FOUNDER_ACCESS_KEY` (constant‑time compare). |
| 2 | `GET /api/users` query | **SQL injection** via `` `AND user_type = '${userType}'` `` in count query. | Replaced with parameterized bind + allow‑list of valid `user_type` values, `limit`/`offset` are clamped. |
| 3 | `GET /api/users/:id` | No auth at all on a specific user. | Now requires either matching Bearer token (`userId === requesterId`) or founder key. |
| 4 | `POST /api/upload-profile-photo` | Accepted `firebase_uid` from body, bypassing auth → IDOR (overwrite any user's photo). | Body cannot supply identity. Bearer token is the only identity source. Added MIME allow‑list (`jpeg/png/webp`), 3 MB size cap, base64 sanity check. |
| 5 | `POST /api/update-profile` (deploy override) | Checked Bearer header **existed** but never parsed/verified it; trusted `firebase_uid` from body. | Bearer is parsed via the shared JWT verifier, `firebase_uid` removed entirely — identity comes from the token. `user_type` is allow‑listed. |
| 6 | `POST /api/firebase-sync` (deploy override) | Same — accepted any Bearer; trusted body `firebase_uid` / `email`. | Now performs **real Firebase RS256 token verification** (cached JWKS, audience/issuer checks). Refuses to run unless `FIREBASE_PROJECT_ID` is set. |
| 7 | `POST /api/social-auth` (deploy override) | Trusted `email` + `provider` posted from any client (explicit TODO). Allowed account takeover. | Now **requires** a real Google or Apple ID token. Google is verified via Google's tokeninfo + `aud` check, Apple via RS256 signature against `appleid.apple.com/auth/keys` + audience check. Refuses to run for Apple unless `APPLE_OAUTH_AUDIENCE` is set. |
| 8 | `auth-utils.js` JWT secret | Hardcoded fallback `'gearsh-dev-secret-change-in-production'`; legacy unsigned base64 tokens still accepted forever. | JWT secret is now required to be ≥16 chars when `NODE_ENV=production` or `ENVIRONMENT=production`; otherwise the worker throws. Legacy unsigned tokens are rejected unless `ALLOW_LEGACY_TOKENS=true` (migration window only). Legacy SHA‑256 comparison made constant time. |
| 9 | `GET /api/get_signups` (deploy override) | Returned the entire artist signup table when `SIGNUPS_API_KEY` env var was unset. | Always requires either `x-founder-key` or `x-api-key` (constant‑time compare). No silent fallback. |
| 10 | `POST /api/reviews` | No auth, no booking ownership check, no completion check — anyone could spam reviews. | Now requires Bearer token; `reviewer_id` is taken from the token. Verifies `booking.client_id === reviewer`, `booking.status === 'completed'`, and that `artist_id` matches the booking. Rating parsed as a number, comment truncated to 2 000 chars. |

---

## 2. High — Information Disclosure, State on GET, Headers (FIXED)

| # | Area | Issue | Fix |
|---|---|---|---|
| 11 | `GET /api/health` | Surfaced raw DB error message in body. | Returns only `'connected' \| 'error'`; no exception message. |
| 12 | `POST /api/signup` | Logged full request body, raw email, and `debug`/`details` with the underlying exception message. | All `console.log` of secrets/PII removed; `debug`/`details` fields stripped from error responses. |
| 13 | `POST /api/forgot-password` | Logged the live reset URL (with token) when `RESEND_API_KEY` was unset. | Logs a generic warning only. |
| 14 | `functions/api/onboarding-utils.js` | Logged email and phone OTPs in plaintext when Resend was not configured. | Email codes are no longer logged; phone `demo_code` is only returned in the API response when **not** running in production. |
| 15 | `web/functions/api/social-auth.js`, `update-profile.js`, `firebase-sync.js` | Returned `debug: err.message` / `details: err.message` to clients. | All such fields removed; clients only see a generic message. |
| 16 | `GET /api/artists/feed` | Seeded up to 15 showcase artists on every read (state change on GET, repeated DB writes under traffic). | Seeding now runs at most once per hour per worker instance and is fired through `context.waitUntil` so it never blocks the response. |
| 17 | `GET /api/artists/[id]` | Auto‑seeded an artist row every time, even when one already existed. | Seeding only runs when `resolveArtistProfile` returns nothing (first miss), then the row exists for subsequent requests. |
| 18 | Site‑wide security headers | No `_headers` file — no CSP family, no `X‑Frame‑Options`, no `Referrer‑Policy`, no `Permissions‑Policy`, no HSTS. | New `web/_headers` deploys: `X-Content-Type-Options`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (camera/mic off, geo/payment self only, FLoC off), HSTS (`max-age=63072000; includeSubDomains; preload`), `COOP`, `CORP`. Auth/admin pages get `Cache-Control: no-store` and `X-Robots-Tag: noindex`. Static `/assets/*` and `/canvaskit/*` get immutable 1‑year cache. JS/CSS get 1‑day must‑revalidate. The deploy workflow now copies `_headers`, `robots.txt`, and `sitemap.xml` into `build/web/`. |
| 19 | Password length inconsistency | `/api/auth/register` allowed 6‑char passwords; `/api/reset-password` allowed 6; signup required 8. | All paths now require ≥8 characters. |
| 20 | `validate-reset-token.js` | Email match was case‑sensitive while signup/reset are case‑insensitive. | Now `LOWER(email) = LOWER(?)`. |

---

## 3. Medium — SEO (FIXED)

| # | Area | Issue | Fix |
|---|---|---|---|
| 21 | `marketing.html` (the live homepage) | Used invalid `<meta name="og:*">` instead of `property="og:*"`; no canonical; no Twitter card; no JSON‑LD. | Added correct OG (`property="og:*"`), Twitter card (`summary_large_image`), `canonical`, `Organization` + `WebSite` JSON‑LD with `SearchAction`. `og:image` points to the absolute `https://thegearsh.com/icons/og-image.png`. |
| 22 | `artists.html`, `search.html`, `book-gig.html`, `join-gig.html`, `auth.html`, `privacy.html`, `terms.html` | No OG/Twitter, or OG was using `name=` not `property=`. | All key pages now have correct OG, Twitter cards, canonical URLs. `auth.html` adds `noindex, follow` (transactional). |
| 23 | `sitemap.xml` | Stuck at `lastmod=2025-01-01`; only listed 3 URLs; included `/privacy` which didn't have a redirect rule. | Replaced with 8 real URLs (home, /artists, /search, /book-gig.html, /join-gig.html, /auth.html, /terms.html, /privacy.html) and current `lastmod`. |
| 24 | `robots.txt` | Disallowed `/assets/`, blocking crawlers from artist OG images. | Allows `/assets/` and `/icons/`. Explicitly disallows `/api/`, `/canvaskit/`, `/gearsh-god*`, `/claim-profile*`, `/artist-dashboard*`, `/reset-password`, `/forgot-password`, `/app/`. |
| 25 | `_redirects` | `/app/login` duplicated; `/privacy-policy` pointed to the Flutter shell, `/privacy.html` to the static page, `/privacy` 404'd. | Duplicate removed. `/privacy`, `/privacy-policy`, `/terms` all resolve to the static legal pages. |

---

## 4. Medium — Performance (FIXED)

| # | Area | Issue | Fix |
|---|---|---|---|
| 26 | Render‑blocking JS | `marketing.html`, `artists.html`, `search.html` loaded `sa-showcase-data.js`, `artist-feed.js`, `gearsh-ui.js`, `artists-page.js`, `search-page.js` without `defer`. | All `<script>` tags marked `defer`. Marketing homepage now boots feed inside `DOMContentLoaded`. |
| 27 | DNS / TLS round trips | jsdelivr (Tabler icons) and Google Fonts had no preconnect. | Added `<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>` and Google Fonts preconnect on relevant pages. |
| 28 | Caching of JS/CSS at site root | `wrangler.toml` only cached `/assets/*` and `/canvaskit/*`. | `_headers` adds 1‑day `must-revalidate` for `*.js`/`*.css`, 7‑day for `/icons/*`, 1‑year immutable for `/assets/*` and `/canvaskit/*`. |

---

## 5. Medium — Accessibility (FIXED)

| # | Area | Issue | Fix |
|---|---|---|---|
| 29 | No skip‑to‑content link | Keyboard / screen‑reader users had to tab through nav on every page. | Added `.skip-link` styles in `gearsh-brand.css` and a `<a class="skip-link" href="#main">Skip to main content</a>` on `marketing.html`, `artists.html`, `search.html`. Pages now wrap their content in `<main id="main">`. |
| 30 | Body / muted text contrast | `--g-text-muted: #8A8780` and `--g-text-dim: #5C5A56` on `#0A0A0A` were below WCAG AA for body copy. | Lifted to `#A8A59E` (≈5.4:1) and `#7A776F` (≈3.5:1, captions only). |
| 31 | Focus visibility | `outline: none` everywhere, replaced only by border colour. | Global `*:focus-visible` outline using a brighter `--g-focus: #66D6FF` colour, 2 px outline + 2 px offset. |
| 32 | `prefers-reduced-motion` | Many animations/transitions ran regardless of OS setting. | Added a global media query that reduces all `animation-*` and `transition-*` durations. |
| 33 | Nav landmarks | `<nav>` lacked an `aria-label`. | All updated nav blocks now use `<nav aria-label="Primary">`. |
| 34 | Footer logo `alt=""` | Logo was decorative‑empty, but the brand name was lost. | Footer logos now use `alt="Gearsh"` with explicit `width`/`height`. |

---

## 6. Quality / Operational (FIXED)

| # | Area | Issue | Fix |
|---|---|---|---|
| 35 | `.gitignore` | `build/` was not ignored — `git status` showed 100+ generated files. | Added `build/`, `/build/`, `**/build/web/`. |
| 36 | `_redirects` duplicates | `/app/login` listed twice. | Removed the duplicate. |
| 37 | Deploy workflow | `_headers`, `robots.txt`, `sitemap.xml` were not copied into the deploy bundle. | `.github/workflows/deploy.yml` now copies all three explicitly. |
| 38 | Inconsistent API responses | Mix of `{ success, error }` / `{ error }` / `{ valid, error, debug, details }`. | New responses standardize on `{ success, error }` (or `{ success, data }`); `debug`/`details` removed entirely. |
| 39 | Stale code in `web/functions/api/get_signups.js` | Used the old `// filepath:` header comment from a different machine. | Replaced with a clean implementation. |

---

## 7. Recommended Follow‑Up (NOT done in this pass)

These were identified but not changed to avoid scope creep — each needs a small design decision or an env var:

1. **Rate limiting** — `/api/login`, `/api/signup`, `/api/forgot-password`, `/api/auth/register`, `/api/claim-profile`, `/api/founder/login`. Easiest path: Cloudflare Pages → Workers KV with sliding window keyed by IP + endpoint, returning `429` after N attempts/min.
2. **CSP** — A real `Content-Security-Policy` is intentionally not in `_headers` yet because the Flutter shell and inline `<script>` blocks in marketing pages need either a nonce or a hash list. Recommend rolling out as `Content-Security-Policy-Report-Only` first, then enforcing once violations are clean.
3. **Founder admin UI** — `gearsh-god.html` still stores the founder key in `localStorage`. Long‑term, this should move to an HttpOnly cookie set by a `/api/founder/login` exchange (already implemented for the API side) and the page should be served behind a Cloudflare Access policy or HTTP basic auth at the edge.
4. **Session cookies** — User auth tokens are still kept in `localStorage`. Migrating to `Secure; HttpOnly; SameSite=Lax` cookies + a CSRF token for the few state‑changing browser POSTs would close the residual XSS‑token‑theft surface.
5. **`/api/users` SQL** — Now parameterized, but the endpoint is broadly powerful. Consider an explicit `?fields=` allow‑list and audit log.
6. **CORS** — Still `Access-Control-Allow-Origin: *` on auth endpoints. Fine while only the same origin and the Flutter mobile app call them, but consider tightening to the production origin set when a `web` and `app` domain split happens.
7. **Image placeholders** — ~30 showcase artists still resolve to a placeholder image; this is a content task, not a code one.
8. **Orphan source files** — `web/index.html`, `web/app.html`, `web/landing.html`, `web/signup (1).html` are not deployed (marketing.html → index.html at build time). Safe to delete in a separate cleanup PR once we're sure no internal docs link to them.
9. **Service Worker scope** — Flutter SW lives under `/app/` now (good). `web/flutter_service_worker.js` is removed pre‑build, but a stale copy still exists in source. Safe to delete.
10. **`gearsh-god.html` heading order** — Two `<h1>` elements (hero + login form). Demote one to `<h2>` when the admin UI gets its next iteration.

---

## 8. Files Touched

```
.github/workflows/deploy.yml                           # copy _headers, robots, sitemap
.gitignore                                             # ignore build/
functions/api/auth-utils.js                            # JWT secret hard fail, legacy gated, isFounderRequest, constant time
functions/api/users.js                                 # founder auth + SQL injection fix
functions/api/upload-profile-photo.js                  # Bearer-only, mime/size limits
functions/api/reviews.js                               # Bearer auth, booking ownership + completion
functions/api/signup.js                                # remove PII logs, drop debug/details
functions/api/onboarding-utils.js                      # stop logging OTPs / reset URLs
functions/api/health.js                                # hide DB error details
functions/api/artists/feed.js                          # throttle + waitUntil for seeding
functions/api/artists/[id].js                          # only seed when row missing
functions/api/auth/[action].js                         # min password 8
web/functions/api/update-profile.js                    # token-only identity
web/functions/api/firebase-sync.js                     # real RS256 Firebase verification
web/functions/api/social-auth.js                       # real Google + Apple verification
web/functions/api/get_signups.js                       # required key, constant time
web/functions/api/reset-password.js                    # min password 8
web/functions/api/validate-reset-token.js              # case-insensitive email match
web/functions/api/forgot-password.js                   # stop logging reset URL
web/_headers                                           # NEW — security + cache headers
web/robots.txt                                         # allow /assets, disallow admin/api
web/sitemap.xml                                        # real URLs + lastmod
web/_redirects                                         # de-dup, /privacy + /terms
web/gearsh-brand.css                                   # focus-visible, skip-link, contrast
web/marketing.html                                     # OG/Twitter/JSON-LD, defer, skip, main
web/artists.html                                       # OG/Twitter, defer, skip, main
web/search.html                                        # OG/Twitter, defer, skip, main
web/book-gig.html                                      # OG/Twitter, canonical, preconnect
web/join-gig.html                                      # OG/Twitter, canonical, preconnect
web/auth.html                                          # noindex, canonical, preconnect
web/privacy.html                                       # OG/Twitter, canonical
web/terms.html                                         # OG/Twitter, canonical
AUDIT.md                                               # this report
```

---

## 9. How to Verify

1. `git diff --stat origin/main HEAD` should show the file list above.
2. Deploy to a preview branch on Cloudflare Pages.
3. Run Lighthouse on `/`, `/artists`, `/search` — expect Best Practices 95+, SEO 100, Accessibility 95+.
4. Hit `/api/users` without `x-founder-key` → must return 401.
5. Hit `/api/upload-profile-photo` with `{ firebase_uid: "anything" }` and no Bearer → must return 401.
6. Hit `/api/reviews` with a forged `reviewer_id` → must return 401/403.
7. View page source on `/` and confirm `<meta property="og:image" content="https://thegearsh.com/icons/og-image.png">` and the two JSON‑LD blocks are present.
8. `curl -I https://thegearsh.com/` should show `Strict-Transport-Security`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`.
