import test from 'node:test';
import assert from 'node:assert/strict';
import { matchesBookingPayment, handleBookingNotify } from '../functions/api/payfast/notify.js';
import { CLIENT_FEE_RATE, ARTIST_FEE_RATE, TOTAL_GEARSH_FEE_RATE } from '../functions/api/payfast-utils.js';

test('V1 client and artist fees add to the stated total', () => {
  assert.equal(CLIENT_FEE_RATE, 0.126);
  assert.equal(ARTIST_FEE_RATE, 0.04);
  assert.equal(TOTAL_GEARSH_FEE_RATE, 0.166);
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
