import hashlib,os,re,glob
D='/home/claude/vespr/assets/wrapped'
fs=sorted(glob.glob(D+'/*.webp'))
# strip old suffix
for f in fs:
    m=re.match(r'(.*/s\d\d(?:_\d\d)?)\.[0-9a-f]{8}\.webp$',f)
    if m:
        if os.path.exists(m.group(1)+'.webp'): os.remove(f)
        else: os.rename(f,m.group(1)+'.webp')
fs=sorted(glob.glob(D+'/*.webp'))
h=hashlib.sha1(b''.join(open(f,'rb').read() for f in fs)).hexdigest()[:8]
for f in fs: os.rename(f,f[:-5]+'.'+h+'.webp')
L='/home/claude/vespr/lib/logic/wrapped_layers.dart'
s=open(L).read()
s=re.sub(r"\nconst wV = '[0-9a-f]+';.*?\n\n","\n",s,flags=re.S)
s=s.replace('\nclass WL',f"\nconst wV = '{h}';\n/// Шлях до файла шару з хешем (щоб браузер не тримав старі копії)\nString wAsset(String f) => 'assets/wrapped/${{f.replaceFirst('.webp', '.$wV.webp')}}';\n\nclass WL",1)
open(L,'w').write(s)
print(h,len(fs))
