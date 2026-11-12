import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/export.dart';
import '../logic/stats.dart';
import '../services/files.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'calendar.dart';

/// Експорт: записи або люди в таблицю (CSV), зустрічі в календар (ICS / календар телефону).
/// Безкоштовно для всіх: це її дані. Дизайн: дошка «13. Експорт».
class ExportScreen extends StatefulWidget {
  final bool calendar;
  const ExportScreen({super.key, this.calendar = false});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late bool cal = widget.calendar;
  // таблиця
  bool people = false;
  ExportPeriod period = ExportPeriod.months3;
  bool anon = false, notes = false, sensitive = false;
  // календар
  bool history = false, quiet = true, place = true, remind = true;
  bool busy = false;

  TableOptions get tOpt => TableOptions(period: period, anon: anon, notes: notes, sensitive: sensitive);
  CalendarOptions get cOpt => CalendarOptions(history: history, quiet: quiet, place: place, remind: remind);

  Future<void> _exportTable(AppStore s) async {
    setState(() => busy = true);
    try {
      final csv = people ? peopleCsv(s.db, tOpt) : meetingsCsv(s.db, tOpt);
      final name = 'vespr-${people ? 'lyudy' : 'zustrichi'}-${fileStamp()}.csv';
      await shareTextFile(name, csv, 'text/csv', subject: 'Vespr: ${people ? 'люди' : 'зустрічі'}');
    } catch (e) {
      if (mounted) toast(context, 'Не вдалося створити таблицю: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _exportCalendar(AppStore s) async {
    final planned = plannedMeetings(s.meetings);
    setState(() => busy = true);
    try {
      if (!history && planned.length == 1) {
        // одна зустріч — одразу у вікно календаря телефону
        await addMeetingToPhoneCalendar(planned.first, s.personName(planned.first.personId), cOpt);
      } else {
        await shareTextFile('vespr-${fileStamp()}.ics', buildIcs(s.db, cOpt), 'text/calendar', subject: 'Vespr: зустрічі');
      }
    } catch (e) {
      if (mounted) toast(context, 'Не вдалося: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Widget _opt({required bool on, required IconData icon, required String title, required String sub, required VoidCallback onTap}) => Expanded(
        child: VCard(
          color: on ? C.accentBg : const Color(0x06F1EEF2),
          border: on ? C.accent : C.line,
          padding: const EdgeInsets.all(14),
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: C.accent.withValues(alpha: .12)),
              child: Icon(icon, size: 16, color: C.accent),
            ),
            const SizedBox(height: 8),
            Text(title, style: T.body(15, C.text, FontWeight.w600)),
            Txt(sub, small: true, muted: true),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final es = entriesInPeriod(s.entries, period);
    final planned = plannedMeetings(s.meetings);
    final names = nameMap(s.people, anon);
    final peopleRows = <List<String>>[];
    for (final p in s.people) {
      final st = personStats(es, p.id);
      if (st.n == 0) continue;
      peopleRows.add([names[p.id] ?? '', '${st.n}', fmt(st.overall), st.sexN > 0 ? fmt(st.sex) : '—', '${st.red}']);
    }

    return Screen(
      footer: [
        if (!cal) Btn(busy ? 'Зачекай…' : 'Створити таблицю', icon: Icons.download_rounded, onTap: busy || es.isEmpty ? null : () => _exportTable(s)),
        if (cal) Btn(busy ? 'Зачекай…' : 'Додати в календар', icon: Icons.event_available_rounded, onTap: busy || (planned.isEmpty && (!history || s.entries.isEmpty)) ? null : () => _exportCalendar(s)),
      ],
      children: [
        const Header(title: 'Експорт'),
        const H1('Забрати', accent: 'свої дані'),
        const Txt('Записи в таблицю або зустрічі в календар. Безкоштовно, без ліміту.', muted: true),
        Seg<bool>(options: const [SegOpt(false, 'Таблиця'), SegOpt(true, 'Календар')], value: cal, onChange: (v) => setState(() => cal = v)),
        if (!cal) ...[
          const Label('Що в таблиці'),
          Row(children: [
            _opt(on: !people, icon: Icons.view_list_rounded, title: 'Зустрічі', sub: 'Кожен запис рядком: оцінки, прапорці, теги', onTap: () => setState(() => people = false)),
            const SizedBox(width: 8),
            _opt(on: people, icon: Icons.people_alt_outlined, title: 'Люди', sub: 'Підсумок по кожному: середні і прапорці', onTap: () => setState(() => people = true)),
          ]),
          const Label('Період'),
          Chips([for (final p in ExportPeriod.values) ChipX(periodLabels[p]!, on: period == p, onTap: () => setState(() => period = p))]),
          VCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchRow(title: 'Без імен', sub: 'Імена → №1, №2 за порядком додавання', value: anon, onChanged: (v) => setState(() => anon = v)),
              if (!people) SwitchRow(title: 'Нотатки', sub: 'Текст нотаток до записів', value: notes, onChanged: (v) => setState(() => notes = v)),
              if (!people) SwitchRow(title: 'Чутливе', sub: 'Захист, дискомфорт, «вдавала», критичні прапорці', value: sensitive, onChanged: (v) => setState(() => sensitive = v)),
            ]),
          ),
          Label(people ? 'Як виглядатиме' : 'Перші рядки'),
          _SheetPreview(
            title: 'vespr-${people ? 'lyudy' : 'zustrichi'}-${fileStamp()}.csv',
            header: people ? const ['Людина', 'Зустрічей', 'Загалом', 'Секс', 'Червоні'] : const ['Дата', 'Людина', 'Загалом', 'Секс', 'Прапорці'],
            rows: people
                ? peopleRows
                : [
                    for (final e in es.take(4))
                      [toUA(e.date), names[e.personId] ?? '—', '${e.overall}', e.hadSex ? '${e.ratings['sx_overall'] ?? e.overall}' : '—', '${e.flags.length}'],
                  ],
          ),
          Txt(es.isEmpty ? 'За цей період записів немає.' : (people ? 'Ще стовпці: статус, кінчала, зелені, перша і остання зустріч.' : '${es.length} ${plural(es.length, 'рядок', 'рядки', 'рядків')} · ще стовпці: тип, твої питання, теги, факти${notes ? ', нотатка' : ''}.'), small: true, muted: true),
        ],
        if (cal) ...[
          const Label('Що додати'),
          Row(children: [
            _opt(on: !history, icon: Icons.schedule_rounded, title: 'Заплановані', sub: 'Майбутні зустрічі · ${planned.length}', onTap: () => setState(() => history = false)),
            const SizedBox(width: 8),
            _opt(on: history, icon: Icons.history_rounded, title: 'Уся історія', sub: 'Ще й минулі · ${planned.length + s.entries.length}', onTap: () => setState(() => history = true)),
          ]),
          VCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchRow(title: 'Тиха назва', sub: '«$quietTitle» замість імені. Календар бачать інші апки й пристрої', value: quiet, onChanged: (v) => setState(() => quiet = v)),
              SwitchRow(title: 'Місце', sub: 'Бар, ресторан, у нього…', value: place, onChanged: (v) => setState(() => place = v)),
              SwitchRow(title: 'Нагадати за годину', sub: 'Нагадування самого календаря', value: remind, onChanged: (v) => setState(() => remind = v)),
            ]),
          ),
          const Label('Так це виглядатиме в календарі'),
          if (planned.isEmpty && !history)
            VCard(
              onTap: () => go(context, const MeetingForm()),
              child: const Txt('Запланованих зустрічей поки немає. Запланувати ›', muted: true),
            ),
          for (final m in planned.take(3))
            _EventRow(
              title: meetingTitle(m, s.personName(m.personId), quiet),
              sub: '${cap(human(m.date))}${place && m.place != null ? ' · ${placeLabel(m.place)}' : ''}',
              time: m.time,
            ),
          if (history)
            for (final e in ([...s.entries]..sort((a, b) => b.date.compareTo(a.date))).take(2))
              _EventRow(title: quiet ? quietTitle : s.personName(e.personId), sub: '${cap(human(e.date))} · весь день', time: 'було', past: true),
          const _Note(Icons.info_outline_rounded, 'Якщо додати ще раз, зустрічі оновляться, а не задвояться. Одну зустріч відкриємо одразу в календарі, кілька — файлом для Google чи Apple Календаря.'),
        ],
        const _Note(Icons.lock_outline_rounded, 'Файл виходить за межі Vespr і вже не захищений PIN-кодом. Зберігай його там, де його бачиш тільки ти.'),
      ],
    );
  }
}

