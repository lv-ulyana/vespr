// «Календар» і «Нова зустріч»: перенесено з дошок Calendar і MeetingNew.
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/export.dart';
import '../services/files.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go, goReplace;
import 'entry.dart' show EntryForm, EntryView, MonthGrid, PAvatar, entryTitle, seedOf;
import 'export_screen.dart';
import 'onboarding.dart' show AddPersonScreen;

const _icPlus = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>';
const _icPrev = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M15 6l-6 6 6 6"/></svg>';
const _icNext = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 6l6 6-6 6"/></svg>';
const _icMic = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>';
const _icClose = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M6 6l12 12M18 6L6 18"/></svg>';
const _icCal = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4M9 15l2 2 4-4"/></svg>';

const _wdFull = ['понеділок', 'вівторок', 'середа', 'четвер', 'пʼятниця', 'субота', 'неділя'];
const _wdShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'нд'];

/// Фото місця для картки «До зустрічі» і плиток у формі
String placeImage(String? place) => switch (place) {
      'restaurant' => 'assets/img/dinner.jpg',
      'cafe' => 'assets/img/place_cafe.jpg',
      'park' => 'assets/img/place_park.jpg',
      'cinema' => 'assets/img/place_cinema.jpg',
      'his' => 'assets/img/place_his.jpg',
      'mine' => 'assets/img/place_mine.jpg',
      'other' => 'assets/img/city.jpg',
      _ => 'assets/img/bar.jpg',
    };

String _dayWord(String isoDate) {
  final t = today();
  if (isoDate == t) return 'сьогодні';
  if (isoDate == addDays(t, 1)) return 'завтра';
  final d = parseIso(isoDate);
  return '${d.day} ${monthsGen[d.month - 1]}';
}

Widget _ghostBtn(String text, VoidCallback? onTap, {String? svg, double h = 48}) => Press(
      onTap: onTap,
      child: Container(
        height: h,
        decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (svg != null) ...[Ico(svg, size: 15), const SizedBox(width: 8)],
          Text(text, style: rw(14, w: FontWeight.w500)),
        ]),
      ),
    );

Widget _accBtn(String text, VoidCallback? onTap, {String? svg}) => Press(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: onTap == null ? K.w(.06) : K.acc, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (svg != null) ...[Ico(svg, size: 15, color: onTap == null ? K.haze : K.bg), const SizedBox(width: 8)],
          Text(text, style: rw(14, color: onTap == null ? K.haze : K.bg, w: FontWeight.w500)),
        ]),
      ),
    );

