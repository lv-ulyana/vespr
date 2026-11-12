// Експорт: записи і люди в таблицю (CSV), зустрічі в календар (ICS).
// CSV: UTF-8 з BOM, роздільник «;», кома в числах — Excel в українській локалі відкриває одразу,
// Google Таблиці і Numbers теж розуміють.
import '../data/catalog.dart';
import '../data/models.dart';
import 'dates.dart';
import 'stats.dart';

enum ExportPeriod { month, months3, year, all }

const periodLabels = {
  ExportPeriod.month: 'Цей місяць',
  ExportPeriod.months3: '3 місяці',
  ExportPeriod.year: 'Рік',
  ExportPeriod.all: 'Усе',
};

/// Перший день періоду (включно) або null для «Усе»
String? periodStart(ExportPeriod p, DateTime now) {
  switch (p) {
    case ExportPeriod.month:
      return iso(DateTime(now.year, now.month, 1));
    case ExportPeriod.months3:
      return iso(DateTime(now.year, now.month - 2, 1));
    case ExportPeriod.year:
      return iso(DateTime(now.year - 1, now.month, now.day));
    case ExportPeriod.all:
      return null;
  }
}

class TableOptions {
  final ExportPeriod period;
  final bool anon, notes, sensitive;
  const TableOptions({this.period = ExportPeriod.months3, this.anon = false, this.notes = false, this.sensitive = false});
}

/// «Без імен»: №1, №2… за порядком додавання людей
Map<String, String> nameMap(List<Person> people, bool anon) {
  final sorted = [...people]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return {for (var i = 0; i < sorted.length; i++) sorted[i].id: anon ? '№${i + 1}' : sorted[i].name};
}

List<Entry> entriesInPeriod(List<Entry> all, ExportPeriod p, [DateTime? now]) {
  final from = periodStart(p, now ?? DateTime.now());
  final es = all.where((e) => from == null || e.date.compareTo(from) >= 0).toList();
  es.sort((a, b) => b.date.compareTo(a.date));
  return es;
}

