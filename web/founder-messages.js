(function(){
'use strict';
var root=document.getElementById('founder-messages-root');
if(!root)return;
var token=localStorage.getItem('gearsh_token')||'';
var selected='';
var isFounder=false;
function el(tag,cls,text){var n=document.createElement(tag);if(cls)n.className=cls;if(text!=null)n.textContent=text;return n;}
function headers(){return {'Authorization':'Bearer '+token,'Content-Type':'application/json'};}
async function api(method,body,artist){
 var url='/api/founder-messages'+(artist?'?artist='+encodeURIComponent(artist):'');
 var response=await fetch(url,{method:method,headers:headers(),body:body?JSON.stringify(body):undefined});
 var result=await response.json();
 if(!response.ok||!result.success)throw Error(result.error||'Request failed');
 return result.data;
}
function setup(){root.replaceChildren();var heading=el('h2','card-title','Messages');root.append(heading);
 root.append(el('p','card-sub','Private conversations between The Gearsh founder and creatives. No booking required.'));
 var panel=el('div','fam-layout');panel.style.cssText='display:grid;grid-template-columns:minmax(200px,1fr) minmax(0,2fr);gap:16px';
 var left=el('div','fam-list'),right=el('div','fam-chat');left.id='fam-list';right.id='fam-chat';panel.append(left,right);root.append(panel);
 var status=el('p','aps-msg');status.id='fam-status';status.setAttribute('role','status');root.append(status);
 var style=el('style');style.textContent='.fam-item{display:block;width:100%;margin:5px 0;padding:12px;background:#10263A;border:1px solid #29506a;color:#fff;border-radius:10px;text-align:left;cursor:pointer}.fam-item[aria-current=true]{border-color:#00BFFF}.fam-messages{max-height:330px;min-height:170px;overflow:auto;padding:12px;background:#07111D;border-radius:10px;margin:12px 0}.fam-bubble{max-width:86%;padding:10px 13px;margin:8px 0;border-radius:12px;background:#18364a;white-space:pre-wrap;overflow-wrap:anywhere}.fam-bubble.mine{background:#075a7d;margin-left:auto}.fam-layout textarea{width:100%;background:#07111D;color:#fff;border:1px solid #53768c;border-radius:8px;padding:12px;min-height:94px}@media(max-width:650px){.fam-layout{grid-template-columns:1fr!important}.fam-messages{min-height:140px}}';root.append(style);
}
function status(t){var n=document.getElementById('fam-status');if(n)n.textContent=t;}
async function load(){
 try{
  var data=await api('GET',null,selected);isFounder=data.is_founder;
  var left=document.getElementById('fam-list');left.replaceChildren();
  left.append(el('h3','',isFounder?'Choose a creative':'Conversations'));
  var options=isFounder?data.artists.map(a=>({name:a.name||a.username,username:a.username})):
   data.conversations.map(a=>({name:'The Gearsh founder',username:a.artist_username}));
  if(!options.length)left.append(el('p','card-sub',isFounder?'No artist profiles found.':'No founder messages yet.'));
  options.forEach(function(a){var btn=el('button','fam-item',a.name);btn.type='button';btn.setAttribute('aria-current',a.username===selected?'true':'false');btn.onclick=function(){selected=a.username;load();};left.append(btn);});
  if(!selected&&options.length){selected=options[0].username;return load();}
  var chat=document.getElementById('fam-chat');chat.replaceChildren();
  if(!selected)return;
  chat.append(el('h3','',isFounder?'Message '+(options.find(x=>x.username===selected)?.name||selected):'Founder messages'));
  var messages=el('div','fam-messages');messages.setAttribute('aria-label','Conversation messages');
  data.messages.forEach(function(m){messages.append(el('div','fam-bubble'+(m.mine?' mine':''),m.body));});
  if(!data.messages.length)messages.append(el('p','card-sub',isFounder?'Start a private welcome conversation.':'No messages yet.'));
  chat.append(messages);messages.scrollTop=messages.scrollHeight;
  var form=el('form');var textarea=el('textarea');textarea.placeholder=isFounder?'Write a welcome message…':'Reply to the founder…';textarea.maxLength=2000;textarea.required=true;
  var send=el('button','btn-main','Send message');send.type='submit';send.style.marginTop='10px';form.append(textarea,send);
  form.onsubmit=async function(e){e.preventDefault();send.disabled=true;status('Sending…');try{await api('POST',{artist:selected,message:textarea.value});textarea.value='';status('Message sent.');await load();}catch(err){status(err.message);}finally{send.disabled=false;}};
  chat.append(form);
 }catch(err){status(err.message);}
}
window.initFounderMessages=function(){if(root.dataset.loaded)return;root.dataset.loaded='1';setup();load();};
})();