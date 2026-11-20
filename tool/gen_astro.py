# Генерує тексти знаків і арканів для апки з tool/astro_src/*.py (там укр + англ поруч):
#   lib/logic/arcana_more.dart   — «Мій аркан»: плюс, мінус, кохання, у ліжку
#   lib/logic/match_texts.dart   — «Ваш метч»: аркан пари, «він у ліжку», стихії, аспекти
#   lib/logic/sign_texts.dart    — знаки: суть, кохання, ліжко, тінь
#   tool/l10n/t/astro_long.py    — англійські переклади всього цього
# Запуск: python3 tool/gen_astro.py && python3 tool/l10n/build_en.py
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(HERE, 'astro_src'))
from signs import SIGNS
from zodiac_pairs import ASPECTS, ELEMENTS
from arcana import ARCANA, BED

T = {}
def uk(pair):
    u, e = pair
    assert u.strip() and e.strip(), pair
    assert u.count('*') == e.count('*') and u.count('*') % 2 == 0, pair
    T[u] = e
    return u
def q(s): return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"

GEN = '// Згенеровано tool/gen_astro.py з tool/astro_src/*.py — не правити вручну, правити там.\n'

# ---------- аркан людини: «Мій аркан»
assert sorted(ARCANA) == list(range(1, 23))
lines = [GEN, '// Тексти для екрана «Мій аркан»: плюс, мінус, кохання і «у ліжку» для кожного з 22 арканів.',
         '// Це гра, а не наука: класичні значення карт, трохи романтизовані.', '',
         'class ArcanaMore {', '  final String plus, minus, bed, love;', '  const ArcanaMore(this.plus, this.minus, this.bed, this.love);', '}', '',
         'const arcanaMore = <ArcanaMore>[', "  ArcanaMore('', '', '', ''),"]
for i in range(1, 23):
    a = ARCANA[i]
    lines.append('  ArcanaMore(%s, %s, %s, %s),' % (q(uk(a['plus'])), q(uk(a['minus'])), q(uk(a['bed'])), q(uk(a['love']))))
lines.append('];\n')
open(os.path.join(ROOT, 'lib/logic/arcana_more.dart'), 'w').write('\n'.join(lines))

# ---------- метч
QLABEL = {
    'sx_overall': 'Як загалом', 'sx_pleasure': 'Наскільки тобі було добре', 'sx_care': 'Наскільки дбали про тебе',
    'sx_heard': 'Наскільки тебе почули', 'sx_pace': 'Наскільки підходив темп', 'sx_finish': 'Наскільки ти задоволена фіналом',
    'sx_fore': 'Наскільки вистачало прелюдії',
}
EL_ORDER = ['Вогонь', 'Земля', 'Повітря', 'Вода']
assert len(ELEMENTS) == 10
el_map = {}
for (a, b), txt in ELEMENTS.items():
    k = '+'.join(sorted([a, b]))  # як у Dart: ([a, b]..sort()).join('+') — порівняння по кодах символів
    assert k not in el_map, k
    el_map[k] = uk(txt)
for a in EL_ORDER:
    for b in EL_ORDER:
        assert '+'.join(sorted([a, b])) in el_map, (a, b)
assert len(ASPECTS) == 7

m = [GEN, '// Тексти для екрана «Ваш метч»: аркан пари, «він у ліжку», стихії й аспекти знаків.',
     '// Це гра, а не наука. *…* — акцент (виділяється кольором).', '',
     'class PairText {', '  final String rel, sex, risk;', '  const PairText(this.rel, this.sex, this.risk);', '}', '',
     '/// Аркан пари → стосунки, секс, ризик', 'const pairTexts = <PairText>[', "  PairText('', '', ''),"]
for i in range(1, 23):
    a = ARCANA[i]
    m.append('  PairText(%s, %s, %s),' % (q(uk(a['rel'])), q(uk(a['sex'])), q(uk(a['risk']))))
m += ['];', '', '/// Аркани пари з позначкою «Легко» (решта — «Складніше»)', 'const easyArcana = {3, 6, 10, 11, 14, 17, 19, 21};', '',
      '/// Аркан людини → «він у ліжку» і питання із записів, яким це перевіряємо.',
      '/// Питання — лише ті, що в записі завжди або увімкнені за замовчуванням; [fallback] — завжди наявне запасне.',
      'class BedClaim {', '  final String claim, q, qLabel;', "  const BedClaim(this.claim, this.q, this.qLabel);",
      "  static const fallback = 'sx_pleasure', fallbackLabel = 'Наскільки тобі було добре';", '}', '',
      'const bedClaims = <BedClaim>[', "  BedClaim('', '', ''),"]
for i in range(1, 23):
    u, e, qq = BED[i]
    T[u] = e
    m.append('  BedClaim(%s, %s, %s),' % (q(u), q(qq), q(QLABEL[qq])))
m += ['];', '',
      '/// Пара стихій → порада', 'String elementsText(String a, String b) {', "  final k = ([a, b]..sort()).join('+');", '  return const {']
for k, v in el_map.items():
    m.append('    %s: %s,' % (q(k), q(v)))
m += ["  }[k] ??", "      '';", '}', '',
      '/// Аспект двох знаків: відстань на зодіакальному колі 0–6',
      'class Aspect {', '  final String name, rel, sex, risk;', '  final bool easy;', '  const Aspect(this.name, this.easy, this.rel, this.sex, this.risk);', '}', '',
      'int aspectDistance(int a, int b) {', '  final d = (a - b).abs() % 12;', '  return d > 6 ? 12 - d : d;', '}', '',
      'const aspects = <Aspect>[']
for a in ASPECTS:
    m.append('  Aspect(%s, %s, %s, %s, %s),' % (q(uk(a['name'])), 'true' if a['easy'] else 'false', q(uk(a['rel'])), q(uk(a['sex'])), q(uk(a['risk']))))
m += ['];', '', 'Aspect aspectOf(int a, int b) => aspects[aspectDistance(a, b)];', '']
open(os.path.join(ROOT, 'lib/logic/match_texts.dart'), 'w').write('\n'.join(m))

# ---------- знаки
assert len(SIGNS) == 12
s = [GEN, '// Знаки зодіаку: суть, кохання, у ліжку і тінь. Порядок — як у [signs] (astro.dart).', '',
     'class SignText {', '  final String core, love, bed, shadow;', '  const SignText(this.core, this.love, this.bed, this.shadow);', '}', '',
     'const signTexts = <SignText>[']
for x in SIGNS:
    s.append('  SignText(%s, %s, %s, %s),' % (q(uk(x['core'])), q(uk(x['love'])), q(uk(x['bed'])), q(uk(x['shadow']))))
s.append('];\n')
open(os.path.join(ROOT, 'lib/logic/sign_texts.dart'), 'w').write('\n'.join(s))

# ---------- переклади
out = ['# Згенеровано tool/gen_astro.py — не правити вручну, правити tool/astro_src/*.py', 'T = {']
for k, v in T.items():
    out.append('  %r: %r,' % (k, v))
out.append('}\n')
open(os.path.join(ROOT, 'tool/l10n/t/astro_long.py'), 'w').write('\n'.join(out))
print('ok:', len(T), 'текстів')