String _cell(Object? v) {
  final s = v == null ? '' : v.toString();
  if (s.contains(';') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _csv(List<List<Object?>> rows) => '\uFEFF${rows.map((r) => r.map(_cell).join(';')).join('\r\n')}\r\n';

String _num(double v) => v.isFinite ? fmt(v) : '';

/// Таблиця «Зустрічі»: рядок на запис
String meetingsCsv(DB db, TableOptions o, [DateTime? now]) {
  final es = entriesInPeriod(db.entries, o.period, now);
  final names = nameMap(db.people, o.anon);
  // стовпці тільки для питань, на які є хоч одна відповідь
  final qIds = allQuestions.where((q) => es.any((e) => e.ratings.containsKey(q.id))).map((q) => q.id).toList();
  final header = <Object?>[
    'Дата', 'День тижня', 'Людина', 'Хто він', 'Був секс', 'Як загалом',
    ...qIds.where((id) => id != 'sx_overall').map((id) => qById(id)!.text),
    'Зелені прапорці', 'Червоні прапорці', if (o.sensitive) 'Критичні прапорці',
    'Що було', ...facts.map((f) => f.label), if (o.notes) 'Нотатка',
  ];
  final rows = <List<Object?>>[header];
  for (final e in es) {
    final p = db.people.where((x) => x.id == e.personId);
    final rel = p.isEmpty ? '' : relLabel(p.first.rel);
    List<String> fl(FlagKind k) => e.flags.where((f) => flagById(f)?.kind == k).map((f) => flagById(f)!.label).toList();
    final tags = e.tags.where((t) => o.sensitive || !sensitiveTags.contains(t)).map(tagLabel).toList();
    rows.add([
      toUA(e.date),
      weekdays[parseIso(e.date).weekday],
      names[e.personId] ?? '—',
      rel,
      e.hadSex ? 'так' : 'ні',
      e.overall,
      ...qIds.where((id) => id != 'sx_overall').map((id) => e.ratings[id]),
      fl(FlagKind.g).join(', '),
      fl(FlagKind.r).join(', '),
      if (o.sensitive) fl(FlagKind.c).join(', '),
      tags.join(', '),
      ...facts.map((f) => e.facts[f.id] == null ? '' : f.steps[e.facts[f.id]!]),
      if (o.notes) e.note,
    ]);
  }
  return _csv(rows);
}

/// Таблиця «Люди»: рядок на людину (за обраний період)
String peopleCsv(DB db, TableOptions o, [DateTime? now]) {
  final es = entriesInPeriod(db.entries, o.period, now);
  final names = nameMap(db.people, o.anon);
  final rows = <List<Object?>>[
    ['Людина', 'Хто він', 'Статус', 'Причина', 'Зустрічей', 'Загалом', 'Секс', 'Кінчала', 'Зелені прапорці', 'Червоні прапорці', 'Перша зустріч', 'Остання зустріч'],
  ];
  final people = [...db.people]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  for (final p in people) {
    final st = personStats(es, p.id);
    if (st.n == 0) continue;
    rows.add([
      names[p.id],
      relLabel(p.rel),
      p.isPast ? 'минулі' : 'зараз',
      p.isPast ? pastReasonLabel(p.pastReason) : '',
      st.n,
      _num(st.overall),
      st.sexN > 0 ? _num(st.sex) : '',
      st.orgN > 0 ? '${st.orgMe} з ${st.orgN}' : '',
      st.green,
      st.red,
      toUA(st.first),
      toUA(st.last),
    ]);
  }
  return _csv(rows);
}

// ---------- Календар ----------
class CalendarOptions {
  final bool history, quiet, place, remind;
  const CalendarOptions({this.history = false, this.quiet = true, this.place = true, this.remind = true});
}

const quietTitle = '✦ Vespr';
const meetingHours = 2;

String _icsText(String s) => s.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll('\n', '\\n');
String _dt(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}00';
String _day(String isoDate) => isoDate.replaceAll('-', '');

DateTime meetingStart(Meeting m) {
  final t = m.time.split(':');
  final d = parseIso(m.date);
  return DateTime(d.year, d.month, d.day, int.tryParse(t[0]) ?? 20, int.tryParse(t.length > 1 ? t[1] : '0') ?? 0);
}

String meetingTitle(Meeting m, String name, bool quiet) => quiet ? quietTitle : 'Побачення: $name';

List<Meeting> plannedMeetings(List<Meeting> all, [DateTime? now]) {
  final t = iso(now ?? DateTime.now());
  return all.where((m) => m.date.compareTo(t) >= 0).toList()..sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'));
}

/// Минулі зустрічі, про які ще нема запису (та сама людина, та сама дата) — пропонуємо оцінити
List<Meeting> unratedMeetings(List<Meeting> all, List<Entry> entries, [DateTime? now]) {
  final t = iso(now ?? DateTime.now());
  final done = entries.map((e) => '${e.personId}|${e.date}').toSet();
  return all.where((m) => m.date.compareTo(t) < 0 && !done.contains('${m.personId}|${m.date}')).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

/// Файл .ics. Кожна подія має сталий UID, тож повторний імпорт оновлює, а не дублює.
String buildIcs(DB db, CalendarOptions o, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final stamp = '${_dt(n.toUtc())}Z';
  final b = StringBuffer()
    ..write('BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Vespr//Diary//UK\r\nCALSCALE:GREGORIAN\r\nMETHOD:PUBLISH\r\n');
  for (final m in plannedMeetings(db.meetings, n)) {
    final start = meetingStart(m);
    final end = start.add(const Duration(hours: meetingHours));
    b
      ..write('BEGIN:VEVENT\r\n')
      ..write('UID:meeting-${m.id}@vespr.app\r\n')
      ..write('DTSTAMP:$stamp\r\n')
      ..write('DTSTART:${_dt(start)}\r\n')
      ..write('DTEND:${_dt(end)}\r\n')
      ..write('SUMMARY:${_icsText(meetingTitle(m, db.people.where((p) => p.id == m.personId).map((p) => p.name).firstOrNull ?? '', o.quiet))}\r\n');
    if (o.place && m.place != null) b.write('LOCATION:${_icsText(placeLabel(m.place))}\r\n');
    if (o.remind) {
      b.write('BEGIN:VALARM\r\nACTION:DISPLAY\r\nDESCRIPTION:${_icsText(quietTitle)}\r\nTRIGGER:-PT1H\r\nEND:VALARM\r\n');
    }
    b.write('END:VEVENT\r\n');
  }
  if (o.history) {
    final es = [...db.entries]..sort((a, c) => a.date.compareTo(c.date));
    for (final e in es) {
      final name = db.people.where((p) => p.id == e.personId).map((p) => p.name).firstOrNull ?? '';
      b
        ..write('BEGIN:VEVENT\r\n')
        ..write('UID:entry-${e.id}@vespr.app\r\n')
        ..write('DTSTAMP:$stamp\r\n')
        ..write('DTSTART;VALUE=DATE:${_day(e.date)}\r\n')
        ..write('DTEND;VALUE=DATE:${_day(addDays(e.date, 1))}\r\n')
        ..write('SUMMARY:${_icsText(o.quiet ? quietTitle : name)}\r\n')
        ..write('TRANSP:TRANSPARENT\r\n')
        ..write('END:VEVENT\r\n');
    }
  }
  b.write('END:VCALENDAR\r\n');
  return b.toString();
}

String fileStamp([DateTime? now]) {
  final n = now ?? DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}
