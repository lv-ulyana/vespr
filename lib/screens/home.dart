// Головна один в один з дошками «Home», «HomeEmpty», «HomeLimit».
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/export.dart';
import '../logic/stats.dart';
import '../logic/texts.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'calendar.dart';
import 'entry.dart';
import 'onboarding.dart';
import 'settings.dart';
import 'wrapped.dart';

/// «сьогодні», «завтра», «у суботу» (до тижня), інакше «14.11»
String _when(String d) {
  final t = today();
  if (d == t) return 'сьогодні';
  if (d == addDays(t, 1)) return 'завтра';
  final n = daysBetween(t, d);
  if (n > 0 && n < 7) return const ['', 'у понеділок', 'у вівторок', 'у середу', 'у четвер', 'у пʼятницю', 'у суботу', 'у неділю'][parseIso(d).weekday];
  final p = parseIso(d);
  return '${p.day.toString().padLeft(2, '0')}.${p.month.toString().padLeft(2, '0')}';
}

String _greet() {
  final h = DateTime.now().hour;
  return h < 5 ? 'Доброї ночі' : h < 12 ? 'Доброго ранку' : h < 18 ? 'Привіт' : 'Добрий вечір';
}

const _gear =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>';
const _sun = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1"/></svg>';
const _award = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="9" r="6"/><path d="M8.5 13.8L7 22l5-2.6 5 2.6-1.5-8.2"/></svg>';
const _plus = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>';
const _chev = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M9 5l7 7-7 7"/></svg>';
const _micBig = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>';
const _orbit =
    '<svg width="120" height="120" viewBox="0 0 120 120" fill="none"><circle cx="60" cy="60" r="56" stroke="#F1EEF2" stroke-opacity=".07"/><circle cx="60" cy="60" r="38" stroke="#F1EEF2" stroke-opacity=".07"/><circle cx="116" cy="60" r="3" fill="#F08A6C"/></svg>';
const star4Line = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.3"><path d="M12 1l2.6 8.4L23 12l-8.4 2.6L12 23l-2.6-8.4L1 12l8.4-2.6z"/></svg>';

/// Кругла аватарка-ініціал з градієнтом
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialAvatar(this.name, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment(-.6, -1), end: Alignment(.6, 1), colors: [K.acc, K.haze])),
        child: Text(name.isEmpty ? 'V' : name.characters.first.toUpperCase(), style: pr(size * 20 / 44, color: K.bg, ls: 0)),
      );
}

/// Повільно обертається (орбіта в картці «Факт дня»)
class _Spin extends StatefulWidget {
  final Widget child;
  const _Spin({required this.child});
  @override
  State<_Spin> createState() => _SpinState();
}

class _SpinState extends State<_Spin> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: c, child: widget.child);
}

class HomeTab extends StatelessWidget {
  final ValueChanged<int> onTab;
  const HomeTab({super.key, required this.onTab});

