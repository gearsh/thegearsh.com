// GET /book/:username — shareable booking links
export async function onRequest(context) {
  const username = String(context.params.username || '').trim();
    if (!username) {
    return Response.redirect(new URL('/book-gig', context.request.url), 302);
  }

  const target = new URL('/book-gig', context.request.url);
  target.searchParams.set('artist', username);
  return Response.redirect(target.toString(), 302);
}
