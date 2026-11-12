"""Після `flutter create . --platforms=web`: назва, кольори і поведінка «як апка» на айфоні."""
import json, pathlib, re

web = pathlib.Path(__file__).resolve().parent.parent / 'web'

m = json.loads((web / 'manifest.json').read_text(encoding='utf-8'))
m.update({
    'name': 'Vespr',
    'short_name': 'Vespr',
    'description': 'Приватний щоденник побачень',
    'background_color': '#17161F',
    'theme_color': '#17161F',
    'display': 'standalone',
    'orientation': 'portrait',
    'lang': 'uk',
})
(web / 'manifest.json').write_text(json.dumps(m, ensure_ascii=False, indent=2), encoding='utf-8')

html = (web / 'index.html').read_text(encoding='utf-8')
html = html.replace('<html>', '<html lang="uk">')
html = re.sub(r'<title>.*?</title>', '<title>Vespr</title>', html, flags=re.S)
html = re.sub(r'<meta name="apple-mobile-web-app-title" content="[^"]*">', '<meta name="apple-mobile-web-app-title" content="Vespr">', html)
html = html.replace('content="black"', 'content="black-translucent"')
extra = ('<meta name="theme-color" content="#17161F">\n'
         '  <meta name="robots" content="noindex">\n'
         '  <style>html,body{background:#17161F}</style>\n')
html = html.replace('</head>', '  ' + extra + '</head>')
(web / 'index.html').write_text(html, encoding='utf-8')
print('web: Vespr ✓')
