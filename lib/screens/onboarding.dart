// Онбординг один в один з дошками «1. Онбординг»: Main → 6 гайдів → Birthdate → Setup → PinNew → AddPerson.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go, goReplace;
import 'pin_screens.dart';
import 'settings.dart' show PaywallScreen;

/// Завершення онбордингу: позначаємо і повертаємось на корінь (там уже головна)
Future<void> finishOnboarding(BuildContext context) async {
  await Store.read(context).updateProfile((p) => p.onboarded = true);
  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = maskDate(newValue.text);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

final dateFormatter = _DateFormatter();

// =====================================================================
// Main: привітання
// =====================================================================
class Welcome extends StatefulWidget {
  const Welcome({super.key});
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  bool adult = true;
  String lang = 'uk';
  late final breathe = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    breathe.dispose();
    super.dispose();
  }

  Widget _pill(String id, String label) {
    final on = lang == id;
    return Press(
      onTap: () {
        setState(() => lang = id);
        if (id == 'en') dToast(context, 'Англійська буде пізніше, поки українською');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: easeD,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: on ? K.star : K.w(.03), border: Border.all(color: on ? K.star : K.w(.1))),
        child: Text(label, style: rw(13, color: on ? K.bg : K.muted, w: FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DFrame(
        builder: (context, h) => Stack(children: [
          // .halo: дихає 5 c
          Positioned(
            left: -60, top: 120,
            child: AnimatedBuilder(
              animation: breathe,
              builder: (_, child) {
                final t = (1 - math.cos(breathe.value * 2 * math.pi)) / 2;
                return Opacity(opacity: .75 + .25 * t, child: Transform.scale(scale: 1 + .06 * t, child: child));
              },
              child: Glow(w: 510, h: 510, circle: true, colors: [K.a(.30), const Color(0x1A8C86A3), const Color(0x0017161F)], stops: const [0, .38, .68]),
            ),
          ),
          starDot(62, 150, 2, K.star, .6),
          starDot(318, 118, 3, K.star, .5),
          starDot(290, 300, 2, K.star, .4),
          starDot(44, 420, 2, K.star, .35),
          starDot(340, 470, 2, K.haze, .8),
          Positioned(
            left: 40, right: 40, top: 250,
            child: Rise(
              child: Column(children: [
                Image.asset('assets/img/logo.webp', width: 262, semanticLabel: 'Vespr'),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text('Щоденник побачень, який з кожним записом краще знає, що тобі подобається.', style: rw(16, color: K.soft, h: 1.5), textAlign: TextAlign.center),
                ),
              ]),
            ),
          ),
          Positioned(
            left: 16, right: 16, bottom: 24,
            child: Rise(
              delay: .15,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xB82B2836),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: K.w(.08)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Text('Мова', style: rw(13, color: K.muted)),
                    const Spacer(),
                    _pill('uk', 'Українська'),
                    const SizedBox(width: 8),
                    _pill('en', 'English'),
                  ]),
                  const SizedBox(height: 20),
                  Press(
                    scale: 1,
                    onTap: () => setState(() => adult = !adult),
                    child: Semantics(
                      checked: adult,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Ck(adult),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text.rich(
                            TextSpan(text: 'Мені є 18 років\n', children: [TextSpan(text: 'Тут відверто про секс і стосунки.', style: rw(14, color: K.muted, h: 1.45))]),
                            style: rw(14, h: 1.45),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Cta('Почати', onTap: adult
                      ? () {
                          Store.read(context).updateProfile((p) => p.lang = lang);
                          go(context, const GuideScreen());
                        }
                      : null),
                ]),
              ),
            ),
          ),
        ]),
      );
}

// =====================================================================
// Гайд: 6 історій
// =====================================================================
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});
  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> with SingleTickerProviderStateMixin {
  final pc = PageController();
  int page = 0;
  late final fill = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    pc.dispose();
    fill.dispose();
    super.dispose();
  }

  void _toBirth() => goReplace(context, const AboutYou());
  void _go(int i) => pc.animateToPage(i, duration: const Duration(milliseconds: 500), curve: easeD);

  static const _chips = [('Голос', 0), ('Записи', 1), ('Мапа', 2), ('Люди', 3), ('Зірки', 4), ('Приватність', 5)];

  @override
  Widget build(BuildContext context) => DFrame(
        builder: (context, h) => Stack(children: [
          PageView(
            controller: pc,
            onPageChanged: (i) => setState(() {
              page = i;
              fill.forward(from: 0);
            }),
            children: const [_GVoice(), _GRate(), _GMap(), _GCompare(), _GStars(), _GPrivate()],
          ),
          // верх: «1 з 6», сегменти, «Пропустити»
          Positioned(
            left: 20, right: 20, top: 50,
            child: Row(children: [
              SizedBox(width: 34, child: Text('${page + 1} з 6', style: rw(12, color: K.muted2, w: FontWeight.w600))),
              const SizedBox(width: 14),
              Expanded(
                child: Row(children: gapped([
                  for (var i = 0; i < 6; i++)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 4,
                          color: i < page ? K.acc : K.hour,
                          alignment: Alignment.centerLeft,
                          child: i == page
                              ? AnimatedBuilder(animation: fill, builder: (_, __) => FractionallySizedBox(widthFactor: fill.value, child: Container(color: K.acc)))
                              : null,
                        ),
                      ),
                    ),
                ], 5, horizontal: true)),
              ),
              const SizedBox(width: 14),
              page < 5
                  ? Press(onTap: _toBirth, child: SizedBox(height: 44, child: Center(child: Text('Пропустити', style: rw(14, color: K.soft, w: FontWeight.w600)))))
                  : const SizedBox(width: 88, height: 44),
            ]),
          ),
          // низ: чип, заголовок, текст
          Positioned(
            left: 24, right: 24, bottom: 104,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: KeyedSubtree(key: ValueKey(page), child: _GText(page)),
            ),
          ),
          Positioned(
            left: 20, right: 20, bottom: 28,
            child: Row(children: [
              if (page > 0) ...[
                Press(
                  onTap: () => _go(page - 1),
                  label: 'Назад',
                  child: Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.hour), alignment: Alignment.center, child: Ico(Svgs.arrowL, size: 18)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: Cta(page == 5 ? 'Почати' : 'Далі', arrow: page < 5, weight: FontWeight.w700, onTap: page == 5 ? _toBirth : () => _go(page + 1))),
            ]),
          ),
        ]),
      );
}

