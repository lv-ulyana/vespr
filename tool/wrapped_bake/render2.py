import re, sys, json, pathlib
from playwright.sync_api import sync_playwright

SRC = pathlib.Path(sys.argv[1])
OUT = pathlib.Path(sys.argv[2]); OUT.mkdir(parents=True, exist_ok=True)
FONTS = pathlib.Path(sys.argv[3])
names = sys.argv[4].split(',')

SHIM = r"""
class DCLogic{constructor(p){this.props=p||{};this.state={}}setState(s){Object.assign(this.state,s)}forceUpdate(){}}
function get(p,sc){p=p.trim();if(p==='true')return true;if(p==='false')return false;if(/^-?\d/.test(p))return +p;return p.split('.').reduce((o,k)=>o==null?undefined:o[k],sc)}
function interp(s,sc){return s.replace(/\{\{([^}]+)\}\}/g,(_,p)=>{const v=get(p,sc);return v==null?'':String(v)})}
function whole(s){const m=s.match(/^\s*\{\{([^}]+)\}\}\s*$/);return m?m[1]:null}
function render(node,sc,parent){
 for(const ch of node.childNodes){
  if(ch.nodeType===3){parent.appendChild(document.createTextNode(interp(ch.textContent,sc)));continue}
  if(ch.nodeType!==1)continue;
  const tag=ch.tagName.toLowerCase();
  if(tag==='sc-for'){const list=get(whole(ch.getAttribute('list')),sc)||[];const as=ch.getAttribute('as');list.forEach((it,i)=>render(ch,{...sc,[as]:it,$index:i},parent));continue}
  if(tag==='sc-if'){if(get(whole(ch.getAttribute('value')),sc))render(ch,sc,parent);continue}
  const el=document.createElement(tag==='svg'||ch.namespaceURI.includes('svg')?tag:tag);
  let e=ch.namespaceURI==='http://www.w3.org/2000/svg'?document.createElementNS(ch.namespaceURI,ch.tagName):document.createElement(tag);
  for(const a of ch.attributes){if(/^on[A-Z]/.test(a.name))continue;const w=whole(a.value);
    if(w!==null){const v=get(w,sc);if(v===false||v==null){continue}e.setAttribute(a.name,v===true?'':String(v))}else e.setAttribute(a.name,interp(a.value,sc))}
  parent.appendChild(e);render(ch.content||ch,sc,e)
 }
}
window.__run=function(tpl,code){const Component=new Function('DCLogic',code+';return Component')(DCLogic);const c=new Component({});const v=c.renderVals();const t=document.createElement('template');t.innerHTML=tpl;render(t.content,v,document.getElementById('root'))}
"""

with sync_playwright() as pw:
    b = pw.chromium.launch()
    pg = b.new_page(viewport={'width': 390, 'height': 844}, device_scale_factor=2)
    for n in names:
        src = (SRC / f'{n}.dc.html').read_text()
        A = SRC.parent / 'assets'
        import glob
        for fpath in glob.glob(str(A / '*')):
            bid = pathlib.Path(fpath).stem
            src = src.replace('/_blob/' + bid, 'file://' + fpath)
        xdc = re.search(r'<x-dc>(.*)</x-dc>', src, re.S).group(1)
        helmet = re.search(r'<helmet>(.*?)</helmet>', xdc, re.S)
        styles = ''.join(re.findall(r'<style>(.*?)</style>', helmet.group(1), re.S)) if helmet else ''
        body = xdc.replace(helmet.group(0), '') if helmet else xdc
        code = re.search(r'data-dc-script[^>]*>(.*?)</script>', src, re.S).group(1)
        html = f"""<!doctype html><html><head><meta charset=utf-8><style>
{open(str(FONTS)+'/newfonts.css').read()}
@font-face{{font-family:'Prata';src:url('file://{FONTS}/Prata-Regular.ttf')}}
@font-face{{font-family:'Onest';src:url('file://{FONTS}/Onest.ttf');font-weight:100 900}}
*{{animation:none!important}}
{styles}</style><script>{SHIM}</script></head><body><div id=root></div></body></html>"""
        p = OUT / f'{n}.html'; p.write_text(html)
        pg.goto(p.as_uri())
        pg.evaluate('([t,c])=>window.__run(t,c)', [body, code])
        pg.wait_for_timeout(300)
        pg.screenshot(path=str(OUT / f'{n}.png'), full_page=True)
        import json as _j
        r=pg.evaluate("()=>[...document.querySelectorAll('span.n')].map(s=>{const e=s.nextElementSibling;if(!e)return null;const r=e.getBoundingClientRect();return [s.textContent.trim(),r.x+scrollX,r.y+scrollY,r.width,r.height]}).filter(Boolean)")
        (OUT / f'{n}.rects.json').write_text(_j.dumps(r,ensure_ascii=False))
    b.close()
print('ok')
