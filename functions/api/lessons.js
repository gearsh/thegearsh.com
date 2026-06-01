// GET  /api/lessons?q=&discipline=&limit=  — tutors and their lesson offerings
// POST /api/lessons                         — book a lesson (auth required)
//
// The founding Gearsh use case: book lessons from artists and learn on the gear
// they own. Browse is public; booking creates a lesson_bookings row that works
// for both claimed tutors and unclaimed showcase profiles.

import { corsPreflightResponse, jsonResponse, requireAuth } from './auth-utils.js';
import { resolveShowcaseImage } from './showcase-profile.js';
import {
  SA_SHOWCASE_ARTISTS,
  LESSON_DISCIPLINES,
  buildArtistLessons,
  disciplineForArtist,
  lessonDisciplineLabel,
  lessonHourlyRate,
  isValidDiscipline,
  ensureLessonTables,
  resolveTutor,
  newId,
} from './lessons-utils.js';
import { scanMessage } from './message-guard.js';

function toTutorCard(artist) {
  const lessons = buildArtistLessons(artist);
  const discipline = disciplineForArtist(artist);
  const from = lessons.reduce(function (min, l) { return Math.min(min, l.price); }, Infinity);
  return {
    name: artist.name,
    username: artist.username,
    image: resolveShowcaseImage(artist) || artist.image || 'assets/images/artists/artists.png',
    category: artist.category,
    genre: artist.genre,
    location: artist.location,
    country: artist.country,
    badge: artist.badge,
    mastery_hours: artist.masteryHours || 0,
    discipline: discipline,
    discipline_label: lessonDisciplineLabel(discipline),
    hourly_rate: lessonHourlyRate(artist),
    from_price: isFinite(from) ? from : null,
    lessons: lessons,
    gear: (lessons[0] && lessons[0].gear) || [],
  };
}

export async function onRequestGet(context) {
  try {
    const url = new URL(context.request.url);
    const q = String(url.searchParams.get('q') || '').trim().toLowerCase();
    const discipline = String(url.searchParams.get('discipline') || '').trim().toLowerCase();
    const limit = Math.min(Number(url.searchParams.get('limit') || 60), 120);

    let pool = SA_SHOWCASE_ARTISTS.slice();

    if (discipline && isValidDiscipline(discipline)) {
      pool = pool.filter(function (a) { return disciplineForArtist(a) === discipline; });
    }

    if (q) {
      pool = pool.filter(function (a) {
        return (
          String(a.name || '').toLowerCase().includes(q) ||
          String(a.username || '').toLowerCase().includes(q) ||
          String(a.genre || '').toLowerCase().includes(q) ||
          String(a.category || '').toLowerCase().includes(q) ||
          String(a.location || '').toLowerCase().includes(q) ||
          lessonDisciplineLabel(disciplineForArtist(a)).toLowerCase().includes(q)
        );
      });
    }

    const cards = pool.slice(0, limit).map(toTutorCard);

    const byHours = SA_SHOWCASE_ARTISTS.slice().sort(function (a, b) {
      return (b.masteryHours || 0) - (a.masteryHours || 0);
    });

    // Count tutors per discipline for the filter chips.
    const counts = {};
    SA_SHOWCASE_ARTISTS.forEach(function (a) {
      const d = disciplineForArtist(a);
      counts[d] = (counts[d] || 0) + 1;
    });

    const sections = {
      top_tutors: byHours.slice(0, 8).map(toTutorCard),
      affordable: SA_SHOWCASE_ARTISTS.slice()
        .filter(function (a) { return Number(a.masteryHours || 0) < 3000; })
        .slice(0, 8).map(toTutorCard),
    };

    return jsonResponse({
      success: true,
      data: {
        tutors: cards,
        total: pool.length,
        disciplines: LESSON_DISCIPLINES.map(function (d) {
          return Object.assign({}, d, { count: counts[d.id] || 0 });
        }),
        sections: sections,
      },
    });
  } catch (err) {
    console.error('Lessons browse error:', err);
    return jsonResponse({ success: false, error: 'Failed to load lessons' }, 500);
  }
}

export async function onRequestPost(context) {
  try {
    await ensureLessonTables(context.env.DB);
    const auth = await requireAuth(context);
    if (auth.error) return auth.error;

    const body = await context.request.json().catch(function () { return {}; });
    const tutorUsername = String(body.tutor_username || body.username || '').trim();
    if (!tutorUsername) {
      return jsonResponse({ success: false, error: 'A tutor is required' }, 400);
    }

    const tutor = await resolveTutor(context.env.DB, tutorUsername);
    if (!tutor) {
      return jsonResponse({ success: false, error: 'Tutor not found' }, 404);
    }
    if (tutor.tutor_id && tutor.tutor_id === auth.userId) {
      return jsonResponse({ success: false, error: 'You cannot book a lesson with yourself' }, 400);
    }

    const lessonTitle = String(body.lesson_title || '').trim().slice(0, 200);
    if (!lessonTitle) {
      return jsonResponse({ success: false, error: 'Pick a lesson' }, 400);
    }

    const format = body.format === 'online' ? 'online' : 'in_person';
    const duration = Math.max(0.5, Math.min(Number(body.duration_hours || 1), 12));
    const sessions = Math.max(1, Math.min(parseInt(body.sessions, 10) || 1, 52));
    const rate = Math.max(0, Number(body.hourly_rate || 0));

    // Anti-leakage: redact any contact/payment details from the opening note.
    const rawMessage = String(body.message || '').slice(0, 4000);
    const scan = scanMessage(rawMessage);

    const id = newId('lsn');
    const now = new Date().toISOString();

    await context.env.DB.prepare(`
      INSERT INTO lesson_bookings (
        id, student_id, tutor_id, tutor_username, tutor_name, discipline, lesson_title,
        level, format, location, hourly_rate, duration_hours, sessions, preferred_times,
        message, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)
    `).bind(
      id, auth.userId, tutor.tutor_id, tutor.tutor_username, tutor.tutor_name,
      String(body.discipline || '').slice(0, 40),
      lessonTitle,
      String(body.level || 'All levels').slice(0, 40),
      format,
      String(body.location || '').slice(0, 200),
      rate,
      duration,
      sessions,
      String(body.preferred_times || '').slice(0, 300),
      scan.clean,
      now, now
    ).run();

    return jsonResponse({
      success: true,
      data: {
        id: id,
        status: 'pending',
        tutor_name: tutor.tutor_name,
        claimed: tutor.claimed,
      },
      redacted: scan.flagged,
      notice: scan.flagged
        ? 'Contact and payment details are hidden until your lesson is booked and paid through Gearsh.'
        : '',
    }, 201);
  } catch (err) {
    console.error('Lesson booking error:', err);
    return jsonResponse({ success: false, error: 'Failed to book lesson' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
