(function(){
  'use strict';
  if (!/\.pages\.dev$/i.test(window.location.hostname)) return;
  document.addEventListener('DOMContentLoaded', function(){
    var form=document.getElementById('booking-form');
    if(!form) return;
    form.addEventListener('submit', function(e){
      e.preventDefault();
      var service=document.getElementById('service-id');
      var msg=document.getElementById('msg');
      var btn=document.getElementById('submit');
      if(!service || !service.value){
        if(msg){msg.className='msg error';msg.textContent='Choose a service first.';}
        return;
      }
      if(msg){msg.className='msg success';msg.textContent='Preview booking request received. Live submission will use the Gearsh booking API.';}
      if(btn){btn.disabled=true;btn.textContent='Request received';}
    }, true);
  });
})();