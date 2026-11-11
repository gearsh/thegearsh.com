/**
 * Gearsh UI utilities — nav, lazy images, reveal animations, session nav
 */
(function (global) {
  'use strict';

  var lazyObserver = null;

  // Distinctive, honest artwork for creatives who have not uploaded a photograph.
  // Never substitute the Gearsh company logo for someone's identity.
  function isPlaceholderImage(value) {
    var src = String(value || '').trim().toLowerCase().split('?')[0].split('#')[0];
    var filename = src.split('/').pop();
    return !src || ['icon-192.png', 'icon-512.png', 'artists.png', 'artists.webp', 'artists.jpg', 'artists.jpeg'].indexOf(filename) !== -1;
  }

  function portraitSrc(name, category) {
    var label = String(name || 'Creative').trim().slice(0, 60) || 'Creative';
    var categoryLabel = String(category || 'CREATIVE PROFILE').trim().slice(0, 34).toUpperCase();
    var tokens = label.split(' ').filter(Boolean);
    var initials = (tokens.length > 1 ? tokens[0][0] + tokens[tokens.length - 1][0] : label.slice(0, 2)).toUpperCase();
    var hash = Array.from(label.toLowerCase()).reduce(function (h, ch) { return ((h * 31) + ch.charCodeAt(0)) >>> 0; }, 7);
    var shades = ['#00BFFF', '#40C9A2', '#A78BFA', '#F5B44C', '#58A6FF', '#F28CB1'];
    var accent = shades[hash % shades.length];
    function xml(value) { return String(value).replace(/[&<>"']/g, function (ch) { return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[ch]; }); }
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="800" viewBox="0 0 640 800">'
      + '<rect width="640" height="800" fill="#101b2d"/>'
      + '<path d="M-130 620L650 -160M-120 840L780 -60" stroke="' + accent + '" stroke-opacity=".13" stroke-width="90"/>'
      + '<circle cx="520" cy="120" r="190" fill="' + accent + '" fill-opacity=".12"/>'
      + '<path d="M44 64h85M44 64v85" stroke="' + accent + '" stroke-width="5" fill="none"/>'
      + '<text x="50%" y="49%" fill="#ffffff" font-family="Arial,Helvetica,sans-serif" font-size="194" font-weight="800" letter-spacing="-10" text-anchor="middle" dominant-baseline="middle">' + xml(initials) + '</text>'
      + '<rect x="44" y="656" width="54" height="5" rx="2" fill="' + accent + '"/>'
      + '<text x="44" y="714" fill="#f8fafc" font-family="Arial,Helvetica,sans-serif" font-size="29" font-weight="700">' + xml(label.length > 29 ? label.slice(0, 28) + '…' : label) + '</text>'
      + '<text x="44" y="751" fill="' + accent + '" font-family="Arial,Helvetica,sans-serif" font-size="18" font-weight="600" letter-spacing="2">' + xml(categoryLabel) + '</text>'
      + '</svg>';
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  }

  function applyPortraitFallback(img) {
    if (!img) return;
    var name = img.getAttribute('data-portrait-name') || img.getAttribute('alt') || 'Creative';
    var category = img.getAttribute('data-portrait-category') || 'Creative profile';
    img.onerror = null;
    img.src = portraitSrc(name, category);
    img.classList.add('is-loaded', 'is-portrait-fallback');
  }

  function initLazyImages(root) {
    root = root || document;
    var imgs = root.querySelectorAll('img.lazy-img[data-src]:not(.is-loaded)');
    if (!imgs.length) return;
    function loadOne(img) {
      var src = img.getAttribute('data-src');
      img.removeAttribute('data-src');
      if (isPlaceholderImage(src)) { applyPortraitFallback(img); return; }
      img.onload = function () { img.classList.add('is-loaded'); };
      img.onerror = function () { applyPortraitFallback(img); };
      img.src = src;
    }
    if (!lazyObserver && 'IntersectionObserver' in window) {
      lazyObserver = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          lazyObserver.unobserve(entry.target);
          loadOne(entry.target);
        });
      }, { rootMargin: '200px 0px', threshold: 0.01 });
    }
    imgs.forEach(function (img) {
      if (lazyObserver) lazyObserver.observe(img);
      else loadOne(img);
    });
  }

  function initNav() {
    var menuBtn = document.querySelector('.g-nav-menu-btn');
    var links = document.querySelector('.g-nav-links');
    if (!menuBtn || !links) return;

    menuBtn.addEventListener('click', function () {
      var open = links.classList.toggle('open');
      menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });

    document.addEventListener('click', function (e) {
      if (!links.classList.contains('open')) return;
      if (links.contains(e.target) || menuBtn.contains(e.target)) return;
      links.classList.remove('open');
      menuBtn.setAttribute('aria-expanded', 'false');
    });

    links.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () {
        links.classList.remove('open');
        menuBtn.setAttribute('aria-expanded', 'false');
      });
    });
  }

  function initReveal() {
    if (!('IntersectionObserver' in window)) {
      document.querySelectorAll('.reveal').forEach(function (el) {
        el.classList.add('visible');
      });
      return;
    }
    var obs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add('visible');
          obs.unobserve(e.target);
        }
      });
    }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });
    document.querySelectorAll('.reveal').forEach(function (el) { obs.observe(el); });
  }

  function debounce(fn, ms) {
    var t;
    return function () {
      var args = arguments;
      var ctx = this;
      clearTimeout(t);
      t = setTimeout(function () { fn.apply(ctx, args); }, ms);
    };
  }

  function navHasHref(links, href) {
    var target = String(href || '').split('?')[0];
    return !!links.querySelector('a[href="' + href + '"], a[href="' + target + '"]');
  }

  function insertBeforeAuth(links, li) {
    var firstAuth = links.querySelector('.g-nav-menu-auth');
    if (firstAuth) links.insertBefore(li, firstAuth);
    else links.appendChild(li);
  }

  function injectSessionNavLinks(session) {
    var links = document.querySelector('.g-nav-links');
    if (!links) return;

    function ensure(marker, href, text) {
      if (links.querySelector('[data-gearsh-nav="' + marker + '"]')) return;
      if (navHasHref(links, href)) return;
      var li = document.createElement('li');
      li.setAttribute('data-gearsh-nav', marker);
      var a = document.createElement('a');
      a.href = href;
      a.textContent = text;
      li.appendChild(a);
      insertBeforeAuth(links, li);
    }

    ensure('my-bookings', '/my-bookings', 'My bookings');
    if (session.has_artist_dashboard || session.user_type === 'artist') {
      ensure('book-artists', '/search', 'Book artists');
    }
  }

  async function fetchSession() {
    if (global.GearshAuth) {
      var sessionOk = await GearshAuth.ensureSession();
      if (sessionOk === false) return null;
    }
    var token = global.GearshAuth ? GearshAuth.getToken() : localStorage.getItem('gearsh_token');
    if (!token) return null;
    try {
      var res = await fetch('/api/session', { headers: { Authorization: 'Bearer ' + token } });
      var data = await res.json();
      if (res.status === 401 && global.GearshAuth) {
        var refreshed = await GearshAuth.refreshSession();
        return refreshed || null;
      }
      if (!res.ok || !data.success) return null;
      return data.data;
    } catch (_) {
      return localStorage.getItem('gearsh_token') ? { cached: true } : null;
    }
  }

  async function updateNavForSession() {
    var session = await fetchSession();
    if (!session || session.cached) return;

    var isArtist = session.has_artist_dashboard || session.user_type === 'artist';
    var dashHref = session.redirect_path || (
      isArtist
        ? '/artist-dashboard.html'
        : (session.user_type === 'admin' ? '/gearsh-god.html' : '/')
    );
    var label = isArtist
      ? 'Dashboard'
      : (session.user_type === 'admin' ? 'Command' : 'Login');

    document.querySelectorAll('.g-nav-mobile-login, .g-nav-menu-auth a[href="/auth.html"], #nav-auth').forEach(function (el) {
      el.textContent = label;
      el.href = dashHref;
    });

    injectSessionNavLinks(session);

    var heroSignIn = document.querySelector('.hero-actions .btn-ghost');
    if (heroSignIn && isArtist) {
      heroSignIn.textContent = 'Go to dashboard';
      heroSignIn.href = '/artist-dashboard.html';
    }
  }

  function initPage() {
    initNav();
    initReveal();
    initLazyImages();
    updateNavForSession();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initPage);
  } else {
    initPage();
  }

  global.GearshUI = {
    initLazyImages: initLazyImages,
    portraitSrc: portraitSrc,
    isPlaceholderImage: isPlaceholderImage,
    applyPortraitFallback: applyPortraitFallback,
    initNav: initNav,
    initReveal: initReveal,
    debounce: debounce,
    fetchSession: fetchSession,
    updateNavForSession: updateNavForSession
  };
})(typeof window !== 'undefined' ? window : this);
