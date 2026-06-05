/**
 * Gearsh Artist Feed Engine
 * Shared by homepage, artists directory, and search results.
 */
(function (global) {
  'use strict';

  var API_BASE = '/api';
  var CACHE_KEY = 'gearsh_feed_cache_v6';
  var CACHE_TTL = 5 * 60 * 1000;

  // Tonight helper — reads from day-genre-schedule.js when present.
  function getTonight() {
    if (typeof window === 'undefined') return null;
    if (!window.GearshSchedule || typeof window.GearshSchedule.today !== 'function') return null;
    try { return window.GearshSchedule.today(); }
    catch (_) { return null; }
  }

  function cardStatus(item) {
    var status = String(item.status || item.availability_status || '').toLowerCase();
    return status === 'unavailable' ? 'unavailable' : 'active';
  }

  function isPlaceholderImage(path) {
    var value = String(path || '').toLowerCase();
    if (!value) return true;
    return value.indexOf('/artists.png') !== -1
      || value.indexOf('artists/artists.png') !== -1
      || value.indexOf('icon-512') !== -1
      || value.indexOf('/icons/icon') !== -1;
  }

  function resolveCardImage(source, showcase) {
    var record = showcase || findShowcaseRecord(source);
    var image = (source && source.image) || (record && record.image) || 'icons/Icon-512.png';
    return image;
  }

  function cardHasSoloPortrait(card) {
    if (!card) return false;
    if (card.has_solo_portrait === true) return true;
    if (card.has_solo_portrait === false) return false;
    if (typeof artistHasSoloPortrait === 'function') return artistHasSoloPortrait(card);
    return !isPlaceholderImage(card.image);
  }

  function compareFeedCards(a, b, genreSlug) {
    if (global.GearshLocation && GearshLocation.hasPosition()) {
      var locCmp = GearshLocation.compare(a, b);
      if (locCmp !== 0) return locCmp;
    }
    if (a.bookable !== b.bookable) return a.bookable ? -1 : 1;
    if (genreSlug && typeof compareArtistsForGenre === 'function') {
      return compareArtistsForGenre(genreSlug, a, b);
    }
    var soloDiff = (cardHasSoloPortrait(b) ? 1 : 0) - (cardHasSoloPortrait(a) ? 1 : 0);
    if (soloDiff !== 0) return soloDiff;
    var bookingsDiff = Number(b.total_bookings || 0) - Number(a.total_bookings || 0);
    if (bookingsDiff !== 0) return bookingsDiff;
    var hoursDiff = cardMasteryHours(b) - cardMasteryHours(a);
    if (hoursDiff !== 0) return hoursDiff;
    return Number(b.is_verified || 0) - Number(a.is_verified || 0);
  }

  // Prefer real headshots in hero slots; only backfill with placeholders when
  // there aren't enough portrait artists to fill the rail.
  function pickPromotedCards(cards, limit, genreSlug, minPortraits) {
    limit = limit || 5;
    minPortraits = minPortraits == null ? 3 : minPortraits;
    var sorted = cards.slice().sort(function (a, b) {
      return compareFeedCards(a, b, genreSlug);
    });
    var portraits = sorted.filter(cardHasSoloPortrait);
    if (portraits.length >= limit) return portraits.slice(0, limit);
    if (portraits.length >= minPortraits) return portraits;
    return sorted.slice(0, limit);
  }
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

  function isDjCategory(category) {
    var value = String(category || '').toLowerCase();
    return value.indexOf('dj') !== -1 || value.indexOf('amapiano') !== -1 || value.indexOf('house') !== -1;
  }

  function showcaseBaseFee(showcase) {
    if (showcase.hourlyRate != null && Number(showcase.hourlyRate) > 0) {
      return Number(showcase.hourlyRate);
    }
    var hours = Number(showcase.masteryHours || 0);
    if (hours >= 10000) return 500000;
    if (hours >= 7500) return 150000;
    if (hours >= 5000) return 75000;
    if (hours >= 3000) return 45000;
    if (hours >= 1000) return 25000;
    return 12000;
  }

  function minPriceFromFee(fee, category) {
    var price = Number(fee || 0);
    if (!price) return 0;
    var mult = isDjCategory(category) ? 0.35 : 0.45;
    return Math.round(price * mult);
  }

  function showcaseMinPrice(showcase) {
    return minPriceFromFee(showcaseBaseFee(showcase), showcase.category);
  }

  function formatPrice(amount) {
    if (!amount) return '';
    var value = Number(amount);
    if (!value) return '';
    if (value >= 1000000) {
      var millions = (value / 1000000).toFixed(2).replace(/\.?0+$/, '');
      return 'from R' + millions.replace('.', ',') + 'M';
    }
    return 'from R' + value.toLocaleString('en-ZA');
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
    if (showcase) {
      return formatPrice(showcaseMinPrice(showcase));
    }
    if (source.min_price) return formatPrice(source.min_price);
    if (source.booking_fee) return formatPrice(minPriceFromFee(source.booking_fee, source.category));
    if (source.hourly_rate) return formatPrice(minPriceFromFee(source.hourly_rate, source.category));
    if (source.base_rate) return formatPrice(minPriceFromFee(source.base_rate, source.category));
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
    var status = cardStatus(artist);
    var unavailable = status === 'unavailable';
    var image = resolveCardImage(artist, showcase);
    var hasPortrait = cardHasSoloPortrait({ image: image, username: artist.username });
    return {
      artist_id: artist.artist_id,
      username: artist.username,
      profile_url: artist.profile_url,
      name: artist.name,
      image: image,
      genre: [artist.category, artist.location].filter(Boolean).join(' · ') || 'Available to book',
      category: artist.category || '',
      location: artist.location || '',
      country: artist.country || '',
      genreSlug: artistGenreSlugFromRecord(artist),
      badge: unavailable ? 'Unavailable' : (tier ? tier.label : (artist.is_verified ? 'Verified' : (artist.is_trending ? 'Trending' : 'Book now'))),
      badgeClass: unavailable ? 'fb-deal' : (tier ? tier.badgeClass : (artist.is_verified ? 'fb-feat' : (artist.is_trending ? 'fb-rise' : 'fb-deal'))),
      price: resolveListingPrice(artist),
      mastery_hours: hours,
      total_bookings: Number(artist.total_bookings || 0),
      bookable: !unavailable,
      has_solo_portrait: hasPortrait,
      status: status,
      is_verified: !!artist.is_verified,
      is_trending: !!artist.is_trending
    };
  }

  function showcaseToCard(item, match) {
    var hours = Math.max(cardMasteryHours(item), match ? cardMasteryHours(match) : 0);
    var tier = masteryBadgeForHours(hours);
    var status = cardStatus(item) === 'unavailable'
      ? 'unavailable'
      : cardStatus(match || {});
    var unavailable = status === 'unavailable';
    var image = resolveCardImage(match || item, item);
    var hasPortrait = cardHasSoloPortrait({ image: image, username: (match && match.username) || item.username });
    return {
      artist_id: match ? match.artist_id : null,
      username: match ? match.username : (item.username || null),
      profile_url: match ? match.profile_url : null,
      name: item.name,
      image: image,
      genre: item.genre || item.category || '',
      category: item.category || '',
      location: item.location || '',
      country: item.country || (match && match.country) || 'South Africa',
      genreSlug: item.genreSlug || artistGenreSlugFromRecord(item),
      badge: unavailable
        ? 'Unavailable'
        : (match ? (tier ? tier.label : 'Book now') : (tier ? tier.label : (item.badge || 'Featured'))),
      badgeClass: unavailable
        ? 'fb-deal'
        : (match ? (tier ? tier.badgeClass : 'fb-deal') : (tier ? tier.badgeClass : (item.badgeClass || 'fb-feat'))),
      price: resolveListingPrice(item),
      mastery_hours: hours,
      total_bookings: match ? Number(match.total_bookings || 0) : 0,
      bookable: !unavailable && !!(match || item.username),
      has_solo_portrait: hasPortrait,
      status: status,
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
      var genreKey = categoryId.indexOf('genre-') === 0 ? categoryId.slice(6) : null;
      return compareFeedCards(a, b, genreKey);
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
      return compareFeedCards(a, b, null);
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
        '<div class="feed-card-genre">' + escapeHtml(
          item.distance_label
            ? item.distance_label + ' · ' + (item.location || item.genre || '')
            : (item.genre || item.location || '')
        ) + '</div>' +
        (item.price ? '<div class="feed-card-price">' + escapeHtml(item.price) + '</div>' : '') +
      '</div>';

    if (href && item.bookable) {
      return '<a class="' + classes + '" href="' + href + '" aria-label="' + escapeHtml(actionLabel + ': ' + item.name) + '">' + inner + '</a>';
    }
    return '<div class="' + classes + '" aria-label="' + escapeHtml(item.name) + ', featured artist">' + inner + '</div>';
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

  function renderCategorySection(category, cards, opts) {
    opts = opts || {};
    var cardsHtml = cards.length
      ? cards.map(function (c) { return renderFeedCard(c); }).join('')
      : '<div class="feed-empty">More artists coming soon. <a href="join-gig.html" style="color:var(--g-accent)">List your gig</a> to appear here.</div>';

    var tonightChip = opts.isTonight
      ? '<span class="rail-badge" title="Tonight\u2019s featured genre">Tonight</span>'
      : '';

    return '<section class="feed-category' + (opts.isTonight ? ' is-tonight' : '') + '" id="cat-' + category.id + '">' +
      '<div class="feed-header">' +
        '<div>' +
          '<h3 class="feed-title"><i class="' + category.icon + '" style="font-size:20px;color:var(--g-accent);margin-right:8px;vertical-align:-2px"></i>' + escapeHtml(category.title) + tonightChip + '</h3>' +
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

  function visibleFeedCategories(categories, apiArtists, index) {
    var source = categories && categories.length ? categories : getCategories();
    index = index || buildArtistIndex(apiArtists || []);
    return source.filter(function (category) {
      if (category.id === 'mastery-legends') return true;
      if (category.artists && category.artists.length) return true;
      var cards = mergeCategoryArtists(category.id, apiArtists || [], index, 1);
      return cards.length > 0;
    });
  }

  // Pin tonight's genre rail to the top of the feed and label it. Returns a
  // new array — caller's list isn't mutated.
  function reorderForTonight(categories) {
    var tonight = getTonight();
    if (!tonight) return categories.slice();
    var targetId = 'genre-' + tonight.slug;
    var ordered = [];
    var tonightCat = null;
    categories.forEach(function (cat) {
      if (cat.id === targetId) tonightCat = cat;
      else ordered.push(cat);
    });
    if (!tonightCat) return categories.slice();
    return [tonightCat].concat(ordered);
  }

  // Build a synthetic "More from <location>" rail (e.g. Monday's Limpopo).
  // Pulls artists from the showcase + DB whose location matches, minus any
  // already shown in the headline rail to avoid duplicates.
  function buildLocationRail(location, excludeUsernames, apiArtists, index) {
    var loc = String(location || '').toLowerCase();
    if (!loc) return null;
    var seen = {};
    (excludeUsernames || []).forEach(function (u) {
      if (u) seen[String(u).toLowerCase()] = true;
    });

    var cards = [];
    (apiArtists || []).forEach(function (artist) {
      var u = String(artist.username || '').toLowerCase();
      if (u && seen[u]) return;
      if (String(artist.location || '').toLowerCase().indexOf(loc) === -1) return;
      cards.push(apiArtistToCard(artist));
      if (u) seen[u] = true;
    });
    getShowcase().forEach(function (item) {
      var u = String(item.username || '').toLowerCase();
      if (u && seen[u]) return;
      if (String(item.location || '').toLowerCase().indexOf(loc) === -1) return;
      var match = findArtistMatch(item.name, index);
      cards.push(showcaseToCard(item, match));
      if (u) seen[u] = true;
    });

    cards.sort(function (a, b) {
      return compareFeedCards(a, b, null);
    });

    if (!cards.length) return null;
    return {
      category: {
        id: 'location-' + loc.replace(/[^a-z0-9]+/g, '-'),
        title: 'More from ' + location,
        subtitle: 'Province pride beyond tonight\u2019s headline genre',
        icon: 'ti ti-map-pin',
      },
      cards: cards.slice(0, 16),
    };
  }

  function buildNearYouRail(apiArtists, index, limit) {
    if (!global.GearshLocation || !GearshLocation.hasPosition()) return null;
    limit = limit || 16;
    var cards = buildAllArtistCards(apiArtists, index);
    cards = GearshLocation.enrichCards(cards);
    cards.sort(function (a, b) { return compareFeedCards(a, b, null); });
    var local = cards.filter(function (card) {
      return card.distance_km != null && card.distance_km <= 250;
    });
    if (!local.length) {
      local = cards.filter(function (card) { return card.distance_km != null; }).slice(0, limit);
    }
    if (!local.length) local = cards.slice(0, limit);
    if (!local.length) return null;
    return {
      category: {
        id: 'near-you',
        title: GearshLocation.artistsNearLabel(),
        subtitle: GearshLocation.locationLabel()
          ? ('Sorted by distance from ' + GearshLocation.locationLabel())
          : 'Sorted by distance',
        icon: 'ti ti-map-pin',
      },
      cards: local.slice(0, limit),
    };
  }

  function paintArtistFeed(categories, apiArtists, opts) {
    opts = opts || {};
    var container = document.getElementById('feed-categories');
    var stories = document.getElementById('stories-bar');
    if (!container) return;

    var index = buildArtistIndex(apiArtists || []);
    var storyCards = [];
    var seenStories = {};
    var feedCategories = visibleFeedCategories(
      categories && categories.length ? categories : getCategories(),
      apiArtists,
      index
    );
    if (!feedCategories.length) feedCategories = getCategories();
    feedCategories = reorderForTonight(feedCategories);
    if (opts.maxCategories > 0) {
      feedCategories = feedCategories.slice(0, opts.maxCategories);
    }

    var tonight = getTonight();
    var tonightCatId = tonight ? 'genre-' + tonight.slug : null;

    var htmlParts = [];
    var nearYouRail = buildNearYouRail(apiArtists, index, opts.cardsPerCategory || 16);
    if (nearYouRail) {
      htmlParts.push({ category: nearYouRail.category, cards: nearYouRail.cards, priority: true, isTonight: false });
    }

    if (opts.buildNav !== false && !opts.hideNav) {
      var navCategories = feedCategories.slice();
      if (nearYouRail) navCategories.unshift(nearYouRail.category);
      buildCategoryNav(navCategories);
    }

    feedCategories.forEach(function (category, idx) {
      var limit = opts.cardsPerCategory || 16;
      var cards = mergeCategoryArtists(category.id, category.artists || apiArtists || [], index, limit);
      if (global.GearshLocation && GearshLocation.hasPosition()) {
        cards = GearshLocation.enrichCards(cards);
        cards.sort(function (a, b) { return compareFeedCards(a, b, null); });
      }
      cards.slice(0, 8).forEach(function (card) {
        var storyKey = card.artist_id || normalizeName(card.name);
        if (seenStories[storyKey]) return;
        seenStories[storyKey] = true;
        storyCards.push(card);
      });
      var isTonight = !!(tonightCatId && category.id === tonightCatId);
      htmlParts.push({ category: category, cards: cards, priority: idx < 2, isTonight: isTonight });

      // Splice the secondary location rail (e.g. "More from Limpopo") directly
      // below tonight's headline rail when configured.
      if (isTonight && tonight && tonight.secondaryLocation) {
        var excludeUsernames = cards.map(function (c) { return c.username; });
        var locationRail = buildLocationRail(tonight.secondaryLocation, excludeUsernames, apiArtists, index);
        if (locationRail) {
          htmlParts.push({ category: locationRail.category, cards: locationRail.cards, priority: true, isTonight: false });
        }
      }
    });

    if (opts.deferCategories) {
      var priorityParts = htmlParts.filter(function (p) { return p.priority; });
      var initialParts = priorityParts.length ? priorityParts : htmlParts;
      container.innerHTML = initialParts
        .map(function (p) { return renderCategorySection(p.category, p.cards, { isTonight: p.isTonight }); }).join('');

      requestAnimationFrame(function () {
        var rest = htmlParts.filter(function (p) { return priorityParts.length && !p.priority; });
        if (!rest.length) return;
        var frag = rest.map(function (p) { return renderCategorySection(p.category, p.cards, { isTonight: p.isTonight }); }).join('');
        container.insertAdjacentHTML('beforeend', frag);
        if (global.GearshUI) GearshUI.initLazyImages(container);
      });
    } else {
      container.innerHTML = htmlParts.map(function (p) {
        return renderCategorySection(p.category, p.cards, { isTonight: p.isTonight });
      }).join('');
    }

    if (!container.innerHTML.trim()) {
      container.innerHTML = '<div class="feed-empty">More artists coming soon. <a href="join-gig.html" style="color:var(--g-accent)">List your gig</a> to appear here.</div>';
    }

    if (stories && !opts.hideStories) {
      if (!storyCards.length && getShowcase().length) {
        storyCards = getShowcase().slice(0, 16).map(function (item) {
          return showcaseToCard(item, findArtistMatch(item.name, index));
        });
      }
      storyCards.sort(function (a, b) { return compareFeedCards(a, b, tonight ? tonight.slug : null); });
      var storyPool = pickPromotedCards(storyCards, 16, tonight ? tonight.slug : null, 6);
      stories.innerHTML = storyPool.map(renderStory).filter(Boolean).join('');
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
    var tonight = getTonight();
    var tonightCatId = tonight ? 'genre-' + tonight.slug : null;
    nav.innerHTML = items.map(function (cat) {
      var chip = (tonightCatId && cat.id === tonightCatId)
        ? '<span class="rail-badge" style="margin-left:6px">Tonight</span>'
        : '';
      return '<a class="cat-pill' + (chip ? ' is-tonight' : '') + '" href="#cat-' + cat.id + '"><i class="' + cat.icon + '"></i> ' + escapeHtml(cat.title) + chip + '</a>';
    }).join('');
  }

  function showFeedSkeletons(containerId, count) {
    var el = document.getElementById(containerId || 'feed-categories');
    if (!el) return;
    el.innerHTML = '<div class="feed-row">' + renderFeedSkeleton(count || 6) + '</div>';
  }

  async function loadArtistFeed(opts) {
    opts = opts || {};
    var paintOpts = {
      deferCategories: false,
      buildNav: opts.buildNav !== false && !opts.hideNav,
      hideNav: opts.hideNav,
      hideStories: opts.hideStories,
      maxCategories: opts.maxCategories,
      cardsPerCategory: opts.cardsPerCategory,
    };
    if (global.GearshLocation) {
      var locInit = GearshLocation.initFast || GearshLocation.init;
      try { locInit(); } catch (_) {}
    }
    if (getShowcase().length) {
      paintArtistFeed(getCategories(), [], paintOpts);
    } else if (!opts.skipSkeleton) {
      showFeedSkeletons('feed-categories', 6);
    }

    try {
      var data = await fetchFeedData();
      paintArtistFeed(
        data.categories.length ? data.categories : getCategories(),
        data.apiArtists,
        paintOpts
      );
    } catch (_) {
      if (!getShowcase().length) {
        showFeedSkeletons('feed-categories', 6);
      } else {
        paintArtistFeed(getCategories(), [], paintOpts);
      }
    }

    // Headliners rail refreshes once API data lands so total_bookings flows in.
    if (typeof renderHeadlinersRail === 'function') {
      renderHeadlinersRail();
    }
  }

  function headlinerCardHtml(card) {
    var href = card.bookable ? bookUrl(card) : (card.username ? '/book/' + encodeURIComponent(String(card.username).toLowerCase()) : '#');
    var price = card.price ? '<div class="headliner-fee">' + escapeHtml(card.price) + '</div>' : '';
    var badge = card.status === 'unavailable'
      ? '<span class="headliner-badge headliner-badge--unavailable">Unavailable</span>'
      : '<span class="headliner-badge">Tonight</span>';
    var img = lazyImgTag(card.image, card.name)
      .replace('class="lazy-img"', 'class="lazy-img headliner-photo"')
      .replace('width="168" height="168"', 'width="320" height="400"');
    return '<a class="headliner-card" href="' + escapeHtml(href) + '" aria-label="' + escapeHtml(card.name) + '">' +
      badge +
      '<div class="headliner-photo-wrap">' + img + '</div>' +
      '<div class="headliner-body">' +
        '<div class="headliner-name">' + escapeHtml(card.name) + '</div>' +
        '<div class="headliner-meta">' + escapeHtml(card.genre || card.location || '') + '</div>' +
        price +
      '</div>' +
    '</a>';
  }

  // Top 5 artists for tonight's genre, sorted by bookings then mastery hours.
  // Limpopo Mondays fall back to location='Limpopo' if the headline slug runs
  // dry, so the rail is never empty.
  function buildHeadlinerCards(apiArtists, tonight) {
    if (!tonight) return [];
    var index = buildArtistIndex(apiArtists || []);
    var cards = [];
    var seen = {};

    function consider(card) {
      var key = String(card.username || card.artist_id || normalizeName(card.name));
      if (seen[key]) return;
      cards.push(card);
      seen[key] = true;
    }

    (apiArtists || []).forEach(function (artist) {
      if (artistGenreSlugFromRecord(artist) !== tonight.slug) return;
      consider(apiArtistToCard(artist));
    });
    getShowcase().forEach(function (item) {
      if ((item.genreSlug || artistGenreSlugFromRecord(item)) !== tonight.slug) return;
      var match = findArtistMatch(item.name, index);
      consider(showcaseToCard(item, match));
    });

    // Mondays: backfill from province-wide Limpopo pool.
    if (cards.length < 5 && tonight.secondaryLocation) {
      var loc = String(tonight.secondaryLocation).toLowerCase();
      (apiArtists || []).forEach(function (artist) {
        if (cards.length >= 8) return;
        if (String(artist.location || '').toLowerCase().indexOf(loc) === -1) return;
        consider(apiArtistToCard(artist));
      });
      getShowcase().forEach(function (item) {
        if (cards.length >= 8) return;
        if (String(item.location || '').toLowerCase().indexOf(loc) === -1) return;
        var match = findArtistMatch(item.name, index);
        consider(showcaseToCard(item, match));
      });
    }

    return pickPromotedCards(cards, 5, tonight.slug, 3);
  }

  function renderHeadlinersRail() {
    var section = document.getElementById('headliners-section');
    var grid = document.getElementById('headliners-grid');
    var titleEl = document.getElementById('headliners-title-text');
    var subtitleEl = document.getElementById('headliners-subtitle');
    if (!section || !grid) return;

    var tonight = getTonight();
    if (!tonight) return;

    // Render straight from the showcase first so the rail paints instantly.
    var cards = buildHeadlinerCards([], tonight);

    // Then enrich from cached/live API data when available.
    var cached = readCache();
    if (cached && cached.apiArtists && cached.apiArtists.length) {
      cards = buildHeadlinerCards(cached.apiArtists, tonight);
    }

    if (!cards.length) return;

    if (titleEl) titleEl.textContent = tonight.title + ' headliners';
    if (subtitleEl) subtitleEl.textContent = tonight.tagline;
    grid.innerHTML = cards.map(headlinerCardHtml).join('');
    section.hidden = false;
    if (global.GearshUI) GearshUI.initLazyImages(section);
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
    if (global.GearshLocation) list = GearshLocation.enrichCards(list);
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
          return compareFeedCards(a, b, genreSlug && genreSlug !== 'all' ? genreSlug : null);
        });
        break;
      case 'popular':
        list.sort(function (a, b) {
          return compareFeedCards(a, b, genreSlug && genreSlug !== 'all' ? genreSlug : null);
        });
        break;
      case 'nearby':
      default:
        list.sort(function (a, b) {
          return compareFeedCards(a, b, genreSlug && genreSlug !== 'all' ? genreSlug : null);
        });
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

  function scheduleArtistFeed(feedSelector) {
    var target = document.querySelector(feedSelector || '#feed');
    if (!target || typeof IntersectionObserver === 'undefined') {
      loadArtistFeed();
      return;
    }
    var started = false;
    var observer = new IntersectionObserver(function (entries) {
      if (started) return;
      if (!entries.some(function (e) { return e.isIntersecting; })) return;
      started = true;
      observer.disconnect();
      loadArtistFeed();
    }, { rootMargin: '240px 0px' });
    observer.observe(target);
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
    cardMasteryHours: cardMasteryHours,
    getTonight: getTonight,
    buildHeadlinerCards: buildHeadlinerCards,
    renderHeadlinersRail: renderHeadlinersRail,
    cardHasSoloPortrait: cardHasSoloPortrait,
    compareFeedCards: compareFeedCards,
    pickPromotedCards: pickPromotedCards,
    scheduleArtistFeed: scheduleArtistFeed
  };
})(typeof window !== 'undefined' ? window : this);