// =====================================================================
// Календар
// =====================================================================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month;
  late String sel;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    month = DateTime(n.year, n.month);
    sel = today();
  }

  void _record(AppStore s, {String? personId}) {
    if (s.people.isEmpty) {
      go(context, const AddPersonScreen());
    } else {
      go(context, EntryForm(personId: personId, date: sel.compareTo(today()) > 0 ? today() : sel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final t = today();
    final hasEntry = s.entries.map((e) => e.date).toSet();
    final hasPlan = s.meetings.map((m) => m.date).toSet();
    final dayEntries = s.entries.where((e) => e.date == sel).toList();
    final dayPlans = s.meetings.where((m) => m.date == sel).toList()..sort((a, b) => a.time.compareTo(b.time));
    final selD = parseIso(sel);

    // сітка: хвіст попереднього місяця, дні, початок наступного
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday - 1;
    final daysIn = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime>[
      for (var i = lead; i > 0; i--) first.subtract(Duration(days: i)),
      for (var d = 1; d <= daysIn; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(cells.last.add(const Duration(days: 1)));
    }

    Widget navBtn(String svg, String label, VoidCallback onTap) => Press(
          label: label,
          onTap: onTap,
          child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.04), border: Border.all(color: K.w(.08))), alignment: Alignment.center, child: Ico(svg, size: 16)),
        );

    return DFrame(
      builder: (context, h) => Stack(children: [
        const Positioned(left: -60, top: -80, child: EGlow(w: 520, h: 420, colors: [Color(0x1FF08A6C), Color(0x0017161F)], stops: [0, .68])),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: 44,
                child: Stack(alignment: Alignment.center, children: [
                  Text('Календар', style: rw(15, w: FontWeight.w600)),
                  const Align(alignment: Alignment.centerLeft, child: BackBtn()),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Press(
                      label: 'Запланувати зустріч',
                      onTap: () => go(context, MeetingForm(date: sel.compareTo(t) >= 0 ? sel : t)),
                      child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.acc), alignment: Alignment.center, child: const Ico(_icPlus, size: 19, color: K.bg)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Rise(
                child: Row(children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(text: '${cap(monthsNom[month.month - 1])} ', children: [TextSpan(text: '${month.year}', style: const TextStyle(color: K.haze))]),
                      style: pr(30, h: 1),
                    ),
                  ),
                  navBtn(_icPrev, 'Попередній місяць', () => setState(() => month = DateTime(month.year, month.month - 1))),
                  const SizedBox(width: 6),
                  navBtn(_icNext, 'Наступний місяць', () => setState(() => month = DateTime(month.year, month.month + 1))),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [for (final d in const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд']) Expanded(child: Text(d, textAlign: TextAlign.center, style: rw(11, color: K.haze, w: FontWeight.w500)))]),
              const SizedBox(height: 8),
              for (var r = 0; r < cells.length ~/ 7; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : 6),
                  child: Row(children: [
                    for (final day in cells.sublist(r * 7, r * 7 + 7))
                      Expanded(
                        child: Builder(builder: (_) {
                          final id = iso(day);
                          final inMonth = day.month == month.month;
                          final on = id == sel;
                          final e = hasEntry.contains(id), p = hasPlan.contains(id);
                          return Semantics(
                            button: true,
                            selected: on,
                            label: '${day.day} ${monthsGen[day.month - 1]}${e ? ', є запис' : ''}${p ? ', заплановано' : ''}',
                            child: Press(
                              scale: .94,
                              onTap: () => setState(() {
                                sel = id;
                                if (!inMonth) month = DateTime(day.year, day.month);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: easeD,
                                height: 44,
                                decoration: BoxDecoration(color: on ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                                child: Stack(children: [
                                  if (id == t && !on)
                                    Positioned(left: 6, right: 6, top: 3, bottom: 3, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: K.a(.55))))),
                                  Center(
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text('${day.day}', style: rw(15, color: on ? K.bg : !inMonth ? K.dimC : id == t ? K.star : K.soft2, w: on || id == t ? FontWeight.w600 : FontWeight.w400)),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: 5, height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: e && inMonth ? K.acc : Colors.transparent,
                                          border: p && !e && inMonth ? Border.all(color: K.acc, width: 1.2) : null,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }),
                      ),
                  ]),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.acc)),
                const SizedBox(width: 6),
                Text('Запис', style: rw(11, color: K.muted)),
                const SizedBox(width: 16),
                Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.acc, width: 1.2))),
                const SizedBox(width: 6),
                Text('Заплановано', style: rw(11, color: K.muted)),
              ]),
              const SizedBox(height: 22),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Expanded(child: Text(sel == t ? 'Сьогодні' : '${selD.day} ${monthsGen[selD.month - 1]}', style: pr(20))),
                Text(sel == t ? '${_wdFull[selD.weekday - 1]}, ${selD.day} ${monthsGen[selD.month - 1]}' : _wdFull[selD.weekday - 1], style: rw(12, color: K.muted)),
              ]),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(sel),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: gapped([
                    for (final m in dayPlans) ...[
                      _UpCard(m: m, name: s.personName(m.personId), onTap: () => go(context, MeetingForm(meetingId: m.id))),
                      Row(children: [
                        Expanded(child: _ghostBtn('Змінити', () => go(context, MeetingForm(meetingId: m.id)))),
                        const SizedBox(width: 8),
                        Expanded(child: _accBtn('Записати', sel.compareTo(t) > 0 ? null : () => _record(s, personId: m.personId), svg: _icMic)),
                      ]),
                    ],
                    for (final e in dayEntries)
                      Press(
                        onTap: () => go(context, EntryView(entryId: e.id)),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A2734), K.card2]),
                            border: Border.all(color: K.w(.04)),
                          ),
                          child: Row(children: [
                            PAvatar(size: 40, seed: seedOf(e.personId)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.personName(e.personId), style: rw(15, w: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  const Ico(Svgs.star4, size: 11, color: K.acc),
                                  const SizedBox(width: 6),
                                  Text('${e.overall}', style: rw(12)),
                                  Flexible(child: Text(' · ${entryTitle(e)}', style: rw(12, color: K.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                              ]),
                            ),
                            Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.1))), alignment: Alignment.center, child: const Ico(_icNext, size: 13, color: K.soft2)),
                          ]),
                        ),
                      ),
                    if (dayEntries.isNotEmpty && sel.compareTo(t) <= 0) _ghostBtn('Ще один запис цього дня', () => _record(s), svg: _icPlus),
                    if (dayPlans.isEmpty && dayEntries.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.07))),
                        child: Text(sel.compareTo(t) > 0 ? 'Цей день вільний.' : 'Цього дня записів немає. Якщо зустріч була, її можна додати.', textAlign: TextAlign.center, style: rw(13, color: K.muted, h: 1.5)),
                      ),
                      Row(children: [
                        Expanded(child: _ghostBtn('Запланувати', () => go(context, MeetingForm(date: sel.compareTo(t) >= 0 ? sel : t)))),
                        if (sel.compareTo(t) <= 0) ...[const SizedBox(width: 8), Expanded(child: _accBtn('Записати', () => _record(s)))],
                      ]),
                    ],
                  ], 8),
                ),
              ),
              const SizedBox(height: 18),
              Press(
                onTap: () => go(context, const ExportScreen(calendar: true)),
                child: SizedBox(
                  height: 44,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Ico(_icCal, size: 16, color: K.muted),
                    const SizedBox(width: 8),
                    Text('Додати зустрічі в календар телефону', style: rw(13, color: K.muted, w: FontWeight.w500)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// .up — фото місця з затемненням і «До зустрічі»
class _UpCard extends StatelessWidget {
  final Meeting m;
  final String name;
  final VoidCallback onTap;
  const _UpCard({required this.m, required this.name, required this.onTap});
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 112,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(placeImage(m.place), fit: BoxFit.cover, alignment: const Alignment(0, -.2)),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xE017161F), Color(0x3317161F)], stops: [0, .72]))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('До зустрічі', style: rw(12, color: K.acc, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$name, ${_dayWord(m.date)} ${m.time}', style: pr(22, h: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (m.placeText != null || m.place != null) ...[
                    const SizedBox(height: 4),
                    Text(m.placeText ?? placeLabel(m.place), style: rw(12, color: K.soft)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      );
}

// =====================================================================
// Нова зустріч
// =====================================================================
const _times = ['18:00', '19:00', '20:00', '21:00'];
const _placeIds = ['bar', 'restaurant', 'cafe', 'park', 'cinema', 'his', 'mine'];

class MeetingForm extends StatefulWidget {
  final String? meetingId;
  final String? date;
  const MeetingForm({super.key, this.meetingId, this.date});
  @override
  State<MeetingForm> createState() => _MeetingFormState();
}

class _MeetingFormState extends State<MeetingForm> {
  Meeting? prev;
  String personId = '';
  late String date;
  String time = '20:00';
  String? place;
  bool remind = true;
  final other = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = Store.read(context);
    final m = widget.meetingId == null ? null : s.meetings.where((x) => x.id == widget.meetingId).firstOrNull;
    prev = m;
    final active = s.people.where((p) => !p.isPast).toList();
    if (m != null) {
      personId = m.personId;
      date = m.date;
      time = m.time;
      place = m.place;
      remind = m.remind;
      other.text = m.placeText ?? '';
    } else {
      personId = active.isNotEmpty ? active.first.id : '';
      date = widget.date ?? today();
    }
  }

  @override
  void dispose() {
    other.dispose();
    super.dispose();
  }

  Meeting get _m => Meeting(
        id: prev?.id ?? uid(),
        personId: personId,
        date: date,
        time: time,
        place: other.text.trim().isNotEmpty && place == null ? 'other' : place,
        remind: remind,
        extId: prev?.extId,
        placeText: other.text.trim().isEmpty ? null : other.text.trim(),
      );

  Future<void> _pickTime() async {
    final parts = time.split(':');
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0),
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (r != null) setState(() => time = '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _pickDate() async {
    final d = await showSheet<String>(context, (ctx) => Sheet(children: [
          Text('Інша дата', style: pr(26, h: 1.15)),
          MonthGrid(value: date, future: true, onPick: (v) => Navigator.pop(ctx, v)),
          Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Скасувати', style: rw(15, w: FontWeight.w600))))),
        ]));
    if (d != null) setState(() => date = d);
  }

  Widget _chip(String label, bool on, VoidCallback onTap, {String? sub}) => Semantics(
        selected: on,
        button: true,
        child: Press(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeD,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: on ? K.star : K.w(.03), borderRadius: BorderRadius.circular(999), border: Border.all(color: on ? K.star : K.w(.1))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: rw(14, color: on ? K.bg : K.soft2, w: FontWeight.w500)),
              if (sub != null && sub.isNotEmpty) ...[const SizedBox(width: 4), Text(sub, style: rw(11, color: (on ? K.bg : K.soft2).withValues(alpha: .7)))],
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final t = today();
    final people = s.people.where((p) => !p.isPast || p.id == personId).toList();
    final canSave = personId.isNotEmpty;
    final lbl = rw(13, color: K.muted);

    // день: сьогодні, завтра, найближча пʼятниця/субота після завтра
    final tom = addDays(t, 1);
    var third = addDays(t, 2);
    while (parseIso(third).weekday < 5) {
      third = addDays(third, 1);
    }
    final quick = [(t, 'Сьогодні', _wdShort[parseIso(t).weekday - 1]), (tom, 'Завтра', _wdShort[parseIso(tom).weekday - 1]), (third, cap(_wdShort[parseIso(third).weekday - 1]), '${parseIso(third).day}')];
    final custom = !quick.any((q) => q.$1 == date);
    final dd = parseIso(date);

    return DFrame(
      builder: (context, h) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: 44,
                child: Stack(alignment: Alignment.center, children: [
                  Text(prev == null ? 'Нова зустріч' : 'Зустріч', style: rw(15, w: FontWeight.w600)),
                  Align(alignment: Alignment.centerLeft, child: IconBtn(svg: _icClose, label: 'Закрити', onTap: () => Navigator.of(context).maybePop())),
                ]),
              ),
              const SizedBox(height: 16),
              Rise(child: titleAcc([('З ким і ', false), ('коли', true), ('?', false)], 30, h: 1.15)),
              const SizedBox(height: 20),
              Text('Людина', style: lbl),
              const SizedBox(height: 10),
              SizedBox(
                height: 86,
                child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: gapped([
                  for (final p in people)
                    Semantics(
                      selected: personId == p.id,
                      button: true,
                      child: Press(
                        onTap: () => setState(() => personId = p.id),
                        child: SizedBox(
                          width: 64,
                          child: Column(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: easeD,
                              padding: EdgeInsets.all(personId == p.id ? 4 : 3),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: personId == p.id ? K.acc : K.w(.1)),
                              child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg), child: PAvatar(size: personId == p.id ? 54 : 56, seed: seedOf(p.id))),
                            ),
                            const SizedBox(height: 6),
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(12, color: personId == p.id ? K.star : K.soft2, w: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                  Press(
                    onTap: () async {
                      final id = await go<String>(context, const AddPersonScreen());
                      if (id != null) setState(() => personId = id);
                    },
                    child: SizedBox(
                      width: 64,
                      child: Column(children: [
                        Container(
                          width: 66, height: 66,
                          alignment: Alignment.center,
                          child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.24))), alignment: Alignment.center, child: const Ico(_icPlus, size: 18, color: K.soft2)),
                        ),
                        const SizedBox(height: 6),
                        Text('Нова', style: rw(12, color: K.soft2, w: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ], 14, horizontal: true)),
              ),
              const SizedBox(height: 20),
              Text('День', style: lbl),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final q in quick) _chip(q.$2, date == q.$1, () => setState(() => date = q.$1), sub: q.$3),
                _chip(custom ? '${dd.day} ${monthsGen[dd.month - 1]}' : 'Інша дата', custom, _pickDate),
              ]),
              const SizedBox(height: 20),
              Text('Час', style: lbl),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final x in _times) _chip(x, time == x, () => setState(() => time = x)),
                _chip(_times.contains(time) ? 'Інший' : time, !_times.contains(time), _pickTime),
              ]),
              const SizedBox(height: 20),
              Text.rich(TextSpan(text: 'Де ', children: [TextSpan(text: '· необовʼязково', style: rw(13, color: K.haze))]), style: lbl),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: gapped([
                    for (final id in _placeIds)
                      Semantics(
                        selected: place == id,
                        button: true,
                        child: Press(
                          onTap: () => setState(() => place = place == id ? null : id),
                          child: SizedBox(
                            width: 76,
                            child: Column(children: [
                              AnimatedScale(
                                scale: place == id ? 1.03 : 1,
                                duration: const Duration(milliseconds: 350),
                                curve: easeD,
                                child: Container(
                                  width: 76, height: 76,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: place == id ? [BoxShadow(color: K.a(.7), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -12)] : null,
                                  ),
                                  foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: place == id ? K.acc : K.w(.08), width: place == id ? 2 : 1)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.matrix(<double>[.75, .08, .01, 0, 0, .03, .8, .01, 0, 0, .03, .08, .71, 0, 0, 0, 0, 0, 1, 0]),
                                      child: Image.asset(placeImage(id), fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(placeLabel(id), style: rw(12, color: place == id ? K.star : K.soft2, w: FontWeight.w500)),
                            ]),
                          ),
                        ),
                      ),
                  ], 8, horizontal: true),
                ),
              ),
              const SizedBox(height: 10),
              DInput(controller: other, label: 'Інше місце', hint: 'Або своє: концерт, дача, виставка…', style: rw(15), height: 52, caps: TextCapitalization.sentences, onChanged: (_) => setState(() {})),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.07))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Нагадати за годину', style: rw(15, w: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text('Тихе сповіщення, без імені', style: rw(12, color: K.muted)),
                    ]),
                  ),
                  Sw(on: remind, label: 'Нагадати за годину', onChanged: (v) => setState(() => remind = v)),
                ]),
              ),
              const SizedBox(height: 28),
              Cta(prev == null ? 'Запланувати' : 'Зберегти', onTap: !canSave
                  ? null
                  : () async {
                      await s.saveMeeting(_m);
                      if (context.mounted) Navigator.pop(context);
                    }),
              const SizedBox(height: 6),
              if (prev == null)
                Center(
                  child: Press(
                    onTap: !canSave ? null : () => goReplace(context, EntryForm(personId: personId, date: t)),
                    child: SizedBox(height: 44, child: Center(child: Text('Зустріч уже була? Одразу записати', style: rw(13, color: K.muted, w: FontWeight.w500)))),
                  ),
                )
              else ...[
                if (date.compareTo(t) <= 0)
                  Center(
                    child: Press(
                      onTap: () => goReplace(context, EntryForm(personId: personId, date: date)),
                      child: SizedBox(height: 44, child: Center(child: Text('Зустріч уже була? Записати', style: rw(13, color: K.muted, w: FontWeight.w500)))),
                    ),
                  ),
                Center(
                  child: Press(
                    onTap: () async {
                      try {
                        await addMeetingToPhoneCalendar(_m, s.personName(personId), CalendarOptions(quiet: true, place: place != null, remind: remind));
                      } catch (_) {
                        if (context.mounted) dToast(context, 'Не вдалося відкрити календар');
                      }
                    },
                    child: SizedBox(height: 44, child: Center(child: Text('Додати в календар телефону · «$quietTitle»', style: rw(13, color: K.muted, w: FontWeight.w500)))),
                  ),
                ),
                Center(
                  child: Press(
                    onTap: () async {
                      final yes = await showSheet<bool>(context, (ctx) => Sheet(children: [
                            Text('Скасувати зустріч?', style: pr(26, h: 1.15)),
                            Text('${s.personName(personId)}, ${_dayWord(date)} $time. Записи не зміняться.', style: rw(14, color: K.soft, h: 1.5)),
                            const SizedBox(height: 6),
                            Press(
                              onTap: () => Navigator.pop(ctx, true),
                              child: Container(height: 54, decoration: BoxDecoration(color: const Color(0xFFD9544F), borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text('Скасувати зустріч', style: rw(15, color: Colors.white, w: FontWeight.w700))),
                            ),
                            Press(onTap: () => Navigator.pop(ctx, false), child: SizedBox(height: 44, child: Center(child: Text('Лишити', style: rw(15, w: FontWeight.w700))))),
                          ]));
                      if (yes != true || !context.mounted) return;
                      final old = prev!;
                      await s.deleteMeeting(old.id);
                      if (!context.mounted) return;
                      final overlay = appNav.currentState?.overlay;
                      Navigator.pop(context);
                      if (overlay != null) undoToast(overlay.context, 'Зустріч скасовано', () => s.saveMeeting(old), overlay: overlay);
                    },
                    child: SizedBox(height: 44, child: Center(child: Text('Скасувати зустріч', style: rw(13, color: K.red, w: FontWeight.w600)))),
                  ),
                ),
              ],
            ]),
      ),
    );
  }
}
