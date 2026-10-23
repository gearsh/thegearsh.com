/* Client registration uses the same account API and session as sign in. */
(function () {
  'use strict';
  var form = document.getElementById('client-signup-form');
  var button = document.getElementById('signup-btn');
  var error = document.getElementById('signup-error');
  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    if (button.disabled) return;
    error.style.display = 'none';
    if (!form.reportValidity()) return;
    var firstName = document.getElementById('first-name').value.trim();
    var lastName = document.getElementById('last-name').value.trim();
    var password = document.getElementById('password').value;
    if (!firstName || !lastName) {
      error.textContent = 'Please enter your first and last name.';
      error.style.display = 'block';
      return;
    }
    if (password !== document.getElementById('confirm-password').value) {
      error.textContent = 'Your passwords do not match.';
      error.style.display = 'block';
      document.getElementById('confirm-password').focus();
      return;
    }
    button.disabled = true;
    button.textContent = 'Creating your account…';
    try {
      var response = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          first_name: firstName,
          last_name: lastName,
          email: document.getElementById('email').value.trim().toLowerCase(),
          password: password,
          user_type: 'client'
        })
      });
      var result;
      try { result = await response.json(); }
      catch (_) { throw new Error('Registration is temporarily unavailable. Please try again shortly.'); }
      if (!response.ok || !result.success) {
        throw new Error(result.error || 'Could not create your account. Please try again.');
      }
      var user = result.data;
      if (!user || !user.token) {
        throw new Error('Your account was created. Please use the Sign in link below to continue.');
      }
      GearshAuth.clearSession();
      GearshAuth.setRemember(true);
      localStorage.setItem('gearsh_token', user.token);
      localStorage.setItem('gearsh_user_id', user.user_id || '');
      localStorage.setItem('gearsh_user_name', user.display_name || firstName);
      localStorage.setItem('gearsh_user_type', 'client');
      window.location.replace('/search');
    } catch (err) {
      error.textContent = err.message || 'Unable to connect. Please try again.';
      error.style.display = 'block';
    } finally {
      button.disabled = false;
      button.textContent = 'Create client account';
    }
  });
})();
