// Shared helpers for booking lessons from artists — the founding use case of
// Gearsh ("gear" + "sharing"): learn a craft 1-on-1 using the gear an artist
// already owns, that the student may not have access to.
//
// Lessons reuse the showcase artist pool. Each artist's discipline maps to a set
// of lesson offerings (with the gear involved, level, format, and an accessible
// hourly tutoring rate). Bookings can target a claimed artist (tutor_id) or an
// unclaimed showcase profile (tutor_username only), surfacing once they join.

import { SA_SHOWCASE_ARTISTS } from './sa-showcase-data.js';
import { findShowcaseArtist } from './showcase-profile.js';

export const LESSON_DISCIPLINES = [
  { id: 'dj', label: 'DJing', icon: 'ti-disc' },
  { id: 'production', label: 'Music Production', icon: 'ti-adjustments' },
  { id: 'vocals', label: 'Vocals & Singing', icon: 'ti-microphone-2' },
  { id: 'songwriting', label: 'Songwriting', icon: 'ti-pencil' },
  { id: 'rap', label: 'Rap & Lyricism', icon: 'ti-microphone' },
  { id: 'instrument', label: 'Instruments', icon: 'ti-guitar-pick' },
  { id: 'dance', label: 'Dance', icon: 'ti-yoga' },
  { id: 'photography', label: 'Photography', icon: 'ti-camera' },
  { id: 'videography', label: 'Videography & Editing', icon: 'ti-video' },
  { id: 'visual_art', label: 'Visual Art & Design', icon: 'ti-palette' },
  { id: 'mentorship', label: 'Artist Mentorship', icon: 'ti-school' },
];

const DISCIPLINE_IDS = new Set(LESSON_DISCIPLINES.map(function (d) { return d.id; }));
export function isValidDiscipline(value) {
  return DISCIPLINE_IDS.has(String(value || ''));
}

export const LESSON_FORMATS = ['in_person', 'online'];
export const LESSON_STATUSES = ['pending', 'accepted', 'scheduled', 'declined', 'completed', 'cancelled'];

export function newId(prefix) {
  return prefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 9);
}

// ---------------------------------------------------------------------------
// Map an artist's category/genre to the discipline(s) they can teach.
// ---------------------------------------------------------------------------

export function disciplineForArtist(artist) {
  const hay = (String(artist.category || '') + ' ' + String(artist.genre || '') + ' ' +
    (Array.isArray(artist.skills) ? artist.skills.join(' ') : '')).toLowerCase();

  if (/(dj|amapiano|house|gqom|deep house|afro tech|piano)/.test(hay)) return 'dj';
  if (/(produc|beat|sound engineer|mixing|mastering)/.test(hay)) return 'production';
  if (/(gospel|soul|rnb|r&b|vocal|sing|afro pop|pop)/.test(hay)) return 'vocals';
  if (/(songwrit|writer|compos)/.test(hay)) return 'songwriting';
  if (/(rap|hip hop|hip-hop|trap|lyric|mc)/.test(hay)) return 'rap';
  if (/(guitar|piano|keys|drum|bass|sax|trumpet|instrument|band|maskandi|jazz)/.test(hay)) return 'instrument';
  if (/(dance|choreo)/.test(hay)) return 'dance';
  if (/(photo)/.test(hay)) return 'photography';
  if (/(video|film|cinema|edit|content)/.test(hay)) return 'videography';
  if (/(art|paint|design|graphic|visual|fashion|makeup|tattoo)/.test(hay)) return 'visual_art';
  return 'mentorship';
}

// Accessible hourly tutoring rate — lessons are about access, not headline fees,
// so this is tiered by experience and kept far below performance booking rates.
export function lessonHourlyRate(artist) {
  const hours = Number(artist.masteryHours || 0);
  if (hours >= 7500) return 1200;
  if (hours >= 5000) return 900;
  if (hours >= 3000) return 650;
  if (hours >= 1000) return 450;
  return 300;
}

