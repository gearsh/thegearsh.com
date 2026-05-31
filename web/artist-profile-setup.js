/**
 * Artist profile setup — profile, portfolio, verification on dashboard
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

  function readFileAsBase64(file) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onload = function () {
        var result = reader.result || '';
        var base64 = String(result).split(',')[1] || '';
        resolve(base64);
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  function compressImageFile(file, maxDim, quality) {
    return new Promise(function (resolve, reject) {
      var url = URL.createObjectURL(file);
      var img = new Image();
      img.onload = function () {
        URL.revokeObjectURL(url);
        var w = img.naturalWidth || img.width;
        var h = img.naturalHeight || img.height;
        if (!w || !h) {
          reject(new Error('Could not read this photo. Try JPG or PNG.'));
          return;
        }
        var scale = Math.min(1, maxDim / Math.max(w, h));
        var canvas = document.createElement('canvas');
        canvas.width = Math.max(1, Math.round(w * scale));
        canvas.height = Math.max(1, Math.round(h * scale));
        var ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        canvas.toBlob(function (blob) {
          if (!blob) {
            reject(new Error('Could not process this photo. Try JPG or PNG.'));
            return;
          }
          resolve(blob);
        }, 'image/jpeg', quality || 0.85);
      };
      img.onerror = function () {
        URL.revokeObjectURL(url);
        reject(new Error('Could not read this photo. Try JPG or PNG.'));
      };
      img.src = url;
    });
  }

  function prepareUploadBlob(file) {
    if (!file || !file.type || file.type.indexOf('image/') !== 0) {
      return compressImageFile(file, 1600, 0.85);
    }
    if (file.size <= 900 * 1024 && file.type !== 'image/heic' && file.type !== 'image/heif') {
      return Promise.resolve(file);
    }
    return compressImageFile(file, 1600, 0.85);
  }

  function ArtistProfileSetup(options) {
    this.root = typeof options.container === 'string'
      ? document.querySelector(options.container)
      : options.container;
    this.token = options.token || localStorage.getItem('gearsh_token') || '';
    this.onChange = options.onChange || null;
    this.preview = null;
    this.portfolio = [];
    if (this.root) this.init();
  }

  ArtistProfileSetup.prototype.authHeaders = function (json) {
    var headers = { Authorization: 'Bearer ' + this.token };
    if (json) headers['Content-Type'] = 'application/json';
    return headers;
  };

  ArtistProfileSetup.prototype.setMsg = function (id, text, ok) {
    var el = document.getElementById(id);
    if (!el) return;
    el.textContent = text;
    el.className = 'aps-msg' + (ok === true ? ' success' : ok === false ? ' error' : '');
  };

  ArtistProfileSetup.prototype.init = function () {
    var self = this;
    this.root.innerHTML =
      '<div class="section-label">Profile setup</div>' +
      '<h2 class="card-title">Build your <em>artist profile</em></h2>' +
      '<p class="card-sub">Complete these steps so clients can find you, see your work, and book you with confidence.</p>' +

      '<div class="card aps-section" id="aps-section-profile" style="margin-bottom:20px;padding:20px">' +
        '<div class="section-label">Step 1</div>' +
        '<h3 style="font-size:16px;color:var(--g-white);margin-bottom:16px">Profile details</h3>' +
        '<form id="aps-profile-form">' +
          '<div class="aps-grid">' +
            '<div class="field-group"><label class="field-label">Stage name *</label>' +
              '<input class="field-input" name="stage_name" id="aps-stage-name" required placeholder="Your artist name"></div>' +
            '<div class="field-group"><label class="field-label">Username</label>' +
              '<input class="field-input" name="username" id="aps-username" placeholder="yourname"></div>' +
            '<div class="field-group"><label class="field-label">Phone *</label>' +
              '<input class="field-input" name="phone" id="aps-phone" type="tel" required placeholder="+27 00 000 0000"></div>' +
            '<div class="field-group"><label class="field-label">Location *</label>' +
              '<input class="field-input" name="location" id="aps-location" required placeholder="Johannesburg"></div>' +
            '<div class="field-group"><label class="field-label">Country</label>' +
              '<input class="field-input" name="country" id="aps-country" placeholder="South Africa"></div>' +
            '<div class="field-group"><label class="field-label">Category</label>' +
              '<select class="field-select" name="category" id="aps-category">' +
                '<option value="Music">Music</option><option value="DJ">DJ</option>' +
                '<option value="Visual Arts">Visual Arts</option><option value="Services">Services</option>' +
                '<option value="Other">Other</option></select></div>' +
            '<div class="field-group"><label class="field-label">Starting price (ZAR)</label>' +
              '<input class="field-input" name="hourly_rate" id="aps-hourly-rate" type="number" min="0" step="1" placeholder="e.g. 3500">' +
              '<p style="font-size:12px;color:var(--g-text-muted);margin:6px 0 0;line-height:1.45">Set during signup — update here if it is wrong. For multiple packages, use the <strong style="color:var(--g-text)">Services</strong> tab.</p></div>' +
          '</div>' +
          '<div class="field-group"><label class="field-label">Bio *</label>' +
            '<textarea class="field-textarea" name="bio" id="aps-bio" rows="4" required placeholder="Tell clients about your style, experience, and what makes you unique."></textarea></div>' +
          '<div class="field-group"><label class="field-label">Skills (comma separated)</label>' +
            '<input class="field-input" name="skills" id="aps-skills" placeholder="House, Amapiano, Live vocals"></div>' +
          '<div class="field-group"><label class="field-label">Profile photo *</label>' +
            '<div class="aps-photo-row">' +
              '<div class="aps-photo-preview" id="aps-photo-preview">Photo</div>' +
              '<label class="btn-ghost aps-upload-btn"><i class="ti ti-camera"></i> Upload photo' +
                '<input type="file" id="aps-photo-input" accept="image/*" capture="environment" hidden></label>' +
            '</div></div>' +
          '<div id="aps-profile-msg" class="aps-msg"></div>' +
          '<button type="submit" class="btn-main" style="margin-top:8px">Save profile</button>' +
        '</form></div>' +

      '<div class="card aps-section" id="aps-section-portfolio" style="margin-bottom:20px;padding:20px">' +
        '<div class="section-label">Step 2</div>' +
        '<h3 style="font-size:16px;color:var(--g-white);margin-bottom:8px">Portfolio</h3>' +
        '<p class="card-sub" style="margin-bottom:16px">Upload photos of your performances, studio work, or past gigs.</p>' +
        '<div class="aps-portfolio-grid" id="aps-portfolio-grid"></div>' +
        '<label class="btn-ghost aps-upload-btn" style="margin-top:12px;display:inline-flex">' +
          '<i class="ti ti-photo-plus"></i> Add photo' +
          '<input type="file" id="aps-portfolio-input" accept="image/*" multiple hidden></label>' +
        '<div id="aps-portfolio-msg" class="aps-msg"></div></div>' +

      '<div class="card aps-section" id="aps-section-verified" style="padding:20px">' +
        '<div class="section-label">Step 3</div>' +
        '<h3 style="font-size:16px;color:var(--g-white);margin-bottom:8px">Get verified</h3>' +
        '<p class="card-sub" id="aps-verify-desc">Verified artists appear higher in search and get more booking requests.</p>' +
        '<div id="aps-email-block" style="display:none;margin-bottom:16px">' +
          '<p style="font-size:13px;color:var(--g-text-muted);margin-bottom:8px">Verify your email to submit for review.</p>' +
          '<div class="aps-inline-row">' +
            '<input class="field-input" id="aps-email-code" placeholder="6-digit code" maxlength="6">' +
            '<button type="button" class="btn-ghost" id="aps-resend-email">Resend code</button>' +
            '<button type="button" class="btn-main" id="aps-verify-email">Verify email</button>' +
          '</div>' +
          '<div id="aps-email-msg" class="aps-msg"></div></div>' +
        '<div id="aps-verify-status" class="aps-status-banner"></div>' +
        '<button type="button" class="btn-main" id="aps-submit-verify" style="margin-top:12px">' +
          '<i class="ti ti-shield-check"></i> Submit for verification</button>' +
        '<div id="aps-verify-msg" class="aps-msg"></div></div>';

    document.getElementById('aps-profile-form').addEventListener('submit', function (e) {
      e.preventDefault();
      self.saveProfile();
    });
    document.getElementById('aps-photo-input').addEventListener('change', function (e) {
      if (e.target.files && e.target.files[0]) self.uploadPhoto(e.target.files[0]);
    });
    document.getElementById('aps-portfolio-input').addEventListener('change', function (e) {
      if (e.target.files && e.target.files.length) self.uploadPortfolioFiles(e.target.files);
    });
    document.getElementById('aps-resend-email').addEventListener('click', function () {
      self.resendEmail();
    });
    document.getElementById('aps-verify-email').addEventListener('click', function () {
      self.verifyEmail();
    });
    document.getElementById('aps-submit-verify').addEventListener('click', function () {
      self.submitVerification();
    });

    this.loadPreview();
  };

  ArtistProfileSetup.prototype.loadPreview = function () {
    var self = this;
    fetch(API + '/onboarding/preview', { headers: this.authHeaders() })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Could not load profile');
        self.preview = d.data;
        self.portfolio = d.data.portfolio_urls || [];
        self.fillForm(d.data);
        self.renderPortfolio();
        self.renderVerification(d.data);
      })
      .catch(function (err) {
        self.setMsg('aps-profile-msg', err.message || 'Could not load profile', false);
      });
  };

  ArtistProfileSetup.prototype.fillForm = function (data) {
    var set = function (id, val) {
      var el = document.getElementById(id);
      if (el && val != null) el.value = val;
    };
    set('aps-stage-name', data.name);
    set('aps-username', data.username);
    set('aps-phone', data.phone);
    set('aps-location', data.location);
    set('aps-country', data.country || 'South Africa');
    set('aps-bio', data.bio);
    set('aps-category', data.category || 'Services');
    if (data.hourly_rate != null || data.base_rate != null) {
      set('aps-hourly-rate', data.hourly_rate != null ? data.hourly_rate : data.base_rate);
    }
    if (data.skills && data.skills.length) {
      set('aps-skills', data.skills.join(', '));
    }
    if (data.image) {
      var preview = document.getElementById('aps-photo-preview');
      preview.style.backgroundImage = 'url(' + data.image + ')';
      preview.textContent = '';
      preview.classList.add('has-photo');
    }
  };

  ArtistProfileSetup.prototype.renderPortfolio = function () {
    var self = this;
    var grid = document.getElementById('aps-portfolio-grid');
    if (!this.portfolio.length) {
      grid.innerHTML = '<p class="card-sub" style="margin:0">No portfolio photos yet. Add your first one above.</p>';
      return;
    }
    grid.innerHTML = this.portfolio.map(function (url, idx) {
      return '<div class="aps-portfolio-item">' +
        '<img src="' + escapeHtml(url) + '" alt="Portfolio">' +
        '<button type="button" class="aps-remove-btn" data-idx="' + idx + '" title="Remove">&times;</button></div>';
    }).join('');
    grid.querySelectorAll('[data-idx]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        self.removePortfolio(Number(btn.getAttribute('data-idx')));
      });
    });
  };

  ArtistProfileSetup.prototype.renderVerification = function (data) {
    var emailBlock = document.getElementById('aps-email-block');
    var status = document.getElementById('aps-verify-status');
    var submitBtn = document.getElementById('aps-submit-verify');
    emailBlock.style.display = data.email_verified ? 'none' : 'block';

    if (data.email_verified && data.onboarding_status === 'pending' && !data.is_verified) {
      status.innerHTML = '<span class="status-pill status-pending">Under review</span> ' +
        'Your profile has been submitted. We typically approve within 24–48 hours.';
      submitBtn.disabled = true;
      submitBtn.textContent = 'Submitted — under review';
    } else if (data.is_verified) {
      status.innerHTML = '<span class="status-pill status-confirmed">Verified</span> ' +
        'You are a verified Gearsh artist.';
      submitBtn.style.display = 'none';
    } else {
      status.innerHTML = '';
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<i class="ti ti-shield-check"></i> Submit for verification';
    }
  };

  ArtistProfileSetup.prototype.saveProfile = function () {
    var self = this;
    this.setMsg('aps-profile-msg', 'Saving…');
    var skills = String(document.getElementById('aps-skills').value || '')
      .split(',').map(function (s) { return s.trim(); }).filter(Boolean);
    var hourlyRaw = document.getElementById('aps-hourly-rate').value.trim();
    var payload = {
      stage_name: document.getElementById('aps-stage-name').value.trim(),
      username: document.getElementById('aps-username').value.trim() || undefined,
      phone: document.getElementById('aps-phone').value.trim(),
      location: document.getElementById('aps-location').value.trim(),
      country: document.getElementById('aps-country').value.trim(),
      category: document.getElementById('aps-category').value,
      bio: document.getElementById('aps-bio').value.trim(),
      skills: skills,
      portfolio: this.portfolio,
    };
    if (hourlyRaw !== '') payload.hourly_rate = Number(hourlyRaw);

    fetch(API + '/onboarding/save', {
      method: 'POST',
      headers: this.authHeaders(true),
      body: JSON.stringify(payload),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Save failed');
        self.setMsg('aps-profile-msg', 'Profile saved.', true);
        if (self.onChange) self.onChange();
      })
      .catch(function (err) {
        self.setMsg('aps-profile-msg', err.message, false);
      });
  };

  ArtistProfileSetup.prototype.uploadPhoto = function (file) {
    var self = this;
    this.setMsg('aps-profile-msg', 'Preparing photo…');
    prepareUploadBlob(file)
      .then(function (blob) {
        if (blob.size > 3 * 1024 * 1024) {
          return compressImageFile(blob, 1200, 0.75);
        }
        return blob;
      })
      .then(function (blob) {
        self.setMsg('aps-profile-msg', 'Uploading photo…');
        return readFileAsBase64(blob).then(function (base64) {
          return fetch(API + '/upload-profile-photo', {
            method: 'POST',
            headers: self.authHeaders(true),
            body: JSON.stringify({
              image_data: base64,
              mime_type: 'image/jpeg',
              type: 'profile',
            }),
          });
        });
      })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Upload failed');
        var url = d.data.photo_url;
        var preview = document.getElementById('aps-photo-preview');
        preview.style.backgroundImage = 'url(' + url + ')';
        preview.textContent = '';
        preview.classList.add('has-photo');
        self.setMsg('aps-profile-msg', 'Photo uploaded. Save profile to keep other changes.', true);
        if (self.onChange) self.onChange();
      })
      .catch(function (err) {
        self.setMsg('aps-profile-msg', err.message, false);
      });
  };

  ArtistProfileSetup.prototype.uploadPortfolioFiles = function (files) {
    var self = this;
    this.setMsg('aps-portfolio-msg', 'Uploading…');
    var chain = Promise.resolve();
    Array.prototype.forEach.call(files, function (file) {
      chain = chain.then(function () {
        return prepareUploadBlob(file).then(function (blob) {
          if (blob.size > 3 * 1024 * 1024) {
            return compressImageFile(blob, 1200, 0.75);
          }
          return blob;
        }).then(function (blob) {
          return readFileAsBase64(blob).then(function (base64) {
            return fetch(API + '/upload-profile-photo', {
              method: 'POST',
              headers: self.authHeaders(true),
              body: JSON.stringify({
                image_data: base64,
                mime_type: 'image/jpeg',
                type: 'portfolio',
              }),
            }).then(function (r) { return r.json(); });
          });
        }).then(function (d) {
          if (!d.success) throw new Error(d.error || 'Upload failed');
          self.portfolio.push(d.data.photo_url);
        });
      });
    });
    chain
      .then(function () {
        return fetch(API + '/onboarding/save', {
          method: 'POST',
          headers: self.authHeaders(true),
          body: JSON.stringify({ portfolio: self.portfolio }),
        });
      })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Could not save portfolio');
        self.renderPortfolio();
        self.setMsg('aps-portfolio-msg', 'Portfolio updated.', true);
        document.getElementById('aps-portfolio-input').value = '';
        if (self.onChange) self.onChange();
      })
      .catch(function (err) {
        self.setMsg('aps-portfolio-msg', err.message, false);
      });
  };

  ArtistProfileSetup.prototype.removePortfolio = function (idx) {
    var self = this;
    this.portfolio.splice(idx, 1);
    fetch(API + '/onboarding/save', {
      method: 'POST',
      headers: this.authHeaders(true),
      body: JSON.stringify({ portfolio: this.portfolio }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Could not update portfolio');
        self.renderPortfolio();
        self.setMsg('aps-portfolio-msg', 'Photo removed.', true);
        if (self.onChange) self.onChange();
      })
      .catch(function (err) {
        self.setMsg('aps-portfolio-msg', err.message, false);
      });
  };

  ArtistProfileSetup.prototype.resendEmail = function () {
    var self = this;
    this.setMsg('aps-email-msg', 'Sending…');
    fetch(API + '/onboarding/resend-email', {
      method: 'POST',
      headers: this.authHeaders(true),
      body: JSON.stringify({}),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Could not send code');
        var msg = 'Code sent. Check your email.';
        if (d.data && d.data.demo_code) msg += ' Demo code: ' + d.data.demo_code;
        self.setMsg('aps-email-msg', msg, true);
      })
      .catch(function (err) {
        self.setMsg('aps-email-msg', err.message, false);
      });
  };

  ArtistProfileSetup.prototype.verifyEmail = function () {
    var self = this;
    var code = document.getElementById('aps-email-code').value.trim();
    if (!code) {
      this.setMsg('aps-email-msg', 'Enter the 6-digit code', false);
      return;
    }
    this.setMsg('aps-email-msg', 'Verifying…');
    fetch(API + '/onboarding/verify-email', {
      method: 'POST',
      headers: this.authHeaders(true),
      body: JSON.stringify({ code: code }),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) throw new Error(d.error || 'Invalid code');
        self.setMsg('aps-email-msg', 'Email verified.', true);
        document.getElementById('aps-email-block').style.display = 'none';
        if (self.onChange) self.onChange();
        self.loadPreview();
      })
      .catch(function (err) {
        self.setMsg('aps-email-msg', err.message, false);
      });
  };

  ArtistProfileSetup.prototype.submitVerification = function () {
    var self = this;
    this.setMsg('aps-verify-msg', 'Submitting…');
    fetch(API + '/onboarding/submit', {
      method: 'POST',
      headers: this.authHeaders(true),
      body: JSON.stringify({}),
    })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.success) {
          var err = new Error(d.error || 'Submit failed');
          err.code = d.code;
          throw err;
        }
        self.setMsg('aps-verify-msg', d.message || 'Submitted for review.', true);
        if (self.onChange) self.onChange();
        self.loadPreview();
      })
      .catch(function (err) {
        var msg = err.message;
        if (err.code === 'PROFILE') self.focusSection('profile');
        if (err.code === 'PORTFOLIO') self.focusSection('portfolio');
        if (err.code === 'SERVICES') {
          if (typeof global.switchTab === 'function') global.switchTab('services');
        }
        if (err.code === 'EMAIL_VERIFY') self.focusSection('verified');
        self.setMsg('aps-verify-msg', msg, false);
      });
  };

  ArtistProfileSetup.prototype.focusSection = function (id) {
    var el = document.getElementById('aps-section-' + id);
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  global.GearshArtistProfileSetup = ArtistProfileSetup;
})(window);
