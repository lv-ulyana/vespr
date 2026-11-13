part of 'wrapped.dart';

// Слайди з дошки «Інші кандидати» артефакту «Vespr Wrapped» (WrappedMore):
// фон і стікери запечені (assets/wrapped/s19…s47), тексти й дані — тут,
// координати з макета 390×844 (класи .ik: kh, kt, kl, kc, kn, krow, kpill, kstamp).

const _lime = Color(0xFFC6F36B);
const _green = Color(0xFF2E8B57);
const _magenta = Color(0xFFC2185B);

TextStyle _e(TextStyle s) => s.copyWith(leadingDistribution: TextLeadingDistribution.even);

/// .kh — заголовок Onest 800
TextStyle _khS(double size, Color c) => _e(ws(size, FontWeight.w800, c, h: .92, ls: -size * .05));

/// .kt — заголовок Cormorant
TextStyle _ktS(Color c, {bool it = false}) => _e(cg(50, FontWeight.w500, c, it: it, h: .92, ls: -.5));

/// .kl — дрібний підпис капсом
TextStyle _klS(Color c, {double size = 9}) => _e(mt(size, FontWeight.w500, c, h: 1.45, ls: size * .2));

/// .kc — підпис курсивом
TextStyle _kcS(Color c, {double size = 18}) => _e(cg(size, FontWeight.w500, c, it: true, h: 1.25));

/// .kn — велике число
TextStyle _knS(double size, Color c) => _e(cg(size, FontWeight.w600, c, h: .9));

TextStyle _mono(double size, FontWeight w, Color c, {double ls = 0, double h = 1}) =>
    _e(TextStyle(fontFamily: 'PlexMono', fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls, fontFamilyFallback: const ['Zodiac']));

extension _More on _Slide {
  Widget _at(double l, double t, Widget c, {double? w, double? h, int d = 0, String a = 'wrUp', double? r}) => Positioned(
        left: r == null ? l : null,
        right: r,
        top: t,
        width: w,
        height: h,
        child: WAnim(a, delay: 150 + d * 90, dur: 900, child: c),
      );