class _GText extends StatelessWidget {
  final int i;
  const _GText(this.i);

  static final _icons = [Svgs.mic, Svgs.star4, Svgs.trend, Svgs.people, Svgs.star4, Svgs.lock];
  static const _labels = ['Голос', 'Записи', 'Мапа', 'Люди', 'Зірки', 'Приватність'];
  static const _titles = <List<(String, bool)>>[
    [('Говори як ', false), ('подрузі', true)],
    [('Оцінюй те, що ', false), ('важливо', true), (' тобі', false)],
    [('Побач, що тобі ', false), ('справді', true), (' подобається', false)],
    [('Порівнюй ', false), ('чесно', true)],
    [('Зірки як гра. Записи як ', false), ('правда', true)],
    [('Тут тільки ', false), ('ти', true)],
  ];
  static const _texts = [
    'Після зустрічі 20 секунд голосом. Vespr сам знайде прапорці й заповнить запис.',
    'Обери до 10 питань про секс і стільки ж про людину. Зірки за секунди.',
    'Після трьох записів Vespr покаже закономірності, яких ти не помічала.',
    'Секс окремо, характер окремо. Видно, хто в чому сильніший і з ким тобі краще.',
    'Знак і аркан для тебе і для нього. А поруч те, що кажуть твої оцінки.',
    'Записи не йдуть на наші сервери. Вхід за PIN-кодом, фото людей розмиті.',
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Rise(
          delay: .12,
          child: Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
            decoration: BoxDecoration(color: K.a(.12), borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Ico(_icons[i], size: 14, color: K.acc), const SizedBox(width: 8), Text(_labels[i], style: rw(13, color: K.acc, w: FontWeight.w700))]),
          ),
        ),
        const SizedBox(height: 12),
        Rise(delay: .12, child: titleAcc(_titles[i], 32, h: 1.12)),
        const SizedBox(height: 12),
        Rise(delay: .24, child: Text(_texts[i], style: rw(15, color: K.soft, h: 1.5))),
      ]);
}

/// Картка гайда (#2B2836, радіус)
BoxDecoration _card(double r) => BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(r));

/// Фон-світіння гайда
Widget _gGlow(double l, double t, double w, double h, double a, {bool circle = false, Color? c}) => Positioned(
      left: l, top: t,
      child: circle
          ? Glow(w: w, h: h, circle: true, colors: [(c ?? K.acc).withValues(alpha: a), const Color(0x0017161F)], stops: const [0, .65])
          : EGlow(w: w, h: h, colors: [(c ?? K.acc).withValues(alpha: a), const Color(0x0017161F)], stops: const [0, .65]),
    );

// ---- 1. Голос ----
class _GVoice extends StatelessWidget {
  const _GVoice();

  Widget _fld(String k, Color kc, String v, double d) => Rise(
        delay: d,
        dy: 14,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _card(16),
          child: Row(children: [SizedBox(width: 76, child: Text(k, style: rw(12, color: kc))), const SizedBox(width: 12), Text(v, style: rw(14))]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    TextSpan hl(String t) => TextSpan(text: t, style: TextStyle(color: K.star, background: Paint()..color = K.a(.2)));
    return Stack(children: [
      _gGlow(-80, -120, 550, 520, .16),
      Positioned(
        left: 20, right: 20, top: 112,
        child: Rise(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 112,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/img/dinner.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -.1), semanticLabel: 'Вечеря в ресторані'),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xD917161F), Color(0x3317161F)], stops: [0, .7]))),
                  Positioned(
                    left: 16, top: 0, bottom: 0,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Після зустрічі', style: rw(12, color: K.acc, w: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Архітектор, вечеря', style: pr(22, h: 1.1)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: _card(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 26, height: 26, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.acc), alignment: Alignment.center, child: Ico(Svgs.mic2, size: 13, color: K.bg)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('слухаю тебе', style: rw(12, color: K.muted2))),
                  const _Waves(),
                  const SizedBox(width: 6),
                  Text('0:18', style: rw(12, color: K.muted2)),
                ]),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'він '),
                    hl('спитав, чи мені комфортно'),
                    const TextSpan(text: ', потім '),
                    hl('провів додому'),
                    const TextSpan(text: '. але піввечора '),
                    hl('сидів у телефоні'),
                    const TextSpan(text: '…'),
                  ]),
                  style: rw(15, color: K.soft, h: 1.6),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            _fld('Зелений', K.green, 'Питав про межі', .5),
            const SizedBox(height: 6),
            _fld('Зелений', K.green, 'Провів додому', .8),
            const SizedBox(height: 6),
            _fld('Червоний', K.red, 'Сидів у телефоні', 1.1),
          ]),
        ),
      ),
    ]);
  }
}

class _Waves extends StatefulWidget {
  const _Waves();
  @override
  State<_Waves> createState() => _WavesState();
}

class _WavesState extends State<_Waves> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Row(children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: 3,
              height: 18 * (.3 + .7 * ((1 - math.cos(((c.value - i * .15) % 1) * 2 * math.pi)) / 2)),
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(2)),
            ),
        ]),
      );
}

// ---- 2. Записи ----
class _GRate extends StatelessWidget {
  const _GRate();

