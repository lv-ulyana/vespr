# Англійські варіанти запечених шарів Wrapped (там, де в макеті є текст).
# 1) render_wr.py з ENMAP=en_map.json LAYD=<dir> ... layers  для слайдів зі списку нижче
# 2) python3 conv_en.py <dir>   → assets/wrapped_en/*.webp + lib/logic/wrapped_layers_en.dart
import json, os, glob, sys, hashlib
import numpy as np
from PIL import Image, ImageFilter
U = '/tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/layers/'
E = sys.argv[1].rstrip('/') + '/'
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
A = ROOT + '/assets/wrapped_en/'
os.makedirs(A, exist_ok=True)
for f in glob.glob(A + '*'): os.remove(f)
SL = [1, 6, 8, 10, 11, 14, 26, 33]
def arr(p): return np.asarray(Image.open(p).convert('RGBA'), dtype=np.int16)
def diff(a, b):
    x, y = arr(a), arr(b)
    return x.shape != y.shape or np.abs(x - y).mean() > .05
def occ(im, L, k, j):
    try:
        F = np.asarray(Image.open(L + f'f{k:02d}_{j:02d}.png').convert('RGB'), dtype=np.int16)
        G = np.asarray(Image.open(L + f'g{k:02d}_{j:02d}.png').convert('RGB'), dtype=np.int16)
    except FileNotFoundError: return im
    m = Image.fromarray(((np.abs(F - G).sum(-1) > 10) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1))
    a = np.asarray(im).copy(); a[..., 3] = (a[..., 3].astype(np.uint16) * np.asarray(m) // 255).astype(np.uint8)
    return Image.fromarray(a)
bases, dart = [], []
for k in SL:
    if diff(U + f'b{k:02d}.png', E + f'b{k:02d}.png'):
        Image.open(E + f'b{k:02d}.png').convert('RGB').save(A + f's{k:02d}.webp', 'WEBP', quality=82, method=4); bases.append(k)
    rows = []
    for j, x in enumerate(json.load(open(E + f'm{k:02d}.json'))):
        changed = diff(U + f'l{k:02d}_{j:02d}.png', E + f'l{k:02d}_{j:02d}.png')
        L = E if changed else U
        im = occ(Image.open(L + f'l{k:02d}_{j:02d}.png').convert('RGBA'), L, k, j)
        bb = im.getbbox()
        if not bb: continue
        fn = f's{k:02d}_{j:02d}.webp'
        if changed: im.crop(bb).save(A + fn, 'WEBP', quality=85, method=4)
        lx = x['clip'][0] + bb[0] / 2; ly = x['clip'][1] + bb[1] / 2; w = (bb[2] - bb[0]) / 2; h = (bb[3] - bb[1]) / 2
        b = x['box']; ocx = b[0] + b[2] / 2; ocy = b[1] + b[3] / 2
        if 'rays' in x['cls']: ocx, ocy = 195, 190
        rows.append(f"WL('{'en:' if changed else ''}{fn}', {lx:.1f}, {ly:.1f}, {w:.1f}, {h:.1f}, '{x['a']}', {int(x['d']*1000)}, {int(x['dur']*1000)}, {str(x['it']=='infinite').lower()}, {ocx:.1f}, {ocy:.1f})")
    dart.append(f"  {k}: [\n    " + ",\n    ".join(rows) + ",\n  ],")
fs = sorted(glob.glob(A + '*.webp'))
h = hashlib.sha1(b''.join(open(f, 'rb').read() for f in fs)).hexdigest()[:8]
for f in fs: os.rename(f, f[:-5] + '.' + h + '.webp')
open(ROOT + '/lib/logic/wrapped_layers_en.dart', 'w').write(
    "// Згенеровано tool/wrapped_bake/conv_en.py: англійські варіанти шарів із текстом у макеті.\n"
    "// Файл з префіксом en: лежить в assets/wrapped_en/, решта — спільні з українською.\n"
    "import 'wrapped_layers.dart';\n\n"
    f"const wVEn = '{h}';\n"
    f"const wBaseEn = <int>{{{', '.join(map(str, bases))}}};\n\n"
    "const wLayersEn = <int, List<WL>>{\n" + "\n".join(dart) + "\n};\n")
print(h, len(fs), 'bases', bases, sum(os.path.getsize(f) for f in glob.glob(A + '*')) // 1024, 'KB')
