// Перевірка верстки Wrapped: кожен слайд 390×844 зі справжніми шрифтами,
// у трьох варіантах — «Без імен», з іменами, з довгими іменами.
// Падає, якщо щось переповнюється, текст обрізається, вилазить за екран
// або два тексти налазять один на одного. З SHOTS=1 ще й пише PNG у build/shots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/data/demo.dart';
import 'package:vespr/data/models.dart';
import 'package:vespr/logic/wrapped.dart';
import 'package:vespr/screens/wrapped.dart';

import 'layout_util.dart';

/// Демо з довгими іменами — найгірший випадок для верстки
DB _longNames(DB db) {
  const long = ['Олександр-Максиміліан', 'Костянтин Вікторович', 'Святослав'];
  for (var i = 0; i < db.people.length; i++) {
    db.people[i].name = long[i % long.length];
  }
  return db;
}

/// Кожен новий фон (19–47) з даними як у макеті — щоб побачити всі, навіть ті, що демо не вмикає
List<WSlide> _gallery() {
  const a = WP('a', 'Архітектор', 'Він №1'), m = WP('m', 'Марк', 'Він №2'), d = WP('d', 'Д.', 'Він №3');
  return [
    const WSlide(WK.dossier, 'Особова', 'справа', who: [m], rows: [WRow('сидів у телефоні', '×5', sub: '|||||'), WRow('запізнився 15+ хв', '×2', sub: '||'), WRow('згадував колишню', '×1', sub: '|')], x: {'num': '№2', 'tab': 'справа · жовт', 'obj': "об'єкт №2", 'opened': 'відкрито 14.10', 'sign': '♏ Скорпіон', 'meet': '2', 'avg': '3,4 / 5', 'stamp': 'Вирок: умовно', 'cap2': 'справа не закрита'}, capSafe: 'Шанс є. Але з випробувальним терміном.'),
    const WSlide(WK.reviews, 'Відгуки', 'покупців', score: 4, ints: [1, 0, 1, 0, 0], rows: [WRow('Відповідає опису. Сам питає, що подобається', '5', who: a), WRow('Рекомендую подругам. Ні, не рекомендую — це мій.', '12'), WRow('На фото такий самий', '3', sub: 'Батарея сідає швидко, доставка запізнюється', who: m), WRow('До кошика повторно не додам.', '8')], x: {'cnt': '2 відгуки', 'verdict': 'Середина ринку.', 'date': 'жовт 2026'}),
    const WSlide(WK.size, 'Розмір', 'місяця', private: true, rows: [WRow('Золотий стандарт', '1', who: a, sub: 'розмір'), WRow('Скромно', '0', who: m, sub: 'новий експонат')], n1: 1, n2: 0, x: {'of': 'з 3', 'intro': 'Твої позначки «розмір» за жовтень: хто що показав.'}, capSafe: 'Подробиці — в закритому показі.'),
    const WSlide(WK.clown, 'Клоун', 'місяця', who: [m], a: '×5', x: {'lab': 'сидів\nу телефоні'}, capSafe: 'Він. Айфон, мабуть, гарніший.', capFull: 'Марк. Айфон, мабуть, гарніший.'),
    const WSlide(WK.rakes, 'Різні хлопці.', 'Той самий|прапорець', who: [m, a, d], n1: 3, x: {'pill': '📱 сидів у телефоні — у всіх трьох', 'meme': 'Коли всі троє дістали телефон на побаченні', 'lvl': 'граблі · рівень 3'}, capSafe: 'Навіть найкращий раз попався. Проблема, схоже, не в них.', capFull: 'Навіть Архітектор раз попався. Проблема, схоже, не в них.'),
    const WSlide(WK.oscars, 'Оскари', 'місяця', who: [a], rows: [WRow('Ходячий червоний прапорець', '⚑', sub: ': 6 червоних за 2 зустрічі', who: m), WRow('Майстер спорту з запізнень', '⏱', sub: ', двічі. Годинник, мабуть, декоративний', who: m), WRow('Золотий гаманець', '₴', sub: 'Рахував копійки. Заплатив 0 разів')], x: {'cer': 'церемонія · 4 номінації', 'g': 'провів|заплатив|вчасно'}, capSafe: 'Промову ніхто не підготував.'),
    const WSlide(WK.init, 'Хто почав:', 'ти, 4 з 5', who: [m], n1: 4, n2: 1, a: '4/5', b: 'ти перша', capSafe: 'Він чекав, поки ти все зробиш сама. Як на роботі, тільки без зарплати.'),
    const WSlide(WK.alco, 'Алкоголь', 'і секс', score: 4.6, score2: 3.5, n1: 2, n2: 3, a: '−1,1', capSafe: 'Тверезий секс на 1,1 бала кращий. Вино розслабляє, але не там, де треба.'),
    const WSlide(WK.territory, 'Чия', 'територія', n1: 3, n2: 5, score: 4.7, score2: 3.5, a: 'ночей\nу нього', capSafe: 'Ти вже знаєш, де в нього рушники. І там тобі краще.'),
    const WSlide(WK.after, 'Після', '', n1: 3, n2: 5, rows: [WRow('Одразу в телефони', '2'), WRow('Першим написав', 'ти 3 · він 2')], capSafe: 'Двічі — скрол рілсів спиною одне до одного.'),
    const WSlide(WK.voice, 'Голос є.', 'Користуйся.', n1: 4, flags: [true], rows: [WRow('Позначила межу', '2 рази', kind: 2), WRow('Похвалила, що сподобалось', '3 рази', kind: 2), WRow('Хотіла, не сказала', '1 раз', kind: 1)], capSafe: 'У вересні було 1. Це рекорд.'),
    const WSlide(WK.quarter, 'Квартальний', 'звіт', score: 4.4, ints: [380, 410, 395, 440], rows: [WRow('лип', ''), WRow('сер', ''), WRow('вер', ''), WRow('жов', '')], x: {'q': 'Q4 · 10/26', 'pct': '▲ 22%', 'vs': 'рентабельність вечора\nдо вересня', 'conv': '100%', 'convL': 'ринок перегрітий', 'risk': '6/2', 'fired': '1', 'stamp': 'Аудит пройдено*'}, capSafe: 'Рада директорів задоволена.\n*Майже.'),
    const WSlide(WK.tarot, 'Таро', 'на листопад', a: 'XIV', b: 'Помірність', capSafe: 'Якщо ще раз підеш на каву з тим, хто сидить у телефоні, вселенський баланс трісне і ти почнеш кусати людей. Зроби перерву.'),
    const WSlide(WK.horo, 'Зорі брешуть,', 'метрики ні', who: [m], score: 3.1, a: 'Діва і Скорпіон — пристрасть', b: 'Ревнує і зникає.', capSafe: 'Довіряй таблиці, а не зорям.'),
    const WSlide(WK.archive, 'Архів', 'колишніх', who: [d], x: {'last': '12 вересня', 'silence': '19 днів тиші', 'reason': '«Він зник»'}, capSafe: 'Зник — значить зник. Справу закрито без права повернення.'),
    const WSlide(WK.cover, 'Жовтень', 'з ним', title2Full: 'і Архітектор', artOv: WArt.coverOne, n1: 10, score: 4.5, x: {'eves': 'вечорів'}, capSafe: 'Один на весь місяць — і це було добре.'),
    const WSlide(WK.himPrev, 'Краще, ніж', 'у вересні', artOv: WArt.himPrev, who: [a], rows: [WRow('Секс', '4,5', sub: '3,9', kind: 2), WRow('Чує тебе', '4,4', sub: '4,0', kind: 2), WRow('Темп', '3,1', sub: '3,2')], x: {'cols': 'вер → жов'}, capSafe: 'Темп — єдине, що не зрушило. Варто сказати.'),
    const WSlide(WK.cover, 'Жовтень:', 'тільки|побачення', artOv: WArt.coverNoSex, n1: 4, x: {'dates': 'побачення'}, capSafe: 'Місяць розмов, келихів і перших вражень.'),
    const WSlide(WK.cover, '2 записи —', 'гарний старт', artOv: WArt.coverMini, n1: 2, x: {'kick': 'Твій жовтень · перші кроки', 'left': 'ще 1 до повного Wrapped', 'prog': '2 з 3 записів', 'men': '1', 'menL': 'чоловік', 'best': '4', 'dates': 'побачення'}, capSafe: 'З третім записом відкриються рекорди, хлопці і нагороди.'),
    const WSlide(WK.match, 'Роздво', 'єння', artOv: WArt.matchSplit, who: [a, m], score: 4.1, score2: 4.8, capSafe: 'Класика, яку ще ніхто не вирішив.'),
    const WSlide(WK.type, 'Детекторка 🕵️‍♀️', 'чужих ексів', artOv: WArt.detective, a: '3', b: '/3', x: {'lab': 'згадали\nколишню'}, capSafe: '3 з 3 згадали колишню. Ти не на побаченні, ти на груповій терапії.'),
    const WSlide(WK.type, 'Заслужена', 'артистка 🎭', artOv: WArt.artist, private: true, a: '2', b: '/5', x: {'lab': 'вдавала\nцього місяця'}, capSafe: 'Станіславський аплодує стоячи. Деталі — на закритому показі.', capFull: 'Вдавала 2 рази з 5. Станіславський аплодує стоячи. Він нічого не помітив.'),
    const WSlide(WK.type, 'Серійна 🎯', 'стрільчиня', artOv: WArt.serial, n1: 4, n2: 4, a: '0', x: {'l1': 'побачення', 'l2': 'чоловіки', 'l3': 'продовжень'}, capSafe: '4 побачення, 4 різні чоловіки, 0 продовжень. Кастинг триває.'),
    const WSlide(WK.type, 'Фінансова 🧮', 'аудиторка', artOv: WArt.auditor, a: '3', x: {'lab': 'рахував\nкопійки'}, capSafe: 'Він рахував копійки 3 рази. Ти рахувала його прапорці. Нічия.'),
    const WSlide(WK.type, 'Відділ 👻', 'кадрів', artOv: WArt.hr, a: '2', x: {'lab': 'звільнились\nбез відпрацювання'}, capSafe: '2 звільнились без відпрацювання. Ghosting — теж відповідь.'),
    const WSlide(WK.type, 'Ген', 'директорка', artOv: WArt.boss, a: '5', b: '/5', x: {'lab': 'почала\nти'}, capSafe: 'Почала ти 5 з 5. Він працює на півставки.'),
    const WSlide(WK.type, 'Сезон', 'пледу', artOv: WArt.plaid, a: '0', x: {'lab': 'побачень.\nі це ок'}, capSafe: '0 побачень. Плед, серіал, какао. Найздоровіші стосунки місяця.'),
    const WSlide(WK.clown, 'Колишня 👋', 'передає привіт', artOv: WArt.clownEx, who: [m], a: '×3', x: {'lab': 'згадував\nколишню'}, capSafe: 'Ти не на побаченні, ти на груповій терапії.'),
    const WSlide(WK.type, 'Нічна', 'зміна', artOv: WArt.night, a: '3', b: '/4', x: {'lab': 'лишалась\nна ніч'}, capSafe: 'Лишалась 3 з 4 ночей. Сніданок у договір не входив.'),
  ];
}

