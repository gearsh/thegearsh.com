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
    if (status === 'confirmed') return 'Paid';
    if (status === 'completed') return 'Completed';
    if (status === 'cancelled') return 'Cancelled';
    return status;
  }

  function statusHelp(status, subtotal) {
    if (status === 'pending') {
      return 'The artist will review your request. You can pay here once they accept.';
    }
    if (status === 'accepted' && subtotal > 0) {
      return 'Accepted — pay securely via PayFast to confirm your booking.';
    }
    if (status === 'accepted' && subtotal <= 0) {
      return 'Accepted — the artist still needs to confirm a price with you.';
    }
    if (status === 'confirmed') return 'Payment received. Your booking is confirmed.';
    return '';
  }

  function renderCard(b, payEmail, highlightId) {
    var subtotal = Number(b.total_price || 0);
    var fee = Math.round(subtotal * PLATFORM_FEE * 100) / 100;
    var total = Math.round((subtotal + fee) * 100) / 100;
    var payable = b.status === 'accepted' && subtotal > 0;
    var help = statusHelp(b.status, subtotal);
    var isHighlight = highlightId && b.id === highlightId;
    var payBtn = payable
      ? '<button type="button" class="btn-main bk-pay" data-id="' + escapeHtml(b.id) + '" data-email="' + escapeHtml(payEmail || '') + '">' +
        '<i class="ti ti-credit-card"></i> Pay ' + money(total) + ' via PayFast</button>'
      : '';
    var feeNote = payable
      ? '<span class="bk-fee-note">Includes R' + fee.toLocaleString('en-ZA') + ' Gearsh service fee</span>'
      : '';

    return '<div class="bk-card' + (isHighlight ? ' bk-card-highlight' : '') + '" data-booking="' + escapeHtml(b.id) + '">' +
      '<div class="bk-card-head">' +
        '<div><div class="bk-artist">' + escapeHtml(b.artist_name || 'Artist') + '</div>' +
        '<div class="bk-meta">' + escapeHtml(b.service_name || 'Booking') +
        (b.event_date ? '<br>' + escapeHtml(b.event_date) : '') +
        (b.event_location ? ' · ' + escapeHtml(b.event_location) : '') +
        '<br><span class="bk-ref">Ref: ' + escapeHtml(b.id) + '</span></div>' +
        '<span class="bk-status ' + escapeHtml(b.status) + '">' + escapeHtml(statusLabel(b.status)) + '</span></div>' +
        '<div class="bk-price">' + (subtotal > 0 ? money(subtotal) : 'Quote TBC') + '</div>' +
      '</div>' +
      (help ? '<p class="bk-help">' + escapeHtml(help) + '</p>' : '') +
      (payBtn ? '<div class="bk-actions">' + payBtn + feeNote + '<div class="bk-pay-error bk-msg error"></div></div>' : '') +
    '</div>';
  }

  function wirePayButtons(root, payEmail) {
    root.querySelectorAll('.bk-pay').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var errEl = btn.closest('.bk-actions').querySelector('.bk-pay-error');
        if (errEl) errEl.textContent = '';
        btn.disabled = true;
        var payload = {
          booking_id: btn.getAttribute('data-id'),
          return_url: window.location.origin + '/booking-success?booking=' + encodeURIComponent(btn.getAttribute('data-id')),
          cancel_url: window.location.href,
        };
        var email = btn.getAttribute('data-email') || payEmail;
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
            if (errEl) errEl.textContent = err.message;
            else alert(err.message);
          });
      });
    });
  }

  function renderList(bookings, payEmail, highlightId) {
    var root = document.getElementById('bookings-root');
    if (!bookings.length) {
      root.innerHTML = '<div class="bk-empty">No bookings yet. <a href="/search" style="color:var(--g-accent)">Find an artist</a> to book.</div>';
      return;
    }
    bookings.sort(function (a, b) {
      if (highlightId) {
        if (a.id === highlightId) return -1;
        if (b.id === highlightId) return 1;
      }
      if (a.status === 'accepted' && b.status !== 'accepted') return -1;
      if (b.status === 'accepted' && a.status !== 'accepted') return 1;
      return String(b.event_date || '').localeCompare(String(a.event_date || ''));
    });
    root.innerHTML = bookings.map(function (b) { return renderCard(b, payEmail, highlightId); }).join('');
    wirePayButtons(root, payEmail);
  }

  function loadAuthed() {
    return fetch(API + '/bookings?user_type=client', { headers: authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Failed to load bookings');
        return d.data || [];
      });
  }

  function loadBookingAuthed(id) {
    return fetch(API + '/bookings/' + encodeURIComponent(id), { headers: authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Booking not found');
        return d.data;
      });
  }

  function loadGuest(id, email) {
    return fetch(API + '/bookings/lookup?id=' + encodeURIComponent(id) + '&email=' + encodeURIComponent(email))
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Booking not found');
        return d.data;
      });
  }

  function mergeBookings(list, item) {
    if (!item || !item.id) return list;
    var found = false;
    var next = list.map(function (b) {
      if (b.id === item.id) { found = true; return Object.assign({}, b, item); }
      return b;
    });
    if (!found) next.unshift(item);
    return next;
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
          if (navAuth) {
            navAuth.textContent = 'Dashboard';
            navAuth.href = '/artist-dashboard.html';
          }
        } else if (navAuth) {
          navAuth.textContent = 'Login';
          navAuth.href = '/auth.html';
        }
        return session.email || null;
      })
      .catch(function () { return null; });
  }

  function showTrackBanner(booking, payEmail) {
    var banner = document.getElementById('track-banner');
    if (!banner || !booking) return;
    var help = statusHelp(booking.status, Number(booking.total_price || 0));
    banner.hidden = false;
    banner.innerHTML =
      '<div class="bk-banner-inner">' +
        '<div><strong>Tracking ' + escapeHtml(booking.id) + '</strong>' +
        (help ? '<p>' + escapeHtml(help) + '</p>' : '') +
        '</div>' +
        (booking.status === 'accepted' && Number(booking.total_price || 0) > 0
          ? '<button type="button" class="btn-main bk-pay" data-id="' + escapeHtml(booking.id) + '" data-email="' + escapeHtml(payEmail || '') + '">Pay now</button>'
          : '') +
      '</div>';
    wirePayButtons(banner, payEmail);
  }

  async function loadEverything(highlightId, guestEmailParam) {
    var sessionEmail = null;
    var bookings = [];
    var payEmail = guestEmailParam || '';

    if (getToken()) {
      sessionEmail = await updateNavFromSession();
      if (sessionEmail) payEmail = sessionEmail;
      try {
        bookings = await loadAuthed();
      } catch (_) {
        bookings = [];
      }
    }

    if (highlightId) {
      var inList = bookings.some(function (b) { return b.id === highlightId; });
      if (!inList) {
        if (getToken()) {
          try {
            var authedOne = await loadBookingAuthed(highlightId);
            bookings = mergeBookings(bookings, authedOne);
          } catch (_) {}
        }
        if (!bookings.some(function (b) { return b.id === highlightId; })) {
          var lookupEmail = guestEmailParam || sessionEmail || document.getElementById('guest-email').value.trim();
          if (lookupEmail) {
            try {
              var guestOne = await loadGuest(highlightId, lookupEmail);
              bookings = mergeBookings(bookings, guestOne);
              payEmail = lookupEmail;
            } catch (err) {
              var errBox = document.getElementById('guest-msg');
              if (errBox && !getToken()) {
                errBox.className = 'bk-msg error';
                errBox.textContent = err.message;
              }
            }
          }
        }
      }
    }

    var highlightBooking = highlightId
      ? bookings.find(function (b) { return b.id === highlightId; })
      : null;

    renderList(bookings, payEmail, highlightId);
    showTrackBanner(highlightBooking, payEmail);

    if (highlightBooking) {
      var el = document.querySelector('[data-booking="' + highlightId + '"]');
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } else if (highlightId && !getToken() && !guestEmailParam) {
      document.getElementById('guest-box').hidden = false;
      document.getElementById('guest-id').value = highlightId;
    }

    return bookings;
  }

  function boot() {
    var params = new URLSearchParams(window.location.search);
    var highlightId = params.get('booking');
    var guestEmailParam = (params.get('email') || '').trim();
    var token = getToken();

    var guestBox = document.getElementById('guest-box');
    if (!token) {
      guestBox.hidden = false;
      if (guestEmailParam) document.getElementById('guest-email').value = guestEmailParam;
      if (highlightId) document.getElementById('guest-id').value = highlightId;
    } else {
      guestBox.hidden = true;
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
      var url = new URL(window.location.href);
      url.searchParams.set('booking', id);
      url.searchParams.set('email', email);
      history.replaceState(null, '', url.pathname + url.search);
      loadEverything(id, email).catch(function (err) {
        msg.className = 'bk-msg error';
        msg.textContent = err.message;
      });
    });

    if (highlightId && guestEmailParam) {
      loadEverything(highlightId, guestEmailParam).catch(function () {
        document.getElementById('bookings-root').innerHTML =
          '<div class="bk-empty">Could not load that booking. Check the email and reference above.</div>';
      });
    } else if (token || highlightId) {
      loadEverything(highlightId, guestEmailParam).catch(function (err) {
        document.getElementById('bookings-root').innerHTML =
          '<div class="bk-empty">' + escapeHtml(err.message) + '</div>';
      });
    } else {
      document.getElementById('bookings-root').innerHTML =
        '<div class="bk-empty">Sign in to see all bookings, or use the form above with your booking reference.</div>';
    }
  }

  boot();
})();
