/* Shared Gearsh discovery header. No fabricated notification counts. */
(function () {
  'use strict';
  function init() {
    var old = document.querySelector('header.top, header.nav, nav.g-nav');
    if (!old) return;
    var css = document.createElement('link'); css.rel = 'stylesheet'; css.href = '/site-header.css'; document.head.appendChild(css);
    old.hidden = true;
    ['mobileMenu','searchMobileMenu'].forEach(function(id){var el=document.getElementById(id);if(el)el.hidden=true;});
    var paths = {
      menu: '<path d="M4 6h16M4 12h16M4 18h16"/>',
      search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
      mic: '<rect x="9" y="2" width="6" height="13" rx="3"/><path d="M5 10v2a7 7 0 0 0 14 0v-2M12 19v3M8 22h8"/>',
      plus: '<path d="M12 4v16M4 12h16"/>',
      bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 7 3 9H3c0-2 3-2 3-9M10 21h4"/>',
      user: '<circle cx="12" cy="8" r="4"/><path d="M4 22v-3a8 8 0 0 1 16 0v3"/>'
    };
    function icon(name){return '<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+paths[name]+'</svg>';}
    function button(name,label,panel){return '<button type="button" class="gh-icon" title="'+label+'" aria-label="'+label+'" aria-expanded="false" aria-controls="gh-'+panel+'" data-panel="'+panel+'">'+icon(name)+'</button>';}
    var header=document.createElement('header');header.className='gh-header';
    header.innerHTML='<div class="gh-row">'+button('menu','Open navigation','nav')+'<a class="gh-brand" href="/" aria-label="Gearsh home"><img src="/icons/Icon-512.png" alt=""><span>GEARSH</span></a><form class="gh-search" action="/search" role="search"><label class="gh-sr" for="gh-query">Search creatives, services and locations</label><input id="gh-query" name="q" type="search" maxlength="200" placeholder="Search creatives, services, locations" required><button class="gh-submit" aria-label="Search">'+icon('search')+'</button></form><button type="button" id="gh-voice" class="gh-icon" title="Search by voice" aria-label="Search by voice">'+icon('mic')+'</button><div class="gh-actions"><button type="button" class="gh-create" id="gh-book">Book</button>'+button('bell','Notifications','notifications')+button('user','Your account','account')+'</div></div><nav id="gh-nav" class="gh-panel gh-nav" aria-label="Main navigation" hidden><a href="/search">Find talent</a><a href="/artists">All artists</a><a href="/gig-guide">Gig guide</a><a href="/collaborate">Collaborate</a><a href="/lessons">Lessons</a><a href="/glog">G-Log</a><a href="/#how-it-works">How it works</a><a href="/#about">About Gearsh</a></nav><div id="gh-create" class="gh-panel" hidden><a href="/join-gig.html">Create a creative profile</a><a href="/artist-dashboard.html">Manage services and gigs</a></div><section id="gh-notifications" class="gh-panel" aria-label="Notifications" hidden><h2>Notifications</h2><p>Live notifications are not available yet. Check your bookings for updates.</p><a href="/my-bookings">View my bookings</a></section><nav id="gh-account" class="gh-panel" aria-label="Your account" hidden><a href="/auth.html">Sign in</a><a href="/join-gig.html">Join Gearsh</a></nav><p id="gh-status" class="gh-status" role="status" hidden></p>';
    old.before(header);
    header.querySelector("#gh-book").addEventListener("click", function () { location.assign("/search"); });
    header.querySelector('input').value=new URLSearchParams(location.search).get('q')||'';
    function close(){header.querySelectorAll('.gh-panel').forEach(function(p){p.hidden=true;});header.querySelectorAll('[data-panel]').forEach(function(b){b.setAttribute('aria-expanded','false');});}
    header.querySelectorAll('[data-panel]').forEach(function(b){b.addEventListener('click',function(){var p=document.getElementById('gh-'+b.dataset.panel),open=p.hidden;close();p.hidden=!open;b.setAttribute('aria-expanded',String(open));if(open){var a=p.querySelector('a');if(a)a.focus();}});});
    document.addEventListener('click',function(e){if(!header.contains(e.target))close();});
    document.addEventListener('keydown',function(e){if(e.key==='Escape'){var b=header.querySelector('[aria-expanded="true"]');close();if(b)b.focus();}});
    var status=header.querySelector('#gh-status');
    function say(message){status.hidden=false;status.textContent=message;}
    var Speech=window.SpeechRecognition||window.webkitSpeechRecognition;
    var voice=header.querySelector('#gh-voice'),recognition;
    voice.addEventListener('click',function(){
      if(!Speech){say('Voice search is not supported in this browser. Type your search above.');header.querySelector('input').focus();return;}
      if(recognition){recognition.stop();return;}
      recognition=new Speech();recognition.lang='en-ZA';
      recognition.onstart=function(){say('Listening…');voice.setAttribute('aria-pressed','true');};
      recognition.onresult=function(e){header.querySelector('input').value=e.results[0][0].transcript;say('Voice captured. Press Search to see results.');header.querySelector('.gh-submit').focus();};
      recognition.onerror=function(e){say(e.error==='not-allowed'?'Microphone access was denied. You can type your search.':'Could not hear your search. Please try again or type it.');};
      recognition.onend=function(){voice.setAttribute('aria-pressed','false');recognition=null;};
      try{recognition.start();}catch(e){recognition=null;say('Voice search could not start. Please type your search.');}
    });
    async function session(){
      try{
        var token=window.GearshAuth?window.GearshAuth.getToken():localStorage.getItem('gearsh_token');if(!token)return;
        var res=await fetch('/api/session',{headers:{Authorization:'Bearer '+token}});if(!res.ok)return;
        var data=await res.json();if(!data.success)return;var s=data.data;
        var account=header.querySelector('#gh-account');account.replaceChildren();
        [['/my-bookings','My bookings'],['/my-tickets','My tickets']].forEach(function(item){var a=document.createElement('a');a.href=item[0];a.textContent=item[1];account.appendChild(a);});
        if(s.has_artist_dashboard||s.user_type==='artist'||s.user_type==='admin'){var a=document.createElement('a');a.href=s.user_type==='admin'?'/gearsh-god.html':'/artist-dashboard.html';a.textContent='Dashboard';account.prepend(a);}
        var out=document.createElement('button');out.type='button';out.textContent='Sign out';out.onclick=function(){if(window.GearshAuth&&window.GearshAuth.clearSession)window.GearshAuth.clearSession();else{['gearsh_token','gearsh_remember','gearsh_user','gearsh_user_id','gearsh_user_name','gearsh_user_type','gearsh_skills','gearsh_artist_id','gearsh_profile_url','gearsh_username'].forEach(function(key){localStorage.removeItem(key);});}location.assign('/auth.html');};account.appendChild(out);
      }catch(e){/* Public navigation remains usable if the session is unavailable. */}
    }
    session();
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
