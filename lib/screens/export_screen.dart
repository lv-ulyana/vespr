import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/export.dart';
import '../logic/stats.dart';
import '../services/files.dart';
import '../ui/board.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
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
      if (mounted) dToast(context, 'Не вдалося створити таблицю: $e');
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
      if (mounted) dToast(context, 'Не вдалося: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  static const _wd = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  String _when(String isoDate) {
    final d = parseIso(isoDate);
    return '${_wd[d.weekday - 1]}, ${d.day} ${monthsGen[d.month - 1]}';
  }

  void _done(AppStore s) {
    final apps = !cal
        ? const [('G', 'Google Таблиці', 'Через Google Диск', Color(0xFF9FCBA9)), ('X', 'Excel', 'Або Numbers на iPhone', Color(0xFFB9D4C2)), ('↗', 'Інше', 'Telegram «Збережене», файли, пошта', Color(0xFFC9C4D6))]
        : const [('G', 'Google Календар', 'Android і iPhone', Color(0xFFF4A189)), ('A', 'Календар iPhone', 'Стандартний календар Apple', Color(0xFFF1EEF2)), ('↗', 'Файл .ics', 'Для Outlook або іншого календаря', Color(0xFFC9C4D6))];
    showSheet(
      context,
      (ctx) => Sheet(children: [
        sheetTitle(cal ? 'Куди додати?' : 'Таблиця готова'),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: sheetText(cal
              ? 'Відкриється твій календар з уже заповненими зустрічами. Залишиться тільки підтвердити.'
              : 'Файл CSV відкривається в Excel, Google Таблицях і Numbers. Обери, куди його відправити.'),
        ),
        for (final a in apps)
          XOpt(
            title: a.$2,
            sub: a.$3,
            radio: false,
            lead: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: a.$4, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(a.$1, style: rw(13, color: K.bg, w: FontWeight.w700)),
            ),
            onTap: () {
              Navigator.pop(ctx);
              if (!cal) {
                _exportTable(s);
              } else if (a.$1 == '↗') {
                _exportIcs(s);
              } else {
                _exportCalendar(s);
              }
            },
          ),
        Padding(padding: const EdgeInsets.only(top: 4), child: GhostBtn('Скасувати', onTap: () => Navigator.pop(ctx))),
      ]),
    );
  }

  Future<void> _exportIcs(AppStore s) async {
    setState(() => busy = true);
    try {
      await shareTextFile('vespr-${fileStamp()}.ics', buildIcs(s.db, cOpt), 'text/calendar', subject: 'Vespr: зустрічі');
    } catch (e) {
      if (mounted) dToast(context, 'Не вдалося: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Widget _swRow(String title, String sub, bool v, ValueChanged<bool> on) => GRow(
        title: title,
        sub: sub,
        onTap: () => on(!v),
        trailing: SwS(on: v, label: title, onChanged: on),
      );

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final es = entriesInPeriod(s.entries, period);
    final planned = plannedMeetings(s.meetings);
    final names = nameMap(s.people, anon);
    final real = nameMap(s.people, false).values.toList();
    final peopleRows = <List<String>>[];
    for (final p in s.people) {
      final st = personStats(es, p.id);
      if (st.n == 0) continue;
      peopleRows.add([names[p.id] ?? '', '${st.n}', fmt(st.overall), st.sexN > 0 ? fmt(st.sex) : '—', '${st.green}', '${st.red}']);
    }
    String flagNames(List<String> ids, bool green) => ids
        .map(flagById)
        .where((f) => f != null && (green ? f.kind == FlagKind.g : f.kind != FlagKind.g) && (sensitive || f.kind != FlagKind.c))
        .map((f) => f!.label)
        .join(', ');
    final canTable = !busy && es.isNotEmpty;
    final canCal = !busy && (planned.isNotEmpty || (history && s.entries.isNotEmpty));

    return DScroll(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
      overlay: const [],
      children: [
        const BoardHeader('Експорт'),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          titleAcc(const [('Забрати\n', false), ('свої дані', true)], 34),
          const SizedBox(height: 8),
          Text('Записи в таблицю або зустрічі в календар. Безкоштовно, без ліміту.', style: rw(14, color: K.muted, h: 1.5)),
        ]),
        Tabs(items: [('Таблиця', BS.table), ('Календар', BS.cal)], index: cal ? 1 : 0, onChanged: (i) => setState(() => cal = i == 1)),
        if (!cal) ...[
          labeled(
            'Що в таблиці',
            optPair(
              OptCard(on: !people, svg: BS.list, title: 'Зустрічі', sub: 'Кожен запис рядком: оцінки, прапорці, теги', onTap: () => setState(() => people = false)),
              OptCard(on: people, svg: BS.people, title: 'Люди', sub: 'Підсумок по кожному: середні і прапорці', onTap: () => setState(() => people = true)),
            ),
          ),
          labeled('Період', chipsWrap([for (final p in ExportPeriod.values) DChip(periodLabels[p]!, on: period == p, onTap: () => setState(() => period = p))])),
          Grp(inset: 14, [
            _swRow('Без імен', real.length >= 2 ? '${real[0]} → №1, ${real[1]} → №2' : 'Імена → №1, №2 за порядком додавання', anon, (v) => setState(() => anon = v)),
            if (!people) _swRow('Нотатки', 'Текст і розшифровки голосових', notes, (v) => setState(() => notes = v)),
            if (!people) _swRow('Чутливе', 'Захист, дискомфорт, «вдавала», критичні прапорці', sensitive, (v) => setState(() => sensitive = v)),
          ]),
          labeled(
            people ? 'Як виглядатиме' : 'Перші рядки',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _SheetPreview(
                title: 'vespr-${people ? 'lyudy' : 'zustrichi'}-${fileStamp()}.csv',
                header: people ? const ['Людина', 'Зустрічей', 'Загалом', 'Секс', 'Зелені', 'Червоні'] : const ['Дата', 'Людина', 'Загалом', 'Секс', 'Зелені', 'Червоні'],
                numeric: people ? const {1, 2, 3, 4, 5} : const {2, 3},
                green: people ? 4 : 4,
                red: 5,
                rows: people
                    ? peopleRows
                    : [
                        for (final e in es.take(4))
                          [toUA(e.date), names[e.personId] ?? '—', '${e.overall}', e.hadSex ? '${e.ratings['sx_overall'] ?? e.overall}' : '—', flagNames(e.flags, true), flagNames(e.flags, false)],
                      ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  es.isEmpty
                      ? 'За цей період записів немає.'
                      : (people
                          ? '${peopleRows.length} ${plural(peopleRows.length, 'людина', 'людини', 'людей')} · ще стовпці: статус, кінчала, тренд'
                          : '${es.length} ${plural(es.length, 'рядок', 'рядки', 'рядків')} · ще стовпці: тип, твої питання, теги, факти${notes ? ', нотатка' : ''}'),
                  style: rw(12, color: K.haze),
                ),
              ),
            ]),
          ),
          CtaIco(busy ? 'Зачекай…' : 'Створити таблицю', svg: BS.download, onTap: canTable ? () => _done(s) : null),
        ],
        if (cal) ...[
          labeled(
            'Що додати',
            optPair(
              OptCard(on: !history, svg: BS.clock, title: 'Заплановані', sub: 'Майбутні зустрічі · ${planned.length}', onTap: () => setState(() => history = false)),
              OptCard(on: history, svg: BS.list3, title: 'Уся історія', sub: 'Ще й минулі зустрічі · ${planned.length + s.entries.length}', onTap: () => setState(() => history = true)),
            ),
          ),
          Grp(inset: 14, [
            _swRow('Тиха назва', '«$quietTitle» замість імені. Календар бачать інші апки й пристрої', quiet, (v) => setState(() => quiet = v)),
            _swRow('Місце', 'Бар, ресторан, у нього…', place, (v) => setState(() => place = v)),
            _swRow('Нагадати за годину', 'Нагадування самого календаря', remind, (v) => setState(() => remind = v)),
          ]),
          labeled(
            'Так це виглядатиме в календарі',
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              if (planned.isEmpty && !history)
                Press(
                  onTap: () => go(context, const MeetingForm()),
                  child: _EventRow(title: 'Запланованих зустрічей поки немає', sub: 'Запланувати ›', time: '', past: true),
                ),
              for (final m in planned.take(history ? 1 : 3))
                _EventRow(
                  title: meetingTitle(m, s.personName(m.personId), quiet),
                  sub: '${_when(m.date)}${place && (m.placeText ?? m.place) != null ? ' · ${m.placeText ?? placeLabel(m.place)}' : ''}',
                  time: m.time,
                ),
              if (history)
                for (final e in ([...s.entries]..sort((a, b) => b.date.compareTo(a.date))).take(2))
                  _EventRow(title: quiet ? quietTitle : s.personName(e.personId), sub: '${_when(e.date)} · весь день', time: 'було', past: true),
            ], 8)),
          ),
          NoteBox('Якщо додати ще раз, зустрічі оновляться, а не задвояться. Видалити з календаря можна тільки в самому календарі.'),
          CtaIco(busy ? 'Зачекай…' : 'Додати в календар', svg: BS.calPlus, onTap: canCal ? () => _done(s) : null),
        ],
        NoteBox('Файл виходить за межі Vespr і вже не захищений PIN-кодом. Зберігай його там, де його бачиш тільки ти.', svg: BS.lock),
      ],
    );
  }
}

