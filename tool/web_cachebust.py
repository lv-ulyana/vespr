"""Після `flutter build web`: main.dart.js → main.<хеш>.dart.js, щоб браузер не тримав стару версію (GitHub Pages кешує на 10 хв)."""
import hashlib, pathlib, re

web = pathlib.Path(__file__).resolve().parent.parent / 'build' / 'web'
js = web / 'main.dart.js'
h = hashlib.sha1(js.read_bytes()).hexdigest()[:10]
name = f'main.{h}.dart.js'
js.rename(web / name)
for f in ['flutter_bootstrap.js', 'index.html', 'flutter_service_worker.js']:
    p = web / f
    if p.exists():
        t = p.read_text(encoding='utf-8')
        p.write_text(t.replace('main.dart.js', name), encoding='utf-8')
b = (web / 'flutter_bootstrap.js').read_text(encoding='utf-8')
assert name in b, 'mainJsPath не знайдено у flutter_bootstrap.js'
# сам bootstrap теж підвантажуємо з версією
i = web / 'index.html'
t = i.read_text(encoding='utf-8')
t = re.sub(r'flutter_bootstrap\.js(\?v=\w+)?', f'flutter_bootstrap.js?v={h}', t)
i.write_text(t, encoding='utf-8')
print('web cache-bust:', name)
