/**
 * Create Activity form for artist dashboard
 */
(function (global) {
  'use strict';

  var API_BASE = '/api';

  var TYPE_OPTIONS = [
    { value: 'gig', label: 'Live / Upcoming gig' },
    { value: 'collaboration', label: 'Feature / Collaboration' },
    { value: 'photoshoot', label: 'Photoshoot / Visual drop' },
    { value: 'studio', label: 'Studio session' },
    { value: 'travel', label: 'Travel / Tour' },
    { value: 'press', label: 'Press / Media' },
    { value: 'milestone', label: 'Milestone' },
    { value: 'custom', label: 'Custom update' },
  ];

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function authHeaders(token) {
    return {
      Authorization: 'Bearer ' + token,
      Accept: 'application/json',
    };
  }

  function ActivityCreateForm(options) {
    this.container = typeof options.container === 'string'
      ? document.querySelector(options.container)
      : options.container;
    this.token = options.token || localStorage.getItem('gearsh_token') || '';
    this.onSuccess = options.onSuccess || null;
    this.mediaUrls = [];

    if (!this.container) return;
    this.render();
    this.bind();
  }

  ActivityCreateForm.prototype.render = function () {
    var typeOptions = TYPE_OPTIONS.map(function (opt) {
      return '<option value="' + opt.value + '">' + escapeHtml(opt.label) + '</option>';
    }).join('');

    this.container.innerHTML =
      '<div class="act-create-shell">' +
        '<div class="section-label">Post to your feed</div>' +
        '<h2 class="card-title" style="margin-bottom:8px">Share your <em>latest</em></h2>' +
        '<p class="card-sub" style="margin-bottom:20px">Gigs, collabs, studio nights, milestones. Keep bookers and fans close to your career.</p>' +
        '<form class="act-create-form" id="act-create-form">' +
          '<div class="act-field"><label for="act-type">Activity type</label>' +
            '<select id="act-type" required>' + typeOptions + '</select></div>' +
          '<div class="act-field"><label for="act-title">Headline</label>' +
            '<input id="act-title" required maxlength="200" placeholder="Performed at Origin Live, Cape Town"></div>' +
          '<div class="act-field"><label for="act-desc">Description</label>' +
            '<textarea id="act-desc" maxlength="2000" placeholder="Tell fans and bookers what happened…"></textarea></div>' +
          '<div class="act-field"><label for="act-venue">Venue (optional)</label>' +
            '<input id="act-venue" maxlength="120" placeholder="The O2 Arena"></div>' +
          '<div class="act-field"><label for="act-location">City / location (optional)</label>' +
            '<input id="act-location" maxlength="120" placeholder="London, UK"></div>' +
          '<div class="act-field"><label for="act-date">Event date (optional)</label>' +
            '<input id="act-date" type="date"></div>' +
          '<div class="act-field"><label>Photos</label>' +
            '<input type="file" id="act-media-input" accept="image/jpeg,image/png,image/webp" multiple>' +
            '<div class="act-media-preview" id="act-media-preview"></div></div>' +
          '<div class="act-toggle-row">' +
            '<div><strong>Public on your profile</strong><span>Only public posts appear to fans and bookers.</span></div>' +
            '<input type="checkbox" id="act-public" checked></div>' +
          '<button type="submit" class="btn-main" id="act-submit" style="justify-content:center">Publish activity</button>' +
          '<p id="act-create-msg" style="font-size:13px;color:var(--g-text-muted);min-height:20px"></p>' +
        '</form></div>';
  };

  ActivityCreateForm.prototype.bind = function () {
    var self = this;
    var form = this.container.querySelector('#act-create-form');
    var fileInput = this.container.querySelector('#act-media-input');

    fileInput.addEventListener('change', function () {
      Array.prototype.forEach.call(fileInput.files || [], function (file) {
        self.uploadFile(file);
      });
      fileInput.value = '';
    });

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      self.submit();
    });
  };

  ActivityCreateForm.prototype.renderPreview = function () {
    var wrap = this.container.querySelector('#act-media-preview');
    wrap.innerHTML = this.mediaUrls.map(function (url, idx) {
      return '<div class="act-media-thumb">' +
        '<img src="' + escapeHtml(url) + '" alt="">' +
        '<button type="button" class="act-media-remove" data-idx="' + idx + '">×</button></div>';
    }).join('');

    wrap.querySelectorAll('.act-media-remove').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var i = Number(btn.getAttribute('data-idx'));
        self.mediaUrls.splice(i, 1);
        self.renderPreview();
      });
    });
  };

  ActivityCreateForm.prototype.uploadFile = function (file) {
    var self = this;
    var msg = this.container.querySelector('#act-create-msg');
    if (file.size > 4 * 1024 * 1024) {
      msg.textContent = 'Image too large. Max 4MB each.';
      return;
    }

    var reader = new FileReader();
    reader.onload = function () {
      var base64 = String(reader.result || '').split(',')[1];
      fetch(API_BASE + '/upload-activity-media', {
        method: 'POST',
        headers: Object.assign({ 'Content-Type': 'application/json' }, authHeaders(self.token)),
        body: JSON.stringify({ image_data: base64, mime_type: file.type }),
      })
        .then(function (res) { return res.json(); })
        .then(function (payload) {
          if (!payload.success) throw new Error(payload.error || 'Upload failed');
          self.mediaUrls.push(payload.data.media_url);
          self.renderPreview();
          msg.textContent = '';
        })
        .catch(function (err) {
          msg.textContent = err.message;
        });
    };
    reader.readAsDataURL(file);
  };

  ActivityCreateForm.prototype.submit = function () {
    var self = this;
    var msg = this.container.querySelector('#act-create-msg');
    var btn = this.container.querySelector('#act-submit');
    btn.disabled = true;
    msg.textContent = 'Publishing…';

    var payload = {
      activity_type: this.container.querySelector('#act-type').value,
      title: this.container.querySelector('#act-title').value.trim(),
      description: this.container.querySelector('#act-desc').value.trim(),
      venue: this.container.querySelector('#act-venue').value.trim(),
      location: this.container.querySelector('#act-location').value.trim(),
      event_date: this.container.querySelector('#act-date').value || null,
      media_urls: this.mediaUrls,
      is_public: this.container.querySelector('#act-public').checked,
    };

    fetch(API_BASE + '/activity', {
      method: 'POST',
      headers: Object.assign({ 'Content-Type': 'application/json' }, authHeaders(this.token)),
      body: JSON.stringify(payload),
    })
      .then(function (res) { return res.json(); })
      .then(function (data) {
        if (!data.success) throw new Error(data.error || 'Could not publish');
        msg.textContent = 'Published. Your feed is live.';
        self.container.querySelector('#act-create-form').reset();
        self.mediaUrls = [];
        self.renderPreview();
        if (self.onSuccess) self.onSuccess(data.data.activity);
      })
      .catch(function (err) {
        msg.textContent = err.message;
      })
      .finally(function () {
        btn.disabled = false;
      });
  };

  global.GearshActivityCreate = ActivityCreateForm;
})(typeof window !== 'undefined' ? window : globalThis);
