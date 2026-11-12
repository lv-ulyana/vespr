// Тести логіки Vespr: `flutter test`
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/data/models.dart';
import 'package:vespr/data/store.dart';
import 'package:vespr/logic/astro.dart';
import 'package:vespr/logic/dates.dart';
import 'package:vespr/logic/export.dart';
import 'package:vespr/logic/import_csv.dart';
import 'package:vespr/logic/import_ics.dart';
import 'package:vespr/logic/stats.dart';
import 'package:vespr/logic/triggers.dart';
import 'package:vespr/logic/wrapped.dart';

int _n = 0;
Entry e(String p, String date, int overall, bool sex, List<String> tags, [List<String> flags = const [], Map<String, int> facts = const {}]) => Entry(
      id: 'e${_n++}', personId: p, date: date, overall: overall, hadSex: sex,
      ratings: sex ? {'sx_overall': overall} : {}, tags: tags, flags: flags, facts: Map.of(facts), note: 'нотатка; з "лапками"', createdAt: date,
    );

final people = [
  Person(id: 'a', name: 'Архітектор', birth: '1995-10-03', createdAt: '2026-09-01'),
  Person(id: 'm', name: 'Марк', signOnly: 7, createdAt: '2026-09-02'),
  Person(id: 'd', name: 'Д.', status: 'past', pastReason: 'gone', pastAt: '2026-10-20', createdAt: '2026-09-03'),
];

final entries = [
  e('a', '2026-09-05', 5, true, ['talk', 'fore', 'slow', 'sober', 'o_me', 'o_him', 'condom'], ['flag_g_walk']),
  e('a', '2026-09-12', 4, true, ['talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_asks']),
  e('m', '2026-09-20', 2, true, ['notalk', 'nofore', 'rush', 'alco1', 'o_none_sad', 'o_him'], ['flag_r_phone', 'flag_r_ex']),
  e('a', '2026-10-03', 5, true, ['talk', 'fore', 'slow', 'sober', 'o_multi', 'o_him'], ['flag_g_walk', 'flag_g_paid']),
  e('m', '2026-10-08', 2, true, ['notalk', 'nofore', 'rush', 'alco2', 'o_fake', 'o_him', 'pain'], ['flag_r_phone', 'flag_r_push']),
  e('d', '2026-10-11', 3, false, ['talk', 'alco1'], ['flag_r_late', 'flag_r_ex']),
  e('m', '2026-10-14', 3, true, ['notalk', 'nofore', 'rush', 'alco1', 'o_fake', 'o_him', 'silent'], ['flag_r_phone', 'flag_c_photo']),
  e('a', '2026-10-20', 4, true, ['talk', 'fore', 'slow', 'sober', 'o_me', 'o_him_no'], ['flag_g_walk'], {'f_init': 0}),
  e('a', '2026-10-24', 5, true, ['talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_texts']),
];

