// Founder-only individual artist email. No bulk or demo-address sending.
import { requireFounder } from '../founder-auth.js';
import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';

const validEmail = value => /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(value);
const esc = value => String(value).replace(/[&<>"']/g, ch => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
})[ch]);
async function ensureLog(db) {
  await db.prepare(`CREATE TABLE IF NOT EXISTS founder_artist_email_log (
    id TEXT PRIMARY KEY, founder_id TEXT NOT NULL, artist_id TEXT NOT NULL,
    recipient TEXT NOT NULL, subject TEXT NOT NULL, status TEXT NOT NULL,
    created_at TEXT NOT NULL, sent_at TEXT, provider_id TEXT
  )`).run();
  await db.prepare('CREATE INDEX IF NOT EXISTS idx_fael_sent ON founder_artist_email_log(created_at)').run();
}
export async function onRequestPost(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;
    const env = context.env;
    if (!env.RESEND_API_KEY || !env.EMAIL_FROM) {
      return jsonResponse({success:false,error:'Artist email is not configured. Add RESEND_API_KEY and EMAIL_FROM to production.'},503);
    }
    const body = await context.request.json().catch(() => ({}));
    const artistId = String(body.artist_id || '').trim();
    const subject = String(body.subject || '').trim();
    const message = String(body.message || '').trim();
    const id = String(body.request_id || '').trim();
    if (!/^[-_a-z0-9]{8,120}$/i.test(artistId) || !/^[a-z0-9-]{24,80}$/i.test(id)
      || subject.length < 3 || subject.length > 140 || message.length < 3 || message.length > 4000) {
      return jsonResponse({success:false,error:'Select an artist and enter a subject (3–140 characters) and message (3–4,000 characters).'},400);
    }
    const db = env.DB;
    const artist = await db.prepare(`SELECT u.id, u.email, u.display_name, u.is_demo, u.is_active
      FROM artist_profiles ap JOIN users u ON u.id=ap.user_id
      WHERE ap.id=? LIMIT 1`).bind(artistId).first();
    const address = String(artist?.email || '').trim();
    if (!artist || !artist.is_active || artist.is_demo || address.toLowerCase().startsWith('unclaimed+')
      || !validEmail(address) || address.length > 254) {
      return jsonResponse({success:false,error:'This artist does not have an active, registered email address.'},400);
    }
    await ensureLog(db);
    const existing = await db.prepare('SELECT status FROM founder_artist_email_log WHERE id=?').bind(id).first();
    if (existing) return jsonResponse({success:false,error:'This email request was already submitted. Check delivery status before trying again.'},409);
    const lastHour = await db.prepare(`SELECT COUNT(*) AS n FROM founder_artist_email_log
      WHERE founder_id=? AND datetime(created_at)>datetime('now','-1 hour')`).bind(auth.user.id).first();
    const todayToArtist = await db.prepare(`SELECT COUNT(*) AS n FROM founder_artist_email_log
      WHERE artist_id=? AND datetime(created_at)>datetime('now','-1 day')`).bind(artistId).first();
    if (Number(lastHour?.n || 0)>=20 || Number(todayToArtist?.n || 0)>=3) {
      return jsonResponse({success:false,error:'Email sending limit reached. Please try later.'},429);
    }
    const now = new Date().toISOString();
    await db.prepare(`INSERT INTO founder_artist_email_log
      (id,founder_id,artist_id,recipient,subject,status,created_at)
      VALUES (?,?,?,?,?,'pending',?)`).bind(id,auth.user.id,artistId,address,subject,now).run();
    const name = String(artist.display_name || 'artist').split(/\\s+/)[0];
    const safeBody = esc(message).replace(/\\r?\\n/g,'<br>');
    const payload = {
      from: env.EMAIL_FROM,
      to: [address],
      subject,
      text: 'Hi '+name+',\\n\\n'+message+'\\n\\nThe Gearsh',
      html: '<p>Hi '+esc(name)+',</p><p>'+safeBody+'</p><p>The Gearsh</p>'
    };
    let response;
    try {
      response = await fetch('https://api.resend.com/emails',{
        method:'POST',
        headers:{Authorization:'Bearer '+env.RESEND_API_KEY,'Content-Type':'application/json','Idempotency-Key':id},
        body:JSON.stringify(payload)
      });
    } catch (_) {
      await db.prepare("UPDATE founder_artist_email_log SET status='failed' WHERE id=?").bind(id).run();
      return jsonResponse({success:false,error:'Email provider could not be reached. Nothing was confirmed sent.'},502);
    }
    if (!response.ok) {
      await db.prepare("UPDATE founder_artist_email_log SET status='failed' WHERE id=?").bind(id).run();
      return jsonResponse({success:false,error:'Email provider rejected the message. Check your sender-domain configuration.'},502);
    }
    const provider = await response.json().catch(()=>({}));
    await db.prepare("UPDATE founder_artist_email_log SET status='accepted',sent_at=?,provider_id=? WHERE id=?")
      .bind(new Date().toISOString(),String(provider.id||''),id).run();
    return jsonResponse({success:true,data:{recipient:address,status:'accepted'}},201);
  } catch(err) {
    console.error('Founder artist email send failed',err);
    return jsonResponse({success:false,error:'Unable to send artist email.'},500);
  }
}
export async function onRequestOptions(){return corsPreflightResponse();}
