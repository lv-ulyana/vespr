import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/export.dart';
import '../services/files.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'entry.dart';
import 'export_screen.dart';
import 'onboarding.dart' show AddPersonScreen;
import 'people.dart' show PersonEdit;

/// Календар: записи (крапка) і заплановані зустрічі (кільце)
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

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final first = DateTime(month.year, month.month, 1);
    final daysIn = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1; // понеділок першим
    final hasEntry = s.entries.map((e) => e.date).toSet();
    final hasPlan = s.meetings.map((m) => m.date).toSet();
    final t = today();
    final dayEntries = s.entries.where((e) => e.date == sel).toList();
    final dayPlans = s.meetings.where((m) => m.date == sel).toList()..sort((a, b) => a.time.compareTo(b.time));

    return Screen(children: [
      Header(
        title: 'Календар',
        right: RoundIcon(icon: Icons.add, label: 'Запланувати зустріч', accent: true, onTap: () => go(context, MeetingForm(date: sel.compareTo(t) >= 0 ? sel : t))),
      ),
      Row(children: [
        Expanded(child: Text.rich(TextSpan(text: '${cap(monthsNom[month.month - 1])} ', children: [TextSpan(text: '${month.year}', style: const TextStyle(color: C.haze))]), style: T.serif(28))),
        IconButton(tooltip: 'Попередній місяць', onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left_rounded, color: C.text)),
        IconButton(tooltip: 'Наступний місяць', onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right_rounded, color: C.text)),
      ]),
      Column(children: [
        Row(children: [for (final d in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд']) Expanded(child: Text(d, textAlign: TextAlign.center, style: T.body(11, C.haze, FontWeight.w500)))]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var d = 1; d <= daysIn; d++)
              Builder(builder: (_) {
                final id = iso(DateTime(month.year, month.month, d));
                final on = id == sel;
                return Semantics(
                  button: true,
                  selected: on,
                  label: '$d ${monthsGen[month.month - 1]}${hasEntry.contains(id) ? ', є запис' : ''}${hasPlan.contains(id) ? ', заплановано' : ''}',
                  child: GestureDetector(
                    onTap: () => setState(() => sel = id),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: on ? C.text : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: id == t && !on ? Border.all(color: C.accent.withValues(alpha: .55)) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$d', style: T.body(15, on ? C.bg : C.text, id == t || on ? FontWeight.w600 : FontWeight.w400)),
                        const SizedBox(height: 3),
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasEntry.contains(id) ? C.accent : Colors.transparent,
                            border: hasPlan.contains(id) && !hasEntry.contains(id) ? Border.all(color: C.accent, width: 1.2) : null,
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
          ],
        ),
        Row(children: [
          Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.accent)),
          const SizedBox(width: 6),
          const Txt('Запис', small: true, muted: true),
          const SizedBox(width: 16),
          Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.accent, width: 1.2))),
          const SizedBox(width: 6),
          const Txt('Заплановано', small: true, muted: true),
        ]),
      ]),
      Row(children: [
        Expanded(child: Text(sel == t ? 'Сьогодні' : cap(human(sel)), style: T.serif(20))),
        if (sel == t) Txt(human(sel), small: true, muted: true),
      ]),
      for (final m in dayPlans)
        VCard(
          color: C.warm,
          border: const Color(0x40F08A6C),
          onTap: () => go(context, MeetingForm(meetingId: m.id)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('До зустрічі', style: T.body(12, C.accent, FontWeight.w600)),
                Text('${s.personName(m.personId)}, ${m.time}', style: T.serif(20)),
                if (m.place != null) Txt(placeLabel(m.place), small: true, muted: true),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.haze),
          ]),
        ),
      for (final e in dayEntries)
        VCard(
          padding: const EdgeInsets.all(12),
          onTap: () => go(context, EntryView(entryId: e.id)),
          child: Row(children: [
            Avatar(s.personName(e.personId)),
            const SizedBox(width: 12),
            Expanded(child: Text(s.personName(e.personId), style: T.body(15, C.text, FontWeight.w600))),
            Text('${e.overall}', style: T.serif(22, C.accentSoft)),
          ]),
        ),
      if (dayPlans.isEmpty && dayEntries.isEmpty)
        VCard(child: Txt(sel.compareTo(t) > 0 ? 'Цей день вільний.' : 'Цього дня записів немає. Якщо зустріч була, її можна додати.', muted: true, align: TextAlign.center)),
      Row(children: [
        Expanded(child: Btn('Запланувати', kind: BtnKind.ghost, onTap: () => go(context, MeetingForm(date: sel.compareTo(t) >= 0 ? sel : t)))),
        const SizedBox(width: 8),
        Expanded(child: Btn('Записати', onTap: sel.compareTo(t) > 0 ? null : () => go(context, s.people.isEmpty ? const AddPersonScreen() : EntryForm(date: sel)))),
      ]),
      NavRow(title: 'Додати зустрічі в календар телефону', icon: Icons.event_available_rounded, onTap: () => go(context, const ExportScreen(calendar: true))),
    ]);
  }
}

