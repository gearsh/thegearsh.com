(function(){
  'use strict';
  function rewrite(){
    document.querySelectorAll('a[href*="book-gig?artist="]').forEach(function(a){
      var href=a.getAttribute('href');
      var match=href.match(/book-gig\?artist=([^&#]+)/i);
      if(match) a.setAttribute('href','/profile.html?artist='+match[1]);
    });
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',rewrite);
  else rewrite();
  new MutationObserver(rewrite).observe(document.body,{childList:true,subtree:true});
})();