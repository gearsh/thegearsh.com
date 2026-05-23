# Gearsh Launch Checklist

## Auth & routing
- [ ] Open https://www.thegearsh.com/sign-in — static login form loads (not `/app/onboarding`)
- [ ] Sign in as artist → redirects to `/artist-dashboard.html`
- [ ] Sign out via `/sign-in?logout=1` clears session

## Artist signup & booking
- [ ] Complete 3-step signup at `/join-gig.html`
- [ ] Public booking page `/book/<username>` accepts venue + creates booking request
- [ ] Flutter/web booking flow creates booking via `POST /api/bookings` before PayFast

## Payments (PayFast)
- [ ] Sandbox: `POST /api/payfast/initiate` returns signed fields
- [ ] PayFast ITN hits `POST /api/payfast/notify` and marks payment + booking confirmed
- [ ] Set production env vars: `PAYFAST_MERCHANT_ID`, `PAYFAST_MERCHANT_KEY`, `PAYFAST_PASSPHRASE`, `PAYFAST_SANDBOX=false`

## Booking lifecycle
- [ ] Artist accepts booking: `PATCH /api/bookings/:id` with `action: accept`
- [ ] Client can cancel pending booking
- [ ] Completed booking writes escrow release ledger entry

## Messaging
- [ ] `GET /api/conversations` lists threads for signed-in user
- [ ] Send/receive messages on a booking thread

## Founder admin (Gearsh Command)
- [ ] `/gearsh-god.html` — stats, artists, verification queue, payments, disputes
- [ ] Force-confirm booking from admin panel

## Security
- [ ] Set `JWT_SECRET` in Cloudflare Pages env (production)
- [ ] Verify protected routes reject missing Bearer token

## App store prep
- [ ] Flutter build: `flutter build appbundle` / `flutter build ipa`
- [ ] Store listings, screenshots, privacy policy URLs
- [ ] PayFast production merchant approval

## Smoke test script
Run from repo root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/smoke-test.ps1
```
