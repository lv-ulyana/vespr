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
const _th = ['m1', 'l2', 'l3', 'm1', 'l3', 'm1', 'l2', 'l3', 'l2', 'l3', 'm1', 'm3', 'l2', 'l3', 'q', 'l3', 'l2', 'm1', 'l3'];
const _bgOf = {'1': _ink, '2': _pink, '3': _yel, '': Color(0xFF17161F)};

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
      precacheImage(AssetImage('assets/wrapped/s${k.toString().padLeft(2, '0')}.webp'), context);
      for (final l in wLayers[k] ?? const <WL>[]) {
        precacheImage(AssetImage('assets/wrapped/${l.file}'), context);
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
            child: locked ? _Locked(s: s, left: w.slides.length - freeSlides) : _Slide(key: ValueKey(idx), s: s, w: w, safe: safe, dark: darkChrome),
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
                  child: k <= idx ? Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: darkChrome ? K.star : const Color(0xFF17161F))) : null,
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
        Positioned.fill(child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: Image.asset('assets/wrapped/s${s.k.index.toString().padLeft(2, '0')}.webp', fit: BoxFit.cover))),
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

/// Один слайд: запечений фон + дані поверх
class _Slide extends StatelessWidget {
  final WSlide s;
  final Wrapped w;
  final bool safe, dark;
  const _Slide({super.key, required this.s, required this.w, required this.safe, required this.dark});

  bool get txtDark => !(_th[s.k.index] == 'm1' || _th[s.k.index] == 'q');
  Color get fg => txtDark ? _ink : Colors.white;

