import json,os,glob
from PIL import Image
L='/tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/layers/'
A='/home/claude/vespr/assets/wrapped/'
for f in glob.glob(A+'*'): os.remove(f)
tot=0; dart=[]
import numpy as np
from PIL import ImageFilter
def occ(im,k,j):
  # прибрати частини шару, які в макеті перекриті іншими елементами
  try:
    F=np.asarray(Image.open(L+f'f{k:02d}_{j:02d}.png').convert('RGB'),dtype=np.int16)
    G=np.asarray(Image.open(L+f'g{k:02d}_{j:02d}.png').convert('RGB'),dtype=np.int16)
  except FileNotFoundError: return im
  d=np.abs(F-G).sum(-1)
  m=Image.fromarray(((d>10)*255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1))
  a=np.asarray(im).copy(); a[...,3]=(a[...,3].astype(np.uint16)*np.asarray(m)//255).astype(np.uint8)
  return Image.fromarray(a)

for k in range(48):
  im=Image.open(L+f'b{k:02d}.png').convert('RGB'); im.save(A+f's{k:02d}.webp','WEBP',quality=82,method=4); tot+=os.path.getsize(A+f's{k:02d}.webp')
  m=json.load(open(L+f'm{k:02d}.json')); rows=[]
  for j,x in enumerate(m):
    im=Image.open(L+f'l{k:02d}_{j:02d}.png').convert('RGBA')
    im=occ(im,k,j)
    bb=im.getbbox()
    if not bb: continue
    im=im.crop(bb)
    lx=x['clip'][0]+bb[0]/2; ly=x['clip'][1]+bb[1]/2; w=(bb[2]-bb[0])/2; h=(bb[3]-bb[1])/2
    fn=f's{k:02d}_{j:02d}.webp'; im.save(A+fn,'WEBP',quality=85,method=4); tot+=os.path.getsize(A+fn)
    b=x['box']; ocx=b[0]+b[2]/2; ocy=b[1]+b[3]/2
    if 'rays' in x['cls']: ocx,ocy=195,190
    inf = x['it']=='infinite'
    rows.append(f"WL('{fn}', {lx:.1f}, {ly:.1f}, {w:.1f}, {h:.1f}, '{x['a']}', {int(x['d']*1000)}, {int(x['dur']*1000)}, {str(inf).lower()}, {ocx:.1f}, {ocy:.1f})")
  dart.append(f"  {k}: [\n    "+",\n    ".join(rows)+(",\n  ]," if rows else "\n  ],"))
src=open('/home/claude/vespr/lib/logic/wrapped_layers.dart').read()
head=src[:src.index('const wLayers')]
open('/home/claude/vespr/lib/logic/wrapped_layers.dart','w').write(head+"const wLayers = <int, List<WL>>{\n"+"\n".join(dart)+"\n};\n")
# local composite check of slides 0,1,8 
for k in range(48):
  base=Image.open(L+f'b{k:02d}.png').convert('RGBA')
  for j,x in enumerate(json.load(open(L+f'm{k:02d}.json'))):
    im=occ(Image.open(L+f'l{k:02d}_{j:02d}.png').convert('RGBA'),k,j); c=x['clip']
    base.alpha_composite(im,(c[0]*2,c[1]*2))
  base.convert('RGB').resize((390,844)).save(f'/tmp/claude-0/-home-claude/ba59a111-bf62-5732-90c1-cf4079a7e5dd/scratchpad/comp{k:02d}.png')
print('DONE',tot//1024,'KB')

import subprocess;subprocess.run(['python3','rehash.py'])
