/**
 * Gearsh Artists Directory Page
 */
(function (global) {
  'use strict';

  var grid = document.getElementById('artist-grid');
  var countEl = document.getElementById('artist-count');
  var loadMoreBtn = document.getElementById('load-more');
  var drawerOverlay = document.getElementById('filter-drawer-overlay');
  var drawer = document.getElementById('filter-drawer');
  var mobileFilterBtn = document.getElementById('filters-mobile-btn');

  if (!grid) return;

  var allCards = [];
  var filtered = [];
  var pageSize = 24;
  var page = 1;

  var filters = {
    q: '',
    genre: 'all',
    category: 'all',
    location: 'all',
    verified: false,
    trending: false,
    bookable: false,
    sort: 'nearby'
  };

  var SA_LOCATIONS = [
    'Johannesburg', 'Cape Town', 'Durban', 'Pretoria', 'Soweto',
    'Tembisa', 'Polokwane', 'Louis Trichardt', 'Thohoyandou', 'Tzaneen',
    'Bloemfontein', 'Port Elizabeth', 'East London'
  ];

  function readUrlState() {
    var p = new URLSearchParams(window.location.search);
    filters.q = p.get('q') || '';
    filters.genre = p.get('genre') || 'all';
    filters.category = p.get('category') || 'all';
    filters.location = p.get('location') || 'all';
    filters.verified = p.get('verified') === '1';
    filters.trending = p.get('trending') === '1';
    filters.bookable = p.get('bookable') === '1';
    filters.sort = p.get('sort') || 'nearby';
  }

  function writeUrlState() {
    var p = new URLSearchParams();
    if (filters.q) p.set('q', filters.q);
    if (filters.genre !== 'all') p.set('genre', filters.genre);
    if (filters.category !== 'all') p.set('category', filters.category);
    if (filters.location !== 'all') p.set('location', filters.location);
    if (filters.verified) p.set('verified', '1');
    if (filters.trending) p.set('trending', '1');
    if (filters.bookable) p.set('bookable', '1');
    if (filters.sort !== 'nearby') p.set('sort', filters.sort);
    var qs = p.toString();
    history.replaceState(null, '', qs ? ('?' + qs) : window.location.pathname);
  }

  function syncFilterControls() {
    document.querySelectorAll('[data-filter]').forEach(function (el) {
      var key = el.getAttribute('data-filter');
      if (el.type === 'checkbox') {
        el.checked = !!filters[key];
        var pill = el.closest('.filter-pill');
        if (pill) pill.classList.toggle('active', el.checked);
      } else if (el.tagName === 'SELECT') {
        el.value = filters[key] || 'all';
      }
    });
    var searchInput = document.getElementById('dir-search');
    if (searchInput) searchInput.value = filters.q;
  }

  function cloneSelectOptions(fromId, toId) {
    var from = document.getElementById(fromId);
    var to = document.getElementById(toId);
    if (!from || !to) return;
    to.innerHTML = from.innerHTML;
  }

  function applyFilters() {
    filtered = GearshFeed.filterCards(allCards, filters);
    filtered = GearshFeed.sortCards(filtered, filters.sort, filters.genre);
    page = 1;
    renderPage();
    writeUrlState();
  }

  function renderPage() {
    var slice = filtered.slice(0, page * pageSize);
    if (!slice.length) {
      grid.innerHTML =
        '<div class="state-panel" style="grid-column:1/-1">' +
          '<i class="ti ti-users-minus"></i>' +
          '<h3>No artists match</h3>' +
          '<p>Adjust your filters or search for something else.</p>' +
        '</div>';
      if (countEl) countEl.textContent = '0 artists';
      if (loadMoreBtn) loadMoreBtn.style.display = 'none';
      return;
    }
    grid.innerHTML = slice.map(function (c) { return GearshFeed.renderFeedCard(c); }).join('');
    GearshUI.initLazyImages(grid);
    if (countEl) countEl.textContent = filtered.length + ' artist' + (filtered.length === 1 ? '' : 's');
    if (loadMoreBtn) {
      loadMoreBtn.style.display = slice.length < filtered.length ? 'inline-flex' : 'none';
    }
  }

  function populateSelects() {
    var cats = {};
    var genres = {};
    allCards.forEach(function (c) {
      if (c.category) cats[c.category] = true;
      if (c.genreSlug) genres[c.genreSlug] = true;
    });

    var catSel = document.getElementById('filter-category');
    if (catSel) {
      Object.keys(cats).sort().forEach(function (c) {
        var opt = document.createElement('option');
        opt.value = c;
        opt.textContent = c;
        catSel.appendChild(opt);
      });
    }

    var genreSel = document.getElementById('filter-genre');
    if (genreSel && typeof GENRE_FEED_CATEGORIES !== 'undefined') {
      GENRE_FEED_CATEGORIES.forEach(function (g) {
        if (g.id.indexOf('genre-') !== 0) return;
        var opt = document.createElement('option');
        opt.value = g.id.slice(6);
        opt.textContent = g.title;
        genreSel.appendChild(opt);
      });
    }

    var locSel = document.getElementById('filter-location');
    if (locSel) {
      SA_LOCATIONS.forEach(function (loc) {
        var opt = document.createElement('option');
        opt.value = loc;
        opt.textContent = loc;
        locSel.appendChild(opt);
      });
    }
  }

  function bindFilters() {
    document.querySelectorAll('[data-filter]').forEach(function (el) {
      el.addEventListener('change', function () {
        var key = el.getAttribute('data-filter');
        if (el.type === 'checkbox') {
          filters[key] = el.checked;
          var pill = el.closest('.filter-pill');
          if (pill) pill.classList.toggle('active', el.checked);
        } else {
          filters[key] = el.value;
        }
        applyFilters();
      });
    });

    document.querySelectorAll('.filter-pill').forEach(function (pill) {
      pill.addEventListener('click', function (e) {
        var input = pill.querySelector('input[type="checkbox"][data-filter]');
        if (!input || e.target === input) return;
        input.checked = !input.checked;
        input.dispatchEvent(new Event('change', { bubbles: true }));
      });
    });

    var searchInput = document.getElementById('dir-search');
    if (searchInput) {
      searchInput.addEventListener('input', GearshUI.debounce(function () {
        filters.q = searchInput.value.trim();
        applyFilters();
      }, 280));
    }

    if (loadMoreBtn) {
      loadMoreBtn.addEventListener('click', function () {
        page += 1;
        renderPage();
      });
    }

    if (mobileFilterBtn && drawer && drawerOverlay) {
      mobileFilterBtn.addEventListener('click', function () {
        drawer.classList.add('is-open');
        drawerOverlay.classList.add('is-open');
      });
      drawerOverlay.addEventListener('click', closeDrawer);
      var closeBtn = document.getElementById('filter-drawer-close');
      if (closeBtn) closeBtn.addEventListener('click', closeDrawer);
    }
  }

  function closeDrawer() {
    if (drawer) drawer.classList.remove('is-open');
    if (drawerOverlay) drawerOverlay.classList.remove('is-open');
  }

  function updateSortLabels() {
    if (!global.GearshLocation || !GearshLocation.sortNearLabel) return;
    var text = GearshLocation.sortNearLabel();
    document.querySelectorAll('option[value="nearby"]').forEach(function (opt) {
      opt.textContent = text;
    });
  }

  async function init() {
    grid.innerHTML = GearshFeed.renderFeedSkeleton(12);
    readUrlState();

    if (global.GearshLocation) {
      try {
        var locInit = GearshLocation.initFast || GearshLocation.init;
        await locInit();
      } catch (_) {}
      updateSortLabels();
    }

    var data = await GearshFeed.fetchFeedData();
    var index = GearshFeed.buildArtistIndex(data.apiArtists);
    allCards = GearshFeed.buildAllArtistCards(data.apiArtists, index);

    populateSelects();
    cloneSelectOptions('filter-genre', 'filter-genre-mobile');
    cloneSelectOptions('filter-category', 'filter-category-mobile');
    cloneSelectOptions('filter-location', 'filter-location-mobile');
    syncFilterControls();
    bindFilters();
    applyFilters();
  }

  init();
})(typeof window !== 'undefined' ? window : this);
