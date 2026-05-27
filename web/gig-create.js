/**
 * Artist gig creation — dashboard Gigs tab
 */
(function (global) {
  'use strict';

  var API = '/api';
  var TIER_OPTIONS = [
    { value: 'general', label: 'General Admission' },
    { value: 'early_bird', label: 'Early Bird' },
    { value: 'vip', label: 'VIP' },
    { value: 'table', label: 'Table / Reserved' },
    { value: 'meet_greet', label: 'Meet & Greet add-on' },
    { value: 'addon', label: 'Add-on' },
  ];

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function GigCreate(options) {
    this.root = typeof options.container === 'string'
      ? document.querySelector(options.container)
      : options.container;
    this.token = options.token || localStorage.getItem('gearsh_token') || '';
    this.onCreated = options.onCreated || null;
    this.tierCount = 0;
    if (this.root) this.render();
  }

  GigCreate.prototype.render = function () {
    var self = this;
    this.root.innerHTML =
      '<div class="section-label">Ticketed gigs</div>' +
      '<h2 class="card-title">Create a <em>live event</em></h2>' +
      '<p class="card-sub">Publish a gig with ticket tiers. It appears in your Activity feed with a Buy Tickets button.</p>' +
      '<form id="gig-create-form">' +
        '<div class="tkt-form-grid">' +
          '<div class="field-group"><label class="field-label">Event title *</label><input class="field-input" name="title" required maxlength="120" placeholder="Ultra South Africa 2026"></div>' +
          '<div class="field-group"><label class="field-label">Flyer image URL</label><input class="field-input" name="flyer_url" placeholder="https://…"></div>' +
          '<div class="field-group"><label class="field-label">Venue *</label><input class="field-input" name="venue" required placeholder="Nasrec Expo Centre"></div>' +
          '<div class="field-group"><label class="field-label">City *</label><input class="field-input" name="city" required placeholder="Johannesburg"></div>' +
          '<div class="field-group"><label class="field-label">Country</label><input class="field-input" name="country" value="South Africa"></div>' +
          '<div class="field-group"><label class="field-label">Capacity</label><input class="field-input" name="capacity" type="number" min="0" placeholder="5000"></div>' +
          '<div class="field-group"><label class="field-label">Starts at *</label><input class="field-input" name="starts_at" type="datetime-local" required></div>' +
          '<div class="field-group"><label class="field-label">Sales end</label><input class="field-input" name="sales_end_at" type="datetime-local"></div>' +
        '</div>' +
        '<div class="field-group" style="margin-top:12px"><label class="field-label">Description</label><textarea class="field-textarea" name="description" rows="4" placeholder="Lineup, vibe, dress code…"></textarea></div>' +
        '<div class="field-group"><label class="field-label">Refund policy</label><textarea class="field-textarea" name="refund_policy" rows="2" placeholder="No refunds within 48 hours of the event."></textarea></div>' +
          '<div class="field-group"><label class="field-label">Visibility</label><select class="field-select" name="visibility"><option value="public">Public</option><option value="followers">Approved followers only</option></select></div>' +
          '<div class="field-group"><label class="field-label">Category</label><select class="field-select" name="category"><option value="music">Music</option><option value="tech">Tech Events</option><option value="cultural">Cultural</option><option value="festival">Festival</option></select></div>' +
        '<div style="margin:20px 0 10px"><div class="section-label">Ticket types</div></div>' +
        '<div id="gig-tiers-root"></div>' +
        '<button type="button" class="btn-ghost" id="gig-add-tier" style="margin-bottom:16px"><i class="ti ti-plus"></i> Add ticket type</button>' +
        '<div class="tkt-form-grid">' +
          '<div class="field-group"><label class="field-label">Promo code (optional)</label><input class="field-input" name="promo_code" placeholder="EARLY20"></div>' +
          '<div class="field-group"><label class="field-label">Promo discount %</label><input class="field-input" name="promo_percent" type="number" min="0" max="100" placeholder="20"></div>' +
        '</div>' +
        '<label style="display:flex;align-items:center;gap:8px;font-size:13px;color:var(--g-text-muted);margin:14px 0">' +
          '<input type="checkbox" name="post_to_feed" checked> Post to Activity feed when published</label>' +
        '<div id="gig-create-msg" class="tkt-msg"></div>' +
        '<button type="submit" class="btn-main" style="margin-top:8px">Publish gig &amp; tickets</button>' +
      '</form>' +
      '<div style="margin-top:28px"><div class="section-label">Your events</div><div id="gig-events-list"><div class="tkt-skeleton tkt-skel-line w60"></div></div></div>';

    this.tiersRoot = this.root.querySelector('#gig-tiers-root');
    this.form = this.root.querySelector('#gig-create-form');
    this.msgEl = this.root.querySelector('#gig-create-msg');
    this.eventsList = this.root.querySelector('#gig-events-list');

    this.root.querySelector('#gig-add-tier').addEventListener('click', function () {
      self.addTier();
    });
    this.form.addEventListener('submit', function (e) {
      e.preventDefault();
      self.submit();
    });

    this.addTier({ name: 'General Admission', tier_kind: 'general', price: 250, quantity_total: 100 });
    this.addTier({ name: 'VIP', tier_kind: 'vip', price: 850, quantity_total: 30 });
    this.loadEvents();
  };

  GigCreate.prototype.addTier = function (preset) {
    var id = 'tier_' + (++this.tierCount);
    var presetData = preset || {};
    var options = TIER_OPTIONS.map(function (o) {
      var sel = o.value === (presetData.tier_kind || 'general') ? ' selected' : '';
      return '<option value="' + o.value + '"' + sel + '>' + o.label + '</option>';
    }).join('');

    var html =
      '<div class="tkt-create-tier" data-tier="' + id + '">' +
        '<div class="tkt-create-tier-head">' +
          '<strong style="color:var(--g-white);font-size:14px">Ticket type</strong>' +
          '<button type="button" class="btn-ghost" data-remove-tier style="padding:4px 10px;font-size:12px">Remove</button>' +
        '</div>' +
        '<div class="tkt-form-grid">' +
          '<div class="field-group"><label class="field-label">Name</label><input class="field-input" data-name value="' + escapeHtml(presetData.name || '') + '" required></div>' +
          '<div class="field-group"><label class="field-label">Kind</label><select class="field-select" data-kind>' + options + '</select></div>' +
          '<div class="field-group"><label class="field-label">Price (ZAR)</label><input class="field-input" data-price type="number" min="0" step="0.01" value="' + (presetData.price || '') + '" required></div>' +
          '<div class="field-group"><label class="field-label">Quantity</label><input class="field-input" data-qty type="number" min="1" value="' + (presetData.quantity_total || 50) + '" required></div>' +
        '</div>' +
        '<div class="field-group" style="margin-top:8px"><label class="field-label">Description</label><input class="field-input" data-desc placeholder="What is included?"></div>' +
      '</div>';

    this.tiersRoot.insertAdjacentHTML('beforeend', html);
    var block = this.tiersRoot.querySelector('[data-tier="' + id + '"]');
    block.querySelector('[data-remove-tier]').addEventListener('click', function () {
      if (block.parentElement.children.length <= 1) return;
      block.remove();
    });
  };

  GigCreate.prototype.collectTiers = function () {
    var tiers = [];
    this.tiersRoot.querySelectorAll('.tkt-create-tier').forEach(function (el) {
      tiers.push({
        name: el.querySelector('[data-name]').value.trim(),
        tier_kind: el.querySelector('[data-kind]').value,
        price: Number(el.querySelector('[data-price]').value),
        quantity_total: Number(el.querySelector('[data-qty]').value),
        description: el.querySelector('[data-desc]').value.trim() || null,
      });
    });
    return tiers;
  };

  GigCreate.prototype.submit = function () {
    var self = this;
    var fd = new FormData(this.form);
    var startsAt = fd.get('starts_at');
    if (startsAt) startsAt = new Date(startsAt).toISOString();

    var salesEnd = fd.get('sales_end_at');
    if (salesEnd) salesEnd = new Date(salesEnd).toISOString();

    var payload = {
      title: fd.get('title'),
      description: fd.get('description'),
      venue: fd.get('venue'),
      city: fd.get('city'),
      country: fd.get('country') || 'South Africa',
      flyer_url: fd.get('flyer_url') || null,
      capacity: Number(fd.get('capacity') || 0),
      starts_at: startsAt,
      sales_end_at: salesEnd || null,
      refund_policy: fd.get('refund_policy') || null,
      visibility: fd.get('visibility') || 'public',
      category: fd.get('category') || 'music',
      publish: true,
      post_to_feed: !!this.form.querySelector('[name="post_to_feed"]').checked,
      ticket_types: this.collectTiers(),
    };

    var promoCode = String(fd.get('promo_code') || '').trim();
    var promoPercent = Number(fd.get('promo_percent') || 0);
    if (promoCode && promoPercent > 0) {
      payload.promo_codes = [{ code: promoCode, discount_type: 'percent', discount_value: promoPercent }];
    }

    this.msgEl.textContent = 'Publishing…';
    this.msgEl.className = 'tkt-msg';

    fetch(API + '/gigs/events', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + this.token,
      },
      body: JSON.stringify(payload),
    })
      .then(function (res) { return res.json(); })
      .then(function (data) {
        if (!data.success) throw new Error(data.error || 'Could not create event');
        self.msgEl.textContent = 'Live! Share: ' + data.data.url;
        self.msgEl.className = 'tkt-msg success';
        self.form.reset();
        self.tiersRoot.innerHTML = '';
        self.tierCount = 0;
        self.addTier({ name: 'General Admission', tier_kind: 'general', price: 250, quantity_total: 100 });
        self.loadEvents();
        if (self.onCreated) self.onCreated(data.data);
      })
      .catch(function (err) {
        self.msgEl.textContent = err.message;
        self.msgEl.className = 'tkt-msg error';
      });
  };

  GigCreate.prototype.loadEvents = function () {
    var self = this;
    fetch(API + '/gigs/events?mine=1', {
      headers: { Authorization: 'Bearer ' + this.token },
    })
      .then(function (res) { return res.json(); })
      .then(function (data) {
        if (!data.success) throw new Error(data.error || 'Failed');
        var events = data.data.events || [];
        if (!events.length) {
          self.eventsList.innerHTML = '<p class="card-sub" style="margin:0">No ticketed gigs yet.</p>';
          return;
        }
        self.eventsList.innerHTML = events.map(function (ev) {
          return '<div class="service-row">' +
            '<div><div class="service-name">' + escapeHtml(ev.title) + '</div>' +
            '<div class="service-desc">' + escapeHtml(ev.city) + ' · ' + escapeHtml(ev.status) +
            ' · ' + Number(ev.tickets_sold || 0) + ' sold · R' + Number(ev.gross_revenue || 0).toLocaleString('en-ZA') + '</div></div>' +
            '<a href="' + escapeHtml(ev.url) + '" class="btn-ghost" style="white-space:nowrap">View</a></div>';
        }).join('');
      })
      .catch(function () {
        self.eventsList.innerHTML = '<p class="card-sub">Could not load events.</p>';
      });
  };

  global.GearshGigCreate = GigCreate;
})(window);
