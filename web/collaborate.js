/* Gearsh — Artist-to-artist collaboration hub */
(function () {
  'use strict';

  var API = '/api';

  var TYPES = [
    { id: 'music_feature', label: 'Music Feature', icon: 'ti-microphone' },
    { id: 'songwriting', label: 'Songwriting', icon: 'ti-pencil' },
    { id: 'production', label: 'Production', icon: 'ti-adjustments' },
    { id: 'visual_art', label: 'Visual Art', icon: 'ti-palette' },
    { id: 'graphic_design', label: 'Graphic Design', icon: 'ti-vector' },
    { id: 'photography', label: 'Photography', icon: 'ti-camera' },
    { id: 'videography', label: 'Videography', icon: 'ti-video' },
    { id: 'dance', label: 'Dance', icon: 'ti-yoga' },
    { id: 'event_appearance', label: 'Event Appearance', icon: 'ti-calendar-star' },
    { id: 'content', label: 'Content', icon: 'ti-device-tv' },
    { id: 'brand', label: 'Brand', icon: 'ti-building-store' },
    { id: 'mentorship', label: 'Mentorship', icon: 'ti-school' },
  ];
  var TYPE_LABEL = {};
  TYPES.forEach(function (t) { TYPE_LABEL[t.id] = t.label; });

  var state = { activeType: '', currentDetailId: null };

  function getToken() { return localStorage.getItem('gearsh_token') || ''; }
  function isAuthed() { return Boolean(getToken()); }

  function escapeHtml(str) {
    return String(str == null ? '' : str)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
  function money(v) {
    return 'R' + Number(v || 0).toLocaleString('en-ZA', { maximumFractionDigits: 0 });
  }
  function timeAgo(ts) {
    if (!ts) return '';
    var d = new Date(ts);
    if (isNaN(d.getTime())) return '';
    return d.toLocaleDateString('en-ZA', { day: 'numeric', month: 'short' });
  }

  function api(path, opts) {
    opts = opts || {};
    var headers = opts.headers || {};
    if (opts.body) headers['Content-Type'] = 'application/json';
    var token = getToken();
    if (token) headers.Authorization = 'Bearer ' + token;
    return fetch(API + path, {
      method: opts.method || 'GET',
      headers: headers,
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    }).then(function (r) {
      return r.json().then(function (d) {
        if (!r.ok || !d.success) throw new Error(d.error || 'Request failed');
        return d.data;
      });
    });
  }

  function el(id) { return document.getElementById(id); }

  function gate(message) {
    return '<div class="collab-gate"><h3>Sign in to continue</h3>' +
      '<p>' + escapeHtml(message || 'Log in to manage your collaborations.') + '</p>' +
      '<a class="btn-main" href="auth.html">Sign in to Gearsh</a></div>';
  }

  function statusPill(status) {
    var label = String(status || '').replace(/_/g, ' ');
    return '<span class="pill pill-' + escapeHtml(status) + '">' + escapeHtml(label) + '</span>';
  }

  // ---- View switching ---------------------------------------------------
  function switchView(name) {
    var tabs = document.querySelectorAll('.collab-tab');
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].classList.toggle('active', tabs[i].getAttribute('data-view') === name);
    }
    var views = document.querySelectorAll('.collab-view');
    for (var j = 0; j < views.length; j++) {
      views[j].classList.toggle('active', views[j].getAttribute('data-view') === name);
    }
    if (name === 'sent') loadBox('sent', 'collab-sent-body');
    else if (name === 'received') loadBox('received', 'collab-received-body');
    else if (name === 'active') loadBox('active', 'collab-active-body');
    else if (name === 'completed') loadBox('completed', 'collab-completed-body');
    else if (name === 'settings') loadSettings();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // ---- Discover ---------------------------------------------------------
  function renderTypeChips() {
    var box = el('collab-type-chips');
    var html = '<button class="collab-chip ' + (state.activeType === '' ? 'active' : '') + '" data-type="">All</button>';
    html += TYPES.map(function (t) {
      return '<button class="collab-chip ' + (state.activeType === t.id ? 'active' : '') + '" data-type="' + t.id + '">' +
        '<i class="ti ' + t.icon + '"></i> ' + escapeHtml(t.label) + '</button>';
    }).join('');
    box.innerHTML = html;
    box.querySelectorAll('.collab-chip').forEach(function (chip) {
      chip.addEventListener('click', function () {
        state.activeType = chip.getAttribute('data-type');
        renderTypeChips();
        loadDiscover();
      });
    });
  }

  function artistCard(a) {
    var fee = a.estimated_fee || {};
    var avail = a.availability || 'available';
    var availLabel = avail === 'limited' ? 'Limited' : (avail === 'fully_booked' ? 'Fully booked' : 'Available');
    return '<div class="collab-card">' +
      '<img class="collab-card-img" src="' + escapeHtml(a.image) + '" alt="' + escapeHtml(a.name) + '" loading="lazy" onerror="this.src=\'assets/images/artists/artists.png\'">' +
      '<div class="collab-card-body">' +
        '<div class="collab-card-name">' + escapeHtml(a.name) + '</div>' +
        '<div class="collab-card-meta">' + escapeHtml(a.genre || a.category || '') + '</div>' +
        '<span class="collab-avail ' + avail + '"><i class="ti ti-circle-filled"></i> ' + availLabel + '</span>' +
        '<div class="collab-fee-label">Estimated collaboration fee</div>' +
        '<div class="collab-fee-value">' + escapeHtml(fee.display || 'Custom Quote') + '</div>' +
        '<button class="collab-card-cta" type="button" data-username="' + escapeHtml(a.username) + '" data-name="' + escapeHtml(a.name) + '">' +
          '<i class="ti ti-sparkles"></i> Book Collaboration</button>' +
      '</div></div>';
  }

  function wireBookButtons(container) {
    container.querySelectorAll('.collab-card-cta').forEach(function (btn) {
      btn.addEventListener('click', function () {
        openBook(btn.getAttribute('data-username'), btn.getAttribute('data-name'));
      });
    });
  }

  function loadDiscover() {
    var body = el('collab-discover-body');
    body.innerHTML = '<p style="color:var(--g-text-dim)">Loading collaborators…</p>';
    var q = (el('collab-search').value || '').trim();
    var path = '/collaborators?limit=60';
    if (q) path += '&q=' + encodeURIComponent(q);
    if (state.activeType) path += '&type=' + encodeURIComponent(state.activeType);

    api(path).then(function (data) {
      var html = '';
      var showSections = !q && !state.activeType && data.sections;
      if (showSections) {
        var sec = data.sections;
        if (sec.trending && sec.trending.length) {
          html += '<div class="collab-section-title">Trending collaborators</div>';
          html += '<div class="collab-grid">' + sec.trending.map(artistCard).join('') + '</div>';
        }
        if (sec.recently_available && sec.recently_available.length) {
          html += '<div class="collab-section-title">Recently available</div>';
          html += '<div class="collab-grid">' + sec.recently_available.map(artistCard).join('') + '</div>';
        }
        html += '<div class="collab-section-title">All collaborators</div>';
      }
      if (data.artists && data.artists.length) {
        html += '<div class="collab-grid">' + data.artists.map(artistCard).join('') + '</div>';
      } else if (!showSections) {
        html += '<div class="collab-empty"><i class="ti ti-search-off"></i>No collaborators match your search.</div>';
      }
      body.innerHTML = html;
      wireBookButtons(body);
    }).catch(function (err) {
      body.innerHTML = '<div class="collab-empty"><i class="ti ti-alert-circle"></i>' + escapeHtml(err.message) + '</div>';
    });
  }

  // ---- Book modal -------------------------------------------------------
  function openBook(username, name) {
    if (!isAuthed()) {
      window.location.href = 'auth.html?next=' + encodeURIComponent('/collaborate.html');
      return;
    }
    var sel = el('bk-type');
    sel.innerHTML = '<option value="">Select type…</option>' + TYPES.map(function (t) {
      return '<option value="' + t.id + '">' + escapeHtml(t.label) + '</option>';
    }).join('');
    el('book-form').setAttribute('data-username', username);
    el('book-modal-recipient').textContent = 'with ' + (name || username);
    el('book-msg').textContent = '';
    el('book-msg').className = 'collab-msg';
    el('book-form').reset();
    el('book-modal').classList.add('open');
  }
  function closeBook() { el('book-modal').classList.remove('open'); }

  function submitBook(e) {
    e.preventDefault();
    var msg = el('book-msg');
    var refs = (el('bk-refs').value || '').split(',').map(function (s) { return s.trim(); }).filter(Boolean);
    var payload = {
      recipient_username: el('book-form').getAttribute('data-username'),
      project_name: el('bk-project').value.trim(),
      collaboration_type: el('bk-type').value,
      budget: el('bk-budget').value || null,
      deadline: el('bk-deadline').value || null,
      description: el('bk-description').value.trim(),
      deliverables: el('bk-deliverables').value.trim(),
      reference_links: refs,
    };
    var btn = el('book-submit');
    btn.disabled = true; btn.textContent = 'Sending…';
    api('/collaborations', { method: 'POST', body: payload }).then(function (data) {
      msg.className = 'collab-msg ok';
      msg.textContent = data.message || 'Request sent.';
      setTimeout(function () { closeBook(); switchView('sent'); }, 1400);
    }).catch(function (err) {
      msg.className = 'collab-msg error';
      msg.textContent = err.message;
    }).finally(function () {
      btn.disabled = false; btn.textContent = 'Send collaboration request';
    });
  }

  // ---- Request lists ----------------------------------------------------
  function requestRow(item) {
    var amount = item.agreed_amount || item.budget;
    return '<div class="collab-row" data-id="' + escapeHtml(item.id) + '">' +
      '<div class="collab-row-main">' +
        '<div class="collab-row-project">' + escapeHtml(item.project_name) + '</div>' +
        '<div class="collab-row-sub">' +
          (item.direction === 'sent' ? 'To ' : 'From ') + escapeHtml(item.counterpart_name || 'Artist') +
          ' · ' + escapeHtml(TYPE_LABEL[item.collaboration_type] || item.collaboration_type) + '</div>' +
        '<div class="collab-row-meta">' +
          (amount ? '<span><i class="ti ti-coin"></i> ' + money(amount) + '</span>' : '') +
          (item.deadline ? '<span><i class="ti ti-calendar"></i> ' + escapeHtml(item.deadline) + '</span>' : '') +
          '<span><i class="ti ti-clock"></i> ' + timeAgo(item.updated_at) + '</span>' +
        '</div>' +
      '</div>' +
      statusPill(item.status) +
    '</div>';
  }

  function loadBox(box, containerId) {
    var body = el(containerId);
    if (!isAuthed()) { body.innerHTML = gate('Log in to see your ' + box + ' collaborations.'); return; }
    body.innerHTML = '<p style="color:var(--g-text-dim)">Loading…</p>';
    api('/collaborations?box=' + box).then(function (items) {
      if (!items.length) {
        var emptyText = {
          sent: 'You have not sent any collaboration requests yet.',
          received: 'No collaboration requests received yet.',
          active: 'No active collaborations right now.',
          completed: 'No completed collaborations yet.',
        }[box] || 'Nothing here yet.';
        body.innerHTML = '<div class="collab-empty"><i class="ti ti-mood-empty"></i>' + emptyText + '</div>';
        return;
      }
      body.innerHTML = '<div class="collab-list">' + items.map(requestRow).join('') + '</div>';
      body.querySelectorAll('.collab-row').forEach(function (row) {
        row.addEventListener('click', function () { openDetail(row.getAttribute('data-id')); });
      });
    }).catch(function (err) {
      body.innerHTML = '<div class="collab-empty"><i class="ti ti-alert-circle"></i>' + escapeHtml(err.message) + '</div>';
    });
  }

  function updateBadges() {
    if (!isAuthed()) return;
    api('/collaborations?box=received').then(function (items) {
      var pending = items.filter(function (i) {
        return i.status === 'pending' || i.status === 'reviewing' || i.status === 'negotiating';
      }).length;
      var b = el('badge-received');
      if (pending > 0) { b.textContent = pending; b.classList.remove('hidden'); }
      else { b.classList.add('hidden'); }
    }).catch(function () {});
  }

  // ---- Detail -----------------------------------------------------------
  function openDetail(id) {
    state.currentDetailId = id;
    el('detail-body').innerHTML = '<p style="color:var(--g-text-dim)">Loading…</p>';
    el('detail-modal').classList.add('open');
    api('/collaborations/' + id).then(renderDetail).catch(function (err) {
      el('detail-body').innerHTML = '<div class="collab-empty">' + escapeHtml(err.message) + '</div>';
    });
  }
  function closeDetail() {
    el('detail-modal').classList.remove('open');
    state.currentDetailId = null;
  }

  function actionButtons(d) {
    var s = d.status;
    var btns = [];
    if (d.is_recipient && (s === 'pending' || s === 'reviewing' || s === 'negotiating')) {
      btns.push('<button class="collab-mini-btn good" data-act="accept"><i class="ti ti-check"></i> Accept</button>');
      btns.push('<button class="collab-mini-btn danger" data-act="decline"><i class="ti ti-x"></i> Decline</button>');
    }
    if (s === 'pending' || s === 'reviewing' || s === 'negotiating' || s === 'accepted') {
      btns.push('<button class="collab-mini-btn" data-act="counter"><i class="ti ti-arrows-exchange"></i> Counter offer</button>');
    }
    if (s === 'accepted') {
      btns.push('<button class="collab-mini-btn primary" data-act="start"><i class="ti ti-player-play"></i> Start work</button>');
    }
    if (s === 'in_progress') {
      btns.push('<button class="collab-mini-btn good" data-act="complete"><i class="ti ti-flag-check"></i> Mark complete</button>');
    }
    if (s !== 'completed' && s !== 'cancelled' && s !== 'declined') {
      btns.push('<button class="collab-mini-btn danger" data-act="cancel"><i class="ti ti-ban"></i> Cancel</button>');
    }
    return btns.join('');
  }

  function renderDetail(d) {
    el('detail-title').textContent = d.project_name;
    el('detail-sub').innerHTML = (d.direction === 'sent' ? 'To ' : 'From ') +
      escapeHtml(d.counterpart_name || 'Artist') + ' · ' + escapeHtml(TYPE_LABEL[d.collaboration_type] || d.collaboration_type);

    var amount = d.agreed_amount || d.budget;
    var html = '';
    html += '<div>' + statusPill(d.status) + '</div>';
    html += '<div class="collab-detail-meta">' +
      (amount ? '<span><b>' + money(amount) + '</b>' + (d.agreed_amount ? ' agreed' : ' budget') + '</span>' : '') +
      (d.deadline ? '<span>Deadline: <b>' + escapeHtml(d.deadline) + '</b></span>' : '') +
      (d.deliverables ? '<span>Deliverables: <b>' + escapeHtml(d.deliverables) + '</b></span>' : '') +
      '</div>';
    if (d.description) html += '<div style="color:var(--g-text-muted);font-size:14px;line-height:1.6">' + escapeHtml(d.description) + '</div>';
    if (d.reference_links && d.reference_links.length) {
      html += '<div style="font-size:13px">References: ' + d.reference_links.map(function (u) {
        return '<a href="' + escapeHtml(u) + '" target="_blank" rel="noopener" style="color:var(--g-accent)">link</a>';
      }).join(' · ') + '</div>';
    }

    var acts = actionButtons(d);
    if (acts) html += '<div class="collab-actions-row">' + acts + '</div>';

    if (d.offers && d.offers.length) {
      html += '<div><div class="collab-fee-label">Offer history</div><div class="collab-offers">' +
        d.offers.map(function (o) {
          return '<div class="collab-offer-item"><span>' + escapeHtml(o.from_name || (o.from_me ? 'You' : 'Artist')) +
            (o.notes ? ' — ' + escapeHtml(o.notes) : '') + '</span><b>' + money(o.amount) + '</b></div>';
        }).join('') + '</div></div>';
    }

    // Messaging thread
    html += '<div><div class="collab-fee-label">Messages</div><div class="collab-thread" id="detail-thread"><p style="color:var(--g-text-dim);font-size:13px">Loading…</p></div>' +
      '<div class="collab-composer"><input id="detail-msg-input" type="text" placeholder="Write a message…">' +
      '<button class="collab-mini-btn primary" id="detail-send"><i class="ti ti-send"></i></button></div></div>';

    // Review (completed only)
    if (d.status === 'completed') {
      if (d.reviewed_by_me) {
        html += '<div class="collab-fee-label">Your review has been submitted. Thank you.</div>';
      } else {
        html += '<div><div class="collab-fee-label">Leave a review</div>' +
          '<div class="collab-stars" id="detail-stars">' +
          [1, 2, 3, 4, 5].map(function (n) { return '<span class="collab-star" data-n="' + n + '">&#9733;</span>'; }).join('') +
          '</div>' +
          '<div class="collab-field" style="margin-top:10px"><textarea id="detail-review-text" placeholder="How was the collaboration?"></textarea></div>' +
          '<label style="font-size:13px;color:var(--g-text-muted);display:flex;align-items:center;gap:8px;margin-bottom:10px">' +
          '<input type="checkbox" id="detail-would-again" checked style="width:auto"> Would collaborate again</label>' +
          '<button class="collab-mini-btn primary" id="detail-review-submit">Submit review</button>' +
          '<div class="collab-msg" id="detail-review-msg"></div></div>';
      }
    }

    el('detail-body').innerHTML = html;

    // Wire actions
    el('detail-body').querySelectorAll('[data-act]').forEach(function (btn) {
      btn.addEventListener('click', function () { doAction(d.id, btn.getAttribute('data-act')); });
    });
    el('detail-send').addEventListener('click', function () { sendMessage(d.id); });
    el('detail-msg-input').addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); sendMessage(d.id); }
    });
    loadThread(d.id);

    var stars = el('detail-stars');
    if (stars) {
      var picked = 0;
      stars.querySelectorAll('.collab-star').forEach(function (st) {
        st.addEventListener('click', function () {
          picked = Number(st.getAttribute('data-n'));
          stars.querySelectorAll('.collab-star').forEach(function (s2) {
            s2.classList.toggle('on', Number(s2.getAttribute('data-n')) <= picked);
          });
        });
      });
      el('detail-review-submit').addEventListener('click', function () {
        submitReview(d.id, picked);
      });
    }
  }

  function doAction(id, action) {
    var extra = {};
    if (action === 'counter') {
      var amount = prompt('Enter your counter-offer amount (ZAR):');
      if (amount == null) return;
      extra.amount = Number(amount);
      if (!isFinite(extra.amount) || extra.amount < 0) { alert('Enter a valid amount.'); return; }
      var notes = prompt('Add a note (optional):');
      if (notes) extra.notes = notes;
    }
    if (action === 'cancel' && !confirm('Cancel this collaboration?')) return;
    if (action === 'decline' && !confirm('Decline this request?')) return;

    var payload = Object.assign({ action: action }, extra);
    api('/collaborations/' + id, { method: 'PATCH', body: payload }).then(function () {
      openDetail(id);
      updateBadges();
    }).catch(function (err) { alert(err.message); });
  }

  function loadThread(id) {
    api('/collaborations/' + id + '/messages').then(function (messages) {
      var thread = el('detail-thread');
      if (!thread) return;
      if (!messages.length) {
        thread.innerHTML = '<p style="color:var(--g-text-dim);font-size:13px">No messages yet. Start the conversation.</p>';
        return;
      }
      thread.innerHTML = messages.map(function (m) {
        return '<div class="collab-bubble ' + (m.sender === 'me' ? 'me' : 'them') + '">' +
          escapeHtml(m.text) +
          (m.attachment_url ? '<br><a href="' + escapeHtml(m.attachment_url) + '" target="_blank" rel="noopener" style="color:inherit;text-decoration:underline">attachment</a>' : '') +
          '<div class="collab-bubble-meta">' + timeAgo(m.timestamp) + '</div></div>';
      }).join('');
      thread.scrollTop = thread.scrollHeight;
    }).catch(function () {});
  }

  function sendMessage(id) {
    var input = el('detail-msg-input');
    var text = (input.value || '').trim();
    if (!text) return;
    input.value = '';
    api('/collaborations/' + id + '/messages', { method: 'POST', body: { message: text } })
      .then(function () { loadThread(id); })
      .catch(function (err) { alert(err.message); });
  }

  function submitReview(id, rating) {
    var msg = el('detail-review-msg');
    if (!rating) { msg.className = 'collab-msg error'; msg.textContent = 'Pick a star rating.'; return; }
    api('/collaborations/' + id + '/review', {
      method: 'POST',
      body: {
        rating: rating,
        review: (el('detail-review-text').value || '').trim(),
        would_again: el('detail-would-again').checked,
      },
    }).then(function () { openDetail(id); }).catch(function (err) {
      msg.className = 'collab-msg error'; msg.textContent = err.message;
    });
  }

  // ---- Settings ---------------------------------------------------------
  function loadSettings() {
    var body = el('collab-settings-body');
    if (!isAuthed()) { body.innerHTML = gate('Log in to set up your collaboration profile.'); return; }
    body.innerHTML = '<p style="color:var(--g-text-dim)">Loading…</p>';
    api('/collaboration-settings').then(function (data) { renderSettings(data); }).catch(function (err) {
      body.innerHTML = '<div class="collab-empty">' + escapeHtml(err.message) + '</div>';
    });
  }

  function renderSettings(data) {
    var s = data.settings;
    var enabled = s.enabled_types || [];
    var body = el('collab-settings-body');
    var availOpts = ['available', 'limited', 'fully_booked'];
    var availLabel = { available: 'Available', limited: 'Limited availability', fully_booked: 'Fully booked' };

    body.innerHTML =
      '<div style="max-width:640px">' +
      '<div class="collab-field"><label>Availability</label><select id="set-availability">' +
        availOpts.map(function (o) {
          return '<option value="' + o + '"' + (s.available_status === o ? ' selected' : '') + '>' + availLabel[o] + '</option>';
        }).join('') +
      '</select></div>' +
      '<div class="collab-field-row">' +
        '<div class="collab-field"><label>Collaboration fee (ZAR)</label><input id="set-collab-fee" type="number" min="0" value="' + (s.collaboration_fee || '') + '"></div>' +
        '<div class="collab-field"><label>Feature fee (ZAR)</label><input id="set-feature-fee" type="number" min="0" value="' + (s.feature_fee || '') + '"></div>' +
      '</div>' +
      '<div class="collab-field-row">' +
        '<div class="collab-field"><label>Appearance fee (ZAR)</label><input id="set-appearance-fee" type="number" min="0" value="' + (s.appearance_fee || '') + '"></div>' +
        '<div class="collab-field"><label>Hourly rate (ZAR)</label><input id="set-hourly" type="number" min="0" value="' + (s.hourly_rate || '') + '"></div>' +
      '</div>' +
      '<div class="collab-field-row">' +
        '<div class="collab-field"><label>Project rate (ZAR)</label><input id="set-project" type="number" min="0" value="' + (s.project_rate || '') + '"></div>' +
        '<div class="collab-field"><label>Typical response time</label><input id="set-response" type="text" placeholder="e.g. Under 24 hours" value="' + escapeHtml(s.response_time || '') + '"></div>' +
      '</div>' +
      '<label style="font-size:13px;color:var(--g-text-muted);display:flex;align-items:center;gap:8px;margin-bottom:10px">' +
        '<input type="checkbox" id="set-hide" style="width:auto"' + (s.hide_pricing ? ' checked' : '') + '> Hide my pricing publicly</label>' +
      '<label style="font-size:13px;color:var(--g-text-muted);display:flex;align-items:center;gap:8px;margin-bottom:16px">' +
        '<input type="checkbox" id="set-quote" style="width:auto"' + (s.quote_only ? ' checked' : '') + '> Request quote only</label>' +
      '<div class="collab-field"><label>Collaboration types I offer</label><div class="collab-types-grid" id="set-types">' +
        TYPES.map(function (t) {
          var on = enabled.indexOf(t.id) !== -1;
          return '<div class="collab-type-toggle ' + (on ? 'on' : '') + '" data-type="' + t.id + '"><i class="ti ' + t.icon + '"></i> ' + escapeHtml(t.label) + '</div>';
        }).join('') +
      '</div></div>' +
      '<div class="collab-msg" id="set-msg"></div>' +
      '<button class="btn-main" id="set-save">Save collaboration profile</button>' +
      '</div>';

    body.querySelectorAll('.collab-type-toggle').forEach(function (tg) {
      tg.addEventListener('click', function () { tg.classList.toggle('on'); });
    });
    el('set-save').addEventListener('click', saveSettings);
  }

  function saveSettings() {
    var types = [];
    el('set-types').querySelectorAll('.collab-type-toggle.on').forEach(function (tg) {
      types.push(tg.getAttribute('data-type'));
    });
    var payload = {
      available_status: el('set-availability').value,
      collaboration_fee: el('set-collab-fee').value,
      feature_fee: el('set-feature-fee').value,
      appearance_fee: el('set-appearance-fee').value,
      hourly_rate: el('set-hourly').value,
      project_rate: el('set-project').value,
      response_time: el('set-response').value,
      hide_pricing: el('set-hide').checked,
      quote_only: el('set-quote').checked,
      enabled_types: types,
    };
    var msg = el('set-msg');
    var btn = el('set-save');
    btn.disabled = true; btn.textContent = 'Saving…';
    api('/collaboration-settings', { method: 'PUT', body: payload }).then(function () {
      msg.className = 'collab-msg ok'; msg.textContent = 'Collaboration profile saved.';
    }).catch(function (err) {
      msg.className = 'collab-msg error'; msg.textContent = err.message;
    }).finally(function () {
      btn.disabled = false; btn.textContent = 'Save collaboration profile';
    });
  }

  // ---- Boot -------------------------------------------------------------
  function boot() {
    if (isAuthed()) {
      var navLink = el('nav-auth-link');
      if (navLink) { navLink.textContent = 'Dashboard'; navLink.setAttribute('href', 'artist-dashboard.html'); }
    }

    document.getElementById('collab-tabs').addEventListener('click', function (e) {
      var tab = e.target.closest('.collab-tab');
      if (tab) switchView(tab.getAttribute('data-view'));
    });

    el('book-form').addEventListener('submit', submitBook);
    el('collab-search').addEventListener('input', debounce(loadDiscover, 350));

    // Backdrop click closes modals
    ['book-modal', 'detail-modal'].forEach(function (mid) {
      el(mid).addEventListener('click', function (e) {
        if (e.target === el(mid)) el(mid).classList.remove('open');
      });
    });

    renderTypeChips();
    loadDiscover();
    updateBadges();

    // Deep link: ?artist=username opens the book modal
    var params = new URLSearchParams(window.location.search);
    var artist = params.get('artist');
    if (artist) openBook(artist, params.get('name') || artist);
    var view = params.get('view');
    if (view) switchView(view);
  }

  function debounce(fn, wait) {
    var t;
    return function () {
      clearTimeout(t);
      t = setTimeout(fn, wait);
    };
  }

  // Public API for inline handlers
  window.GearshCollab = {
    closeBook: closeBook,
    closeDetail: closeDetail,
    openBook: openBook,
    switchView: switchView,
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