  Widget _kh(double top, String l1, String l2, Color c1, Color c2, {double size = 46, int d = 0}) {
    final p = l2.split('|');
    final st = _khS(size, c1);
    return _at(26, top, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l1, style: st),
      Text(p.first, style: st.copyWith(color: c2)),
      if (p.length > 1) Text(p[1], style: st),
    ]), w: 338, d: d);
  }

  Widget _kt(double top, String l1, String l2, Color c1, Color c2, {int d = 0}) => _at(26, top, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l1, style: _ktS(c1)),
        Text(l2, style: _ktS(c2, it: true)),
      ]), w: 338, d: d);

  Widget _kc(double top, String? t, Color c, {double w = 338, int d = 6}) => t == null || t.isEmpty ? const SizedBox.shrink() : _at(26, top, Text(t, style: _kcS(c)), w: w, d: d);

  Widget _kl(double top, String t, Color c, {double left = 26, int d = 0}) => _at(left, top, Text(t.toUpperCase(), style: _klS(c)), w: 338, d: d);

  Widget _kpill(String t, Color bg, Color fg, {Border? border, double size = 11, FontWeight w = FontWeight.w600, bool mont = false, EdgeInsets pad = const EdgeInsets.symmetric(horizontal: 11, vertical: 6)}) => Container(
        padding: pad,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: border),
        child: Text(mont ? t.toUpperCase() : t, style: mont ? _e(mt(size, w, fg, h: 1, ls: size * .16)) : _e(ws(size, w, fg, h: 1))),
      );

  Widget _kavs({Color bg = _ink, Color fg = _pink, String t = '?', double size = 40, double fs = 18}) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        alignment: Alignment.center,
        child: Text(t, style: _e(ws(fs, FontWeight.w800, fg, h: 1))),
      );

  Widget _stamp(double l, double t, double deg, String text, Color c, Color bg, {double size = 17, double maxW = 200, EdgeInsets pad = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)}) => Positioned(
        left: l, top: t,
        child: WAnim('wrPop', delay: 900, dur: 600, child: Transform.rotate(
          angle: deg * math.pi / 180,
          child: Container(
            padding: pad,
            constraints: BoxConstraints(maxWidth: maxW),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: c, width: 3)),
            child: Text(text.toUpperCase(), textAlign: TextAlign.center, style: _e(ws(size, FontWeight.w800, c, h: 1.05, ls: size * .02))),
          ),
        )),
      );

  /// Текст на запеченій «вибуховій» плашці (.bb): велике значення + підпис
  Widget _bb(double l, double t, double size, double deg, String big, String small, {double bigSize = 30}) => Positioned(
        left: l, top: t, width: size, height: size,
        child: WAnim('wrStc', delay: 200, dur: 600, child: Transform.rotate(
          angle: deg * math.pi / 180,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (big.isNotEmpty) Text(big, style: _e(ws(bigSize, FontWeight.w800, _ink, h: .95, ls: -bigSize * .04))),
              Text(small.toUpperCase(), textAlign: TextAlign.center, style: _e(ws(15, FontWeight.w800, _ink, h: .95, ls: .3))),
            ]),
          ),
        )),
      );

  /// Рядок .krow: плашка з напівпрозорим фоном і тонкою рамкою
  Widget _krow(List<Widget> kids, {Color bg = const Color(0x0FFFFFFF), Color? line = const Color(0x24FFFFFF), double h = 60, EdgeInsets pad = const EdgeInsets.symmetric(horizontal: 12, vertical: 10)}) => Container(
        height: h,
        padding: pad,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: line == null ? null : Border.all(color: line)),
        child: Row(children: gapped(kids, 12, horizontal: true)),
      );

  String _nm(WP? p) => p == null ? 'Він' : p.show(safe);

  Widget _num(String big, String suf, double size, Color c, {double sufSize = 44, double sufOp = .5, Color? sufC}) => Text.rich(TextSpan(children: [
        TextSpan(text: big, style: _knS(size, c)),
        if (suf.isNotEmpty) TextSpan(text: suf, style: _knS(sufSize, (sufC ?? c).withValues(alpha: sufOp))),
      ]));

  /// Слайди з дошки WrappedMore і варіанти (фони 19–47)
  void more(List<Widget> ov) {
    final c2 = s.cap(safe);
    switch (s.art) {
      case 19: // Особова справа
        ov.add(Positioned(right: 26, top: 140, child: WAnim('wrUp', delay: 150, dur: 900, child: Text(s.x['num'] ?? '', style: _e(cg(64, FontWeight.w500, _ink, it: true, h: .8))))));
        ov.add(_kh(112, s.title1, s.title2, _ink, Colors.white));
        ov.add(Positioned(
          left: 40, top: 240, width: 132, height: 30,
          child: Transform.rotate(angle: -1.5 * math.pi / 180, child: Padding(padding: const EdgeInsets.only(left: 12), child: Align(alignment: Alignment.centerLeft, child: Text((s.x['tab'] ?? '').toUpperCase(), style: _mono(9, FontWeight.w600, const Color(0xFF5B4524), ls: .9))))),
        ));
        TextStyle lab = _mono(9, FontWeight.w500, _ink.withValues(alpha: .55), ls: .72);
        Widget kv(String k, String v) => Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x1F0E0D1F)))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                SizedBox(width: 78, child: Text(k.toUpperCase(), style: lab)),
                Expanded(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: _mono(13, FontWeight.w500, _ink, h: 1.2))),
              ]),
            );
        ov.add(Positioned(
          left: 38, top: 280, width: 318, height: 388,
          child: WAnim('wrUp', delay: 300, dur: 900, child: Transform.rotate(
            angle: math.pi / 180,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Opacity(
                  opacity: .6,
                  child: SizedBox(
                    width: 178,
                    child: Row(children: [
                      Text((s.x['obj'] ?? '').toUpperCase(), style: _mono(9, FontWeight.w500, _ink, ls: .72)),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                  child: SizedBox(width: 170, height: 46, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(_nm(s.who.firstOrNull), maxLines: 1, style: _e(cg(46, FontWeight.w600, _ink, it: true, h: 1))))),
                ),
                SizedBox(width: 178, child: Column(children: [kv('знак', s.x['sign'] ?? '—'), kv('зустрічей', s.x['meet'] ?? ''), kv('середня', s.x['avg'] ?? '')])),
                const SizedBox(height: 14),
                Text('ПОРУШЕННЯ', style: lab),
                const SizedBox(height: 6),
                if (s.rows.isEmpty) Text('чисто, без жодного прапорця', style: _mono(12.5, FontWeight.w500, _ink)),
                for (final r in s.rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(child: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _mono(12.5, FontWeight.w500, _ink))),
                      const SizedBox(width: 10),
                      Text(r.sub ?? '', style: _mono(13, FontWeight.w600, _red, ls: 2)),
                      const SizedBox(width: 10),
                      Text(r.value, style: _mono(12.5, FontWeight.w600, _ink)),
                    ]),
                  ),
              ]),
            ),
          )),
        ));
        // «відкрито» праворуч у шапці картки — над фото не залазить
        ov.add(Positioned(left: 38, top: 280, width: 318, height: 40, child: Transform.rotate(angle: math.pi / 180, child: Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 0), child: Align(alignment: Alignment.topRight, child: Opacity(opacity: .6, child: Text((s.x['opened'] ?? '').toUpperCase(), style: _mono(9, FontWeight.w500, _ink, ls: .72))))))));
        ov.add(_stamp(172, 600, -9, s.x['stamp'] ?? '', _red, const Color(0xD9FFFDF7), size: 18, maxW: 196, pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)));
        ov.add(_kc(736, c2, Colors.white));
        ov.add(_kl(765, s.x['cap2'] ?? '', Colors.white.withValues(alpha: .6), d: 7));
      case 20: // Відгуки покупців
        ov.add(_kh(112, s.title1, s.title2, _ink, _plum));
        final st = s.score.isNaN ? 0 : s.score.round();
        Widget stars(int k, double size) => Text.rich(TextSpan(children: [
              TextSpan(text: '★' * k, style: _e(ws(size, FontWeight.w500, _hot, h: 1.2, ls: 1))),
              TextSpan(text: '★' * (5 - k), style: _e(ws(size, FontWeight.w500, size > 12 ? const Color(0xFFE3DED3) : const Color(0x330E0D1F), h: 1.2, ls: 1))),
            ]));
        final hist = s.ints.length == 5 ? s.ints : const [0, 0, 0, 0, 0];
        final mx = hist.fold<int>(1, (a, b) => b > a ? b : a);
        ov.add(_at(26, 226, Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(children: [
            Text(fmt(s.score), style: _e(cg(46, FontWeight.w600, _ink, h: 1))),
            stars(st, 11),
            const SizedBox(height: 3),
            Opacity(opacity: .6, child: Text(s.x['cnt'] ?? '', style: _e(mt(8.5, FontWeight.w400, _ink, h: 1.3)))),
          ]),
          const SizedBox(width: 18),
          SizedBox(
            width: 150,
            child: Column(children: [
              for (var k = 0; k < 5; k++)
                Padding(
                  padding: EdgeInsets.only(bottom: k < 4 ? 4 : 0),
                  child: Row(children: [
                    SizedBox(width: 22, child: Text('${5 - k}★', style: _e(mt(9, FontWeight.w500, _ink, h: 1)))),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(color: const Color(0x1F0E0D1F), borderRadius: BorderRadius.circular(9)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(widthFactor: hist[k] / mx, child: Container(decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(9)))),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(child: Text(s.x['verdict'] ?? '', style: _e(cg(16, FontWeight.w500, _ink, it: true, h: 1.25)))),
        ]), w: 338, d: 1));
        for (var k = 0; k + 1 < s.rows.length && k < 4; k += 2) {
          final r = s.rows[k], q = s.rows[k + 1];
          final top = k == 0 ? 318.0 : 532.0;
          ov.add(Positioned(
            left: 22, top: top, width: 346,
            child: WAnim('wrStc', delay: 300 + k * 80, dur: 700, child: Transform.rotate(
              angle: (k == 0 ? -1.5 : 1.5) * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x8C0E0D1F), blurRadius: 30, offset: Offset(0, 18), spreadRadius: -16)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _kavs(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_nm(r.who), maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(15, FontWeight.w700, _ink, h: 1))),
                        const SizedBox(height: 4),
                        Text('✓ ПЕРЕВІРЕНИЙ ПОКУПЕЦЬ', style: _e(mt(9, FontWeight.w500, _green, h: 1, ls: .54))),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      stars(int.tryParse(r.value) ?? 0, 15),
                      const SizedBox(height: 3),
                      Opacity(opacity: .5, child: Text(s.x['date'] ?? '', style: _e(mt(9, FontWeight.w400, _ink, h: 1)))),
                    ]),
                  ]),
                  for (final (t, v, cc) in [('переваги', r.label, _green), if ((r.sub ?? '').isNotEmpty) ('недоліки', r.sub!, _red)])
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 72, child: Text(t.toUpperCase(), style: _e(mt(9, FontWeight.w500, cc, h: 1.4, ls: 1.08)))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(v, maxLines: 2, overflow: TextOverflow.ellipsis, style: _e(mt(11.5, FontWeight.w400, _ink, h: 1.4)))),
                      ]),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    padding: const EdgeInsets.only(top: 9),
                    width: double.infinity,
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x140E0D1F)))),
                    child: Text(q.label, style: _kcS(_ink, size: 17)),
                  ),
                  const SizedBox(height: 6),
                  Opacity(opacity: .5, child: Text('Корисно · ${q.value}', style: _e(mt(9.5, FontWeight.w400, _ink, h: 1)))),
                ]),
              ),
            )),
          ));
        }
        ov.add(_at(26, 772, Text('* ТОВАР ПОВЕРНЕННЮ НЕ ПІДЛЯГАЄ', style: _e(mt(9.5, FontWeight.w500, _ink, h: 1, ls: 1.4))), d: 8));
      case 21: // Розмір місяця
        ov.add(_at(26, 130, _kpill('🔒 тільки для тебе · у сторіз не йде', _ink, Colors.white, border: Border.all(color: Colors.white.withValues(alpha: .6)), size: 9.5, w: FontWeight.w500, mont: true)));
        ov.add(_kt(176, s.title1, s.title2, Colors.white, _rose, d: 1));
        ov.add(_at(26, 278, Text(s.x['intro'] ?? '', style: _e(mt(10.5, FontWeight.w400, Colors.white.withValues(alpha: .8), h: 1.45))), w: 190, d: 2));
        for (final (k, r) in s.rows.indexed) {
          ov.add(_at(26, 420 + k * 70.0, _krow([
            _kavs(),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_nm(r.who), maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(14.5, FontWeight.w700, Colors.white, h: 1.15))),
                const SizedBox(height: 3),
                Opacity(opacity: .65, child: Text((r.sub ?? 'розмір').toUpperCase(), style: _e(mt(9, FontWeight.w400, Colors.white, h: 1, ls: 1.44)))),
              ]),
            ),
            Text(r.label, style: _e(cg(20, FontWeight.w500, r.value == '1' ? _yel : _rose, it: true, h: 1))),
          ]), w: 338, d: 3 + k));
        }
        Widget cell(String n, Color c, String l) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: n, style: _e(cg(44, FontWeight.w600, c, h: 1))),
                TextSpan(text: ' ${s.x['of'] ?? ''}', style: _e(cg(22, FontWeight.w600, Colors.white.withValues(alpha: .6), h: 1))),
              ])),
              const SizedBox(height: 4),
              Text(l.toUpperCase(), style: _klS(Colors.white.withValues(alpha: .8))),
            ]);
        ov.add(_at(26, 600, Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x33FFFFFF)))),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: cell('${s.n1}', _rose, 'дюймовочка\nна горизонті'))),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x33FFFFFF)))),
                  child: cell('${s.n2}', Colors.white, 'гігантоманія\nпоки що'),
                ),
              ),
            ]),
          ),
        ), w: 338, d: 6));
        ov.add(_kc(742, c2, Colors.white.withValues(alpha: .9)));
      case 22: // Клоун місяця
        ov.add(_at(26, 372, Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(s.a, style: _e(ws(132, FontWeight.w800, _ink, h: .8, ls: -9.24))),
          const SizedBox(width: 14),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text((s.x['lab'] ?? '').toUpperCase(), style: _klS(_ink, size: 10))),
        ]), w: 338, a: 'wrPop'));
        ov.add(_tape(528, -4, _ink, _pink, 'Hall of shame ✦ ', h: 40, size: 17));
        ov.add(_kh(600, s.title1, s.title2, _ink, Colors.white, size: 42, d: 2));
        ov.add(_kc(712, c2, _ink));
      case 46: // Зала ганьби: колишня
        ov.add(_at(26, 112, _kpill('зала ганьби', _ink, Colors.white, size: 9.5, mont: true, pad: const EdgeInsets.symmetric(horizontal: 11, vertical: 7))));
        ov.add(_kh(290, s.title1, s.title2, _ink, _magenta, size: 42, d: 1));
        ov.add(_at(26, 404, Row(children: [
          Text(s.a, style: _e(cg(170, FontWeight.w600, _ink, h: .8))),
          const SizedBox(width: 14),
          Text((s.x['lab'] ?? '').toUpperCase(), style: _klS(_ink, size: 10)),
        ]), w: 338, a: 'wrPop', d: 2));
        ov.add(_tape(588, -4, _ink, _pink, 'Hall of shame ✦ ', h: 40, size: 16));
        ov.add(_kc(740, c2, Colors.white));
      case 23: // Мем «Граблі»
        ov.add(_at(26, 112, Row(children: [
          Text((s.x['lvl'] ?? '').toUpperCase(), style: _e(mt(9.5, FontWeight.w500, _ink, h: 1, ls: 1.71))),
          const SizedBox(width: 8),
          for (var k = 0; k < s.n1.clamp(1, 6); k++) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 4), decoration: const BoxDecoration(color: _plum, shape: BoxShape.circle)),
        ])));
        ov.add(Positioned(
          left: 26, top: 140, width: 338, height: 282,
          child: Transform.rotate(angle: -2 * math.pi / 180, child: Stack(children: [
            Positioned(left: 13, top: 239, width: 312, child: Text(s.x['meme'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: _e(cg(16, FontWeight.w500, _ink, it: true, h: 1.2)))),
          ])),
        ));
        const pills = [(42.0, 160.0, -6.0), (152.0, 150.0, 3.0), (300.0, 166.0, 6.0)];
        for (final (k, p) in s.who.take(3).indexed) {
          final (l, t, dg) = pills[k];
          ov.add(Positioned(
            left: k == 2 ? null : l, right: k == 2 ? 390 - 342 : null, top: t,
            child: WAnim('wrPop', delay: 500 + k * 120, dur: 500, child: Transform.rotate(
              angle: dg * math.pi / 180,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 130),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 6), spreadRadius: -6)]),
                child: Text(safe ? p.safe.replaceAll(RegExp(r'^(Він|Вона) '), '') : p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(10.5, FontWeight.w600, Colors.white, h: 1))),
              ),
            )),
          ));
        }
        ov.add(_at(26, 440, _kpill(s.x['pill'] ?? '', Colors.white, _ink, border: Border.all(color: _ink, width: 2)), d: 2));
        ov.add(_kh(530, s.title1, s.title2, _ink, _plum, d: 3));
        ov.add(_kc(752, c2, Colors.white));
      case 24: // Оскари місяця
        ov.add(_kh(120, s.title1, s.title2, Colors.white, _yel));
        ov.add(_at(26, 262, Row(children: [
          Container(width: 22, height: 1, color: _yel),
          const SizedBox(width: 10),
          Text((s.x['cer'] ?? '').toUpperCase(), style: _e(mt(9.5, FontWeight.w500, Colors.white.withValues(alpha: .6), h: 1, ls: 1.71))),
        ]), d: 1));
        for (final (k, r) in s.rows.indexed) {
          final who = r.who == null ? '' : (safe ? r.who!.safe.replaceAll(RegExp(r'^(Він|Вона) '), '') : r.who!.name);
          ov.add(_at(26, 290 + k * 68.0, _krow([
            _kavs(bg: _yel, fg: _ink, t: r.value, fs: 20),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(14.5, FontWeight.w700, _yel, h: 1.15))),
                const SizedBox(height: 3),
                Opacity(opacity: .75, child: Text('$who${r.sub ?? ''}'.replaceFirst(RegExp(r'^[:,] '), ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(mt(10.5, FontWeight.w400, Colors.white, h: 1.3)))),
              ]),
            ),
          ], bg: const Color(0x0DFFFFFF)), w: 338, d: 2 + k));
        }
        if (s.who.isNotEmpty) {
          final g = (s.x['g'] ?? '').split('|').where((x) => x.isNotEmpty).toList();
          ov.add(_at(26, 290 + s.rows.length * 68.0 + 34, Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.fromLTRB(112, 18, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x2EFF9AD5), Color(0x0FFF9AD5)]),
              border: Border.all(color: _pink, width: 1.5),
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: -94, top: 0, bottom: 0,
                child: Center(
                  child: Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2A2650), border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: _pink, spreadRadius: 2)]),
                    alignment: Alignment.center,
                    child: Text('?', style: _e(cg(36, FontWeight.w500, _pink, it: true, h: 1))),
                  ),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ГОЛОВНА НАГОРОДА', style: _e(mt(9, FontWeight.w500, _pink, h: 1, ls: 1.62))),
                const SizedBox(height: 6),
                Text('Кавалер місяця', style: _e(cg(30, FontWeight.w600, Colors.white, it: true, h: 1))),
                const SizedBox(height: 6),
                Text(safe ? s.who.first.safe.replaceAll(RegExp(r'^(Він|Вона) '), '') : s.who.first.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(13, FontWeight.w600, _pink, h: 1.2))),
                const SizedBox(height: 10),
                Row(children: gapped([
                  for (final t in g)
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '✓ ', style: _e(ws(12, FontWeight.w700, _pink, h: 1))),
                      TextSpan(text: t, style: _e(ws(12, FontWeight.w500, Colors.white.withValues(alpha: .85), h: 1))),
                    ])),
                ], 12, horizontal: true)),
              ]),
            ]),
          ), w: 338, d: 5));
        }
        ov.add(_kc(770, c2, Colors.white.withValues(alpha: .85)));
      case 25: // Хто почав
        ov.add(_bb(36, 180, 130, -8, s.a, s.b));
        ov.add(_kh(436, s.title1, s.title2, Colors.white, _pink));
        final hisName = s.who.isEmpty || safe ? 'Він' : s.who.first.name;
        final rows = [('Почала ти', '${s.n1}/${s.n1 + s.n2}'), ('$hisName почав', '${s.n2}')];
        for (final (k, r) in rows.indexed) {
          ov.add(_at(26, 560 + k * 52.0, _krow([
            Expanded(child: Text(r.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(14.5, FontWeight.w700, Colors.white, h: 1.15)))),
            Text(r.$2, style: _e(cg(24, FontWeight.w500, _pink, it: true, h: 1))),
          ], h: 44), w: 338, d: 2 + k));
        }
        ov.add(_kc(700, c2, Colors.white.withValues(alpha: .9)));
      case 26: // Алкоголь і секс
        ov.add(_kh(116, s.title1, s.title2, Colors.white, _pink));
        Widget col(double v, String l, double op) => Opacity(
              opacity: op,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fmt(v), style: _knS(96, Colors.white)),
                const SizedBox(height: 6),
                Text(l.toUpperCase(), style: _klS(Colors.white)),
              ]),
            );
        final ns = s.n1, nd = s.n2;
        ov.add(_at(26, 258, Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: col(s.score, 'тверезий секс\n$ns ${plural(ns, 'ніч', 'ночі', 'ночей')}', s.score >= s.score2 ? 1 : .55)),
          Expanded(child: col(s.score2, 'після келиха-двох\n$nd ${plural(nd, 'ніч', 'ночі', 'ночей')}', s.score2 > s.score ? 1 : .55)),
        ]), w: 338, d: 1));
        Widget bar(String l, double v, Color c) => Row(children: [
              SizedBox(width: 86, child: Text(l.toUpperCase(), style: _klS(Colors.white))),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.centerLeft,
                  child: WAnim('wrGrowX', delay: 600, dur: 900, child: FractionallySizedBox(widthFactor: (v / 5).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(999))))),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 34, child: Text(fmt(v), style: _e(cg(20, FontWeight.w600, Colors.white, h: 1)))),
            ]);
        ov.add(_at(26, 434, Column(children: [bar('тверезо', s.score, Colors.white), const SizedBox(height: 12), bar('під вином', s.score2, _pink)]), w: 338, d: 2));
        ov.add(_bb(250, 568, 118, 8, s.a, 'бала', bigSize: 24));
        ov.add(_kc(712, c2, Colors.white, w: 230));
      case 27: // Чия територія
        ov.add(_kl(150, 'книга рекордів vespr', Colors.white.withValues(alpha: .85)));
        ov.add(_kt(170, s.title1, s.title2, Colors.white, _rose, d: 1));
        ov.add(_at(26, 540, Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          _num('${s.n1}', '/${s.n2}', 96, _rose, sufSize: 36, sufOp: 1, sufC: Colors.white),
          const SizedBox(width: 14),
          Text(s.a.toUpperCase(), style: _klS(Colors.white.withValues(alpha: .85))),
        ]), w: 338, d: 2));
        Widget half(double v, String l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(v.isNaN ? '—' : fmt(v), style: _e(cg(26, FontWeight.w600, Colors.white, h: 1))),
                const SizedBox(width: 8),
                Text(l.toUpperCase(), style: _klS(Colors.white.withValues(alpha: .75))),
              ]),
            );
        ov.add(_at(26, 660, Container(
          decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Color(0x40FFFFFF)))),
          child: Row(children: [Expanded(child: half(s.score, 'у нього')), Expanded(child: half(s.score2, 'у тебе'))]),
        ), w: 338, d: 3));
        ov.add(_kc(740, c2, Colors.white.withValues(alpha: .92)));
      case 28: // Після
        ov.add(_at(26, 380, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ПІСЛЯ', style: _klS(_ink)),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            _num('${s.n1}', '/${s.n2}', 110, _ink, sufSize: 38, sufOp: .6),
            const SizedBox(width: 14),
            Text('обійми', style: _e(ws(30, FontWeight.w800, _ink, h: 1, ls: -1.2))),
          ]),
        ]), w: 338));
        for (final (k, r) in s.rows.indexed) {
          ov.add(_at(26, 530 + k * 48.0, _krow([
            Expanded(child: Text(r.label, style: _e(ws(14.5, FontWeight.w700, _ink, h: 1.15)))),
            Text(r.value, style: _e(cg(20, FontWeight.w500, _hot, it: true, h: 1))),
          ], bg: Colors.white, line: null, h: 40), w: 338, d: 2 + k));
        }
        ov.add(_kc(660, c2, _ink, w: 300));
      case 29: // Твій голос
        ov.add(_at(26, 112, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ТВІЙ ГОЛОС', style: _klS(_ink)),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${s.n1}', style: _e(cg(200, FontWeight.w600, _ink, h: .78))),
            const SizedBox(width: 12),
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Text('${plural(s.n1, 'раз', 'рази', 'разів')}\nсказала,\nчого хочеш', style: _e(ws(24, FontWeight.w800, _ink, h: 1, ls: -.72)))),
          ]),
        ]), w: 338));
        ov.add(_bb(258, 320, 110, 10, s.flags.firstOrNull == true ? 'рекорд' : 'голос', s.flags.firstOrNull == true ? 'місяця' : 'є', bigSize: 16));
        ov.add(Positioned(
          left: 22, top: 440, width: 346,
          child: WAnim('wrStc', delay: 400, dur: 700, child: Transform.rotate(
            angle: -math.pi / 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x8C0E0D1F), blurRadius: 30, offset: Offset(0, 18), spreadRadius: -16)]),
              child: Column(children: [
                for (final (k, r) in s.rows.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(border: k < s.rows.length - 1 ? const Border(bottom: BorderSide(color: Color(0x1F0E0D1F))) : null),
                    child: Row(children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: r.kind == 2 ? _hot : null, border: r.kind == 2 ? null : Border.all(color: _red, width: 1.5)),
                        alignment: Alignment.center,
                        child: Text(r.kind == 2 ? '✓' : '✕', style: _e(ws(13, FontWeight.w700, r.kind == 2 ? Colors.white : _red, h: 1))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r.label, style: _e(ws(14, FontWeight.w600, _ink, h: 1.2)))),
                      const SizedBox(width: 10),
                      Text(r.value, style: _e(cg(17, FontWeight.w500, _ink, it: true, h: 1))),
                    ]),
                  ),
              ]),
            ),
          )),
        ));
        ov.add(_kh(640, s.title1, s.title2, _ink, Colors.white, size: 40, d: 4));
        ov.add(_kc(752, c2, _ink));
      case 30: // Квартальний звіт
        ov.add(_kh(110, s.title1, s.title2, Colors.white, _pink));
        final pts = s.ints;
        ov.add(Positioned(
          left: 20, top: 232, width: 350, height: 327,
          child: WAnim('wrUp', delay: 300, dur: 900, child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text('VSP', style: _e(ws(11, FontWeight.w700, _ink, h: 1)))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Особисте життя', style: _e(ws(13, FontWeight.w600, Colors.white, h: 1.2))),
                    Opacity(opacity: .55, child: Text('VSPR · індекс вечорів', style: _mono(10, FontWeight.w500, Colors.white, h: 1.3))),
                  ]),
                ),
                Opacity(opacity: .55, child: Text(s.x['q'] ?? '', style: _mono(9, FontWeight.w500, Colors.white))),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt(s.score), style: _e(cg(64, FontWeight.w600, Colors.white, h: .8))),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ((s.x['pct'] ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: (s.x['pct']!.startsWith('▲') ? _lime : _hot).withValues(alpha: .15), borderRadius: BorderRadius.circular(99)),
                        child: Text(s.x['pct']!, style: _e(ws(11, FontWeight.w600, s.x['pct']!.startsWith('▲') ? _lime : _hot, h: 1))),
                      ),
                    const SizedBox(height: 5),
                    Opacity(opacity: .6, child: Text(s.x['vs'] ?? '', style: _e(ws(10, FontWeight.w500, Colors.white, h: 1.3)))),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              SizedBox(height: 110, width: double.infinity, child: CustomPaint(painter: _QChart(pts))),
              const SizedBox(height: 8),
              SizedBox(
                height: 10,
                child: LayoutBuilder(builder: (_, c) => Stack(clipBehavior: Clip.none, children: [
                  for (final (k, r) in s.rows.indexed)
                    Positioned(
                      left: c.maxWidth * const [.0327, .3442, .6558, .9673][k.clamp(0, 3)] - 20, width: 40,
                      child: Text(r.label, textAlign: TextAlign.center, style: _mono(9, k == s.rows.length - 1 ? FontWeight.w600 : FontWeight.w500, k == s.rows.length - 1 ? Colors.white : Colors.white.withValues(alpha: .5))),
                    ),
                ])),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  for (final t in const ['1Т', '1М', '3М', '1Р'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: t == '3М' ? Colors.white : null, borderRadius: BorderRadius.circular(99)),
                      child: Text(t, style: _e(ws(10.5, t == '3М' ? FontWeight.w600 : FontWeight.w500, t == '3М' ? _ink : Colors.white.withValues(alpha: .6), h: 1))),
                    ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('● ринок відкрито', style: _mono(9, FontWeight.w500, _lime))),
                ]),
              ),
            ]),
          )),
        ));
        final cards = [('Конверсія\nв 2-гу', s.x['conv'] ?? '', s.x['convL'] ?? '', _ink), ('Ризики', s.x['risk'] ?? '', 'червоних /\nпроігноровано', _red), ('Звільнено', s.x['fired'] ?? '', 'без вихідної\nдопомоги', _ink)];
        for (final (k, c) in cards.indexed) {
          ov.add(Positioned(
            left: 20 + k * 119.35, top: 566, width: 111.3, height: 109.7,
            child: WAnim('wrStc', delay: 500 + k * 100, dur: 700, child: Transform.rotate(
              angle: const [-1.5, 1.0, -1.0][k] * math.pi / 180,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(height: 21, child: Opacity(opacity: .6, child: Text(c.$1.toUpperCase(), style: _e(mt(8.5, FontWeight.w500, _ink, h: 1.25, ls: .85))))),
                  const SizedBox(height: 4),
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(c.$2, style: _e(cg(34, FontWeight.w600, c.$4, h: 1)))),
                  const SizedBox(height: 3),
                  Opacity(opacity: .65, child: Text(c.$3, style: _e(ws(9.5, FontWeight.w500, _ink, h: 1.3)))),
                ]),
              ),
            )),
          ));
        }
        ov.add(_stamp(222, 672, -12, s.x['stamp'] ?? '', _lime, const Color(0xD90E0D1F), maxW: 150));
        ov.add(_kc(724, c2, Colors.white.withValues(alpha: .9), w: 190));
      case 31: // Таро
        ov.add(_kl(150, 'твій аркан', Colors.white.withValues(alpha: .85)));
        ov.add(_kt(170, s.title1, s.title2, Colors.white, _rose, d: 1));
        ov.add(Positioned(
          left: 192, top: 324, width: 156, height: 250,
          child: Transform.rotate(angle: 7 * math.pi / 180, child: Stack(children: [
            Positioned(left: 8, right: 8, top: 20, child: Text(s.a, textAlign: TextAlign.center, style: _e(cg(30, FontWeight.w600, const Color(0xFF3A2A18), h: 1)))),
            Positioned(left: 8, right: 8, bottom: 20, child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.b.toUpperCase(), maxLines: 1, style: _e(mt(9, FontWeight.w500, const Color(0xFF3A2A18), h: 1, ls: 1.8))))),
          ])),
        ));
        ov.add(_kc(640, c2, Colors.white.withValues(alpha: .92)));
      case 32: // Зорі брешуть, метрики ні
        ov.add(_kh(120, s.title1, s.title2, Colors.white, _pink));
        ov.add(Positioned(
          left: 24, top: 290, width: 300,
          child: WAnim('wrStc', delay: 300, dur: 700, child: Transform.rotate(angle: -3 * math.pi / 180, child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✦ ЗОРІ КАЗАЛИ', style: _klS(_pink)),
              const SizedBox(height: 6),
              Text(s.a, maxLines: 2, style: _e(cg(26, FontWeight.w500, Colors.white, it: true, h: 1.1))),
            ]),
          ))),
        ));
        ov.add(Positioned(
          left: 66, top: 450, width: 300,
          child: WAnim('wrStc', delay: 500, dur: 700, child: Transform.rotate(angle: 2 * math.pi / 180, child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ФАКТИ КАЖУТЬ', style: _klS(_hot)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(fmt(s.score), style: _e(cg(48, FontWeight.w600, _ink, h: 1))),
                const SizedBox(width: 10),
                Expanded(child: Text('${safe ? 'Він' : _nm(s.who.firstOrNull)} за секс.\n${s.b}', maxLines: 2, overflow: TextOverflow.ellipsis, style: _e(ws(13, FontWeight.w600, _ink, h: 1.25)))),
              ]),
            ]),
          ))),
        ));
        ov.add(_kc(640, c2, Colors.white.withValues(alpha: .9)));
      case 33: // Архів колишніх
        ov.add(_kh(112, s.title1, s.title2, Colors.white, _pink));
        final p = s.who.firstOrNull;
        TextStyle pill = _e(mt(8.5, FontWeight.w600, _ink.withValues(alpha: .5), h: 1, ls: .85));
        ov.add(Positioned(
          left: 40, top: 244, width: 310, height: 329,
          child: Transform.rotate(angle: -3 * math.pi / 180, child: Stack(children: [
            Positioned(left: 70.6, top: 14, width: 150, child: Text(p == null ? '' : (safe ? p.safe.replaceAll(RegExp(r'^(Він|Вона) '), '') : p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(14, FontWeight.w700, _ink, h: 1.2)))),
            Positioned(left: 0, right: 0, top: 74, child: Text((s.x['last'] ?? '').toUpperCase(), textAlign: TextAlign.center, style: pill)),
            Positioned(left: 0, right: 0, top: 146, child: Text((s.x['silence'] ?? '').toUpperCase(), textAlign: TextAlign.center, style: pill)),
            Positioned(left: 12, right: 12, top: 267, child: Text('— ${safe ? 'він' : (p?.name ?? 'він')} вийшов з чату —'.toUpperCase(), textAlign: TextAlign.center, maxLines: 1, style: _e(mt(9, FontWeight.w500, _ink.withValues(alpha: .45), h: 1, ls: 1.08)))),
          ])),
        ));
        ov.add(_stamp(214, 572, -10, 'В архів', const Color(0xFFF08A6C), const Color(0xD90E0D1F)));
        ov.add(_kl(592, 'причина закриття', Colors.white.withValues(alpha: .75), d: 2));
        ov.add(_at(26, 611, Text(s.x['reason'] ?? '', style: _e(cg(30, FontWeight.w500, Colors.white, it: true, h: 1.1))), w: 338, d: 3));
        ov.add(_tape(664, -4, _pink, _ink, 'Не пиши мені ✦ ', h: 40, size: 17));
        ov.add(_kc(736, c2, Colors.white.withValues(alpha: .9)));
      case 34: // Обкладинка: одна людина весь місяць
        ov.add(_at(26, 112, _kpill('обкладинка місяця', _ink, Colors.white, size: 9.5, mont: true, pad: const EdgeInsets.symmetric(horizontal: 11, vertical: 7))));
        ov.add(_kh(150, s.title1, s.t2(safe), _ink, Colors.white, size: 44, d: 1));
        ov.add(_at(26, 552, Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${s.n1}', style: _knS(68, _ink)), Text('${s.x['eves'] ?? ''}\nразом'.toUpperCase(), style: _klS(_ink))]),
          const SizedBox(width: 26),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_num(fmt(s.score), '/5', 68, _ink, sufSize: 30), Text('середня\nоцінка'.toUpperCase(), style: _klS(_ink))]),
        ]), w: 338, d: 2));
        ov.add(_kc(752, c2, Colors.white));
      case 35: // Він vs минулий місяць
        ov.add(_kl(330, '${_nm(s.who.firstOrNull)} цього місяця', Colors.white.withValues(alpha: .7)));
        ov.add(_kh(354, s.title1, s.title2, Colors.white, _yel, d: 1));
        TextStyle hd = _e(mt(9, FontWeight.w500, Colors.white.withValues(alpha: .5), h: 1, ls: 1.62));
        ov.add(_at(26, 470, Column(children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Text('ПОКАЗНИК', style: hd), const Spacer(), Text((s.x['cols'] ?? '').toUpperCase(), style: hd)])),
          for (final r in s.rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x1FFFFFFF)))),
              child: Row(children: [
                Expanded(child: Text(r.label, style: _e(ws(14, FontWeight.w600, Colors.white, h: 1)))),
                Text.rich(TextSpan(children: [
                  TextSpan(text: r.sub, style: _e(cg(22, FontWeight.w600, Colors.white.withValues(alpha: .4), h: 1))),
                  TextSpan(text: ' → ', style: _e(cg(18, FontWeight.w600, _pink, h: 1))),
                  TextSpan(text: r.value, style: _e(cg(30, FontWeight.w600, Colors.white, h: 1))),
                ])),
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Builder(builder: (_) {
                      final d = (double.tryParse(r.value.replaceAll(',', '.')) ?? 0) - (double.tryParse((r.sub ?? '').replaceAll(',', '.')) ?? 0);
                      final c = r.kind == 2 ? _lime : (r.kind == 1 ? _hot : Colors.white.withValues(alpha: .7));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: r.kind == 0 ? const Color(0x1AFFFFFF) : c.withValues(alpha: .16), borderRadius: BorderRadius.circular(99)),
                        child: Text(r.kind == 0 ? 'без змін' : '${d > 0 ? '+' : '−'}${fmt(d.abs())}', style: _e(ws(10.5, FontWeight.w600, c, h: 1))),
                      );
                    }),
                  ),
                ),
              ]),
            ),
        ]), w: 338, d: 2));
        ov.add(_kc(742, c2, Colors.white.withValues(alpha: .9)));
      case 36: // Обкладинка: тільки побачення
        ov.add(_at(26, 112, _kpill('обкладинка місяця', _ink, Colors.white, size: 9.5, mont: true, pad: const EdgeInsets.symmetric(horizontal: 11, vertical: 7))));
        ov.add(_kh(150, s.title1, s.title2, _ink, _hot, size: 50, d: 1));
        ov.add(_at(26, 420, Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${s.n1}', style: _knS(110, _ink)), const SizedBox(height: 6), Text((s.x['dates'] ?? '').toUpperCase(), style: _klS(_ink))])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('0', style: _knS(110, _hot)), const SizedBox(height: 6), Text('СЕКСУ', style: _klS(_ink))])),
        ]), w: 338, d: 2));
        ov.add(_at(26, 600, Row(children: [_kpill('оцінюємо вечори', _ink, Colors.white), const SizedBox(width: 8), _kpill('і хлопців', Colors.white, _ink)]), d: 3));
        ov.add(_kc(750, c2, Colors.white));
      case 37: // Міні-Wrapped
        ov.add(_kl(300, s.x['kick'] ?? '', Colors.white.withValues(alpha: .7)));
        ov.add(_kh(326, s.title1, s.title2, Colors.white, _yel, d: 1));
        TextStyle sm = _e(ws(10.5, FontWeight.w500, Colors.white.withValues(alpha: .7), h: 1));
        ov.add(_at(26, 450, Column(children: [
          Row(children: gapped([for (var k = 0; k < 3; k++) Expanded(child: Container(height: 8, decoration: BoxDecoration(color: k < s.n1 ? _pink : const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(99))))], 6, horizontal: true)),
          const SizedBox(height: 8),
          Row(children: [Text(s.x['prog'] ?? '', style: sm), const Spacer(), Text(s.x['left'] ?? '', style: sm.copyWith(color: _pink))]),
        ]), w: 338, d: 2));
        Widget tile(String v, String l, {Color c = _ink, String suf = ''}) => Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(children: [TextSpan(text: v, style: _e(cg(38, FontWeight.w600, c, h: 1))), if (suf.isNotEmpty) TextSpan(text: suf, style: _e(cg(20, FontWeight.w600, c.withValues(alpha: .5), h: 1)))])),
                  const SizedBox(height: 6),
                  Opacity(opacity: .65, child: Text(l.toUpperCase(), maxLines: 2, style: _klS(_ink, size: 8.5))),
                ]),
              ),
            );
        ov.add(_at(26, 510, IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
          tile('${s.n1}', s.x['dates'] ?? ''),
          tile(s.x['men'] ?? '', s.x['menL'] ?? ''),
          tile(s.x['best'] ?? '', 'найкращий\nвечір', c: _hot, suf: '/5'),
        ], 8, horizontal: true))), w: 338, d: 3));
        ov.add(_kc(742, c2, Colors.white.withValues(alpha: .9)));
      case 38: // Метч: роздвоєння
        ov.add(_kl(388, 'Метч місяця', Colors.white.withValues(alpha: .7)));
        final st = _khS(46, Colors.white);
        ov.add(_at(26, 412, Text.rich(TextSpan(children: [TextSpan(text: s.title1, style: st), TextSpan(text: s.title2, style: st.copyWith(color: _pink)), TextSpan(text: ' 🫠', style: st)])), w: 338, d: 1));
        final rows = [('🧠', 'говорити', _lime, s.who.firstOrNull, s.score, 'Один'), ('🔥', 'спати', _hot, s.who.length > 1 ? s.who[1] : null, s.score2, 'Зовсім інший')];
        for (final (k, r) in rows.indexed) {
          ov.add(_at(26, 486 + k * 66.0, Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0x12FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1FFFFFFF))),
            child: Row(children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle), alignment: Alignment.center, child: Text(r.$1, style: const TextStyle(fontSize: 16, height: 1))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Opacity(opacity: .65, child: Text(r.$2.toUpperCase(), style: _klS(Colors.white, size: 8.5))),
                  Text(safe || r.$4 == null ? r.$6 : r.$4!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _e(ws(15, FontWeight.w700, Colors.white, h: 1.1))),
                ]),
              ),
              const SizedBox(width: 12),
              Text(fmt(r.$5), style: _e(cg(34, FontWeight.w600, r.$3, h: 1))),
            ]),
          ), w: 338, d: 2 + k));
        }
        ov.add(_kc(752, c2, Colors.white.withValues(alpha: .9)));
      default: // Типажі: 39–45, 47
        final dark = _darkBg.contains(s.art);
        final fgc = dark ? Colors.white : _ink;
        final em = switch (s.art) { 39 || 45 || 47 => _pink, 41 || 44 => _hot, 42 => _yel, _ => Colors.white };
        final kn = switch (s.art) { 42 => _yel, 45 || 47 => _pink, _ => fgc };
        final capC = s.art == 42 ? _ink : Colors.white;
        ov.add(_at(26, 112, _kpill('твій типаж', dark ? const Color(0x1AFFFFFF) : _ink, dark ? _pink : Colors.white, size: 9.5, mont: true, pad: const EdgeInsets.symmetric(horizontal: 11, vertical: 7))));
        if (s.art == 44) {
          final st = _khS(41, _ink);
          ov.add(_at(26, 322, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [TextSpan(text: s.title1, style: st), TextSpan(text: s.title2, style: st.copyWith(color: _hot))])),
            Text('💼', style: _khS(46, _ink)),
          ]), w: 338, d: 1));
        } else {
          ov.add(_kh(326, s.title1, s.title2, fgc, em, d: 1));
        }
        if (s.art == 41) {
          final cols = [('${s.n1}', s.x['l1'] ?? '', _ink), ('${s.n2}', s.x['l2'] ?? '', _ink), (s.a, s.x['l3'] ?? '', _hot)];
          ov.add(_at(26, 488, Row(children: [
            for (final c in cols)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.$1, style: _knS(72, c.$3)), Text(c.$2.toUpperCase(), style: _klS(_ink))])),
          ]), w: 338, d: 2));
        } else if (s.art == 40 && safe) {
          ov.add(_at(26, 501, _kpill('🎟 закритий показ', _ink, Colors.white), d: 2));
        } else {
          ov.add(_at(26, 500, Row(children: [
            _num(s.a, s.b, 96, kn),
            const SizedBox(width: 16),
            Text((s.x['lab'] ?? '').toUpperCase(), style: _klS(fgc, size: 9.5)),
          ]), w: 338, a: 'wrPop', d: 2));
        }
        ov.add(_kc(712, c2, capC));
    }
  }
}

