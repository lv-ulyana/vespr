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
            issues.add(Issue('$name: $e'));
          }
          issues.addAll(scanText(key.currentContext!.findRenderObject()!, name));
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