// Per-discipline lesson catalogue. Each entry describes what's taught and the
// gear the student gets hands-on with — the core of the gear-sharing promise.
const LESSON_TEMPLATES = {
  dj: {
    gear: ['Pioneer CDJs / DDJ controller', 'DJM mixer', 'Studio monitors', 'Headphones'],
    lessons: [
      { title: 'DJ fundamentals', level: 'Beginner', hours: 1.5, desc: 'Decks, controllers and mixer basics — get hands-on with real club gear from your first session.' },
      { title: 'Beatmatching & mixing', level: 'Intermediate', hours: 2, desc: 'Phrasing, EQ blends, and seamless transitions on CDJs.' },
      { title: 'Build & record a DJ set', level: 'All levels', hours: 2, desc: 'Plan, perform and record a full set you can release.' },
    ],
  },
  production: {
    gear: ['Studio monitors', 'MIDI keyboard', 'Audio interface', 'DAW (FL Studio / Ableton / Logic)'],
    lessons: [
      { title: 'Beat-making foundations', level: 'Beginner', hours: 2, desc: 'Build your first beat from scratch on a pro studio setup.' },
      { title: 'Arrangement & sound design', level: 'Intermediate', hours: 2, desc: 'Turn loops into full records — structure, layering, and texture.' },
      { title: 'Mixing in the studio', level: 'Advanced', hours: 2, desc: 'Get a release-ready mix using the studio monitors and outboard gear.' },
    ],
  },
  vocals: {
    gear: ['Studio condenser mic', 'Vocal booth', 'Audio interface', 'Monitoring setup'],
    lessons: [
      { title: 'Vocal technique & breath', level: 'Beginner', hours: 1, desc: 'Pitch, breath control, and warm-ups for a stronger voice.' },
      { title: 'Studio recording session', level: 'All levels', hours: 1.5, desc: 'Record vocals properly in a real booth with pro mics.' },
      { title: 'Performance & stage presence', level: 'Intermediate', hours: 1.5, desc: 'Command a room — delivery, ad-libs, and confidence.' },
    ],
  },
  songwriting: {
    gear: ['Studio setup', 'Reference library', 'Recording rig'],
    lessons: [
      { title: 'Songwriting & topline', level: 'Beginner', hours: 1.5, desc: 'Hooks, melody, and structure that lands.' },
      { title: 'Lyric craft', level: 'Intermediate', hours: 1.5, desc: 'Storytelling, imagery, and rhyme that connects.' },
      { title: 'Write & demo a song', level: 'All levels', hours: 2, desc: 'Leave with a finished, recorded song idea.' },
    ],
  },
  rap: {
    gear: ['Studio condenser mic', 'Vocal booth', 'Beats & instrumentals'],
    lessons: [
      { title: 'Flow & delivery', level: 'Beginner', hours: 1, desc: 'Cadence, pockets, and breath control over any beat.' },
      { title: 'Writing & freestyle', level: 'Intermediate', hours: 1.5, desc: 'Punchlines, schemes, and writing fast.' },
      { title: 'Record your verse', level: 'All levels', hours: 1.5, desc: 'Lay and comp a verse in a real booth.' },
    ],
  },
  instrument: {
    gear: ['Instrument provided', 'Amp / monitoring', 'Studio space'],
    lessons: [
      { title: 'Instrument basics', level: 'Beginner', hours: 1, desc: 'Start playing on quality gear, no instrument needed.' },
      { title: 'Technique & theory', level: 'Intermediate', hours: 1.5, desc: 'Build real skill — scales, timing, and feel.' },
      { title: 'Play a song end-to-end', level: 'All levels', hours: 1.5, desc: 'Learn and perform a full track.' },
    ],
  },
  dance: {
    gear: ['Studio / rehearsal space', 'Sound system', 'Mirrors'],
    lessons: [
      { title: 'Choreography basics', level: 'Beginner', hours: 1, desc: 'Foundational moves and musicality.' },
      { title: 'Routine & performance', level: 'Intermediate', hours: 1.5, desc: 'Learn a full routine ready to perform or film.' },
      { title: 'Style intensive', level: 'All levels', hours: 2, desc: 'Deep-dive a style — amapiano, hip hop, or your pick.' },
    ],
  },
  photography: {
    gear: ['Pro camera body & lenses', 'Studio lighting', 'Lightroom / editing rig'],
    lessons: [
      { title: 'Camera & composition', level: 'Beginner', hours: 1.5, desc: 'Shoot manual on a pro body — light, framing, and focus.' },
      { title: 'Studio lighting', level: 'Intermediate', hours: 2, desc: 'Hands-on with strobes and modifiers in a real studio.' },
      { title: 'Editing & retouching', level: 'All levels', hours: 1.5, desc: 'Develop and retouch your shots like a pro.' },
    ],
  },
  videography: {
    gear: ['Cinema camera & lenses', 'Gimbal & lighting', 'Premiere / DaVinci editing rig'],
    lessons: [
      { title: 'Filming fundamentals', level: 'Beginner', hours: 1.5, desc: 'Shoot cinematic footage on pro gear.' },
      { title: 'Music video production', level: 'Intermediate', hours: 2, desc: 'Plan and shoot a performance video.' },
      { title: 'Editing & colour', level: 'All levels', hours: 2, desc: 'Cut and grade on a real editing setup.' },
    ],
  },
  visual_art: {
    gear: ['Studio space & tools', 'Wacom / iPad', 'Design software'],
    lessons: [
      { title: 'Fundamentals session', level: 'Beginner', hours: 1.5, desc: 'Core techniques on professional tools.' },
      { title: 'Project workshop', level: 'Intermediate', hours: 2, desc: 'Build a real piece start to finish.' },
      { title: 'Portfolio review & direction', level: 'All levels', hours: 1, desc: 'Sharpen your work and creative direction.' },
    ],
  },
  mentorship: {
    gear: ['Industry insight', 'Studio access', 'Networks'],
    lessons: [
      { title: '1-on-1 mentorship', level: 'All levels', hours: 1, desc: 'Career guidance from someone who has done it.' },
      { title: 'Craft masterclass', level: 'Intermediate', hours: 1.5, desc: 'A focused deep-dive into their craft.' },
      { title: 'Strategy & growth session', level: 'All levels', hours: 1, desc: 'Plan releases, brand, and the next move.' },
    ],
  },
};

