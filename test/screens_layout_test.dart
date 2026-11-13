// Перевірка верстки всіх екранів апки 390×844 зі справжніми шрифтами:
// повне демо, «рання» стадія (3 записи) і порожньо. Туторіал — кожна сторінка.
// Падає, якщо щось переповнюється, текст обрізається, вилазить за екран
// або тексти налазять один на одного. З SHOTS=1 пише PNG у build/shots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vespr/data/demo.dart';
import 'package:vespr/data/legal.dart';
import 'package:vespr/data/models.dart';
import 'package:vespr/data/store.dart';
import 'package:vespr/screens/calendar.dart';
import 'package:vespr/screens/entry.dart';
import 'package:vespr/screens/export_screen.dart';
import 'package:vespr/screens/import_screen.dart';
import 'package:vespr/screens/map.dart';
import 'package:vespr/screens/onboarding.dart';
import 'package:vespr/screens/people.dart';
import 'package:vespr/screens/pin_screens.dart';
import 'package:vespr/screens/settings.dart';
import 'package:vespr/screens/shell.dart';
import 'package:vespr/screens/table_screen.dart';
import 'package:vespr/screens/wrapped.dart';
import 'package:vespr/ui/theme.dart';

import 'layout_util.dart';

List<(String, Widget)> _screens(DB db) => [
      ('welcome', const Welcome()),
      ('guide', const GuideScreen()),
      ('about_you', const AboutYou()),
      ('setup', const SetupScreen()),
      ('add_person', const AddPersonScreen()),
      ('home', const Shell()),
      ('people', const Shell(initial: 1)),
      ('map', const Shell(initial: 2)),
      ('awards', const Shell(initial: 3)),
      ('calendar', const CalendarScreen()),
      ('meeting_new', const MeetingForm()),
      ('entry_new', const EntryForm()),
      if (db.entries.isNotEmpty) ('entry_view', EntryView(entryId: db.entries.last.id)),
      if (db.entries.isNotEmpty) ('entry_edit', EntryForm(entryId: db.entries.last.id)),
      if (db.people.isNotEmpty) ('person_view', PersonView(personId: db.people.first.id)),
      if (db.people.length > 1) ('person_view2', PersonView(personId: db.people[1].id)),
      if (db.people.isNotEmpty) ('person_edit', PersonEdit(personId: db.people.first.id)),
      ('shame', const ShameScreen()),
      ('glory', const ShameScreen(glory: true)),
      ('arcana', const MyArcanaScreen()),
      ('settings', const SettingsScreen()),
      ('questions', const QuestionsScreen()),
      ('paywall', const PaywallScreen()),
      ('paywall_limit', const PaywallScreen(kind: PaywallKind.limit)),
      ('paywall_match', const PaywallScreen(kind: PaywallKind.match, name: 'Марк')),
      ('subscription', const SubscriptionScreen()),
      ('privacy', const DocScreen(doc: privacyDoc)),
      ('terms', const DocScreen(doc: termsDoc)),
      ('backup_export', const BackupScreen(export: true)),
      ('backup_import', const BackupScreen(export: false)),
      ('delete_all', const DeleteAllScreen()),
      ('export', const ExportScreen()),
      ('export_calendar', const ExportScreen(calendar: true)),
      ('import', const ImportScreen()),
      ('import_calendar', const ImportScreen(calendar: true)),
      ('table', const TableScreen()),
      ('wrapped_archive', const WrappedArchiveScreen()),
      ('pin_new', const PinNewScreen()),
      ('pin_lock', PinLockScreen(onUnlock: () {})),
    ];

DB _variant(String v, DateTime now) {
  final d = demoDb(now);
  if (v == 'early') d.entries.removeRange(3, d.entries.length);
  if (v == 'empty') {
    d.entries.clear();
    d.people.clear();
    d.meetings.clear();
  }
  return d;
}

