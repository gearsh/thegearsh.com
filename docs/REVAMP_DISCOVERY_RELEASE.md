# Revamped website launch — 23 October 2026

This release publishes the revamped homepage, discovery, creative profiles, signup/sign-in, password-recovery pages and booking requests. It includes the payment hardening from PR #11, but does not launch payments. The paid-booking restrictions documented in V1_PAYMENT_RELEASE_AUDIT.md remain open.

`functions/api/release-config.js` sets `ONLINE_CHECKOUT_RELEASED=false`. PayFast initiation rejects both booking and ticket checkout even if an existing environment variable enables payments. Existing payment notifications remain available for transactions initiated earlier. Activate payments only through a separate reviewed release after processor approval, legal review, refund/payout reconciliation and live integration verification.

Hvdini Mxgic is retained with his supplied YouTube link, placeholder image and clearly labelled estimated service prices. Discovery links and legacy booking links render the same profile and retain actual API service IDs. API errors and removed profiles are not replaced with locally fabricated bookable profiles.

Validation: password recovery and payment audit tests; checkout disabled with enabling environment variables; changed inline JavaScript syntax; production static packaging and homepage links/images. CI and preview checks run against the release commit. Live email delivery requires configured sender credentials and is not established by unit tests.

Rollback: revert the release merge to restore the previous website. No destructive data migration is required; new database tables are additive.
