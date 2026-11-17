# Публічні сторінки політики приватності й умов (для App Store Connect) з lib/data/legal.dart.
# Англійська — з перекладів lib/l10n/en.dart. Запуск: python3 tool/legal_pages.py build/web
# → privacy.html, terms.html (англ.) і privacy-uk.html, terms-uk.html.
import re, sys, os, html
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'build/web')
src = open(os.path.join(ROOT, 'lib/data/legal.dart')).read()
en_src = open(os.path.join(ROOT, 'lib/l10n/en.dart')).read()

def un(s): return s.replace("\\'", "'").replace('\\$', '$').replace('\\n', '\n').replace('\\\\', '\\')
EN = {}
body = en_src.split('const enExact = <String, String>{')[1].split('\n};')[0]
for m in re.finditer(r"^  '((?:[^'\\]|\\.)*)': '((?:[^'\\]|\\.)*)',$", body, re.M): EN[un(m.group(1))] = un(m.group(2))

STR = r"'((?:[^'\\]|\\.)*)'"
def doc(name):
    block = src.split('const %s = LegalDoc(' % name)[1].split('\n);')[0]
    strs = lambda t: [un(x) for x in re.findall(STR, t)]
    head, rest = block.split('[', 1)
    title, updated = strs(head)
    tldr_part, rest = rest.split('],', 1)
    tldr = strs(tldr_part)
    secs = []
    for m in re.finditer(r"LegalSec\(" + STR + r", " + STR + r", \[(.*?)\]\)", rest, re.S):
        secs.append((un(m.group(1)), un(m.group(2)), strs(m.group(3))))
    return title, updated, tldr, secs

def tr(s, en):
    if not en: return s
    if s in EN: return EN[s]
    if s.startswith('• ') and s[2:] in EN: return '• ' + EN[s[2:]]
    return s

def fmt(s):
    # внутрішня примітка про можливий ШІ — не для публічної сторінки
    s = re.sub(r'\s*⟦\[(якщо додамо ШІ|if we add AI)[^⟧]*⟧', '', s)
    s = html.escape(s)
    return re.sub(r'⟦(.*?)⟧', r'<mark>\1</mark>', s)

CSS = '''body{margin:0;background:#16141c;color:#e6e2eb;font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
main{max-width:680px;margin:0 auto;padding:48px 22px 80px}h1{font:400 34px/1.15 Georgia,serif;margin:0 0 6px}
.up{color:#8f89a6;font-size:14px;margin-bottom:28px}.tl{background:#221f2b;border:1px solid #ffffff14;border-radius:18px;padding:18px 20px;margin-bottom:30px}
.tl b{color:#f0a48e;font-size:13px;letter-spacing:.04em}.tl li{margin:6px 0}h2{font-size:18px;font-weight:600;margin:30px 0 8px}
h2 span{color:#8f89a6;margin-right:10px}p{margin:0 0 10px}ul{margin:0 0 10px;padding-left:20px}a{color:#f0a48e}
mark{background:#f0a48e22;color:#f0a48e}nav{display:flex;gap:16px;font-size:14px;margin-bottom:30px}'''

def page(name, en, fname, other, links):
    title, updated, tldr, secs = doc(name)
    t = lambda s: tr(s, en)
    parts = [f'<!doctype html><html lang="{"en" if en else "uk"}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
             f'<title>{html.escape(t(title))} · Vespr</title><style>{CSS}</style></head><body><main>',
             '<nav>' + links + f'<a href="{other}">{"Українською" if en else "English"}</a></nav>',
             f'<h1>{html.escape(t(title))}</h1><div class="up">{html.escape(t(updated))}</div>',
             f'<div class="tl"><b>{"IN SHORT" if en else "КОРОТКО"}</b><ul>' + ''.join(f'<li>{fmt(t(x))}</li>' for x in tldr) + '</ul></div>']
    for n, h, blocks in secs:
        parts.append(f'<h2><span>{n}</span>{html.escape(t(h))}</h2>')
        ul = []
        for b in blocks:
            tb = t(b)
            if tb.startswith('• '): ul.append(f'<li>{fmt(tb[2:])}</li>'); continue
            if ul: parts.append('<ul>' + ''.join(ul) + '</ul>'); ul = []
            parts.append(f'<p>{fmt(tb)}</p>')
        if ul: parts.append('<ul>' + ''.join(ul) + '</ul>')
    parts.append('</main></body></html>')
    open(os.path.join(out, fname), 'w').write('\n'.join(parts))

os.makedirs(out, exist_ok=True)
for en in (True, False):
    sfx = '' if en else '-uk'
    links = (f'<a href="privacy{sfx}.html">{"Privacy" if en else "Приватність"}</a>'
             f'<a href="terms{sfx}.html">{"Terms of Use" if en else "Умови"}</a>')
    page('privacyDoc', en, f'privacy{sfx}.html', f'privacy{"-uk" if en else ""}.html', links)
    page('termsDoc', en, f'terms{sfx}.html', f'terms{"-uk" if en else ""}.html', links)
print('ok', out)