  Widget _header(BuildContext context, String name, bool empty) => Row(children: [
        InitialAvatar(name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(empty ? 'Привіт' : _greet(), style: rw(12, color: K.muted2)),
            Text(name.isEmpty ? 'ти' : name, style: rw(16, w: empty ? FontWeight.w500 : FontWeight.w600)),
          ]),
        ),
        IconBtn(svg: empty ? _sun : _gear, label: 'Налаштування', onTap: () => go(context, const SettingsScreen())),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    final empty = s.entries.isEmpty;
    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _header(context, p.name, empty),
            const SizedBox(height: 20),
            if (empty) ..._empty(context, s) else ..._full(context, s),
          ]),
        ),
      ),
    ]);
  }

  // ---------------- порожньо: ще жодного запису ----------------
  List<Widget> _empty(BuildContext context, AppStore s) => [
        Rise(
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(32), border: Border.all(color: K.w(.06))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: SizedBox(
                height: 238,
                child: Stack(fit: StackFit.expand, children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix([.64, .08, .02, 0, 0, .04, .68, .02, 0, 0, .04, .08, .62, 0, 0, 0, 0, 0, 1, 0]),
                    child: Image.asset('assets/img/city.jpg', fit: BoxFit.cover, alignment: const Alignment(0, .2), semanticLabel: 'Нічне місто у вогнях'),
                  ),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x8C17161F), Color(0x2617161F), Color(0xCC17161F)], stops: [0, .45, 1]))),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x8C17161F), Color(0x0017161F)], stops: [0, .75]))),
                  Positioned(right: -70, top: -70, child: Glow(w: 260, h: 260, circle: true, colors: [K.a(.28), K.a(0)], stops: const [0, .7])),
                  Positioned(right: 46, top: 40, child: Ico(Svgs.star4, size: 34, color: K.acc)),
                  starDot(390 - 50 - 120 - 3, 36, 3, K.star, .9),
                  starDot(390 - 50 - 30 - 2, 110, 2, K.star, .7),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Твоя мапа', style: rw(12, color: K.muted2, w: FontWeight.w600)),
                      const SizedBox(height: 48),
                      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: Text('Після трьох записів покажемо, що тобі справді подобається.', style: pr(23, h: 1.25))),
                    ]),
                  ),
                  Positioned(
                    left: 22, right: 22, bottom: 20,
                    child: Semantics(
                      label: '0 з 3 записів',
                      child: Row(children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) ...[const SizedBox(width: 8), Container(width: 14, height: 1, color: K.w(.15)), const SizedBox(width: 8)],
                          Ico(star4Line, size: 18, color: K.w(.35)),
                        ],
                        const Spacer(),
                        Text('кожен запис запалює зірку', style: rw(11, color: K.muted2)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Rise(
          delay: .05,
          child: Press(
            onTap: () => go(context, s.people.isEmpty ? const AddPersonScreen() : const EntryForm()),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const RadialGradient(center: Alignment.topLeft, radius: 2.2, colors: [Color(0xFFF6A890), K.acc], stops: [0, .6]),
                boxShadow: [BoxShadow(color: K.a(.65), blurRadius: 32, offset: const Offset(0, 16), spreadRadius: -16)],
              ),
              child: Row(children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg), alignment: Alignment.center, child: const Ico(_micBig, size: 24, color: K.acc)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Перший запис', style: rw(17, color: K.bg, w: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('20 секунд, голосом або тапами', style: rw(12, color: const Color(0xB317161F))),
                  ]),
                ),
                Container(width: 36, height: 36, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1F17161F)), alignment: Alignment.center, child: const Ico(_chev, size: 16, color: K.bg)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (s.people.isEmpty || s.people.length < 2)
          Rise(
            delay: .1,
            child: Press(
              onTap: () => go(context, const AddPersonScreen()),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(26), border: Border.all(color: K.w(.08))),
                child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: K.a(.12), border: Border.all(color: K.a(.32))), alignment: Alignment.center, child: const Ico(_plus, size: 18, color: K.accSoft)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.people.isEmpty ? 'Додай людину' : 'Додай ще людину', style: rw(15, w: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Щоб порівнювати і бачити ваш метч', style: rw(12, color: K.muted)),
                    ]),
                  ),
                  Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.05), border: Border.all(color: K.w(.08))), alignment: Alignment.center, child: const Ico(_chev, size: 14, color: K.soft2)),
                ]),
              ),
            ),
          ),
        if (s.people.length < 2) const SizedBox(height: 12),
        Rise(
          delay: .15,
          child: Press(
            onTap: () => onTab(3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: K.w(.06)),
                gradient: const RadialGradient(center: Alignment.topRight, radius: 1.2, colors: [Color(0xFF3A3446), K.hour], stops: [0, .55]),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(children: [
                  const Positioned(right: -44, top: -44, child: _Spin(child: SvgPicture(SvgStringLoader(_orbit), width: 120, height: 120))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: gapped([
                      Row(children: [const Ico(_award, size: 13, color: K.acc), const SizedBox(width: 6), Text('Нагороди', style: rw(11, color: K.muted2, w: FontWeight.w600))]),
                      Text('Перша чекає на твій перший запис', style: pr(20, h: 1.2)),
                      Row(children: [
                        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: K.w(.1), borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(width: 10),
                        Text('0 з 33', style: rw(12, color: K.muted, w: FontWeight.w600)),
                      ]),
                      Row(children: [Text('Подивитись усі', style: rw(12, color: K.acc, w: FontWeight.w500)), const SizedBox(width: 4), const Ico(_chev, size: 12, color: K.acc)]),
                    ], 10)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ];

  // ---------------- повна головна ----------------
  List<Widget> _full(BuildContext context, AppStore s) {
    final p = s.profile;
    final now = DateTime.now();
    final month = monthKey(today());
    final monthEntries = s.entries.where((e) => monthKey(e.date) == month).toList();
    final limitHit = !p.premium && monthEntries.length >= freeEntriesPerMonth;

    String insight;
    var patterns = 0;
    if (s.entries.length < 3) {
      insight = fewText(3 - s.entries.length);
    } else {
      final eff = effects(s.entries);
      patterns = eff.length;
      final f = formula(eff);
      if (f.length == 3) {
        insight = say('formula', {'t1': f[0].label.toLowerCase(), 't2': f[1].label.toLowerCase(), 't3': f[2].label.toLowerCase()});
      } else if (eff.isEmpty) {
        insight = 'Поки жодна звичка не вибивається. Записуй далі.';
      } else {
        final top = eff.first;
        insight = top.delta > 0
            ? say('tagUp', {'tag': top.label.toLowerCase(), 'd': d1(top.delta)}, top.id)
            : say('tagDown', {'tag': top.label, 'd': d1(top.delta), 'n': top.nWith}, top.id);
      }
    }

    final next = plannedMeetings(s.meetings);
    final unrated = unratedMeetings(s.meetings, s.entries).where((m) => daysBetween(m.date, today()) <= 60).toList();
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonth = iso(prevMonthDate).substring(0, 7);
    final prevCount = s.entries.where((e) => monthKey(e.date) == prevMonth).length;

    // тиждень: понеділок…неділя поточного тижня
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final week = [for (var i = 0; i < 7; i++) iso(monday.add(Duration(days: i)))];
    final weekEntries = s.entries.where((e) => week.contains(e.date)).toList();

    return [
      // --- мапа каже ---
      Rise(
        child: Press(
          scale: .99,
          onTap: () => onTab(2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [K.acc, Color(0xFFD27E70), Color(0xFF6E6382)], stops: [0, .4, 1]),
              boxShadow: const [BoxShadow(color: Color(0x8C08070C), blurRadius: 50, offset: Offset(0, 24), spreadRadius: -24)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(children: [
                Positioned(right: -40, top: -60, child: Glow(w: 200, h: 200, circle: true, colors: [K.w(.35), K.w(0)], stops: const [0, .7])),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Твоя мапа каже', style: rw(12, color: const Color(0xB317161F), w: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 290), child: Text(insight, style: pr(25, color: K.bg, h: 1.2)))),
                    const SizedBox(height: 18),
                    if (patterns > 0 || s.entries.length < 3)
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                        decoration: BoxDecoration(color: K.w(.88), borderRadius: BorderRadius.circular(999)),
                        child: Row(children: [
                          Container(
                            width: 30, height: 30,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg),
                            alignment: Alignment.center,
                            child: Text(s.entries.length < 3 ? '${s.entries.length}' : '$patterns', style: rw(13, color: K.acc, w: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.entries.length < 3
                                  ? 'з 3 записів до мапи'
                                  : '${plural(patterns, 'закономірність', 'закономірності', 'закономірностей')} про тебе',
                              style: rw(13, color: K.bg, w: FontWeight.w600),
                            ),
                          ),
                          const Ico(_chev, size: 16, color: K.bg),
                        ]),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
      // --- до зустрічі ---
      if (next.isNotEmpty) ...[
        const SizedBox(height: 12),
        Rise(
          delay: .05,
          child: Press(
            scale: .99,
            onTap: () => go(context, MeetingForm(meetingId: next.first.id)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 112,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/img/bar.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -.2), semanticLabel: 'Вечірній бар крізь вітрину'),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xE017161F), Color(0x3317161F)], stops: [0, .72]))),
                  Positioned(
                    left: 16, top: 0, bottom: 0, right: 16,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('До зустрічі', style: rw(12, color: K.acc, w: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${s.personName(next.first.personId)}, ${_when(next.first.date)} ${next.first.time}',
                        style: pr(22, h: 1.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ],
      // --- лишилось оцінити (з календаря) ---
      if (unrated.isNotEmpty && !limitHit) ...[
        const SizedBox(height: 12),
        _RowCard(
          badge: Container(
            width: 44, height: 52,
            decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(12), border: Border.all(color: K.a(.4))),
            alignment: Alignment.center,
            child: Text('${unrated.length}', style: pr(24, color: K.accSoft, h: 1, ls: 0)),
          ),
          label: 'Лишилось оцінити',
          title: '${s.personName(unrated.first.personId)}, ${human(unrated.first.date)}',
          onTap: () => go(context, EntryForm(personId: unrated.first.personId, date: unrated.first.date)),
        ),
      ],
      // --- Wrapped ---
      if (prevCount > 0 || monthEntries.isNotEmpty) ...[
        const SizedBox(height: 12),
        _RowCard(
          badge: Transform.rotate(
            angle: -4 * math.pi / 180,
            child: Container(
              width: 44, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(begin: Alignment(-.3, -1), end: Alignment(.3, 1), colors: [Color(0xFFF2A088), Color(0xFFD9775F)]),
                boxShadow: [BoxShadow(color: K.a(.8), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -10)],
              ),
              alignment: Alignment.center,
              child: Text('${prevCount > 0 ? prevCount : monthEntries.length}', style: pr(24, color: K.bg, h: 1, ls: 0)),
            ),
          ),
          label: 'Wrapped',
          title: prevCount > 0 ? 'Твій ${monthsNom[prevMonthDate.month - 1]} готовий' : '${cap(monthsNom[now.month - 1])} поки збирається',
          onTap: () => go(context, WrappedScreen(month: prevCount > 0 ? prevMonth : month)),
        ),
      ],
      // --- цей тиждень ---
      const SizedBox(height: 20),
      Row(children: [
        Text('Цей тиждень', style: rw(15, w: FontWeight.w600)),
        const Spacer(),
        Press(
          onTap: () => go(context, const CalendarScreen()),
          child: SizedBox(
            height: 44,
            child: Row(children: [
              Text('${weekEntries.length} ${plural(weekEntries.length, 'запис', 'записи', 'записів')} · календар', style: rw(12, color: K.muted2)),
              const SizedBox(width: 4),
              const Ico(_chev, size: 12, color: K.muted2),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 0),
      Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Press(
              onTap: () => go(context, const CalendarScreen()),
              child: _DayRing(
                label: const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'][i],
                today: week[i] == today(),
                entries: weekEntries.where((e) => e.date == week[i]).toList(),
              ),
            ),
          ),
      ]),
      // --- записати ---
      const SizedBox(height: 20),
      Press(
        onTap: () => limitHit ? go(context, const PaywallScreen()) : go(context, s.people.isEmpty ? const AddPersonScreen() : const EntryForm()),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A2734), K.card2]),
            border: Border.all(color: K.w(.05)),
          ),
          child: Row(children: [
            const _Orb(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Записати', style: rw(17, w: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(limitHit ? '$freeEntriesPerMonth з $freeEntriesPerMonth записів цього місяця' : 'Після зустрічі, поки свіже', style: rw(12, color: K.muted)),
              ]),
            ),
            Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.12))), alignment: Alignment.center, child: Ico(Svgs.arrowR, size: 14, color: K.soft2)),
          ]),
        ),
      ),
      // --- нагороди + факт дня ---
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 11,
            child: Press(
              onTap: () => onTab(3),
              child: Container(
                height: 156,
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(begin: Alignment(-.35, -1), end: Alignment(.35, 1), colors: [Color(0xFFF7F3F5), Color(0xFFE9E3EA)]),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [const Ico(_award, size: 13, color: Color(0xFF6E6880)), const SizedBox(width: 6), Text('Нагороди', style: rw(11, color: const Color(0xFF6E6880), w: FontWeight.w700))]),
                  Row(children: [
                    Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: K.acc, spreadRadius: 2)]),
                      child: ClipOval(child: Image.asset('assets/img/award_gold.webp', width: 48, height: 48, fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Скоро тут', style: pr(17, color: K.bg, h: 1.2))),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(height: 4, decoration: BoxDecoration(color: const Color(0x1A17161F), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 7),
                    Text('0 з 33 відкрито', style: rw(11, color: K.haze, w: FontWeight.w600)),
                  ]),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 10,
            child: Container(
              height: 156,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: K.w(.06)),
                gradient: const RadialGradient(center: Alignment.topRight, radius: 1.2, colors: [Color(0xFF3A3446), K.hour], stops: [0, .55]),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(children: [
                  const Positioned(right: -44, top: -44, child: _Spin(child: SvgPicture(SvgStringLoader(_orbit), width: 120, height: 120))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [const Ico(Svgs.star4, size: 13, color: K.acc), const SizedBox(width: 6), Text('Факт дня', style: rw(11, color: K.muted2, w: FontWeight.w600))]),
                      Text.rich(
                        TextSpan(text: 'Більшості жінок для оргазму потрібна ', children: [TextSpan(text: 'стимуляція клітора', style: rw(14, w: FontWeight.w500, h: 1.38))]),
                        style: rw(14, color: const Color(0xFFD7D3E0), w: FontWeight.w300, h: 1.38),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ];
  }
}

