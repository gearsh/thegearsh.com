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
- [ ] Keep `GEARSH_BOOKING_PAYMENTS_ENABLED` unset until the refund, Artist payout, legal, and reconciliation gates below are satisfied; then set it to `true` only in the verified environment
- [ ] Confirm PayFast merchant account capability for the intended Artist settlement model; Split Payments at checkout is not deferred escrow release
- [ ] Document and test the merchant dashboard refund procedure, including partial refunds and reconciliation to transaction IDs
- [ ] Verify Artist bank beneficiary details securely; send bank transfer after PayFast settlement, booking completion and dispute review
- [ ] Record transfer reference with `POST /api/founder/payouts`, then verify bank statement reference using `PATCH /api/founder/payouts`; test duplicate and ineligible attempts
- [ ] Compare `GET /api/founder/payments` reconciliation queue against PayFast transaction history and bank records; investigate every unmatched reference and amount
- [ ] Obtain qualified South African legal approval for operative Terms and cancellation/refund policy; replace the marked drafts in website and app
- [ ] Verify the `V1 Payment Audit` CI check on the exact branch commit and sandbox ITN, duplicate, wrong amount, failed payment and dispute flows

## Booking lifecycle
- [ ] Artist accepts booking: `PATCH /api/bookings/:id` with `action: accept`
- [ ] Client can cancel pending booking
- [ ] Completed booking does not falsely write a payout ledger entry; record release only after independently verified transfer

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