class _SheetPreview extends StatelessWidget {
  final String title;
  final List<String> header;
  final List<List<String>> rows;
  final Set<int> numeric;
  final int green, red;
  const _SheetPreview({required this.title, required this.header, required this.rows, this.numeric = const {}, this.green = -1, this.red = -1});
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17161F);
    const line = Color(0xFFECE8F1);
    Color colOf(int i) => i == green ? const Color(0xFF2E7D4F) : (i == red ? const Color(0xFFB3261E) : ink);
    Widget cell(String t, int i, {bool head = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: !head && numeric.contains(i) ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(t, style: rw(12, color: head ? const Color(0xFF5E5874) : colOf(i), w: head ? FontWeight.w600 : FontWeight.w500)),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: K.star,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0xCC000000), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -24)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: const Color(0xFFE6E2EC),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF3FA06A), borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: rw(12, color: const Color(0xFF3E3950), w: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 350),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: const TableBorder(horizontalInside: BorderSide(color: line), verticalInside: BorderSide(color: line), bottom: BorderSide(color: line)),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF7F5FA), border: Border(bottom: BorderSide(color: Color(0xFFDCD7E3)))),
                  children: [for (var i = 0; i < header.length; i++) cell(header[i], i, head: true)],
                ),
                for (final r in rows) TableRow(children: [for (var i = 0; i < r.length; i++) cell(r[i], i)]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _EventRow extends StatelessWidget {
  final String title, sub, time;
  final bool past;
  const _EventRow({required this.title, required this.sub, required this.time, this.past = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.06))),
        child: Row(children: [
          Container(width: 4, height: 38, decoration: BoxDecoration(color: past ? K.dimC : K.acc, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              title.startsWith('✦')
                  ? Row(children: [const Ico(Svgs.star4, size: 11, color: K.star), const SizedBox(width: 5), Text(title.substring(1).trim(), style: rw(14, w: FontWeight.w600))])
                  : Text(title, style: rw(14, w: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(sub, style: rw(12, color: K.muted)),
            ]),
          ),
          if (time.isNotEmpty) Text(time, style: rw(12, color: K.muted)),
        ]),
      );
}
