(function () {
  'use strict';

  var API = '/api';
  var PLATFORM_FEE = 0.126;

  function getToken() { return localStorage.getItem('gearsh_token') || ''; }
  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
  function money(v) { return 'R' + Number(v || 0).toLocaleString('en-ZA', { maximumFractionDigits: 0 }); }

  function authHeaders() {
    var h = { Accept: 'application/json', 'Content-Type': 'application/json' };
    var t = getToken();
    if (t) h.Authorization = 'Bearer ' + t;
    return h;
  }

  function submitPayfast(pay) {
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = pay.process_url;
    Object.keys(pay.fields).forEach(function (key) {
      var input = document.createElement('input');
      input.type = 'hidden';
      input.name = key;
      input.value = pay.fields[key];
      form.appendChild(input);
    });
    document.body.appendChild(form);
    form.submit();
  }

  function statusLabel(status) {
    if (status === 'accepted') return 'Ready to pay';
    if (status === 'pending') return 'Awaiting artist';
    return status;
  }

  function renderCard(b, guestEmail) {
    var subtotal = Number(b.total_price || 0);
    var fee = Math.round(subtotal * PLATFORM_FEE * 100) / 100;
    var total = Math.round((subtotal + fee) * 100) / 100;
    var payable = b.status === 'accepted' && subtotal > 0;
    var payBtn = payable
      ? '<button type="button" class="btn-main bk-pay" data-id="' + escapeHtml(b.id) + '" data-email="' + escapeHtml(guestEmail || '') + '">' +
        '<i class="ti ti-credit-card"></i> Pay ' + money(total) + ' via PayFast</button>'
      : '';
    var feeNote = payable
      ? '<span class="bk-fee-note">Includes R' + fee.toLocaleString('en-ZA') + ' Gearsh service fee</span>'
      : '';

    return '<div class="bk-card" data-booking="' + escapeHtml(b.id) + '">' +
      '<div class="bk-card-head">' +
        '<div><div class="bk-artist">' + escapeHtml(b.artist_name || 'Artist') + '</div>' +
        '<div class="bk-meta">' + escapeHtml(b.service_name || 'Booking') +
        (b.event_date ? '<br>' + escapeHtml(b.event_date) : '') +
        (b.event_location ? ' · ' + escapeHtml(b.event_location) : '') + '</div>' +
        '<span class="bk-status ' + escapeHtml(b.status) + '">' + escapeHtml(statusLabel(b.status)) + '</span></div>' +
        '<div class="bk-price">' + (subtotal > 0 ? money(subtotal) : 'Quote TBC') + '</div>' +
      '</div>' +
      (payBtn ? '<div class="bk-actions">' + payBtn + feeNote + '</div>' : '') +
    '</div>';
  }

  function wirePayButtons(root, guestEmail) {
    root.querySelectorAll('.bk-pay').forEach(function (btn) {
      btn.addEventListener('click', function () {
        btn.disabled = true;
        var payload = {
          booking_id: btn.getAttribute('data-id'),
          return_url: window.location.origin + '/booking-success?booking=' + encodeURIComponent(btn.getAttribute('data-id')),
          cancel_url: window.location.href,
        };
        var email = btn.getAttribute('data-email') || guestEmail;
        if (email) payload.client_email = email;

        fetch(API + '/payfast/initiate', {
          method: 'POST',
          headers: authHeaders(),
          body: JSON.stringify(payload),
        })
          .then(function (r) { return r.json(); })
          .then(function (d) {
            if (!d.success) throw new Error(d.error || 'Could not start payment');
            submitPayfast(d.data);
          })
          .catch(function (err) {
            btn.disabled = false;
            alert(err.message);
          });
      });
    });
  }

  function renderList(bookings, guestEmail) {
    var root = document.getElementById('bookings-root');
    if (!bookings.length) {
      root.innerHTML = '<div class="bk-empty">No bookings yet. <a href="/search" style="color:var(--g-accent)">Find an artist</a> to book.</div>';
      return;
    }
    root.innerHTML = bookings.map(function (b) { return renderCard(b, guestEmail); }).join('');
    wirePayButtons(root, guestEmail);
  }

  function loadAuthed() {
    return fetch(API + '/bookings?user_type=client', { headers: authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Failed to load bookings');
        return d.data || [];
      });
  }

  function loadGuest(id, email) {
    return fetch(API + '/bookings/lookup?id=' + encodeURIComponent(id) + '&email=' + encodeURIComponent(email))
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Booking not found');
        return [d.data];
      });
  }

  function updateNavFromSession() {
    var token = getToken();
    if (!token) return Promise.resolve(null);
    return fetch(API + '/session', { headers: authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) return null;
        var session = d.data;
        var navAuth = document.getElementById('nav-auth');
        var dashLi = document.getElementById('nav-dashboard-li');
        if (session.has_artist_dashboard || session.user_type === 'artist') {
          if (dashLi) dashLi.hidden = false;
          if (navAuth) navAuth.hidden = true;
        } else if (navAuth) {
          navAuth.textContent = 'Home';
          navAuth.href = '/';
        }
        return session.email || null;
      })
      .catch(function () { return null; });
  }

  function boot() {
    var params = new URLSearchParams(window.location.search);
    var highlightId = params.get('booking');
    var guestEmailParam = params.get('email') || '';
    var token = getToken();
    var sessionEmail = null;

    var guestBox = document.getElementById('guest-box');
    if (!token) {
      guestBox.hidden = false;
      if (guestEmailParam) document.getElementById('guest-email').value = guestEmailParam;
      if (highlightId) document.getElementById('guest-id').value = highlightId;
    }

    document.getElementById('guest-find').addEventListener('click', function () {
      var msg = document.getElementById('guest-msg');
      msg.className = 'bk-msg';
      var email = document.getElementById('guest-email').value.trim();
      var id = document.getElementById('guest-id').value.trim();
      if (!email || !id) {
        msg.className = 'bk-msg error';
        msg.textContent = 'Enter your email and booking reference.';
        return;
      }
      loadGuest(id, email)
        .then(function (list) { renderList(list, email); })
        .catch(function (err) {
          msg.className = 'bk-msg error';
          msg.textContent = err.message;
        });
    });

    if (token) {
      updateNavFromSession().then(function (email) {
        sessionEmail = email;
        return loadAuthed();
      })
        .then(function (list) {
          renderList(list, sessionEmail);
          if (highlightId) {
            var el = document.querySelector('[data-booking="' + highlightId + '"]');
            if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
          }
        })
        .catch(function (err) {
          document.getElementById('bookings-root').innerHTML =
            '<div class="bk-empty">' + escapeHtml(err.message) + '</div>';
        });
    } else if (highlightId && guestEmailParam) {
      loadGuest(highlightId, guestEmailParam)
        .then(function (list) { renderList(list, guestEmailParam); })
        .catch(function () {
          document.getElementById('bookings-root').innerHTML =
            '<div class="bk-empty">Use the form above to find your booking.</div>';
        });
    } else {
      document.getElementById('bookings-root').innerHTML =
        '<div class="bk-empty">Sign in to see all bookings, or use the form above with your booking reference.</div>';
    }
  }

  boot();
})();
