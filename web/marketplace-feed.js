/**
 * Gearsh Creative Gigs Marketplace — homepage + search UI
 */
(function (global) {
  'use strict';

  var API = '/api/marketplace/services';
  var CACHE_KEY = 'gearsh_mp_home_v1';
  var CACHE_TTL = 5 * 60 * 1000;

  function escapeHtml(str) {
    return global.GearshMarketplace
      ? GearshMarketplace.escapeHtml(str)
      : String(str || '');
  }

  function readCache() {
    try {
      var raw = sessionStorage.getItem(CACHE_KEY);
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (parsed && parsed.ts && Date.now() - parsed.ts < CACHE_TTL) return parsed.data;
    } catch (_) {}
    return null;
  }

  function writeCache(data) {
    try {
      sessionStorage.setItem(CACHE_KEY, JSON.stringify({ ts: Date.now(), data: data }));
    } catch (_) {}
  }

  function isPlaceholderImage(path) {
    var value = String(path || '').toLowerCase();
    if (!value) return true;
    return value.indexOf('/artists.png') !== -1
      || value.indexOf('artists/artists.png') !== -1
      || value.indexOf('icon-512') !== -1
      || value.indexOf('/icons/icon') !== -1;
  }

  var IMG_PLACEHOLDER = 'data:image/svg+xml,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"><rect fill="#181818" width="1" height="1"/></svg>'
  );

  function lazyImgTag(src, alt) {
    return '<img src="' + IMG_PLACEHOLDER + '" data-src="' + escapeHtml(src) + '" alt="' + escapeHtml(alt) + '" loading="lazy" decoding="async" class="lazy-img" width="320" height="320">';
  }

  function renderServiceCard(service) {
    var href = service.book_url || (service.provider_username
      ? '/book-gig?artist=' + encodeURIComponent(service.provider_username)
      : '#');
    var img = service.provider_image || 'icons/Icon-512.png';
    var hasPhoto = !isPlaceholderImage(img);
    var price = service.price_label || ('from R' + Number(service.price || 0).toLocaleString('en-ZA'));
    var category = service.category_short || service.category_title || 'Gig';
    var provider = service.provider_name || 'Creator';
    var location = service.provider_location || 'South Africa';
    var rating = Number(service.rating || 0);
    var metaLine = escapeHtml(provider);
    if (location) metaLine += ' · ' + escapeHtml(location);
    if (rating > 0) {
      metaLine += ' · <i class="ti ti-star-filled"></i> ' + rating.toFixed(1);
    }

    var mediaInner = hasPhoto
      ? lazyImgTag(img, provider)
      : ('<div class="svc-card-fallback" aria-hidden="true">' +
          '<i class="' + escapeHtml(service.category_icon || 'ti ti-tag') + '"></i>' +
        '</div>');

    return '<a class="svc-card" href="' + escapeHtml(href) + '" aria-label="' + escapeHtml(service.name + ', ' + price) + '">' +
      '<div class="svc-card-media">' +
        mediaInner +
        '<span class="svc-card-cat"><i class="' + escapeHtml(service.category_icon || 'ti ti-tag') + '"></i> ' +
          escapeHtml(category) + '</span>' +
        (service.is_featured ? '<span class="svc-card-badge">Featured</span>' : '') +
        '<span class="svc-card-price">' + escapeHtml(price) + '</span>' +
      '</div>' +
      '<div class="svc-card-body">' +
        '<div class="svc-card-name">' + escapeHtml(service.name) + '</div>' +
        '<div class="svc-card-meta">' + metaLine + '</div>' +
      '</div>' +
    '</a>';
  }

  function renderSkeleton(count) {
    var html = '';
    for (var i = 0; i < count; i++) {
      html += '<div class="svc-card svc-card--skeleton" aria-hidden="true">' +
        '<div class="svc-card-media skeleton-shimmer"></div>' +
        '<div class="svc-card-body">' +
          '<div class="skeleton-line w80 skeleton-shimmer"></div>' +
          '<div class="skeleton-line w60 skeleton-shimmer"></div>' +
        '</div></div>';
    }
    return html;
  }

  function renderCategoryPills(containerId) {
    var el = document.getElementById(containerId);
    if (!el || !global.GearshMarketplace) return;
    el.innerHTML = GearshMarketplace.FEATURED.map(function (cat) {
      return '<a class="mp-cat-pill" href="' + GearshMarketplace.categorySearchUrl(cat.id) + '">' +
        '<i class="' + cat.icon + '"></i> ' + escapeHtml(cat.title) + '</a>';
    }).join('');
  }

  function initHeroSearch(inputId, formId) {
    var input = document.getElementById(inputId);
    if (!input || !global.GearshMarketplace) return;

    var placeholders = GearshMarketplace.HERO_PLACEHOLDERS;
    var idx = 0;
    input.placeholder = placeholders[0];

    setInterval(function () {
      idx = (idx + 1) % placeholders.length;
      input.placeholder = placeholders[idx];
    }, 3200);

    var form = document.getElementById(formId);
    if (form) {
      form.addEventListener('submit', function (e) {
        e.preventDefault();
        var q = input.value.trim();
        window.location.href = q ? ('/search?q=' + encodeURIComponent(q)) : '/search';
      });
    }
  }

  async function fetchServices(params) {
    var url = new URL(API, window.location.origin);
    Object.keys(params || {}).forEach(function (key) {
      if (params[key] != null && params[key] !== '') url.searchParams.set(key, params[key]);
    });
    var res = await fetch(url.toString(), { headers: { Accept: 'application/json' } });
    var data = await res.json();
    if (!res.ok || !data.success) throw new Error(data.error || 'Failed to load gigs');
    return data;
  }

  function paintFeatured(containerId, services, limit) {
    var el = document.getElementById(containerId);
    if (!el) return;
    if (!services || !services.length) {
      el.innerHTML = '<div class="mp-empty">Gigs are being listed. <a href="join-gig.html">Add yours</a>.</div>';
      return;
    }
    el.innerHTML = services.slice(0, limit || 12).map(renderServiceCard).join('');
    if (global.GearshUI) GearshUI.initLazyImages(el);
  }

  function paintCategorySections(containerId, sections) {
    var el = document.getElementById(containerId);
    if (!el) return;
    if (!sections || !sections.length) {
      el.innerHTML = '';
      return;
    }
    el.innerHTML = sections.map(function (section) {
      return '<section class="mp-section">' +
        '<div class="mp-section-head">' +
          '<h3 class="mp-section-title"><i class="' + escapeHtml(section.icon) + '"></i> ' + escapeHtml(section.title) + '</h3>' +
          '<a href="' + (global.GearshMarketplace
            ? GearshMarketplace.categorySearchUrl(section.category)
            : '/search') + '">View all</a>' +
        '</div>' +
        '<div class="mp-grid">' + section.services.map(renderServiceCard).join('') + '</div>' +
      '</section>';
    }).join('');
    if (global.GearshUI) GearshUI.initLazyImages(el);
  }

  async function loadHomeMarketplace(featuredId, sectionsId, limit) {
    var featuredEl = document.getElementById(featuredId);
    var sectionsEl = document.getElementById(sectionsId);
    if (featuredEl) featuredEl.innerHTML = renderSkeleton(limit || 8);
    if (sectionsEl) sectionsEl.innerHTML = renderSkeleton(4);

    var cached = readCache();
    if (cached) {
      paintFeatured(featuredId, cached.featured, limit);
      paintCategorySections(sectionsId, cached.sections);
    }

    try {
      var data = await fetchServices({ featured: '1', limit: limit || 12 });
      var payload = data.data || {};
      writeCache(payload);
      paintFeatured(featuredId, payload.featured || [], limit);
      paintCategorySections(sectionsId, payload.sections || []);
    } catch (_) {
      if (!cached && featuredEl) {
        featuredEl.innerHTML = '<div class="mp-empty">Could not load gigs. <a href="/search">Browse search</a>.</div>';
      }
      if (!cached && sectionsEl) sectionsEl.innerHTML = '';
    }
  }

  function scheduleHomeMarketplace(blockSelector, featuredId, sectionsId, limit) {
    var target = document.querySelector(blockSelector || '#marketplace-block');
    if (!target || typeof IntersectionObserver === 'undefined') {
      loadHomeMarketplace(featuredId, sectionsId, limit);
      return;
    }
    var started = false;
    var observer = new IntersectionObserver(function (entries) {
      if (started) return;
      if (!entries.some(function (e) { return e.isIntersecting; })) return;
      started = true;
      observer.disconnect();
      loadHomeMarketplace(featuredId, sectionsId, limit);
    }, { rootMargin: '320px 0px' });
    observer.observe(target);
  }

  async function loadFeaturedServices(containerId, limit) {
    return loadHomeMarketplace(containerId, '', limit);
  }

  async function loadCategorySections(containerId) {
    var cached = readCache();
    if (cached) {
      paintCategorySections(containerId, cached.sections);
      return;
    }
    await loadHomeMarketplace('', containerId, 12);
  }

  function renderSearchResults(services, container) {
    if (!container) return;
    if (!services || !services.length) {
      container.innerHTML = '';
      return;
    }
    container.innerHTML =
      '<section class="mp-search-block">' +
        '<div class="mp-search-head">' +
          '<h2><i class="ti ti-briefcase"></i> Gigs</h2>' +
        '</div>' +
        '<div class="mp-grid">' + services.map(renderServiceCard).join('') + '</div>' +
      '</section>';
    if (global.GearshUI) GearshUI.initLazyImages(container);
  }

  global.GearshMarketplaceFeed = {
    renderServiceCard: renderServiceCard,
    renderCategoryPills: renderCategoryPills,
    initHeroSearch: initHeroSearch,
    loadHomeMarketplace: loadHomeMarketplace,
    scheduleHomeMarketplace: scheduleHomeMarketplace,
    loadFeaturedServices: loadFeaturedServices,
    loadCategorySections: loadCategorySections,
    renderSearchResults: renderSearchResults,
    fetchServices: fetchServices,
  };
})(typeof window !== 'undefined' ? window : this);