  Widget _title({String? line2}) {
    final big = txtDark ? 48.0 : 46.0;
    final st = ws(big, FontWeight.w800, fg, h: .93, ls: -big * .05);
    final l2 = line2 ?? s.title2;
    final parts = l2.split('|');
    final lines = <Widget>[
      Text(s.title1, style: st),
      if (parts.length > 1) Text(parts.first, style: st),
      if (l2.isNotEmpty) Text(parts.last, style: st.copyWith(color: txtDark ? _ink : _pink)),
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

  Widget _tape(double top, double deg, Color bg, Color c, String text) => Positioned(
        left: -70, top: top, width: 530, height: 46,
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
                width: _textW(text.toUpperCase(), ws(19, FontWeight.w800, c, h: 1, ls: .76)) * 3,
                seconds: deg > 0 ? 22 : 18,
                reverse: deg > 0,
                child: Text((text * 12).toUpperCase(), maxLines: 1, softWrap: false, style: ws(19, FontWeight.w800, c, h: 1, ls: .76)),
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
    final img = 'assets/wrapped/s${s.k.index.toString().padLeft(2, '0')}.webp';
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
        if (!safe) ov.add(_ntag(s.who.first.name, 294, 386));
        Widget hb(String l, double v, Color c, bool top) => Container(
              height: 56,
              decoration: BoxDecoration(border: Border(top: top ? const BorderSide(color: Color(0x29FFFFFF)) : BorderSide.none, bottom: const BorderSide(color: Color(0x29FFFFFF)))),
              child: Row(children: [
                SizedBox(
                  width: 106,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l, style: ws(15, FontWeight.w700, Colors.white)),
                    Text(safe ? 'він' : s.who.first.name, overflow: TextOverflow.ellipsis, style: ws(12, FontWeight.w500, Colors.white.withValues(alpha: .7))),
                  ]),
                ),
                ..._hearts(v, c, w: 28, h: 26, step: 32),
                const Spacer(),
                Text(fmt(v), style: ws(22, FontWeight.w800, c)),
              ]),
            );
        body.addAll([
          _title(),
          Column(children: [hb('Характер', s.score, _pink, true), hb('Секс', s.score2, _yel, false)]),
          if (s.a.isNotEmpty && s.b.isNotEmpty)
            Row(children: [
              _pill(s.a, Colors.white, _ink, size: 14, pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('+', style: ws(16, FontWeight.w800, _yel))),
              _pill(s.b, Colors.white, _ink, size: 14, pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              const SizedBox(width: 10),
              Flexible(child: Text(s.c, style: ws(13, FontWeight.w600, Colors.white))),
            ]),
        ]);
      case WK.matrix:
        const centers = [Offset(300, 242), Offset(144, 254), Offset(290, 330), Offset(130, 335)];
        for (var k = 0; k < s.who.length; k++) {
          var c = centers[s.ints[k]];
          if (k == 1 && s.ints[0] == s.ints[1]) c = c.translate(0, 70);
          ov.add(Positioned(
            left: c.dx - 50, top: c.dy - 50, width: 100, height: 100,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: _ink, border: Border.all(color: Colors.white, width: 5), boxShadow: const [BoxShadow(color: Color(0x660E0D1F), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -8)]),
              alignment: Alignment.center,
              child: Text('?', style: ws(46, FontWeight.w800, _pink, h: 1)),
            ),
          ));
          if (!safe) ov.add(_ntag(s.who[k].name, c.dx, c.dy + 56));
        }
        body.addAll([_title(), _cap(s.cap(safe))]);
      case WK.battle:
        if (!safe) ov.add(_ntag('Переможець', 126, 279, bg: _pink));
        Widget hp(int k, bool left) => Expanded(
              child: Column(crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
                Text(safe ? 'Гравець ${k + 1}' : s.who[k].name, overflow: TextOverflow.ellipsis, style: ws(11, FontWeight.w700, _ink, h: 1)),
                const SizedBox(height: 5),
                Container(
                  height: 20,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: _ink, width: 2.5)),
                  alignment: left ? Alignment.centerLeft : Alignment.centerRight,
                  child: WAnim(left ? 'wrGrowX' : 'wrGrowXR', delay: 600, dur: 1000, child: FractionallySizedBox(widthFactor: ((left ? s.n1 : s.n2) / 100).clamp(0.0, 1.0), child: Container(color: left ? _ink : _red))),
                ),
                const SizedBox(height: 5),
                Text('${left ? s.n1 : s.n2}%', style: ws(11, FontWeight.w700, _ink, h: 1)),
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
                  child: Text('K.O.', style: ws(18, FontWeight.w800, _yel, h: 1)),
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
                    Expanded(child: Text(r.label, style: ws(14.5, FontWeight.w600, _ink))),
                    for (final v in [(r.value, r.kind == 1), (r.sub ?? '', r.kind == 2)])
                      Container(
                        width: 38, height: 27,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(color: v.$2 ? _ink : null, borderRadius: BorderRadius.circular(999)),
                        alignment: Alignment.center,
                        child: Text(v.$1, style: ws(15, FontWeight.w800, v.$2 ? _yel : _ink.withValues(alpha: .55), h: 1)),
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
        body.addAll([_title(line2: safe ? s.title2 : s.who.first.name), _fbl(s.rows), _cap(s.capSafe)]);
      case WK.longest:
      case WK.fastest:
        final fast = s.k == WK.fastest;
        final icons = fast ? [_icBolt, _icPersonF, _icTimer2] : [_icTimer, _icPerson, _icRepeat];
        body.addAll([
          _title(),
          Column(
            children: gapped([
              for (var k = 0; k < s.rows.length; k++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: fast ? const Color(0xFFFFF2C7) : const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: fast ? null : Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Row(children: [
                    Ico(icons[k.clamp(0, 2)], size: fast ? 26 : 28, color: fast ? _ink : _pink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${s.rows[k].who?.show(safe) ?? ''}${s.rows[k].label}',
                          overflow: TextOverflow.ellipsis, style: ws(15, FontWeight.w700, fast ? _ink : _pink, h: 1.2)),
                    ),
                    _pill(s.rows[k].value, fast ? _ink : const Color(0xFF2E2A44), fast ? _yel : Colors.white, size: fast ? 14 : 15, pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
                  ]),
                ),
            ], 8),
          ),
        ]);
      case WK.budget:
        ov.add(Positioned(
          left: 24, top: 104,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.a, style: ws(76, FontWeight.w800, _ink, h: 1, ls: -3.8)),
            const SizedBox(height: 4),
            _pill('гривень за місяць', _ink, _pink, size: 14, pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          ]),
        ));
        body.addAll([_title(), _fbl(s.rows), _cap(s.capSafe)]);
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
        body.addAll([
          Text('🔒 ТІЛЬКИ ДЛЯ ТЕБЕ', style: rw(12, color: K.star, w: FontWeight.w500, ls: 1.68)),
          Text(s.title1, style: pr(34, h: 1.15)),
          if (safe)
            _calm('Цей слайд бачиш тільки ти', 'У сторіз і «Без імен» його нема.')
          else
            Column(children: gapped([for (final r in s.rows) _calm(r.label, '${r.value}${r.who != null ? ', з ${r.who!.name}' : ''}')], 8)),
          Text(s.capSafe ?? '', style: rw(16, color: K.star, h: 1.5)),
        ]);
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
        ov.add(Positioned(
          left: 96, top: 104, width: 200, height: 200,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.score.isNaN ? '—' : fmt(s.score), style: ws(64, FontWeight.w800, _ink, h: 1, ls: -2)),
            const SizedBox(height: 4),
            Text('СЕРЕДНІЙ БАЛ\n${w.monthGen.toUpperCase()}', textAlign: TextAlign.center, style: ws(12, FontWeight.w700, _ink, h: 1.2)),
          ]),
        ));
        body.addAll([_title(), _cap(s.capSafe)]);
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
              Container(
                height: 24,
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x330E0D1F)))),
                child: Row(children: [
                  Text(r.$1, style: ws(13, FontWeight.w600, _ink)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.$2, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: ws(13, FontWeight.w800, _ink))),
                ]),
              ),
          ]),
        ));
        body.addAll([_title(), _cap(s.capSafe)]);
    }

    String ovAnim() => switch (s.k) {
          WK.sex || WK.wishes => 'wrSpinIn',
          WK.receipt || WK.budget || WK.closed || WK.ticket => 'wrUp',
          _ => 'wrStc',
        };
    final ovA = [
      for (final (n, x) in ov.indexed)
        x is Positioned && x.child is! OverflowBox && !(s.k == WK.cover || (s.k == WK.best && n == 0))
            ? Positioned(left: x.left, top: x.top, right: x.right, bottom: x.bottom, width: x.width, height: x.height, child: WAnim(ovAnim(), delay: 200 + n * 120, dur: 900, child: x.child))
            : x,
    ];
    return Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(child: Image.asset(img, fit: BoxFit.fill, frameBuilder: (_, child, frame, sync) => frame == null && !sync ? ColoredBox(color: _bgOf[_th[s.k.index].substring(1)] ?? _ink) : child)),
      ...wrappedLayers(s.k.index),
      ...ovA,
      // шапка
      Positioned(
        left: 24, right: 24, top: 70, height: 28,
        child: Row(children: [
          Image.asset(logo, width: 84, semanticLabel: 'Vespr'),
          const Spacer(),
          Text(w.label, style: ws(13, FontWeight.w600, dark ? Colors.white : _ink)),
        ]),
      ),
      if (body.isNotEmpty) _body(body),
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
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x802B2830)
      ..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += 6) {
      c.drawLine(Offset(x, 0), Offset(x + 3, 0), p);
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
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(big ? '${mName(m)} ${m.substring(0, 4)}' : mName(m), style: rw(12, color: big ? _ink : K.muted2, w: FontWeight.w600)),
              const Spacer(),
              if (big)
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(t.$1, style: pr(96, color: txt, h: .85)),
                  const SizedBox(width: 14),
                  Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t.$2, style: pr(18, color: txt, h: 1.3)))),
                ])
              else ...[
                Text(t.$1, style: pr(64, color: K.accSoft, h: .85)),
                const SizedBox(height: 6),
                Text(t.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: pr(14, color: txt, h: 1.3)),
              ],
            ]),
            if (big)
              Positioned(
                right: -4, top: -4,
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

    final lockCard = Container(
      height: 176,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: K.w(.025), border: Border.all(color: K.w(.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cap(monthsNom[now.month - 1]), style: rw(12, color: K.muted2, w: FontWeight.w600)),
        const Spacer(),
        Row(children: [Ico(BS.lock, size: 14, color: K.muted2), const SizedBox(width: 8), Text('$lastDay ${monthsGen[now.month - 1]}', style: rw(13, color: K.muted2))]),
      ]),
    );

    final grid = <Widget>[...months.skip(1).map((m) => card(m)), lockCard];
    return DScroll(
      gap: 18,
      children: [
        const BoardHeader('Wrapped'),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Твої місяці', style: pr(34, h: 1.1)),
          const SizedBox(height: 8),
          Text("Новий Wrapped з'являється в останній день місяця.", style: rw(14, color: K.muted2, h: 1.5)),
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