  Widget _stars(int v) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var k = 1; k <= 5; k++) Padding(padding: const EdgeInsets.only(left: 2), child: Ico(Svgs.star4, size: 20, color: k <= v ? K.acc : K.w(.14))),
      ]);

  Widget _tick(String t) => Row(children: [
        Container(width: 18, height: 18, decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Ico(Svgs.check, size: 11, color: K.bg)),
        const SizedBox(width: 8),
        Text(t, style: rw(12.5, color: K.bg)),
      ]);

  @override
  Widget build(BuildContext context) {
    const rows = [('Наскільки тобі було добре?', 5), ('Наскільки дбали про тебе?', 3), ('Наскільки тобі підходив темп?', 2), ('Наскільки тебе почули?', 4)];
    return Stack(children: [
      _gGlow(270, -60, 480, 480, .18, circle: true, c: K.haze),
      Positioned(
        left: 20, right: 20, top: 112, height: 420,
        child: Rise(
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 60, offset: Offset(0, 30), spreadRadius: -30)]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Row(children: [
                    Text('Як пройшло?', style: pr(24)),
                    const Spacer(),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                      decoration: BoxDecoration(color: K.bg, borderRadius: BorderRadius.circular(999)),
                      child: Row(children: [
                        Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [K.haze, K.hour]))),
                        const SizedBox(width: 6),
                        Text('Марк', style: rw(12)),
                      ]),
                    ),
                  ]),
                ),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: K.bg, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [Expanded(child: Text(r.$1, style: rw(13.5, h: 1.3))), const SizedBox(width: 10), _stars(r.$2)]),
                    ),
                  ),
              ]),
            ),
            Positioned(
              right: -6, bottom: 6,
              child: Transform.rotate(
                angle: -4 * math.pi / 180,
                child: Container(
                  width: 212,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0xB3000000), blurRadius: 50, offset: Offset(0, 24), spreadRadius: -16)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [Text('Мої питання', style: rw(12, color: K.bg, w: FontWeight.w700)), const Spacer(), Text('8 з 10', style: rw(11, color: K.muted2, w: FontWeight.w700))]),
                    const SizedBox(height: 10),
                    _tick('Прелюдії вистачало?'),
                    const SizedBox(height: 8),
                    _tick('Поважає твої межі?'),
                    const SizedBox(height: 8),
                    _tick('Атмосфера'),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ---- 3. Мапа ----
const _chartSvg = '''<svg width="318" height="132" viewBox="0 0 318 132"><defs><linearGradient id="gm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F08A6C" stop-opacity=".4"/><stop offset="1" stop-color="#F08A6C" stop-opacity="0"/></linearGradient></defs>
<path d="M0 33H318M0 66H318M0 99H318" stroke="#F1EEF2" stroke-opacity=".06"/>
<path d="M4 100 C 30 96, 42 110, 52 104 S 86 76, 100 80 S 130 94, 142 86 S 176 58, 190 56 S 220 62, 232 48 S 266 34, 278 30 S 296 24, 304 22 V132 H4Z" fill="url(#gm)"/>
<path d="M4 100 C 30 96, 42 110, 52 104 S 86 76, 100 80 S 130 94, 142 86 S 176 58, 190 56 S 220 62, 232 48 S 266 34, 278 30 S 296 24, 304 22" fill="none" stroke="#F08A6C" stroke-width="3" stroke-linecap="round"/>
<circle cx="304" cy="22" r="11" fill="#F08A6C" fill-opacity=".25"/><circle cx="304" cy="22" r="5.5" fill="#17161F" stroke="#F08A6C" stroke-width="3"/></svg>''';

class _GMap extends StatelessWidget {
  const _GMap();
  Widget _pill(String t, bool light, double d) => Rise(
        delay: d,
        dy: 8,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: light ? K.star : K.hour, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(t, style: rw(13, color: light ? K.bg : K.soft, w: FontWeight.w600))]),
        ),
      );

  @override
  Widget build(BuildContext context) => Stack(children: [
        _gGlow(-60, 20, 510, 420, .14),
        Positioned(
          left: 20, right: 20, top: 112,
          child: Rise(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: _card(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('Твоє задоволення', style: rw(14, w: FontWeight.w600)),
                    const Spacer(),
                    Text('3 місяці', style: rw(12, color: K.muted2)),
                  ]),
                  const SizedBox(height: 10),
                  SvgPicture.string(_chartSvg, width: 318, height: 132, semanticsLabel: 'Графік задоволення росте від 2,5 до 4,6'),
                  const SizedBox(height: 4),
                  Row(children: [Text('серпень', style: rw(11, color: K.muted2)), const Spacer(), Text('4,6 зараз', style: rw(11, w: FontWeight.w700))]),
                ]),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill('+ Довга прелюдія', true, .5),
                _pill('+ Коли питають, як тобі', true, .65),
                _pill('− Після алкоголю', false, .8),
                _pill('− Поспіх', false, .95),
              ]),
              const SizedBox(height: 12),
              Rise(
                delay: 1.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: K.a(.1), borderRadius: BorderRadius.circular(22), border: Border.all(color: K.a(.35))),
                  child: Row(children: [
                    const Ico(Svgs.star4, size: 24, color: K.acc),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Тобі краще, коли до близькості є хоча б година розмови', style: rw(13.5, h: 1.4))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]);
}

// ---- 4. Люди ----
class _GCompare extends StatelessWidget {
  const _GCompare();

  Widget _ph(Color ring, double shift) => Container(
        width: 60, height: 76,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: ring, width: 2)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Transform.scale(scale: 1.15, child: Image.asset('assets/img/couple.jpg', fit: BoxFit.cover, alignment: Alignment(shift, 0), width: 56, height: 72)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const rows = [('Наскільки тобі було добре', 4, 5), ('Наскільки дбали про тебе', 5, 2), ('Прелюдії вистачало', 5, 3), ('Тебе почули', 4, 3)];
    const w = 112.0;
    return Stack(children: [
      _gGlow(-60, 0, 510, 440, .13),
      Positioned(
        left: 20, right: 20, top: 112,
        child: Rise(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _card(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                _ph(K.acc, -1),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Архітектор', style: rw(13, w: FontWeight.w700)),
                    Text('4,6', style: pr(24, color: K.acc, h: 1.1)),
                  ]),
                ),
                Text('vs', style: pr(16, color: K.muted2)),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Марк', style: rw(13, w: FontWeight.w700)),
                    Text('3,1', style: pr(24, color: K.soft, h: 1.1)),
                  ]),
                ),
                const SizedBox(width: 10),
                _ph(K.haze, 1),
              ]),
              const SizedBox(height: 14),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Text(rows[i].$1, style: rw(12, color: K.soft), textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Row(children: [
                  SizedBox(width: 24, child: Text('${rows[i].$2}', textAlign: TextAlign.center, style: rw(13, w: FontWeight.w700, color: rows[i].$2 > rows[i].$3 ? K.acc : K.haze))),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _Bar(width: rows[i].$2 / 5 * w, color: rows[i].$2 > rows[i].$3 ? K.acc : K.a(.32), left: true, delay: i * .25),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3A3548))),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Bar(width: rows[i].$3 / 5 * w, color: rows[i].$3 > rows[i].$2 ? K.soft : K.haze.withValues(alpha: .38), left: false, delay: i * .25),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(width: 24, child: Text('${rows[i].$3}', textAlign: TextAlign.center, style: rw(13, w: FontWeight.w700, color: rows[i].$3 > rows[i].$2 ? K.star : K.haze))),
                ]),
              ],
              const SizedBox(height: 14),
              Rise(
                delay: 1.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: K.a(.3)),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [K.a(.22), const Color(0x9917161F)], stops: const [0, .75]),
                  ),
                  child: Text('З Марком тілу краще, але про тебе дбає Архітектор.', style: pr(16, h: 1.35)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Bar extends StatefulWidget {
  final double width;
  final Color color;
  final bool left;
  final double delay;
  const _Bar({required this.width, required this.color, required this.left, required this.delay});
  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: (300 + widget.delay * 1000).round()), () {
      if (mounted) c.forward();
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Container(
          width: widget.width * easeOut.transform(c.value),
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: widget.left
                ? const BorderRadius.horizontal(left: Radius.circular(6), right: Radius.circular(2))
                : const BorderRadius.horizontal(left: Radius.circular(2), right: Radius.circular(6)),
          ),
        ),
      );
}

