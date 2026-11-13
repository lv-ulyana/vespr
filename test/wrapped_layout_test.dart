// Перевірка верстки Wrapped: кожен слайд 390×844 зі справжніми шрифтами,
// у трьох варіантах — «Без імен», з іменами, з довгими іменами.
// Падає, якщо щось переповнюється, текст обрізається, вилазить за екран
// або два тексти налазять один на одного. З SHOTS=1 ще й пише PNG у build/shots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/data/demo.dart';
import 'package:vespr/data/models.dart';
import 'package:vespr/logic/wrapped.dart';
import 'package:vespr/screens/wrapped.dart';

const _fams = {
  'Onest': 'Onest_',
  'Prata': 'Prata_',
  'Raleway': 'Raleway_',
  'PlexMono': 'IBMPlexMono_',
  'Cormorant': 'CormorantGaramond_',
  'Montserrat': 'Montserrat_',
  'Oswald': 'Oswald_',
  'Zodiac': 'NotoZodiac',
};

Future<void> _loadFonts() async {
  final files = Directory('assets/fonts').listSync().whereType<File>().where((f) => f.path.endsWith('.ttf')).toList();
  for (final e in _fams.entries) {
    final l = FontLoader(e.key);
    for (final f in files.where((f) => f.uri.pathSegments.last.startsWith(e.value))) {
      l.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await l.load();
  }
}

/// Демо з довгими іменами — найгірший випадок для верстки
DB _longNames(DB db) {
  const long = ['Олександр-Максиміліан', 'Костянтин Вікторович', 'Святослав'];
  for (var i = 0; i < db.people.length; i++) {
    db.people[i].name = long[i % long.length];
  }
  return db;
}

class _Issue {
  final String what;
  const _Issue(this.what);
  @override
  String toString() => what;
}

List<_Issue> _scan(RenderObject root, String tag) {
  final out = <_Issue>[];
  final paras = <(RenderParagraph, Rect, String)>[];
  void walk(RenderObject r) {
    if (r is RenderParagraph && r.hasSize && r.attached) {
      final t = r.text.toPlainText().trim();
      if (t.isNotEmpty) {
        final tl = r.localToGlobal(Offset.zero);
        // справжні межі гліфів, а не всієї коробки тексту
        final boxes = r.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: r.text.toPlainText().length));
        var rect = boxes.isEmpty ? (tl & r.size) : boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b)).shift(tl);
        // текст під поворотом/масштабом: беремо реальну трансформацію
        final m = r.getTransformTo(null);
        rect = MatrixUtils.transformRect(m, boxes.isEmpty ? Offset.zero & r.size : boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b)));
        paras.add((r, rect, t));
        if (r.didExceedMaxLines) out.add(_Issue('$tag: обрізано «$t»'));
        // біжучі стрічки свідомо ширші за екран
        if (t.length < 60 && (rect.right > 391 || rect.left < -1)) out.add(_Issue('$tag: за краєм екрана «$t» ${rect.left.toStringAsFixed(0)}..${rect.right.toStringAsFixed(0)}'));
      }
    }
    r.visitChildren(walk);
  }

  walk(root);
  for (var i = 0; i < paras.length; i++) {
    for (var j = i + 1; j < paras.length; j++) {
      final a = paras[i], b = paras[j];
      if (a.$3.length >= 60 || b.$3.length >= 60) continue;
      final x = a.$2.intersect(b.$2);
      final small = [a.$2.width * a.$2.height, b.$2.width * b.$2.height].reduce((p, q) => p < q ? p : q);
      if (x.width > 3 && x.height > 3 && x.width * x.height > small * .25) out.add(_Issue('$tag: налазять «${a.$3}» і «${b.$3}»'));
    }
  }
  return out;
}

void main() {
  testWidgets('Wrapped: верстка слайдів', skip: Platform.environment['LAYOUT'] != '1', (tester) async {
    await tester.runAsync(_loadFonts);
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
    final issues = <_Issue>[];
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
    try {
      for (final (tag, db, safe) in variants) {
        final w = buildWrapped('2026-10', db);
        for (final s in w.slides) {
          final key = GlobalKey();
          final name = '${tag}_${s.k.index.toString().padLeft(2, '0')}_${s.k.name}';
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
            issues.add(_Issue('$name: $e'));
          }
          issues.addAll(_scan(key.currentContext!.findRenderObject()!, name));
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
