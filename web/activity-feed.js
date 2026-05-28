/**
 * Gearsh Activity Feed — reusable feed renderer
 * Modes: artist (per profile), following (unified dashboard feed)
 */
(function (global) {
  'use strict';

  var API_BASE = '/api';
  var POLL_MS = 45000;

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function resolveMedia(path) {
    if (!path) return '/icons/Icon-512.png';
    if (/^https?:\/\//i.test(path) || path.startsWith('data:')) return path;
    if (path.startsWith('/')) return path;
    return '/' + path.replace(/^\/?/, '');
  }

  function authHeaders(token) {
    var headers = { Accept: 'application/json' };
    if (token) headers.Authorization = 'Bearer ' + token;
    return headers;
  }

  function ActivityFeed(options) {
    this.container = typeof options.container === 'string'
      ? document.querySelector(options.container)
      : options.container;
    this.mode = options.mode || 'artist';
    this.artistId = options.artistId || null;
    this.token = options.token || localStorage.getItem('gearsh_token') || '';
    this.onBook = options.onBook || null;
    this.cursor = null;
    this.loading = false;
    this.done = false;
    this.artist = null;
    this.pollTimer = null;
    this.pullStartY = 0;
    this.pullEl = null;

    if (!this.container) return;
    this.init();
  }

  ActivityFeed.prototype.init = function () {
    var self = this;
    this.container.innerHTML =
      '<div class="act-pull-hint" id="act-pull-hint"></div>' +
      '<div id="act-feed-header-slot"></div>' +
      '<div id="act-highlights-slot"></div>' +
      '<div class="act-cards" id="act-cards"></div>' +
      '<div class="act-load-sentinel" id="act-load-sentinel"></div>' +
      '<div class="act-load-more-wrap" id="act-load-more-wrap" hidden>' +
        '<button type="button" class="btn-ghost" id="act-load-more">Load more</button></div>';

    this.pullEl = this.container.querySelector('#act-pull-hint');
    this.cardsEl = this.container.querySelector('#act-cards');
    this.sentinelEl = this.container.querySelector('#act-load-sentinel');

    var loadMore = this.container.querySelector('#act-load-more');
    if (loadMore) {
      loadMore.addEventListener('click', function () { self.load(false); });
    }

    if ('IntersectionObserver' in window && this.sentinelEl) {
      this.observer = new IntersectionObserver(function (entries) {
        if (entries[0].isIntersecting) self.load(false);
      }, { rootMargin: '200px' });
      this.observer.observe(this.sentinelEl);
    }

    this.bindPullRefresh();
    this.load(true);
    this.startPolling();
  };

  ActivityFeed.prototype.bindPullRefresh = function () {
    var self = this;
    var touchZone = this.container.closest('.act-feed-shell') || this.container;

    touchZone.addEventListener('touchstart', function (e) {
      if (window.scrollY <= 4) self.pullStartY = e.touches[0].clientY;
    }, { passive: true });

    touchZone.addEventListener('touchmove', function (e) {
      if (!self.pullStartY || window.scrollY > 4) return;
      var delta = e.touches[0].clientY - self.pullStartY;
      if (delta > 70 && self.pullEl) {
        self.pullEl.textContent = 'Release to refresh';
        self.pullEl.classList.add('is-refreshing');
      }
    }, { passive: true });

    touchZone.addEventListener('touchend', function () {
      if (self.pullEl && self.pullEl.classList.contains('is-refreshing')) {
        self.pullEl.textContent = 'Refreshing…';
        self.load(true);
      }
      self.pullStartY = 0;
      setTimeout(function () {
        if (self.pullEl) {
          self.pullEl.textContent = '';
          self.pullEl.classList.remove('is-refreshing');
        }
      }, 800);
    });
  };

  ActivityFeed.prototype.startPolling = function () {
    var self = this;
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.pollTimer = setInterval(function () {
      if (document.hidden) return;
      self.load(true, true);
    }, POLL_MS);
  };

  ActivityFeed.prototype.apiUrl = function (reset) {
    if (this.mode === 'following') {
      var url = API_BASE + '/activity/following?limit=10';
      if (!reset && this.cursor) url += '&cursor=' + encodeURIComponent(this.cursor);
      return url;
    }
    var base = API_BASE + '/artists/' + encodeURIComponent(this.artistId) + '/activity?limit=10';
    if (!reset && this.cursor) base += '&cursor=' + encodeURIComponent(this.cursor);
    return base;
  };

  ActivityFeed.prototype.load = function (reset, silent) {
    var self = this;
    if (this.loading || (!reset && this.done)) return;
    if (reset) {
      this.cursor = null;
      this.done = false;
      if (!silent) this.renderSkeletons();
    }
    this.loading = true;

    fetch(this.apiUrl(reset), { headers: authHeaders(this.token) })
      .then(function (res) { return res.json(); })
      .then(function (payload) {
        if (!payload.success) throw new Error(payload.error || 'Could not load feed');
        var data = payload.data || {};
        if (self.mode === 'artist') {
          self.artist = data.artist;
          if (reset && !silent) {
            self.renderHeader(data.artist);
            self.renderHighlights(data.highlights || []);
          }
        }
        var items = data.activities || [];
        self.cursor = data.next_cursor || null;
        if (!items.length && reset) self.renderEmpty();
        else if (reset) self.cardsEl.innerHTML = '';
        if (!items.length) self.done = true;
        items.forEach(function (item) {
          self.cardsEl.insertAdjacentHTML('beforeend', self.renderCard(item));
        });
        self.bindCardEvents();
        var wrap = self.container.querySelector('#act-load-more-wrap');
        if (wrap) wrap.hidden = self.done || !self.cursor;
      })
      .catch(function (err) {
        if (reset) {
          self.cardsEl.innerHTML = '<div class="act-error">' + escapeHtml(err.message) + '</div>';
        }
      })
      .finally(function () {
        self.loading = false;
      });
  };

  ActivityFeed.prototype.renderSkeletons = function () {
    this.cardsEl.innerHTML =
      '<div class="act-skeleton"></div><div class="act-skeleton"></div>';
  };

  ActivityFeed.prototype.renderHeader = function (artist) {
    if (!artist || this.mode !== 'artist') return;
    var slot = this.container.querySelector('#act-feed-header-slot');
    if (!slot) return;

    var verified = artist.is_verified
      ? '<i class="ti ti-rosette-discount-check act-feed-verified" aria-label="Verified"></i>'
      : '';

    slot.innerHTML =
      '<header class="act-feed-header">' +
        '<img class="act-feed-avatar" src="' + escapeHtml(resolveMedia(artist.image)) + '" alt="">' +
        '<div class="act-feed-header-meta">' +
          '<div class="act-feed-name-row">' +
            '<h2 class="act-feed-name">' + escapeHtml(artist.name) + '</h2>' + verified +
          '</div>' +
          '<p class="act-feed-followers">' + Number(artist.follower_count || 0).toLocaleString() +
            ' follower' + (Number(artist.follower_count) === 1 ? '' : 's') + '</p>' +
        '</div>' +
        '<button type="button" class="act-follow-btn' + (artist.is_following ? ' is-following' : '') +
          '" id="act-follow-btn" data-artist="' + escapeHtml(artist.username || this.artistId) + '">' +
          (artist.is_following ? 'Following' : 'Follow') +
        '</button>' +
      '</header>';

    var btn = slot.querySelector('#act-follow-btn');
    if (btn) {
      btn.addEventListener('click', this.toggleFollow.bind(this));
    }
  };

  ActivityFeed.prototype.renderHighlights = function (highlights) {
    var slot = this.container.querySelector('#act-highlights-slot');
    if (!slot || !highlights.length) {
      if (slot) slot.innerHTML = '';
      return;
    }
    slot.innerHTML =
      '<div class="act-highlights" aria-label="Recent highlights">' +
      highlights.map(function (h) {
        return '<a class="act-highlight" href="#act-' + escapeHtml(h.id) + '">' +
          '<div class="act-highlight-ring"><img src="' + escapeHtml(resolveMedia(h.media_url)) + '" alt=""></div>' +
          '<span class="act-highlight-label">' + escapeHtml(h.type_label || h.title) + '</span></a>';
      }).join('') +
      '</div>';
  };

  ActivityFeed.prototype.renderEmpty = function () {
    var copy = this.mode === 'following'
      ? { title: 'Nothing here yet', text: 'Follow artists you want to book. Their latest gigs, drops, and milestones will show up here.', cta: 'Browse artists', href: '/artists' }
      : { title: 'No activity yet', text: 'When this artist posts gigs, studio sessions, and milestones, you will see them here first.', cta: 'Book this artist', href: null };

    this.cardsEl.innerHTML =
      '<div class="act-empty">' +
        '<i class="ti ti-activity"></i>' +
        '<h3>' + escapeHtml(copy.title) + '</h3>' +
        '<p>' + escapeHtml(copy.text) + '</p>' +
        (copy.href ? '<a href="' + copy.href + '" class="btn-main">' + escapeHtml(copy.cta) + '</a>' : '') +
      '</div>';
  };

  ActivityFeed.prototype.renderMedia = function (item) {
    var urls = (item.media_urls || []).filter(Boolean);
    if (!urls.length) return '';
    if (urls.length === 1) {
      return '<div class="act-card-media"><img src="' + escapeHtml(resolveMedia(urls[0])) + '" alt="" loading="lazy"></div>';
    }
    return '<div class="act-card-media"><div class="act-carousel">' +
      '<div class="act-carousel-track">' +
      urls.map(function (url) {
        return '<div class="act-carousel-slide"><img src="' + escapeHtml(resolveMedia(url)) + '" alt="" loading="lazy"></div>';
      }).join('') +
      '</div><div class="act-carousel-dots">' +
      urls.map(function (_, i) {
        return '<span class="act-carousel-dot' + (i === 0 ? ' is-active' : '') + '"></span>';
      }).join('') +
      '</div></div></div>';
  };

  ActivityFeed.prototype.renderCard = function (item) {
    var artist = item.artist || this.artist || {};
    var locationLine = [item.venue, item.location].filter(Boolean).join(' · ');
    var bookHref = artist.profile_url || (artist.username ? '/book/' + artist.username : '#');
    var showArtistLine = this.mode === 'following';
    var meta = item.metadata || {};
    var ticketUrl = meta.ticket_url || (meta.event_slug ? '/gig/' + meta.event_slug : null);
    var isTicketGig = item.activity_type === 'gig' && (meta.has_tickets || ticketUrl);
    var primaryCta = isTicketGig && ticketUrl
      ? '<a href="' + escapeHtml(ticketUrl) + '" class="act-action-btn act-action-primary act-action-tickets">' +
          '<i class="ti ti-ticket"></i> Buy tickets</a>'
      : '<a href="' + escapeHtml(bookHref) + '" class="act-action-btn act-action-primary">' +
          '<i class="ti ti-calendar-event"></i> View availability</a>';

    return '<article class="act-card" id="act-' + escapeHtml(item.id) + '" data-id="' + escapeHtml(item.id) + '">' +
      '<div class="act-card-head">' +
        (showArtistLine
          ? '<img class="act-card-avatar" src="' + escapeHtml(resolveMedia(artist.image)) + '" alt="">' +
            '<div class="act-card-head-meta">' +
              '<a class="act-card-artist" href="' + escapeHtml(bookHref) + '">' + escapeHtml(artist.name) + '</a>' +
              '<div class="act-card-type">' + escapeHtml(item.type_label) + '</div></div>'
          : '<div class="act-card-head-meta"><div class="act-card-type">' + escapeHtml(item.type_label) + '</div></div>') +
        '<time class="act-card-time">' + escapeHtml(item.relative_time) + '</time>' +
      '</div>' +
      this.renderMedia(item) +
      '<div class="act-card-body">' +
        '<h3 class="act-card-title">' + escapeHtml(item.title) + '</h3>' +
        (item.description ? '<p class="act-card-desc">' + escapeHtml(item.description) + '</p>' : '') +
        (locationLine ? '<div class="act-card-location"><i class="ti ti-map-pin"></i> ' + escapeHtml(locationLine) + '</div>' : '') +
        '<div class="act-card-actions">' +
          '<button type="button" class="act-action-btn' + (item.liked_by_viewer ? ' is-liked' : '') + '" data-like="' + escapeHtml(item.id) + '">' +
            '<i class="ti ti-heart' + (item.liked_by_viewer ? '-filled' : '') + '"></i> ' +
            Number(item.like_count || 0).toLocaleString() +
          '</button>' +
          '<button type="button" class="act-action-btn" data-comment="' + escapeHtml(item.id) + '">' +
            '<i class="ti ti-message-circle"></i> ' + Number(item.comment_count || 0).toLocaleString() +
          '</button>' +
          '<button type="button" class="act-action-btn" data-share="' + escapeHtml(item.id) + '" data-title="' + escapeHtml(item.title) + '">' +
            '<i class="ti ti-share-3"></i> Share</button>' +
          primaryCta +
        '</div></div></article>';
  };

  ActivityFeed.prototype.bindCardEvents = function () {
    var self = this;
    this.cardsEl.querySelectorAll('[data-like]').forEach(function (btn) {
      if (btn.dataset.bound) return;
      btn.dataset.bound = '1';
      btn.addEventListener('click', function () { self.toggleLike(btn); });
    });
    this.cardsEl.querySelectorAll('[data-comment]').forEach(function (btn) {
      if (btn.dataset.bound) return;
      btn.dataset.bound = '1';
      btn.addEventListener('click', function () { self.promptComment(btn.getAttribute('data-comment')); });
    });
    this.cardsEl.querySelectorAll('[data-share]').forEach(function (btn) {
      if (btn.dataset.bound) return;
      btn.dataset.bound = '1';
      btn.addEventListener('click', function () {
        var title = btn.getAttribute('data-title') || 'Gearsh activity';
        var url = new URL('/act/' + encodeURIComponent(btn.getAttribute('data-share')), window.location.origin).toString();
        if (navigator.share) {
          navigator.share({ title: title, url: url }).catch(function () {});
        } else {
          navigator.clipboard.writeText(url);
          btn.textContent = 'Copied';
          setTimeout(function () { btn.innerHTML = '<i class="ti ti-share-3"></i> Share'; }, 1500);
        }
      });
    });

    this.cardsEl.querySelectorAll('.act-carousel-track').forEach(function (track) {
      track.addEventListener('scroll', function () {
        var idx = Math.round(track.scrollLeft / track.clientWidth);
        var dots = track.parentElement.querySelectorAll('.act-carousel-dot');
        dots.forEach(function (dot, i) {
          dot.classList.toggle('is-active', i === idx);
        });
      }, { passive: true });
    });
  };

  ActivityFeed.prototype.toggleFollow = function () {
    var self = this;
    var btn = this.container.querySelector('#act-follow-btn');
    if (!btn) return;
    if (!this.token) {
      window.location.href = '/auth.html?redirect=' + encodeURIComponent(window.location.pathname + window.location.search);
      return;
    }
    fetch(API_BASE + '/artists/' + encodeURIComponent(btn.getAttribute('data-artist')) + '/follow', {
      method: 'POST',
      headers: Object.assign({ 'Content-Type': 'application/json' }, authHeaders(this.token)),
      body: JSON.stringify({ action: 'toggle' }),
    })
      .then(function (res) { return res.json(); })
      .then(function (payload) {
        if (!payload.success) throw new Error(payload.error || 'Follow failed');
        var following = payload.data.is_following;
        btn.classList.toggle('is-following', following);
        btn.textContent = following ? 'Following' : 'Follow';
        var countEl = self.container.querySelector('.act-feed-followers');
        if (countEl) {
          countEl.textContent = Number(payload.data.follower_count || 0).toLocaleString() + ' followers';
        }
      })
      .catch(function (err) { alert(err.message); });
  };

  ActivityFeed.prototype.toggleLike = function (btn) {
    var self = this;
    if (!this.token) {
      window.location.href = '/auth.html?redirect=' + encodeURIComponent(window.location.pathname);
      return;
    }
    var id = btn.getAttribute('data-like');
    fetch(API_BASE + '/activity/' + encodeURIComponent(id) + '/like', {
      method: 'POST',
      headers: authHeaders(this.token),
    })
      .then(function (res) { return res.json(); })
      .then(function (payload) {
        if (!payload.success) throw new Error(payload.error || 'Like failed');
        btn.classList.toggle('is-liked', payload.data.liked);
        var icon = btn.querySelector('i');
        if (icon) icon.className = 'ti ti-heart' + (payload.data.liked ? '-filled' : '');
        var parts = btn.textContent.trim().split(/\s+/);
        parts[parts.length - 1] = Number(payload.data.like_count || 0).toLocaleString();
        btn.innerHTML = '<i class="ti ti-heart' + (payload.data.liked ? '-filled' : '') + '"></i> ' + parts[parts.length - 1];
      })
      .catch(function () {});
  };

  ActivityFeed.prototype.promptComment = function (activityId) {
    if (!this.token) {
      window.location.href = '/auth.html?redirect=' + encodeURIComponent(window.location.pathname);
      return;
    }
    var body = window.prompt('Add a comment');
    if (!body || !body.trim()) return;
    fetch(API_BASE + '/activity/' + encodeURIComponent(activityId) + '/comments', {
      method: 'POST',
      headers: Object.assign({ 'Content-Type': 'application/json' }, authHeaders(this.token)),
      body: JSON.stringify({ body: body.trim() }),
    })
      .then(function (res) { return res.json(); })
      .then(function (payload) {
        if (!payload.success) throw new Error(payload.error || 'Comment failed');
        var card = document.querySelector('[data-id="' + activityId + '"] [data-comment]');
        if (card && payload.data.comment_count != null) {
          card.innerHTML = '<i class="ti ti-message-circle"></i> ' + Number(payload.data.comment_count).toLocaleString();
        }
      })
      .catch(function (err) { alert(err.message); });
  };

  ActivityFeed.prototype.destroy = function () {
    if (this.pollTimer) clearInterval(this.pollTimer);
    if (this.observer) this.observer.disconnect();
  };

  global.GearshActivityFeed = ActivityFeed;
})(typeof window !== 'undefined' ? window : globalThis);
