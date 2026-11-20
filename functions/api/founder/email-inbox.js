// Founder-only combined artist inbox.
// Reads thegearsh@gmail.com via Gmail API; domain mail appears once forwarded there.
// No OAuth token or full third-party mailbox data ever reaches a public endpoint.
import { requireFounder } from '../founder-auth.js';
import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';

function header(message, name) {
  return (message.payload?.headers || []).find(h => h.name?.toLowerCase() === name.toLowerCase())?.value || '';
}
function extractEmail(value) {
  const address = String(value || '').match(/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/i);
  return address ? address[0].toLowerCase() : '';
}
async function gmailToken(env) {
  const keys = [env.GEARSH_GMAIL_CLIENT_ID, env.GEARSH_GMAIL_CLIENT_SECRET, env.GEARSH_GMAIL_REFRESH_TOKEN];
  if (keys.some(k => !k)) return null;
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: env.GEARSH_GMAIL_CLIENT_ID,
      client_secret: env.GEARSH_GMAIL_CLIENT_SECRET,
      refresh_token: env.GEARSH_GMAIL_REFRESH_TOKEN,
      grant_type: 'refresh_token',
    }),
  });
  if (!res.ok) throw new Error('Gmail authorization failed. Reconnect the mailbox.');
  const data = await res.json();
  if (!data.access_token) throw new Error('Gmail access token unavailable.');
  return data.access_token;
}
async function gmailGet(token, path) {
  const res = await fetch('https://gmail.googleapis.com/gmail/v1/users/me/' + path, {
    headers: { Authorization: 'Bearer ' + token },
  });
  if (!res.ok) throw new Error(res.status === 403 ? 'Gmail read permission is missing.' : 'Gmail is temporarily unavailable.');
  return res.json();
}
function extractPlainPart(part, depth = 0) {
  if (!part || depth > 8) return '';
  if (part.mimeType === 'text/plain' && part.body?.data) {
    try {
      let encoded = part.body.data.replace(/-/g, '+').replace(/_/g, '/');
      const raw = atob(encoded);
      return new TextDecoder().decode(Uint8Array.from(raw, c => c.charCodeAt(0)));
    } catch (_) { return ''; }
  }
  for (const child of (part.parts || [])) {
    const decoded = extractPlainPart(child, depth + 1);
    if (decoded) return decoded;
  }
  return '';
}
async function artistsByEmail(db) {
  const result = await db.prepare(`
    SELECT ap.id AS artist_id, u.display_name AS name, LOWER(u.email) AS email
    FROM users u JOIN artist_profiles ap ON ap.user_id = u.id
    WHERE u.is_active=1 AND (u.is_demo=0 OR u.is_demo IS NULL)
      AND u.email NOT LIKE 'unclaimed+%'
    LIMIT 1000
  `).all();
  const known = new Map();
  for (const a of result.results || []) if (a.email) known.set(a.email, a);
  return known;
}
async function sentLogs(db) {
  const table = await db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='founder_artist_email_log'").first();
  if (!table) return [];
  const result = await db.prepare(`
    SELECT l.id, l.artist_id, u.display_name AS artist_name, l.recipient, l.subject, l.status, l.created_at
    FROM founder_artist_email_log l LEFT JOIN artist_profiles ap ON ap.id=l.artist_id
    LEFT JOIN users u ON u.id=ap.user_id ORDER BY l.created_at DESC LIMIT 50
  `).all();
  return result.results || [];
}
export async function onRequestGet(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;
    const url = new URL(context.request.url);
    const mode = url.searchParams.get('mode') || 'inbox';
    if (mode === 'sent') return jsonResponse({ success:true, data:{ messages:await sentLogs(context.env.DB) } });
    if (!['inbox','message'].includes(mode)) return jsonResponse({success:false,error:'Invalid mailbox view'},400);
    const token = await gmailToken(context.env);
    if (!token) return jsonResponse({success:true,data:{configured:false,messages:[],instructions:'Configure Gmail OAuth read-only secrets and forward @thegearsh.com incoming mail into thegearsh@gmail.com.'}});
    const artists = await artistsByEmail(context.env.DB);
    if (mode === 'message') {
      const id = String(url.searchParams.get('id') || '');
      if (!/^[a-zA-Z0-9_-]{8,150}$/.test(id)) return jsonResponse({success:false,error:'Invalid message'},400);
      const mail = await gmailGet(token, 'messages/' + encodeURIComponent(id) + '?format=full');
      const address = extractEmail(header(mail,'From'));
      const artist = artists.get(address);
      if (!artist || !mail.labelIds?.includes('INBOX')) return jsonResponse({success:false,error:'Artist message not found in inbox'},404);
      return jsonResponse({success:true,data:{
        id:mail.id, artist_id:artist.artist_id, artist_name:artist.name,
        from:header(mail,'From').slice(0,254), to:header(mail,'To').slice(0,254),
        subject:header(mail,'Subject').slice(0,200), date:header(mail,'Date').slice(0,90),
        text:extractPlainPart(mail.payload).slice(0,18000) || String(mail.snippet || '').slice(0,500),
      }});
    }
    const list = await gmailGet(token, 'messages?labelIds=INBOX&maxResults=65');
    const ids = (list.messages || []).slice(0,65);
    const messages = [];
    // Bound concurrency to limit Gmail API pressure.
    for (let i=0; i<ids.length; i+=6) {
      const group = await Promise.all(ids.slice(i,i+6).map(m =>
        gmailGet(token,'messages/'+encodeURIComponent(m.id)+'?format=metadata&metadataHeaders=From&metadataHeaders=To&metadataHeaders=Subject&metadataHeaders=Date').catch(()=>null)
      ));
      for (const m of group) {
        if (!m) continue;
        const sender = extractEmail(header(m,'From'));
        const artist = artists.get(sender);
        if (!artist) continue; // Do not expose unrelated personal Gmail conversations.
        messages.push({
          id:m.id, artist_id:artist.artist_id, artist_name:artist.name, sender,
          subject:header(m,'Subject').slice(0,200), date:header(m,'Date').slice(0,90),
          to:header(m,'To').slice(0,254), snippet:String(m.snippet||'').slice(0,240),
          unread:m.labelIds?.includes('UNREAD') || false,
        });
      }
    }
    return jsonResponse({success:true,data:{configured:true,messages}});
  } catch (err) {
    console.error('Founder inbox failed', String(err.message || err).slice(0,120));
    return jsonResponse({success:false,error:'Unable to read the inbox. Check Gmail OAuth configuration and permissions.'},503);
  }
}
export async function onRequestOptions() { return corsPreflightResponse(); }
