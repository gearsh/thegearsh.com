(function () {
  'use strict';

  var API = '/api';
  var root = document.getElementById('tickets-root');
  var token = localStorage.getItem('gearsh_token');

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatDate(iso) {
    return new Date(iso).toLocaleString('en-ZA', {
      weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
    });
  }

  if (!token) {
    root.innerHTML = '<div class="tkt-card"><p style="color:var(--g-text-muted)">Sign in to view your tickets, or check your email for your ticket link.</p><a href="/auth.html?redirect=' + encodeURIComponent('/my-tickets') + '" class="btn-main" style="display:inline-flex;margin-top:12px">Sign in</a></div>';
    return;
  }

  fetch(API + '/my-tickets', { headers: { Authorization: 'Bearer ' + token } })
    .then(function (r) { return r.json(); })
    .then(function (d) {
      if (!d.success) throw new Error(d.error || 'Failed');
      var tickets = d.data.tickets || [];
      if (!tickets.length) {
        root.innerHTML = '<div class="tkt-card"><p style="color:var(--g-text-muted)">No tickets yet. When you buy tickets to a Gearsh gig, they show up here instantly.</p><a href="/search" class="btn-main" style="display:inline-flex;margin-top:12px">Find events</a></div>';
        return;
      }
      root.innerHTML = tickets.map(function (t) {
        var flyer = t.event.flyer_url || '/icons/Icon-512.png';
        return '<article class="tkt-ticket-card">' +
          '<div class="tkt-ticket-top">' +
            '<img class="tkt-ticket-flyer" src="' + escapeHtml(flyer) + '" alt="">' +
            '<div>' +
              '<div style="font-weight:700;color:var(--g-white);font-size:16px">' + escapeHtml(t.event.title) + '</div>' +
              '<div style="font-size:13px;color:var(--g-text-muted);margin-top:4px">' + escapeHtml(t.tier_name) + ' · ' + escapeHtml(formatDate(t.event.starts_at)) + '</div>' +
              '<div style="font-size:12px;color:var(--g-text-muted);margin-top:4px">' + escapeHtml(t.event.venue) + ', ' + escapeHtml(t.event.city) + '</div>' +
            '</div>' +
            '<span class="tkt-ticket-code">' + escapeHtml(t.ticket_code) + '</span>' +
          '</div>' +
          '<div style="padding:0 18px 18px;display:flex;gap:8px;flex-wrap:wrap">' +
            '<a href="' + escapeHtml(t.url) + '" class="btn-main">View ticket</a>' +
            '<a href="' + escapeHtml(t.event.url) + '" class="btn-ghost">Event details</a>' +
          '</div></article>';
      }).join('');
    })
    .catch(function (err) {
      root.innerHTML = '<div class="tkt-card"><p class="tkt-msg error">' + escapeHtml(err.message) + '</p></div>';
    });
})();
