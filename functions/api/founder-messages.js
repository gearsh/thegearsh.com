// Founder-to-artist private messages, independent of bookings.
// GET lists the caller's threads and (founder only) available artists.
// POST sends to an artist username (founder) or replies to an existing thread (artist).
import { requireAuth, jsonResponse, corsPreflightResponse } from './auth-utils.js';

const FOUNDER_EMAIL = 'nhlanhla@thegearsh.com';
const founder = user => String(user.email || '').toLowerCase() === FOUNDER_EMAIL;
const validUsername = value => /^[a-z0-9_-]{2,40}$/.test(value);
async function ensure(db) {
  await db.prepare(`CREATE TABLE IF NOT EXISTS founder_artist_messages (
    id TEXT PRIMARY KEY, founder_id TEXT NOT NULL, artist_id TEXT NOT NULL,
    sender_id TEXT NOT NULL, body TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    read_at TEXT
  )`).run();
  await db.prepare('CREATE INDEX IF NOT EXISTS idx_fam_pair ON founder_artist_messages(founder_id, artist_id, created_at)').run();
}
async function founderUser(db) {
  return db.prepare('SELECT id FROM users WHERE LOWER(email) = ? AND is_active = 1 LIMIT 1').bind(FOUNDER_EMAIL).first();
}
export async function onRequestGet(context) {
  try {
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;
    const db = context.env.DB;
    await ensure(db);
    const isFounder = founder(auth.user);
    const owner = await founderUser(db);
    if (!owner) return jsonResponse({success:false,error:'Founder account unavailable'},503);
    const pairs = await db.prepare(`
      SELECT u.id AS artist_id, u.display_name AS artist_name, u.username AS artist_username,
       MAX(m.created_at) AS last_at,
       (SELECT body FROM founder_artist_messages x WHERE x.artist_id=u.id AND x.founder_id=?
          ORDER BY created_at DESC, id DESC LIMIT 1) AS last_message,
       SUM(CASE WHEN m.sender_id != ? AND m.read_at IS NULL THEN 1 ELSE 0 END) AS unread
      FROM founder_artist_messages m JOIN users u ON u.id=m.artist_id
      WHERE m.founder_id=? AND (?=1 OR m.artist_id=?)
      GROUP BY u.id, u.display_name, u.username ORDER BY last_at DESC
      LIMIT 100`).bind(owner.id,auth.userId,owner.id,isFounder?1:0,auth.userId).all();
    const target = String(new URL(context.request.url).searchParams.get('artist')||'').trim().toLowerCase();
    let messages=[];
    if(target && validUsername(target)) {
      const artist=await db.prepare(`SELECT u.id FROM users u JOIN artist_profiles ap ON ap.user_id=u.id
        WHERE LOWER(u.username)=? AND u.is_active=1 LIMIT 1`).bind(target).first();
      if(artist && (isFounder || artist.id===auth.userId)) {
        const result=await db.prepare(`SELECT sender_id,body,created_at,id FROM founder_artist_messages
          WHERE founder_id=? AND artist_id=? ORDER BY created_at ASC,id ASC LIMIT 200`).bind(owner.id,artist.id).all();
        messages=(result.results||[]).map(x=>({id:x.id,body:x.body,created_at:x.created_at,mine:x.sender_id===auth.userId}));
        await db.prepare(`UPDATE founder_artist_messages SET read_at=datetime('now')
          WHERE founder_id=? AND artist_id=? AND sender_id != ? AND read_at IS NULL`).bind(owner.id,artist.id,auth.userId).run();
      }
    }
    let artists=[];
    if(isFounder) {
      const list=await db.prepare(`SELECT u.username,u.display_name AS name FROM users u
        JOIN artist_profiles ap ON ap.user_id=u.id WHERE u.is_active=1
        AND u.id != ? AND u.username IS NOT NULL
        ORDER BY u.created_at DESC LIMIT 100`).bind(auth.userId).all();
      artists=list.results||[];
    }
    return jsonResponse({success:true,data:{is_founder:isFounder,conversations:pairs.results||[],artists,messages}});
  } catch(e) {console.error('Founder messages get failed',e);return jsonResponse({success:false,error:'Unable to load messages'},500);}
}
export async function onRequestPost(context) {
  try {
    const auth=await requireAuth(context);
    if(auth.error)return auth.error;
    const db=context.env.DB;
    await ensure(db);
    const owner=await founderUser(db);
    if(!owner)return jsonResponse({success:false,error:'Founder account unavailable'},503);
    const body=await context.request.json();
    const username=String(body.artist||'').trim().toLowerCase();
    const message=String(body.message||'').trim();
    if(!validUsername(username)||!message||message.length>2000)
      return jsonResponse({success:false,error:'Choose an artist and enter a message (maximum 2,000 characters)'},400);
    const artist=await db.prepare(`SELECT u.id FROM users u JOIN artist_profiles ap ON ap.user_id=u.id
       WHERE LOWER(u.username)=? AND u.is_active=1 LIMIT 1`).bind(username).first();
    if(!artist)return jsonResponse({success:false,error:'Artist not found'},404);
    const isFounder=founder(auth.user);
    if(!isFounder) {
      if(auth.userId!==artist.id)return jsonResponse({success:false,error:'Not authorised'},403);
      const prior=await db.prepare(`SELECT id FROM founder_artist_messages
        WHERE founder_id=? AND artist_id=? LIMIT 1`).bind(owner.id,artist.id).first();
      if(!prior)return jsonResponse({success:false,error:'No founder conversation to reply to'},403);
    }
    const id='fam_'+crypto.randomUUID();
    await db.prepare(`INSERT INTO founder_artist_messages
      (id,founder_id,artist_id,sender_id,body,created_at)
      VALUES (?,?,?,?,?,?)`).bind(id,owner.id,artist.id,auth.userId,message,new Date().toISOString()).run();
    // Notification is best-effort: saving the in-app message is authoritative.
    // Only notify an artist for a founder-originated message.
    let notification = 'not_applicable';
    if (isFounder) {
      notification = 'not_configured';
      if (context.env.RESEND_API_KEY && context.env.EMAIL_FROM) {
        const recipient = await db.prepare(`SELECT email, display_name, email_verified
          FROM users WHERE id=? AND is_active=1`).bind(artist.id).first();
        const address = String(recipient?.email || '').trim();
        if (recipient?.email_verified && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(address)
            && !address.toLowerCase().startsWith('unclaimed+')) {
          // One provider request per newly created message, keyed by its stable ID.
          const firstName = String(recipient.display_name || 'there').split(/\s+/)[0]
            .replace(/[&<>"']/g, '');
          const mail = {
            from: context.env.EMAIL_FROM,
            to: [address],
            subject: 'You have a new message from The Gearsh',
            html: '<p>Hi ' + firstName + ',</p>' +
              '<p>You have a new private message from the founder of The Gearsh.</p>' +
              '<p><a href="https://thegearsh.com/artist-dashboard.html#messages">Read and reply on The Gearsh</a></p>' +
              '<p>This notification does not contain the private message itself.</p>'
          };
          try {
            const response = await fetch('https://api.resend.com/emails', {
              method: 'POST',
              headers: {
                Authorization: 'Bearer ' + context.env.RESEND_API_KEY,
                'Content-Type': 'application/json',
                'Idempotency-Key': id
              },
              body: JSON.stringify(mail)
            });
            notification = response.ok ? 'sent' : 'failed';
            if (!response.ok) console.error('Founder message notification failed',response.status);
          } catch(e) {
            notification = 'failed';
            console.error('Founder message notification unavailable');
          }
        } else {
          notification = 'not_eligible';
        }
      }
    }
    return jsonResponse({success:true,data:{id,notification}},201);
  } catch(e) {console.error('Founder messages send failed',e);return jsonResponse({success:false,error:'Unable to send message'},500);}
}
export async function onRequestOptions(){return corsPreflightResponse();}
