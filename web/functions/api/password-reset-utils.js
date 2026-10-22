export async function hashResetToken(token) {
  const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
  return Array.from(new Uint8Array(bytes), byte => byte.toString(16).padStart(2, '0')).join('');
}

export function resetBaseUrl(request) {
  const url = new URL(request.url);
  if (url.hostname === 'website-revamp-v1.thegearsh-com.pages.dev') return url.origin;
  return 'https://thegearsh.com';
}

export function escapeHtml(value) {
  return String(value || '').replace(/[&<>"']/g, char => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[char]);
}