/// Рядок-картка з плашкою зліва (Wrapped, «Лишилось оцінити»)
class _RowCard extends StatelessWidget {
  final Widget badge;
  final String label, title;
  final VoidCallback onTap;
  const _RowCard({required this.badge, required this.label, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Rise(
        delay: .1,
        child: Press(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: K.card2,
              border: Border.all(color: K.a(.18)),
              gradient: LinearGradient(begin: const Alignment(-1, -.2), end: const Alignment(1, .2), colors: [K.a(.2), const Color(0x002B2836), const Color(0x002B2836)], stops: const [0, .7, 1]),
            ),
            child: Row(children: [
              badge,
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: rw(12, color: K.accSoft, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(title, style: pr(19, h: 1.15), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const Ico(_chev, size: 16, color: K.soft2),
            ]),
          ),
        ),
      );
}

/// День тижня: кільце з оцінкою (заповнення = оцінка × 20%)
class _DayRing extends StatelessWidget {
  final String label;
  final bool today;
  final List<Entry> entries;
  const _DayRing({required this.label, required this.today, required this.entries});
  @override
  Widget build(BuildContext context) {
    final v = entries.isEmpty ? 0 : entries.map((e) => e.overall).reduce(math.max);
    return Semantics(
      label: '$label${v > 0 ? ', оцінка $v' : ''}',
      child: Column(children: [
        Text(label, style: rw(11, color: today ? K.star : K.muted2, w: today ? FontWeight.w700 : FontWeight.w400)),
        const SizedBox(height: 6),
        SizedBox(
          width: 34, height: 34,
          child: CustomPaint(
            painter: _RingPainter(v: v, today: today),
            child: Center(child: v > 0 ? Text('$v', style: rw(11, w: FontWeight.w600)) : null),
          ),
        ),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int v;
  final bool today;
  _RingPainter({required this.v, required this.today});
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    if (v > 0) {
      final r = s.width / 2 - 1.6;
      canvas.drawCircle(c, r, Paint()..color = K.hour..style = PaintingStyle.stroke..strokeWidth = 3.2);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * v / 5, false, Paint()..color = K.acc..style = PaintingStyle.stroke..strokeWidth = 3.2);
    } else if (today) {
      final p = Paint()..color = K.acc..style = PaintingStyle.stroke..strokeWidth = 1.5;
      final r = s.width / 2 - .75;
      const n = 20;
      for (var i = 0; i < n; i += 2) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * 2 * math.pi / n, 2 * math.pi / n, false, p);
      }
    } else {
      canvas.drawCircle(c, s.width / 2 - .75, Paint()..color = K.hour..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.today != today;
}

/// Помаранчева куля з мікрофоном, двічі «пульсує» при появі
class _Orb extends StatefulWidget {
  const _Orb();
  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      await c.forward(from: 0);
      if (mounted) c.forward(from: 0);
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
        builder: (_, __) {
          final t = math.sin(c.value * math.pi);
          return Container(
            width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, color: K.acc, boxShadow: [BoxShadow(color: K.a(.45 * (1 - t)), spreadRadius: 10 * t)]),
            alignment: Alignment.center,
            child: const Ico(_micBig, size: 24, color: K.bg),
          );
        },
      );
}
