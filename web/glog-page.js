/**
 * G-Log index — search, filters, featured post, load-more pagination
 */
(function () {
  'use strict';

  var PAGE_SIZE = 9;
  var state = {
    query: '',
    category: 'All',
    visible: PAGE_SIZE,
  };

  var featuredEl = document.getElementById('glog-featured');
  var gridEl = document.getElementById('glog-grid');
  var emptyEl = document.getElementById('glog-empty');
  var loadMoreBtn = document.getElementById('glog-load-more');
  var searchInput = document.getElementById('glog-search');
  var filtersEl = document.getElementById('glog-filters');
  var countEl = document.getElementById('glog-count');

  if (!gridEl || typeof GLOG_POSTS === 'undefined') return;

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatDate(iso) {
    try {
      return new Date(iso + 'T12:00:00').toLocaleDateString('en-ZA', {
        year: 'numeric', month: 'long', day: 'numeric',
      });
    } catch (_) {
      return iso;
    }
  }

  function resolveImage(path) {
    if (!path) return '/icons/Icon-512.png';
    if (/^https?:\/\//i.test(path)) return path;
    if (path.startsWith('/')) return path;
    return '/' + path.replace(/^\/?/, '');
  }

  function postMatches(post) {
    if (state.category !== 'All') {
      var cats = post.categories || [];
      var hit = false;
      for (var i = 0; i < cats.length; i++) {
        if (cats[i] === state.category) { hit = true; break; }
      }
      if (!hit) return false;
    }
    var q = state.query.trim().toLowerCase();
    if (!q) return true;
    var hay = [
      post.title,
      post.excerpt,
      (post.categories || []).join(' '),
      (post.tags || []).join(' '),
    ].join(' ').toLowerCase();
    return hay.indexOf(q) !== -1;
  }

  function filteredPosts() {
    var featured = typeof getGlogFeaturedPost === 'function' ? getGlogFeaturedPost() : null;
    var list = sortGlogPostsNewest(GLOG_POSTS).filter(function (post) {
      if (featured && post.slug === featured.slug && state.category === 'All' && !state.query) {
        return false;
      }
      return postMatches(post);
    });
    return list;
  }

  function renderTags(tags, limit) {
    limit = limit || 3;
    return (tags || []).slice(0, limit).map(function (tag) {
      return '<span class="glog-tag">' + escapeHtml(tag) + '</span>';
    }).join('');
  }

  function renderMeta(post) {
    var mins = post.readTimeMinutes || estimateGlogReadTime(post.content);
    return '<div class="glog-meta-row">' +
      '<span><i class="ti ti-user"></i> ' + escapeHtml(post.author || 'Gearsh') + '</span>' +
      '<span><i class="ti ti-calendar"></i> ' + formatDate(post.publishedAt) + '</span>' +
      '<span><i class="ti ti-clock"></i> ' + mins + ' min read</span>' +
    '</div>';
  }

  function renderFeatured(post) {
    if (!featuredEl || !post) {
      if (featuredEl) featuredEl.innerHTML = '';
      return;
    }
    if (state.category !== 'All' || state.query) {
      featuredEl.hidden = true;
      return;
    }
    featuredEl.hidden = false;
    featuredEl.innerHTML =
      '<a class="glog-featured reveal" href="/glog/' + encodeURIComponent(post.slug) + '">' +
        '<div class="glog-featured-media">' +
          '<span class="glog-featured-label">Featured</span>' +
          '<img src="' + escapeHtml(resolveImage(post.featuredImage)) + '" alt="" loading="eager" decoding="async">' +
        '</div>' +
        '<div class="glog-featured-body">' +
          '<div class="glog-tags">' + renderTags(post.categories, 4) + '</div>' +
          '<h2 class="glog-featured-title">' + escapeHtml(post.title) + '</h2>' +
          '<p class="glog-featured-excerpt">' + escapeHtml(post.excerpt) + '</p>' +
          renderMeta(post) +
          '<span class="glog-read-link">Read story <i class="ti ti-arrow-right"></i></span>' +
        '</div>' +
      '</a>';
  }

  function renderCard(post) {
    return '<a class="glog-card reveal" href="/glog/' + encodeURIComponent(post.slug) + '">' +
      '<div class="glog-card-media">' +
        '<img src="' + escapeHtml(resolveImage(post.featuredImage)) + '" alt="" loading="lazy" decoding="async">' +
      '</div>' +
      '<div class="glog-card-body">' +
        '<div class="glog-tags">' + renderTags(post.categories, 2) + '</div>' +
        '<h3 class="glog-card-title">' + escapeHtml(post.title) + '</h3>' +
        '<p class="glog-card-excerpt">' + escapeHtml(post.excerpt) + '</p>' +
        renderMeta(post) +
      '</div>' +
    '</a>';
  }

  function render() {
    var posts = filteredPosts();
    var slice = posts.slice(0, state.visible);

    if (countEl) {
      countEl.textContent = posts.length + ' stor' + (posts.length === 1 ? 'y' : 'ies');
    }

    var featured = typeof getGlogFeaturedPost === 'function' ? getGlogFeaturedPost() : null;
    renderFeatured(featured);

    if (!slice.length) {
      gridEl.innerHTML = '';
      if (emptyEl) emptyEl.hidden = false;
      if (loadMoreBtn) loadMoreBtn.hidden = true;
      return;
    }

    if (emptyEl) emptyEl.hidden = true;
    gridEl.innerHTML = slice.map(renderCard).join('');

    if (loadMoreBtn) {
      loadMoreBtn.hidden = slice.length >= posts.length;
    }

    if (window.GearshUI) {
      GearshUI.initReveal();
      GearshUI.initLazyImages(gridEl);
    }
  }

  function buildFilters() {
    if (!filtersEl || typeof GLOG_CATEGORIES === 'undefined') return;
    filtersEl.innerHTML = GLOG_CATEGORIES.map(function (cat) {
      var active = cat === state.category ? ' is-active' : '';
      return '<button type="button" class="glog-filter' + active + '" data-category="' + escapeHtml(cat) + '">' + escapeHtml(cat) + '</button>';
    }).join('');

    filtersEl.addEventListener('click', function (e) {
      var btn = e.target.closest('.glog-filter');
      if (!btn) return;
      state.category = btn.getAttribute('data-category') || 'All';
      state.visible = PAGE_SIZE;
      filtersEl.querySelectorAll('.glog-filter').forEach(function (el) {
        el.classList.toggle('is-active', el === btn);
      });
      render();
    });
  }

  if (searchInput) {
    var debounced = GearshUI.debounce(function () {
      state.query = searchInput.value;
      state.visible = PAGE_SIZE;
      render();
    }, 220);
    searchInput.addEventListener('input', debounced);
  }

  if (loadMoreBtn) {
    loadMoreBtn.addEventListener('click', function () {
      state.visible += PAGE_SIZE;
      render();
    });
  }

  function initFromUrl() {
    var params = new URLSearchParams(window.location.search);
    var category = params.get('category');
    var tag = params.get('tag');
    if (category && typeof GLOG_CATEGORIES !== 'undefined' && GLOG_CATEGORIES.indexOf(category) !== -1) {
      state.category = category;
    }
    if (tag) {
      state.query = tag;
      if (searchInput) searchInput.value = tag;
    }
  }

  initFromUrl();
  buildFilters();
  if (state.category !== 'All' && filtersEl) {
    filtersEl.querySelectorAll('.glog-filter').forEach(function (el) {
      el.classList.toggle('is-active', el.getAttribute('data-category') === state.category);
    });
  }
  render();
})();