// ---- 5. Зірки ----
class _GStars extends StatefulWidget {
  const _GStars();
  @override
  State<_GStars> createState() => _GStarsState();
}

class _GStarsState extends State<_GStars> with SingleTickerProviderStateMixin {
  late final flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) flip.forward();
    });
  }

  @override
  void dispose() {
    flip.dispose();
    super.dispose();
  }

  Widget _back() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/img/sky.jpg', fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: K.w(.4)), color: const Color(0x4017161F)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Ico(Svgs.star4, size: 30), const SizedBox(height: 10), Text('vesp·r', style: pr(22))]),
            ),
          ),
        ]),
      );

  Widget _front() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment(-.35, -1), end: Alignment(.35, 1), colors: [Color(0xFF3A3548), K.hour, Color(0xFF3B2E36)], stops: [0, .55, 1]),
          boxShadow: const [BoxShadow(color: Color(0x8C08070C), blurRadius: 60, offset: Offset(0, 30), spreadRadius: -24)],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: K.a(.5))),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Діва · Земля', style: rw(11, color: K.muted2, w: FontWeight.w600)),
            Column(children: [const Ico(Svgs.star4, size: 22, color: K.acc), const SizedBox(height: 10), Text('XIV', style: pr(58, h: 1, ls: 0))]),
            Text('Помірність', style: pr(20)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Stack(children: [
        _gGlow(-40, 40, 470, 470, .24, circle: true),
        starDot(54, 170, 3, K.star, .7),
        starDot(330, 150, 2, K.star, .6),
        starDot(300, 380, 3, K.acc, .8),
        starDot(70, 400, 2, K.star, .5),
        Positioned(
          left: 20, right: 20, top: 118,
          child: Rise(
            child: Column(children: [
              AnimatedBuilder(
                animation: flip,
                builder: (_, __) {
                  final v = Curves.easeInOutCubic.transform(flip.value);
                  final a = v * math.pi;
                  final front = a > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .0009)
                      ..rotateY(a),
                    child: SizedBox(
                      width: 176, height: 264,
                      child: front ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _front()) : _back(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Rise(
                delay: 1.6,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
                  decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Ти XIV + він III =', style: rw(13, color: K.soft)),
                    const SizedBox(width: 8),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999)),
                      child: Text('XVII Зірка · легко', style: rw(13, color: K.bg, w: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Rise(
                delay: 2,
                dy: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: K.a(.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.a(.3))),
                  child: Row(children: [
                    Text('5,0', style: pr(24, color: K.acc)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Аркан обіцяв «уважний до тебе». Твої записи це підтверджують', style: rw(13, h: 1.35))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]);
}

// ---- 6. Приватність ----
class _GPrivate extends StatelessWidget {
  const _GPrivate();

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(
          left: 20, right: 20, top: 112, height: 400,
          child: Rise(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/img/stars.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -.4), semanticLabel: 'Людина під зоряним небом'),
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x2617161F), Color(0x5917161F), Color(0xEB17161F)], stops: [0, .45, 1])),
                ),
                Positioned(
                  left: 0, right: 0, top: 34,
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: const Color(0x8C17161F), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.2))),
                          alignment: Alignment.center,
                          child: Ico(Svgs.lock, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const DDots(4),
                  ]),
                ),
                Positioned(
                  left: 16, right: 16, bottom: 16,
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xBF2B2836), borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.08))),
                      child: Row(children: [
                        const _AppIcon(dark: true, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Темна іконка', style: rw(14, w: FontWeight.w700)),
                            Text('або світла, як тобі до вподоби', style: rw(12, color: K.soft)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Row(children: gapped([
                      for (final t in ['Тільки на телефоні', 'Лише псевдоніми', 'Розмиті фото'])
                        Expanded(
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xBF2B2836), borderRadius: BorderRadius.circular(14)),
                            child: Text(t, textAlign: TextAlign.center, style: rw(12)),
                          ),
                        ),
                    ], 8, horizontal: true)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]);
}

