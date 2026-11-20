// Перевірка: знаки, аркани (усі тексти на місці), збереження людей і всі 33 нагороди.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/data/catalog.dart';
import 'package:vespr/data/models.dart';
import 'package:vespr/logic/achievements.dart';
import 'package:vespr/logic/arcana_more.dart';
import 'package:vespr/logic/astro.dart';
import 'package:vespr/logic/dates.dart';
import 'package:vespr/l10n/tr.dart';
import 'package:vespr/logic/match_check.dart';
import 'package:vespr/logic/match_texts.dart';
import 'package:vespr/logic/sign_texts.dart';

int _n = 0;
Entry en(String p, String date, int overall, {bool sex = true, List<String> tags = const [], List<String> flags = const [], String? at}) => Entry(
      id: 'e${_n++}', personId: p, date: date, overall: overall, hadSex: sex,
      ratings: sex ? {'sx_overall': overall} : {}, tags: List.of(tags), flags: List.of(flags), createdAt: at ?? '${date}T20:00:00',
    );
Person pe(String id, {String rel = 'date', String? birth, int? signOnly, int? size, String status = 'now', String? reason, String? pastAt, String created = '2026-01-01'}) =>
    Person(id: id, name: id, rel: rel, birth: birth, signOnly: signOnly, size: size, status: status, pastReason: reason, pastAt: pastAt, createdAt: created);

Map<String, int> ach(DB db, [String today = '2026-11-21']) => {for (final a in computeAchievements(db, todayIso: today)) a.d.id: a.v};
DB db({List<Person> people = const [], List<Entry> entries = const [], Map<String, int>? counters, String? birth}) =>
    DB(profile: Profile(name: 'Я', birth: birth, counters: counters), people: List.of(people), entries: List.of(entries), meetings: []);

