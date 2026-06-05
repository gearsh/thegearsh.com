/**
 * Artist services CRUD — dashboard Services tab
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

  function ArtistServicesManage(options) {
    this.root = typeof options.container === 'string'
      ? document.querySelector(options.container)
      : options.container;
    this.token = options.token || localStorage.getItem('gearsh_token') || '';
    this.onChange = options.onChange || null;
    if (this.root) this.init();
  }

  ArtistServicesManage.prototype.authHeaders = function () {
    return {
      'Content-Type': 'application/json',
      Authorization: 'Bearer ' + this.token,
    };
  };

  ArtistServicesManage.prototype.init = function () {
    var self = this;
    this.services = [];
    this.editingId = null;
    this.root.innerHTML =
      '<p class="card-sub" style="margin:0 0 16px">Wrong price from signup or a seeded profile? Edit any package below — clients see these rates when booking.</p>' +
      '<div id="asv-list"></div>' +
      '<hr style="border:none;border-top:0.5px solid var(--g-border);margin:24px 0">' +
      '<h3 style="font-size:15px;color:var(--g-white);margin-bottom:12px">Add a service</h3>' +
      '<form id="asv-form">' +
        '<div class="aps-grid">' +
          '<div class="field-group"><label class="field-label">Name *</label>' +
            '<input class="field-input" name="name" required placeholder="Live set (2 hours)"></div>' +
          '<div class="field-group"><label class="field-label">Price (ZAR) *</label>' +
            '<input class="field-input" name="price" type="number" min="0" required placeholder="5000"></div>' +
          '<div class="field-group"><label class="field-label">Duration (hours)</label>' +
            '<input class="field-input" name="duration_hours" type="number" min="0.5" step="0.5" placeholder="2"></div>' +
          '<div class="field-group"><label class="field-label">Delivery days</label>' +
            '<input class="field-input" name="delivery_days" type="number" min="1" placeholder="Optional"></div>' +
          '<div class="field-group"><label class="field-label">Category</label>' +
            '<select class="field-input" name="marketplace_category" id="asv-category"></select></div>' +
        '</div>' +
        '<div class="field-group"><label class="field-label">Description</label>' +
          '<textarea class="field-textarea" name="description" rows="3" placeholder="What clients get when they book this package."></textarea></div>' +
        '<div id="asv-msg" class="aps-msg"></div>' +
        '<button type="submit" class="btn-main" style="margin-top:8px"><i class="ti ti-plus"></i> Add service</button>' +
      '</form>';

    document.getElementById('asv-form').addEventListener('submit', function (e) {
      e.preventDefault();
      self.addService();
    });

    this.populateCategories();
    this.loadServices();
  };

  ArtistServicesManage.prototype.populateCategories = function () {
    var sel = document.getElementById('asv-category');
    if (!sel) return;
    var options = [{ id: 'producers', title: 'General production' }];
    if (global.GearshMarketplace && GearshMarketplace.FEATURED) {
      options = GearshMarketplace.FEATURED.map(function (c) {
        return { id: c.id, title: c.title };
      }).concat([
        { id: 'producers', title: 'Production' },
        { id: 'djs', title: 'DJ services' },
        { id: 'feature-artists', title: 'Feature / collab' },
      ]);
    }
    sel.innerHTML = options.map(function (opt) {
      return '<option value="' + escapeHtml(opt.id) + '">' + escapeHtml(opt.title) + '</option>';
    }).join('');
  };

  ArtistServicesManage.prototype.setMsg = function (text, ok) {
    var el = document.getElementById('asv-msg');
    if (!el) return;
    el.textContent = text;
    el.className = 'aps-msg' + (ok ? ' success' : ' error');
  };

  ArtistServicesManage.prototype.loadServices = function () {
    var self = this;
    var list = document.getElementById('asv-list');
    list.innerHTML = '<p class="card-sub">Loading services…</p>';

    fetch(API + '/services', { headers: this.authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Could not load services');
        var svcs = (d.data.services || []).filter(function (s) { return s.is_active; });
        if (!svcs.length) {
          list.innerHTML = '<p class="card-sub">No services yet. Add your first package below so clients can book you.</p>';
          return;
        }
        self.services = svcs;
        list.innerHTML = svcs.map(function (s) {
          return self.renderServiceItem(s);
        }).join('');

        list.querySelectorAll('[data-edit]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            self.openEdit(btn.getAttribute('data-edit'));
          });
        });
        list.querySelectorAll('[data-cancel]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            self.closeEdit();
          });
        });
        list.querySelectorAll('.asv-edit-form').forEach(function (form) {
          form.addEventListener('submit', function (e) {
            e.preventDefault();
            self.saveService(form.getAttribute('data-edit-form'));
          });
        });
        list.querySelectorAll('[data-remove]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            if (!confirm('Remove this service?')) return;
            fetch(API + '/services?id=' + encodeURIComponent(btn.getAttribute('data-remove')), {
              method: 'DELETE',
              headers: self.authHeaders(),
            })
              .then(function () {
                self.closeEdit();
                self.loadServices();
                if (self.onChange) self.onChange();
              });
          });
        });
      })
      .catch(function (err) {
        list.innerHTML = '<p class="card-sub">' + escapeHtml(err.message) + '</p>';
      });
  };

  ArtistServicesManage.prototype.renderServiceItem = function (s) {
    var open = this.editingId === s.id;
    return '<div class="asv-item" style="margin-bottom:10px">' +
      '<div class="list-row"' + (open ? ' style="display:none"' : '') + ' data-view="' + escapeHtml(s.id) + '">' +
        '<div class="list-row-main">' +
          '<div class="list-row-title">' + escapeHtml(s.name) + '</div>' +
          '<div class="list-row-sub">' + escapeHtml(s.description || 'No description') +
            (s.duration_hours ? ' · ' + s.duration_hours + ' hrs' : '') +
            (s.delivery_days ? ' · ' + s.delivery_days + ' days' : '') +
          '</div></div>' +
        '<div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">' +
          '<div class="service-price">R' + Number(s.price).toLocaleString('en-ZA') + '</div>' +
          '<button type="button" class="btn-ghost" data-edit="' + escapeHtml(s.id) + '" style="font-size:12px">Edit</button>' +
          '<button type="button" class="btn-ghost" data-remove="' + escapeHtml(s.id) + '" style="font-size:12px">Remove</button>' +
        '</div></div>' +
      '<form class="asv-edit-form card" data-edit-form="' + escapeHtml(s.id) + '" style="' +
        (open ? 'padding:16px;margin:0' : 'display:none') + '">' +
        '<div class="section-label">Edit service</div>' +
        '<div class="aps-grid">' +
          '<div class="field-group"><label class="field-label">Name</label>' +
            '<input class="field-input asv-name" value="' + escapeHtml(s.name) + '" required></div>' +
          '<div class="field-group"><label class="field-label">Price (ZAR)</label>' +
            '<input class="field-input asv-price" type="number" min="1" step="1" value="' + Number(s.price) + '" required></div>' +
          '<div class="field-group"><label class="field-label">Duration (hours)</label>' +
            '<input class="field-input asv-duration" type="number" min="0.5" step="0.5" value="' + (s.duration_hours || '') + '"></div>' +
          '<div class="field-group"><label class="field-label">Delivery days</label>' +
            '<input class="field-input asv-days" type="number" min="1" value="' + (s.delivery_days || '') + '"></div>' +
        '</div>' +
        '<div class="field-group"><label class="field-label">Description</label>' +
          '<textarea class="field-textarea asv-desc" rows="2">' + escapeHtml(s.description || '') + '</textarea></div>' +
        '<div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px">' +
          '<button type="submit" class="btn-main" style="height:40px">Save changes</button>' +
          '<button type="button" class="btn-ghost" data-cancel="' + escapeHtml(s.id) + '" style="height:40px">Cancel</button>' +
        '</div></form></div>';
  };

  ArtistServicesManage.prototype.openEdit = function (serviceId) {
    this.editingId = serviceId;
    this.loadServices();
  };

  ArtistServicesManage.prototype.closeEdit = function () {
    this.editingId = null;
    this.loadServices();
  };

  ArtistServicesManage.prototype.saveService = function (serviceId) {
    var self = this;
    var form = document.querySelector('[data-edit-form="' + serviceId + '"]');
    if (!form) return;

    var price = Number(form.querySelector('.asv-price').value);
    if (!price || price < 1) {
      this.setMsg('Enter a valid price (R1 or more).', false);
      return;
    }

    this.setMsg('Saving…', true);
    fetch(API + '/services', {
      method: 'PATCH',
      headers: this.authHeaders(),
      body: JSON.stringify({
        id: serviceId,
        name: form.querySelector('.asv-name').value.trim(),
        price: price,
        duration_hours: Number(form.querySelector('.asv-duration').value || 0) || null,
        delivery_days: Number(form.querySelector('.asv-days').value || 0) || null,
        description: form.querySelector('.asv-desc').value.trim(),
        marketplace_category: form.querySelector('.asv-category') ? form.querySelector('.asv-category').value : undefined,
      }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Failed to update');
        self.closeEdit();
        self.setMsg('Pricing updated.', true);
        self.loadServices();
        if (self.onChange) self.onChange();
      })
      .catch(function (err) {
        self.setMsg(err.message, false);
      });
  };

  ArtistServicesManage.prototype.addService = function () {
    var self = this;
    var form = document.getElementById('asv-form');
    var fd = new FormData(form);
    this.setMsg('Adding…', true);

    fetch(API + '/services', {
      method: 'POST',
      headers: this.authHeaders(),
      body: JSON.stringify({
        name: fd.get('name'),
        price: Number(fd.get('price')),
        duration_hours: Number(fd.get('duration_hours') || 0) || null,
        delivery_days: Number(fd.get('delivery_days') || 0) || null,
        description: fd.get('description'),
        marketplace_category: fd.get('marketplace_category'),
      }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Failed to add service');
        self.setMsg('Service added.', true);
        form.reset();
        self.loadServices();
        if (self.onChange) self.onChange();
      })
      .catch(function (err) {
        self.setMsg(err.message, false);
      });
  };

  global.GearshArtistServicesManage = ArtistServicesManage;
})(window);
