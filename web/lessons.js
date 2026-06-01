/* Gearsh — Book lessons from artists (the founding "gear sharing" use case) */
(function () {
  'use strict';

  var API = '/api';
  var state = { discipline: '', tutors: [], activeTutor: null };

  function getToken() { return localStorage.getItem('gearsh_token') || ''; }
  function isAuthed() { return Boolean(getToken()); }
  function el(id) { return document.getElementById(id); }

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
  function money(v) { return 'R' + Number(v || 0).toLocaleString('en-ZA', { maximumFractionDigits: 0 }); }
  function timeAgo(ts) {
    if (!ts) return '';
    var d = new Date(ts);
    if (isNaN(d.getTime())) return '';
    return d.toLocaleDateString('en-ZA', { day: 'numeric', month: 'short' });
  }
  function debounce(fn, ms) {
    var t;
    return function () { var a = arguments, c = this; clearTimeout(t); t = setTimeout(function () { fn.apply(c, a); }, ms); };
  }

  function api(path, opts) {
    opts = opts || {};
    var headers = opts.headers || {};
    if (opts.body) headers['Content-Type'] = 'application/json';
    var token = getToken();
    if (token) headers.Authorization = 'Bearer ' + token;
    return fetch(API + path, {
      method: opts.method || 'GET', headers: headers,
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    }).then(function (r) {
      return r.json().then(function (d) {
        if (!r.ok || !d.success) throw new Error(d.error || 'Request failed');
        return d;
      });
    });
  }

  // ---- Discover -----------------------------------------------------------

  function loadDiscover() {
    var q = (el('lsn-search').value || '').trim();
    var path = '/lessons?limit=60';
    if (q) path += '&q=' + encodeURIComponent(q);
    if (state.discipline) path += '&discipline=' + encodeURIComponent(state.discipline);

    el('lsn-discover-body').innerHTML = '<div class="lsn-empty">Loading tutors…</div>';
    api(path).then(function (res) {
      var data = res.data || {};
      state.tutors = data.tutors || [];
      renderChips(data.disciplines || []);
      renderTutors(state.tutors);
    }).catch(function () {
      el('lsn-discover-body').innerHTML = '<div class="lsn-empty">Couldn\u2019t load tutors. Try again.</div>';
    });
  }

  function renderChips(disciplines) {
    var box = el('lsn-chips');
    var chips = ['<button class="lsn-chip ' + (state.discipline ? '' : 'active') + '" data-d="">All</button>'];
    disciplines.forEach(function (d) {
      if (!d.count) return;
      chips.push('<button class="lsn-chip ' + (state.discipline === d.id ? 'active' : '') + '" data-d="' + d.id + '">' +
        '<i class="ti ' + d.icon + '"></i> ' + escapeHtml(d.label) + ' <span class="cnt">' + d.count + '</span></button>');
    });
    box.innerHTML = chips.join('');
    box.querySelectorAll('.lsn-chip').forEach(function (c) {
      c.addEventListener('click', function () {
        state.discipline = c.getAttribute('data-d');
        loadDiscover();
      });
    });
  }

  function tutorCard(t) {
    var lessons = (t.lessons || []).map(function (l) {
      return '<div class="lsn-offering"><span>' + escapeHtml(l.title) +
        ' <span class="lvl">· ' + escapeHtml(l.level) + ' · ' + l.duration_hours + 'h</span></span>' +
        '<b>' + money(l.price) + '</b></div>';
    }).join('');
    var gear = (t.gear || []).slice(0, 3).join(' · ');
    return '<div class="lsn-card">' +
      '<div class="lsn-card-top">' +
        '<img src="' + escapeHtml(t.image) + '" alt="" loading="lazy" onerror="this.src=\'assets/images/artists/artists.png\'">' +
        '<div><div class="lsn-card-name">' + escapeHtml(t.name) + '</div>' +
        '<div class="lsn-card-meta">' + escapeHtml((t.genre || t.category || '') + (t.location ? ' · ' + t.location : '')) + '</div>' +
        '<span class="lsn-discipline">' + escapeHtml(t.discipline_label) + '</span></div>' +
      '</div>' +
      '<div class="lsn-card-body">' +
        (gear ? '<div class="lsn-gear"><i class="ti ti-device-speaker"></i><span>Learn on: ' + escapeHtml(gear) + '</span></div>' : '') +
        '<div class="lsn-offerings">' + lessons + '</div>' +
      '</div>' +
      '<div class="lsn-card-foot">' +
        '<div class="lsn-from">from <b>' + money(t.from_price) + '</b></div>' +
        '<button class="lsn-btn" data-book="' + escapeHtml(t.username) + '">Book a lesson</button>' +
      '</div>' +
    '</div>';
  }

  function renderTutors(tutors) {
    var body = el('lsn-discover-body');
    if (!tutors.length) {
      body.innerHTML = '<div class="lsn-empty">No tutors match that. Try a different discipline or search.</div>';
      return;
    }
    body.innerHTML = '<div class="lsn-grid">' + tutors.map(tutorCard).join('') + '</div>';
    body.querySelectorAll('[data-book]').forEach(function (btn) {
      btn.addEventListener('click', function () { openBook(btn.getAttribute('data-book')); });
    });
  }

  // ---- Book modal ---------------------------------------------------------

  function openBook(username, name) {
    if (!isAuthed()) {
      window.location.href = 'auth.html?next=' + encodeURIComponent('lessons.html?tutor=' + username);
      return;
    }
    var tutor = state.tutors.filter(function (t) { return t.username === username; })[0];
    if (!tutor) {
      // Fetch on demand if not in the current list (e.g. deep link).
      api('/lessons?q=' + encodeURIComponent(username) + '&limit=10').then(function (res) {
        var match = (res.data.tutors || []).filter(function (t) { return t.username === username; })[0];
        if (match) { fillBook(match); }
        else { fillBook({ username: username, name: name || username, lessons: [], hourly_rate: 0, discipline: '' }); }
      });
      return;
    }
    fillBook(tutor);
  }

  function fillBook(tutor) {
    state.activeTutor = tutor;
    el('book-tutor').textContent = 'with ' + (tutor.name || tutor.username);
    var sel = el('bk-lesson');
    sel.innerHTML = (tutor.lessons || []).map(function (l) {
      return '<option value="' + escapeHtml(l.title) + '" data-price="' + l.price + '" data-hours="' + l.duration_hours + '" data-level="' + escapeHtml(l.level) + '">' +
        escapeHtml(l.title) + ' — ' + money(l.price) + '</option>';
    }).join('') || '<option value="1-on-1 lesson" data-price="0" data-hours="1" data-level="All levels">1-on-1 lesson</option>';
    el('book-msg').textContent = '';
    el('book-msg').className = 'lsn-msg';
    el('bk-sessions').value = 1;
    updateEstimate();
    el('book-modal').classList.add('open');
  }

  function updateEstimate() {
    var opt = el('bk-lesson').options[el('bk-lesson').selectedIndex];
    if (!opt) { el('bk-est').innerHTML = ''; return; }
    var price = Number(opt.getAttribute('data-price') || 0);
    var sessions = Math.max(1, Number(el('bk-sessions').value || 1));
    var total = price * sessions;
    el('bk-est').innerHTML = sessions > 1
      ? 'Estimated total: <b>' + money(total) + '</b> <span style="color:var(--g-text-dim)">(' + sessions + ' × ' + money(price) + ')</span>'
      : 'Estimated: <b>' + money(price) + '</b> per session';
  }

  function closeBook() { el('book-modal').classList.remove('open'); }

  function submitBook(e) {
    e.preventDefault();
    var tutor = state.activeTutor;
    if (!tutor) return;
    var opt = el('bk-lesson').options[el('bk-lesson').selectedIndex];
    var msg = el('book-msg');
    msg.className = 'lsn-msg';
    msg.textContent = '';

    var btn = el('book-submit');
    btn.disabled = true; btn.textContent = 'Sending…';

    api('/lessons', {
      method: 'POST',
      body: {
        tutor_username: tutor.username,
        discipline: tutor.discipline || '',
        lesson_title: opt ? opt.value : '',
        level: opt ? opt.getAttribute('data-level') : 'All levels',
        hourly_rate: tutor.hourly_rate || 0,
        duration_hours: opt ? Number(opt.getAttribute('data-hours') || 1) : 1,
        sessions: Number(el('bk-sessions').value || 1),
        format: el('bk-format').value,
        preferred_times: el('bk-times').value,
        message: el('bk-message').value,
      },
    }).then(function (res) {
      msg.className = 'lsn-msg ok';
      msg.textContent = res.data && res.data.claimed === false
        ? 'Request sent! ' + tutor.name + ' will be invited to Gearsh to accept it.'
        : 'Lesson request sent! You\u2019ll hear back from ' + tutor.name + ' soon.';
      el('book-form').reset();
      setTimeout(function () { closeBook(); loadMine(); switchView('booked'); }, 1400);
    }).catch(function (err) {
      msg.className = 'lsn-msg error';
      msg.textContent = err.message;
    }).finally(function () {
      btn.disabled = false; btn.textContent = 'Request lesson';
    });
  }

  // ---- My lessons / Teaching ---------------------------------------------

  function loadMine() {
    if (!isAuthed()) {
      var note = '<div class="lsn-empty">Sign in to see your lessons.</div>';
      el('lsn-booked-body').innerHTML = note;
      el('lsn-teaching-body').innerHTML = note;
      return;
    }
    api('/lessons/mine').then(function (res) {
      var d = res.data || {};
      renderRows(el('lsn-booked-body'), d.sent || [], 'student');
      renderRows(el('lsn-teaching-body'), d.received || [], 'tutor');
      setBadge('badge-booked', (d.sent || []).filter(activeish).length);
      setBadge('badge-teaching', (d.received || []).filter(function (r) { return r.status === 'pending'; }).length);
    }).catch(function () {});
  }

  function activeish(r) { return ['pending', 'accepted', 'scheduled'].indexOf(r.status) !== -1; }

  function setBadge(id, n) {
    var b = el(id);
    if (!b) return;
    if (n > 0) { b.textContent = n; b.classList.remove('hidden'); }
    else { b.classList.add('hidden'); }
  }

  function rowActions(r) {
    var btns = [];
    if (r.role === 'tutor') {
      if (r.status === 'pending') {
        btns.push('<button class="lsn-mini primary" data-act="accept" data-id="' + r.id + '">Accept</button>');
        btns.push('<button class="lsn-mini" data-act="decline" data-id="' + r.id + '">Decline</button>');
      } else if (r.status === 'accepted') {
        btns.push('<button class="lsn-mini primary" data-act="schedule" data-id="' + r.id + '">Schedule</button>');
      } else if (r.status === 'scheduled') {
        btns.push('<button class="lsn-mini primary" data-act="complete" data-id="' + r.id + '">Mark complete</button>');
      }
    }
    if (r.role === 'student' && activeish(r)) {
      btns.push('<button class="lsn-mini" data-act="cancel" data-id="' + r.id + '">Cancel</button>');
    }
    return btns.join('');
  }

  function renderRows(container, rows, role) {
    if (!rows.length) {
      container.innerHTML = '<div class="lsn-empty">' +
        (role === 'tutor' ? 'No lesson requests yet.' : 'You haven\u2019t booked any lessons yet.') + '</div>';
      return;
    }
    container.innerHTML = rows.map(function (r) {
      var who = role === 'tutor'
        ? ('Student: ' + escapeHtml(r.student_name || 'Someone'))
        : ('with ' + escapeHtml(r.tutor_name || r.tutor_username));
      var total = (r.hourly_rate && r.duration_hours)
        ? money(r.hourly_rate * r.duration_hours * (r.sessions || 1)) : '';
      return '<div class="lsn-row">' +
        '<div><h4>' + escapeHtml(r.lesson_title) + (total ? ' · <span style="color:var(--g-accent)">' + total + '</span>' : '') + '</h4>' +
        '<div class="sub">' + who + ' · ' + escapeHtml(r.format === 'online' ? 'Online' : 'In person') +
        (r.sessions > 1 ? ' · ' + r.sessions + ' sessions' : '') + ' · ' + timeAgo(r.created_at) + '</div></div>' +
        '<div class="lsn-row-actions"><span class="lsn-status ' + r.status + '">' + r.status + '</span>' + rowActions(r) + '</div>' +
      '</div>';
    }).join('');
    container.querySelectorAll('[data-act]').forEach(function (btn) {
      btn.addEventListener('click', function () { doAction(btn.getAttribute('data-id'), btn.getAttribute('data-act')); });
    });
  }

  function doAction(id, action) {
    var body = { action: action };
    if (action === 'schedule') {
      var when = prompt('When is the lesson? (e.g. Sat 14 Jun, 3pm)');
      if (when == null) return;
      body.scheduled_time = when;
    }
    if (action === 'cancel' && !confirm('Cancel this lesson?')) return;
    if (action === 'decline' && !confirm('Decline this request?')) return;
    api('/lessons/' + id, { method: 'PATCH', body: body })
      .then(function () { loadMine(); })
      .catch(function (err) { alert(err.message); });
  }

  // ---- Views --------------------------------------------------------------

  function switchView(view) {
    document.querySelectorAll('.lsn-tab').forEach(function (t) {
      t.classList.toggle('active', t.getAttribute('data-view') === view);
    });
    document.querySelectorAll('.lsn-view').forEach(function (v) {
      v.classList.toggle('active', v.getAttribute('data-view') === view);
    });
    if (view === 'booked' || view === 'teaching') loadMine();
  }

  function boot() {
    if (isAuthed()) {
      var link = el('nav-auth-link');
      if (link) { link.textContent = 'Dashboard'; link.href = 'artist-dashboard.html'; }
    }

    el('lsn-tabs').addEventListener('click', function (e) {
      var tab = e.target.closest('.lsn-tab');
      if (tab) switchView(tab.getAttribute('data-view'));
    });
    el('lsn-search').addEventListener('input', debounce(loadDiscover, 350));
    el('book-form').addEventListener('submit', submitBook);
    el('bk-lesson').addEventListener('change', updateEstimate);
    el('bk-sessions').addEventListener('input', updateEstimate);
    el('book-modal').addEventListener('click', function (e) {
      if (e.target === el('book-modal')) closeBook();
    });

    loadDiscover();
    loadMine();

    // Deep link: ?tutor=username opens the booking modal.
    var params = new URLSearchParams(window.location.search);
    var tutor = params.get('tutor');
    if (tutor) openBook(tutor, params.get('name') || tutor);
    var view = params.get('view');
    if (view) switchView(view);
  }

  window.GearshLessons = { closeBook: closeBook, openBook: openBook };

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
