// Тексти: факт дня влазить у картку, спостереження «Твоя мапа каже» без дірок і з цифрами з даних.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/data/demo.dart';
import 'package:vespr/logic/facts.dart';
import 'package:vespr/logic/insights.dart';

import 'layout_util.dart';

void main() {
  testWidgets('Факт дня: кожен влазить у картку на 375 і 390', (tester) async {
    await tester.runAsync(loadFonts);
    // картка «Факт дня»: на 390 текст має ~132 px ширини, на 375 ~125; на 320 текст сам зменшується
    for (final w in [132.0, 125.0]) {
      for (final f in dayCards) {
        final tp = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: f.plain,
            style: const TextStyle(fontFamily: 'Raleway', fontSize: 14, height: 1.38, fontWeight: FontWeight.w300),
            children: [TextSpan(text: f.accent, style: const TextStyle(fontFamily: 'Raleway', fontSize: 14, height: 1.38, fontWeight: FontWeight.w500))],
          ),
        )..layout(maxWidth: w);
        // 5 рядків влазять як є; довша цитата трохи зменшується (FittedBox), але не дрібніше ~12 px
        final maxLines = w > 130 ? 6 : 7;
        expect(tp.computeLineMetrics().length <= maxLines, isTrue, reason: '«${f.plain}${f.accent}» на ширині $w: ${tp.computeLineMetrics().length} рядків');
      }
    }
  });

  test('Факт дня: щодня інший, усі різні', () {
    final seen = {for (final f in dayCards) f.plain + f.accent};
    expect(seen.length, dayCards.length);
    expect(factOfDay(DateTime(2026, 11, 15)) != factOfDay(DateTime(2026, 11, 16)), isTrue);
  });

  test('Твоя мапа каже: тільки правдиві й заповнені', () {
    final db = demoDb();
    final xs = homeInsights(db.people, db.entries);
    expect(xs, isNotEmpty);
    for (final x in xs) {
      expect(x.contains('{') || x.contains('null') || x.contains('NaN') || x.contains('Infinity'), isFalse, reason: x);
      expect(x.length <= 110, isTrue, reason: 'задовго: $x');
    }
    // ~кілька днів поспіль дають різні тексти, якщо є з чого
    if (xs.length > 1) {
      expect(insightOfDay(db.people, db.entries, DateTime(2026, 11, 15)) != insightOfDay(db.people, db.entries, DateTime(2026, 11, 16)), isTrue);
    }
    // ignore: avoid_print
    for (final x in xs) print('  · $x');
  });
}
