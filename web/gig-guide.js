(function () {
  'use strict';

  var API = '/api';
  var state = {
    q: '', city: '', category: 'all', filter: '', view: 'grid',
    offset: 0, loading: false, done: false, events: [],
  };

  var grid = document.getElementById('gg-grid');
  var hero = document.getElementById('gg-hero');
  var sentinel = document.getElementById('gg-sentinel');
  var searchTimer = null;

  function escapeHtml(s) {
    return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function formatMoney(n, cur) {
    if (n === 0) return 'Free';
    return (cur === 'ZAR' ? 'R' : cur + ' ') + Number(n || 0).toLocaleString('en-ZA');
  }

  function formatDate(iso) {
    return new Date(iso).toLocaleString('en-ZA', {
      weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    });
  }

  function authHeaders() {
    var h = { Accept: 'application/json' };
    var t = localStorage.getItem('gearsh_token');
    if (t) h.Authorization = 'Bearer ' + t;
    return h;
  }

  function countdown(iso) {
    var diff = new Date(iso).getTime() - Date.now();
    if (diff <= 0) return 'Live now';
    var d = Math.floor(diff / 86400000);
    var h = Math.floor((diff % 86400000) / 3600000);
    if (d > 0) return d + 'd ' + h + 'h to go';
    var m = Math.floor((diff % 3600000) / 60000);
    return h + 'h ' + m + 'm to go';
  }

  function renderCard(ev) {
    var artist = ev.artist || {};
    var priceLabel = ev.is_free ? 'Free' : (ev.price_from != null ? 'From ' + formatMoney(ev.price_from, ev.currency) : 'TBA');
    var badge = ev.sold_out
      ? '<span class="gg-badge sold">Sold out</span>'
      : '<span class="gg-badge avail">' + escapeHtml(ev.availability_label) + '</span>';
    if (ev.has_vip && !ev.sold_out) badge += '<span class="gg-badge vip">VIP</span>';

    var quickVip = ev.vip_tier_id && !ev.sold_out
      ? '<a href="' + escapeHtml(ev.url) + '?tier=' + encodeURIComponent(ev.vip_tier_id) + '&qty=1" class="btn-ghost">VIP</a>'
      : '';

    return '<article class="gg-card">' +
      '<a href="' + escapeHtml(ev.url) + '"><img class="gg-card-flyer" src="' + escapeHtml(ev.flyer_url) + '" alt="" loading="lazy"></a>' +
      '<div class="gg-card-body">' +
        '<div class="gg-card-badges">' + badge + '</div>' +
        '<div class="gg-card-artist">' + escapeHtml(artist.name || 'Artist') +
          (artist.is_verified ? ' <i class="ti ti-rosette-discount-check verified"></i>' : '') + '</div>' +
        '<h3 class="gg-card-title"><a href="' + escapeHtml(ev.url) + '" style="color:inherit;text-decoration:none">' + escapeHtml(ev.title) + '</a></h3>' +
        '<div class="gg-card-meta">' + escapeHtml(formatDate(ev.starts_at)) + '<br>' + escapeHtml(ev.venue) + ', ' + escapeHtml(ev.city) + '</div>' +
        '<div class="gg-card-price">' + escapeHtml(priceLabel) + '</div>' +
        '<div class="gg-card-actions">' +
          (ev.sold_out
            ? '<a href="' + escapeHtml(ev.url) + '#waitlist" class="btn-main">Join waitlist</a>'
            : '<a href="' + escapeHtml(ev.buy_url) + '" class="btn-main"><i class="ti ti-ticket"></i> Buy tickets</a>') +
          quickVip +
        '</div></div></article>';
  }

  function renderHero(featured) {
    if (!featured || !featured.length) {
      hero.innerHTML = '<div class="gg-hero-slide"><div class="gg-hero-bg"></div><div class="gg-hero-overlay"></div>' +
        '<div class="gg-hero-content"><div class="gg-hero-badge"><i class="ti ti-flame"></i> Gig Guide</div>' +
        '<h1 class="gg-hero-title">What\'s popping this weekend?</h1>' +
        '<p class="gg-hero-meta">Discover gigs across South Africa. Buy tickets in seconds.</p></div></div>';
      return;
    }
    hero.innerHTML = '<div class="gg-hero-track">' + featured.map(function (ev) {
      var artist = ev.artist || {};
      return '<div class="gg-hero-slide">' +
        '<div class="gg-hero-bg"><img src="' + escapeHtml(ev.flyer_url) + '" alt=""></div>' +
        '<div class="gg-hero-overlay"></div>' +
        '<div class="gg-hero-content">' +
          '<div class="gg-hero-badge"><i class="ti ti-flame"></i> Trending</div>' +
          '<h1 class="gg-hero-title">' + escapeHtml(ev.title) + '</h1>' +
          '<p class="gg-hero-meta">' + escapeHtml(artist.name || '') + ' · ' + escapeHtml(ev.city) + ' · ' + escapeHtml(formatDate(ev.starts_at)) + '</p>' +
          '<div class="gg-countdown"><i class="ti ti-clock"></i> ' + escapeHtml(countdown(ev.starts_at)) + '</div>' +
          '<div class="gg-hero-actions">' +
            '<a href="' + escapeHtml(ev.buy_url) + '" class="btn-main"><i class="ti ti-ticket"></i> Buy tickets</a>' +
            '<a href="' + escapeHtml(ev.url) + '" class="btn-ghost">Details</a>' +
          '</div></div></div>';
    }).join('') + '</div>';
  }

  function renderFollowing(list) {
    var sec = document.getElementById('gg-following-section');
    var fg = document.getElementById('gg-following-grid');
    if (!list || !list.length) { sec.hidden = true; return; }
    sec.hidden = false;
    fg.innerHTML = list.map(renderCard).join('');
  }

  function buildUrl() {
    var p = new URLSearchParams();
    if (state.q) p.set('q', state.q);
    if (state.city) p.set('city', state.city);
    if (state.category !== 'all') p.set('category', state.category);
    if (state.filter) p.set('filter', state.filter);
    p.set('offset', String(state.offset));
    p.set('limit', '24');
    return API + '/gigs/guide?' + p.toString();
  }

  function load(reset) {
    if (state.loading || (state.done && !reset)) return;
    if (reset) { state.offset = 0; state.done = false; state.events = []; grid.innerHTML = ''; }
    state.loading = true;

    fetch(buildUrl(), { headers: authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Failed');
        var data = d.data;
        if (reset) {
          renderHero(data.featured);
          renderFollowing(data.following);
          populateCities(data.cities);
        }
        var batch = data.events || [];
        if (!batch.length && state.offset === 0) {
          grid.innerHTML = '<div class="gg-empty" style="grid-column:1/-1">' +
            '<h3>No gigs found</h3><p>Try another city or filter. New events drop every week.</p>' +
            '<a href="/join-gig.html" class="btn-main">List your gig</a></div>';
          state.done = true;
          return;
        }
        state.events = state.events.concat(batch);
        grid.insertAdjacentHTML('beforeend', batch.map(renderCard).join(''));
        state.done = !data.has_more;
        state.offset = data.next_offset || state.offset + batch.length;
      })
      .catch(function (err) {
        if (state.offset === 0) {
          grid.innerHTML = '<div class="gg-empty" style="grid-column:1/-1"><p>' + escapeHtml(err.message) + '</p></div>';
        }
      })
      .finally(function () { state.loading = false; });
  }

  function populateCities(cities) {
    var sel = document.getElementById('gg-city');
    var saved = localStorage.getItem('gearsh_gig_city') || '';
    (cities || []).forEach(function (c) {
      var opt = document.createElement('option');
      opt.value = c; opt.textContent = c;
      sel.appendChild(opt);
    });
    if (saved) { sel.value = saved; state.city = saved; }
  }

  document.getElementById('gg-search').addEventListener('input', function (e) {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      state.q = e.target.value.trim();
      load(true);
    }, 300);
  });

  document.getElementById('gg-city').addEventListener('change', function (e) {
    state.city = e.target.value;
    localStorage.setItem('gearsh_gig_city', state.city);
    load(true);
  });

  document.getElementById('gg-chips').addEventListener('click', function (e) {
    var chip = e.target.closest('[data-filter]');
    if (!chip) return;
    document.querySelectorAll('.gg-chip').forEach(function (c) { c.classList.remove('active'); });
    chip.classList.add('active');
    state.filter = chip.getAttribute('data-filter') || '';
    if (state.filter === 'following' && !localStorage.getItem('gearsh_token')) {
      window.location.href = '/auth.html?redirect=' + encodeURIComponent('/gigs');
      return;
    }
    load(true);
  });

  document.getElementById('gg-tabs').addEventListener('click', function (e) {
    var tab = e.target.closest('[data-category]');
    if (!tab) return;
    document.querySelectorAll('.gg-tab').forEach(function (t) { t.classList.remove('active'); });
    tab.classList.add('active');
    state.category = tab.getAttribute('data-category');
    load(true);
  });

  document.querySelector('.gg-view-toggle').addEventListener('click', function (e) {
    var btn = e.target.closest('[data-view]');
    if (!btn) return;
    document.querySelectorAll('.gg-view-btn').forEach(function (b) { b.classList.remove('active'); });
    btn.classList.add('active');
    state.view = btn.getAttribute('data-view');
    grid.classList.toggle('list-view', state.view === 'list');
  });

  if ('IntersectionObserver' in window && sentinel) {
    new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) load(false);
    }, { rootMargin: '300px' }).observe(sentinel);
  }

  var pullStart = 0;
  document.addEventListener('touchstart', function (e) { pullStart = e.touches[0].clientY; }, { passive: true });
  document.addEventListener('touchend', function (e) {
    if (window.scrollY > 10) return;
    if (e.changedTouches[0].clientY - pullStart > 80) {
      var hint = document.getElementById('gg-pull');
      hint.classList.add('show');
      load(true);
      setTimeout(function () { hint.classList.remove('show'); }, 1200);
    }
  }, { passive: true });

  load(true);
})();
