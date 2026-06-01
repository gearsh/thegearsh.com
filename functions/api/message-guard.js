// Anti-disintermediation guard for in-platform messaging.
//
// Marketplaces lose revenue when two parties exchange contact details and take
// the deal off-platform ("leakage"). Before a collaboration is booked & paid
// through Gearsh, we redact contact details and off-platform payment cues from
// messages, warn the sender, and flag the attempt for founder review. Once the
// work is locked in (paid via escrow), contact exchange is unlocked as a reward
// for keeping the deal on Gearsh.

const MASK = '\u2022\u2022\u2022';

// Email addresses.
const RE_EMAIL = /[A-Z0-9._%+-]+\s*(?:@|\(at\)|\[at\]|\bat\b)\s*[A-Z0-9.-]+\s*(?:\.|\(dot\)|\[dot\]|\bdot\b)\s*[A-Z]{2,}/gi;

// URLs and link-shorteners (incl. wa.me / t.me / linktr.ee etc.).
const RE_URL = /\b(?:https?:\/\/|www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|co\.za|net|org|io|me|link|page|gg|app|info|biz|store|live|tv|fm|to|ly|be)\b(?:\/[^\s]*)?/gi;

// Social / messaging handles introduced by @ or platform keywords.
const RE_HANDLE = /(?:^|[\s(])@[A-Za-z0-9._]{2,}/g;

// Phone numbers: a run of 9+ digits, optionally with +, spaces, dashes, dots, parens.
const RE_PHONE = /(?:\+?\d[\d\s().\-]{7,}\d)/g;

// Long digit runs (account numbers) caught by RE_PHONE; this catches spelled groups too.

// Off-platform contact / payment / circumvention phrases. Matching any of these
// flags the message even if no raw number/email is present.
const FLAG_PHRASES = [
  'whatsapp', 'whatsap', 'watsapp', 'wsp', 'whats app', 'whtsapp',
  'telegram', 'signal app', 'snapchat', ' snap me', 'instagram', ' insta ', ' ig ',
  'dm me', 'inbox me', 'tiktok', 'facebook', ' fb ', 'messenger',
  'capitec', 'fnb', 'absa', 'nedbank', 'standard bank', 'tymebank', 'tyme bank',
  'account number', 'acc number', 'acc no', 'account no', 'bank details', 'branch code',
  'snapscan', 'zapper', 'ewallet', 'e-wallet', 'payshap', 'instant eft',
  'pay me directly', 'pay directly', 'pay me cash', 'cash deal', 'send the money',
  'off the app', 'off gearsh', 'outside gearsh', 'off platform', 'off-platform',
  'skip gearsh', 'bypass gearsh', 'without gearsh', 'avoid the fee', 'no commission',
  'call me on', 'text me on', 'reach me on', 'contact me on', 'my number is', 'my cell',
];

function maskMatches(text, re, label, reasons) {
  let hit = false;
  const out = text.replace(re, function (m) {
    // Keep a leading space/paren captured by RE_HANDLE.
    const lead = /^[\s(]/.test(m) ? m[0] : '';
    hit = true;
    return lead + MASK;
  });
  if (hit && reasons.indexOf(label) === -1) reasons.push(label);
  return out;
}

// Scan text for leakage. Returns { clean, flagged, reasons }.
//  - clean:   redaction-applied text (use this for storage pre-unlock)
//  - flagged: whether anything suspicious was detected
//  - reasons: machine labels for the founder dashboard
export function scanMessage(text) {
  const original = String(text || '');
  const reasons = [];
  let clean = original;

  clean = maskMatches(clean, RE_EMAIL, 'email', reasons);
  clean = maskMatches(clean, RE_URL, 'link', reasons);
  clean = maskMatches(clean, RE_PHONE, 'phone', reasons);
  clean = maskMatches(clean, RE_HANDLE, 'handle', reasons);

  // Normalise to single-spaced lowercase so phrases match regardless of punctuation.
  const lower = (' ' + original.toLowerCase() + ' ').replace(/[^a-z0-9@.\-]+/g, ' ');
  for (let i = 0; i < FLAG_PHRASES.length; i++) {
    const phrase = FLAG_PHRASES[i].trim();
    if (lower.indexOf(' ' + phrase + ' ') === -1 && lower.indexOf(' ' + phrase) === -1) continue;
    if (reasons.indexOf('off_platform_phrase') === -1) reasons.push('off_platform_phrase');
    const phraseRe = new RegExp(phrase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
    clean = clean.replace(phraseRe, MASK);
  }

  return {
    clean: clean,
    flagged: reasons.length > 0,
    reasons: reasons,
  };
}

// Produce the message text to store/return given whether contact is unlocked.
// When unlocked (deal is paid through Gearsh) we keep the original text.
export function guardMessage(text, unlocked) {
  const scan = scanMessage(text);
  if (unlocked) {
    return { text: String(text || ''), flagged: false, reasons: [], redacted: false };
  }
  return {
    text: scan.clean,
    flagged: scan.flagged,
    reasons: scan.reasons,
    redacted: scan.flagged,
  };
}

// A short, human-readable nudge shown to a sender whose message was redacted.
export function leakageNudge(reasons) {
  if (reasons.indexOf('off_platform_phrase') !== -1 || reasons.indexOf('phone') !== -1 ||
      reasons.indexOf('email') !== -1 || reasons.indexOf('handle') !== -1 || reasons.indexOf('link') !== -1) {
    return 'For both artists\u2019 protection, contact and payment details are hidden until the collaboration is booked and paid through Gearsh. Keeping it on Gearsh covers you with escrow, disputes, and a verified track record.';
  }
  return '';
}

// Statuses at which the deal is considered locked-in / paid, so contact unlocks.
const UNLOCKED_STATUSES = new Set(['in_progress', 'completed']);

export function isContactUnlocked(status) {
  return UNLOCKED_STATUSES.has(String(status || ''));
}
