/**
 * Master Profile management — services CRUD + profile editor for dashboard
 */
(function (global) {
  'use strict';

  var API = '/api';

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function MasterProfileManage(options) {
    this.root = typeof options.container === 'string'
      ? document.querySelector(options.container)
      : options.container;
    this.token = options.token || localStorage.getItem('gearsh_token') || '';
    this.isMaster = options.isMaster || false;
    if (this.root && this.isMaster) this.init();
  }

  MasterProfileManage.prototype.init = function () {
    var self = this;
    this.root.innerHTML =
      '<div class="section-label">Master profile</div>' +
      '<h2 class="card-title">Manage <em>@gearsh</em></h2>' +
      '<p class="card-sub">Edit your public master profile, services, and booking settings.</p>' +
      '<div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:20px">' +
        '<a href="/gearsh" class="btn-main" target="_blank"><i class="ti ti-external-link"></i> View live profile</a>' +
        '<a href="/gearsh#book" class="btn-ghost" target="_blank">Test booking form</a>' +
      '</div>' +
      '<div class="card" style="margin-bottom:20px;padding:20px">' +
        '<div class="section-label">Profile copy</div>' +
        '<form id="mp-edit-form">' +
          '<div class="field-group"><label class="field-label">Tagline</label><input class="field-input" name="tagline" id="mp-tagline"></div>' +
          '<div class="field-group"><label class="field-label">Long bio</label><textarea class="field-textarea" name="long_bio" id="mp-long-bio" rows="6"></textarea></div>' +
          '<div class="field-group"><label class="field-label">Cover image URL</label><input class="field-input" name="cover_image_url" id="mp-cover"></div>' +
          '<div id="mp-edit-msg" class="mp-msg"></div>' +
          '<button type="submit" class="btn-main" style="margin-top:8px">Save profile</button>' +
        '</form></div>' +
      '<div class="card" style="padding:20px">' +
        '<div class="section-label">Services</div>' +
        '<div id="mp-services-list"></div>' +
        '<hr style="border:none;border-top:0.5px solid var(--g-border);margin:20px 0">' +
        '<h3 style="font-size:15px;color:var(--g-white);margin-bottom:12px">Add service</h3>' +
        '<form id="mp-service-form">' +
          '<div class="tkt-form-grid">' +
            '<div class="field-group"><label class="field-label">Name</label><input class="field-input" name="name" required></div>' +
            '<div class="field-group"><label class="field-label">Price (ZAR)</label><input class="field-input" name="price" type="number" min="0" required></div>' +
            '<div class="field-group"><label class="field-label">Delivery days</label><input class="field-input" name="delivery_days" type="number" min="1"></div>' +
            '<div class="field-group"><label class="field-label">Featured</label><select class="field-select" name="is_featured"><option value="0">No</option><option value="1">Yes</option></select></div>' +
          '</div>' +
          '<div class="field-group"><label class="field-label">Description</label><textarea class="field-textarea" name="description" rows="3"></textarea></div>' +
          '<div class="field-group"><label class="field-label">Deliverables (comma separated)</label><input class="field-input" name="deliverables" placeholder="Design, Build, Deploy"></div>' +
          '<div id="mp-svc-msg" class="mp-msg"></div>' +
          '<button type="submit" class="btn-ghost" style="margin-top:8px"><i class="ti ti-plus"></i> Add service</button>' +
        '</form></div>';

    this.loadProfile();
    this.loadServices();

    document.getElementById('mp-edit-form').addEventListener('submit', function (e) {
      e.preventDefault();
      self.saveProfile();
    });
    document.getElementById('mp-service-form').addEventListener('submit', function (e) {
      e.preventDefault();
      self.addService();
    });
  };

  MasterProfileManage.prototype.authHeaders = function () {
    return {
      'Content-Type': 'application/json',
      Authorization: 'Bearer ' + this.token,
    };
  };

  MasterProfileManage.prototype.loadProfile = function () {
    fetch(API + '/master-profile/gearsh')
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) return;
        var p = d.data;
        var tagline = document.getElementById('mp-tagline');
        var bio = document.getElementById('mp-long-bio');
        var cover = document.getElementById('mp-cover');
        if (tagline) tagline.value = p.tagline || '';
        if (bio) bio.value = p.long_bio || '';
        if (cover) cover.value = p.cover_image_url || '';
      });
  };

  MasterProfileManage.prototype.saveProfile = function () {
    var msg = document.getElementById('mp-edit-msg');
    msg.textContent = 'Saving…';
    fetch(API + '/master-profile/manage', {
      method: 'PATCH',
      headers: this.authHeaders(),
      body: JSON.stringify({
        profile: {
          tagline: document.getElementById('mp-tagline').value,
          long_bio: document.getElementById('mp-long-bio').value,
          cover_image_url: document.getElementById('mp-cover').value,
        },
      }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        msg.textContent = d.success ? 'Profile saved.' : (d.error || 'Failed');
        msg.className = 'mp-msg ' + (d.success ? 'success' : 'error');
      });
  };

  MasterProfileManage.prototype.loadServices = function () {
    var self = this;
    var list = document.getElementById('mp-services-list');
    fetch(API + '/services', { headers: this.authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error);
        var svcs = d.data.services || [];
        if (!svcs.length) {
          list.innerHTML = '<p class="card-sub">No services yet.</p>';
          return;
        }
        list.innerHTML = svcs.filter(function (s) { return s.is_active; }).map(function (s) {
          return '<div class="service-row">' +
            '<div><div class="service-name">' + escapeHtml(s.name) + (s.is_featured ? ' ★' : '') + '</div>' +
            '<div class="service-desc">R' + Number(s.price).toLocaleString('en-ZA') +
            (s.delivery_days ? ' · ' + s.delivery_days + ' days' : '') + '</div></div>' +
            '<button type="button" class="btn-ghost" data-remove="' + escapeHtml(s.id) + '" style="font-size:12px">Remove</button></div>';
        }).join('');
        list.querySelectorAll('[data-remove]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            if (!confirm('Remove this service?')) return;
            fetch(API + '/services?id=' + encodeURIComponent(btn.getAttribute('data-remove')), {
              method: 'DELETE',
              headers: self.authHeaders(),
            }).then(function () { self.loadServices(); });
          });
        });
      })
      .catch(function () {
        list.innerHTML = '<p class="card-sub">Could not load services.</p>';
      });
  };

  MasterProfileManage.prototype.addService = function () {
    var self = this;
    var form = document.getElementById('mp-service-form');
    var fd = new FormData(form);
    var msg = document.getElementById('mp-svc-msg');
    var deliverables = String(fd.get('deliverables') || '').split(',').map(function (s) {
      return s.trim();
    }).filter(Boolean);

    fetch(API + '/services', {
      method: 'POST',
      headers: this.authHeaders(),
      body: JSON.stringify({
        name: fd.get('name'),
        price: Number(fd.get('price')),
        delivery_days: Number(fd.get('delivery_days') || 0) || null,
        description: fd.get('description'),
        deliverables: deliverables,
        is_featured: fd.get('is_featured') === '1',
      }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Failed');
        msg.textContent = 'Service added.';
        msg.className = 'mp-msg success';
        form.reset();
        self.loadServices();
      })
      .catch(function (err) {
        msg.textContent = err.message;
        msg.className = 'mp-msg error';
      });
  };

  global.GearshMasterProfileManage = MasterProfileManage;
})(window);