/// Іконка апки «v» з крапкою (темна або світла)
class _AppIcon extends StatelessWidget {
  final bool dark;
  final double size;
  const _AppIcon({required this.dark, this.size = 56});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: dark ? K.bg : K.star,
          borderRadius: BorderRadius.circular(size * 15 / 56),
          border: dark ? Border.all(color: K.w(.14)) : null,
        ),
        child: Stack(children: [
          Center(child: Transform.translate(offset: Offset(0, -size * 6 / 56), child: Text('v', style: pr(size * 32 / 56, color: dark ? K.star : K.bg, h: 1, ls: 0)))),
          Positioned(
            right: size * 13 / 56, top: size * 17 / 56,
            child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: K.acc, boxShadow: [BoxShadow(color: K.a(.8), blurRadius: 8)])),
          ),
        ]),
      );
}

// =====================================================================
// Birthdate: «Трохи про тебе» (і з налаштувань)
// =====================================================================
class _Lbl extends StatelessWidget {
  final String t;
  const _Lbl(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: rw(12, color: K.muted));
}

/// Блимаючий курсор у клітинці дати
class _Caret extends StatefulWidget {
  const _Caret();
  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Opacity(opacity: c.value < .5 ? 1 : 0, child: Container(margin: const EdgeInsets.only(left: 2), width: 2, height: 24, color: K.acc)),
      );
}

class AboutYou extends StatefulWidget {
  const AboutYou({super.key});
  @override
  State<AboutYou> createState() => _AboutYouState();
}

class _AboutYouState extends State<AboutYou> with SingleTickerProviderStateMixin {
  late final TextEditingController name, dt; // dt — 8 цифр ДДММРРРР в одному прихованому полі
  final fdt = FocusNode();
  late final spin = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void initState() {
    super.initState();
    final p = Store.read(context).profile;
    final b = p.birth?.split('-');
    name = TextEditingController(text: p.name);
    dt = TextEditingController(text: b == null ? '' : '${b[2]}${b[1]}${b[0]}');
    fdt.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    name.dispose();
    dt.dispose();
    fdt.dispose();
    spin.dispose();
    super.dispose();
  }

  String get _dg => dt.text;
  String get dd => _dg.length > 2 ? _dg.substring(0, 2) : _dg;
  String get mm => _dg.length > 4 ? _dg.substring(2, 4) : (_dg.length > 2 ? _dg.substring(2) : '');
  String get yy => _dg.length > 4 ? _dg.substring(4) : '';
  String? get iso => _dg.length == 8 ? parseUA('$dd.$mm.$yy') : null;

