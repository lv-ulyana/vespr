import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/wrapped.dart';
import '../logic/wrapped_layers.dart';
import '../services/files.dart';
import '../ui/board.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'settings.dart' show PaywallScreen;
import 'wrapped_anim.dart';

/// Wrapped за дошкою «Wrapped»: 19 сторіз-слайдів 390×844.
/// Декор (стікери, фото, стрічки, візерунки) — запечені шари assets/wrapped/sNN.webp з макета;
/// усе, що залежить від даних (заголовки, цифри, рядки, кільця, графіки), малюється тут.

const _ink = Color(0xFF0E0D1F);
const _pink = Color(0xFFFF9AD5);
const _hot = Color(0xFFFF5C8A);
const _yel = Color(0xFFFFC83D);
const _red = Color(0xFFE8333B);

// Тема кожної дошки: m — темна (білий текст), l — світла, q — тиха
// тема панелі керування — як TH у макеті (кнопки), фон слайда може відрізнятись
const _th = ['m1', 'l2', 'l3', 'm1', 'l3', 'm1', 'l2', 'l3', 'l2', 'l3', 'm1', 'm3', 'l2', 'l3', 'q', 'l3', 'l2', 'm1', 'l3'];
// слайди з темним фоном (білий текст)
const _darkBg = {0, 3, 5, 10, 11, 12, 14};
const _bgOf = {'1': _ink, '2': _pink, '3': _yel, '': Color(0xFF17161F)};

/// Cormorant Garamond (бюджет, «Варто помітити», фінал)
TextStyle cg(double s, FontWeight w, Color c, {bool it = false, double? h, double ls = 0}) =>
    TextStyle(fontFamily: 'Cormorant', fontSize: s, fontWeight: w, fontStyle: it ? FontStyle.italic : FontStyle.normal, color: c, height: h, letterSpacing: ls, fontFeatures: const [FontFeature.liningFigures()]);

/// Montserrat, дрібні підписи капсом
TextStyle mt(double s, FontWeight w, Color c, {double? h, double ls = 0}) => TextStyle(fontFamily: 'Montserrat', fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls);

const _rose = Color(0xFFFF6FAE);
const _plum = Color(0xFFE2559F);

TextStyle ws(double s, FontWeight w, Color c, {double? h, double ls = 0, TextDecoration? dec, Color? decColor}) =>
    TextStyle(fontFamily: 'Onest', fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: ls, decoration: dec, decorationColor: decColor, decorationThickness: 2);
TextStyle mono(double s, FontWeight w, {double? h}) => TextStyle(fontFamily: 'PlexMono', fontSize: s, fontWeight: w, color: const Color(0xFF2B2830), height: h, letterSpacing: .125);

String _svg(String inner, {String vb = '0 0 24 24'}) => '<svg viewBox="$vb">$inner</svg>';
const _heartPath = 'M12 21C5 15.6 1 11.9 1 7.2 1 3.8 3.6 1.2 6.9 1.2c2 0 3.9 1 5.1 2.6 1.2-1.6 3.1-2.6 5.1-2.6 3.3 0 5.9 2.6 5.9 6 0 4.7-4 8.4-11 13.8z';
final _heartOn = _svg('<path fill="currentColor" d="$_heartPath"/>', vb: '0 0 24 22');
final _heartOff = _svg('<path fill="none" stroke="currentColor" stroke-width="1.8" d="$_heartPath"/>', vb: '-1 -1 26 24');
final _icTimer = _svg('<g fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="13.5" r="7.5"/><path d="M12 9.5v4.2l2.6 1.6M10 2.5h4M12 2.5V6M18.2 6.8l1.4-1.4"/></g>');
final _icPerson = _svg('<g fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4.5 20.5c1.2-4 4-6 7.5-6s6.3 2 7.5 6z"/></g>');
final _icRepeat = _svg('<g fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12a8 8 0 0 1 13.7-5.6L20 9M20 4v5h-5M20 12a8 8 0 0 1-13.7 5.6L4 15M4 20v-5h5"/></g>');
final _icBolt = _svg('<path d="M13 2 5 14h6l-1 8 8-12h-6z" fill="currentColor"/>');
final _icPersonF = _svg('<circle cx="12" cy="8" r="4" fill="currentColor"/><path d="M4.5 20.5c1.2-4 4-6 7.5-6s6.3 2 7.5 6z" fill="currentColor"/>');
final _icTimer2 = _svg('<g fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="13.5" r="7.5"/><path d="M12 9.5v4.2l2.6 1.6M10 2.5h4M12 2.5V6"/></g>');
final _icCheck = _svg('<path d="M5 12.5l4.5 4.5L19 7" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>');
final _icX = _svg('<path d="M6 6l12 12M18 6 6 18" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>');
final _icPhone = _svg('<rect x="6" y="2" width="12" height="20" rx="3" fill="none" stroke="currentColor" stroke-width="2.2"/><circle cx="12" cy="18" r="1.2" fill="currentColor"/>');
final _icHeartO = _svg('<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.3 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>');
final _icEye = _svg('<g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.6-6.5 10-6.5S22 12 22 12s-3.6 6.5-10 6.5S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></g>');
final _icChat = _svg('<path fill="currentColor" d="M12 3C6.5 3 2 6.8 2 11.4c0 2.4 1.2 4.5 3.2 6L4.5 21l4.1-2.1c1.1.3 2.2.5 3.4.5 5.5 0 10-3.8 10-8.4S17.5 3 12 3z"/><circle cx="8" cy="11.4" r="1.3" fill="#1A120E"/><circle cx="12" cy="11.4" r="1.3" fill="#1A120E"/><circle cx="16" cy="11.4" r="1.3" fill="#1A120E"/>');
final _icShield = _svg('<path fill="currentColor" d="M12 2 4 5v6c0 5 3.4 9.3 8 11 4.6-1.7 8-6 8-11V5z"/><path d="m8.5 12 2.5 2.5 4.5-5" fill="none" stroke="#1A120E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>');
final _icHeart2 = _svg('<path d="M12 21C5 15.5 2 12 2 8a5 5 0 0 1 10-2 5 5 0 0 1 10 2c0 4-3 7.5-10 13z" fill="currentColor"/>');
final _icShare = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3v13M7 8l5-5 5 5M5 14v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5"/></svg>';
final _icClose = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M6 6l12 12M18 6L6 18"/></svg>';
final _icIg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1" fill="currentColor"/></svg>';
final _icTg = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M21.5 4.3L2.9 11.5c-.9.4-.9 1.5 0 1.8l4.6 1.5 1.8 5.4c.2.7 1.1.9 1.6.4l2.6-2.5 4.7 3.5c.6.4 1.4.1 1.6-.6l3.2-14.8c.2-.9-.7-1.6-1.5-1.3zM9.6 14.2l8.2-7.1-6.6 8.6-.3 3.1-1.3-4.6z"/></svg>';
final _icSave = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>';
final _icMore = '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/></svg>';

const _rot8 = -8 * math.pi / 180;

double _textW(String t, TextStyle st) {
  final tp = TextPainter(text: TextSpan(text: t, style: st), textDirection: TextDirection.ltr, maxLines: 1)..layout();
  return tp.width;
}

