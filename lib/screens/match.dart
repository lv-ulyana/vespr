// «Ваш метч» за дошкою Match: двоє з вузликом, аркан пари (сума арканів),
// стосунки / секс / ризик, зодіак зі стихіями і «Аркан каже, записи перевіряють» —
// твердження про нього з його аркана, перевірене середньою з твоїх записів.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../logic/match_texts.dart';
import '../logic/stats.dart';
import '../services/files.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'entry.dart' show PAvatar, seedOf;
import 'settings.dart' show PaywallScreen, PaywallKind;

const _starPath = 'M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z';
final _icShare = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M12 3v13M7 8l5-5 5 5M5 14v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5"/></svg>';
final _icStarO = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="$_starPath"/></svg>';
final _icStarF = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="$_starPath"/></svg>';
final _icRisk = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.4v.1"/></svg>';
final _icOk = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>';
final _icNo = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M7 7l10 10M17 7 7 17"/></svg>';
String _elIcon(String el) => switch (el) {
      'Вогонь' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><path d="M3 19h18L12 3z"/></svg>',
      'Повітря' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><path d="M3 19h18L12 3z"/><path d="M5 12h14"/></svg>',
      'Вода' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><path d="M3 5h18L12 21z"/></svg>',
      _ => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><path d="M3 5h18L12 21z"/><path d="M7.5 13h9"/></svg>',
    };

/// Відкрити метч з людиною: без Premium — пейвол «метч»; без дат — підказка
void openMatch(BuildContext context, Person p) {
  final s = Store.read(context);
  if (!s.profile.premium) {
    go(context, PaywallScreen(kind: PaywallKind.match, name: p.name));
    return;
  }
  if (astroOf(s.profile.birth) == null) {
    dToast(context, 'Додай свою дату народження в налаштуваннях');
    return;
  }
  if (astroOf(p.birth, p.signOnly) == null) {
    dToast(context, 'Додай дату народження чи знак ${p.name} в картці');
    return;
  }
  go(context, MatchScreen(personId: p.id));
}

/// Текст з акцентом *…*
Widget _rich(String t, TextStyle base, Color acc) {
  final parts = t.split('*');
  return Text.rich(TextSpan(children: [
    for (var i = 0; i < parts.length; i++) TextSpan(text: parts[i], style: i.isOdd ? base.copyWith(color: acc, fontWeight: FontWeight.w500) : null),
  ]), style: base);
}

class MatchScreen extends StatefulWidget {
  final String personId;
  const MatchScreen({super.key, required this.personId});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final shot = GlobalKey();
  bool safeShot = true;
  bool capturing = false; // на час знімка для поширення

  Future<void> _share() async {
    setState(() => capturing = true);
    await WidgetsBinding.instance.endOfFrame;
    final b = shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return;
    final img = await b.toImage(pixelRatio: 3);
    if (mounted) setState(() => capturing = false);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await shareBytesFile('vespr-metch.png', data.buffer.asUint8List(), 'image/png');
  }

