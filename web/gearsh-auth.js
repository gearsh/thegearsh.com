/**
 * Gearsh auth — keep users signed in with token refresh and safe session storage.
 */
(function (global) {
  'use strict';

  var TOKEN_KEY = 'gearsh_token';
  var REMEMBER_KEY = 'gearsh_remember_me';
  var REFRESH_SOON_DAYS = 14;

  function getToken() {
    return localStorage.getItem(TOKEN_KEY) || '';
  }

  function isRemembered() {
    return localStorage.getItem(REMEMBER_KEY) !== '0';
  }

  function setRemember(remember) {
    localStorage.setItem(REMEMBER_KEY, remember ? '1' : '0');
  }

  function decodePayload(token) {
    try {
      if (!token || token.indexOf('.') === -1) return null;
      var parts = token.split('.');
      if (parts.length !== 3) return null;
      var payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      while (payload.length % 4) payload += '=';
      return JSON.parse(atob(payload));
    } catch (_) {
      return null;
    }
  }

  function daysUntilExpiry(token) {
    var payload = decodePayload(token);
    if (!payload || !payload.exp) return null;
    return (payload.exp - Date.now()) / (24 * 60 * 60 * 1000);
  }

  function authHeaders() {
    var token = getToken();
    var headers = { Accept: 'application/json', 'Content-Type': 'application/json' };
    if (token) headers.Authorization = 'Bearer ' + token;
    return headers;
  }

  async function refreshSession() {
    var token = getToken();
    if (!token) return false;

    try {
      var res = await fetch('/api/session', {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify({ remember: isRemembered() }),
      });
      var data = await res.json();
      if (res.ok && data.success && data.data && data.data.token) {
        localStorage.setItem(TOKEN_KEY, data.data.token);
        return data.data;
      }
      if (res.status === 401) {
        clearSession();
        return false;
      }
    } catch (_) {
      return null;
    }
    return false;
  }

  function clearSession() {
    [
      TOKEN_KEY,
      REMEMBER_KEY,
      'gearsh_user_id',
      'gearsh_user_name',
      'gearsh_user_type',
      'gearsh_skills',
      'gearsh_artist_id',
      'gearsh_profile_url',
      'gearsh_username',
    ].forEach(function (key) {
      localStorage.removeItem(key);
    });
  }

  async function ensureSession() {
    var token = getToken();
    if (!token) return false;

    var daysLeft = daysUntilExpiry(token);
    if (daysLeft != null && daysLeft > REFRESH_SOON_DAYS) return true;

    try {
      var res = await fetch('/api/session', { headers: { Authorization: 'Bearer ' + token } });
      if (res.ok) {
        if (daysLeft != null && daysLeft <= REFRESH_SOON_DAYS) {
          var refreshed = await refreshSession();
          return refreshed !== false;
        }
        return true;
      }
      if (res.status === 401) {
        var session = await refreshSession();
        if (session === null) return true;
        return session !== false;
      }
    } catch (_) {
      return true;
    }
    return false;
  }

  global.GearshAuth = {
    TOKEN_KEY: TOKEN_KEY,
    REMEMBER_KEY: REMEMBER_KEY,
    getToken: getToken,
    isRemembered: isRemembered,
    setRemember: setRemember,
    refreshSession: refreshSession,
    ensureSession: ensureSession,
    clearSession: clearSession,
    authHeaders: authHeaders,
  };
})(typeof window !== 'undefined' ? window : this);
