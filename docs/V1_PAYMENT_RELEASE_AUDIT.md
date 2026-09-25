# V1 payment release audit — 25 September 2026

**Release decision: blocked.** PR #8 was merged on 16 September 2026. The subsequent commercial commits on `website-revamp-v1` are a separate change set; do not represent them as an unmerged PR #8 or deploy them as production ready.

## Verified in this branch

- Booking checkout charges Artist Subtotal plus 12.6% Client fee; the quoted Artist payout is Artist Subtotal less 4% Artist fee. The total Gearsh fee is 16.6% of Artist Subtotal, before processor costs.
- A pending checkout no longer creates an escrow hold. A signed, PayFast validated notification must match the pending payment's merchant and amount before recording a hold and confirming the booking.
- A booking completion no longer records a bank payout that was never executed. A paid cancellation is blocked instead of recording an unprocessed refund.

## Open blockers

1. **No actual payout integration or settlement reconciliation.** A completed booking does not transfer money to an artist. The 36 hour dispute hold in `web/terms.html` is not enforced by a payout scheduler. Do not promise automatic release through PayFast until an authorized payout mechanism and reconciliation exist.
2. **No actual refund integration.** Cancellation tiers, artist no-show, client no-show, fee retention and split dispute outcomes in `web/terms.html` are not implemented. Paid cancellation is now rejected pending a verified refund operation. Support must resolve existing paid booking cases manually and reconcile the ledger to processor statements.
3. **Payment concurrency and recovery.** A webhook after a partially completed legacy attempt, duplicate checkout or a concurrent status update needs transaction and idempotency testing against D1 and PayFast sandbox. The booking reference in historical checkouts was a booking ID; new checkouts use a unique payment ID.
4. **Ticket payments are a separate flow.** Ticket order fulfillment, duplicate and delayed ITNs, amount validation, chargebacks and refund policy need independent audit before ticket sales are enabled.
5. **Legal approval.** `web/terms.html` calls itself a draft requiring review. Its escrow, payout, 36 hour dispute, cancellation and refund promises exceed the implemented system. Obtain qualified South African legal review and align the actual processor arrangement before publishing these claims as operative terms.
6. **Live integration evidence.** Verify sandbox payment, wrong amount and merchant rejection, duplicate ITN, failed checkout, completion, dispute, refund and payout with transaction IDs and bank reconciliation. Unit tests and syntax checks alone cannot satisfy this gate.

The code changes here reduce false accounting and reject unsafe state transitions. They do not authorize a production merge or payment launch.
