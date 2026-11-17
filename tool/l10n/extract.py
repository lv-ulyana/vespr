# Витягує всі українські рядки з lib/**/*.dart, інтерполяції -> {0},{1}...
import re, glob, json, sys, os
CYR = re.compile('[А-Яа-яІіЇїЄєҐґ]')

def lex(src):
    """Повертає список (start, end, template, raw) для кожного рядкового літерала верхнього рівня і вкладених."""
    out = []
    i = 0; n = len(src)
    def read_string(i):
        # i на початку літерала (можливо з r)
        raw = False
        if src[i] == 'r': raw = True; i += 1
        q = src[i]
        triple = src[i:i+3] in ("'''", '"""')
        delim = src[i:i+3] if triple else q
        i += len(delim)
        parts = []; buf = ''; args = []
        while i < n:
            if src.startswith(delim, i):
                i += len(delim); break
            c = src[i]
            if not raw and c == '\\':
                nxt = src[i+1]
                buf += {'n': '\n', 't': '\t', "'": "'", '"': '"', '\\': '\\', '$': '$'}.get(nxt, '\\' + nxt)
                i += 2; continue
            if not raw and c == '$':
                if src[i+1] == '{':
                    # знайти кінець ${...} з урахуванням вкладених рядків
                    j = i + 2; depth = 1; start = j
                    while depth:
                        ch = src[j]
                        if ch in '\'"' or (ch == 'r' and src[j+1:j+2] in ('\'','"') and not src[j-1].isalnum()):
                            j = read_string(j)[0]; continue
                        if ch == '{': depth += 1
                        elif ch == '}': depth -= 1
                        j += 1
                    expr = src[start:j-1]
                    buf += '{%d}' % len(args); args.append(expr)
                    i = j; continue
                m = re.match(r'\$([A-Za-z_][A-Za-z0-9_]*)', src[i:])
                if m:
                    buf += '{%d}' % len(args); args.append(m.group(1)); i += len(m.group(0)); continue
            if not triple and c == '\n': break
            buf += c; i += 1
        return i, buf, args
    while i < n:
        c = src[i]
        if src.startswith('//', i):
            j = src.find('\n', i); i = n if j < 0 else j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i); i = n if j < 0 else j + 2; continue
        if c in '\'"' or (c == 'r' and src[i+1:i+2] in ('\'','"') and (i == 0 or not (src[i-1].isalnum() or src[i-1] == '_'))):
            s = i
            e, t, args = read_string(i)
            out.append((s, e, t, args))
            i = e; continue
        i += 1
    return out

if __name__ == '__main__':
    root = sys.argv[1]
    keys = {}
    for f in sorted(glob.glob(root + '/lib/**/*.dart', recursive=True)):
        if 'wrapped_layers' in f or '/l10n/' in f: continue
        src = open(f).read()
        lits = lex(src)
        # склеїти сусідні літерали 'a' 'b'
        merged = []
        for s, e, t, a in lits:
            if merged and re.fullmatch(r'\s*', src[merged[-1][1]:s]) and not merged[-1][3] and not a:
                ps, pe, pt, pa = merged[-1]; merged[-1] = (ps, e, pt + t, pa)
            else:
                merged.append((s, e, t, a))
        for s, e, t, a in merged:
            if CYR.search(t):
                rel = os.path.relpath(f, root)
                keys.setdefault(t, []).append(rel)
        # вкладені літерали всередині ${} теж
        for s, e, t, a in lits:
            for expr in a:
                for s2, e2, t2, a2 in lex(expr):
                    if CYR.search(t2): keys.setdefault(t2, []).append(os.path.relpath(f, root))
    json.dump(keys, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'keys.json'), 'w'), ensure_ascii=False, indent=0)
    print(len(keys), 'unique keys')
