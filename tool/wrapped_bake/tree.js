()=>{const out=[];const R=e=>{const r=e.getBoundingClientRect();return [Math.round(r.x),Math.round(r.y),Math.round(r.width),Math.round(r.height)]};
function walk(e,d){if(d>5)return;const cs=getComputedStyle(e);if(cs.display==='none')return;let own='';for(const c of e.childNodes)if(c.nodeType===3)own+=c.textContent;own=own.replace(/\s+/g,' ').trim();
const tag=e.tagName.toLowerCase();if(e.closest('.body')||e.closest('.prog')||e.closest('.ctl')||e.closest('.tap'))return;
let s=' '.repeat(d)+tag+'.'+(e.getAttribute('class')||'').replace(/ /g,'.')+' '+JSON.stringify(R(e));
if(own)s+=' "'+own.slice(0,50)+'" '+cs.fontFamily.split(',')[0]+' '+cs.fontWeight+' '+cs.fontSize+(cs.fontStyle!=='normal'?' i':'')+' '+cs.color;
if(cs.backgroundColor!=='rgba(0, 0, 0, 0)')s+=' bg='+cs.backgroundColor;if(cs.transform!=='none')s+=' tf='+cs.transform;if(cs.borderRadius!=='0px')s+=' rad='+cs.borderRadius;if(cs.animationName!=='none')s+=' anim='+cs.animationName;if(cs.visibility==='hidden')s+=' HIDDEN';
if(tag==='img')s+=' src='+(e.getAttribute('src')||'').split('/').pop().slice(0,10);
out.push(s);if(tag==='svg')return;for(const c of e.children)walk(c,d+1)}
walk(document.querySelector('.sl'),0);return out.join('\n')}