class WrappedScreen extends StatefulWidget {
  final String month;
  const WrappedScreen({super.key, required this.month});
  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  int i = 0;
  bool safe = true;
  final shot = GlobalKey();
  bool _cached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cached) return;
    _cached = true;
    // усі 19 фонів одразу, щоб текст не з'являвся поверх старого слайда
    for (var k = 0; k < 19; k++) {
      precacheImage(AssetImage(wAsset('s${k.toString().padLeft(2, '0')}.webp')), context);
      for (final l in wLayers[k] ?? const <WL>[]) {
        precacheImage(AssetImage(wAsset(l.file)), context);
      }
    }
  }

  Future<void> _share(Wrapped w, WSlide s, bool square) async {
    if (s.private) {
      dToast(context, 'Цей слайд бачиш тільки ти, його не поширити');
      return;
    }
    final b = shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return;
    final img = await b.toImage(pixelRatio: 3);
    ui.Image out = img;
    if (square) {
      final side = img.height.toDouble();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(Rect.fromLTWH(0, 0, side, side), Paint()..color = _bgOf[_th[s.k.index].substring(1)] ?? _ink);
      c.drawImage(img, Offset((side - img.width) / 2, 0), Paint());
      out = await rec.endRecording().toImage(side.toInt(), side.toInt());
    }
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await shareBytesFile('vespr-wrapped-${w.month}-${i + 1}.png', data.buffer.asUint8List(), 'image/png');
  }

  void _shareSheet(Wrapped w, WSlide s) {
    var square = false;
    showSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Sheet(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text('Поділитися слайдом', style: pr(24))),
            Text('${i + 1} з ${w.slides.length}', style: rw(12, color: K.muted2)),
          ]),
          Tabs(items: const [('Сторіз 9:16', null), ('Квадрат 1:1', null)], index: square ? 1 : 0, onChanged: (v) => setS(() => square = v == 1)),
          Row(children: [
            for (final a in [('Сторіз', _icIg, const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF2A088), Color(0xFFC9796E), Color(0xFF6E6382)])), ('Telegram', _icTg, null), ('Зберегти', _icSave, null), ('Ще', _icMore, null)])
              Expanded(
                child: Press(
                  onTap: () {
                    Navigator.pop(ctx);
                    _share(w, s, square);
                  },
                  child: Column(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: a.$3,
                        color: a.$3 != null ? null : (a.$1 == 'Telegram' ? const Color(0xFF3B82C4) : K.hour),
                      ),
                      alignment: Alignment.center,
                      child: Ico(a.$2, size: 24, color: K.star),
                    ),
                    const SizedBox(height: 8),
                    Text(a.$1, style: rw(12, color: K.soft2, w: FontWeight.w500)),
                  ]),
                ),
              ),
          ]),
          Text(safe ? 'Без імен і подробиць. Лого Vespr лишається на картинці.' : 'Увага: на картинці будуть імена. Увімкни «Без імен» для сторіз.',
              style: rw(12, color: safe ? K.muted : K.accSoft, h: 1.45)),
          sheetCancel(ctx),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = Store.of(context);
    final w = buildWrapped(widget.month, st.db);
    final idx = i.clamp(0, w.slides.length - 1).toInt();
    final s = w.slides[idx];
    final th = _th[s.k.index];
    final darkChrome = th.startsWith('m') || th == 'q';
    final bg = _bgOf[th.substring(1)] ?? _ink;
    final locked = !st.profile.premium && idx >= freeSlides;

    void step(int d) {
      if (d > 0 && idx == w.slides.length - 1) {
        Navigator.maybePop(context);
        return;
      }
      setState(() => i = (idx + d).clamp(0, w.slides.length - 1).toInt());
    }

    final canvas = SizedBox(
      width: 390, height: 844,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        RepaintBoundary(
          key: shot,
          child: SizedBox(
            width: 390, height: 844,
            child: locked ? _Locked(s: s, left: w.slides.length - freeSlides) : _Slide(key: ValueKey(idx), s: s, w: w, safe: safe, dark: _darkBg.contains(s.k.index)),
          ),
        ),
        // прогрес
        Positioned(
          left: 24, right: 24, top: 54,
          child: Row(children: [
            for (var k = 0; k < w.slides.length; k++) ...[
              if (k > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0x597F788C)),
                  alignment: Alignment.centerLeft,
                  child: k <= idx ? Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: _darkBg.contains(s.k.index) ? K.star : const Color(0xFF17161F))) : null,
                ),
              ),
            ],
          ]),
        ),
        // тап-зони: третина зліва — назад, решта — далі
        Positioned(left: 0, top: 110, bottom: 90, width: 130, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => step(-1))),
        Positioned(left: 130, right: 0, top: 110, bottom: 90, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => step(1))),
        // керування
        Positioned(
          left: 16, right: 16, top: 772,
          child: Row(children: [
            Semantics(
              toggled: safe,
              button: true,
              child: Press(
                onTap: () => setState(() => safe = !safe),
                child: Container(
                  width: 120, height: 52,
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  decoration: BoxDecoration(color: const Color(0x8C17161F), borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    Text('Без імен', style: rw(13, w: FontWeight.w700)),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 34, height: 22,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: safe ? K.acc : K.w(.2), borderRadius: BorderRadius.circular(999)),
                      alignment: safe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Press(
                onTap: locked ? null : () => _shareSheet(w, s),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: darkChrome ? K.star : _ink, borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Ico(_icShare, size: 18, color: darkChrome ? const Color(0xFF17161F) : K.star),
                    const SizedBox(width: 8),
                    Text('Поділитися', style: rw(15, color: darkChrome ? const Color(0xFF17161F) : K.star, w: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Закрити',
              child: Press(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(color: Color(0x8C17161F), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Ico(_icClose, size: 18, color: K.star),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );

    return Scaffold(
      backgroundColor: bg,
      body: SizedBox.expand(child: FittedBox(fit: BoxFit.contain, child: canvas)),
    );
  }
}

/// Замок для безкоштовного плану після перших слайдів
class _Locked extends StatelessWidget {
  final WSlide s;
  final int left;
  const _Locked({required this.s, required this.left});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: Image.asset(wAsset('s${s.k.index.toString().padLeft(2, '0')}.webp'), fit: BoxFit.cover))),
        Positioned.fill(child: Container(color: const Color(0xB30E0D1F))),
        Positioned(
          left: 24, right: 24, bottom: 150,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ще $left', style: ws(48, FontWeight.w800, Colors.white, h: .93, ls: -2.4)),
            Text(plural(left, 'слайд', 'слайди', 'слайдів'), style: ws(48, FontWeight.w800, _pink, h: .93, ls: -2.4)),
            const SizedBox(height: 12),
            Text('Рекорди, Зала слави, матриця типажів і квиток для чату. Усе в повному Wrapped.', style: ws(14.5, FontWeight.w500, Colors.white, h: 1.4)),
            const SizedBox(height: 18),
            SizedBox(
              width: 260,
              child: Press(
                onTap: () => go(context, const PaywallScreen()),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: Text('Відкрити повний Wrapped', style: ws(15, FontWeight.w800, _ink)),
                ),
              ),
            ),
          ]),
        ),
      ]);
}

/// Слайд без панелі керування — для тесту верстки і знімків
@visibleForTesting
Widget wrappedSlideForTest(WSlide s, Wrapped w, {required bool safe}) => _Slide(s: s, w: w, safe: safe, dark: _darkBg.contains(s.k.index));

/// Один слайд: запечений фон + дані поверх
class _Slide extends StatelessWidget {
  final WSlide s;
  final Wrapped w;
  final bool safe, dark;
  const _Slide({super.key, required this.s, required this.w, required this.safe, required this.dark});

  bool get txtDark => !_darkBg.contains(s.k.index);
  Color get fg => txtDark ? _ink : Colors.white;

  Widget _title({String? line2, bool fit = false}) {
    final big = txtDark ? 48.0 : 46.0;
    final st = ws(big, FontWeight.w800, fg, h: .93, ls: -big * .05);
    final l2 = line2 ?? s.title2;
    final parts = l2.split('|');
    final lines = <Widget>[
      Text(s.title1, style: st),
      if (parts.length > 1) Text(parts.first, style: st),
      if (l2.isNotEmpty)
        fit
            ? FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(parts.last, maxLines: 1, style: st.copyWith(color: txtDark ? _ink : _pink)))
            : Text(parts.last, style: st.copyWith(color: txtDark ? _ink : _pink)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var k = 0; k < lines.length; k++) WAnim('wrUp', delay: 150 + k * 150, dur: 900, child: lines[k]),
    ]);
  }

  Widget _cap(String? t) => t == null || t.isEmpty
      ? const SizedBox.shrink()
      : SizedBox(width: 300, child: Text(t, style: txtDark ? ws(16, FontWeight.w500, _ink, h: 1.4) : ws(14.5, FontWeight.w500, Colors.white, h: 1.4)));

  Widget _body(List<Widget> xs) => Positioned(
        left: 24, right: 24, bottom: 150,
        child: Builder(builder: (_) {
          final items = xs.where((x) => x is! SizedBox || x.height != 0).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: gapped([
            for (var k = 0; k < items.length; k++) k == 0 ? items[k] : WAnim('wrUp', delay: 350 + k * 100, dur: 900, child: items[k]),
          ], 12));
        }),
      );

  Widget _pill(String t, Color bg, Color c, {double size = 15, EdgeInsets pad = const EdgeInsets.symmetric(horizontal: 10, vertical: 6)}) => Container(
        padding: pad,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(t, style: ws(size, FontWeight.w800, c, h: 1)),
      );

  Widget _ntag(String t, double cx, double cy, {Color bg = Colors.white}) => Positioned(
        left: cx - 90, top: cy - 30, width: 180, height: 60,
        child: Center(
          child: Transform.rotate(
            angle: _rot8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x800E0D1F), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -8)]),
              child: Text(t, style: ws(15, FontWeight.w800, _ink, h: 1)),
            ),
          ),
        ),
      );

  Widget _tape(double top, double deg, Color bg, Color c, String text, {double h = 46, double size = 19, int? sec}) => Positioned(
        left: -70, top: top, width: 530, height: h,
        child: Transform.rotate(
          angle: deg * math.pi / 180,
          child: Container(
            decoration: BoxDecoration(color: bg, boxShadow: const [BoxShadow(color: Color(0x8C0E0D1F), blurRadius: 28, offset: Offset(0, 14), spreadRadius: -14)]),
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.hardEdge,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: 4000,
              child: WMarquee(
                width: _textW(text.toUpperCase(), ws(size, FontWeight.w800, c, h: 1, ls: size * .04)) * 3,
                seconds: sec ?? (deg > 0 ? 22 : 18),
                reverse: deg > 0,
                child: Text((text * 12).toUpperCase(), maxLines: 1, softWrap: false, style: ws(size, FontWeight.w800, c, h: 1, ls: size * .04)),
              ),
            ),
          ),
        ),
      );

  List<Widget> _hearts(double v, Color c, {double w = 34, double h = 31, double step = 40}) => [
        for (var k = 0; k < 5; k++)
          Padding(
            padding: EdgeInsets.only(right: step - w),
            child: WAnim('wrPop', delay: 500 + k * 80, dur: 500, child: Transform.rotate(angle: _rot8, child: Ico(k < v.round() ? _heartOn : _heartOff, size: w, color: c))),
          ),
      ];

  Widget _fbl(List<WRow> rows, {List<Color>? colors}) => Column(
        children: gapped([
          for (var k = 0; k < rows.length; k++)
            Row(children: [
              SizedBox(
                width: 118,
                child: Text(rows[k].label,
                    style: ws(14, FontWeight.w700, _ink, h: 1.15, dec: rows[k].kind == 4 ? TextDecoration.lineThrough : null, decColor: _red)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(color: const Color(0x1F0E0D1F), borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.antiAlias,
                  child: WAnim('wrGrowX', delay: 500 + k * 120, dur: 900, child: FractionallySizedBox(
                    widthFactor: (double.tryParse(rows[k].sub ?? '') ?? 0).clamp(0.0, 1.0),
                    child: Container(decoration: BoxDecoration(color: (colors ?? const [_ink, _hot, _hot])[k.clamp(0, 2)], borderRadius: BorderRadius.circular(999))),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 50, child: Text(rows[k].value, textAlign: TextAlign.right, style: ws(17, FontWeight.w800, rows[k].kind == 4 ? _red : _ink, h: 1))),
            ]),
        ], 8),
      );

  @override
  Widget build(BuildContext context) {
    final img = wAsset('s${s.k.index.toString().padLeft(2, '0')}.webp');
    final logo = dark ? 'assets/img/logo.webp' : 'assets/img/logo_dark.webp';
    final ov = <Widget>[];
    final body = <Widget>[];

    switch (s.k) {
      case WK.cover:
        ov.add(_tape(412, -7, Colors.white, _ink, '${w.label} ✦ '));
        ov.add(_tape(458, 5, _yel, _ink, 'Секретно ✦ тільки для дівчат ✦ '));
        body.addAll([_title(), _cap(s.capSafe)]);
      case WK.receipt:
        ov.add(_Receipt(s: s));
        ov.add(Positioned(
          left: 304, top: 132, width: 60, height: 57,
          child: Transform.rotate(
            angle: _rot8,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(fmt(s.score), style: ws(26, FontWeight.w800, _ink, h: 1)),
              Text('середній\nбал', textAlign: TextAlign.center, style: ws(9.5, FontWeight.w700, _ink, h: 1.05)),
            ]),
          ),
        ));
      case WK.best:
        ov.add(_tape(398, -5, _ink, _yel, s.a));
        if (!safe) ov.add(_ntag(s.who.first.name, 302, 232));
        body.addAll([
          _title(),
          Row(children: [
            Container(
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(999)),
              child: Row(children: [Text(s.b, style: ws(26, FontWeight.w800, Colors.white, h: 1, ls: -1.04)), const SizedBox(width: 10), Text(s.c, style: ws(12.5, FontWeight.w600, Colors.white))]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 49,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  Text(s.score.isNaN ? '—' : fmt(s.score), style: ws(26, FontWeight.w800, _ink, h: 1, ls: -1.04)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${safe ? 'він' : s.who.first.name}\nяк людина', maxLines: 2, overflow: TextOverflow.ellipsis, style: ws(12.5, FontWeight.w600, _ink, h: 1.15))),
                ]),
              ),
            ),
          ]),
          _cap(s.capSafe),
        ]);
      case WK.sex:
        ov.add(Positioned(left: 109, top: 104, width: 172, height: 172, child: CustomPaint(painter: _Ring5(s.score))));
        ov.add(Positioned(
          left: 146, top: 141, width: 98, height: 98,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(fmt(s.score), style: ws(38, FontWeight.w800, _ink, h: 1)),
              Text('з 5', style: ws(12, FontWeight.w700, _ink)),
            ]),
          ),
        ));
        body.addAll([
          _title(),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x2EFFFFFF)))),
            child: Column(children: [
              for (final r in s.rows)
                Container(
                  height: 38,
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x2EFFFFFF)))),
                  child: Row(children: [
                    SizedBox(width: 98, child: Text(r.label, maxLines: 1, style: ws(12, FontWeight.w500, Colors.white))),
                    Expanded(child: Text(r.who != null ? r.who!.show(safe) : (r.sub ?? ''), overflow: TextOverflow.ellipsis, style: r.who != null && safe ? ws(12, FontWeight.w500, Colors.white) : ws(15, FontWeight.w700, Colors.white))),
                    _pill(r.value, r.kind == 3 ? _yel : _pink, _ink),
                  ]),
                ),
            ]),
          ),
          _cap(s.capSafe),
        ]);
      case WK.orgasm:
        body.add(_title());
        if (safe) {
          body.add(Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0x140E0D1F), borderRadius: BorderRadius.circular(14)),
            child: Text('Цей слайд бачиш тільки ти. У сторіз і «Без імен» його нема', style: ws(15, FontWeight.w600, _ink, h: 1.35)),
          ));
        } else {
          Widget hrow(String l, int v, Color c) => SizedBox(
                height: 31,
                child: Row(children: [
                  SizedBox(width: 50, child: Text(l, style: ws(15, FontWeight.w700, _ink))),
                  ..._hearts(s.score == 0 ? 0 : v / s.score * 5, c),
                  const Spacer(),
                  Text('$v із ${s.score.toInt()}', style: ws(20, FontWeight.w800, _ink, ls: -.6)),
                ]),
              );
          body.addAll([hrow('Ти', s.n1, _ink), hrow('Він', s.n2, _hot), _cap(s.capSafe)]);
        }
      case WK.match:
        if (!safe) {
          ov.add(Positioned(
            left: 156, top: 374, width: 218,
            child: Transform.rotate(
              angle: -5 * math.pi / 180,
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(s.who.first.name, maxLines: 1, style: pr(30, color: Colors.white, h: 1))),
                const SizedBox(height: 2),
                CustomPaint(size: const Size(170, 14), painter: _Swoosh()),
              ]),
            ),
          ));
        }
        Widget hb(String l, double v, Color c, bool top) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(top: top ? const BorderSide(color: Color(0x29FFFFFF)) : BorderSide.none, bottom: const BorderSide(color: Color(0x29FFFFFF)))),
              child: Row(children: [
                SizedBox(width: 96, child: Text(l, style: ws(16, FontWeight.w500, Colors.white, h: 1.1, ls: .16))),
                const SizedBox(width: 10),
                ..._hearts(v, c, w: 28, h: 26, step: 32),
                const Spacer(),
                Text(fmt(v), style: ws(22, FontWeight.w500, c, h: 1)),
              ]),
            );
        body.addAll([
          _title(),
          Column(children: [hb('Характер', s.score, _pink, true), hb('Секс', s.score2, _yel, false)]),
          if (s.a.isNotEmpty && s.b.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(children: [
                Text(s.a, style: ws(14, FontWeight.w500, Colors.white)),
                const SizedBox(width: 10),
                Text('✦', style: ws(14, FontWeight.w500, _pink)),
                const SizedBox(width: 10),
                Text(s.b, style: ws(14, FontWeight.w500, Colors.white)),
                const SizedBox(width: 10),
                Flexible(child: Text('· ${s.c}', overflow: TextOverflow.ellipsis, style: ws(14, FontWeight.w500, Colors.white.withValues(alpha: .62)))),
              ]),
            ),
        ]);
      case WK.matrix:
        // центри кружечків у картках 2×2: гаряче й безпечно, гаряче й токсично, надійно-нудно, навіщо
        const centers = [Offset(290, 200), Offset(130, 200), Offset(290, 368), Offset(130, 368)];
        const nameC = [_ink, Colors.white, _ink, _ink];
        for (var k = 0; k < s.who.length; k++) {
          var c = centers[s.ints[k]];
          if (s.ints.length > 1 && s.ints[0] == s.ints[1]) c = c.translate(k == 0 ? -26 : 26, k == 0 ? -10 : 14);
          ov.add(Positioned(
            left: c.dx - 43, top: c.dy - 43, width: 86, height: 86,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: _ink, border: Border.all(color: Colors.white, width: 6), boxShadow: const [BoxShadow(color: Color(0x800E0D1F), blurRadius: 22, offset: Offset(0, 14), spreadRadius: -10)]),
              alignment: Alignment.center,
              child: Text('?', style: ws(46, FontWeight.w800, _pink, h: 1)),
            ),
          ));
          if (!safe) {
            ov.add(Positioned(
              left: c.dx - 76, top: c.dy + 48, width: 152,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.who[k].name, textAlign: TextAlign.center, maxLines: 1, style: pr(20, color: nameC[s.ints[k]], h: 1))),
            ));
          }
        }
        body.addAll([_title(), _cap(s.cap(safe))]);
      case WK.battle:
        if (!safe) {
          final wi = s.who.length > 2 && s.who[2].id == s.who[1].id ? 1 : 0;
          Widget lab(String tag, String name, bool win, bool right) => Column(
                crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
                    decoration: BoxDecoration(color: win ? _ink : null, border: win ? null : Border.all(color: _ink, width: 1.5)),
                    child: Text(tag.toUpperCase(), style: mono(10, FontWeight.w600).copyWith(color: win ? _yel : _ink, letterSpacing: 1.4, height: 1)),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 165),
                    child: FittedBox(fit: BoxFit.scaleDown, alignment: right ? Alignment.centerRight : Alignment.centerLeft, child: Text(name.toUpperCase(), maxLines: 1, style: const TextStyle(fontFamily: 'Oswald', fontSize: 30, fontWeight: FontWeight.w600, color: _ink, height: 1, letterSpacing: .3))),
                  ),
                ],
              );
          ov.add(Positioned(left: 40, top: 98, child: Transform.rotate(angle: _rot8, child: lab('переможець', s.who[wi].name, true, false))));
          ov.add(Positioned(right: 26, top: 118, width: 168, child: Transform.rotate(angle: _rot8, alignment: Alignment.centerRight, child: Align(alignment: Alignment.centerRight, child: lab('суперник', s.who[1 - wi].name, false, true)))));
        }
        Widget hp(int k, bool left) => Expanded(
              child: Column(crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
                Text(safe ? 'Гравець ${k + 1}' : s.who[k].name, overflow: TextOverflow.ellipsis, style: ws(11, FontWeight.w500, _ink, h: 1)),
                const SizedBox(height: 5),
                Container(
                  height: 20,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: _ink, width: 2.5)),
                  alignment: left ? Alignment.centerLeft : Alignment.centerRight,
                  child: WAnim(left ? 'wrGrowX' : 'wrGrowXR', delay: 600, dur: 1000, child: FractionallySizedBox(widthFactor: ((left ? s.n1 : s.n2) / 100).clamp(0.0, 1.0), child: Container(color: left ? _ink : _red))),
                ),
                const SizedBox(height: 5),
                Text('${left ? s.n1 : s.n2}%', style: ws(11, FontWeight.w500, _ink, h: 1)),
              ]),
            );
        body.addAll([
          _title(),
          SizedBox(
            height: 55,
            child: Row(children: [
              hp(0, true),
              WAnim('wrPop', delay: 700, dur: 500, child: Transform.rotate(
                angle: _rot8,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
                  decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(8), border: Border.all(color: _ink, width: 2)),
                  child: Text('K.O.', style: ws(18, FontWeight.w700, _yel, h: 1)),
                ),
              )),
              hp(1, false),
            ]),
          ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x330E0D1F)))),
            child: Column(children: [
              for (final r in s.rows)
                Container(
                  height: 38,
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x330E0D1F)))),
                  child: Row(children: [
                    Expanded(child: Text(r.label, style: ws(14.5, FontWeight.w500, _ink))),
                    for (final v in [(r.value, r.kind == 1), (r.sub ?? '', r.kind == 2)])
                      Container(
                        width: 38, height: 27,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(color: v.$2 ? _ink : null, borderRadius: BorderRadius.circular(999)),
                        alignment: Alignment.center,
                        child: Text(v.$1, style: ws(15, FontWeight.w600, v.$2 ? _yel : _ink.withValues(alpha: .55), h: 1)),
                      ),
                  ]),
                ),
            ]),
          ),
          _cap(s.cap(safe)),
        ]);
      case WK.phone:
        final f = s.flags.length > 5 ? s.flags.sublist(s.flags.length - 5) : s.flags;
        body.addAll([
          _title(),
          Container(
            height: 58,
            padding: const EdgeInsets.fromLTRB(10, 0, 18, 0),
            decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(999)),
            child: Row(children: [
              for (final (n, p) in f.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: WAnim('wrPop', delay: 500 + n * 90, dur: 500, child: Transform.rotate(
                    angle: _rot8,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: p ? Colors.white : _pink),
                      alignment: Alignment.center,
                      child: Ico(p ? _icPhone : _icHeart2, size: 22, color: p ? _ink : const Color(0xFFE2246B)),
                    ),
                  )),
                ),
              const Spacer(),
              Text('${s.n1} : ${s.n2}', style: ws(26, FontWeight.w800, _yel, ls: -.78)),
            ]),
          ),
          _cap(s.cap(safe)),
        ]);
      case WK.fame:
        if (!safe) ov.add(_ntag('MVP місяця', 302, 284));
        body.addAll([_title(line2: safe ? s.title2 : s.who.first.name, fit: !safe), _fbl(s.rows), _cap(s.capSafe)]);
      case WK.longest:
      case WK.fastest:
        final fast = s.k == WK.fastest;
        final icons = fast ? [_icTimer, _icPerson, _icHeartO] : [_icTimer, _icPerson, _icRepeat];
        body.addAll([
          _title(),
          Column(
            children: gapped([
              for (var k = 0; k < s.rows.length; k++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
                  child: Row(children: [
                    Ico(icons[k.clamp(0, 2)], size: 28, color: fast && k == 2 ? Colors.white : _pink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${s.rows[k].who == null ? '' : (safe ? s.rows[k].who!.safe.split(' ').first : s.rows[k].who!.name)}${s.rows[k].label}', maxLines: 2, style: ws(15, FontWeight.w700, _pink, h: 1.2)),
                    ),
                    _pill(s.rows[k].value, const Color(0xFF2E2A44), Colors.white, size: 15, pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                  ]),
                ),
            ], 8),
          ),
        ]);
      case WK.budget:
        const tilt = -8 * math.pi / 180;
        ov.add(Positioned(left: 34, top: 452, width: 322, child: Text('витратив на тебе за ${w.monthNom}'.toUpperCase(), style: mt(8.4, FontWeight.w400, Colors.white.withValues(alpha: .78), h: 1, ls: 1.09))));
        ov.add(Positioned(
          left: 34, top: 458, width: 322,
          child: WAnim('wrPop', delay: 200, dur: 800, child: Transform.rotate(
            angle: tilt,
            child: Text.rich(TextSpan(children: [
              TextSpan(text: s.a, style: cg(72, FontWeight.w500, Colors.white, h: 1, ls: -.72)),
              const WidgetSpan(child: SizedBox(width: 6)),
              TextSpan(text: 'грн', style: cg(26, FontWeight.w500, _rose, it: true, h: 1)),
            ])),
          )),
        ));
        ov.add(Positioned(
          left: 34, top: 552, width: 322,
          child: WAnim('wrPop', delay: 300, dur: 800, child: Transform.rotate(
            angle: tilt,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title1, style: cg(40, FontWeight.w500, Colors.white, h: 1.02)),
              Text(s.title2, style: cg(44, FontWeight.w500, _rose, it: true, h: 1.02)),
            ]),
          )),
        ));
        ov.add(Positioned(
          left: 34, top: 650, width: 322,
          child: WAnim('wrUp', delay: 450, dur: 900, child: Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x38FFFFFF)))),
            child: Column(children: [
              for (var k = 0; k < s.rows.length; k++)
                Container(
                  height: 32,
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x38FFFFFF)))),
                  child: Row(children: [
                    Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.rows[k].kind == 5 ? const Color(0xFFF3D9A4) : (s.rows[k].kind == 6 ? _rose : null),
                        border: s.rows[k].kind == 7 ? Border.all(color: _rose, width: 1.5) : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(width: 96, child: Text(s.rows[k].label, maxLines: 1, style: mt(12, FontWeight.w300, Colors.white, h: 1))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(999)),
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.antiAlias,
                        child: WAnim('wrGrowX', delay: 600 + k * 150, dur: 1100, child: FractionallySizedBox(
                          widthFactor: (double.tryParse(s.rows[k].sub ?? '') ?? 0).clamp(0.0, 1.0) * .87,
                          child: Container(decoration: BoxDecoration(color: s.rows[k].kind == 5 ? const Color(0xFFF3D9A4) : _rose, borderRadius: BorderRadius.circular(999))),
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 50, child: Text(s.rows[k].value, textAlign: TextAlign.right, style: mt(12, FontWeight.w300, Colors.white, h: 1))),
                  ]),
                ),
            ]),
          )),
        ));
        ov.add(Positioned(
          left: 34, top: 760, width: 322, height: 20,
          child: WAnim('wrUp', delay: 600, dur: 900, child: Row(children: [
            if (s.n2 <= 8)
              for (var k = 0; k < s.n2; k++)
                Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: k < s.n1 ? _rose : null, border: Border.all(color: k < s.n1 ? _rose : const Color(0x99FFFFFF))),
                ),
            Container(
              margin: EdgeInsets.only(left: s.n2 <= 8 ? 8 : 0),
              padding: EdgeInsets.only(left: s.n2 <= 8 ? 16 : 0),
              decoration: s.n2 <= 8 ? const BoxDecoration(border: Border(left: BorderSide(color: Color(0x47FFFFFF)))) : null,
              height: 20,
              alignment: Alignment.centerLeft,
              child: Text(s.c, maxLines: 1, style: mt(12, FontWeight.w300, Colors.white, h: 1)),
            ),
          ].map((x) => x is Container && x.child is Text ? Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: x)) : x).toList())),
        ));
        ov.add(Positioned(
          left: 34, top: 808, width: 322,
          child: WAnim('wrUp', delay: 700, dur: 900, child: Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x38FFFFFF)))),
            child: Text(s.capSafe ?? '', style: cg(17, FontWeight.w500, const Color(0xEBFFFFFF), it: true, h: 1.2)),
          )),
        ));
      case WK.wishes:
        ov.add(Positioned(left: 93, top: 118, width: 204, height: 204, child: CustomPaint(painter: _RingN(s.n1, s.n2))));
        ov.add(Positioned(
          left: 137, top: 162, width: 116, height: 116,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF6F2F4), boxShadow: [BoxShadow(color: Color(0x400E0D1F), blurRadius: 18, offset: Offset(0, 6))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${s.n1}/${s.n2}', style: ws(38, FontWeight.w800, _ink, h: 1)),
              Text('вийшло', style: ws(12, FontWeight.w700, _ink)),
            ]),
          ),
        ));
        body.addAll([
          _title(),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x330E0D1F), width: 1.5))),
            child: Column(children: [
              for (final r in s.rows)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x330E0D1F), width: 1.5))),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: r.kind == 2 ? _ink : Colors.white),
                      alignment: Alignment.center,
                      child: Ico(r.kind == 2 ? _icCheck : _icX, size: 20, color: r.kind == 2 ? _yel : _red),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.label, style: ws(15, FontWeight.w700, _ink, h: 1.2, dec: r.kind == 4 ? TextDecoration.lineThrough : null, decColor: _red)),
                        Text(r.sub ?? '', style: ws(12, FontWeight.w500, _ink.withValues(alpha: .6), h: 1.2)),
                      ]),
                    ),
                  ]),
                ),
            ]),
          ),
        ]);
      case WK.notice:
        Widget card(Widget icon, String b, String sm) => Container(
              width: 230,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0x6B1C120E), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x47FFFFFF))),
              child: Row(children: [
                SizedBox(width: 30, child: Align(alignment: Alignment.centerLeft, child: icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b, style: cg(17, FontWeight.w600, Colors.white, h: 1.08)),
                    const SizedBox(height: 6),
                    Text(sm, style: mt(9.6, FontWeight.w400, const Color(0xD1FFFFFF), h: 1.3)),
                  ]),
                ),
              ]),
            );
        final cards = safe
            ? [card(Ico(_icEye, size: 26, color: _rose), 'Цей слайд бачиш тільки ти', 'У сторіз і «Без імен» його нема.')]
            : [
                for (final r in s.rows)
                  card(Ico(r.kind == 11 ? _icShield : _icChat, size: 26, color: _rose), r.label, '${r.value}${r.who != null && !r.value.contains('той самий') ? ', з ${r.who!.name}' : ''}'),
              ];
        ov.add(Positioned(
          left: 30, top: 318,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var k = 0; k < cards.length; k++)
              Padding(padding: const EdgeInsets.only(bottom: 7), child: WAnim('wrUp', delay: 350 + k * 150, dur: 900, child: cards[k])),
          ]),
        ));
        ov.add(Positioned(
          left: 30, right: 30, top: 716,
          child: WAnim('wrUp', delay: 650, dur: 900, child: Text(s.capSafe ?? '', style: cg(16, FontWeight.w500, const Color(0xE6FFFFFF), it: true, h: 1.3))),
        ));
      case WK.awards:
        body.addAll([
          _title(),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x330E0D1F)))),
            child: Column(children: [
              for (final r in s.rows)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x330E0D1F)))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.label, style: ws(15, FontWeight.w800, _ink, h: 1.2)),
                    const SizedBox(height: 2),
                    Text(r.sub ?? '', style: ws(13, FontWeight.w500, _ink, h: 1.3)),
                  ]),
                ),
            ]),
          ),
        ]);
      case WK.glow:
        ov.add(_Calendar(month: s.a, best: s.ints.first, firstWeekday: s.ints.length > 1 ? s.ints[1] : 1));
        for (var k = 0; k < s.rows.length && k < 3; k++) {
          ov.add(Positioned(left: 24.0 + k * 118, top: 222, width: 106, height: 150, child: _Bars(r: s.rows[k], prev: s.b, cur: s.c, color: k == 1 ? _yel : _pink)));
        }
        body.addAll([_title(), _cap(s.capSafe)]);
      case WK.closed:
        final moments = s.rows.where((r) => r.kind != 9).toList();
        final nums = s.rows.where((r) => r.kind == 9).toList();
        final rib = '${(s.capSafe ?? '').replaceAll('. ', ' ✦ ').replaceAll(RegExp(r'\.$'), '')} ✦ ';
        ov.add(_tape(712, -3, _ink, _pink, rib, h: 34, size: 14, sec: 22));
        ov.add(Positioned(
          left: 26, right: 26, top: 330,
          child: WAnim('wrUp', delay: 200, dur: 900, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.title1},', style: cg(56, FontWeight.w500, _ink, h: .9, ls: -.56)),
            Text(s.title2, style: cg(56, FontWeight.w500, _plum, it: true, h: .9, ls: -.56)),
          ])),
        ));
        final h4 = mt(8.6, FontWeight.w500, _ink.withValues(alpha: .75), h: 1, ls: 1.72);
        ov.add(Positioned(
          left: 26, right: 26, top: 450,
          child: WAnim('wrUp', delay: 400, dur: 900, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 125,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (moments.isNotEmpty) Text('ТОП-МОМЕНТИ', style: h4),
                const SizedBox(height: 10),
                for (var k = 0; k < moments.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 18, child: Text('${k + 1}', style: cg(16, FontWeight.w500, _plum, h: 1.1))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(moments[k].label, maxLines: 1, overflow: TextOverflow.ellipsis, style: cg(18, FontWeight.w500, _ink, it: true, h: 1)),
                          const SizedBox(height: 3),
                          Text(
                            [if (moments[k].who != null) safe ? 'він' : moments[k].who!.name, if (moments[k].value.isNotEmpty) moments[k].value].join(' · ').toUpperCase(),
                            maxLines: 2,
                            style: mt(8.6, FontWeight.w400, _ink.withValues(alpha: .75), h: 1.4, ls: 1.2),
                          ),
                        ]),
                      ),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 100,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ТВОЇ ЧИСЛА', style: h4),
                const SizedBox(height: 10),
                for (final r in nums)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(r.value, style: cg(32, FontWeight.w600, _plum, h: .95)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(r.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: mt(8.6, FontWeight.w400, _ink.withValues(alpha: .8), h: 1, ls: 1.38))),
                    ]),
                  ),
              ]),
            ),
          ])),
        ));
        ov.add(Positioned(
          left: 26, right: 26, top: 762, height: 23,
          child: Row(children: [
            Text(s.a.toUpperCase(), style: mt(9, FontWeight.w500, _ink, h: 1, ls: 1.62)),
            const Spacer(),
            Container(
              height: 23,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(999)),
              child: Text(s.b.toUpperCase(), style: mt(9, FontWeight.w500, _yel, h: 1, ls: 1.62)),
            ),
          ]),
        ));
      case WK.ticket:
        ov.add(Positioned(
          left: 44, top: 150, width: 231,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Мій ${w.monthNom}', style: ws(20, FontWeight.w800, _ink, h: 1.2)),
            const SizedBox(height: 7),
            for (final r in [
              ('Побачень', '${s.n1}'),
              ('MVP', safe ? s.a : s.who.first.name),
              ('Зашкварик', s.b),
              ('Нагород', '+${s.n2}'),
            ])
              CustomPaint(
                foregroundPainter: _Dash(bottom: true),
                child: SizedBox(
                height: 24,
                child: Row(children: [
                  Text(r.$1, style: ws(13, FontWeight.w600, _ink)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.$2, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: ws(13, FontWeight.w800, _ink))),
                ]),
              )),
          ]),
        ));
        body.addAll([_title(), _cap(s.capSafe)]);
    }

    String ovAnim() => switch (s.k) {
          WK.sex || WK.wishes => 'wrSpinIn',
          WK.receipt || WK.ticket => 'wrUp',
          WK.match || WK.battle => 'wrPop',
          _ => 'wrStc',
        };
    final ovA = [
      for (final (n, x) in ov.indexed)
        x is Positioned && x.child is! OverflowBox && !(s.k == WK.cover || s.k == WK.budget || s.k == WK.notice || s.k == WK.closed || (s.k == WK.best && n == 0))
            ? Positioned(left: x.left, top: x.top, right: x.right, bottom: x.bottom, width: x.width, height: x.height, child: WAnim(ovAnim(), delay: 200 + n * 120, dur: 900, child: x.child))
            : x,
    ];
    return Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(child: Image.asset(img, fit: BoxFit.fill, frameBuilder: (_, child, frame, sync) => frame == null && !sync ? ColoredBox(color: _darkBg.contains(s.k.index) ? _ink : (_bgOf[_th[s.k.index].substring(1)] ?? _ink)) : child)),
      ...wrappedLayers(s.k.index),
      ...ovA,
      // шапка
      Positioned(
        left: 24, right: 24, top: 70, height: 28,
        child: Row(children: [
          Image.asset(logo, width: 84, semanticLabel: 'Vespr'),
          const Spacer(),
          Text(w.label, style: s.k == WK.budget || s.k == WK.notice ? cg(15, FontWeight.w500, Colors.white, h: 1) : ws(13, FontWeight.w600, dark ? Colors.white : _ink)),
        ]),
      ),
      if (body.isNotEmpty) _body(body),
      ...wrappedLayers(s.k.index, above: true),
    ]);
  }

  Widget _calm(String b, String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF25222F), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b, style: rw(15, w: FontWeight.w700, h: 1.45)),
          const SizedBox(height: 3),
          Text(t, style: rw(13, color: const Color(0xFFB9B4CB), h: 1.45)),
        ]),
      );
}

