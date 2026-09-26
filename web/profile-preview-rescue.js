(function(){
  'use strict';
  function boot(){
    var params=new URLSearchParams(window.location.search);
    var slug=(params.get('artist')||params.get('username')||'').trim().toLowerCase();
    if(!slug || typeof SA_SHOWCASE_ARTISTS==='undefined') return;
    var artist=SA_SHOWCASE_ARTISTS.find(function(x){return String(x.username||'').toLowerCase()===slug;});
    if(!artist) return;
    var loading=document.getElementById('loading');
    var content=document.getElementById('content');
    var error=document.getElementById('error');
    var name=document.getElementById('name');
    var photo=document.getElementById('photo');
    var loc=document.getElementById('location');
    var category=document.getElementById('category');
    var bio=document.getElementById('bio');
    var about=document.getElementById('about-copy');
    var skills=document.getElementById('skills');
    var claim=document.getElementById('claim');
    var claimLink=document.getElementById('claim-link');
    var servicesList=document.getElementById('services-list');
    var serviceSelect=document.getElementById('service-id');
    var selected=document.getElementById('selected-service');
    var services=(artist.bookingServices||[]).map(function(s,i){return{id:'showcase-'+artist.username+'-'+i,name:s.name,description:s.description||'',price:Number(s.price||0),duration_hours:s.duration_hours};});
    var esc=function(s){return String(s==null?'':s).replace(/[&<>\"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c];});};
    var money=function(n){return 'R'+Number(n||0).toLocaleString('en-ZA');};
    if(loading) loading.hidden=true;
    if(error) error.hidden=true;
    if(content) content.hidden=false;
    if(name) name.textContent=artist.name||'Creative';
    if(photo){photo.src=artist.image||'icons/Icon-512.png';photo.alt=artist.name||'Creative';}
    if(loc) loc.innerHTML='<i class="ti ti-map-pin"></i> '+esc([artist.location,artist.country].filter(Boolean).join(', ')||'Location on request');
    if(category) category.innerHTML='<i class="ti ti-tag"></i> '+esc(artist.category||'Creative professional');
    if(bio) bio.textContent=artist.bio||'';
    if(about) about.textContent=artist.bio||'Explore this creative professional and the services available through Gearsh.';
    if(skills) skills.innerHTML=(artist.skills||[]).map(function(s){return '<span class="skill">'+esc(s)+'</span>';}).join('');
    if(claim && claimLink){claim.hidden=false;claimLink.href='claim-profile.html?artist='+encodeURIComponent(artist.username);}
    if(servicesList){
      servicesList.innerHTML=services.length?services.map(function(s){return '<button class="service" type="button" data-id="'+esc(s.id)+'"><div class="service-top"><div class="service-name">'+esc(s.name)+'</div><div class="service-price">'+money(s.price)+'</div></div><div class="service-desc">'+esc(s.description)+(s.duration_hours?' · '+esc(s.duration_hours)+' hrs':'')+'</div><div class="service-choose">Choose service <i class="ti ti-arrow-right"></i></div></button>';}).join(''):'<p class="section-copy">Contact this creative to discuss the work and pricing.</p>';
      servicesList.querySelectorAll('.service').forEach(function(btn){btn.addEventListener('click',function(){servicesList.querySelectorAll('.service').forEach(function(x){x.classList.remove('selected');});btn.classList.add('selected');if(serviceSelect)serviceSelect.value=btn.dataset.id;if(selected)selected.textContent='Selected: '+btn.querySelector('.service-name').textContent;var book=document.getElementById('book');if(book)book.scrollIntoView({behavior:'smooth'});});});
    }
    if(serviceSelect){serviceSelect.innerHTML='<option value="">Choose a service</option>';services.forEach(function(s){var o=document.createElement('option');o.value=s.id;o.textContent=s.name+' · '+money(s.price);serviceSelect.appendChild(o);});}
    var form=document.getElementById('booking-form');
    if(form){
      form.addEventListener('submit',function(e){
        if(!serviceSelect || !serviceSelect.value) return;
        if(form.dataset.previewHandled==='1') return;
        e.preventDefault();e.stopImmediatePropagation();form.dataset.previewHandled='1';
        var msg=document.getElementById('msg'),btn=document.getElementById('submit');
        if(msg){msg.className='msg success';msg.textContent='Booking request form is ready. The live booking submission will use this creative profile.';}
        if(btn){btn.textContent='Request ready';btn.disabled=true;}
      },true);
    }
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',boot); else boot();
})();
