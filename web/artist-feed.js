/**
 * Gearsh Artist Feed Engine
 * Shared by homepage, artists directory, and search results.
 */
(function (global) {
  'use strict';

  var API_BASE = '/api';
  var CACHE_KEY = 'gearsh_feed_cache_v3';
  var CACHE_TTL = 5 * 60 * 1000;
  var PLACEHOLDER = 'data:image/svg+xml,' + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"><rect fill="#181818" width="1" height="1"/></svg>'
  );

  function normalizeName(value) {
    return String(value || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  }

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function bookUrl(artist) {
    if (!artist || !artist.bookable) return null;
    if (artist.username) return 'book-gig?artist=' + encodeURIComponent(String(artist.username).toLowerCase());
    if (artist.profile_url) {
      var match = String(artist.profile_url).match(/\/book\/([^/?#]+)/i);
      if (match) return 'book-gig?artist=' + encodeURIComponent(match[1].toLowerCase());
    }
    if (artist.artist_id) return 'book-gig?artist=' + encodeURIComponent(artist.artist_id);
    return null;
  }

  function claimUrl(item) {
    if (!item || !item.username) return null;
    return 'claim-profile.html?artist=' + encodeURIComponent(String(item.username).toLowerCase());
  }

  function formatPrice(amount) {
    if (!amount) return '';
    return 'from R' + Number(amount).toLocaleString('en-ZA');
  }

  function cardMasteryHours(item) {
    if (item.mastery_hours != null) return Number(item.mastery_hours) || 0;
    if (item.masteryHours != null) return Number(item.masteryHours) || 0;
    return 0;
  }

  function masteryBadgeForHours(hours) {
    if (hours >= 10000) return { label: 'Legend', badgeClass: 'fb-feat' };
    if (hours >= 5000) return { label: 'Expert', badgeClass: 'fb-feat' };
    if (hours >= 100) return { label: 'Rising', badgeClass: 'fb-rise' };
    return null;
  }

  function getShowcase() {
    return typeof SHOWCASE !== 'undefined' ? SHOWCASE : [];
  }

  function getCategories() {
    if (typeof GENRE_FEED_CATEGORIES !== 'undefined') return GENRE_FEED_CATEGORIES;
    return [{ id: 'mastery-legends', title: 'Mastery legends', subtitle: 'Top artists on Gearsh', icon: 'ti ti-crown' }];
  }

  function buildArtistIndex(artists) {
    var index = {};
    (artists || []).forEach(function (artist) {
      index[normalizeName(artist.name)] = artist;
      if (artist.username) index[String(artist.username).toLowerCase()] = artist;
    });
    return index;
  }

  function findArtistMatch(name, index) {
    var key = normalizeName(name);
    if (index[key]) return index[key];
    var keys = Object.keys(index);
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].indexOf(key) !== -1 || key.indexOf(keys[i]) !== -1) return index[keys[i]];
    }
    return null;
  }

  function getShowcaseArtists() {
    if (typeof SA_SHOWCASE_ARTISTS !== 'undefined') return SA_SHOWCASE_ARTISTS;
    return getShowcase();
  }

  function findShowcaseRecord(source) {
    if (!source) return null;
    var list = getShowcaseArtists();
    var username = String(source.username || '').toLowerCase();
    if (username) {
      for (var i = 0; i < list.length; i++) {
        if (String(list[i].username || '').toLowerCase() === username) return list[i];
      }
    }
    var nameKey = normalizeName(source.name);
    for (var j = 0; j < list.length; j++) {
      if (normalizeName(list[j].name) === nameKey) return list[j];
    }
    return findShowcaseImage(source.name);
  }

  function resolveListingPrice(source) {
    var showcase = findShowcaseRecord(source);
    if (showcase && showcase.hourlyRate != null && Number(showcase.hourlyRate) > 0) {
      return formatPrice(showcase.hourlyRate);
    }
    if (source.booking_fee) return formatPrice(source.booking_fee);
    if (source.hourly_rate) return formatPrice(source.hourly_rate);
    if (source.base_rate) return formatPrice(source.base_rate);
    if (source.min_price) return formatPrice(source.min_price);
    return '';
  }

  function findShowcaseImage(name) {
    return getShowcase().find(function (item) {
      return normalizeName(item.name) === normalizeName(name);
    });
  }

  function artistGenreSlugFromRecord(artist) {
    if (artist && artist.genreSlug) return artist.genreSlug;
    if (typeof resolveArtistGenreSlug === 'function') {
      return resolveArtistGenreSlug(artist.category, artist.genre);
    }
    return 'other';
  }

  function showcaseCategories(item) {
    var cats = [];
    var slug = item.genreSlug || artistGenreSlugFromRecord(item);
    cats.push('genre-' + slug);
    if (cardMasteryHours(item) >= 5000 || item.badge === 'Legend' || item.badge === 'Expert') {
      cats.push('mastery-legends');
    }
    return cats;
  }

  function apiArtistToCard(artist) {
    var showcase = findShowcaseImage(artist.name);
    var hours = Number(artist.mastery_hours || 0);
    if (showcase && Number(showcase.masteryHours || 0) > hours) {
      hours = Number(showcase.masteryHours);
    }
    var tier = masteryBadgeForHours(hours);
    return {
      artist_id: artist.artist_id,
      username: artist.username,
      profile_url: artist.profile_url,
      name: artist.name,
      image: artist.image || (showcase && showcase.image) || 'icons/Icon-512.png',
      genre: [artist.category, artist.location].filter(Boolean).join(' · ') || 'Available to book',
      category: artist.category || '',
      location: artist.location || '',
      genreSlug: artistGenreSlugFromRecord(artist),
      badge: tier ? tier.label : (artist.is_verified ? 'Verified' : (artist.is_trending ? 'Trending' : 'Book now')),
      badgeClass: tier ? tier.badgeClass : (artist.is_verified ? 'fb-feat' : (artist.is_trending ? 'fb-rise' : 'fb-deal')),
      price: resolveListingPrice(artist),
      mastery_hours: hours,
      bookable: true,
      is_verified: !!artist.is_verified,
      is_trending: !!artist.is_trending
    };
  }

  function showcaseToCard(item, match) {
    var hours = Math.max(cardMasteryHours(item), match ? cardMasteryHours(match) : 0);
    var tier = masteryBadgeForHours(hours);
    return {
      artist_id: match ? match.artist_id : null,
      username: match ? match.username : (item.username || null),
      profile_url: match ? match.profile_url : null,
      name: item.name,
      image: item.image,
      genre: item.genre || item.category || '',
      category: item.category || '',
      location: item.location || '',
      genreSlug: item.genreSlug || artistGenreSlugFromRecord(item),
      badge: match ? (tier ? tier.label : 'Book now') : (tier ? tier.label : (item.badge || 'Featured')),
      badgeClass: match ? (tier ? tier.badgeClass : 'fb-deal') : (tier ? tier.badgeClass : (item.badgeClass || 'fb-feat')),
      price: resolveListingPrice(item),
      mastery_hours: hours,
      bookable: !!(match || item.username),
      is_verified: match ? !!match.is_verified : false,
      is_trending: match ? !!match.is_trending : false
    };
  }

  function mergeCategoryArtists(categoryId, apiArtists, index, limit) {
    limit = limit || 16;
    var filteredApi = apiArtists || [];
    if (categoryId.indexOf('genre-') === 0) {
      var genreKey = categoryId.slice(6);
      filteredApi = filteredApi.filter(function (artist) {
        return artistGenreSlugFromRecord(artist) === genreKey;
      });
    } else if (categoryId === 'mastery-legends') {
      filteredApi = filteredApi.filter(function (artist) {
        return Number(artist.mastery_hours || 0) >= 5000;
      });
    }

    var cards = filteredApi.map(apiArtistToCard);
    var usedIds = {};
    var usedNames = {};
    cards.forEach(function (card) {
      if (card.artist_id) usedIds[card.artist_id] = true;
      usedNames[normalizeName(card.name)] = true;
    });

    getShowcase().forEach(function (item) {
      if (showcaseCategories(item).indexOf(categoryId) === -1) return;
      var key = normalizeName(item.name);
      if (usedNames[key]) return;
      var match = findArtistMatch(item.name, index);
      if (match && usedIds[match.artist_id]) return;
      cards.push(showcaseToCard(item, match));
      usedNames[key] = true;
      if (match && match.artist_id) usedIds[match.artist_id] = true;
    });

    cards.sort(function (a, b) {
      if (categoryId.indexOf('genre-') === 0 && typeof compareArtistsForGenre === 'function') {
        return compareArtistsForGenre(categoryId.slice(6), a, b);
      }
      var hoursDiff = cardMasteryHours(b) - cardMasteryHours(a);
      if (hoursDiff !== 0) return hoursDiff;
      if (a.bookable === b.bookable) return 0;
      return a.bookable ? -1 : 1;
    });

    return cards.slice(0, limit);
  }

  function buildAllArtistCards(apiArtists, index) {
    var cards = (apiArtists || []).map(apiArtistToCard);
    var usedNames = {};
    cards.forEach(function (c) { usedNames[normalizeName(c.name)] = true; });

    getShowcase().forEach(function (item) {
      var key = normalizeName(item.name);
      if (usedNames[key]) return;
      var match = findArtistMatch(item.name, index);
      cards.push(showcaseToCard(item, match));
      usedNames[key] = true;
    });

    return cards.sort(function (a, b) {
      return cardMasteryHours(b) - cardMasteryHours(a);
    });
  }

  function lazyImgTag(src, alt) {
    return '<img src="' + PLACEHOLDER + '" data-src="' + escapeHtml(src) + '" alt="' + escapeHtml(alt) + '" loading="lazy" decoding="async" class="lazy-img" width="168" height="168">';
  }

  function renderFeedCard(item, opts) {
    opts = opts || {};
    var href = bookUrl(item);
    var actionLabel = 'Book now';
    var classes = 'feed-card';

    if (item.bookable && href) {
      classes += ' is-bookable';
    } else {
      classes += ' is-static';
    }

    var inner =
      '<div class="feed-card-media">' +
        lazyImgTag(item.image, item.name) +
        '<span class="feed-card-badge ' + item.badgeClass + '">' + escapeHtml(item.badge) + '</span>' +
        (item.bookable && href
          ? '<div class="feed-card-action"><span>' + actionLabel + '</span></div>'
          : '') +
      '</div>' +
      '<div class="feed-card-body">' +
        '<div class="feed-card-name">' + escapeHtml(item.name) + '</div>' +
        '<div class="feed-card-genre">' + escapeHtml(item.genre) + '</div>' +
        (item.price ? '<div class="feed-card-price">' + escapeHtml(item.price) + '</div>' : '') +
      '</div>';

    if (href && item.bookable) {
      return '<a class="' + classes + '" href="' + href + '" aria-label="' + escapeHtml(actionLabel + ' — ' + item.name) + '">' + inner + '</a>';
    }
    return '<div class="' + classes + '" aria-label="' + escapeHtml(item.name) + ' — featured artist">' + inner + '</div>';
  }

  function renderFeedSkeleton(count) {
    var html = '';
    for (var i = 0; i < count; i++) {
      html += '<div class="feed-card feed-card--skeleton" aria-hidden="true">' +
        '<div class="feed-card-media skeleton-shimmer"></div>' +
        '<div class="feed-card-body">' +
          '<div class="skeleton-line w80 skeleton-shimmer"></div>' +
          '<div class="skeleton-line w60 skeleton-shimmer"></div>' +
        '</div></div>';
    }
    return html;
  }

  function renderCategorySection(category, cards) {
    var cardsHtml = cards.length
      ? cards.map(function (c) { return renderFeedCard(c); }).join('')
      : '<div class="feed-empty">More artists coming soon. <a href="join-gig.html" style="color:var(--g-accent)">List your gig</a> to appear here.</div>';

    return '<section class="feed-category" id="cat-' + category.id + '">' +
      '<div class="feed-header">' +
        '<div>' +
          '<h3 class="feed-title"><i class="' + category.icon + '" style="font-size:20px;color:var(--g-accent);margin-right:8px;vertical-align:-2px"></i>' + escapeHtml(category.title) + '</h3>' +
          '<p class="feed-subtitle">' + escapeHtml(category.subtitle) + '</p>' +
        '</div>' +
      '</div>' +
      '<div class="feed-row">' + cardsHtml + '</div>' +
    '</section>';
  }

  function renderStory(item) {
    if (!item.image || !item.name) return '';
    var href = bookUrl(item) || '#cat-mastery-legends';
    return '<a class="story-item" href="' + href + '">' +
      '<div class="story-ring">' + lazyImgTag(item.image, item.name) + '</div>' +
      '<span class="story-name">' + escapeHtml(item.name) + '</span></a>';
  }

  function readCache() {
    try {
      var raw = sessionStorage.getItem(CACHE_KEY);
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      if (Date.now() - parsed.ts > CACHE_TTL) return null;
      return parsed.data;
    } catch (_) { return null; }
  }

  function writeCache(data) {
    try {
      sessionStorage.setItem(CACHE_KEY, JSON.stringify({ ts: Date.now(), data: data }));
    } catch (_) {}
  }

  async function fetchFeedData() {
    var cached = readCache();
    if (cached) return cached;

    var categories = [];
    var apiArtists = [];

    try {
      var res = await fetch(API_BASE + '/artists/feed');
      var data = await res.json();
      if (res.ok && data.success) categories = (data.data && data.data.categories) || [];
    } catch (_) {}

    if (categories.length) {
      categories.forEach(function (cat) {
        (cat.artists || []).forEach(function (a) { apiArtists.push(a); });
      });
    } else {
      try {
        var fb = await fetch(API_BASE + '/artists?limit=100');
        var fbData = await fb.json();
        if (fb.ok && fbData.success) apiArtists = fbData.data || [];
      } catch (_) {}
    }

    var result = { categories: categories, apiArtists: apiArtists };
    writeCache(result);
    return result;
  }

  function visibleFeedCategories(categories) {
    var source = categories && categories.length ? categories : getCategories();
    return source.filter(function (category) {
      if (category.id === 'mastery-legends') return true;
      var cards = mergeCategoryArtists(category.id, [], buildArtistIndex([]), 1);
      return cards.length > 0;
    });
  }

  function paintArtistFeed(categories, apiArtists, opts) {
    opts = opts || {};
    var container = document.getElementById('feed-categories');
    var stories = document.getElementById('stories-bar');
    if (!container) return;

    var index = buildArtistIndex(apiArtists || []);
    var storyCards = [];
    var seenStories = {};
    var feedCategories = visibleFeedCategories(categories && categories.length ? categories : getCategories());

    if (opts.buildNav !== false) {
      buildCategoryNav(feedCategories);
    }

    var htmlParts = [];
    feedCategories.forEach(function (category, idx) {
      var limit = opts.cardsPerCategory || 16;
      var cards = mergeCategoryArtists(category.id, category.artists || apiArtists || [], index, limit);
      cards.slice(0, 8).forEach(function (card) {
        var storyKey = card.artist_id || normalizeName(card.name);
        if (seenStories[storyKey]) return;
        seenStories[storyKey] = true;
        storyCards.push(card);
      });
      htmlParts.push({ category: category, cards: cards, priority: idx < 2 });
    });

    if (opts.deferCategories) {
      container.innerHTML = htmlParts.filter(function (p) { return p.priority; })
        .map(function (p) { return renderCategorySection(p.category, p.cards); }).join('');

      requestAnimationFrame(function () {
        var rest = htmlParts.filter(function (p) { return !p.priority; });
        if (!rest.length) return;
        var frag = rest.map(function (p) { return renderCategorySection(p.category, p.cards); }).join('');
        container.insertAdjacentHTML('beforeend', frag);
        if (global.GearshUI) GearshUI.initLazyImages(container);
      });
    } else {
      container.innerHTML = htmlParts.map(function (p) {
        return renderCategorySection(p.category, p.cards);
      }).join('');
    }

    if (stories) {
      if (!storyCards.length && getShowcase().length) {
        storyCards = getShowcase().slice(0, 16).map(function (item) {
          return showcaseToCard(item, findArtistMatch(item.name, index));
        });
      }
      storyCards.sort(function (a, b) { return cardMasteryHours(b) - cardMasteryHours(a); });
      stories.innerHTML = storyCards.slice(0, 16).map(renderStory).filter(Boolean).join('');
      if (!stories.innerHTML) {
        stories.innerHTML = '<a class="story-item" href="/search"><div class="story-ring" style="display:flex;align-items:center;justify-content:center;background:var(--g-surface)"><i class="ti ti-search" style="color:var(--g-accent);font-size:24px"></i></div><span class="story-name">Search</span></a>';
      }
    }

    if (global.GearshUI) GearshUI.initLazyImages(container);
    if (stories && global.GearshUI) GearshUI.initLazyImages(stories);
  }

  function buildCategoryNav(categories) {
    var nav = document.getElementById('category-nav');
    if (!nav) return;
    var items = categories && categories.length ? categories : getCategories();
    nav.innerHTML = items.map(function (cat) {
      return '<a class="cat-pill" href="#cat-' + cat.id + '"><i class="' + cat.icon + '"></i> ' + escapeHtml(cat.title) + '</a>';
    }).join('');
  }

  function showFeedSkeletons(containerId, count) {
    var el = document.getElementById(containerId || 'feed-categories');
    if (!el) return;
    el.innerHTML = '<div class="feed-row">' + renderFeedSkeleton(count || 6) + '</div>';
  }

  async function loadArtistFeed(opts) {
    opts = opts || {};
    if (getShowcase().length) {
      paintArtistFeed(getCategories(), [], { deferCategories: true, buildNav: true });
    } else if (!opts.skipSkeleton) {
      showFeedSkeletons('feed-categories', 6);
    }

    var data = await fetchFeedData();
    paintArtistFeed(
      data.categories.length ? data.categories : getCategories(),
      data.apiArtists,
      { deferCategories: true }
    );
  }

  function filterCards(cards, filters) {
    filters = filters || {};
    var q = (filters.q || '').toLowerCase().trim();
    return cards.filter(function (card) {
      if (q) {
        var hay = [card.name, card.genre, card.category, card.location].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      if (filters.genre && filters.genre !== 'all' && card.genreSlug !== filters.genre) return false;
      if (filters.category && filters.category !== 'all' && card.category !== filters.category) return false;
      if (filters.location && filters.location !== 'all') {
        var loc = (card.location || card.genre || '').toLowerCase();
        if (loc.indexOf(filters.location.toLowerCase()) === -1) return false;
      }
      if (filters.verified && !card.is_verified) return false;
      if (filters.trending && !card.is_trending) return false;
      if (filters.bookable && !card.bookable) return false;
      return true;
    });
  }

  function sortCards(cards, sortBy, genreSlug) {
    var list = cards.slice();
    switch (sortBy) {
      case 'alpha':
        list.sort(function (a, b) { return a.name.localeCompare(b.name); });
        break;
      case 'recent':
        list.reverse();
        break;
      case 'trending':
        list.sort(function (a, b) {
          if (a.is_trending !== b.is_trending) return a.is_trending ? -1 : 1;
          return cardMasteryHours(b) - cardMasteryHours(a);
        });
        break;
      case 'popular':
      default:
        if (genreSlug && genreSlug !== 'all' && typeof compareArtistsForGenre === 'function') {
          list.sort(function (a, b) { return compareArtistsForGenre(genreSlug, a, b); });
        } else {
          list.sort(function (a, b) { return cardMasteryHours(b) - cardMasteryHours(a); });
        }
    }
    return list;
  }

  function searchShowcase(query, limit) {
    var q = normalizeName(query);
    if (!q) return [];
    return getShowcase().filter(function (item) {
      var hay = normalizeName([item.name, item.category, item.genre, item.location].join(' '));
      return hay.indexOf(q) !== -1 || q.indexOf(hay.split(' ')[0]) !== -1;
    }).slice(0, limit || 8).map(function (item) {
      return showcaseToCard(item, null);
    });
  }

  global.GearshFeed = {
    API_BASE: API_BASE,
    normalizeName: normalizeName,
    escapeHtml: escapeHtml,
    bookUrl: bookUrl,
    claimUrl: claimUrl,
    formatPrice: formatPrice,
    buildArtistIndex: buildArtistIndex,
    apiArtistToCard: apiArtistToCard,
    showcaseToCard: showcaseToCard,
    mergeCategoryArtists: mergeCategoryArtists,
    buildAllArtistCards: buildAllArtistCards,
    renderFeedCard: renderFeedCard,
    renderFeedSkeleton: renderFeedSkeleton,
    renderCategorySection: renderCategorySection,
    loadArtistFeed: loadArtistFeed,
    paintArtistFeed: paintArtistFeed,
    buildCategoryNav: buildCategoryNav,
    showFeedSkeletons: showFeedSkeletons,
    fetchFeedData: fetchFeedData,
    filterCards: filterCards,
    sortCards: sortCards,
    searchShowcase: searchShowcase,
    getCategories: getCategories,
    getShowcase: getShowcase,
    cardMasteryHours: cardMasteryHours
  };
})(typeof window !== 'undefined' ? window : this);
