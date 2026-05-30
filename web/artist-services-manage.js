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
    this.root.innerHTML =
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

    this.loadServices();
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
        list.innerHTML = '<div class="list-stack">' + svcs.map(function (s) {
          return '<div class="list-row">' +
            '<div class="list-row-main">' +
              '<div class="list-row-title">' + escapeHtml(s.name) + '</div>' +
              '<div class="list-row-sub">' + escapeHtml(s.description || 'No description') +
                (s.duration_hours ? ' · ' + s.duration_hours + ' hrs' : '') +
                (s.delivery_days ? ' · ' + s.delivery_days + ' days' : '') +
              '</div></div>' +
            '<div style="display:flex;align-items:center;gap:12px">' +
              '<div class="service-price">R' + Number(s.price).toLocaleString('en-ZA') + '</div>' +
              '<button type="button" class="btn-ghost" data-remove="' + escapeHtml(s.id) + '" style="font-size:12px">Remove</button>' +
            '</div></div>';
        }).join('') + '</div>';

        list.querySelectorAll('[data-remove]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            if (!confirm('Remove this service?')) return;
            fetch(API + '/services?id=' + encodeURIComponent(btn.getAttribute('data-remove')), {
              method: 'DELETE',
              headers: self.authHeaders(),
            })
              .then(function () {
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
