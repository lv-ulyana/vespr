(m)=>{const keys=Object.keys(m).sort((a,b)=>b.length-a.length);
const w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let n;const ns=[];while(n=w.nextNode())ns.push(n);
for(const n of ns){let t=n.textContent;const tt=t.trim();if(!tt)continue;
 if(m[t]!==undefined){n.textContent=m[t];continue}
 if(m[tt]!==undefined){n.textContent=t.replace(tt,m[tt]);continue}
 if(!/✦/.test(t))continue;
 for(const k of keys){t=t.split(k).join(m[k])}n.textContent=t}
return true}