void main() {
  test('знак і аркан', () {
    final me = astroOf('2001-09-14')!;
    expect(me.signName, 'Діва');
    expect(me.arcanaName, 'Помірність');
    expect(astroOf('2001-01-05')!.signName, 'Козеріг');
    expect(astroOf('2001-12-25')!.signName, 'Козеріг');
    expect(astroOf('2001-03-21')!.signName, 'Овен');
    expect(pairArcana(14, 3), 17);
  });

  test('дати', () {
    expect(parseUA('14.09.2001'), '2001-09-14');
    expect(parseUA('31.02.2001'), isNull);
    expect(maskDate('14092001'), '14.09.2001');
    expect(plural(1, 'запис', 'записи', 'записів'), 'запис');
    expect(plural(12, 'запис', 'записи', 'записів'), 'записів');
    expect(plural(22, 'запис', 'записи', 'записів'), 'записи');
  });

  test('ефекти тегів', () {
    final eff = effects(entries);
    final fore = eff.firstWhere((x) => x.id == 'fore');
    expect(fore.delta, greaterThan(2));
    expect(fore.level, 'Схоже');
  });

  test('статистика людини', () {
    final st = personStats(entries, 'a');
    expect(st.n, 5);
    expect(st.overall, closeTo(4.6, 0.01));
    expect(st.orgMe, 5);
    final m = personStats(entries, 'm');
    expect(m.fake, 2);
  });

  test('безпека', () {
    expect(isUnsafe(entries[6]), isTrue);
    expect(isUnsafe(entries[0]), isFalse);
  });

  test('тригери прапорців', () {
    final f = suggestFlags('він не тиснув, сам спитав, чи мені комфортно, потім провів до хати. але піввечора сидів у телефоні');
    expect(f, containsAll(['flag_g_no', 'flag_g_asks', 'flag_g_walk', 'flag_r_phone']));
    expect(f, isNot(contains('flag_r_push')));
    expect(suggestFlags('не запізнився, прийшов вчасно'), ['flag_g_ontime']);
  });

  test('Wrapped', () {
    final w = buildWrapped('2026-10', entries, people);
    expect(w.mini, isFalse);
    expect(w.slides.first.key, 'cover');
    expect(w.slides.map((s) => s.key), containsAll(['best', 'sex', 'shame', 'type', 'notice', 'end']));
    expect(w.slides.firstWhere((s) => s.key == 'notice').private, isTrue);
    expect(buildWrapped('2026-08', entries, people).slides.single.key, 'empty');
  });

  test('експорт у таблицю', () {
    final db = DB(profile: Profile(), people: people, entries: entries, meetings: []);
    final now = DateTime(2026, 10, 30);
    final csv = meetingsCsv(db, const TableOptions(period: ExportPeriod.all, notes: true), now);
    expect(csv.startsWith('﻿Дата;День тижня;Людина'), isTrue);
    expect(csv.contains('"нотатка; з ""лапками"""'), isTrue);
    expect(csv.contains('Симулювала'), isFalse); // чутливе вимкнене
    expect(csv.contains('Знімав без дозволу'), isFalse);
    final anon = meetingsCsv(db, const TableOptions(period: ExportPeriod.month, anon: true), now);
    expect(anon.contains('Архітектор'), isFalse);
    expect(anon.contains('№1'), isTrue);
    final ppl = peopleCsv(db, const TableOptions(period: ExportPeriod.all), now);
    expect(ppl.split('\r\n').where((l) => l.isNotEmpty).length, 4);
  });

  test('експорт у календар', () {
    final db = DB(profile: Profile(), people: people, entries: entries, meetings: [
      Meeting(id: 'x1', personId: 'm', date: '2026-11-14', time: '20:00', place: 'bar'),
      Meeting(id: 'x0', personId: 'a', date: '2026-10-01', time: '19:00'),
    ]);
    final ics = buildIcs(db, const CalendarOptions(), DateTime(2026, 10, 30));
    expect(ics.contains('UID:meeting-x1@vespr.app'), isTrue);
    expect(ics.contains('UID:meeting-x0'), isFalse); // минула зустріч
    expect(ics.contains('SUMMARY:✦ Vespr'), isTrue);
    expect(ics.contains('Марк'), isFalse); // тиха назва
    expect(ics.contains('DTSTART:20261114T200000'), isTrue);
    expect(ics.contains('TRIGGER:-PT1H'), isTrue);
    final loud = buildIcs(db, const CalendarOptions(quiet: false, history: true), DateTime(2026, 10, 30));
    expect(loud.contains('SUMMARY:Побачення: Марк'), isTrue);
    expect(loud.contains('DTSTART;VALUE=DATE:20261024'), isTrue);
  });

  test('імпорт: наш експорт туди і назад', () {
    final now = DateTime(2026, 10, 30);
    final src = DB(profile: Profile(), people: people, entries: entries, meetings: []);
    final csv = meetingsCsv(src, const TableOptions(period: ExportPeriod.all, notes: true, sensitive: true), now);
    final t = parseCsv(csv);
    expect(t.sep, ';');
    expect(t.rows.length, entries.length);
    final map = autoMap(t.header);
    expect(missingRequired(map), isEmpty);
    expect(map[t.header.indexOf('День тижня')], isNull);
    var n = 0;
    final empty = DB(profile: Profile(), people: [], entries: [], meetings: []);
    final plan = planCsvImport(t, map, empty, newId: () => 'id${n++}', now: now);
    expect(plan.entries.length, entries.length);
    expect(plan.newPeople.map((p) => p.name).toSet(), {'Архітектор', 'Марк', 'Д.'});
    expect(plan.skipped, isEmpty);
    final first = plan.entries.firstWhere((x) => x.date == '2026-10-20');
    expect(first.overall, 4);
    expect(first.hadSex, isTrue);
    expect(first.flags, ['flag_g_walk']); // «Провів, викликав таксі» — з комою всередині
    expect(first.tags.toSet(), {'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him_no'});
    expect(first.facts['f_init'], 0);
    expect(first.note, 'нотатка; з "лапками"');
    final d = plan.entries.firstWhere((x) => x.date == '2026-10-11');
    expect(d.hadSex, isFalse);
    expect(d.flags.toSet(), {'flag_r_late', 'flag_r_ex'});
    // повторно в базу, де це вже є, — усе дублі
    final again = planCsvImport(t, map, src, newId: () => 'z${n++}', now: now);
    expect(again.entries, isEmpty);
    expect(again.duplicates, entries.length);
    expect(again.newPeople, isEmpty);
  });

  test('імпорт: своя таблиця з комами і кривими рядками', () {
    const text = 'Коли,Хто,Оцінка,Секс?,Коментар\n'
        '14.10.25,Олег,4,так,"кава, потім кіно"\n'
        '2025-10-20,олег,"4,6",,\n'
        '21.10.2025,Тарас,4+,ні,\n'
        '31.02.2025,Тарас,3,ні,\n'
        ',Тарас,3,ні,\n';
    final t = parseCsv(text);
    expect(t.sep, ',');
    final map = autoMap(t.header);
    expect(map, ['date', 'person', 'overall', 'sex', 'note']);
    final plan = planCsvImport(t, map, DB(profile: Profile(), people: [], entries: [], meetings: []), newId: uid, now: DateTime(2026, 1, 1));
    expect(plan.entries.length, 2);
    expect(plan.newPeople.map((p) => p.name), ['Олег']); // «олег» — та сама людина; Тарас без жодного доброго рядка
    expect(plan.entries[1].overall, 5); // 4,6 → 5
    expect(plan.entries[0].note, 'кава, потім кіно');
    expect(plan.skipped.map((r) => r.line), [4, 5, 6]);
  });

  test('імпорт: кодування і значення', () {
    // «Дата;Людина» у Windows-1251
    final bytes = [0xC4, 0xE0, 0xF2, 0xE0, 0x3B, 0xCB, 0xFE, 0xE4, 0xE8, 0xED, 0xE0, 0x3B, 0xB2, 0xBF, 0xBA];
    expect(decodeTextFile(bytes), 'Дата;Людина;Іїє');
    expect(decodeTextFile(utf8Bytes('Дата')), 'Дата');
    expect(parseRating('вогонь'), 5);
    expect(parseRating('0'), isNull);
    expect(parseRating('3/5'), 3);
    expect(parseAnyDate('01.01.2027', DateTime(2026, 6, 1)), isNull); // майбутнє
    expect(parseYesNo('Так'), isTrue);
    expect(parseYesNo('—'), isFalse);
  });

  test('імпорт календаря .ics', () {
    const ics = 'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'
        'BEGIN:VEVENT\r\nUID:abc@google.com\r\nDTSTART:20261114T200000\r\nSUMMARY:Побачення з Марком\\, бар\r\nLOCATION:Бар «Ку\r\n », Поділ\r\n'
        'BEGIN:VALARM\r\nTRIGGER:-PT1H\r\nSUMMARY:нагадування\r\nEND:VALARM\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nUID:day@x\r\nDTSTART;VALUE=DATE:20261003\r\nSUMMARY:Архітектор\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nUID:c@x\r\nDTSTART:20261020T170000Z\r\nSUMMARY:Стоматолог\r\nSTATUS:CANCELLED\r\nEND:VEVENT\r\n'
        'BEGIN:VEVENT\r\nUID:meeting-x1@vespr.app\r\nDTSTART:20261115T200000\r\nSUMMARY:✦ Vespr\r\nEND:VEVENT\r\n'
        'END:VCALENDAR\r\n';
    final evs = parseIcs(ics);
    expect(evs.length, 3);
    expect(evs[0].title, 'Побачення з Марком, бар');
    expect(evs[0].location, 'Бар «Ку», Поділ');
    expect(evs[0].time, '20:00');
    expect(evs[1].allDay, isTrue);
    expect(evs[1].date, '2026-10-03');
    expect(guessPerson('Побачення з Марком', people)?.id, 'm');
    expect(guessPerson('архітектор кіно', people)?.id, 'a');
    expect(guessPerson('Стоматолог', people), isNull);
    expect(placeFromText('Бар «Ку» Побачення'), 'bar');
    final db = DB(profile: Profile(), people: people, entries: entries, meetings: [Meeting(id: 'q', personId: 'a', date: '2026-10-03', time: '20:00', extId: 'day@x')]);
    final ch = buildChoices(evs, db, DateTime(2026, 10, 30));
    expect(ch.length, 2); // наша власна подія Vespr не повертається назад
    expect(ch[0].already, isTrue); // уже імпортована
    expect(ch[0].past, isTrue);
    expect(ch[1].on, isTrue);
    expect(ch[1].personId, 'm');
    final ms = meetingsFromChoices([ch[1]], newId: () => 'new', personIdOf: (c) => c.personId!, now: DateTime(2026, 10, 30));
    expect(ms.single.extId, 'abc@google.com');
    expect(ms.single.place, 'bar');
    expect(ms.single.remind, isTrue);
    expect(unratedMeetings([Meeting(id: 'p', personId: 'a', date: '2026-10-24', time: '20:00'), Meeting(id: 'u', personId: 'm', date: '2026-10-25', time: '20:00')], entries, DateTime(2026, 10, 30)).map((m) => m.id), ['u']);
  });
}

List<int> utf8Bytes(String s) => const Utf8Encoder().convert(s);
