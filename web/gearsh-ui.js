/**
 * Gearsh UI utilities — nav, lazy images, reveal animations, session nav
 */
(function (global) {
  'use strict';

  var lazyObserver = null;

  function initLazyImages(root) {
    root = root || document;
    var imgs = root.querySelectorAll('img.lazy-img[data-src]:not(.is-loaded)');
    if (!imgs.length) return;

    if (!lazyObserver && 'IntersectionObserver' in window) {
      lazyObserver = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          var img = entry.target;
          var src = img.getAttribute('data-src');
          if (!src) return;
          img.onload = function () {
            img.classList.add('is-loaded');
          };
          img.onerror = function () {
            img.src = 'icons/Icon-512.png';
            img.classList.add('is-loaded');
          };
          img.src = src;
          img.removeAttribute('data-src');
          lazyObserver.unobserve(img);
        });
      }, { rootMargin: '200px 0px', threshold: 0.01 });
    }

    imgs.forEach(function (img) {
      if (lazyObserver) {
        lazyObserver.observe(img);
      } else {
        img.src = img.getAttribute('data-src') || img.src;
        img.classList.add('is-loaded');
      }
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

  function injectSessionNavLinks(session) {
    var links = document.querySelector('.g-nav-links');
    if (!links) return;

    function ensure(marker, href, text) {
      if (links.querySelector('[data-gearsh-nav="' + marker + '"]')) return;
      var li = document.createElement('li');
      li.setAttribute('data-gearsh-nav', marker);
      var a = document.createElement('a');
      a.href = href;
      a.textContent = text;
      li.appendChild(a);

      var searchLi = links.querySelector('a[href="/search"], a[href="./search"]');
      if (searchLi && searchLi.parentElement) {
        searchLi.parentElement.insertAdjacentElement('afterend', li);
        return;
      }
      var lastAuth = null;
      links.querySelectorAll('.g-nav-menu-auth').forEach(function (el) { lastAuth = el; });
      if (lastAuth) {
        lastAuth.insertAdjacentElement('afterend', li);
      } else {
        links.insertBefore(li, links.firstChild);
      }
    }

    ensure('my-bookings', '/my-bookings', 'My bookings');
    if (session.has_artist_dashboard || session.user_type === 'artist') {
      ensure('book-artists', '/search', 'Book artists');
    }
  }

  async function fetchSession() {
    var token = localStorage.getItem('gearsh_token');
    if (!token) return null;
    try {
      var res = await fetch('/api/session', { headers: { Authorization: 'Bearer ' + token } });
      var data = await res.json();
      if (!res.ok || !data.success) return null;
      return data.data;
    } catch (_) {
      return null;
    }
  }

  async function updateNavForSession() {
    var session = await fetchSession();
    if (!session) return;

    var isArtist = session.has_artist_dashboard || session.user_type === 'artist';
    var dashHref = session.redirect_path || (
      isArtist
        ? '/artist-dashboard.html'
        : (session.user_type === 'admin' ? '/gearsh-god.html' : '/')
    );
    var label = isArtist
      ? 'Dashboard'
      : (session.user_type === 'admin' ? 'Command' : 'Home');

    document.querySelectorAll('.g-nav-mobile-login, .g-nav-menu-auth a[href="/auth.html"]').forEach(function (el) {
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
    initNav: initNav,
    initReveal: initReveal,
    debounce: debounce,
    fetchSession: fetchSession,
    updateNavForSession: updateNavForSession
  };
})(typeof window !== 'undefined' ? window : this);
