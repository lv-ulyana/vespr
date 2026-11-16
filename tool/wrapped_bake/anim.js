()=>{
const root=document.querySelector('.sl');
const skip=e=>e.closest('.top,.body,.prog,.ctl,.tap');
const all=[...root.querySelectorAll('*')].filter(e=>!skip(e));
const anim=e=>{const cs=getComputedStyle(e);return cs.animationName&&cs.animationName!=='none'?cs:null};
const out=[];
for(const e of all){
  const cs=anim(e); if(!cs) continue;
  // outermost animated
  let p=e.parentElement, inner=false; while(p&&p!==root){if(anim(p)){inner=true;break}p=p.parentElement}
  if(inner) continue;
  const r=e.getBoundingClientRect();
  out.push({tag:e.tagName.toLowerCase(),cls:(e.getAttribute('class')||'').toString(),a:cs.animationName,d:cs.animationDelay,dur:cs.animationDuration,it:cs.animationIterationCount,o:cs.transformOrigin,r:[r.x,r.y,r.width,r.height].map(Math.round),vis:cs.visibility})
}
return out}
