import test from 'node:test';
import assert from 'node:assert/strict';
import { matchesBookingPayment, handleBookingNotify } from '../functions/api/payfast/notify.js';
import { CLIENT_FEE_RATE, ARTIST_FEE_RATE, TOTAL_GEARSH_FEE_RATE } from '../functions/api/payfast-utils.js';
import { onRequestPost as initiatePayment } from '../functions/api/payfast/initiate.js';
import { reconciliationRow } from '../functions/api/founder/payments.js';
import { payoutEligibility } from '../functions/api/founder/payouts.js';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';

test('V1 client and artist fees add to the stated total', () => {
  assert.equal(CLIENT_FEE_RATE, 0.126);
  assert.equal(ARTIST_FEE_RATE, 0.04);
  assert.equal(TOTAL_GEARSH_FEE_RATE, 0.166);
});

test('checkout is disabled until explicitly enabled and production credentials are complete', async () => {
  const context = { env: {}, request: new Request('https://example.com/api/payfast/initiate', { method: 'POST' }) };
  const disabled = await initiatePayment(context);
  assert.equal(disabled.status, 503);
  context.env.GEARSH_BOOKING_PAYMENTS_ENABLED = 'true';
  context.env.PAYFAST_SANDBOX = 'false';
  const unconfigured = await initiatePayment(context);
  assert.equal(unconfigured.status, 503);
});

test('ITN must match a pending amount and merchant', () => {
  const payment = { status: 'pending', amount: 1126 };
  const payload = { amount_gross: '1126.00', merchant_id: 'merchant' };
  assert.equal(matchesBookingPayment(payment, payload, 'merchant'), true);
  assert.equal(matchesBookingPayment(payment, { ...payload, amount_gross: '1.00' }, 'merchant'), false);
  assert.equal(matchesBookingPayment(payment, { ...payload, merchant_id: 'other' }, 'merchant'), false);
  assert.equal(matchesBookingPayment({ ...payment, status: 'complete' }, payload, 'merchant'), false);
  assert.equal(matchesBookingPayment(payment, { ...payload, amount_gross: 'NaN' }, 'merchant'), false);
});

function fakeDb() {
  const payment = { id: 'pay_1', booking_id: 'book_1', status: 'pending', amount: 1126 };
  const booking = { status: 'accepted' };
  const operations = [];
  return {
    payment, booking, operations,
    prepare(sql) {
      return {
        bind(...args) {
          return {
            async first() {
              if (sql.includes('SELECT status FROM bookings')) return booking;
              if (sql.includes("status = 'complete' LIMIT")) return null;
              return payment;
            },
            sql, args,
          };
        },
      };
    },
    async batch(statements) {
      operations.push(...statements);
      payment.status = 'complete';
      payment.payfast_payment_id = 'pf_1';
      booking.status = 'confirmed';
    },
  };
}

test('confirmed ITN writes payment, hold and booking together', async () => {
  const db = fakeDb();
  const payload = { amount_gross: '1126.00', merchant_id: 'merchant' };
  await handleBookingNotify(db, 'pay_1', 'COMPLETE', 'pf_1', payload, 'merchant');
  assert.equal(db.operations.length, 3);
  assert.match(db.operations[1].sql, /INSERT INTO escrow_ledger/);
  assert.equal(db.payment.status, 'complete');
  await handleBookingNotify(db, 'pay_1', 'COMPLETE', 'pf_1', payload, 'merchant');
  assert.equal(db.operations.length, 3);
});

test('invalid ITN never updates booking or ledger', async () => {
  const db = fakeDb();
  await assert.rejects(() => handleBookingNotify(db, 'pay_1', 'COMPLETE', 'pf_1',
    { amount_gross: '1125.99', merchant_id: 'merchant' }, 'merchant'));
  assert.equal(db.operations.length, 0);
  assert.equal(db.booking.status, 'accepted');
});

test('founder reconciliation shows gross and calculated artist share without claiming a transfer', () => {
  const row = reconciliationRow({
    booking_id: 'book_1', payment_id: 'pay_1', payfast_payment_id: 'pf_1',
    booking_status: 'completed', amount: 1126, total_price: 1000,
    recorded_refund: 0, recorded_release: 0,
  });
  assert.equal(row.gross_collected, 1126);
  assert.equal(row.artist_share_if_fully_payable, 960);
  assert.equal(row.ledger_release, 0);
  assert.equal(row.requires_external_verification, true);
});

test('bank payout amount is calculated server-side and blocked by disputes, refunds or unsettled payment', () => {
  const row = { payment_status: 'complete', booking_status: 'completed',
    payfast_payment_id: 'pf_1', total_price: 1000, payment_amount: 1126,
    holds: 1126, refunds: 0, disputes: 0 };
  assert.equal(payoutEligibility(row), 960);
  assert.equal(payoutEligibility({ ...row, disputes: 1 }), null);
  assert.equal(payoutEligibility({ ...row, refunds: 50 }), null);
  assert.equal(payoutEligibility({ ...row, holds: 0 }), null);
  assert.equal(payoutEligibility({ ...row, prior_releases: 960 }), null);
  assert.equal(payoutEligibility({ ...row, payment_status: 'pending' }), null);
});

test('payout records cannot reuse a payment, bank transfer or bank statement reference', () => {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../database/schema.sql', import.meta.url), 'utf8'));
  // This test isolates the payout uniqueness constraints from booking fixtures.
  db.exec('PRAGMA foreign_keys = OFF');
  const insert = db.prepare(`INSERT INTO payout_reconciliations
    (id, payment_id, booking_id, amount, payfast_settlement_reference,
     bank_transfer_reference, beneficiary_last4, recorded_by, created_at)
    VALUES (?, ?, 'book_1', 960, 'settlement_1', ?, '1234', 'founder', '2026-09-25')`);
  insert.run('pout_1', 'pay_1', 'bank_1');
  assert.throws(() => insert.run('pout_2', 'pay_1', 'bank_2'));
  assert.throws(() => insert.run('pout_3', 'pay_2', 'bank_1'));
  db.prepare(`UPDATE payout_reconciliations SET bank_statement_reference = 'statement_1' WHERE id = 'pout_1'`).run();
  insert.run('pout_4', 'pay_4', 'bank_4');
  assert.throws(() => db.prepare(`UPDATE payout_reconciliations SET bank_statement_reference = 'statement_1' WHERE id = 'pout_4'`).run());
  db.close();
});
