const SITE_ORIGIN = 'https://thegearsh.com';
export const DEFAULT_OG_IMAGE = `${SITE_ORIGIN}/icons/og-banner.png`;

export function escapeHtml(value) {
  return String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function absoluteUrl(request, path) {
  if (!path) return DEFAULT_OG_IMAGE;
  if (/^https?:\/\//i.test(path)) return path;
  const base = new URL(request.url);
  const normalized = path.startsWith('/') ? path : `/${path}`;
  if (normalized.startsWith('/assets/')) return `${SITE_ORIGIN}${normalized}`;
  return new URL(normalized, `${base.protocol}//${base.host}`).toString();
}

export function resolveMediaUrl(request, path) {
  if (!path) return DEFAULT_OG_IMAGE;
  if (/^https?:\/\//i.test(path)) return path;
  const value = String(path).replace(/^assets\//, '/assets/');
  return absoluteUrl(request, value.startsWith('/') ? value : `/assets/${value}`);
}

export function buildSharePageHtml(options) {
  const {
    title,
    description,
    url,
    image,
    redirectUrl,
    siteName = 'Gearsh',
    type = 'website',
  } = options;

  const safeTitle = escapeHtml(title);
  const safeDescription = escapeHtml(description);
  const safeUrl = escapeHtml(url);
  const safeImage = escapeHtml(image || DEFAULT_OG_IMAGE);
  const safeSite = escapeHtml(siteName);
  const safeRedirect = escapeHtml(redirectUrl || url);
  const safeType = escapeHtml(type);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${safeTitle}</title>
  <meta name="description" content="${safeDescription}">
  <link rel="canonical" href="${safeUrl}">
  <meta property="og:type" content="${safeType}">
  <meta property="og:site_name" content="${safeSite}">
  <meta property="og:title" content="${safeTitle}">
  <meta property="og:description" content="${safeDescription}">
  <meta property="og:url" content="${safeUrl}">
  <meta property="og:image" content="${safeImage}">
  <meta property="og:image:secure_url" content="${safeImage}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="${safeTitle}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:site" content="@thegearsh">
  <meta name="twitter:title" content="${safeTitle}">
  <meta name="twitter:description" content="${safeDescription}">
  <meta name="twitter:image" content="${safeImage}">
  <meta name="twitter:image:alt" content="${safeTitle}">
  <meta http-equiv="refresh" content="0;url=${safeRedirect}">
  <style>
    body { margin: 0; font-family: system-ui, sans-serif; background: #0a0a0a; color: #fff; display: grid; place-items: center; min-height: 100vh; }
    a { color: #00bfff; }
  </style>
</head>
<body>
  <p>Opening on Gearsh… <a href="${safeRedirect}">Continue</a></p>
</body>
</html>`;
}

export function htmlResponse(html, status = 200) {
  return new Response(html, {
    status,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=300',
    },
  });
}
