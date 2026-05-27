// Weekly genre rotation for The Gearsh.
//
// Single source of truth for "what is tonight?" across the marketing page,
// search, artists list, and the /tonight redirect. Loaded as a defer script
// before any feed/rail logic that needs to know today's genre.
//
// Cutover hour is 03:00 SAST — late-night browsing (e.g. 02:30 SAST Tuesday)
// still reads as "Monday tonight" so club-goers see the same genre they were
// dancing to. Africa/Johannesburg is UTC+2 year-round (no DST).
//
// Days are JS weekdays: Sunday=0, Monday=1, ..., Saturday=6.
(function () {
  'use strict';

  var SCHEDULE = {
    0: {
      slug: 'gospel',
      title: 'Sunday Gospel',
      tagline: 'Sundays are sacred.',
      icon: 'ti ti-pray',
    },
    1: {
      slug: 'xigaza-lekompo',
      title: 'Limpopo Night',
      tagline: 'From the soil. Xigaza ne Lekompo.',
      icon: 'ti ti-flame',
      secondaryLocation: 'Limpopo',
    },
    2: {
      slug: 'hip-hop',
      title: 'Hip Hop Tuesday',
      tagline: 'Bars before bed.',
      icon: 'ti ti-microphone',
    },
    3: {
      slug: 'house',
      title: 'Deep House Wednesday',
      tagline: 'Wednesdays go deep.',
      icon: 'ti ti-vinyl',
    },
    4: {
      slug: 'afropop',
      title: 'Smooth Thursday',
      tagline: 'Afropop, soul and R&B.',
      icon: 'ti ti-heart',
    },
    5: {
      slug: 'gqom',
      title: 'Gqom Friday',
      tagline: 'Friday hits different in Durban.',
      icon: 'ti ti-bolt',
    },
    6: {
      slug: 'amapiano',
      title: 'Amapiano Saturday',
      tagline: 'Saturdays are Piano.',
      icon: 'ti ti-piano',
    },
  };

  var CUTOVER_HOUR = 3;
  var SAST_OFFSET_MIN = 120;

  function computeWeekday(now) {
    // n.getTime() is already epoch-UTC ms regardless of the visitor's local
    // timezone, so we add 120 min to land in SAST then subtract the cutover
    // hour so 02:59 SAST still reads as the previous day.
    var n = now || new Date();
    var sastMs = n.getTime() + SAST_OFFSET_MIN * 60000 - CUTOVER_HOUR * 3600000;
    return new Date(sastMs).getUTCDay();
  }

  function today(now) {
    var weekday = computeWeekday(now);
    var entry = SCHEDULE[weekday] || SCHEDULE[0];
    return {
      weekday: weekday,
      slug: entry.slug,
      title: entry.title,
      tagline: entry.tagline,
      icon: entry.icon,
      secondaryLocation: entry.secondaryLocation || null,
    };
  }

  function week() {
    var out = [];
    for (var i = 0; i < 7; i += 1) out.push(SCHEDULE[i]);
    return out;
  }

  window.GearshSchedule = {
    cutoverHour: CUTOVER_HOUR,
    schedule: SCHEDULE,
    today: today,
    week: week,
    computeWeekday: computeWeekday,
  };
}());
