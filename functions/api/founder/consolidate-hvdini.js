// One-off founder-authorised migration: keep Hvdini's registered account and retire the unclaimed demo.
// Safe to repeat. Historic rows remain for audit; no accounts or bookings are deleted.
import { requireFounder } from '../founder-auth.js';
import { jsonResponse, corsPreflightResponse } from '../auth-utils.js';

export async function onRequestPost(context) {
  try {
    const auth = await requireFounder(context);
    if (auth.error) return auth.error;
    const body = await context.request.json().catch(() => ({}));
    if (body.confirm !== 'CONSOLIDATE_HVDINI') {
      return jsonResponse({success:false,error:'Explicit confirmation is required.'},400);
    }
    const db = context.env.DB;
    const rows = await db.prepare(`SELECT u.id AS user_id,u.email,u.username,u.is_demo,ap.id AS artist_id
      FROM users u JOIN artist_profiles ap ON ap.user_id=u.id
      WHERE LOWER(u.username) IN ('hvdini_mxgic','hvdini-mxgic')`).all();
    const found = rows.results || [];
    const registered = found.find(x => String(x.username).toLowerCase()==='hvdini_mxgic'
      && String(x.email).toLowerCase()==='hvdinigotmxgic@gmail.com' && !x.is_demo);
    const demo = found.find(x => String(x.username).toLowerCase()==='hvdini-mxgic'
      && x.is_demo && String(x.email).toLowerCase().startsWith('unclaimed+'));
    if (!registered) return jsonResponse({success:false,error:'Registered Hvdini account not found or identity mismatch. No changes made.'},409);
    const legacyAccount = found.find(x => String(x.username).toLowerCase()==='hvdini-mxgic');
    if (legacyAccount && !demo) return jsonResponse({
      success:false,error:'Legacy slug belongs to a claimed or non-demo account. Manual review required; no changes made.'
    },409);
    if (demo) {
      const bookings = await db.prepare('SELECT COUNT(*) AS n FROM bookings WHERE artist_id=?').bind(demo.artist_id).first();
      const reviews = await db.prepare('SELECT COUNT(*) AS n FROM reviews WHERE artist_id=?').bind(demo.artist_id).first();
      if (Number(bookings?.n||0)>0 || Number(reviews?.n||0)>0)
        return jsonResponse({success:false,error:'Demo has associated booking/review records. Review and migrate history before retiring.'},409);
    }
    const description='Indicative pricing — subject to artist confirmation. Travel and production quoted separately.';
    const offers=[
      ['svc_hvdini_live_30','Live performance (30 min)',1350,0.5],
      ['svc_hvdini_live_45','Live performance (45 min)',2250,0.75],
      ['svc_hvdini_live_60','Live performance (60 min)',3000,1]
    ];
    const now=new Date().toISOString();
    const queries=[
      db.prepare("UPDATE users SET location='Louis Trichardt',country='South Africa',updated_at=? WHERE id=?").bind(now,registered.user_id),
      db.prepare(`UPDATE artist_profiles SET category='Music',genre='Hip Hop · Rap',skills=?,
        base_rate=1350,hourly_rate=1350,updated_at=? WHERE id=?`)
        .bind(JSON.stringify(['Production','Videography','Music videos','Producer','Live music','Visual art']),now,registered.artist_id),
      db.prepare('UPDATE services SET is_active=0 WHERE artist_id=?').bind(registered.artist_id)
    ];
    for(const [id,name,price,hours] of offers){
      queries.push(db.prepare(`INSERT INTO services
        (id,artist_id,name,description,price,duration_hours,is_active,created_at,marketplace_category,price_type,search_keywords)
        VALUES (?,?,?,?,?,?,1,?,'musicians','fixed',?)
        ON CONFLICT(id) DO UPDATE SET name=excluded.name,description=excluded.description,
        price=excluded.price,duration_hours=excluded.duration_hours,is_active=1`)
      .bind(id,registered.artist_id,name,description,price,hours,now,'hip hop rap live performance'));
    }
    if (demo) {
      queries.push(db.prepare('UPDATE services SET is_active=0 WHERE artist_id=?').bind(demo.artist_id));
      queries.push(db.prepare('UPDATE users SET is_active=0,updated_at=? WHERE id=?').bind(now,demo.user_id));
    }
    await db.batch(queries);
    return jsonResponse({success:true,data:{
      retained_username:registered.username,retired_demo:Boolean(demo),services:offers.map(x=>({name:x[1],price:x[2]}))
    }});
  } catch(err){
    console.error('Hvdini consolidation failed',err);
    return jsonResponse({success:false,error:'Could not consolidate Hvdini profiles. Changes not confirmed.'},500);
  }
}
export async function onRequestOptions(){return corsPreflightResponse();}