void main() {
  testWidgets('Wrapped: верстка слайдів', skip: Platform.environment['LAYOUT'] != '1', (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final shots = Platform.environment['SHOTS'] == '1';
    if (shots) Directory('build/shots').createSync(recursive: true);

    final now = DateTime(2026, 11, 13);
    final variants = [
      ('safe', demoDb(now), true),
      ('names', demoDb(now), false),
      ('long', _longNames(demoDb(now)), false),
    ];
    final issues = <Issue>[];
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
    try {
      for (final (tag, db, safe) in variants) {
        final w = buildWrapped('2026-10', db);
        for (final (gal, s) in [...w.slides.map((x) => (false, x)), ..._gallery().map((x) => (true, x))]) {
          final key = GlobalKey();
          final name = '${tag}_${gal ? 'g' : ''}${s.art.toString().padLeft(2, '0')}_${s.k.name}';
          errors.clear();
          await tester.pumpWidget(MediaQuery(
            data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RepaintBoundary(key: key, child: SizedBox(width: 390, height: 844, child: wrappedSlideForTest(s, w, safe: safe))),
            ),
          ));
          // картинки декодуються по-справжньому
          await tester.runAsync(() async {
            final ctx = key.currentContext!;
            for (final el in find.byType(Image).evaluate()) {
              await precacheImage((el.widget as Image).image, ctx);
            }
          });
          await tester.pump();
          for (final e in errors) {
            issues.add(Issue('$name: $e'));
          }
          issues.addAll(scanText(key.currentContext!.findRenderObject()!, name));
          // у переглядачі з 772 по низу кнопки «Без імен / Поділитися / ×» — текст туди не має залазити
          void low(RenderObject r) {
            if (r is RenderParagraph && r.hasSize) {
              final t = r.text.toPlainText().trim();
              final rect = MatrixUtils.transformRect(r.getTransformTo(key.currentContext!.findRenderObject()), Offset.zero & r.size);
              if (t.isNotEmpty && t.length < 60 && rect.bottom > 770 && rect.top < 844 && rect.right > 0 && rect.left < 390) issues.add(Issue('$name: під кнопками «$t» ${rect.top.toStringAsFixed(0)}..${rect.bottom.toStringAsFixed(0)}'));
            }
            r.visitChildren(low);
          }
          low(key.currentContext!.findRenderObject()!);
          if (shots) {
            await tester.runAsync(() async {
              final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
              final img = await b.toImage(pixelRatio: 1);
              final png = await img.toByteData(format: ui.ImageByteFormat.png);
              File('build/shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
            });
          }
        }
      }
    } finally {
      FlutterError.onError = old;
    }
    if (issues.isNotEmpty) {
      // ignore: avoid_print
      print('ПРОБЛЕМИ ВЕРСТКИ (${issues.length}):\n${issues.join('\n')}');
    }
    expect(issues, isEmpty);
  });
}