// Build the lesson offerings for an artist, priced from their tutoring rate.
export function buildArtistLessons(artist) {
  const discipline = disciplineForArtist(artist);
  const template = LESSON_TEMPLATES[discipline] || LESSON_TEMPLATES.mentorship;
  const rate = lessonHourlyRate(artist);
  const username = String(artist.username || 'artist');

  return template.lessons.map(function (l, i) {
    return {
      id: 'lesson_' + username + '_' + (i + 1),
      title: l.title,
      description: l.desc,
      level: l.level,
      duration_hours: l.hours,
      price: Math.round(rate * l.hours),
      gear: template.gear,
    };
  });
}

export function lessonDisciplineLabel(id) {
  const d = LESSON_DISCIPLINES.find(function (x) { return x.id === id; });
  return d ? d.label : 'Lessons';
}

// ---------------------------------------------------------------------------
// Schema
// ---------------------------------------------------------------------------

export async function ensureLessonTables(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS lesson_bookings (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      tutor_id TEXT,
      tutor_username TEXT,
      tutor_name TEXT,
      discipline TEXT,
      lesson_title TEXT,
      level TEXT,
      format TEXT DEFAULT 'in_person',
      location TEXT,
      hourly_rate REAL,
      duration_hours REAL DEFAULT 1,
      sessions INTEGER DEFAULT 1,
      preferred_times TEXT,
      message TEXT,
      status TEXT DEFAULT 'pending',
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  `).run();

  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_lesson_student ON lesson_bookings(student_id)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_lesson_tutor ON lesson_bookings(tutor_id)`).run();
  await db.prepare(`CREATE INDEX IF NOT EXISTS idx_lesson_tutor_username ON lesson_bookings(tutor_username)`).run();
}

// ---------------------------------------------------------------------------
// Resolution + access
// ---------------------------------------------------------------------------

// Resolve a tutor by username to a user account (if claimed) plus display name.
export async function resolveTutor(db, username) {
  const handle = String(username || '').trim().toLowerCase();
  if (!handle) return null;

  const user = await db.prepare(`
    SELECT id, display_name, first_name, last_name, username
    FROM users WHERE LOWER(username) = ? AND is_active = 1
  `).bind(handle).first();

  if (user) {
    return {
      tutor_id: user.id,
      tutor_username: user.username || handle,
      tutor_name: user.display_name || [user.first_name, user.last_name].filter(Boolean).join(' ') || handle,
      claimed: true,
    };
  }

  const showcase = findShowcaseArtist(handle);
  if (showcase) {
    return {
      tutor_id: null,
      tutor_username: showcase.username,
      tutor_name: showcase.name,
      claimed: false,
    };
  }

  return null;
}

export function userOnLesson(row, userId) {
  if (!row) return false;
  return row.student_id === userId || row.tutor_id === userId;
}

export { SA_SHOWCASE_ARTISTS };