  /// Три клітинки дати, а вводимо в одне приховане поле: «14092001» підряд, курсор сам іде далі
  Widget _box(String label, String v, bool active) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Lbl(label),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeD,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: active ? K.a(.05) : K.w(.03),
              border: Border.all(color: active ? K.a(.7) : K.w(.1)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(v, style: pr(22)),
              if (active) const _Caret(),
            ]),
          ),
        ]),
      );

  Widget _dateRow() {
    final f = fdt.hasFocus, n = _dg.length;
    return Stack(children: [
      Row(children: [
        _box('День', dd, f && n < 2),
        const SizedBox(width: 10),
        _box('Місяць', mm, f && n >= 2 && n < 4),
        const SizedBox(width: 10),
        _box('Рік', yy, f && n >= 4),
      ]),
      Positioned.fill(
        top: 20,
        child: Opacity(
          opacity: 0,
          child: Semantics(
            label: 'Дата народження, день місяць рік',
            child: TextField(
              controller: dt,
              focusNode: fdt,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(fontSize: 1, color: Colors.transparent),
              decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
              onChanged: (_) => setState(() {}),
              expands: true,
              maxLines: null,
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final store = Store.of(context);
    final onb = !store.profile.onboarded;
    final i = iso;
    final a = i == null ? null : astroOf(i);
    final ok = name.text.trim().isNotEmpty && i != null;
    final dateTyped = _dg.length == 8;
    return DFrame(
      builder: (context, h) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: h - 82),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              onb ? const StepHeader(1) : const SizedBox(height: 44, child: Align(alignment: Alignment.centerLeft, child: BackBtn())),
              const SizedBox(height: 22),
              titleAcc([('Трохи\n', false), ('про тебе', true)], 36),
              const SizedBox(height: 10),
              Text("Ім'я бачиш тільки ти. За датою покажемо знак і аркан.", style: rw(14, color: K.muted, h: 1.5)),
              const SizedBox(height: 22),
              const _Lbl('Як тебе звати'),
              const SizedBox(height: 8),
              DInput(
                controller: name, height: 60, label: 'Як тебе звати', hint: "Ім'я або як тебе називати",
                style: rw(16), caps: TextCapitalization.words,
                action: TextInputAction.next, onSubmitted: (_) => fdt.requestFocus(),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 22),
              _dateRow(),
              if (dateTyped && i == null) ...[const SizedBox(height: 8), Text('Перевір дату', style: rw(12, color: K.red))],
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 900),
                switchInCurve: easeOut,
                transitionBuilder: (c, an) => FadeTransition(opacity: an, child: SlideTransition(position: Tween(begin: const Offset(0, .07), end: Offset.zero).animate(an), child: ScaleTransition(scale: Tween(begin: .97, end: 1.0).animate(an), child: c))),
                child: a == null ? const SizedBox(key: ValueKey('none'), height: 240) : _AstroCard(a, spin, key: ValueKey('${a.sign}-${a.arc}')),
              ),
              const Spacer(),
              const SizedBox(height: 22),
              Cta(onb ? 'Далі' : 'Зберегти', onTap: !ok
                  ? null
                  : () async {
                      await store.updateProfile((p) { p.name = name.text.trim(); p.birth = i; });
                      if (!context.mounted) return;
                      if (onb) {
                        go(context, const SetupScreen());
                      } else {
                        Navigator.pop(context);
                      }
                    }),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AstroCard extends StatelessWidget {
  final Astro a;
  final Animation<double> spin;
  const _AstroCard(this.a, this.spin, {super.key});
  @override
  Widget build(BuildContext context) {
    final arc = a.arc == null ? null : arcana[a.arc!];
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(begin: Alignment(-.6, -1), end: Alignment(.6, 1), colors: [K.acc, Color(0xFFC9796E), Color(0xFF5E5674), K.hour], stops: [0, .38, .78, 1]),
        boxShadow: const [BoxShadow(color: Color(0x8C08070C), blurRadius: 60, offset: Offset(0, 30), spreadRadius: -20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(children: [
          Positioned(
            right: -70, top: -70,
            child: RotationTransition(
              turns: spin,
              child: Opacity(
                opacity: .22,
                child: SvgPicture.string(
                  '<svg width="260" height="260" viewBox="0 0 100 100" fill="none" stroke="#F1EEF2" stroke-width=".5"><circle cx="50" cy="50" r="48"/><circle cx="50" cy="50" r="36"/><path d="M50 2v96M2 50h96M16 16l68 68M84 16L16 84"/></svg>',
                  width: 260, height: 260,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24, top: 22,
            child: Container(
              height: 28,
              padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
              decoration: BoxDecoration(color: const Color(0x3817161F), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.18))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Ico(Svgs.star4, size: 12), const SizedBox(width: 8), Text('Твоя карта', style: rw(12, w: FontWeight.w500))]),
            ),
          ),
          const Positioned(
            left: 0, right: 0, bottom: 0, height: 150,
            child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0017161F), Color(0x6117161F)]))),
          ),
          Positioned(
            left: 24, right: 24, bottom: 24,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                columnWidths: const {1: FlexColumnWidth()},
                defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  TableRow(children: [
                    Padding(padding: const EdgeInsets.only(right: 16, bottom: 8), child: Text('Знак', style: rw(12, color: K.w(.75)))),
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(a.signName, style: pr(32, h: 1))),
                  ]),
                  if (arc != null)
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.only(right: 16), child: Text('Аркан ${a.romanNum}', style: rw(12, color: K.w(.75)))),
                      Text(arc.name, style: pr(32, h: 1), maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                    ]),
                ],
              ),
              if (arc != null) ...[
                const SizedBox(height: 14),
                Text('${arc.core} ${arc.love}', style: rw(13, color: K.w(.9), h: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// =====================================================================
// Setup: з ким зустрічаєшся, PIN, іконка
// =====================================================================
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store.of(context);
    final p = store.profile;
    const who = [('men', 'Чоловіки'), ('women', 'Жінки'), ('all', 'Усі')];
    return DFrame(
      builder: (context, h) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: h - 82),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const StepHeader(2),
              const SizedBox(height: 24),
              Rise(child: titleAcc([('З ким ти\n', false), ('зустрічаєшся', true), ('?', false)], 36)),
              const SizedBox(height: 24),
              Rise(
                delay: .05,
                child: Row(children: gapped([
                  for (final w in who)
                    Expanded(
                      child: Press(
                        onTap: () => store.updateProfile((x) => x.dating = w.$1),
                        child: Semantics(
                          selected: p.dating == w.$1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: easeOut,
                            height: 112,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: p.dating == w.$1 ? K.star : K.hour,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: p.dating == w.$1 ? K.star : K.w(.08)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 22, height: 22,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.dating == w.$1 ? K.acc : K.w(.3), width: p.dating == w.$1 ? 6 : 1.5)),
                              ),
                              Text(w.$2, style: rw(15, color: p.dating == w.$1 ? K.bg : K.star, w: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ], 10, horizontal: true)),
              ),
              const SizedBox(height: 24),
              Rise(
                delay: .1,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Приватність', style: rw(13, color: K.muted)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(22), border: Border.all(color: K.w(.07))),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(center: const Alignment(0, -.4), colors: [K.a(.2), K.a(.06)]), border: Border.all(color: K.a(.3))),
                        alignment: Alignment.center,
                        child: Ico(Svgs.lock, size: 20, color: K.accSoft),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('PIN-код або Face ID', style: rw(15, w: FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text('Питаємо щоразу, коли відкриваєш', style: rw(12, color: K.muted)),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Sw(on: p.pinEnabled, label: 'PIN-код', onChanged: (v) => store.updateProfile((x) => x.pinEnabled = v)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Rise(
                delay: .15,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Іконка апки', style: rw(13, color: K.muted)),
                  const SizedBox(height: 14),
                  Row(children: gapped([
                    for (final ic in [('dark', 'Темна'), ('light', 'Світла')])
                      Expanded(
                        child: Press(
                          onTap: () => store.updateProfile((x) => x.appIcon = ic.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: easeD,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: p.appIcon == ic.$1 ? K.a(.55) : K.w(.08)),
                              gradient: p.appIcon == ic.$1
                                  ? RadialGradient(center: Alignment.topLeft, radius: 1.3, colors: [K.a(.16), K.a(0)], stops: const [0, .65])
                                  : null,
                              color: p.appIcon == ic.$1 ? null : K.w(.025),
                            ),
                            child: Row(children: [
                              _AppIcon(dark: ic.$1 == 'dark'),
                              const SizedBox(width: 14),
                              Text(ic.$2, style: rw(14, color: p.appIcon == ic.$1 ? K.star : K.soft2, w: FontWeight.w500)),
                            ]),
                          ),
                        ),
                      ),
                  ], 10, horizontal: true)),
                ]),
              ),
              const Spacer(),
              const SizedBox(height: 24),
              Cta('Далі', onTap: () {
                if (p.pinEnabled) {
                  go(context, PinNewScreen(doneLabel: 'Далі', onDone: (c) => goReplace(c, const AddPersonScreen(onboarding: true))));
                } else {
                  go(context, const AddPersonScreen(onboarding: true));
                }
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// AddPerson: «Додай першу людину» (і «Нова людина» з вкладки Люди)
// =====================================================================
class AddPersonScreen extends StatefulWidget {
  final bool onboarding;
  const AddPersonScreen({super.key, this.onboarding = false});
  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final nick = TextEditingController(), d = TextEditingController(), m = TextEditingController();
  final fd = FocusNode(), fm = FocusNode();
  String gender = 'm', rel = 'date';
  bool unknown = false, signsOpen = false;
  int? signOnly;
  int? size;

  // знаки в порядку з макета (від Овна) → індекс у signs
  static const _signOrder = ['Овен', 'Телець', 'Близнюки', 'Рак', 'Лев', 'Діва', 'Терези', 'Скорпіон', 'Стрілець', 'Козеріг', 'Водолій', 'Риби'];

  @override
  void dispose() {
    for (final c in [nick, d, m]) {
      c.dispose();
    }
    fd.dispose();
    fm.dispose();
    super.dispose();
  }

  String? get birth {
    final dd = int.tryParse(d.text), mm = int.tryParse(m.text);
    if (dd == null || mm == null || mm < 1 || mm > 12 || dd < 1) return null;
    final dim = DateTime(2000, mm + 1, 0).day; // 2000 — високосний, тож 29.02 приймаємо
    if (dd > dim) return null;
    return '0000-${mm.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final s = Store.read(context);
    if (widget.onboarding == false && !s.profile.premium && s.people.where((p) => !p.isPast).length >= freePeople) {
      go(context, const PaywallScreen());
      return;
    }
    final p = Person(
      id: uid(),
      name: nick.text.trim(),
      gender: gender,
      rel: rel,
      birth: unknown ? null : birth,
      signOnly: unknown ? signOnly : null,
      size: size,
      createdAt: DateTime.now().toIso8601String(),
    );
    await s.addPerson(p);
    if (!mounted) return;
    if (widget.onboarding) {
      await finishOnboarding(context);
    } else {
      Navigator.pop(context, p.id);
    }
  }

  Widget _signBtn(String sname) {
    final idx = signs.indexWhere((x) => x.name == sname);
    final on = signOnly == idx;
    return Press(
      onTap: () => setState(() => signOnly = idx),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? K.acc : K.w(.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: on ? K.acc : K.w(.08))),
        child: Text(sname, style: rw(13, color: on ? K.bg : K.soft2, w: on ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Press(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: easeD,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: on ? K.star : K.w(.03), border: Border.all(color: on ? K.star : K.w(.1))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: rw(13, color: on ? K.bg : K.soft2, w: FontWeight.w500))]),
        ),
      );

  Widget _res(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.07))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: rw(11, color: K.muted, w: FontWeight.w500, ls: .2)),
            const SizedBox(height: 4),
            Text(value, style: pr(20, h: 1.15), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final b = unknown ? null : birth;
    final a = b == null ? null : astroOf(b);
    final f = gender == 'f';
    final ok = nick.text.trim().isNotEmpty;
    const relLabels = [('date', 'Побачення'), ('fling', 'Інтрижка'), ('rel', 'Стосунки'), ('night', 'Одна ніч'), ('ex', 'Колишній')];
    const sizeL = ['Скромно', 'Золотий стандарт', 'Вражає', 'Гігант'];
    const sizeT = ['Скромно', 'Стандарт', 'Вражає', 'Гігант'];
    final lbl = rw(13, color: K.muted);

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              widget.onboarding
                  ? StepHeader(3, right: Press(onTap: () => finishOnboarding(context), child: SizedBox(height: 44, child: Center(child: Text('Пізніше', style: rw(13, color: K.muted, w: FontWeight.w500))))))
                  : const SizedBox(height: 44, child: Align(alignment: Alignment.centerLeft, child: BackBtn())),
              Text(widget.onboarding ? 'Додай першу людину' : 'Нова людина', style: pr(34, h: 1.1)),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(f ? 'Як її назвеш' : 'Як його назвеш', style: lbl),
                const SizedBox(height: 8),
                Row(children: [
                  Press(
                    label: 'Додати фото',
                    onTap: () => dToast(context, 'Фото людей додамо в наступній версії'),
                    child: SizedBox(
                      width: 56, height: 56,
                      child: Stack(clipBehavior: Clip.none, children: [
                        CustomPaint(size: const Size(56, 56), painter: _DashedCircle(K.w(.24))),
                        Center(child: Ico(Svgs.camera, size: 20, color: K.soft)),
                        Positioned(
                          right: -2, bottom: -2,
                          child: Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: K.acc, border: Border.all(color: K.bg, width: 3)),
                            alignment: Alignment.center,
                            child: Text('+', style: rw(12, color: K.bg, w: FontWeight.w600, h: 1)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: DInput(controller: nick, label: 'Псевдонім', hint: 'Псевдонім, напр. Архітектор', style: rw(16), caps: TextCapitalization.sentences, onChanged: (_) => setState(() {}))),
                ]),
              ]),
              Row(children: [
                Text('Стать', style: lbl),
                const Spacer(),
                Container(
                  width: 180,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.07))),
                  child: Row(children: [
                    for (final g in [('m', 'Він'), ('f', 'Вона')])
                      Expanded(
                        child: Press(
                          onTap: () => setState(() => gender = g.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: easeD,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: gender == g.$1 ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                            child: Text(g.$2, style: rw(14, color: gender == g.$1 ? K.bg : K.muted2, w: FontWeight.w500)),
                          ),
                        ),
                      ),
                  ]),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(text: f ? 'Хто вона для тебе ' : 'Хто він для тебе ', children: [TextSpan(text: '· можна змінити потім', style: rw(13, color: K.haze))]), style: lbl),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final r in relLabels) _chip(f && r.$1 == 'ex' ? 'Колишня' : r.$2, rel == r.$1, () => setState(() => rel = r.$1)),
                ]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Text('День народження', style: lbl),
                  const Spacer(),
                  Press(
                    scale: 1,
                    onTap: () => setState(() { unknown = !unknown; signsOpen = false; }),
                    child: SizedBox(height: 44, child: Row(children: [Text('Не знаю дати', style: rw(13, color: K.soft2)), const SizedBox(width: 10), Ck(unknown, size: 22)])),
                  ),
                ]),
                if (!unknown) ...[
                  Row(children: [
                    Expanded(child: DInput(controller: d, focus: fd, label: 'День', hint: 'ДД', align: TextAlign.center, style: pr(20), keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], onChanged: (v) { setState(() {}); if (v.length == 2) fm.requestFocus(); })),
                    const SizedBox(width: 8),
                    Expanded(child: DInput(controller: m, focus: fm, label: 'Місяць', hint: 'ММ', align: TextAlign.center, style: pr(20), keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], onChanged: (_) => setState(() {}))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _res('Знак', a?.signName ?? '—'),
                    const SizedBox(width: 8),
                    _res(a == null ? 'Аркан' : 'Аркан ${a.romanNum}', a?.arcanaName ?? '—'),
                  ]),
                ],
                if (unknown && !signsOpen) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.07))),
                    child: Text("Знак і аркан з'являться, коли додаси дату. Це можна зробити потім на картці людини.", style: rw(13, color: K.soft2, h: 1.45)),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Press(onTap: () => setState(() => signsOpen = true), child: SizedBox(height: 44, child: Center(child: Text('Знаю тільки знак', style: rw(13, color: K.accSoft, w: FontWeight.w500))))),
                  ),
                ],
                if (unknown && signsOpen) ...[
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 81 / 44,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final sname in _signOrder) _signBtn(sname),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Без дати аркан не порахуємо, тільки знак', style: rw(12, color: K.muted2)),
                ],
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text.rich(TextSpan(text: 'Розмір ', children: [TextSpan(text: '· можна пізніше', style: rw(13, color: K.haze))]), style: lbl),
                  const Spacer(),
                  Text(size == null ? '—' : sizeL[size!], style: pr(17, h: 1)),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                  decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.07))),
                  child: Column(children: [
                    _SizeSlider(value: size, onChanged: (v) => setState(() => size = v)),
                    Row(children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Press(
                            onTap: () => setState(() => size = i),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                              child: Text(sizeT[i], textAlign: TextAlign.center, style: rw(11, color: size == i ? K.star : K.muted, w: size == i ? FontWeight.w600 : FontWeight.w500, h: 1.25)),
                            ),
                          ),
                        ),
                    ]),
                  ]),
                ),
              ]),
              if (a != null)
                Press(
                  onTap: () => go(context, const PaywallScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: K.a(.25)),
                      gradient: LinearGradient(begin: const Alignment(-1, -.5), end: const Alignment(1, .5), colors: [K.a(.18), K.hour], stops: const [0, .65]),
                    ),
                    child: Row(children: [
                      const Ico(Svgs.star4, size: 22, color: K.acc),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Ваш метч уже пораховано', style: rw(14, w: FontWeight.w700)),
                          ExcludeSemantics(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Text('Аркан пари XVII Зірка, легко', style: rw(12, color: K.muted2)))),
                        ]),
                      ),
                      Ico(Svgs.lock, size: 18, color: K.acc),
                    ]),
                  ),
                ),
              const SizedBox(height: 4),
              Cta('Додати', onTap: ok ? _save : null),
            ], 16)),
          ),
        ),
      ]),
    );
  }
}

