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
        '<a href="/gearsh" class="btn-main"><i class="ti ti-external-link"></i> View live profile</a>' +
        '<a href="/gearsh#book" class="btn-ghost" target="_blank">Test booking form</a>' +
      '</div>' +
      '<div class="card" style="margin-bottom:20px;padding:20px">' +
        '<div class="section-label">Profile copy</div>' +
        '<form id="mp-edit-form">' +
          '<div class="field-group"><label class="field-label">Display name</label><input class="field-input" id="mp-name" maxlength="100"></div>' +
          '<div class="field-group"><label class="field-label">Profile photo</label><div class="aps-photo-row"><img id="mp-photo-preview" alt="Profile preview" style="width:88px;height:88px;border-radius:50%;object-fit:cover;background:#111"/><label class="btn-ghost aps-upload-btn">Choose picture<input id="mp-photo-upload" type="file" accept="image/*" hidden></label></div><small style="color:var(--g-text-muted)">Choose a photo from your phone or computer. Keep your face centred.</small></div>' +
          '<div class="field-group"><label class="field-label">Profile image URL</label><input class="field-input" id="mp-image" placeholder="/assets/images/your-photo.png"></div>' +
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
    document.getElementById('mp-photo-upload').addEventListener('change', function (event) {
      if (event.target.files[0]) self.uploadFounderPhoto(event.target.files[0]);
    });

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
        var name = document.getElementById('mp-name');
        var image = document.getElementById('mp-image');
        if (name) name.value = p.name || '';
        if (image) image.value = p.image || '';
        var picture = document.getElementById('mp-photo-preview');
        if (picture && p.image) picture.src = p.image;
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
        user: { name: document.getElementById('mp-name').value, image: document.getElementById('mp-image').value },
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

  MasterProfileManage.prototype.uploadFounderPhoto = function (file) {
    var self = this;
    var msg = document.getElementById('mp-edit-msg');
    if (!file || !file.type.startsWith('image/')) { msg.textContent = 'Choose a photo file.'; return; }
    msg.textContent = 'Preparing photo…';
    var source = URL.createObjectURL(file);
    var picture = new Image();
    picture.onload = function () {
      URL.revokeObjectURL(source);
      var scale = Math.min(1, 1200 / Math.max(picture.naturalWidth, picture.naturalHeight));
      var canvas = document.createElement('canvas');
      canvas.width = Math.max(1, Math.round(picture.naturalWidth * scale));
      canvas.height = Math.max(1, Math.round(picture.naturalHeight * scale));
      canvas.getContext('2d').drawImage(picture, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(function (blob) {
        if (!blob) { msg.textContent = 'Could not process photo. Try JPG or PNG.'; return; }
        var reader = new FileReader();
        reader.onload = function () {
          msg.textContent = 'Uploading photo…';
          fetch(API + '/upload-profile-photo', {
            method: 'POST', headers: self.authHeaders(),
            body: JSON.stringify({ image_data: String(reader.result).split(',')[1], mime_type: 'image/jpeg', type: 'profile' })
          }).then(function (r) { return r.json(); }).then(function (d) {
            if (!d.success || !d.data || !d.data.photo_url) throw new Error(d.error || 'Photo upload failed');
            var url = d.data.photo_url;
            document.getElementById('mp-image').value = url;
            document.getElementById('mp-photo-preview').src = url;
            msg.textContent = 'Photo uploaded. Save profile to publish your changes.';
            msg.className = 'mp-msg success';
          }).catch(function (error) { msg.textContent = error.message; msg.className = 'mp-msg error'; });
        };
        reader.readAsDataURL(blob);
      }, 'image/jpeg', 0.86);
    };
    picture.onerror = function () { URL.revokeObjectURL(source); msg.textContent = 'Cannot read this photo. Try JPG or PNG.'; };
    picture.src = source;
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
