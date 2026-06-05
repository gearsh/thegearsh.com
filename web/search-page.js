/**
 * Gearsh Search Page
 */
(function () {
  'use strict';

  var input = document.getElementById('search-input');
  var clearBtn = document.getElementById('search-clear');
  var suggestions = document.getElementById('search-suggestions');
  var resultsEl = document.getElementById('search-results');
  var metaEl = document.getElementById('search-meta');
  var chipsEl = document.getElementById('search-chips');
  var trendingEl = document.getElementById('trending-artists');

  if (!input || !resultsEl) return;

  var debounce = GearshUI.debounce;
  var activeIndex = -1;
  var suggestionItems = [];
  var userCoords = null;

  async function ensureLocation() {
    if (userCoords) return userCoords;
    if (global.GearshLocation) {
      try {
        await GearshLocation.init();
        if (GearshLocation.hasPosition()) {
          userCoords = { ready: true };
        }
      } catch (_) {}
    }
    return userCoords;
  }

  function getQueryParam() {
    return new URLSearchParams(window.location.search).get('q') || '';
  }

  function setQueryParam(q) {
    var url = new URL(window.location.href);
    if (q) url.searchParams.set('q', q);
    else url.searchParams.delete('q');
    history.replaceState(null, '', url.pathname + url.search);
  }

  function renderResults(cards, label) {
    if (!cards.length) {
      resultsEl.innerHTML =
        '<div class="state-panel">' +
          '<i class="ti ti-search-off"></i>' +
          '<h3>No artists found</h3>' +
          '<p>Try a different name, genre, or location. Or browse all artists.</p>' +
          '<a href="/artists" class="btn-main" style="margin-top:20px;display:inline-flex">View all artists</a>' +
        '</div>';
      if (metaEl) metaEl.textContent = label || '0 results';
      return;
    }
    resultsEl.innerHTML = '<div class="artist-grid">' +
      cards.map(function (c) { return GearshFeed.renderFeedCard(c); }).join('') +
    '</div>';
    GearshUI.initLazyImages(resultsEl);
    if (metaEl) metaEl.textContent = (label || cards.length + ' artist' + (cards.length === 1 ? '' : 's'));
  }

  function showSuggestions(items) {
    suggestionItems = items;
    activeIndex = -1;
    if (!items.length) {
      suggestions.classList.remove('is-open');
      suggestions.innerHTML = '';
      return;
    }
    suggestions.innerHTML = items.map(function (item, i) {
      var href = GearshFeed.bookUrl(item) || (item.username ? 'book-gig?artist=' + encodeURIComponent(item.username) : '#');
      return '<a class="search-suggestion" href="' + href + '" data-idx="' + i + '" role="option">' +
        '<img src="' + (item.image || 'icons/Icon-512.png') + '" alt="" loading="lazy">' +
        '<div class="search-suggestion-meta">' +
          '<div class="search-suggestion-name">' + GearshFeed.escapeHtml(item.name) + '</div>' +
          '<div class="search-suggestion-sub">' + GearshFeed.escapeHtml(item.genre) + '</div>' +
        '</div>' +
        '<span class="search-suggestion-tag">' + (item.bookable !== false ? 'Book' : 'Artist') + '</span>' +
      '</a>';
    }).join('');
    suggestions.classList.add('is-open');
  }

  async function runSearch(query, skipUrl) {
    var q = (query || '').trim();
    if (!skipUrl) setQueryParam(q);
    clearBtn.classList.toggle('visible', !!q);

    if (!q) {
      suggestions.classList.remove('is-open');
      renderTrending();
      return;
    }

    resultsEl.innerHTML = '<div class="artist-grid">' + GearshFeed.renderFeedSkeleton(8) + '</div>';

    await ensureLocation();

    var local = GearshFeed.searchShowcase(q, 12);
    var apiCards = [];
    var searchBody = { query: q, limit: 40, sortBy: 'nearby' };
    if (global.GearshLocation && GearshLocation.hasPosition && GearshLocation.hasPosition()) {
      searchBody.sortBy = 'nearby';
    }

    try {
      var res = await fetch('/api/search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(searchBody)
      });
      var data = await res.json();
      if (res.ok && data.success) {
        apiCards = (data.data || []).map(GearshFeed.apiArtistToCard);
      }
    } catch (_) {}

    var merged = [];
    var seen = {};
    apiCards.concat(local).forEach(function (card) {
      var key = GearshFeed.normalizeName(card.name);
      if (seen[key]) return;
      seen[key] = true;
      merged.push(card);
    });

    merged.sort(function (a, b) {
      return GearshFeed.compareFeedCards(a, b, null);
    });

    if (global.GearshLocation && GearshLocation.enrichCards) {
      merged = GearshLocation.enrichCards(merged);
      merged.sort(function (a, b) {
        return GearshFeed.compareFeedCards(a, b, null);
      });
    }

    renderResults(merged, merged.length + ' result' + (merged.length === 1 ? '' : 's') + ' for “' + q + '”');
    suggestions.classList.remove('is-open');
  }

  var debouncedSuggest = debounce(function () {
    var q = input.value.trim();
    if (q.length < 2) {
      suggestions.classList.remove('is-open');
      return;
    }
    showSuggestions(GearshFeed.searchShowcase(q, 6));
  }, 180);

  var debouncedSearch = debounce(function () {
    runSearch(input.value);
  }, 320);

  input.addEventListener('input', function () {
    debouncedSuggest();
    debouncedSearch();
  });

  input.addEventListener('keydown', function (e) {
    var opts = suggestions.querySelectorAll('.search-suggestion');
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      activeIndex = Math.min(activeIndex + 1, opts.length - 1);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      activeIndex = Math.max(activeIndex - 1, 0);
    } else if (e.key === 'Enter') {
      if (activeIndex >= 0 && opts[activeIndex]) {
        e.preventDefault();
        window.location.href = opts[activeIndex].href;
        return;
      }
      runSearch(input.value);
      return;
    } else if (e.key === 'Escape') {
      suggestions.classList.remove('is-open');
      return;
    } else {
      return;
    }
    opts.forEach(function (el, i) {
      el.style.background = i === activeIndex ? 'rgba(255,255,255,0.04)' : '';
    });
  });

  clearBtn.addEventListener('click', function () {
    input.value = '';
    clearBtn.classList.remove('visible');
    suggestions.classList.remove('is-open');
    setQueryParam('');
    renderTrending();
    input.focus();
  });

  document.addEventListener('click', function (e) {
    if (!suggestions.contains(e.target) && e.target !== input) {
      suggestions.classList.remove('is-open');
    }
  });

  function renderTrending() {
    var metaText = (global.GearshLocation && GearshLocation.artistsNearLabel)
      ? GearshLocation.artistsNearLabel()
      : 'Browse artists';
    if (metaEl) metaEl.textContent = metaText;
    ensureLocation().then(function () {
      if (metaEl && global.GearshLocation && GearshLocation.artistsNearLabel) {
        metaEl.textContent = GearshLocation.artistsNearLabel();
      }
      var cards = GearshFeed.getShowcase().slice(0, 24).map(function (item) {
        return GearshFeed.showcaseToCard(item, null);
      });
      if (global.GearshLocation && GearshLocation.enrichCards) {
        cards = GearshLocation.enrichCards(cards);
      }
      cards.sort(function (a, b) {
        return GearshFeed.compareFeedCards(a, b, null);
      });
      renderResults(GearshFeed.pickPromotedCards(cards, 12, null, 4));
    });
  }

  function renderTonightSpotlight() {
    var tonight = (window.GearshSchedule && typeof GearshSchedule.today === 'function')
      ? GearshSchedule.today() : null;
    if (!tonight) {
      renderTrending();
      return;
    }
    var slug = tonight.slug;
    var secondaryLoc = String(tonight.secondaryLocation || '').toLowerCase();
    var cards = [];
    var seen = {};

    function consider(card) {
      var key = GearshFeed.normalizeName(card.name);
      if (seen[key]) return;
      cards.push(card);
      seen[key] = true;
    }

    GearshFeed.getShowcase().forEach(function (item) {
      var itemSlug = item.genreSlug || (typeof resolveArtistGenreSlug === 'function'
        ? resolveArtistGenreSlug(item.category, item.genre)
        : 'other');
      if (itemSlug === slug) {
        consider(GearshFeed.showcaseToCard(item, null));
      } else if (secondaryLoc
        && String(item.location || '').toLowerCase().indexOf(secondaryLoc) !== -1) {
        consider(GearshFeed.showcaseToCard(item, null));
      }
    });

    cards.sort(function (a, b) {
      return GearshFeed.compareFeedCards(a, b, slug);
    });

    var promoted = GearshFeed.pickPromotedCards(cards, 24, slug, 6);

    if (metaEl) {
      metaEl.innerHTML = 'Tonight: <strong style="color:var(--g-white)">' +
        GearshFeed.escapeHtml(tonight.title) + '</strong>. ' +
        GearshFeed.escapeHtml(tonight.tagline);
    }
    renderResults(promoted, promoted.length + ' artist' + (promoted.length === 1 ? '' : 's'));
  }
  function initChips() {
    if (!chipsEl) return;
    var chips = ['Amapiano', 'Hip Hop', 'House', 'DJ', 'Gospel', 'Johannesburg', 'Durban'];
    chipsEl.innerHTML = chips.map(function (c) {
      return '<button type="button" class="search-chip" data-q="' + GearshFeed.escapeHtml(c) + '">' + GearshFeed.escapeHtml(c) + '</button>';
    }).join('');
    chipsEl.addEventListener('click', function (e) {
      var btn = e.target.closest('.search-chip');
      if (!btn) return;
      input.value = btn.getAttribute('data-q');
      runSearch(input.value);
    });
  }

  initChips();
  var initial = getQueryParam();
  var spotlight = new URLSearchParams(window.location.search).get('spotlight');
  if (initial) {
    input.value = initial;
    runSearch(initial, true);
  } else if (spotlight === 'tonight') {
    renderTonightSpotlight();
  } else {
    renderTrending();
  }
  input.focus();
})();