/// Графік індексу вечорів: 4 місяці, остання точка підсвічена (як у макеті, viewBox 306×110)
class _QChart extends CustomPainter {
  final List<int> v; // середня ×100, -1 — нема записів
  _QChart(this.v);
  double _y(int x) {
    final ok = v.where((e) => e >= 0);
    final lo = ok.reduce(math.min), hi = ok.reduce(math.max);
    return hi == lo ? 55 : 88 - (x - lo) / (hi - lo) * 64;
  }

  @override
  void paint(Canvas c, Size sz) {
    final sx = sz.width / 306;
    final dash = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    for (final y in const [20.0, 55.0, 90.0]) {
      for (var x = 0.0; x < 306; x += 6) {
        c.drawLine(Offset(x * sx, y), Offset((x + 2) * sx, y), dash);
      }
    }
    const xs = [10.0, 105.3, 200.7, 296.0];
    final pts = <Offset>[
      for (var k = 0; k < v.length && k < 4; k++)
        if (v[k] >= 0) Offset(xs[k] * sx, _y(v[k])),
    ];
    if (pts.isEmpty) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var k = 1; k < pts.length; k++) {
      final a = pts[k - 1], b = pts[k];
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final area = Path.from(path)
      ..lineTo(pts.last.dx, 110)
      ..lineTo(pts.first.dx, 110)
      ..close();
    c.drawPath(area, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x73FF9AD5), Color(0x00FF9AD5)]).createShader(Rect.fromLTWH(0, 0, sz.width, 110)));
    c.drawPath(path, Paint()
      ..color = _pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round);
    for (final p in pts.take(pts.length - 1)) {
      c.drawCircle(p, 3, Paint()..color = const Color(0xFF1B1936));
      c.drawCircle(p, 3, Paint()
        ..color = _pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
    c.drawCircle(pts.last, 11, Paint()..color = _pink.withValues(alpha: .18));
    c.drawCircle(pts.last, 5, Paint()..color = _pink);
    c.drawCircle(pts.last, 5, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _QChart o) => o.v != v;
}
