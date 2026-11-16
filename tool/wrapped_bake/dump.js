()=>{
const out=[];
const root=document.querySelector('.sl');
const R=e=>{const r=e.getBoundingClientRect();return [Math.round(r.x),Math.round(r.y),Math.round(r.width),Math.round(r.height)]};
function walk(e,d){
  const cs=getComputedStyle(e);
  if(cs.display==='none'||cs.visibility==='hidden')return;
  let own='';for(const c of e.childNodes)if(c.nodeType===3)own+=c.textContent;own=own.replace(/\s+/g,' ').trim();
  const tag=e.tagName.toLowerCase();
  if(tag==='svg'){out.push({d,tag,cls:e.getAttribute('class')||'',r:R(e)});return}
  const o={d,tag,cls:(e.getAttribute('class')||''),r:R(e)};
  if(own){o.t=own;o.f=cs.fontFamily.split(',')[0].replace(/["']/g,'')+' '+cs.fontWeight+' '+cs.fontSize+'/'+cs.lineHeight+(cs.letterSpacing!=='normal'?' ls'+cs.letterSpacing:'')+(cs.textTransform!=='none'?' '+cs.textTransform:'')+(cs.fontStyle!=='normal'?' i':'');o.c=cs.color}
  if(cs.backgroundColor!=='rgba(0, 0, 0, 0)')o.bg=cs.backgroundColor;
  if(cs.backgroundImage!=='none')o.bgi=cs.backgroundImage.slice(0,120);
  if(cs.borderRadius!=='0px')o.rad=cs.borderRadius;
  if(cs.boxShadow!=='none')o.sh=cs.boxShadow.slice(0,100);
  if(cs.borderTopWidth!=='0px')o.bt=cs.borderTopWidth+' '+cs.borderTopStyle+' '+cs.borderTopColor;
  if(cs.borderBottomWidth!=='0px')o.bb=cs.borderBottomWidth+' '+cs.borderBottomStyle+' '+cs.borderBottomColor;
  if(cs.transform!=='none')o.tf=cs.transform;
  if(cs.textDecorationLine!=='none')o.td=cs.textDecorationLine;
  if(tag==='img')o.src=(e.getAttribute('src')||'').split('/').pop().slice(0,12);
  out.push(o);
  for(const c of e.children)walk(c,d+1);
}
for(const sel of ['.top','.body','.prog','.ctl']){const e=document.querySelector(sel);if(e){out.push({sel});walk(e,0)}}
// outside-body text holders
const extra=[...root.querySelectorAll('*')].filter(e=>!e.closest('.body')&&!e.closest('.top')&&e.tagName!=='svg'&&!e.closest('svg')&&[...e.childNodes].some(c=>c.nodeType===3&&c.textContent.trim()));
out.push({sel:'OUTSIDE'});
for(const e of extra){const cs=getComputedStyle(e);let own='';for(const c of e.childNodes)if(c.nodeType===3)own+=c.textContent;out.push({tag:e.tagName.toLowerCase(),cls:e.getAttribute('class')||'',par:(e.parentElement.getAttribute('class')||''),r:R(e),t:own.replace(/\s+/g,' ').trim().slice(0,60),f:cs.fontFamily.split(',')[0].replace(/["']/g,'')+' '+cs.fontWeight+' '+cs.fontSize,c:cs.color,tf:cs.transform})}
return out}