  void _shareSheet() {
    showSheet(context, (ctx) => StatefulBuilder(
          builder: (ctx, setS) => Sheet(children: [
            Text('Поділитися', style: pr(24, h: 1.15)),
            Text('Картинка з вашим арканом і знаками. Ім’я можна сховати.', style: rw(13, color: K.muted, h: 1.45)),
            Press(
              onTap: () {
                setS(() {});
                setState(() => safeShot = !safeShot);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: K.w(.025), border: Border.all(color: K.w(.07))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Безпечна версія', style: rw(15, w: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Без імен, оцінок і деталей', style: rw(12, color: K.muted)),
                    ]),
                  ),
                  Sw(on: safeShot, label: 'Безпечна версія', onChanged: (v) {
                    setS(() {});
                    setState(() => safeShot = v);
                  }),
                ]),
              ),
            ),
            for (final (t, svg) in [('У сторіс', '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="4" y="4" width="16" height="16" rx="5"/><circle cx="12" cy="12" r="3.5"/></svg>'), ('Зберегти картинкою', '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>'), ('Інше', '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>')])
              Press(
                onTap: () {
                  Navigator.pop(ctx);
                  _share();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: K.w(.025), border: Border.all(color: K.w(.07))),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.1))), alignment: Alignment.center, child: Ico(svg, size: 16, color: K.soft2)),
                    const SizedBox(width: 12),
                    Text(t, style: rw(15, w: FontWeight.w500)),
                  ]),
                ),
              ),
            Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Скасувати', style: rw(15, w: FontWeight.w600))))),
          ]),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.people.where((x) => x.id == widget.personId).firstOrNull;
    final me = astroOf(s.profile.birth);
    final him = p == null ? null : astroOf(p.birth, p.signOnly);
    if (p == null || me == null || him == null) return const ColoredBox(color: K.bg);
    final arc = me.arc != null && him.arc != null ? pairArcana(me.arc!, him.arc!) : null;
    final easyZ = zodiacEase(me.sign, him.sign) == 'Легко';
    final myInitial = (s.profile.name.isNotEmpty ? s.profile.name[0] : 'Т').toUpperCase();

    Widget tag(bool easy, {double h = 28}) => Container(
          height: h,
          padding: const EdgeInsets.fromLTRB(11, 0, 13, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: easy ? K.a(.10) : K.w(.03),
            border: Border.all(color: easy ? K.a(.32) : K.w(.08)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: easy ? K.acc : null, border: easy ? null : Border.all(color: K.soft), boxShadow: easy ? [BoxShadow(color: K.a(.8), blurRadius: 8)] : null)),
            const SizedBox(width: 7),
            Text(easy ? 'Легко' : 'Складніше', style: rw(12, color: easy ? K.accSoft : K.soft2, w: FontWeight.w600, ls: .24)),
          ]),
        );

    Widget mx(Widget child) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: K.w(.025), border: Border.all(color: K.w(.06))),
          child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
        );

    final himName = capturing && safeShot ? (p.gender == 'f' ? 'Вона' : 'Він') : p.name;

    // --- шапка з двома людьми й арканом пари (те, що йде в картинку для поширення)
    final hero = Column(children: [
      const SizedBox(height: 6),
      SizedBox(
        width: 148, height: 90,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            right: 0, top: 0,
            child: Rise(dy: 0, child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [const BoxShadow(color: Color(0xFF1E1B25), spreadRadius: 3), BoxShadow(color: K.soft.withValues(alpha: .5), spreadRadius: 4)]),
              child: PAvatar(size: 80, seed: seedOf(p.id)),
            )),
          ),
          Positioned(
            left: 0, top: 0,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFF6B39E), K.acc, Color(0xFF9C86A6)], stops: [0, .45, 1]),
                boxShadow: [const BoxShadow(color: Color(0xFF1E1B25), spreadRadius: 3), BoxShadow(color: K.a(.55), spreadRadius: 4)],
              ),
              alignment: Alignment.center,
              child: Text(myInitial, style: pr(30, color: K.bg, h: 1)),
            ),
          ),
          Positioned(
            left: 61, bottom: 4,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1E1B25), border: Border.all(color: K.a(.45)), boxShadow: [BoxShadow(color: K.a(.35), blurRadius: 16)]),
              alignment: Alignment.center,
              child: Ico(_icStarF, size: 12, color: K.acc),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text('Ти', style: rw(15, w: FontWeight.w500, ls: .15)),
        const SizedBox(width: 8),
        Text('і', style: rw(15, color: K.muted2)),
        const SizedBox(width: 8),
        Flexible(child: Text(himName, maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(15, w: FontWeight.w500, ls: .15))),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text.rich(TextSpan(children: [TextSpan(text: me.signName), if (me.romanNum != null) TextSpan(text: ' ${me.romanNum}', style: rw(12, color: K.soft2, w: FontWeight.w500, ls: .5))]), style: rw(12, color: K.muted, w: FontWeight.w500)),
        Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 10), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6B6580))),
        Text.rich(TextSpan(children: [TextSpan(text: him.signName), if (him.romanNum != null) TextSpan(text: ' ${him.romanNum}', style: rw(12, color: K.soft2, w: FontWeight.w500, ls: .5))]), style: rw(12, color: K.muted, w: FontWeight.w500)),
      ]),
      if (arc != null) ...[
        const SizedBox(height: 16),
        Stack(alignment: Alignment.topCenter, children: [
          Positioned(top: 34, child: IgnorePointer(child: Container(width: 220, height: 140, decoration: BoxDecoration(gradient: RadialGradient(colors: [K.a(.18), K.a(0)]))))),
          Column(children: [
            Text('${me.romanNum} + ${him.romanNum}', style: rw(11, color: const Color(0xFF8F89A6), w: FontWeight.w500, ls: 1.98)),
            const SizedBox(height: 8),
            Rise(
              delay: .2,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE9C3B7)], stops: [.3, 1]).createShader(r),
                child: Text(roman[arc], style: pr(76, color: Colors.white, h: 1, ls: .02)),
              ),
            ),
            const SizedBox(height: 6),
            Text(arcana[arc].name, style: pr(28, h: 1.1)),
            const SizedBox(height: 14),
            tag(easyArcana.contains(arc)),
          ]),
        ]),
      ],
    ]);

    // --- стосунки / секс / ризик
    final pt = arc == null ? null : pairTexts[arc];
    Widget mr(String svg, Color ic, String h, String t, {bool risk = false, bool glow = false}) => Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: risk ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [K.a(.10), K.a(.05)]) : null,
            border: Border(top: BorderSide(color: risk ? K.a(.22) : K.w(.07))),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 20, child: Center(child: Ico(svg, size: glow ? 13 : 12, color: ic))),
              const SizedBox(width: 10),
              Text(h, style: rw(12, color: risk ? K.accSoft : K.muted, w: FontWeight.w500, ls: .24)),
            ]),
            const SizedBox(height: 6),
            Padding(padding: const EdgeInsets.only(left: 30), child: _rich(t, rw(15, color: risk ? const Color(0xFFDCD7E3) : const Color(0xFFE6E2EB), h: 1.55, ls: .07), K.accSoft)),
          ]),
        );

    final relCard = pt == null
        ? null
        : mx(Container(
            decoration: const BoxDecoration(color: K.card2),
            foregroundDecoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 1.2, colors: [K.a(.12), K.a(0)], stops: const [0, .6])),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [SizedBox(width: 20, child: Center(child: Ico(_icStarO, size: 12, color: K.soft))), const SizedBox(width: 10), Text('Стосунки', style: rw(12, color: K.muted, w: FontWeight.w500, ls: .24))]),
                  const SizedBox(height: 6),
                  Padding(padding: const EdgeInsets.only(left: 30), child: _rich(pt.rel, rw(15, color: const Color(0xFFE6E2EB), h: 1.55, ls: .07), K.accSoft)),
                ]),
              ),
              mr(_icStarF, K.acc, 'Секс', pt.sex, glow: true),
              mr(_icRisk, K.acc, 'Ризик', pt.risk, risk: true),
            ]),
          ));

    // --- зодіак
    Widget zs(Astro a, bool mine) => Expanded(
          child: Column(children: [
            Container(
              width: 52, height: 52,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: mine
                    ? RadialGradient(center: const Alignment(0, -.4), colors: [K.soft.withValues(alpha: .16), K.soft.withValues(alpha: .04)])
                    : const RadialGradient(center: Alignment(0, -.4), colors: [Color(0xFFF6A890), K.acc]),
                border: mine ? Border.all(color: K.soft.withValues(alpha: .28)) : null,
                boxShadow: mine ? null : [BoxShadow(color: K.a(.6), blurRadius: 22, offset: const Offset(0, 8), spreadRadius: -8)],
              ),
              alignment: Alignment.center,
              child: Text(zodiacGlyph(a.sign), style: TextStyle(fontFamily: 'Zodiac', fontSize: 22, height: 1, color: mine ? const Color(0xFFD9D5E3) : K.bg)),
            ),
            const SizedBox(height: 6),
            Text(a.signName, style: pr(21, h: 1.1)),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [Ico(_elIcon(a.el), size: 11, color: K.muted), const SizedBox(width: 5), Text(a.el, style: rw(12, color: K.muted, w: FontWeight.w500))]),
          ]),
        );
    final zodiac = mx(Container(
      decoration: const BoxDecoration(color: K.card2),
      child: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topLeft, radius: 1, colors: [K.haze.withValues(alpha: .16), K.haze.withValues(alpha: 0)], stops: const [0, .7])))),
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 1, colors: [K.a(.14), K.a(0)], stops: const [0, .7])))),
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
            child: Row(children: [
              zs(me, true),
              Padding(
                padding: const EdgeInsets.only(bottom: 34),
                child: SizedBox(width: 56, height: 20, child: CustomPaint(painter: _ZLine())),
              ),
              zs(him, false),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: K.w(.07)))),
            child: Text(elementsText(me.el, him.el), style: rw(14, color: K.soft2, h: 1.55)),
          ),
        ]),
      ]),
    ));

    // --- аркан людини: що «каже» і що показують записи
    Widget? check;
    if (him.arc != null) {
      final bc = bedClaims[him.arc!];
      final es = entriesOf(s.entries, p.id).where((e) => e.hadSex).toList();
      final vals = es.map((e) => bc.q == 'sx_overall' ? (e.ratings['sx_overall'] ?? e.overall) : e.ratings[bc.q]).whereType<int>().toList();
      final v = avg(vals);
      final ok = !v.isNaN && v >= 3.5;
      check = mx(Container(
        color: K.card2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            Positioned(right: 18, top: 0, child: Text('“', style: pr(96, color: K.w(.05), h: 1))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 34, height: 46,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [K.w(.07), K.w(.02)]), border: Border.all(color: K.w(.12))),
                    alignment: Alignment.center,
                    child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text(him.romanNum ?? '', style: pr(15, color: const Color(0xFFE6E2EB))))),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(him.arcanaName ?? '', style: rw(14, w: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(p.gender == 'f' ? 'вона в ліжку' : 'він у ліжку', style: rw(12, color: K.muted)),
                  ]),
                ]),
                const SizedBox(height: 14),
                Text(bc.claim, style: pr(19, h: 1.4, ls: -.01)),
              ]),
            ),
          ]),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [K.a(.10), K.a(.05)]),
              border: Border(top: BorderSide(color: K.a(.22))),
            ),
            child: Row(children: [
              Text(v.isNaN ? '—' : fmt(v), style: pr(30, color: K.accSoft, h: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(v.isNaN ? '«${bc.qLabel}» — ще нема оцінок у записах' : '«${bc.qLabel}» за ${vals.length} ${plural(vals.length, 'зустріч', 'зустрічі', 'зустрічей')}',
                    style: rw(12.5, color: const Color(0xFFDCD7E3), h: 1.4)),
              ),
              if (!v.isNaN) ...[
                const SizedBox(width: 12),
                Container(
                  height: 28,
                  padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: ok ? K.a(.12) : K.w(.04), border: Border.all(color: ok ? K.a(.34) : K.w(.1))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Ico(ok ? _icOk : _icNo, size: 12, color: ok ? K.accSoft : K.soft2),
                    const SizedBox(width: 6),
                    Text(ok ? 'Збігається' : 'Не збігається', style: rw(12, color: ok ? K.accSoft : K.soft2, w: FontWeight.w600, ls: .12)),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ));
    }

    Widget hr() => Container(height: 1, margin: const EdgeInsets.fromLTRB(0, 10, 0, 4), color: K.w(.08));

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned(left: -40, top: 60, width: 470, height: 420, child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [K.a(.22), K.a(0)], stops: const [0, .65]))))),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              Row(children: [
                BackBtn(onTap: () => Navigator.maybePop(context)),
                Expanded(child: Center(child: Text('Ваш метч', style: rw(15, w: FontWeight.w700)))),
                Semantics(button: true, label: 'Поділитися', child: Press(onTap: _shareSheet, child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.hour), alignment: Alignment.center, child: Ico(_icShare, size: 19)))),
              ]),
              RepaintBoundary(key: shot, child: ColoredBox(color: K.bg, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: hero))),
              if (relCard != null) Padding(padding: const EdgeInsets.only(top: 8), child: relCard),
              hr(),
              Row(children: [Expanded(child: Text('Зодіак', style: pr(24, h: 1.2))), tag(easyZ, h: 26)]),
              zodiac,
              if (check != null) ...[
                hr(),
                Text('Аркан каже, записи перевіряють', style: pr(24, h: 1.2)),
                check,
              ] else
                Text('Для аркана пари потрібна повна дата народження ${p.name}, не тільки знак.', style: rw(13, color: K.muted, h: 1.5)),
              Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Text('Це гра, а не наука', style: rw(11, color: K.muted2)))),
            ], 16)),
          ),
        ),
      ]),
    );
  }
}

/// Пунктирні лінії між знаками і ромбик посередині
class _ZLine extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final sh = const LinearGradient(colors: [K.soft, K.acc]).createShader(Offset.zero & s);
    final p = Paint()
      ..shader = sh
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in const [(2.0, 20.0), (36.0, 54.0)]) {
      for (var x = a; x < b; x += 6) {
        c.drawLine(Offset(x, 10), Offset((x + 2).clamp(a, b), 10), p);
      }
    }
    final d = Path()
      ..moveTo(28, 4)
      ..lineTo(34, 10)
      ..lineTo(28, 16)
      ..lineTo(22, 10)
      ..close();
    c.drawPath(d, Paint()
      ..color = K.soft.withValues(alpha: .7)
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
