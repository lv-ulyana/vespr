import 'package:flutter/material.dart';

import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/wrapped.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'settings.dart';

class _Th {
  final Color bg, fg, acc, blob;
  const _Th(this.bg, this.fg, this.acc, this.blob);
}

const _themes = {
  SlideTheme.navy: _Th(C.navy, Colors.white, C.pink, Color(0xFF2A2650)),
  SlideTheme.pink: _Th(C.pink, C.navy, Colors.white, Color(0x73FFFFFF)),
  SlideTheme.yellow: _Th(C.yellow, C.navy, C.hotPink, Color(0x80FFFFFF)),
};

class WrappedScreen extends StatefulWidget {
  final String month;
  const WrappedScreen({super.key, required this.month});
  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  late String month = widget.month;
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final months = s.entries.map((e) => monthKey(e.date)).toSet().toList()..sort((a, b) => b.compareTo(a));
    final w = buildWrapped(month, s.entries, s.people);
    final idx = i.clamp(0, w.slides.length - 1).toInt();
    final slide = w.slides[idx];
    final locked = !s.profile.premium && idx >= freeSlides;
    final th = _themes[slide.theme]!;
    void step(int d) {
      if (d > 0 && idx == w.slides.length - 1) {
        Navigator.pop(context);
        return;
      }
      setState(() => i = (idx + d).clamp(0, w.slides.length - 1).toInt());
    }

    return Scaffold(
      backgroundColor: th.bg,
      body: SafeArea(
        child: Stack(children: [
          Positioned(
            right: -100, top: 140,
            child: IgnorePointer(child: Container(width: 360, height: 360, decoration: BoxDecoration(shape: BoxShape.circle, color: th.blob))),
          ),
          Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(children: [
                for (var k = 0; k < w.slides.length; k++)
                  Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: th.fg.withValues(alpha: k <= idx ? .9 : .25)))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 6, 0),
              child: Row(children: [
                Expanded(child: Text('vesp·r', style: T.serif(22, th.fg))),
                IconButton(tooltip: 'Закрити', onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: th.fg)),
              ]),
            ),
            if (months.length > 1)
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 18), children: [
                  for (final m in months)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() { month = m; i = 0; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: m == month ? th.fg : Colors.transparent, borderRadius: BorderRadius.circular(99), border: Border.all(color: th.fg)),
                          child: Text('${monthsNom[int.parse(m.substring(5)) - 1]} ${m.substring(2, 4)}', style: T.body(11, m == month ? th.bg : th.fg, FontWeight.w600)),
                        ),
                      ),
                    ),
                ]),
              ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => step(d.localPosition.dx < MediaQuery.of(context).size.width / 3 ? -1 : 1),
                child: locked ? _Locked(th: th, left: w.slides.length - freeSlides) : _SlideView(slide: slide, th: th),
              ),
            ),
            if (locked)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Material(
                  color: th.fg,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => go(context, const PaywallScreen()),
                    child: SizedBox(height: 54, child: Center(child: Text('Відкрити повний Wrapped', style: T.body(16, th.bg, FontWeight.w700)))),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final Slide slide;
  final _Th th;
  const _SlideView({required this.slide, required this.th});
  @override
  Widget build(BuildContext context) {
    final onNavy = th.bg == C.navy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (slide.eyebrow != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: th.fg, borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (slide.private) ...[Icon(Icons.lock_rounded, size: 11, color: th.bg), const SizedBox(width: 5)],
                Text(slide.eyebrow!.toUpperCase(), style: T.body(10, th.bg, FontWeight.w700).copyWith(letterSpacing: 1.5)),
              ]),
            ),
          ),
        const SizedBox(height: 14),
        Text.rich(TextSpan(text: slide.title, children: [if (slide.accent != null) TextSpan(text: '\n${slide.accent}', style: TextStyle(color: th.acc))]), style: T.onest(44, th.fg)),
        const Spacer(),
        if (slide.big != null)
          Row(children: [
            Text(slide.big!, style: T.corm(96, th.fg).copyWith(height: 1.0)),
            const SizedBox(width: 14),
            if (slide.bigLabel != null) Expanded(child: Text(slide.bigLabel!.toUpperCase(), style: T.body(11, th.fg, FontWeight.w600).copyWith(letterSpacing: 1.6))),
          ]),
        for (final r in slide.rows)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: onNavy ? const Color(0x14FFFFFF) : Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Text(r.label, style: TextStyle(fontFamily: 'Onest', fontWeight: FontWeight.w600, fontSize: 15, color: onNavy ? Colors.white : C.navy))),
              Text(r.value, style: T.corm(24, onNavy ? C.pink : C.hotPink)),
            ]),
          ),
        if (slide.caption != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(slide.caption!, style: T.corm(21, th.fg, italic: true))),
      ]),
    );
  }
}

class _Locked extends StatelessWidget {
  final _Th th;
  final int left;
  const _Locked({required this.th, required this.left});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(text: 'Ще $left\n', children: [TextSpan(text: 'слайдів', style: TextStyle(color: th.acc))]), style: T.onest(44, th.fg)),
          const SizedBox(height: 12),
          Text('Рекорди, Зала ганьби, твій типаж і формула вечора — у повному Wrapped.', style: T.corm(21, th.fg, italic: true)),
        ]),
      );
}