void main() {
  group('Знаки зодіаку', () {
    // межі за стандартною таблицею: перший день кожного знака і день перед ним
    const bounds = {
      '01-19': 'Козеріг', '01-20': 'Водолій', '02-18': 'Водолій', '02-19': 'Риби', '03-20': 'Риби', '03-21': 'Овен',
      '04-19': 'Овен', '04-20': 'Телець', '05-20': 'Телець', '05-21': 'Близнюки', '06-20': 'Близнюки', '06-21': 'Рак',
      '07-22': 'Рак', '07-23': 'Лев', '08-22': 'Лев', '08-23': 'Діва', '09-22': 'Діва', '09-23': 'Терези',
      '10-22': 'Терези', '10-23': 'Скорпіон', '11-21': 'Скорпіон', '11-22': 'Стрілець', '12-21': 'Стрілець', '12-22': 'Козеріг',
      '12-31': 'Козеріг', '01-01': 'Козеріг',
    };
    test('межі знаків правильні', () {
      bounds.forEach((md, name) => expect(signs[signIndex('2000-$md')].name, name, reason: md));
    });
    test('кожен день року дає знак, усі 12 трапляються, рік невідомий теж працює', () {
      final seen = <int>{};
      for (var d = DateTime(2024, 1, 1); d.year == 2024; d = d.add(const Duration(days: 1))) {
        final i = signIndex(iso(d));
        expect(i, inInclusiveRange(0, 11));
        seen.add(i);
        expect(signIndex('0000-${iso(d).substring(5)}'), i);
      }
      expect(seen.length, 12);
    });
    test('у кожного знака є символ і стихія, у кожної пари стихій — порада', () {
      const els = ['Вогонь', 'Земля', 'Повітря', 'Вода'];
      for (var i = 0; i < 12; i++) {
        expect(zodiacGlyph(i).runes.length, 1);
        expect(els, contains(signs[i].el));
        for (var j = 0; j < 12; j++) {
          expect(elementsText(signs[i].el, signs[j].el), isNotEmpty, reason: '${signs[i].name}+${signs[j].name}');
          expect(['Легко', 'Складніше'], contains(zodiacEase(i, j)));
        }
      }
      expect(signs.map((s) => zodiacGlyph(signs.indexOf(s))).toSet().length, 12);
    });
    test('аспект для кожної з 144 пар: легкість збігається з тегом «Легко/Складніше», тексти є', () {
      expect(aspects.length, 7);
      for (var i = 0; i < 12; i++) {
        for (var j = 0; j < 12; j++) {
          final a = aspectOf(i, j);
          expect(aspectOf(j, i), same(a), reason: 'симетрія');
          expect(a.easy, zodiacEase(i, j) == 'Легко', reason: '${signs[i].name}+${signs[j].name}: ${a.name}');
          for (final t in [a.name, a.rel, a.sex, a.risk]) {
            expect(t.trim(), isNotEmpty);
          }
        }
      }
      expect(aspectOf(3, 3).name, 'Один знак'); // Овен + Овен
      expect(aspectOf(3, 7).name, 'Тригон'); // Овен + Лев
      expect(aspectOf(3, 9).name, 'Опозиція'); // Овен + Терези
      expect(aspectOf(3, 0).name, 'Квадрат'); // Овен + Козеріг
    });
    test('у кожного знака є суть, кохання, ліжко й тінь', () {
      expect(signTexts.length, 12);
      for (var i = 0; i < 12; i++) {
        for (final t in [signTexts[i].core, signTexts[i].love, signTexts[i].bed, signTexts[i].shadow]) {
          expect(t.split('. ').length, greaterThanOrEqualTo(2), reason: '${signs[i].name}: розписано, а не одне речення');
        }
      }
    });
  });

  group('Аркани', () {
    test('аркан особистості з будь-якого дня: 1–22', () {
      for (var day = 1; day <= 31; day++) {
        final a = arcanaOf('2000-01-${day.toString().padLeft(2, '0')}');
        expect(a, inInclusiveRange(1, 22));
        expect(a, day > 22 ? day - 22 : day);
      }
    });
    test('аркан пари: будь-яка пара дає 1–22', () {
      for (var a = 1; a <= 22; a++) {
        for (var b = 1; b <= 22; b++) {
          expect(pairArcana(a, b), inInclusiveRange(1, 22));
        }
      }
    });
    test('у кожного з 22 арканів є всі тексти', () {
      expect(arcana.length, 23);
      expect(arcanaMore.length, 23);
      expect(pairTexts.length, 23);
      expect(bedClaims.length, 23);
      for (var i = 1; i <= 22; i++) {
        expect(roman[i], isNotEmpty);
        for (final t in [arcana[i].name, arcana[i].core, arcana[i].love, arcanaMore[i].plus, arcanaMore[i].minus, arcanaMore[i].bed, arcanaMore[i].love, pairTexts[i].rel, pairTexts[i].sex, pairTexts[i].risk, bedClaims[i].claim, bedClaims[i].qLabel]) {
          expect(t.trim(), isNotEmpty, reason: 'аркан $i');
        }
        // «у ліжку» перевіряється питанням, яке є в записі завжди або за замовчуванням
        final q = sexQuestions.firstWhere((q) => q.id == bedClaims[i].q);
        expect(q.always || q.def, isTrue, reason: 'аркан $i: ${bedClaims[i].q}');
        // текст пари не суперечить тегу «Легко/Складніше»
        final pair = '${pairTexts[i].rel} ${pairTexts[i].sex} ${pairTexts[i].risk}'.toLowerCase();
        expect(pair.contains(easyArcana.contains(i) ? 'складний аркан' : 'легкий аркан'), isFalse, reason: 'аркан пари $i');
      }
      expect(arcana.skip(1).map((a) => a.name).toSet().length, 22);
      expect(sexQuestions.firstWhere((q) => q.id == BedClaim.fallback).always, isTrue);
    });
    test('усі довгі тексти мають англійський переклад', () {
      setLang('en');
      final all = [
        for (var i = 1; i <= 22; i++) ...[arcanaMore[i].plus, arcanaMore[i].minus, arcanaMore[i].bed, arcanaMore[i].love, pairTexts[i].rel, pairTexts[i].sex, pairTexts[i].risk, bedClaims[i].claim],
        for (final s in signTexts) ...[s.core, s.love, s.bed, s.shadow],
        for (final a in aspects) ...[a.name, a.rel, a.sex, a.risk],
        for (var i = 0; i < 12; i++)
          for (var j = 0; j < 12; j++) elementsText(signs[i].el, signs[j].el),
      ];
      for (final t in all) {
        expect(RegExp('[А-Яа-яІіЇїЄєҐґ]').hasMatch(tr(t)), isFalse, reason: t);
      }
      setLang('uk');
    });
  });

  test('сила аспекту: тригон > секстиль > один знак > опозиція > сусідні > квінконс > квадрат, легкі вище складних', () {
    final byDist = [for (var d = 0; d <= 6; d++) aspectStrength(0, d)];
    expect(byDist, [4, 2, 5, 0, 6, 1, 3]);
    for (var i = 0; i < 12; i++) {
      for (var j = 0; j < 12; j++) {
        for (var k = 0; k < 12; k++) {
          final ej = zodiacEase(i, j) == 'Легко', ek = zodiacEase(i, k) == 'Легко';
          if (ej && !ek) expect(aspectStrength(i, j), greaterThan(aspectStrength(i, k)));
        }
      }
    }
  });

  test('перевірка «аркан каже»: основне питання, запасне і поріг 3,5', () {
    Entry r(String p, Map<String, int> rt) => Entry(id: 'r${_n++}', personId: p, date: '2026-11-01', overall: 4, hadSex: true, ratings: rt, createdAt: '');
    final all = [r('a', {'sx_care': 5}), r('a', {'sx_care': 4}), r('b', {'sx_pleasure': 3}), r('b', {'sx_pleasure': 3})];
    final ca = claimCheck(all, 'a', 3); // Імператриця → «дбали»
    expect([ca.qLabel, ca.value, ca.ok], ['Наскільки дбали про тебе', 4.5, true]);
    final cb = claimCheck(all, 'b', 3); // «дбали» нема → запасне «було добре»
    expect([cb.qLabel, cb.value, cb.ok], [BedClaim.fallbackLabel, 3.0, false]);
    expect(claimCheck(all, 'c', 3).hasData, isFalse);
  });

  test('люди зберігаються і читаються назад з усіма полями', () {
    final p = Person(id: 'x', name: 'Архітектор', gender: 'm', rel: 'rel', birth: '1995-10-03', signOnly: null, size: 2, met: 1, want: 2, notes: 'серветки', createdAt: '2026-11-01T10:00:00', photo: 'AAA');
    final q = Person(id: 'y', name: 'Марк', rel: 'fling', signOnly: 7, status: 'past', pastReason: 'gone', pastAt: '2026-11-10', createdAt: '2026-11-02');
    final back = DB.fromJson(jsonDecode(jsonEncode(db(people: [p, q]).toJson())) as Map<String, dynamic>);
    expect(back.people.length, 2);
    final a = back.people.first, b = back.people.last;
    expect([a.name, a.rel, a.birth, a.size, a.notes, a.photo], ['Архітектор', 'rel', '1995-10-03', 2, 'серветки', 'AAA']);
    expect(astroOf(a.birth)!.signName, 'Терези');
    expect([b.signOnly, b.isPast, b.pastReason, b.pastAt], [7, true, 'gone', '2026-11-10']);
    expect(astroOf(b.birth, b.signOnly)!.signName, 'Лев');
  });

  group('Нагороди', () {
    test('усі 33 мають картинку-id і пороги', () {
      expect(achDefs.length, 33);
      expect(achDefs.map((d) => d.id).toSet().length, 33);
      for (final d in achDefs) {
        expect(d.th, isNotEmpty);
      }
    });

    test('порожня база — нічого не відкрито', () {
      expect(ach(db()).values.where((v) => v > 0), isEmpty);
    });

    test('прапорці: граблі, сліпа зона, червоний — мій колір, зелене світло, кавалер, чиста історія', () {
      final a = ach(db(people: [pe('a'), pe('b')], entries: [
        en('a', '2026-11-01', 4, flags: ['flag_r_phone']),
        en('a', '2026-11-02', 4, flags: ['flag_r_phone', 'flag_r_late', 'flag_g_asks']),
        en('b', '2026-11-03', 5, flags: ['flag_r_phone']),
        en('b', '2026-11-04', 5, flags: ['flag_g_walk', 'flag_g_paid', 'flag_g_ontime']),
      ]));
      expect(a['rake'], 1); // телефон у двох різних людей
      expect(a['blind'], 2); // після червоних в «a» і «b» були ще зустрічі
      expect(a['redcolor'], 3);
      expect(a['green'], 1);
      expect(a['gentleman'], 1);
      expect(a['clean'], 1);
    });

    test('оцінки: золотий стандарт, ну а раптом, зірки зійшлись', () {
      final a = ach(db(birth: '2000-03-25' /* Овен, вогонь */, people: [pe('a', birth: '2000-07-25' /* Лев, вогонь */), pe('b')], entries: [
        en('a', '2026-11-01', 5), en('a', '2026-11-02', 5), en('a', '2026-11-03', 5),
        en('b', '2026-11-04', 1), en('b', '2026-11-05', 3),
      ]));
      expect(a['gold'], 3);
      expect(a['maybe'], 1);
      expect(a['stars'], 3);
    });

    test('люди: астрологиня, стихійне лихо, хардкор, дюймовочка, гігантоманія, колишній', () {
      final a = ach(db(people: [
        pe('s1', birth: '1999-10-25', created: '2026-01-01'), pe('s2', signOnly: 10, created: '2026-01-02'), pe('s3', birth: '1998-11-10', created: '2026-01-03'),
        pe('x', birth: '2000-03-25', size: 0, created: '2026-02-01'), pe('y', birth: '2000-05-01', size: 0, created: '2026-02-02'), pe('z', birth: '2000-06-01', size: 0, created: '2026-02-03'),
        pe('g1', size: 3, created: '2026-02-04'), pe('g2', size: 3, created: '2026-02-05'), pe('g3', size: 3, rel: 'ex', created: '2026-02-06'),
      ]));
      expect(a['astro'], 4); // Скорпіон, Овен, Телець, Близнюки
      expect(a['elements'], 4);
      expect(a['hardcore'], 3);
      expect(a['thumbelina'], 3);
      expect(a['giant'], 3);
      expect(a['ex'], 1);
    });

    test('минулі: ghosted, без «а раптом», бумеранг', () {
      final a = ach(db(counters: {'boomerang': 1}, people: [
        pe('a', status: 'past', reason: 'gone', pastAt: '2026-11-03'),
        pe('b', status: 'past', reason: 'ended', pastAt: '2026-11-06'),
      ], entries: [en('a', '2026-11-01', 4), en('b', '2026-11-05', 2)]));
      expect(a['ghosted'], 1);
      expect(a['nomaybe'], 1);
      expect(a['boomerang'], 1);
    });

    test('остання сповідь — запис, збережений з 2:00 до 4:59 за місцевим часом', () {
      final a = ach(db(people: [pe('a')], entries: [
        en('a', '2026-11-20', 4, at: '2026-11-21T03:10:00'),
        en('a', '2026-11-19', 4, at: '2026-11-19T23:50:00'),
        en('a', '2026-11-18', 4, at: '2026-11-18T05:00:00'),
      ]));
      expect(a['confess'], 1);
    });

    test('теги: оскар, хеппі-енд, барна душа', () {
      final a = ach(db(people: [pe('a')], entries: [
        en('a', '2026-11-01', 4, tags: ['o_fake', 'bar']),
        en('a', '2026-11-02', 4, tags: ['o_me', 'bar']),
        en('a', '2026-11-03', 4, tags: ['o_multi', 'bar', 'restaurant']),
      ]));
      expect(a['oscar'], 1);
      expect(a['happy'], 2);
      expect(a['bar'], 3);
    });

    test('ритм: закохалась, гарячий тиждень, сезон, повернення, новорічна', () {
      final es = [for (var i = 0; i < 12; i++) en('a', addDays('2026-01-05', i * 2), 4)]; // 12 записів за 23 дні
      es.add(en('a', '2026-03-20', 4)); // після 30+ днів тиші
      es.add(en('b', '2025-12-31', 3));
      final a = ach(db(people: [pe('a'), pe('b')], entries: es));
      expect(a['love'], greaterThanOrEqualTo(5));
      expect(a['hotweek'], 4); // через день: за 7 днів лише 4 записи, рівень ще не відкрито
      expect(a['comeback'], greaterThanOrEqualTo(1));
      expect(a['newyear'], 1);
      final weekly = [for (var i = 0; i < 12; i++) en('c', addDays('2026-01-05', i * 7), 4)];
      expect(ach(db(people: [pe('c')], entries: weekly))['season'], 12);
      final hot = [for (var i = 0; i < 12; i++) en('c', addDays('2026-02-02', i), 4)];
      expect(ach(db(people: [pe('c')], entries: hot))['hotweek'], 12);
    });

    test('одна ніч: спортивний інтерес і ніч з продовженням', () {
      final a = ach(db(people: [pe('n1', rel: 'night'), pe('n2', rel: 'night'), pe('n3', rel: 'night')], entries: [
        en('n1', '2026-11-01', 4), en('n2', '2026-11-08', 4), en('n3', '2026-11-15', 4),
        en('n1', '2026-11-16', 4), en('n1', '2026-11-17', 4), en('n1', '2026-11-18', 4),
      ]));
      expect(a['sport'], 3);
      expect(a['nightmore'], 4);
    });

    test('лічильники: сказала вголос, ревізія; монастир і нуль граблів рахуються від дат', () {
      final a = ach(db(counters: {'voice:2026-10': 3, 'voice:2026-11': 2, 'rev:2026-11-16': 3}, people: [pe('a')], entries: [
        en('a', '2026-05-01', 4, flags: ['flag_r_phone']),
        en('a', '2026-05-02', 4, flags: ['flag_r_phone']),
      ]));
      expect(a['saiddone'], 5);
      expect(a['revision'], 3);
      expect(a['monastery'], 6); // з 1 травня до 21 листопада, без «Інтрижки»
      expect(a['norake'], daysBetween('2026-05-02', '2026-11-21'));
    });
  });
}