void main() {
  testWidgets('Апка: верстка всіх екранів', skip: Platform.environment['LAYOUT'] != '1', (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final shots = Platform.environment['SHOTS'] == '1';
    if (shots) Directory('build/shots').createSync(recursive: true);

    final now = DateTime.now();
    final issues = <Issue>[];
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      var m = d.exceptionAsString().split('\n').first;
      // звідки помилка: перші рядки стеку з нашого коду
      final own = (d.stack?.toString() ?? '').split('\n').where((l) => l.contains('package:vespr/')).take(3).map((l) => l.replaceAll(RegExp(r'^#\d+\s+'), '')).join(' ← ');
      if (own.isNotEmpty) m = '$m [$own]';
      final all = d.toString().split('\n');
      final w = all.indexWhere((l) => l.contains('relevant error-causing widget'));
      if (w >= 0 && w + 1 < all.length) m = '$m {${all[w + 1].trim()}${w + 2 < all.length ? ' ${all[w + 2].trim()}' : ''}}';
      errors.add(m);
    };
    try {
      // 390×844 — макет; 375×667 — низький екран (iPhone SE), там найчастіше налазить
      for (final (sz, vs) in const [(Size(390, 844), ['full', 'early', 'empty']), (Size(375, 667), ['full'])]) {
      tester.view.physicalSize = sz;
      final px = sz.height < 700 ? 'se_' : '';
      for (final v in vs) {
        SharedPreferences.setMockInitialValues({});
        final store = AppStore();
        await tester.runAsync(() async {
          await store.load();
          await store.replaceAll(_variant(v, now));
        });
        for (final (name, screen) in _screens(store.db)) {
          // екрани, що не залежать від даних, перевіряємо один раз
          const dataFree = {'welcome', 'guide', 'about_you', 'setup', 'privacy', 'terms', 'pin_new', 'pin_lock', 'paywall', 'paywall_limit', 'paywall_match', 'subscription', 'delete_all', 'backup_export', 'backup_import', 'import', 'import_calendar', 'questions'};
          if (v != 'full' && dataFree.contains(name)) continue;
          final tagV = '$px$v';
          final key = GlobalKey();
          errors.clear();
          await tester.pumpWidget(Store(
            store: store,
            child: MaterialApp(
              key: ValueKey('$px$v/$name'),
              debugShowCheckedModeBanner: false,
              theme: vesprTheme(),
              locale: const Locale('uk'),
              supportedLocales: const [Locale('uk'), Locale('en')],
              localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
              builder: (c, child) => RepaintBoundary(key: key, child: child),
              home: screen,
            ),
          ));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() async {
            final ctx = key.currentContext!;
            for (final el in find.byType(Image).evaluate()) {
              try {
                await precacheImage((el.widget as Image).image, ctx);
              } catch (_) {}
            }
          });
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 2));

          Future<void> check(String tag) async {
            for (final e in errors) {
              issues.add(Issue('$tag: $e'));
            }
            errors.clear();
            issues.addAll(scanText(key.currentContext!.findRenderObject()!, tag, width: sz.width));
            if (shots) {
              await tester.runAsync(() async {
                final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                final img = await b.toImage(pixelRatio: 1);
                final png = await img.toByteData(format: ui.ImageByteFormat.png);
                File('build/shots/app_${tag.replaceAll('/', '_')}.png').writeAsBytesSync(png!.buffer.asUint8List());
              });
            }
          }

          if (name == 'guide') {
            // кожна сторінка туторіалу окремо
            for (var i = 0; i < 6; i++) {
              final pv = tester.widget<PageView>(find.byType(PageView).first);
              pv.controller!.jumpToPage(i);
              await tester.pump(const Duration(seconds: 2));
              await tester.pump(const Duration(seconds: 2));
              await check('$tagV/guide$i');
            }
          } else {
            await check('$tagV/$name');
          }
        }
      }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
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
