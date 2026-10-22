(function () {
  const menuButton = document.getElementById('join-menu-button');
  const mobileMenu = document.getElementById('join-mobile-menu');
  menuButton.addEventListener('click', function () {
    const open = mobileMenu.hidden;
    mobileMenu.hidden = !open;
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    menuButton.textContent = open ? '×' : '☰';
  });
  mobileMenu.querySelectorAll('a').forEach(function (link) {
    link.addEventListener('click', function () {
      mobileMenu.hidden = true;
      menuButton.setAttribute('aria-expanded', 'false');
      menuButton.setAttribute('aria-label', 'Open menu');
      menuButton.textContent = '☰';
    });
  });

  const error = document.getElementById('error');
  const notice = document.getElementById('notice');
  function showError(message) { error.textContent = message; error.style.display = 'block'; }
  function clearError() { error.textContent = ''; error.style.display = 'none'; }
  async function post(path, body) {
    const response = await fetch(path, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body)
    });
    let result;
    try { result = await response.json(); }
    catch (_) { throw new Error('The service is temporarily unavailable. Please try again later.'); }
    if (!response.ok || result.success === false) {
      throw new Error(result.error || 'The service is temporarily unavailable. Please try again later.');
    }
    return result;
  }

  const forgotForm = document.getElementById('forgot-form');
  if (forgotForm) {
    forgotForm.addEventListener('submit', async function (event) {
      event.preventDefault(); clearError(); notice.hidden = true;
      const button = document.getElementById('submit-btn');
      button.disabled = true; button.textContent = 'Sending…';
      try {
        const result = await post('/api/forgot-password', { email: document.getElementById('email').value.trim() });
        notice.textContent = result.message || 'If an account exists with that email, we will send a reset link.';
        notice.hidden = false;
      } catch (err) { showError(err.message); }
      finally { button.disabled = false; button.textContent = 'Send reset link'; }
    });
  }

  const resetForm = document.getElementById('reset-form');
  if (resetForm) {
    const token = new URLSearchParams(window.location.search).get('token');
    window.history.replaceState({}, '', '/reset-password');
    const intro = document.getElementById('reset-intro');
    if (!token) {
      intro.textContent = 'This reset link is missing or invalid. Request a new link below.';
      return;
    }
    fetch('/api/validate-reset-token', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: token })
    }).then(function (response) { return response.json(); }).then(function (result) {
      if (!result.valid) throw new Error('This reset link is invalid or expired. Request a new link below.');
      intro.textContent = 'Choose a new password of at least 8 characters.';
      resetForm.hidden = false;
    }).catch(function () {
      intro.textContent = 'This reset link is invalid or expired. Request a new link below.';
    });
    resetForm.addEventListener('submit', async function (event) {
      event.preventDefault(); clearError();
      const password = document.getElementById('new-password').value;
      if (password !== document.getElementById('confirm-password').value) {
        showError('Passwords do not match.'); return;
      }
      const button = document.getElementById('submit-btn');
      button.disabled = true; button.textContent = 'Updating…';
      try {
        const result = await post('/api/reset-password', { token: token, password: password });
        resetForm.hidden = true;
        intro.textContent = 'Your password has been updated.';
        notice.textContent = result.message || 'You can sign in with your new password.';
        notice.hidden = false;
      } catch (err) { showError(err.message); }
      finally { button.disabled = false; button.textContent = 'Update password'; }
    });
  }
})();
