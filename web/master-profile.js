/**
 * Master Profile page renderer — @gearsh flagship profile
 */
(function () {
  'use strict';

  var API = '/api';
  var USERNAME = 'gearsh';
  var root = document.getElementById('mp-root');
  var profile = null;
  var selectedService = null;
  var selectedDate = null;

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatMoney(amount) {
    return 'R' + Number(amount || 0).toLocaleString('en-ZA');
  }

  function formatDateShort(iso) {
    return new Date(iso).toLocaleDateString('en-ZA', { weekday: 'short', day: 'numeric', month: 'short' });
  }

  function renderStars(n) {
    var s = '';
    for (var i = 0; i < 5; i += 1) {
      s += i < n ? '★' : '☆';
    }
    return s;
  }

  function renderHero(p) {
    var cover = p.cover_image_url || '/icons/og-image.png';
    var avatar = p.image || '/icons/Icon-512.png';
    var stats = p.stats || {};

    return '<section class="mp-hero">' +
      '<div class="mp-hero-cover"><img src="' + escapeHtml(cover) + '" alt=""></div>' +
      '<div class="mp-hero-grid"></div>' +
      '<div class="mp-hero-overlay"></div>' +
      '<div class="mp-hero-inner">' +
        '<div class="mp-avatar-wrap">' +
          '<div class="mp-avatar-glow"></div>' +
          '<img class="mp-avatar" src="' + escapeHtml(avatar) + '" alt="The Gearsh">' +
          '<span class="mp-master-badge">Master</span>' +
        '</div>' +
        '<div class="mp-hero-meta">' +
          '<div class="mp-eyebrow"><i class="ti ti-code"></i> Master Profile · Tech & Product</div>' +
          '<h1 class="mp-name">' + escapeHtml(p.name) + '</h1>' +
          '<div class="mp-username"><span>@</span>' + escapeHtml(p.username) +
            '<span class="mp-verified"><i class="ti ti-rosette-discount-check"></i> Verified</span></div>' +
          '<p class="mp-tagline">' + escapeHtml(p.tagline) + '</p>' +
          '<div class="mp-hero-actions">' +
            '<a href="#book" class="btn-main"><i class="ti ti-calendar-plus"></i> Book The Gearsh</a>' +
            '<a href="#services" class="btn-ghost">View gigs</a>' +
          '</div>' +
          '<div class="mp-stats-bar">' +
            '<div class="mp-stat"><div class="mp-stat-num accent">' + Number(stats.projects_completed || 0) + '+</div><div class="mp-stat-lbl">Projects</div></div>' +
            '<div class="mp-stat"><div class="mp-stat-num">' + Number(stats.clients_served || 0) + '+</div><div class="mp-stat-lbl">Clients</div></div>' +
            '<div class="mp-stat"><div class="mp-stat-num accent">' + Number(stats.hours_coded || 0).toLocaleString() + '</div><div class="mp-stat-lbl">Hours coded</div></div>' +
            '<div class="mp-stat"><div class="mp-stat-num">' + escapeHtml(stats.satisfaction || '98%') + '</div><div class="mp-stat-lbl">Satisfaction</div></div>' +
          '</div>' +
        '</div>' +
      '</div></section>';
  }

  function renderNav() {
    var links = [
      { href: '#about', label: 'About' },
      { href: '#services', label: 'Gigs' },
      { href: '#portfolio', label: 'Portfolio' },
      { href: '#activity', label: 'Activity' },
      { href: '#testimonials', label: 'Reviews' },
      { href: '#availability', label: 'Availability' },
      { href: '#book', label: 'Book' },
    ];
    return '<nav class="mp-nav-sticky" aria-label="Profile sections"><div class="mp-nav-inner">' +
      links.map(function (l) {
        return '<a class="mp-nav-link" href="' + l.href + '">' + l.label + '</a>';
      }).join('') +
    '</div></nav>';
  }

  function renderAbout(p) {
    return '<section class="mp-section" id="about">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">About</div><h2 class="mp-section-title">The builder behind <em>Gearsh</em></h2></div></div>' +
      '<div class="mp-card mp-card-glow"><p class="mp-bio-text">' + escapeHtml(p.long_bio || p.bio) + '</p>' +
      '<div class="mp-skills">' + (p.skills || []).map(function (s) {
        return '<span class="mp-skill">' + escapeHtml(s) + '</span>';
      }).join('') + '</div></div></section>';
  }

  function renderServices(p) {
    var cards = (p.services || []).map(function (svc) {
      var tags = (svc.deliverables || []).slice(0, 3).map(function (d) {
        return '<span class="mp-deliverable-tag">' + escapeHtml(d) + '</span>';
      }).join('');
      return '<article class="mp-service-card' + (svc.is_featured ? ' featured' : '') + '">' +
        (svc.is_featured ? '<div class="mp-service-featured">Popular</div>' : '') +
        '<div class="mp-service-name">' + escapeHtml(svc.name) + '</div>' +
        '<div class="mp-service-desc">' + escapeHtml(svc.description) + '</div>' +
        (tags ? '<div class="mp-deliverables">' + tags + '</div>' : '') +
        '<div class="mp-service-meta">' +
          '<div class="mp-service-price">From ' + formatMoney(svc.price) + '</div>' +
          '<div class="mp-service-delivery">' + (svc.delivery_days ? svc.delivery_days + ' days' : '') + '</div>' +
        '</div>' +
        '<button type="button" class="mp-service-book" data-service="' + escapeHtml(svc.id) + '">Book this gig</button>' +
      '</article>';
    }).join('');

    return '<section class="mp-section" id="services">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">Gigs</div><h2 class="mp-section-title">Bookable <em>tech gigs</em></h2></div></div>' +
      '<div class="mp-services-grid">' + cards + '</div></section>';
  }

  function renderPortfolio(p) {
    var cards = (p.portfolio_projects || []).map(function (proj) {
      return '<article class="mp-project-card">' +
        '<img class="mp-project-img" src="' + escapeHtml(proj.image || '/icons/Icon-512.png') + '" alt="" loading="lazy">' +
        '<div class="mp-project-body">' +
          '<div class="mp-project-title">' + escapeHtml(proj.title) + '</div>' +
          '<div class="mp-project-desc">' + escapeHtml(proj.description) + '</div>' +
          (proj.result ? '<div class="mp-project-result">' + escapeHtml(proj.result) + '</div>' : '') +
          '<div class="mp-project-tags">' + (proj.tags || []).map(function (t) {
            return '<span class="mp-deliverable-tag">' + escapeHtml(t) + '</span>';
          }).join('') + '</div>' +
          (proj.url ? '<a href="' + escapeHtml(proj.url) + '" class="btn-ghost" style="margin-top:12px;display:inline-flex;font-size:12px" target="_blank" rel="noopener">View project</a>' : '') +
        '</div></article>';
    }).join('');

    return '<section class="mp-section" id="portfolio">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">Portfolio</div><h2 class="mp-section-title">Past <em>work</em></h2></div></div>' +
      '<div class="mp-portfolio-grid">' + cards + '</div></section>';
  }

  function renderActivity() {
    return '<section class="mp-section" id="activity">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">Activity</div><h2 class="mp-section-title">Latest <em>builds</em></h2></div></div>' +
      '<div class="act-feed-shell mp-card" style="padding:20px"><div id="mp-activity-feed"></div></div></section>';
  }

  function renderTestimonials(p) {
    var cards = (p.testimonials || []).map(function (t) {
      return '<blockquote class="mp-testimonial">' +
        '<p class="mp-testimonial-quote">"' + escapeHtml(t.quote) + '"</p>' +
        '<div class="mp-stars">' + renderStars(t.rating || 5) + '</div>' +
        '<div class="mp-testimonial-author">' +
          '<div class="mp-testimonial-name">' + escapeHtml(t.name) + '</div>' +
          '<div class="mp-testimonial-role">' + escapeHtml(t.role) + '</div>' +
        '</div></blockquote>';
    }).join('');

    return '<section class="mp-section" id="testimonials">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">Social proof</div><h2 class="mp-section-title">Client <em>reviews</em></h2></div></div>' +
      '<div class="mp-testimonials"><div class="mp-testimonial-track">' + cards + '</div></div></section>';
  }

  function renderAvailability(p) {
    var days = (p.availability || []).slice(0, 14).map(function (d) {
      return '<button type="button" class="mp-cal-day open" data-date="' + escapeHtml(d.date) + '">' +
        '<div class="mp-cal-date">' + escapeHtml(formatDateShort(d.date)) + '</div>' +
        '<div class="mp-cal-slots">' + (d.slots ? d.slots.length + ' slots' : 'Open') + '</div></button>';
    }).join('');

    return '<section class="mp-section" id="availability">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">Calendar</div><h2 class="mp-section-title">Open <em>slots</em></h2></div></div>' +
      '<div class="mp-card"><p style="font-size:13px;color:var(--g-text-muted);margin-bottom:16px">Select a preferred date for your discovery call or kickoff session.</p>' +
      '<div class="mp-calendar-grid">' + days + '</div></div></section>';
  }

  function renderBooking(p) {
    var serviceOptions = (p.services || []).map(function (s) {
      return '<option value="' + escapeHtml(s.id) + '">' + escapeHtml(s.name) + ' · from ' + formatMoney(s.price) + '</option>';
    }).join('');

    return '<section class="mp-section" id="book">' +
      '<div class="mp-section-head"><div><div class="mp-section-label">Get started</div><h2 class="mp-section-title">Book <em>The Gearsh</em></h2></div></div>' +
      '<div class="mp-book-panel">' +
        '<p style="font-size:14px;color:var(--g-text-muted);margin-bottom:20px">Tell me about your project. I will review your brief and respond within 24 hours with next steps or a custom quote.</p>' +
        '<form id="mp-book-form">' +
          '<div class="mp-book-grid">' +
            '<div class="mp-field"><label>Your name *</label><input name="client_name" required placeholder="Full name"></div>' +
            '<div class="mp-field"><label>Email *</label><input name="client_email" type="email" required placeholder="you@company.com"></div>' +
            '<div class="mp-field"><label>Phone number *</label><input name="client_phone" required placeholder="+27…"></div>' +
            '<div class="mp-field"><label>Service *</label><select name="service_id" id="mp-service-select" required><option value="">Select a service</option>' + serviceOptions + '</select></div>' +
            '<div class="mp-field"><label>Preferred date *</label><input name="event_date" id="mp-date-input" type="date" required></div>' +
            '<div class="mp-field"><label>Preferred time</label><input name="preferred_time" placeholder="e.g. 14:00 SAST"></div>' +
          '</div>' +
          '<div class="mp-field"><label>Project brief *</label><textarea name="project_brief" required placeholder="What are you building? Timeline, budget range, tech stack preferences, and goals…"></textarea></div>' +
          '<div class="mp-field"><label>Company / brand (optional)</label><input name="event_location" placeholder="Remote / Online or company name"></div>' +
          '<div id="mp-book-msg" class="mp-msg"></div>' +
          '<button type="submit" class="btn-main" style="margin-top:8px;padding:14px 32px"><i class="ti ti-send"></i> Send booking inquiry</button>' +
          '<div class="mp-trust-row">' +
            '<span><i class="ti ti-lock"></i> Secure & confidential</span>' +
            '<span><i class="ti ti-shield-check"></i> Verified founder profile</span>' +
            '<span><i class="ti ti-clock"></i> Response within 24 hrs</span>' +
            '<span><i class="ti ti-credit-card"></i> Deposit via PayFast after quote</span>' +
          '</div>' +
        '</form></div></section>';
  }

  function bindEvents() {
    document.querySelectorAll('.mp-service-book').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var id = btn.getAttribute('data-service');
        var sel = document.getElementById('mp-service-select');
        if (sel) sel.value = id;
        document.getElementById('book').scrollIntoView({ behavior: 'smooth' });
      });
    });

    document.querySelectorAll('.mp-cal-day').forEach(function (btn) {
      btn.addEventListener('click', function () {
        document.querySelectorAll('.mp-cal-day').forEach(function (b) { b.classList.remove('selected'); });
        btn.classList.add('selected');
        selectedDate = btn.getAttribute('data-date');
        var input = document.getElementById('mp-date-input');
        if (input) input.value = selectedDate;
        document.getElementById('book').scrollIntoView({ behavior: 'smooth' });
      });
    });

    var form = document.getElementById('mp-book-form');
    if (form) {
      form.addEventListener('submit', submitBooking);
    }

    document.querySelectorAll('.mp-nav-link').forEach(function (link) {
      link.addEventListener('click', function () {
        document.querySelectorAll('.mp-nav-link').forEach(function (l) { l.classList.remove('active'); });
        link.classList.add('active');
      });
    });
  }

  function submitBooking(e) {
    e.preventDefault();
    var form = e.target;
    var msg = document.getElementById('mp-book-msg');
    var fd = new FormData(form);
    msg.textContent = 'Sending inquiry…';
    msg.className = 'mp-msg';

    fetch(API + '/booking-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        artist_username: USERNAME,
        artist_id: profile.artist_id,
        client_name: fd.get('client_name'),
        client_email: fd.get('client_email'),
        client_phone: fd.get('client_phone'),
        service_id: fd.get('service_id'),
        event_date: fd.get('event_date'),
        event_location: fd.get('event_location') || 'Remote / Online',
        preferred_time: fd.get('preferred_time'),
        project_brief: fd.get('project_brief'),
      }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Could not send inquiry');
        msg.textContent = d.message || 'Inquiry sent! The Gearsh will respond within 24 hours.';
        msg.className = 'mp-msg success';
        form.reset();
      })
      .catch(function (err) {
        msg.textContent = err.message;
        msg.className = 'mp-msg error';
      });
  }

  function initActivityFeed() {
    if (!window.GearshActivityFeed || !profile) return;
    new GearshActivityFeed({
      container: '#mp-activity-feed',
      mode: 'artist',
      artistId: USERNAME,
    });
  }

  function render(p) {
    profile = p;
    document.title = p.name + ' (@' + p.username + ') | Gearsh';
    root.innerHTML =
      renderHero(p) +
      '<div class="mp-body">' +
        renderNav() +
        renderAbout(p) +
        renderServices(p) +
        renderPortfolio(p) +
        renderActivity() +
        renderTestimonials(p) +
        renderAvailability(p) +
        renderBooking(p) +
      '</div>';
    bindEvents();
    setTimeout(initActivityFeed, 60);
  }

  fetch(API + '/master-profile/' + USERNAME)
    .then(function (r) { return r.json(); })
    .then(function (d) {
      if (!d.success) throw new Error(d.error || 'Profile not found');
      render(d.data);
    })
    .catch(function (err) {
      root.innerHTML = '<div class="mp-body"><div class="mp-card"><h1 style="color:var(--g-white)">' + escapeHtml(err.message) + '</h1></div></div>';
    });
})();
