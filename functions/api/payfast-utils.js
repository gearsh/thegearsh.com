// PayFast helpers shared by initiate + notify endpoints
import { md5 } from './payfast-md5.js';

export const PLATFORM_FEE_RATE = 0.126;

export function getPayfastConfig(env) {
  const sandbox = String(env.PAYFAST_SANDBOX || 'true') !== 'false';
  return {
    sandbox,
    merchantId: env.PAYFAST_MERCHANT_ID || '10000100',
    merchantKey: env.PAYFAST_MERCHANT_KEY || '46f0cd694581a',
    passphrase: env.PAYFAST_PASSPHRASE || 'jt7NOE43FZPn',
    processUrl: sandbox
      ? 'https://sandbox.payfast.co.za/eng/process'
      : 'https://www.payfast.co.za/eng/process',
    validateUrl: sandbox
      ? 'https://sandbox.payfast.co.za/eng/query/validate'
      : 'https://www.payfast.co.za/eng/query/validate',
  };
}

export function buildSignature(data, passphrase) {
  const sortedKeys = Object.keys(data).sort();
  const paramString = sortedKeys
    .filter(function(key) {
      const value = data[key];
      return value !== undefined && value !== null && String(value).trim() !== '';
    })
    .map(function(key) {
      return `${key}=${encodeURIComponent(String(data[key]).trim()).replace(/%20/g, '+')}`;
    })
    .join('&');

  const stringToHash = passphrase
    ? `${paramString}&passphrase=${encodeURIComponent(passphrase.trim()).replace(/%20/g, '+')}`
    : paramString;

  return md5(stringToHash);
}

export function verifyPayfastSignature(payload, passphrase) {
  const received = String(payload.signature || '');
  const clone = { ...payload };
  delete clone.signature;
  const expected = buildSignature(clone, passphrase);
  return received.toLowerCase() === expected.toLowerCase();
}

export async function validateItnWithPayfast(env, rawBody) {
  const config = getPayfastConfig(env);
  const response = await fetch(config.validateUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: rawBody,
  });
  const text = await response.text();
  return text.trim().toUpperCase() === 'VALID';
}

export function parseFormBody(rawBody) {
  const params = new URLSearchParams(rawBody);
  const data = {};
  for (const [key, value] of params.entries()) {
    data[key] = value;
  }
  return data;
}