/// Текст чека на запеченому папері
class _Receipt extends StatelessWidget {
  final WSlide s;
  const _Receipt({required this.s});
  @override
  Widget build(BuildContext context) {
    final rows = s.rows.take(6).toList();
    Widget line(String l, String r, {Color? rc, double size = 12.5, bool totRow = false}) => SizedBox(
          height: 22,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l.toUpperCase(), style: mono(size, totRow ? FontWeight.w600 : FontWeight.w500)),
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(6, 0, 6, 5), child: CustomPaint(size: const Size(double.infinity, 1), painter: _Dots()))),
            Text(r.toUpperCase(), style: totRow ? ws(19, FontWeight.w800, const Color(0xFF2B2830), h: 1) : mono(size, FontWeight.w600).copyWith(color: rc)),
          ]),
        );
    Widget hr(double top) => Positioned(left: 65, top: top, width: 260, height: 1, child: CustomPaint(painter: _Dash()));
    return Positioned.fill(
      child: Stack(children: [
        Positioned(left: 65, top: 158, width: 260, child: Text('VESPR', textAlign: TextAlign.center, style: ws(22, FontWeight.w800, const Color(0xFF2B2830), h: 1, ls: 4.4))),
        Positioned(left: 65, top: 225, width: 260, child: Text(s.title1, textAlign: TextAlign.center, style: ws(21, FontWeight.w800, const Color(0xFF2B2830), h: 1.05, ls: -.42))),
        Positioned(
          left: 65, top: 257, width: 260,
          child: Row(children: [Text(s.a, style: mono(10.5, FontWeight.w500)), const Spacer(), Text(s.b, style: mono(10.5, FontWeight.w500))]),
        ),
        hr(280),
        for (var k = 0; k < rows.length; k++)
          Positioned(
            left: 65, top: 290 + k * 22.3, width: 260,
            child: line(rows[k].label, rows[k].value, rc: rows[k].kind == 1 ? const Color(0xFFC9302C) : (rows[k].kind == 2 ? const Color(0xFF24804A) : null)),
          ),
        hr(433),
        Positioned(left: 65, top: 443, width: 260, child: line('Середній бал', '${fmt(s.score)} / 5', size: 14, totRow: true)),
        Positioned(left: 65, top: 466, width: 260, child: line('Решта', '0 нервів', size: 11)),
        Positioned(left: 65, top: 549, width: 260, child: Text('ДЯКУЄМО, ЩО ОБРАЛИ НАС\nПОВЕРНЕННЯ НЕ ПРИЙМАЮТЬСЯ', textAlign: TextAlign.center, style: mono(10, FontWeight.w500, h: 1.38))),
      ]),
    );
  }
}

