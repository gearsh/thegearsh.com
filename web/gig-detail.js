(function () {
  'use strict';

  var API = '/api';
  var slug = new URLSearchParams(window.location.search).get('slug');
  var root = document.getElementById('gig-root');
  var cart = {};
  var eventData = null;
  var countdownTimer = null;

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatMoney(amount, currency) {
    var sym = (currency || 'ZAR') === 'ZAR' ? 'R' : currency + ' ';
    return sym + Number(amount || 0).toLocaleString('en-ZA', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
  }

  function formatDate(iso) {
    if (!iso) return '';
    return new Date(iso).toLocaleString('en-ZA', {
      weekday: 'short', day: 'numeric', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  }

  function authHeaders() {
    var token = localStorage.getItem('gearsh_token');
    var h = { 'Content-Type': 'application/json', Accept: 'application/json' };
    if (token) h.Authorization = 'Bearer ' + token;
    return h;
  }

  function showError(msg) {
    root.innerHTML = '<div class="tkt-body"><div class="tkt-card"><h1 class="tkt-title" style="font-size:28px">' + escapeHtml(msg) + '</h1><p style="margin-top:12px"><a href="/search">Browse artists</a></p></div></div>';
  }

  function updateSummary() {
    var subtotal = 0;
    var count = 0;
    if (!eventData) return;
    eventData.ticket_types.forEach(function (tier) {
      var qty = cart[tier.id] || 0;
      subtotal += qty * tier.price;
      count += qty;
    });
    var fee = Math.round(subtotal * 0.126 * 100) / 100;
    var total = Math.round((subtotal + fee) * 100) / 100;

    var subEl = document.getElementById('tkt-subtotal');
    var feeEl = document.getElementById('tkt-fee');
    var totalEl = document.getElementById('tkt-total');
    var btn = document.getElementById('tkt-checkout-btn');
    if (subEl) subEl.textContent = formatMoney(subtotal, eventData.currency);
    if (feeEl) feeEl.textContent = formatMoney(fee, eventData.currency);
    if (totalEl) totalEl.textContent = formatMoney(total, eventData.currency);
    if (btn) {
      btn.disabled = count === 0 || !eventData.sales_open;
      btn.textContent = count === 0 ? 'Select tickets' : 'Checkout (' + count + ')';
    }
  }

  function bindQtyEvents() {
    root.querySelectorAll('[data-qty-minus]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-qty-minus');
        cart[id] = Math.max(0, (cart[id] || 0) - 1);
        var span = root.querySelector('[data-qty-val="' + id + '"]');
        if (span) span.textContent = cart[id];
        updateSummary();
      });
    });
    root.querySelectorAll('[data-qty-plus]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-qty-plus');
        var tier = eventData.ticket_types.find(function (t) { return t.id === id; });
        if (!tier) return;
        var next = (cart[id] || 0) + 1;
        if (next > tier.max_per_order || next > tier.quantity_remaining) return;
        cart[id] = next;
        var span = root.querySelector('[data-qty-val="' + id + '"]');
        if (span) span.textContent = cart[id];
        updateSummary();
      });
    });
  }

  function startCountdown(iso) {
    if (countdownTimer) clearInterval(countdownTimer);
    function tick() {
      var diff = new Date(iso).getTime() - Date.now();
      var el = document.getElementById('tkt-countdown');
      if (!el) return;
      if (diff <= 0) {
        el.innerHTML = '<div class="tkt-countdown-item"><div class="tkt-countdown-num">Live</div><div class="tkt-countdown-lbl">now</div></div>';
        clearInterval(countdownTimer);
        return;
      }
      var d = Math.floor(diff / 86400000);
      var h = Math.floor((diff % 86400000) / 3600000);
      var m = Math.floor((diff % 3600000) / 60000);
      var s = Math.floor((diff % 60000) / 1000);
      el.innerHTML = ['days', 'hours', 'mins', 'secs'].map(function (lbl, i) {
        var val = [d, h, m, s][i];
        return '<div class="tkt-countdown-item"><div class="tkt-countdown-num">' + val + '</div><div class="tkt-countdown-lbl">' + lbl + '</div></div>';
      }).join('');
    }
    tick();
    countdownTimer = setInterval(tick, 1000);
  }

  function renderEvent(ev) {
    eventData = ev;
    var flyer = ev.flyer_url || '/icons/Icon-512.png';
    var artistLink = ev.artist && ev.artist.profile_url ? ev.artist.profile_url : (ev.artist && ev.artist.username ? '/book/' + ev.artist.username : '#');

    var tiersHtml = (ev.ticket_types || []).map(function (tier) {
      cart[tier.id] = cart[tier.id] || 0;
      var soldOut = tier.quantity_remaining <= 0;
      return '<div class="tkt-tier">' +
        '<div class="tkt-tier-info">' +
          '<div class="tkt-tier-name">' + escapeHtml(tier.name) + '</div>' +
          (tier.description ? '<div class="tkt-tier-desc">' + escapeHtml(tier.description) + '</div>' : '') +
          '<div class="tkt-tier-avail' + (soldOut ? ' sold' : '') + '">' + escapeHtml(tier.availability_label) + '</div>' +
        '</div>' +
        '<div style="text-align:right">' +
          '<div class="tkt-tier-price">' + formatMoney(tier.price, ev.currency) + '</div>' +
          (soldOut ? '<span style="font-size:12px;color:#f87171">Sold out</span>' : (
            '<div class="tkt-qty" style="margin-top:8px">' +
              '<button type="button" data-qty-minus="' + escapeHtml(tier.id) + '">−</button>' +
              '<span data-qty-val="' + escapeHtml(tier.id) + '">0</span>' +
              '<button type="button" data-qty-plus="' + escapeHtml(tier.id) + '">+</button>' +
            '</div>'
          )) +
        '</div></div>';
    }).join('');

    var lineupHtml = (ev.lineup || []).length
      ? '<ul style="margin:0;padding-left:18px;color:var(--g-text-muted);font-size:14px">' +
        ev.lineup.map(function (a) { return '<li>' + escapeHtml(typeof a === 'string' ? a : a.name || a) + '</li>'; }).join('') +
        '</ul>'
      : '<p style="color:var(--g-text-muted);font-size:14px">Full lineup announced soon.</p>';

    root.innerHTML =
      '<section class="tkt-hero">' +
        '<div class="tkt-hero-bg"><img src="' + escapeHtml(flyer) + '" alt=""></div>' +
        '<div class="tkt-hero-overlay"></div>' +
        '<div class="tkt-hero-inner">' +
          '<div class="tkt-badge"><i class="ti ti-ticket"></i> Live on Gearsh</div>' +
          '<h1 class="tkt-title">' + escapeHtml(ev.title) + '</h1>' +
          '<div class="tkt-meta">' +
            '<span><i class="ti ti-calendar"></i> ' + escapeHtml(formatDate(ev.starts_at)) + '</span>' +
            '<span><i class="ti ti-map-pin"></i> ' + escapeHtml(ev.venue) + ', ' + escapeHtml(ev.city) + '</span>' +
            (ev.artist ? '<span><i class="ti ti-microphone-2"></i> <a href="' + escapeHtml(artistLink) + '" style="color:inherit">' + escapeHtml(ev.artist.name) + '</a></span>' : '') +
          '</div>' +
          '<div style="display:flex;gap:8px;margin-top:14px;flex-wrap:wrap" id="tkt-quick-actions"></div>' +
          '<div class="tkt-countdown" id="tkt-countdown"></div>' +
        '</div></section>' +
      '<div class="tkt-body"><div class="tkt-grid">' +
        '<div>' +
          '<div class="tkt-card" style="margin-bottom:20px">' +
            '<div class="tkt-section-label">About</div>' +
            '<p style="color:var(--g-text-muted);line-height:1.65;font-size:15px">' + escapeHtml(ev.description || 'An unforgettable night of live music.') + '</p>' +
          '</div>' +
          '<div class="tkt-card" style="margin-bottom:20px">' +
            '<div class="tkt-section-label">Lineup</div>' + lineupHtml +
          '</div>' +
          (ev.refund_policy ? '<div class="tkt-card"><div class="tkt-section-label">Refund policy</div><p style="font-size:14px;color:var(--g-text-muted)">' + escapeHtml(ev.refund_policy) + '</p></div>' : '') +
        '</div>' +
        '<div class="tkt-sticky">' +
          '<div class="tkt-card" id="tickets">' +
            '<div class="tkt-section-label">Tickets</div>' +
            (ev.sales_open ? tiersHtml : (
              ev.is_sold_out
                ? '<p style="color:var(--g-text-muted);font-size:14px;margin-bottom:16px">Sold out. Join the waitlist and we will notify you if tickets open up.</p>' +
                  '<div class="tkt-field" id="waitlist"><label>Email</label><input id="waitlist-email" type="email" placeholder="you@email.com"></div>' +
                  '<button type="button" class="btn-main" id="waitlist-btn" style="width:100%">Join waitlist</button>'
                : '<p style="color:var(--g-text-muted);font-size:14px">Ticket sales are not open yet.</p>'
            )) +
            '<div id="checkout-panel" style="margin-top:18px;' + (ev.sales_open ? '' : 'display:none') + '">' +
              '<div class="tkt-field"><label>Promo code</label><input id="tkt-promo" placeholder="Optional"></div>' +
              '<div class="tkt-summary-row"><span>Subtotal</span><span id="tkt-subtotal">R0</span></div>' +
              '<div class="tkt-summary-row"><span>Service fee</span><span id="tkt-fee">R0</span></div>' +
              '<div class="tkt-summary-row total"><span>Total</span><span id="tkt-total">R0</span></div>' +
              '<div class="tkt-field" style="margin-top:14px"><label>Full name</label><input id="tkt-name" placeholder="Your name"></div>' +
              '<div class="tkt-field"><label>Email</label><input id="tkt-email" type="email" placeholder="you@email.com"></div>' +
              '<div class="tkt-field"><label>Phone</label><input id="tkt-phone" placeholder="+27…"></div>' +
              '<div id="tkt-msg" class="tkt-msg"></div>' +
              '<button type="button" class="btn-main" id="tkt-checkout-btn" style="width:100%;margin-top:8px" disabled>Select tickets</button>' +
              '<div class="tkt-trust">' +
                '<span><i class="ti ti-lock"></i> Secure checkout</span>' +
                '<span><i class="ti ti-shield-check"></i> Powered by PayFast</span>' +
              '</div>' +
            '</div>' +
          '</div></div></div></div>';

    document.title = ev.title + ' | Tickets | Gearsh';
    startCountdown(ev.starts_at);
    bindQtyEvents();
    updateSummary();
    renderQuickActions(ev);
    applyUrlParams();

    var checkoutBtn = document.getElementById('tkt-checkout-btn');
    if (checkoutBtn) checkoutBtn.addEventListener('click', checkout);

    var waitBtn = document.getElementById('waitlist-btn');
    if (waitBtn) waitBtn.addEventListener('click', joinWaitlist);

    var token = localStorage.getItem('gearsh_token');
    if (token) {
      var savedName = localStorage.getItem('gearsh_user_name');
      if (savedName && document.getElementById('tkt-name')) document.getElementById('tkt-name').value = savedName;
    }
  }

  function renderQuickActions(ev) {
    var el = document.getElementById('tkt-quick-actions');
    if (!el) return;
    var general = (ev.ticket_types || []).find(function (t) {
      return (t.tier_kind === 'general' || t.tier_kind === 'early_bird') && t.quantity_remaining > 0;
    }) || (ev.ticket_types || []).find(function (t) { return t.quantity_remaining > 0; });
    var vip = (ev.ticket_types || []).find(function (t) {
      return (t.tier_kind === 'vip' || /vip/i.test(t.name)) && t.quantity_remaining > 0;
    });
    var html = '<a href="/gigs" class="btn-ghost" style="font-size:12px"><i class="ti ti-arrow-left"></i> Gig Guide</a>';
    if (ev.sales_open && general) {
      html += '<button type="button" class="btn-main" data-quick-tier="' + escapeHtml(general.id) + '" style="padding:10px 16px;font-size:13px">Buy ' + escapeHtml(general.name) + '</button>';
    }
    if (ev.sales_open && vip) {
      html += '<button type="button" class="btn-ghost" data-quick-tier="' + escapeHtml(vip.id) + '" style="padding:10px 16px;font-size:13px">Buy VIP</button>';
    }
    html += '<button type="button" class="btn-ghost" id="tkt-share" style="padding:10px 12px;font-size:12px"><i class="ti ti-share-3"></i></button>';
    html += '<button type="button" class="btn-ghost" id="tkt-calendar" style="padding:10px 12px;font-size:12px"><i class="ti ti-calendar-plus"></i></button>';
    el.innerHTML = html;
    el.querySelectorAll('[data-quick-tier]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-quick-tier');
        cart[id] = 1;
        var span = root.querySelector('[data-qty-val="' + id + '"]');
        if (span) span.textContent = '1';
        updateSummary();
        document.getElementById('tickets').scrollIntoView({ behavior: 'smooth' });
      });
    });
    var shareBtn = document.getElementById('tkt-share');
    if (shareBtn) {
      shareBtn.addEventListener('click', function () {
        var url = window.location.href;
        if (navigator.share) navigator.share({ title: ev.title, url: url }).catch(function () {});
        else navigator.clipboard.writeText(url);
      });
    }
    var calBtn = document.getElementById('tkt-calendar');
    if (calBtn) {
      calBtn.addEventListener('click', function () {
        var start = new Date(ev.starts_at);
        var end = ev.ends_at ? new Date(ev.ends_at) : new Date(start.getTime() + 3 * 3600000);
        var fmt = function (d) {
          return d.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
        };
        var ics = 'BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nDTSTART:' + fmt(start) + '\nDTEND:' + fmt(end) +
          '\nSUMMARY:' + ev.title + '\nLOCATION:' + ev.venue + ', ' + ev.city + '\nEND:VEVENT\nEND:VCALENDAR';
        var blob = new Blob([ics], { type: 'text/calendar' });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = ev.slug + '.ics';
        a.click();
      });
    }
  }

  function applyUrlParams() {
    var params = new URLSearchParams(window.location.search);
    var tier = params.get('tier');
    var qty = Math.max(1, Number(params.get('qty') || 1));
    if (tier && eventData) {
      cart[tier] = qty;
      var span = root.querySelector('[data-qty-val="' + tier + '"]');
      if (span) span.textContent = qty;
      updateSummary();
      setTimeout(function () {
        document.getElementById('tickets').scrollIntoView({ behavior: 'smooth' });
      }, 400);
    }
    if (window.location.hash === '#tickets' || window.location.hash === '#waitlist') {
      setTimeout(function () {
        var el = document.getElementById(window.location.hash.slice(1)) || document.getElementById('tickets');
        if (el) el.scrollIntoView({ behavior: 'smooth' });
      }, 500);
    }
  }

  function joinWaitlist() {
    var email = document.getElementById('waitlist-email').value.trim();
    if (!email) return alert('Enter your email');
    fetch(API + '/gigs/events/' + encodeURIComponent(eventData.id) + '/waitlist', {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ email: email }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        alert(d.success ? (d.data.message || 'You are on the waitlist') : (d.error || 'Failed'));
      });
  }

  function checkout() {
    var items = [];
    Object.keys(cart).forEach(function (id) {
      if (cart[id] > 0) items.push({ ticket_type_id: id, quantity: cart[id] });
    });
    if (!items.length) return;

    var name = document.getElementById('tkt-name').value.trim();
    var email = document.getElementById('tkt-email').value.trim();
    var phone = document.getElementById('tkt-phone').value.trim();
    var promo = document.getElementById('tkt-promo').value.trim();
    var msgEl = document.getElementById('tkt-msg');
    msgEl.textContent = 'Creating order…';
    msgEl.className = 'tkt-msg';

    fetch(API + '/ticket-orders', {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        event_id: eventData.id,
        items: items,
        buyer_name: name,
        buyer_email: email,
        buyer_phone: phone,
        promo_code: promo || undefined,
      }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Checkout failed');
        return fetch(API + '/payfast/initiate', {
          method: 'POST',
          headers: authHeaders(),
          body: JSON.stringify({
            ticket_order_id: d.data.order_id,
            return_url: window.location.origin + '/ticket-success?order=' + encodeURIComponent(d.data.order_id),
            cancel_url: window.location.href,
          }),
        }).then(function (r2) { return r2.json().then(function (pay) { return { order: d.data, pay: pay }; }); });
      })
      .then(function (result) {
        if (!result.pay.success) throw new Error(result.pay.error || 'Payment failed to start');
        var form = document.createElement('form');
        form.method = 'POST';
        form.action = result.pay.data.process_url;
        Object.keys(result.pay.data.fields).forEach(function (key) {
          var input = document.createElement('input');
          input.type = 'hidden';
          input.name = key;
          input.value = result.pay.data.fields[key];
          form.appendChild(input);
        });
        document.body.appendChild(form);
        form.submit();
      })
      .catch(function (err) {
        msgEl.textContent = err.message;
        msgEl.className = 'tkt-msg error';
      });
  }

  if (!slug) {
    showError('Event not found');
    return;
  }

  fetch(API + '/gigs/events/' + encodeURIComponent(slug), { headers: authHeaders() })
    .then(function (r) { return r.json(); })
    .then(function (d) {
      if (!d.success) throw new Error(d.error || 'Not found');
      renderEvent(d.data.event);
    })
    .catch(function (err) { showError(err.message); });
})();
