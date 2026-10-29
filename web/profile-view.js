(function () {
  'use strict';
  var activeProfile = null, initialized = false, followState = false, followBusy = false, followReady = false;
  function el(tag, className, text) { var n = document.createElement(tag); if (className) n.className = className; if (text != null) n.textContent = text; return n; }
  function safeImage(value) {
    try { var u = new URL(String(value), location.href); return /^https?:$/.test(u.protocol) ? u.href : ''; } catch (_) { return ''; }
  }
  function token() { try { return window.GearshAuth ? window.GearshAuth.getToken() : localStorage.getItem('gearsh_token'); } catch (_) { return ''; } }
  function headers() { var t = token(); return t ? { Authorization: 'Bearer ' + t, 'Content-Type': 'application/json' } : { 'Content-Type': 'application/json' }; }
  function feedback(text, signIn) {
    var n = document.getElementById('profile-feedback'); n.replaceChildren(); n.appendChild(document.createTextNode(text));
    if (signIn) { var a = el('a', '', 'Sign in'); a.href = '/auth.html'; n.appendChild(document.createTextNode(' ')); n.appendChild(a); }
  }
  function followUrl() { return '/api/artists/' + encodeURIComponent(activeProfile.username || activeProfile.artist_id) + '/follow'; }
  function setFollow(d) {
    followState = !!d.is_following;
    var b = document.getElementById('profile-follow'); b.textContent = followState ? 'Following' : '+ Follow'; b.setAttribute('aria-pressed', String(followState));
    var count = Number(d.follower_count);
    if (Number.isFinite(count) && count >= 0) { document.getElementById('profile-followers-count').textContent = count.toLocaleString(); document.getElementById('profile-followers').hidden = false; }
  }
  async function loadFollow() {
    try { var r = await fetch(followUrl(), { headers: headers() }); var j = await r.json(); if (r.ok && j.success) { setFollow(j.data); followReady = true; } } catch (_) { /* Counts stay hidden until confirmed by the API. */ }
  }
  async function toggleFollow() {
    if (followBusy) return;
    if (!token()) { feedback('Sign in to follow this creative and see their updates.', true); return; }
    if (!followReady) { feedback('Follow status is unavailable. Please try again shortly.'); await loadFollow(); return; }
    var b = document.getElementById('profile-follow'); followBusy = true; b.disabled = true; b.textContent = 'Updating…';
    try {
      var r = await fetch(followUrl(), { method: 'POST', headers: headers(), body: JSON.stringify({ action: followState ? 'unfollow' : 'follow' }) });
      var j = await r.json(); if (r.status === 401) { feedback('Your session has expired. Sign in to follow this creative.', true); return; }
      if (!r.ok || !j.success) throw new Error(j.error || 'Could not update follow.'); setFollow(j.data); feedback(followState ? 'You are following this creative.' : 'You have unfollowed this creative.');
    } catch (e) { feedback(e.message || 'Could not update follow. Please try again.'); }
    finally { followBusy = false; b.disabled = false; b.textContent = followState ? 'Following' : '+ Follow'; }
  }
  function init() {
    if (initialized) return; initialized = true;
    var hero = document.querySelector('.profile-hero'), name = document.getElementById('name'), line = el('div', 'profile-name-line');
    name.before(line); line.appendChild(name); var badge = el('span', 'profile-verified', '✦'); badge.id = 'profile-verified'; badge.hidden = true; badge.setAttribute('aria-label', 'Verified creative'); badge.title = 'Verified creative'; line.appendChild(badge);
    var stats = el('div', 'profile-stats'); stats.innerHTML = '<div class="profile-stat" id="profile-followers" hidden><strong id="profile-followers-count"></strong><span>Followers</span></div><div class="profile-stat"><strong id="profile-services-count">0</strong><span>Services</span></div><div class="profile-stat"><strong id="profile-work-count">0</strong><span>Work</span></div>';
    var actions = document.querySelector('.hero-actions'); actions.before(stats);
    var follow = el('button', 'btn btn-secondary', '+ Follow'); follow.id = 'profile-follow'; follow.type = 'button'; follow.setAttribute('aria-pressed', 'false'); follow.onclick = toggleFollow; actions.prepend(follow);
    var book = actions.querySelector('a'); book.textContent = 'Book';
    var share = document.getElementById('share'); share.setAttribute('aria-label', 'Share profile'); share.title = 'Share profile'; share.innerHTML = '<span aria-hidden="true" style="font-size:22px">↗</span><span class="share-label">Share</span>'; 
    share.onclick=async function(){try{if(navigator.share){await navigator.share({title:document.title,url:location.href});}else if(navigator.clipboard){await navigator.clipboard.writeText(location.href);feedback('Profile link copied.');}else{feedback('Copy the page address to share this profile.');}}catch(e){if(e.name!=='AbortError')feedback('Could not share the profile. You can copy the page address.');}};
    var message = el('p', 'profile-feedback'); message.id = 'profile-feedback'; message.setAttribute('role', 'status'); actions.after(message);
    var nav = el('nav', 'profile-subnav'); nav.setAttribute('aria-label', 'Profile sections'); [['work','My work'],['services','Services'],['about','About'],['book','Booking']].forEach(function(x){var a=el('a','',x[1]);a.href='#'+x[0];nav.appendChild(a);});hero.after(nav);
    var work = document.getElementById('work'); nav.after(work); document.getElementById('services').after(document.getElementById('about')); work.querySelector('h2').textContent = 'My work';
    var dialog = el('dialog', 'profile-lightbox'); dialog.id = 'profile-lightbox'; dialog.setAttribute('aria-label', 'Portfolio image'); dialog.innerHTML='<div class="profile-lightbox-top"><span id="profile-lightbox-label">Selected work</span><button type="button">Close</button></div><img alt="">'; document.body.appendChild(dialog); dialog.querySelector('button').onclick=function(){dialog.close();};dialog.onclick=function(e){if(e.target===dialog)dialog.close();};
  }
  function render(d) {
    init(); activeProfile = d; followReady = false;
    document.getElementById('profile-verified').hidden = !d.is_verified || !!d.is_demo;
    var photo = document.getElementById('photo'); photo.onerror = function(){photo.onerror=null;photo.src='/icons/Icon-512.png';};
    var services = d.services || [], portfolio = (d.portfolio_urls || []).map(safeImage).filter(Boolean);
    document.getElementById('profile-services-count').textContent = services.length;
    document.getElementById('profile-services-count').nextElementSibling.textContent = services.length===1?'Service':'Services';
    document.getElementById('profile-work-count').textContent = portfolio.length;
    var work = document.getElementById('work'), grid = document.getElementById('work-grid'); work.hidden = false; grid.replaceChildren();
    if (!portfolio.length) { var empty = el('p','work-empty','No portfolio work shared yet. Explore the services below.'); empty.style.gridColumn='1 / -1'; grid.appendChild(empty); }
    portfolio.forEach(function(url,index){var b=el('button','work-tile');b.type='button';b.setAttribute('aria-label','View work '+(index+1));var img=el('img');img.src=url;img.alt=(d.name||'Creative')+' · work '+(index+1);img.loading='lazy';b.appendChild(img);b.onclick=function(){var dialog=document.getElementById('profile-lightbox');dialog.querySelector('img').src=url;dialog.querySelector('img').alt=img.alt;document.getElementById('profile-lightbox-label').textContent='Work '+(index+1)+' of '+portfolio.length;dialog.showModal();};grid.appendChild(b);});
    var reviews = d.reviews || [], list = document.getElementById('reviews-list'); list.replaceChildren();document.getElementById('reviews').hidden=!reviews.length;
    reviews.forEach(function(r){var card=el('article','profile-review');card.appendChild(el('strong','',r.reviewer_name||'Client'));if(r.rating!=null)card.appendChild(el('p','',Number(r.rating)+' / 5'));if(r.comment)card.appendChild(el('p','',r.comment));list.appendChild(card);});
    var date=document.getElementById('event-date'),now=new Date();date.min=now.getFullYear()+'-'+String(now.getMonth()+1).padStart(2,'0')+'-'+String(now.getDate()).padStart(2,'0');
    loadFollow();
  }
  window.addEventListener('gearsh:profile',function(e){render(e.detail);});
  if(window.GearshProfileData)render(window.GearshProfileData);
})();
