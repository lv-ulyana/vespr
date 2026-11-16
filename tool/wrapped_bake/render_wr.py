import re, sys, pathlib, glob, os, json
sys.argv=[sys.argv[0]]+sys.argv[1:]
from playwright.sync_api import sync_playwright
P=pathlib.Path('/tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad')
exec(open(P/'render/render2.py').read().split('with sync_playwright()')[0].split("SRC = ")[0])
SHIM=re.search(r'SHIM = r"""(.*?)"""',open(P/'render/render2.py').read(),re.S).group(1)
FONTS=P/'fonts'
OUT=P/os.environ.get('OUTD','design/ref_wr'); OUT.mkdir(exist_ok=True)
src=(P/'vw/project'/os.environ.get('SRCF','Main.dc.html')).read_text()
for fpath in glob.glob(str(P/'vw/assets/*')):
    src=src.replace('/_blob/'+pathlib.Path(fpath).stem,'file://'+fpath)
xdc=re.search(r'<x-dc>(.*)</x-dc>',src,re.S).group(1)
helmet=re.search(r'<helmet>(.*?)</helmet>',xdc,re.S)
styles=''.join(re.findall(r'<style>(.*?)</style>',helmet.group(1),re.S))
links=''.join(re.findall(r'<link[^>]*>',helmet.group(1)))
body=xdc.replace(helmet.group(0),'')
code0=re.search(r'data-dc-script[^>]*>(.*?)</script>',src,re.S).group(1)
MODE=sys.argv[2] if len(sys.argv)>2 else 'shot'
import json as _js
HIDE={int(k):v for k,v in _js.load(open(str(P/'hide.json'))).items()} if (P/'hide.json').exists() else {}
DUMP=open(str(P/'render/dump.js')).read()
which=[int(x) for x in sys.argv[1].split(',')] if len(sys.argv)>1 else range(19)
with sync_playwright() as pw:
    b=pw.chromium.launch(); pg=b.new_page(viewport={'width':390,'height':844},device_scale_factor=(2 if MODE in ('bake','layers') else 1))
    for k in which:
        code=code0.replace('this.state = { i: 0','this.state = { i: %d'%k)
        if os.environ.get('UNSAFE'): code=code.replace('safe: true','safe: false')
        html=f"""<!doctype html><html><head><meta charset=utf-8>{links}<style>
{open(str(FONTS)+'/newfonts.css').read()}
@font-face{{font-family:'Prata';src:url('file://{FONTS}/Prata-Regular.ttf')}}
@font-face{{font-family:'Onest';src:url('file://{FONTS}/Onest.ttf');font-weight:100 900}}
@font-face{{font-family:'Oswald';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/Oswald-500.ttf');font-weight:500}}@font-face{{font-family:'Oswald';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/Oswald-600.ttf');font-weight:600}}@font-face{{font-family:'Oswald';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/Oswald-700.ttf');font-weight:700}}@font-face{{font-family:'Caveat';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/Caveat-600.ttf');font-weight:600}}@font-face{{font-family:'Caveat';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/Caveat-700.ttf');font-weight:700}}@font-face{{font-family:'IBM Plex Mono';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/PlexMono-400.ttf');font-weight:400}}@font-face{{font-family:'IBM Plex Mono';src:url('file:///tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/PlexMono-600.ttf');font-weight:600}}
{styles}</style><style id=kill>*{{animation-duration:0s!important;animation-delay:0s!important;transition:none!important}}</style><script>{SHIM}</script></head><body><div id=root></div></body></html>"""
        p=OUT/f'w{k}.html'; p.write_text(html)
        pg.goto(p.as_uri())
        if os.environ.get('MORE'): code=code.replace("safe: false }","safe: true }",1)
        pg.evaluate('([t,c])=>window.__run(t,c)',[body,code])
        pg.wait_for_timeout(500)
        if os.environ.get('MORE'):
            MM={int(a):int(b) for a,b in (x.split(':') for x in os.environ['MORE'].split(','))}
            pg.evaluate('''([j])=>{const els=[...document.querySelectorAll('.sl')];const keep=els[j];
              let r=keep.closest('.root')||document.getElementById('root').firstElementChild;
              const host=document.createElement('div');host.className=(r&&r.className)||'root';
              host.style.cssText='position:fixed;left:0;top:0;width:390px;height:844px;margin:0;padding:0;z-index:99999';
              host.appendChild(keep);document.body.innerHTML='';document.body.appendChild(host);document.body.style.margin='0';
              keep.style.margin='0';}''',[MM[k]])
            pg.wait_for_timeout(300)
            ED=json.load(open(str(P/'edits.json'))) if (P/'edits.json').exists() else {}
            if str(k) in ED: pg.evaluate(ED[str(k)]); pg.wait_for_timeout(300)
        import json
        if MODE=='shot': pg.screenshot(path=str(OUT/f'w{k:02d}.png'))
        if MODE=='all':
            pg.set_viewport_size({'width':1400,'height':900})
            pg.wait_for_timeout(800)
            els=pg.query_selector_all('.sl')
            for j,e in enumerate(els): e.screenshot(path=str(OUT/f'm{j:02d}.png'))
            print('slides',len(els))
            break
        if MODE=='live':
            # без «kill»: анімації йдуть по-справжньому, знімок через 4 с
            pg.evaluate("()=>document.getElementById('kill').remove()")
            pg.evaluate('([t,c])=>{document.getElementById("root").innerHTML="";window.__run(t,c)}',[body,code])
            pg.wait_for_timeout(4000)
            pg.screenshot(path=str(OUT/f'live{k:02d}.png'))
        if MODE=='tree': print('=== SLIDE',k); print(pg.evaluate(open(str(P/'render/tree.js')).read()))
        if MODE=='js':
            print('==',k, pg.evaluate(open(os.environ['JSF']).read()))
        if MODE=='krects':
            q=pg.evaluate('''()=>[...document.querySelectorAll('.sl .kcard,.sl .krow,.sl .kpill,.sl .kstamp,.sl .kx,.sl [class*=d15] ')].map(e=>{const r=e.getBoundingClientRect();const cs=getComputedStyle(e);return [e.className.toString().slice(0,20),Math.round(r.x),Math.round(r.y),Math.round(r.width),Math.round(r.height),cs.transform==='none'?'':cs.transform.slice(0,40),cs.backgroundColor,cs.borderRadius,(e.innerText||'').replace(/\s+/g,' ').slice(0,40)]})''')
            print('== ',k); [print(x) for x in q]
        if MODE=='rects':
            q=pg.evaluate("()=>{const o={};for(const s of ['.rgw','.rgc','.rbn','.seal2','.seal2 .core','.orb','.tkl','.bc2','.cal','.cg','.bign','.ntag','.rc4','.rc4c','.tkh','.tbc'])o[s]=[...document.querySelectorAll(s)].map(e=>{const r=e.getBoundingClientRect();return [Math.round(r.x),Math.round(r.y),Math.round(r.width),Math.round(r.height),getComputedStyle(e).transform]});return o}")
            print(k,{a:b for a,b in q.items() if b})
        if MODE=='layers':
            h=HIDE.get(k,'')
            pg.add_style_tag(content=(h[1:] if h.startswith('!') else h+' .top,.body,.prog,.ctl,.tap{visibility:hidden!important}'))
            pg.wait_for_timeout(150)
            info=pg.evaluate(open(str(P/'render/layers.js')).read())
            LD=P/'layers'; LD.mkdir(exist_ok=True)
            for j,L in enumerate(info):
                pg.evaluate('([j])=>{document.querySelectorAll("[data-l]").forEach(e=>e.removeAttribute("data-l"));window.__L[j].setAttribute("data-l","1")}',[j])
                css=pg.add_style_tag(content='.sl.sl.sl{background:transparent!important}html,body,#root,.root{background:transparent!important} .sl.sl::after,.sl.sl::before{display:none!important} .sl .body{display:none!important} .sl *:not([data-l]):not([data-l] *){visibility:hidden!important} [data-l]{visibility:visible!important} [data-inf],[data-inf] *{animation:none!important}')
                x,y,w,hh=L['clip']
                pg.screenshot(path=str(LD/f'l{k:02d}_{j:02d}.png'),clip={'x':x,'y':y,'width':w,'height':hh},omit_background=True)
                css.evaluate('e=>e.remove()')
                c2=pg.add_style_tag(content='.sl.sl::after,.sl.sl::before{display:none!important} [data-inf],[data-inf] *{animation:none!important}')
                pg.screenshot(path=str(LD/f'f{k:02d}_{j:02d}.png'),clip={'x':x,'y':y,'width':w,'height':hh})
                c3=pg.add_style_tag(content='[data-l]{visibility:hidden!important}')
                pg.screenshot(path=str(LD/f'g{k:02d}_{j:02d}.png'),clip={'x':x,'y':y,'width':w,'height':hh})
                c3.evaluate('e=>e.remove()'); c2.evaluate('e=>e.remove()')
            pg.evaluate('()=>document.querySelectorAll("[data-l]").forEach(e=>e.removeAttribute("data-l"))')
            css=pg.add_style_tag(content='.lyr{visibility:hidden!important}')
            pg.screenshot(path=str(LD/f'b{k:02d}.png'))
            (LD/f'm{k:02d}.json').write_text(json.dumps(info))
            print(k,len(info))
        if MODE=='anim':
            q=pg.evaluate(open(str(P/'render/anim.js')).read())
            (OUT/f'a{k:02d}.json').write_text(json.dumps(q))
            print(k,len(q),sorted(set(x['a'] for x in q)))
        if MODE=='dump':
            d=pg.evaluate(DUMP)
            (OUT/(('u' if os.environ.get('UNSAFE') else 'd')+f'{k:02d}.json')).write_text(json.dumps(d,ensure_ascii=False))
        if MODE=='bake':
            h=HIDE.get(k,'')
            pg.add_style_tag(content=h[1:] if h.startswith('!') else h+' .top,.body,.prog,.ctl,.tap{visibility:hidden!important}')
            pg.wait_for_timeout(200)
            pg.screenshot(path=str(OUT/f'b{k:02d}.png'))
    b.close()
