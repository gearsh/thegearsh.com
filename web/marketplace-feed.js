/**
 * Gearsh Creative Services Marketplace — homepage + search UI
 */
(function (global) {
  'use strict';

  var API = '/api/marketplace/services';

  function escapeHtml(str) {
    return global.GearshMarketplace
      ? GearshMarketplace.escapeHtml(str)
      : String(str || '');
  }

  function formatRating(rating, count) {
    var r = Number(rating || 0);
    if (!r && !count) return '';
    return (r ? r.toFixed(1) : 'New') + (count ? ' · ' + count + ' reviews' : '');
  }

  function renderServiceCard(service) {
    var href = service.book_url || (service.provider_username
      ? '/book-gig?artist=' + encodeURIComponent(service.provider_username)
      : '#');
    var img = service.provider_image || 'icons/Icon-512.png';
    var rating = formatRating(service.rating, service.review_count);
    var distance = service.distance_label || (service.distance_km != null
      ? Math.round(service.distance_km) + ' km away'
      : '');

    return '<a class="svc-card" href="' + escapeHtml(href) + '">' +
      '<div class="svc-card-top">' +
        '<span class="svc-cat"><i class="' + escapeHtml(service.category_icon || 'ti ti-tag') + '"></i> ' +
          escapeHtml(service.category_short || service.category_title || 'Service') + '</span>' +
        (service.is_featured ? '<span class="svc-badge">Featured</span>' : '') +
      '</div>' +
      '<h3 class="svc-name">' + escapeHtml(service.name) + '</h3>' +
      '<p class="svc-provider">by ' + escapeHtml(service.provider_name || 'Creator') + '</p>' +
      (service.description
        ? '<p class="svc-desc">' + escapeHtml(service.description).slice(0, 120) + '</p>'
        : '') +
      '<div class="svc-foot">' +
        '<div class="svc-price">' + escapeHtml(service.price_label || ('from R' + Number(service.price || 0).toLocaleString('en-ZA'))) + '</div>' +
        '<div class="svc-meta">' +
          (rating ? '<span><i class="ti ti-star-filled"></i> ' + escapeHtml(rating) + '</span>' : '') +
          (distance ? '<span>' + escapeHtml(distance) + '</span>' : '') +
        '</div>' +
      '</div>' +
      '<div class="svc-provider-row">' +
        '<img src="' + escapeHtml(img) + '" alt="" loading="lazy" width="32" height="32">' +
        '<span>' + escapeHtml(service.provider_location || 'South Africa') + '</span>' +
      '</div>' +
    '</a>';
  }

  function renderSkeleton(count) {
    var html = '';
    for (var i = 0; i < count; i++) {
      html += '<div class="svc-card svc-card--skeleton" aria-hidden="true">' +
        '<div class="skeleton-line w80 skeleton-shimmer"></div>' +
        '<div class="skeleton-line w60 skeleton-shimmer"></div>' +
        '<div class="skeleton-line w40 skeleton-shimmer"></div></div>';
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
    if (!res.ok || !data.success) throw new Error(data.error || 'Failed to load services');
    return data;
  }

  async function loadFeaturedServices(containerId, limit) {
    var el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = renderSkeleton(limit || 8);
    try {
      var data = await fetchServices({ featured: '1', limit: limit || 12 });
      var services = (data.data && data.data.featured) || data.data || [];
      if (!services.length) {
        el.innerHTML = '<div class="mp-empty">Services are being listed. <a href="join-gig.html">Add yours</a>.</div>';
        return;
      }
      el.innerHTML = services.map(renderServiceCard).join('');
      if (global.GearshUI) GearshUI.initLazyImages(el);
    } catch (_) {
      el.innerHTML = '<div class="mp-empty">Could not load services. <a href="/search">Browse search</a>.</div>';
    }
  }

  async function loadCategorySections(containerId) {
    var el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = renderSkeleton(4);
    try {
      var data = await fetchServices({ featured: '1', limit: 3 });
      var sections = (data.data && data.data.sections) || [];
      if (!sections.length) {
        el.innerHTML = '';
        return;
      }
      el.innerHTML = sections.map(function (section) {
        return '<section class="mp-section">' +
          '<div class="mp-section-head">' +
            '<h3><i class="' + escapeHtml(section.icon) + '"></i> ' + escapeHtml(section.title) + '</h3>' +
            '<a href="' + (global.GearshMarketplace
              ? GearshMarketplace.categorySearchUrl(section.category)
              : '/search') + '">View all</a>' +
          '</div>' +
          '<div class="mp-grid">' + section.services.map(renderServiceCard).join('') + '</div>' +
        '</section>';
      }).join('');
      if (global.GearshUI) GearshUI.initLazyImages(el);
    } catch (_) {
      el.innerHTML = '';
    }
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
          '<h2>Services</h2>' +
          '<p>' + services.length + ' creative service' + (services.length === 1 ? '' : 's') + ' match your search</p>' +
        '</div>' +
        '<div class="mp-grid">' + services.map(renderServiceCard).join('') + '</div>' +
      '</section>';
    if (global.GearshUI) GearshUI.initLazyImages(container);
  }

  global.GearshMarketplaceFeed = {
    renderServiceCard: renderServiceCard,
    renderCategoryPills: renderCategoryPills,
    initHeroSearch: initHeroSearch,
    loadFeaturedServices: loadFeaturedServices,
    loadCategorySections: loadCategorySections,
    renderSearchResults: renderSearchResults,
    fetchServices: fetchServices,
  };
})(typeof window !== 'undefined' ? window : this);
