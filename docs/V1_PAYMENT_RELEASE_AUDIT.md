# V1 payment release audit — 25 September 2026

**Release decision: blocked.** PR #8 was merged on 16 September 2026. The subsequent commercial commits on `website-revamp-v1` are a separate change set; do not represent them as an unmerged PR #8 or deploy them as production ready.

## Verified in this branch

- Booking checkout charges Artist Subtotal plus 12.6% Client fee; the quoted Artist payout is Artist Subtotal less 4% Artist fee. The total Gearsh fee is 16.6% of Artist Subtotal, before processor costs.
- A pending checkout no longer creates an escrow hold. A signed, PayFast validated notification must match the pending payment's merchant and amount before recording a hold and confirming the booking.
- A booking completion no longer records a bank payout that was never executed. A paid cancellation is blocked instead of recording an unprocessed refund.
- Checkout now requires an explicit `GEARSH_BOOKING_PAYMENTS_ENABLED=true` setting; production mode also requires all three PayFast merchant credentials. Leave the setting unset until the release gates are met.
- Website and app payment terms are marked drafts and no longer promise automatic escrow, payout, fixed cancellation percentages or an enforced 36-hour dispute window.
- Founder payments API now exposes a read-only reconciliation queue with PayFast transaction IDs, gross collected, calculated Artist share and internal ledger amounts. Every row explicitly requires external verification; the queue does not initiate a refund or payout.
- The V1 settlement design uses Gearsh's PayFast account and Artist bank transfers after completion and verified settlement. Founder-only payout records retain PayFast settlement and bank transfer references; the ledger release is written only after a bank statement reference is supplied. The API never initiates a bank transfer or independently verifies those references.

## Open blockers

1. **External bank transfer required.** A completed booking does not transfer money automatically. Gearsh must confirm PayFast settlement, verify the Artist beneficiary, send an actual bank transfer, then reconcile it to the bank statement. The internal evidence workflow supports this process but cannot verify the bank independently.
2. **No actual refund integration.** Paid cancellation is rejected pending a verified refund operation. PayFast documents full and partial refunds in its merchant dashboard; the app has no verified dashboard-to-ledger reconciliation. Support must resolve existing paid booking cases manually and reconcile against processor statements.
3. **Payment concurrency and recovery.** A webhook after a partially completed legacy attempt, duplicate checkout or a concurrent status update needs transaction and idempotency testing against D1 and PayFast sandbox. The booking reference in historical checkouts was a booking ID; new checkouts use a unique payment ID.
4. **Ticket payments are a separate flow.** Ticket ITNs now check pending order, merchant and amount before fulfillment, but fulfillment atomicity, duplicate and delayed ITNs across attempts, chargebacks and event-specific refund policies need independent sandbox and concurrency testing before ticket sales are enabled.
5. **Legal approval.** Website and app terms are explicitly marked as drafts aligned to the current technical limits. Obtain qualified South African legal review and align the actual processor arrangement and cancellation policy before publishing them as operative terms.
6. **Live integration evidence.** Verify sandbox payment, wrong amount and merchant rejection, duplicate ITN, failed checkout, completion, dispute, refund and payout with transaction IDs and bank reconciliation. Unit tests and syntax checks alone cannot satisfy this gate.

The code changes here reduce false accounting and reject unsafe state transitions. They do not authorize a production merge or payment launch.

## Processor references

- PayFast [Merchant Refund](https://payfast.io/features/merchant-refund/) describes full and partial refunds through its merchant dashboard.
- PayFast [Split Payments](https://payfast.io/features/split-payments/) describes an immediate split of a payment with a third party, not a deferred Artist payout after completion.