class _Dots extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0x802B2830);
    for (var x = 0.0; x < s.width; x += 4) {
      c.drawCircle(Offset(x, 0), .7, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _Dash extends CustomPainter {
  final bool bottom; // пунктир по нижньому краю (рядки квитка)
  _Dash({this.bottom = false});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = bottom ? const Color(0x660E0D1F) : const Color(0x802B2830)
      ..strokeWidth = 1;
    final y = bottom ? s.height - .5 : 0.0;
    for (var x = 0.0; x < s.width; x += 6) {
      c.drawLine(Offset(x, y), Offset(x + 3, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Кільце з п'яти сегментів (оцінка 1–5)
class _Ring5 extends CustomPainter {
  final double v;
  _Ring5(this.v);
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 200;
    final rect = Rect.fromCircle(center: Offset(s.width / 2, s.height / 2), radius: 78 * k);
    for (var i = 0; i < 5; i++) {
      final start = (-90 + 2.5 + i * 72) * math.pi / 180;
      const sweep = 67 * math.pi / 180;
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26 * k
        ..color = const Color(0x24FFFFFF);
      c.drawArc(rect, start, sweep, false, base);
      final f = (v.isNaN ? 0.0 : v - i).clamp(0.0, 1.0);
      if (f > 0) c.drawArc(rect, start, sweep * f, false, base..color = i.isEven ? _pink : _yel);
    }
  }

  @override
  bool shouldRepaint(covariant _Ring5 o) => o.v != v;
}

/// Кільце «вийшло N із M»
class _RingN extends CustomPainter {
  final int ok, all;
  _RingN(this.ok, this.all);
  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromCircle(center: Offset(s.width / 2, s.height / 2), radius: s.width / 2 - 20);
    final n = all < 1 ? 1 : all;
    final seg = 360 / n;
    for (var i = 0; i < n; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..color = i < ok ? _ink : const Color(0x80FFFFFF);
      c.drawArc(rect, (-90 + 3 + i * seg) * math.pi / 180, (seg - 6) * math.pi / 180, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingN o) => o.ok != ok || o.all != all;
}

/// Календар місяця на запеченому аркуші (дні 1–28 і найкращий вечір)
class _Calendar extends StatelessWidget {
  final String month;
  final int best, firstWeekday;
  const _Calendar({required this.month, required this.best, required this.firstWeekday});
  @override
  Widget build(BuildContext context) => Positioned(
        left: 42, top: 110, width: 202,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(month, style: ws(14, FontWeight.w800, _ink, h: 1.1)),
          const SizedBox(height: 6),
          for (var row = 0; row < 4; row++)
            Row(children: [
              for (var col = 0; col < 7; col++)
                Builder(builder: (_) {
                  final d = row * 7 + col + 1;
                  final hit = d == best;
                  return SizedBox(
                    width: 28.8, height: row == 3 ? 20 : 18,
                    child: Center(
                      child: Container(
                        width: hit ? 26 : null, height: hit ? 18 : null,
                        decoration: hit ? BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: _hot, width: 1.6)) : null,
                        alignment: Alignment.center,
                        child: Text('$d', style: ws(9.5, FontWeight.w600, hit ? _hot : _ink)),
                      ),
                    ),
                  );
                }),
            ]),
        ]),
      );
}

/// Два стовпчики «було / стало» на запеченій картці
class _Bars extends StatelessWidget {
  final WRow r;
  final String prev, cur;
  final Color color;
  const _Bars({required this.r, required this.prev, required this.cur, required this.color});
  @override
  Widget build(BuildContext context) {
    double num(String x) => double.tryParse(x.replaceAll(',', '.')) ?? 0;
    final a = num(r.sub ?? '0'), b = num(r.value);
    final mx = math.max(math.max(a, b), .1);
    double h(double v) => 10 + 52 * (v / mx);
    final good = color;
    final up = b >= a;
    Widget bar(double v, String t, Color c) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(t, style: ws(12, FontWeight.w800, Colors.white)),
          const SizedBox(height: 4),
          WAnim('wrGrow', delay: 600, dur: 800, child: Container(width: 29, height: h(v), decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))))),
        ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.label.toUpperCase(), style: ws(11, FontWeight.w700, Colors.white, ls: .3))),
        ]),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            bar(a, r.sub ?? '', const Color(0xFF55525F)),
            const SizedBox(width: 6),
            bar(b, r.value, good),
            const Spacer(),
            Padding(padding: const EdgeInsets.only(bottom: 56), child: Text(up ? '↗' : '↘', style: ws(22, FontWeight.w800, good, h: 1))),
          ]),
        ),
        const SizedBox(height: 4),
        Row(children: [
          SizedBox(width: 29, child: Text(prev, textAlign: TextAlign.center, style: ws(9, FontWeight.w600, Colors.white.withValues(alpha: .7)))),
          const SizedBox(width: 6),
          SizedBox(width: 29, child: Text(cur, textAlign: TextAlign.center, style: ws(9, FontWeight.w600, Colors.white.withValues(alpha: .7)))),
        ]),
      ]),
    );
  }
}