class _SheetPreview extends StatelessWidget {
  final String title;
  final List<String> header;
  final List<List<String>> rows;
  const _SheetPreview({required this.title, required this.header, required this.rows});
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17161F);
    TextStyle st(bool h) => T.body(12, h ? const Color(0xFF5E5874) : ink, h ? FontWeight.w600 : FontWeight.w500);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: C.text,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: const Color(0xFFE6E2EC),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF3FA06A), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: T.body(12, const Color(0xFF3E3950), FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFECE8F1)), verticalInside: BorderSide(color: Color(0xFFECE8F1))),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF7F5FA)),
                  children: [for (final h in header) Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text(h, style: st(true)))],
                ),
                for (final r in rows)
                  TableRow(children: [for (final c in r) Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text(c, style: st(false)))]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String title, sub, time;
  final bool past;
  const _EventRow({required this.title, required this.sub, required this.time, this.past = false});
  @override
  Widget build(BuildContext context) => VCard(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 4, decoration: BoxDecoration(color: past ? C.dim : C.accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: T.body(14, C.text, FontWeight.w600)),
                Txt(sub, small: true, muted: true),
              ]),
            ),
            Center(child: Txt(time, small: true, muted: true)),
          ]),
        ),
      );
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x06F1EEF2), borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: C.accent),
          const SizedBox(width: 10),
          Expanded(child: Txt(text, small: true, muted: true)),
        ]),
      );
}
