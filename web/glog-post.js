/**
 * G-Log article page — markdown render, SEO meta, share, related posts
 */
(function () {
  'use strict';

  function getSlugFromPath() {
    var params = new URLSearchParams(window.location.search);
    var fromQuery = params.get('slug');
    if (fromQuery) return fromQuery.trim().toLowerCase();
    var match = window.location.pathname.match(/^\/glog\/([^/?#]+)\/?$/i);
    if (match) return decodeURIComponent(match[1]).trim().toLowerCase();
    return null;
  }

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function escapeAttr(str) {
    return escapeHtml(str).replace(/'/g, '&#39;');
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
    if (!path) return 'https://thegearsh.com/icons/og-image.png';
    if (/^https?:\/\//i.test(path)) return path;
    var rel = path.startsWith('/') ? path : '/' + path.replace(/^\/?/, '');
    return 'https://thegearsh.com' + rel.replace(/^\/assets\//, '/assets/');
  }

  function resolveImageSrc(path) {
    if (!path) return '/icons/Icon-512.png';
    if (/^https?:\/\//i.test(path)) return path;
    if (path.startsWith('/')) return path;
    return '/' + path.replace(/^\/?/, '');
  }

  function setMeta(attr, key, value) {
    if (!value) return;
    var el = document.querySelector('meta[' + attr + '="' + key + '"]');
    if (!el) {
      el = document.createElement('meta');
      el.setAttribute(attr, key);
      document.head.appendChild(el);
    }
    el.setAttribute('content', value);
  }

  function updateSeo(post) {
    var url = 'https://thegearsh.com/glog/' + encodeURIComponent(post.slug);
    var image = resolveImage(post.featuredImage);
    var description = post.excerpt || post.title;

    document.title = post.title + ' | G-Log | Gearsh';
    setMeta('name', 'description', description);
    setMeta('property', 'og:type', 'article');
    setMeta('property', 'og:site_name', 'Gearsh G-Log');
    setMeta('property', 'og:title', post.title);
    setMeta('property', 'og:description', description);
    setMeta('property', 'og:url', url);
    setMeta('property', 'og:image', image);
    setMeta('name', 'twitter:card', 'summary_large_image');
    setMeta('name', 'twitter:title', post.title);
    setMeta('name', 'twitter:description', description);
    setMeta('name', 'twitter:image', image);

    var canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) canonical.setAttribute('href', url);

    var mins = post.readTimeMinutes || estimateGlogReadTime(post.content);
    var schema = {
      '@context': 'https://schema.org',
      '@type': 'BlogPosting',
      headline: post.title,
      description: description,
      image: [image],
      datePublished: post.publishedAt,
      dateModified: post.publishedAt,
      author: {
        '@type': 'Organization',
        name: post.author || 'Gearsh',
        url: 'https://thegearsh.com/',
      },
      publisher: {
        '@type': 'Organization',
        name: 'Gearsh',
        logo: {
          '@type': 'ImageObject',
          url: 'https://thegearsh.com/icons/Icon-512.png',
        },
      },
      mainEntityOfPage: url,
      wordCount: String(post.content || '').trim().split(/\s+/).filter(Boolean).length,
      timeRequired: 'PT' + mins + 'M',
      keywords: (post.tags || []).join(', '),
    };

    var script = document.getElementById('glog-article-schema');
    if (!script) {
      script = document.createElement('script');
      script.id = 'glog-article-schema';
      script.type = 'application/ld+json';
      document.head.appendChild(script);
    }
    script.textContent = JSON.stringify(schema);
  }

  function enhanceProse(el) {
    if (!el) return;

    var firstP = el.querySelector('p');
    if (firstP) firstP.classList.add('glog-lead');

    var headings = el.querySelectorAll('h2');
    headings.forEach(function (heading) {
      var match = heading.textContent.match(/^(\d+)\.\s*(.+)$/);
      if (!match) return;

      var stepNum = match[1];
      var stepTitle = match[2];
      var step = document.createElement('div');
      step.className = 'glog-step';

      var head = document.createElement('div');
      head.className = 'glog-step-head';
      head.innerHTML =
        '<span class="glog-step-num">' + escapeHtml(stepNum) + '</span>' +
        '<h2 class="glog-step-title">' + escapeHtml(stepTitle) + '</h2>';

      var body = document.createElement('div');
      body.className = 'glog-step-body';
      var node = heading.nextElementSibling;
      while (node && node.tagName !== 'H2') {
        var next = node.nextElementSibling;
        body.appendChild(node);
        node = next;
      }

      step.appendChild(head);
      step.appendChild(body);
      heading.replaceWith(step);
    });

    el.querySelectorAll('a[href^="/"]').forEach(function (a) {
      a.classList.add('glog-inline-link');
    });
  }

  function renderMarkdown(post) {
    var html = '';
    if (window.marked && typeof window.marked.parse === 'function') {
      window.marked.setOptions({ gfm: true, breaks: false });
      html = window.marked.parse(post.content || '');
    } else {
      html = '<p>' + escapeHtml(post.content).replace(/\n\n/g, '</p><p>').replace(/\n/g, '<br>') + '</p>';
    }
    var el = document.getElementById('glog-article-content');
    if (el) {
      el.innerHTML = html;
      enhanceProse(el);
    }
  }

  function setupReadingProgress() {
    var bar = document.getElementById('glog-read-progress');
    if (!bar) return;

    function update() {
      var doc = document.documentElement;
      var scrollTop = doc.scrollTop || document.body.scrollTop;
      var height = doc.scrollHeight - doc.clientHeight;
      var pct = height > 0 ? Math.min(100, (scrollTop / height) * 100) : 0;
      bar.style.width = pct + '%';
    }

    window.addEventListener('scroll', update, { passive: true });
    update();
  }

  function renderTags(post) {
    var el = document.getElementById('glog-article-tags');
    if (!el) return;
    el.innerHTML = (post.categories || []).concat(post.tags || []).slice(0, 8).map(function (tag) {
      return '<a class="glog-tag" href="/glog?tag=' + encodeURIComponent(tag) + '">' + escapeHtml(tag) + '</a>';
    }).join('');
  }

  function setupShare(post) {
    var url = encodeURIComponent('https://thegearsh.com/glog/' + post.slug);
    var text = encodeURIComponent(post.title + ' on G-Log | Gearsh');
    var wrap = document.getElementById('glog-share');
    if (!wrap) return;

    wrap.querySelectorAll('[data-share]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var kind = btn.getAttribute('data-share');
        var shareUrl = '';
        if (kind === 'x') shareUrl = 'https://twitter.com/intent/tweet?url=' + url + '&text=' + text;
        if (kind === 'whatsapp') shareUrl = 'https://wa.me/?text=' + text + '%20' + url;
        if (kind === 'facebook') shareUrl = 'https://www.facebook.com/sharer/sharer.php?u=' + url;
        if (kind === 'instagram') {
          navigator.clipboard.writeText('https://thegearsh.com/glog/' + post.slug).catch(function () {});
          btn.textContent = 'Link copied';
          setTimeout(function () { btn.innerHTML = '<i class="ti ti-brand-instagram"></i> Instagram'; }, 2000);
          return;
        }
        if (kind === 'copy') {
          navigator.clipboard.writeText('https://thegearsh.com/glog/' + post.slug).then(function () {
            btn.textContent = 'Copied!';
            setTimeout(function () { btn.innerHTML = '<i class="ti ti-link"></i> Copy link'; }, 2000);
          });
          return;
        }
        if (shareUrl) window.open(shareUrl, '_blank', 'noopener,noreferrer,width=600,height=520');
      });
    });
  }

  function scoreRelated(post, candidate) {
    if (candidate.slug === post.slug) return -1;
    var score = 0;
    (post.categories || []).forEach(function (cat) {
      if ((candidate.categories || []).indexOf(cat) !== -1) score += 3;
    });
    (post.tags || []).forEach(function (tag) {
      if ((candidate.tags || []).indexOf(tag) !== -1) score += 1;
    });
    return score;
  }

  function renderRelated(post) {
    var el = document.getElementById('glog-related-grid');
    if (!el) return;
    var related = sortGlogPostsNewest(GLOG_POSTS)
      .map(function (p) { return { post: p, score: scoreRelated(post, p) }; })
      .filter(function (item) { return item.score > 0; })
      .sort(function (a, b) {
        if (b.score !== a.score) return b.score - a.score;
        return String(b.post.publishedAt).localeCompare(String(a.post.publishedAt));
      })
      .slice(0, 3)
      .map(function (item) { return item.post; });

    if (!related.length) {
      related = sortGlogPostsNewest(GLOG_POSTS).filter(function (p) {
        return p.slug !== post.slug;
      }).slice(0, 3);
    }

    el.innerHTML = related.map(function (p) {
      return '<a class="glog-card" href="/glog/' + encodeURIComponent(p.slug) + '">' +
        '<div class="glog-card-media"><img src="' + escapeAttr(resolveImageSrc(p.featuredImage)) + '" alt="" loading="lazy"></div>' +
        '<div class="glog-card-body">' +
          '<h3 class="glog-card-title">' + escapeHtml(p.title) + '</h3>' +
          '<p class="glog-card-excerpt">' + escapeHtml(p.excerpt) + '</p>' +
        '</div></a>';
    }).join('');

    if (window.GearshUI) GearshUI.initLazyImages(el);
  }

  function renderError() {
    document.title = 'Story not found | G-Log | Gearsh';
    var shell = document.getElementById('glog-article-app');
    if (shell) {
      shell.innerHTML = '<div class="glog-empty"><i class="ti ti-news-off"></i><h2>Story not found</h2><p>This G-Log article may have moved or hasn\'t been published yet.</p><a href="/glog" class="btn-main" style="margin-top:18px;display:inline-flex">Back to G-Log</a></div>';
    }
  }

  function renderPost(post) {
    updateSeo(post);
    var mins = post.readTimeMinutes || estimateGlogReadTime(post.content);

    document.getElementById('glog-article-title').textContent = post.title;

    var lede = document.getElementById('glog-article-lede');
    if (lede) lede.textContent = post.excerpt || '';

    document.getElementById('glog-article-meta').innerHTML =
      '<span><i class="ti ti-user"></i> ' + escapeHtml(post.author || 'Gearsh') + '</span>' +
      '<span><i class="ti ti-calendar"></i> ' + formatDate(post.publishedAt) + '</span>' +
      '<span><i class="ti ti-clock"></i> ' + mins + ' min read</span>';

    var cover = document.getElementById('glog-article-cover-img');
    if (cover) {
      cover.src = resolveImageSrc(post.featuredImage);
      cover.alt = post.title;
    }

    renderTags(post);
    renderMarkdown(post);
    setupShare(post);
    renderRelated(post);
    setupReadingProgress();

    if (window.GearshUI) {
      GearshUI.initReveal(document.querySelector('.glog-article-main'));
    }
  }

  function boot() {
    if (typeof GLOG_POSTS === 'undefined') return renderError();
    var slug = getSlugFromPath();
    var post = slug ? getGlogPostBySlug(slug) : null;
    if (!post) return renderError();
    renderPost(post);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