const _times = ['18:00', '19:00', '19:30', '20:00', '21:00', '22:00'];

/// Нова або змінена запланована зустріч
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
  bool confirmDelete = false;

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
    } else {
      personId = active.length == 1 ? active.first.id : '';
      date = widget.date ?? today();
    }
  }

  Future<void> _pickTime() async {
    final parts = time.split(':');
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0),
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (r != null) setState(() => time = '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final t = today();
    final people = s.people.where((p) => !p.isPast || p.id == personId).toList();
    final canSave = personId.isNotEmpty;
    final m = Meeting(id: prev?.id ?? uid(), personId: personId, date: date, time: time, place: place, remind: remind);

    return Screen(
      footer: [
        Btn(prev == null ? 'Запланувати' : 'Зберегти', onTap: !canSave ? null : () async {
          await s.saveMeeting(m);
          if (context.mounted) Navigator.pop(context);
        }),
      ],
      children: [
        Header(title: prev == null ? 'Нова зустріч' : 'Зустріч'),
        const H1('З ким', accent: 'і коли?'),
        const Label('Людина'),
        Chips([
          for (final p in people) ChipX(p.name, on: personId == p.id, onTap: () => setState(() => personId = p.id)),
          ChipX('+ Нова', on: false, onTap: () => go(context, const PersonEdit())),
        ]),
        const Label('День'),
        Row(children: [
          IconButton(tooltip: 'Попередній день', onPressed: date.compareTo(t) <= 0 ? null : () => setState(() => date = addDays(date, -1)), icon: Icon(Icons.chevron_left_rounded, color: date.compareTo(t) <= 0 ? C.dim : C.text)),
          Expanded(child: Text(date == t ? 'Сьогодні' : cap(human(date)), textAlign: TextAlign.center, style: T.body(15, C.text, FontWeight.w600))),
          IconButton(tooltip: 'Наступний день', onPressed: () => setState(() => date = addDays(date, 1)), icon: const Icon(Icons.chevron_right_rounded, color: C.text)),
        ]),
        const Label('Час'),
        Chips([
          for (final x in _times) ChipX(x, on: time == x, onTap: () => setState(() => time = x)),
          ChipX(_times.contains(time) ? 'Інший…' : time, on: !_times.contains(time), onTap: _pickTime),
        ]),
        const Label("Де · необов'язково"),
        Chips([for (final p in places) ChipX(p.label, on: place == p.id, onTap: () => setState(() => place = place == p.id ? null : p.id))]),
        VCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwitchRow(title: 'Нагадати за годину', sub: 'Тихе нагадування в календарі, без імені', value: remind, onChanged: (v) => setState(() => remind = v)),
        ),
        if (canSave)
          NavRow(
            title: 'Додати в календар телефону',
            sub: 'Назва «$quietTitle», без імені',
            icon: Icons.event_available_rounded,
            onTap: () async {
              try {
                await addMeetingToPhoneCalendar(m, s.personName(personId), CalendarOptions(quiet: true, place: place != null, remind: remind));
              } catch (_) {
                if (context.mounted) toast(context, 'Не вдалося відкрити календар');
              }
            },
          ),
        if (prev != null && date.compareTo(t) <= 0)
          Btn('Зустріч уже була? Записати', kind: BtnKind.ghost, onTap: () => goReplace(context, EntryForm(personId: personId, date: date))),
        if (prev != null)
          confirmDelete
              ? Row(children: [
                  Expanded(child: Btn('Видалити', kind: BtnKind.danger, onTap: () async { await s.deleteMeeting(prev!.id); if (context.mounted) Navigator.pop(context); })),
                  const SizedBox(width: 8),
                  Expanded(child: Btn('Скасувати', kind: BtnKind.ghost, onTap: () => setState(() => confirmDelete = false))),
                ])
              : Btn('Скасувати зустріч', kind: BtnKind.ghost, onTap: () => setState(() => confirmDelete = true)),
      ],
    );
  }
}
