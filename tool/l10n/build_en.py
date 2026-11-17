# Збирає lib/l10n/en.dart з файлів перекладу work/l10n/t/*.py (у кожному словник T = {uk: en})
import glob, re, json, runpy, sys, os
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, '../..'))
exact, tpl, words = {}, {}, {}
for f in sorted(glob.glob(os.path.join(HERE, 't/*.py'))):
    d = runpy.run_path(f, init_globals={'ROOT': ROOT})
    for k, v in d.get('T', {}).items():
        (tpl if re.search(r'\{\d+\}', k) else exact)[k] = v
    words.update(d.get('W', {}))
# пункти списків у документах показуються без «• » — додаємо й такі ключі
# «звіт про|виживання» показується двома шматками — додаємо й шматки
for k, v in list(exact.items()):
    if '|' in k and k.count('|') == v.count('|'):
        for a, b in zip(k.split('|'), v.split('|')): exact.setdefault(a, b)
for k, v in list(exact.items()):
    if k.startswith('• ') and v.startswith('• '): exact.setdefault(k[2:], v[2:])
def q(s): return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n') + "'"
out = ['// Згенеровано tool/l10n/build_en.py — не правити вручну, правити переклади в tool/l10n/t/*.py', '// ignore_for_file: lines_longer_than_80_chars', '']
for name, d in (('enExact', exact), ('enTpl', tpl), ('enWords', words)):
    out.append('const %s = <String, String>{' % name)
    for k in sorted(d): out.append('  %s: %s,' % (q(k), q(d[k])))
    out.append('};\n')
open(os.path.join(ROOT, 'lib/l10n/en.dart'), 'w').write('\n'.join(out))
print(len(exact), len(tpl), len(words))