class _DashedCircle extends CustomPainter {
  final Color c;
  _DashedCircle(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final r = s.width / 2 - .5;
    const n = 36;
    for (var i = 0; i < n; i += 2) {
      canvas.drawArc(Rect.fromCircle(center: Offset(s.width / 2, s.height / 2), radius: r), i * 2 * math.pi / n, 2 * math.pi / n, false, p);
    }
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), r - .5, Paint()..color = K.w(.03));
  }

  @override
  bool shouldRepaint(_DashedCircle o) => false;
}

/// Повзунок розміру з макета: рейка 2px, 4 крапки, біла ручка 18
class _SizeSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  const _SizeSlider({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final l = w * .125, r = w * .875, span = r - l;
        int at(double x) => (((x - l) / span) * 3).round().clamp(0, 3);
        final v = value;
        final x = v == null ? null : l + span * v / 3;
        return Semantics(
          slider: true,
          label: 'Розмір',
          value: v == null ? 'не вказано' : '${v + 1} з 4',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (e) => onChanged(at(e.localPosition.dx)),
            onHorizontalDragUpdate: (e) => onChanged(at(e.localPosition.dx)),
            child: SizedBox(
              height: 40,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(left: l, width: span, top: 19, child: Container(height: 2, decoration: BoxDecoration(color: K.w(.12), borderRadius: BorderRadius.circular(1)))),
                if (x != null) AnimatedPositioned(duration: const Duration(milliseconds: 300), curve: easeOut, left: l, width: x - l, top: 19, child: Container(height: 2, color: K.acc)),
                for (var i = 0; i < 4; i++)
                  Positioned(left: l + span * i / 3 - 3, top: 17, child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: v != null && i <= v ? K.acc : const Color(0xFF3A3646)))),
                if (x != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: easeOut,
                    left: x - 9, top: 11,
                    child: Container(width: 18, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.star, boxShadow: [BoxShadow(color: Color(0x7308060E), blurRadius: 6, offset: Offset(0, 2))])),
                  ),
              ]),
            ),
          ),
        );
      });
}
