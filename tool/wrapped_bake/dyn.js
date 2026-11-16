(spec)=>{
const root=document.querySelector('.sl');
const norm=s=>(s||'').replace(/\s+/g,'');
const vis=e=>{const cs=getComputedStyle(e);return cs.display!=='none'&&cs.visibility!=='hidden'};
const all=[...root.querySelectorAll('*')].filter(e=>vis(e)&&e.getBoundingClientRect().width>0);
const used=new Set();
const out=[];
const st=e=>{const cs=getComputedStyle(e);const fs=parseFloat(cs.fontSize);
  return {fam:cs.fontFamily.split(',')[0].replace(/["']/g,''),w:parseInt(cs.fontWeight),sz:fs,lh:cs.lineHeight==='normal'?0:parseFloat(cs.lineHeight)/fs,c:cs.color,ls:cs.letterSpacing==='normal'?0:parseFloat(cs.letterSpacing),up:cs.textTransform==='uppercase',it:cs.fontStyle==='italic'}};
function segs(e){const r=[];for(const n of e.childNodes){
  if(n.nodeType===3){const t=n.textContent.replace(/\s+/g,' ');if(t.trim())r.push({t:t,...st(e)});}
  else if(n.nodeType===1){if(!vis(n))continue;if(n.tagName==='BR'){r.push({t:'\n',br:1,...st(e)});continue}
    const cs=getComputedStyle(n);
    if(cs.position==='absolute')continue;
    r.push(...segs(n));}}
  // trim
  if(r.length){r[0].t=r[0].t.replace(/^ /,'');const L=r[r.length-1];L.t=L.t.replace(/ $/,'')}
  return r}
const R=e=>{const r=e.getBoundingClientRect();return [r.x,r.y,r.width,r.height]};
const rotAnc=e=>{let p=e;while(p&&p!==root){const t=getComputedStyle(p).transform;if(t&&t!=='none'){const m=t.match(/matrix\(([^)]+)\)/);if(m){const v=m[1].split(',').map(parseFloat);if(Math.abs(v[1])>1e-3)return p}}p=p.parentElement}return null};
for(const it of spec){
  const [txt,key,fl]=it; const f=fl||{};
  let cands=all.filter(e=>norm(e.innerText)===norm(txt)&&!used.has(e));
  if(f.row) cands=cands.filter(e=>{const d=getComputedStyle(e).display;return d.includes('flex')||d.includes('grid')});
  if(!cands.length){out.push({key,miss:txt});continue}
  // deepest
  let pick=cands.filter(e=>!cands.some(o=>o!==e&&e.contains(o)));
  if(f.row||f.outer) pick=cands.filter(e=>!cands.some(o=>o!==e&&o.contains(e)));
  const e=pick[Math.min(f.n||0,pick.length-1)];
  used.add(e); e.setAttribute('data-dyn',f.box?'box':'1');
  const g=rotAnc(e);
  let ang=0,gb=null;
  if(g){const m=getComputedStyle(g).transform.match(/matrix\(([^)]+)\)/)[1].split(',').map(parseFloat);ang=Math.atan2(m[1],m[0]);
    const old=g.style.transform;g.style.setProperty('transform','none','important');}
  const box=R(e);
  if(g){gb=R(g);}
  const par=e.parentElement;const pb=R(par);
  const cs=getComputedStyle(e);
  let anchor='l';
  const ta=cs.textAlign;
  if(ta==='center')anchor='c'; else if(ta==='right'||ta==='end')anchor='r';
  else{ // flex child pushed right
    const pcs=getComputedStyle(par);
    if((pcs.display.includes('flex')||pcs.display.includes('grid'))&&Math.abs(box[0]+box[2]-(pb[0]+pb[2]-parseFloat(pcs.paddingRight)))<2&&box[0]-pb[0]>40)anchor='r';
  }
  const o={key,box,ang,group:gb,anchor,segs:segs(e)};
  if(f.row){o.row={gap:parseFloat(cs.columnGap)||0,align:cs.alignItems,just:cs.justifyContent,kids:[...e.children].filter(vis).map(k=>({box:R(k),segs:segs(k).length?segs(k):[{t:k.innerText,...st(k)}],flex:getComputedStyle(k).flexGrow}))}}
  if(f.box){o.deco={bg:cs.backgroundColor,bw:parseFloat(cs.borderTopWidth),bc:cs.borderTopColor,rad:parseFloat(cs.borderTopLeftRadius),pad:[parseFloat(cs.paddingTop),parseFloat(cs.paddingRight),parseFloat(cs.paddingBottom),parseFloat(cs.paddingLeft)],sh:cs.boxShadow}}
  if(g){g.style.removeProperty('transform')}
  out.push(o);
}
return out}
