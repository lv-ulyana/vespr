()=>{
const root=document.querySelector('.sl');
const kill=document.getElementById('kill');
const skip=e=>e.closest('.top,.body,.prog,.ctl,.tap');
kill.disabled=true;
const anim=e=>{const cs=getComputedStyle(e);return cs.animationName&&cs.animationName!=='none'};
const els=[...root.querySelectorAll('*')].filter(e=>!skip(e)&&anim(e)&&getComputedStyle(e).visibility!=='hidden');
const top=els.filter(e=>{const rr=e.getBoundingClientRect();if(rr.width<2||rr.height<2)return false;let p=e.parentElement;while(p&&p!==root){if(els.includes(p))return false;p=p.parentElement}return true});
const meta=top.map(e=>{const cs=getComputedStyle(e);return {a:cs.animationName.split(',')[0].trim(),d:parseFloat(cs.animationDelay)||0,dur:parseFloat(cs.animationDuration)||0,it:cs.animationIterationCount,o:cs.transformOrigin,cls:(e.getAttribute('class')||'').toString()}});
kill.disabled=false;
window.__L=top;
top.forEach((e,i)=>{if(meta[i].it==='infinite')e.setAttribute('data-inf','1')});
return top.map((e,i)=>{
  e.classList.add('lyr');
  const r=e.getBoundingClientRect();const pad=30;
  let x=Math.max(0,Math.floor(r.x-pad)),y=Math.max(0,Math.floor(r.y-pad));
  let x2=Math.min(390,Math.ceil(r.right+pad)),y2=Math.min(844,Math.ceil(r.bottom+pad));
  const o=meta[i].o.split(' ').map(parseFloat);
  return {...meta[i],clip:[x,y,Math.max(1,x2-x),Math.max(1,y2-y)],box:[r.x,r.y,r.width,r.height],ox:r.x+0*o[0],}
})}