// =====================================================================
// Архів: «Твої місяці»
// =====================================================================
class WrappedArchiveScreen extends StatelessWidget {
  const WrappedArchiveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final now = DateTime.now();
    final cur = iso(now).substring(0, 7);
    final first = s.entries.isEmpty ? cur : (s.entries.map((e) => monthKey(e.date)).toList()..sort()).first;
    final months = <String>[];
    var d = DateTime(now.year, now.month - 1, 1);
    while (iso(d).substring(0, 7).compareTo(first) >= 0 && months.length < 24) {
      months.add(iso(d).substring(0, 7));
      d = DateTime(d.year, d.month - 1, 1);
    }
    String mName(String m) => cap(monthsNom[int.parse(m.substring(5)) - 1]);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    Widget card(String m, {bool big = false}) {
      final t = wrappedTeaser(m, s.db);
      final txt = big ? _ink : K.star;
      return Press(
        onTap: () => go(context, WrappedScreen(month: m)),
        child: Container(
          height: big ? 196 : 176,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: big
                ? const LinearGradient(begin: Alignment(-.3, -1), end: Alignment(.3, 1), colors: [Color(0xFFF2A088), Color(0xFFF08A6C), Color(0xFFD9775F)], stops: [0, .45, 1])
                : const LinearGradient(begin: Alignment(-.3, -1), end: Alignment(.3, 1), colors: [Color(0xFF3A3446), Color(0xFF25222F)]),
            border: big ? null : Border.all(color: K.w(.06)),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(big ? '${mName(m)} ${m.substring(0, 4)}' : mName(m), style: rw(12, color: big ? _ink : K.muted2, w: FontWeight.w600)),
              const Spacer(),
              if (big)
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(t.$1, style: pr(96, color: txt, h: .85, ls: -.03)),
                  const SizedBox(width: 14),
                  Flexible(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t.$2, style: pr(18, color: txt, h: 1.3))))),
                ])
              else ...[
                Text(t.$1, style: pr(64, color: K.accSoft, h: .85, ls: -.03)),
                const Spacer(),
                Text(t.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: pr(14, color: txt, h: 1.3)),
              ],
            ]),
            if (big)
              Positioned(
                right: -4, top: -4, // 12/12 від краю картки (відступ 16 мінус 4)
                child: Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(color: const Color(0xFF17161F), borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: Text('Новий', style: rw(11, w: FontWeight.w600)),
                ),
              ),
          ]),
        ),
      );
    }

    const lockC = Color(0xFF9A94B0);
    final lockCard = CustomPaint(
      foregroundPainter: _DashBox(K.w(.12), 24),
      child: Container(
        height: 176,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: K.w(.025)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cap(monthsNom[now.month - 1]), style: rw(12, color: lockC, w: FontWeight.w600)),
          const Spacer(),
          Row(children: [Ico(BS.lock, size: 14, color: lockC), const SizedBox(width: 8), Text('$lastDay ${monthsGen[now.month - 1]}', style: rw(13, color: lockC))]),
        ]),
      ),
    );

    final grid = <Widget>[...months.skip(1).map((m) => card(m)), lockCard];
    return DScroll(
      gap: 18,
      children: [
        const BoardHeader('Wrapped'),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Твої місяці', style: pr(34, h: 1.1)),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text("Новий Wrapped з'являється в останній день місяця.", maxLines: 1, style: rw(14, color: K.muted2, h: 1.5))),
        ]),
        Column(children: gapped([
          if (months.isNotEmpty) card(months.first, big: true),
          for (var k = 0; k < grid.length; k += 2)
            Row(children: [
              Expanded(child: grid[k]),
              const SizedBox(width: 10),
              Expanded(child: k + 1 < grid.length ? grid[k + 1] : const SizedBox()),
            ]),
        ], 10)),
      ],
    );
  }
}

/// Пунктирна рамка (border: 1px dashed)
class _DashBox extends CustomPainter {
  final Color c;
  final double r;
  const _DashBox(this.c, this.r);
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & s).deflate(.5), Radius.circular(r)));
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashBox o) => o.c != c;
}

/// Рожевий розчерк під іменем на «Метчі»
class _Swoosh extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 170;
    final p = Path()
      ..moveTo(2 * k, 9 * k)
      ..cubicTo(32 * k, 3 * k, 60 * k, 1 * k, 94 * k, 4 * k)
      ..cubicTo(120 * k, 6 * k, 142 * k, 8 * k, 168 * k, 3 * k);
    c.drawPath(p, Paint()..color = _pink..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
