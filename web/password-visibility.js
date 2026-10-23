/* Accessible, independent visibility controls for password inputs. */
(function () {
  'use strict';
  var eye = '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>';
  var hiddenEye = '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m3 3 18 18M10.6 5.1A11 11 0 0 1 12 5c6.5 0 10 7 10 7a19 19 0 0 1-3.1 4.1M6.2 6.2A20 20 0 0 0 2 12s3.5 7 10 7a11 11 0 0 0 5.8-1.8M9.9 9.9a3 3 0 0 0 4.2 4.2"/></svg>';
  document.querySelectorAll('input[type="password"]').forEach(function (input, index) {
    if (input.parentElement.classList.contains('password-field')) return;
    if (!input.id) input.id = 'password-field-' + index;
    var wrapper = document.createElement('div');
    wrapper.className = 'password-field';
    input.parentNode.insertBefore(wrapper, input);
    wrapper.appendChild(input);
    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'password-visibility';
    button.setAttribute('aria-controls', input.id);
    var label = input.labels && input.labels[0] ? input.labels[0].textContent.trim() : 'password';
    function update(visible) {
      input.type = visible ? 'text' : 'password';
      var action = (visible ? 'Hide ' : 'Show ') + label;
      button.setAttribute('aria-label', action);
      button.title = action;
      button.innerHTML = visible ? hiddenEye : eye;
    }
    update(false);
    button.addEventListener('click', function () {
      var start = input.selectionStart;
      var end = input.selectionEnd;
      update(input.type === 'password');
      input.focus({ preventScroll: true });
      if (start !== null && end !== null) input.setSelectionRange(start, end);
    });
    if (input.form) input.form.addEventListener('submit', function () { update(false); });
    window.addEventListener('pageshow', function () { update(false); });
    wrapper.appendChild(button);
  });
})();
