import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/legal.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../services/files.dart';
import '../services/pin.dart';
import '../ui/board.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go, Screen, Header, H1, Txt, Field, Btn, VCard;
import '../ui/theme.dart' show C;
import 'export_screen.dart';
import 'import_screen.dart';
import 'map.dart' show MyArcanaScreen;
import 'pin_screens.dart';
import 'table_screen.dart';
import 'wrapped.dart' show WrappedScreen;

/// Перемикачі без окремого поля в профілі живуть у counters під ключем opt:… (1 — увімкнено).
bool profOpt(Profile p, String k) => (p.counters['opt:$k'] ?? 1) == 1;

String _monthCount(AppStore s) {
  final m = today().substring(0, 7);
  return '${s.entries.where((e) => e.date.startsWith(m)).length}';
}

/// Орудний відмінок для імені: «з Архітектором», «з Марком», «з Олею».
String instrCase(String n) {
  final t = n.trim();
  if (t.isEmpty) return 'ним';
  final last = t[t.length - 1].toLowerCase();
  final base = t.substring(0, t.length - 1);
  if (last == 'а') return '${base}ою';
  if (last == 'я') return '${base}ею';
  if (last == 'й') return '${base}єм';
  if (last == 'ь') return '${base}ем';
  if ('бвгґджзклмнпрстфхцчшщ'.contains(last)) return '$tом';
  return t;
}

// =====================================================================
// Налаштування
// =====================================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final _icStar = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 1l2.6 8.4L23 12l-8.4 2.6L12 23l-2.6-8.4L1 12l8.4-2.6z"/></svg>';

  void _setOpt(AppStore s, String k, bool v) => s.updateProfile((x) => x.counters['opt:$k'] = v ? 1 : 0);

  void _langSheet(BuildContext context, AppStore s) => showSheet(
        context,
        (ctx) => Sheet(children: [
          sheetTitle('Мова'),
          for (final l in const [('uk', 'Українська', 'Ukrainian'), ('en', 'English', 'Англійська')])
            XOpt(
              title: l.$2,
              sub: l.$3,
              on: s.profile.lang == l.$1,
              onTap: () {
                s.updateProfile((x) => x.lang = l.$1);
                Navigator.pop(ctx);
                if (l.$1 == 'en') dToast(context, 'Англійська ще перекладається');
              },
            ),
          sheetCancel(ctx),
        ]),
      );

  void _iconSheet(BuildContext context, AppStore s) {
    Widget tile(bool dark) => Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: dark ? K.bg : K.star,
            borderRadius: BorderRadius.circular(12),
            border: dark ? Border.all(color: K.w(.14)) : null,
          ),
          alignment: Alignment.center,
          child: Text('v', style: pr(24, color: dark ? K.star : K.bg, h: 1)),
        );
    showSheet(
      context,
      (ctx) => Sheet(children: [
        sheetTitle('Іконка апки'),
        sheetText('Світла менше впадає в око на екрані телефона.'),
        for (final d in const [true, false])
          XOpt(
            title: d ? 'Темна' : 'Світла',
            lead: tile(d),
            on: (s.profile.appIcon == 'dark') == d,
            onTap: () {
              s.updateProfile((x) => x.appIcon = d ? 'dark' : 'light');
              Navigator.pop(ctx);
            },
          ),
        sheetCancel(ctx),
      ]),
    );
  }

  void _datingSheet(BuildContext context, AppStore s) => showSheet(
        context,
        (ctx) => Sheet(children: [
          sheetTitle('З ким зустрічаєшся'),
          sheetText('Від цього залежать «він» чи «вона» в питаннях і картках.'),
          for (final d in datingOptions)
            XOpt(
              title: cap(d.label),
              on: s.profile.dating == d.id,
              onTap: () {
                s.updateProfile((x) => x.dating = d.id);
                Navigator.pop(ctx);
              },
            ),
          sheetCancel(ctx),
        ]),
      );

  void _backupSheet(BuildContext context) => showSheet(
        context,
        (ctx) => Sheet(children: [
          sheetTitle('Резервна копія'),
          sheetText('Зашифрований файл з усіма записами. Без копії записи зникнуть разом з телефоном.'),
          XOpt(
            title: 'Зберегти копію',
            sub: 'На Google Диск, iCloud Drive чи куди зручно',
            radio: false,
            lead: Ico(BS.cloud, size: 20, color: K.acc),
            onTap: () {
              Navigator.pop(ctx);
              go(context, const BackupScreen(export: true));
            },
          ),
          XOpt(
            title: 'Відновити з копії',
            sub: 'Замінить усі дані на телефоні даними з файлу',
            radio: false,
            lead: Ico(BS.restore, size: 20, color: K.acc),
            onTap: () {
              Navigator.pop(ctx);
              go(context, const BackupScreen(export: false));
            },
          ),
          sheetCancel(ctx),
        ]),
      );

  void _dateSheet(BuildContext context, AppStore s) {
    final b = s.profile.birth;
    final parts = b == null ? ['', '', ''] : b.split('-');
    final d = TextEditingController(text: parts.length == 3 ? parts[2] : '');
    final m = TextEditingController(text: parts.length == 3 ? parts[1] : '');
    final y = TextEditingController(text: parts.length == 3 && parts[0] != '0000' ? parts[0] : '');
    Widget box(TextEditingController c, String label, int len) => DInput(
          controller: c,
          label: label,
          hint: label == 'Рік' ? 'РРРР' : (label == 'День' ? 'ДД' : 'ММ'),
          style: pr(20),
          align: TextAlign.center,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(len)],
        );
    showSheet(
      context,
      (ctx) => Sheet(children: [
        sheetTitle('Моя дата'),
        sheetText('Знак, аркан і всі метчі перерахуються.'),
        Row(children: [
          Expanded(flex: 10, child: box(d, 'День', 2)),
          const SizedBox(width: 8),
          Expanded(flex: 10, child: box(m, 'Місяць', 2)),
          const SizedBox(width: 8),
          Expanded(flex: 14, child: box(y, 'Рік', 4)),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Cta('Зберегти', onTap: () {
            final dd = int.tryParse(d.text), mm = int.tryParse(m.text), yy = int.tryParse(y.text);
            final now = DateTime.now().year;
            if (dd == null || mm == null || yy == null || mm < 1 || mm > 12 || dd < 1 || yy < 1930 || yy > now - 16) {
              dToast(ctx, 'Перевір дату');
              return;
            }
            final dt = DateTime(yy, mm, dd);
            if (dt.month != mm || dt.day != dd) {
              dToast(ctx, 'Такої дати нема');
              return;
            }
            s.updateProfile((x) => x.birth = iso(dt));
            Navigator.pop(ctx);
            dToast(context, 'Дату збережено');
          }),
        ),
        sheetCancel(ctx),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    final a = astroOf(p.birth);
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final sexN = sexQuestions.where((q) => q.always || p.sexQs.contains(q.id)).length;
    final ptN = partnerQuestions.where((q) => q.always || p.ptQs.contains(q.id)).length;
    final premium = p.premium;
    final initial = p.name.trim().isEmpty ? 'V' : p.name.trim()[0].toUpperCase();
    final dating = datingOptions.firstWhere((d) => d.id == p.dating, orElse: () => datingOptions.first);

    return DScroll(
      overlay: const [],
      children: [
        const BoardHeader('Налаштування'),
        // --- профіль ---
        Press(
          onTap: () => go(context, const MyArcanaScreen()),
          label: 'Мій аркан',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(begin: const Alignment(-.87, -.5), end: const Alignment(.87, .5), colors: [Color.alphaBlend(K.a(.22), K.hour), K.hour], stops: const [0, .6]),
              border: Border.all(color: K.a(.25)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment(-.64, -.77), end: Alignment(.64, .77), colors: [K.acc, K.haze])),
                alignment: Alignment.center,
                child: Text(initial, style: pr(22, color: K.bg, h: 1)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name.isEmpty ? 'Ти' : p.name, style: rw(16, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    a == null ? 'Додай дату, щоб побачити аркан' : [a.signName, if (a.romanNum != null) 'Аркан ${a.romanNum} ${a.arcanaName}'].join(' · '),
                    style: rw(12, color: K.soft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: premium ? K.acc : null,
                  borderRadius: BorderRadius.circular(999),
                  border: premium ? null : Border.all(color: K.w(.2)),
                ),
                alignment: Alignment.center,
                child: Text(premium ? 'Premium' : 'Free', style: rw(12, color: premium ? K.bg : K.soft2, w: FontWeight.w700)),
              ),
            ]),
          ),
        ),
        // --- підписка ---
        labeled(
          'Підписка',
          Grp([
            GRow(
              icon: _icStar,
              title: premium ? 'Premium' : 'Безкоштовний план',
              value: premium ? 'тестовий' : '${_monthCount(s)} з $freeEntriesPerMonth записів',
              arrow: BS.chev,
              onTap: () => go(context, const SubscriptionScreen()),
            ),
            GRow(icon: BS.restore, title: 'Відновити покупки', onTap: () => dToast(context, 'Активних покупок не знайдено')),
            GRow(
              icon: BS.card,
              title: 'Тестовий Premium',
              sub: 'Поки нема оплати в магазині',
              trailing: SwS(on: premium, label: 'Тестовий Premium', onChanged: (v) => s.updateProfile((x) => x.premium = v)),
            ),
          ]),
        ),
        // --- записи ---
        labeled(
          'Записи',
          Grp([
            GRow(icon: BS.wrapped, title: 'Wrapped', value: cap(monthsNom[prev.month - 1]), arrow: BS.chev, onTap: () => go(context, WrappedScreen(month: iso(prev).substring(0, 7)))),
            GRow(icon: _icStar, title: 'Мої питання', value: '$sexN + $ptN', arrow: BS.chev, onTap: () => go(context, const QuestionsScreen())),
            GRow(icon: BS.download, title: 'Експорт', value: 'Таблиця, календар', arrow: BS.chev, onTap: () => go(context, const ExportScreen())),
            GRow(icon: BS.upload, title: 'Імпорт', value: 'З таблиці чи календаря', arrow: BS.chev, onTap: () => go(context, const ImportScreen())),
            GRow(icon: BS.table, title: 'Усі записи таблицею', arrow: BS.chev, onTap: () => go(context, const TableScreen())),
            GRow(
              icon: BS.bell,
              title: 'Нагадати записати',
              trailing: SwS(on: profOpt(p, 'remind'), label: 'Нагадувати записати після зустрічі', onChanged: (v) => _setOpt(s, 'remind', v)),
            ),
          ]),
        ),
        // --- приватність ---
        labeled(
          'Приватність',
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Grp([
              GRow(
                icon: BS.lock,
                title: kIsWeb ? 'PIN-код' : 'PIN і Face ID',
                trailing: SwS(
                  on: p.pinEnabled,
                  label: 'PIN і Face ID',
                  onChanged: (v) async {
                    if (v) {
                      go(context, const PinNewScreen());
                    } else {
                      await PinService.clear();
                      await s.updateProfile((x) => x.pinEnabled = false);
                    }
                  },
                ),
              ),
              if (p.pinEnabled) GRow(icon: BS.dots, title: 'Змінити PIN', arrow: BS.chev, onTap: () => go(context, const PinNewScreen())),
              GRow(icon: BS.square, title: 'Іконка апки', value: p.appIcon == 'light' ? 'Світла' : 'Темна', arrow: BS.chev, onTap: () => _iconSheet(context, s)),
              GRow(
                icon: BS.eyeOff,
                title: 'Розмивати фото',
                trailing: SwS(on: profOpt(p, 'blur'), label: 'Розмивати фото', onChanged: (v) => _setOpt(s, 'blur', v)),
              ),
              GRow(
                icon: BS.cloud,
                title: 'Резервна копія',
                sub: 'Зашифрована. Без неї записи зникнуть разом з телефоном',
                arrow: BS.chev,
                onTap: () => _backupSheet(context),
              ),
            ]),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Text(
                  'Це веб-версія для тесту. Записи живуть тільки в цьому браузері. Додай Vespr на початковий екран '
                  '(Safari → Поділитися → «На початковий екран»), інакше Safari може стерти дані, якщо довго не відкривати.',
                  style: rw(12, color: K.haze, h: 1.5),
                ),
              ),
          ]),
        ),
        // --- загальне ---
        labeled(
          "Загальне і здоров'я",
          Grp([
            GRow(icon: BS.cal, title: 'Моя дата', value: p.birth == null ? 'Додай' : toUA(p.birth), arrow: BS.chev, onTap: () => _dateSheet(context, s)),
            GRow(icon: BS.globe, title: 'Мова', value: p.lang == 'en' ? 'English' : 'Українська', arrow: BS.chev, onTap: () => _langSheet(context, s)),
            GRow(icon: BS.people, title: 'Зустрічаюсь', value: dating.label, arrow: BS.chev, onTap: () => _datingSheet(context, s)),
            GRow(
              icon: BS.heart,
              title: 'Нагадувати про тести',
              trailing: SwS(on: profOpt(p, 'tests'), label: 'Нагадувати про тести', onChanged: (v) => _setOpt(s, 'tests', v)),
            ),
          ]),
        ),
        // --- документи ---
        labeled(
          'Документи',
          Grp(inset: 14, [
            GRow(title: 'Умови використання', arrow: BS.ext, onTap: () => go(context, const DocScreen(doc: termsDoc))),
            GRow(title: 'Політика приватності', arrow: BS.ext, onTap: () => go(context, const DocScreen(doc: privacyDoc))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Press(
            onTap: () => go(context, const DeleteAllScreen()),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: K.red.withValues(alpha: .35)),
                color: const Color(0xFFD9544F).withValues(alpha: .05),
              ),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Ico(BS.trash, size: 16, color: K.red),
                const SizedBox(width: 8),
                Text('Видалити все', style: rw(15, color: K.red, w: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Мої питання
// =====================================================================
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});
  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  int tab = 0;
  List<String>? sex, pt;
  bool warn = false;

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    sex ??= [...s.profile.sexQs];
    pt ??= [...s.profile.ptQs];
    final qs = tab == 0 ? sexQuestions : partnerQuestions;
    final cur = tab == 0 ? sex! : pt!;
    final n = qs.where((q) => q.always || cur.contains(q.id)).length;
    final mins = math.max(1, (n * 7 / 60).round());

    Widget row(Question q) {
      final on = q.always || cur.contains(q.id);
      return Semantics(
        checked: on,
        button: true,
        child: InkWell(
          onTap: q.always
              ? null
              : () => setState(() {
                    if (on) {
                      cur.remove(q.id);
                      warn = true;
                    } else {
                      cur.add(q.id);
                      warn = false;
                    }
                  }),
          highlightColor: K.w(.03),
          splashColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Ck(on, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(q.text, style: rw(14, color: on ? K.star : K.muted, w: on ? FontWeight.w500 : FontWeight.w400, h: 1.35))),
                if (q.always) ...[
                  const SizedBox(width: 8),
                  Ico(BS.lock, size: 11, color: K.muted),
                  const SizedBox(width: 5),
                  Text('завжди', style: rw(11, color: K.muted, w: FontWeight.w500)),
                ],
              ]),
            ),
          ),
        ),
      );
    }

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 130),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              const BoardHeader('Налаштування'),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Мої питання', style: pr(34, h: 1.1)),
                const SizedBox(height: 8),
                Text('Три базові питання є завжди. Решту обирай скільки хочеш. Вони однакові для всіх людей, тож їх можна порівнювати.', style: rw(14, color: K.muted2, h: 1.5)),
              ]),
              Tabs(items: const [('Секс', null), ('Він', null)], index: tab, onChanged: (i) => setState(() => tab = i)),
              Grp(inset: 52, [for (final q in qs) row(q)]),
            ], 16)),
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0017161F), K.bg], stops: [0, .34]),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('$n ${plural(n, 'питання', 'питання', 'питань')}', style: rw(15, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    warn ? 'Відповіді збережуться. Просто перестанемо питати.' : 'Запис займе приблизно $mins хв',
                    style: rw(12, color: warn ? K.accSoft : K.muted, h: 1.35),
                  ),
                ]),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 130,
                child: Cta('Зберегти', onTap: () async {
                  final a = sex!, b = pt!;
                  await s.updateProfile((x) {
                    x.sexQs = a;
                    x.ptQs = b;
                  });
                  if (context.mounted) Navigator.of(context).maybePop();
                }),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// =====================================================================
// Пейвол
// =====================================================================
enum PaywallKind { main, limit, match }

class PaywallScreen extends StatefulWidget {
  final PaywallKind kind;
  final String? name; // для метчу
  const PaywallScreen({super.key, this.kind = PaywallKind.main, this.name});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String plan = 'y';
  static const _plans = [
    ('y', 'Рік', '−52%', '\$39,99 одним платежем', '\$3,33'),
    ('m', 'Місяць', '', 'Можна скасувати будь-коли', '\$6,99'),
  ];

  void _buy(AppStore s) => showSheet(
        context,
        (ctx) => Sheet(children: [
          sheetTitle('Оплата ще не підключена'),
          sheetText("Оплата через App Store і Google Play з'явиться в першій збірці для магазинів. Поки можна ввімкнути тестовий Premium: усе відкриється без оплати."),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Cta('Увімкнути тестовий Premium', onTap: () async {
              await s.updateProfile((x) => x.premium = true);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) Navigator.of(context).maybePop();
            }),
          ),
          sheetCancel(ctx),
        ]),
      );

  Widget _teaser(String tag, String lead, String hidden, String? sub) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F2B3A), Color(0xFF29262F)]),
          border: Border.all(color: K.w(.05)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Ico(Svgs.star4, size: 10, color: K.accSoft),
                const SizedBox(width: 5),
                Text(tag, style: rw(10.5, color: K.accSoft, w: FontWeight.w600, ls: .1)),
              ]),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(text: '$lead ', children: [
                  TextSpan(
                    text: hidden,
                    semanticsLabel: 'приховано',
                    style: TextStyle(foreground: Paint()
                      ..color = const Color(0xFFD7D3E0)
                      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.3)),
                  ),
                ]),
                style: rw(13.5, h: 1.35),
              ),
              if (sub != null) ...[const SizedBox(height: 5), Text(sub, style: rw(11.5, color: K.muted2))],
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: K.a(.14)),
            alignment: Alignment.center,
            child: Ico(BS.lock, size: 13, color: K.accSoft),
          ),
        ]),
      );

  Widget _avatarRing(Widget child, Color ring) => Container(
        width: 72, height: 72,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg),
          child: ClipOval(child: child),
        ),
      );

  List<Widget> _hero(AppStore s) {
    switch (widget.kind) {
      case PaywallKind.main:
        return [
          const SizedBox(height: 4),
          const Center(child: _SpinRing(size: 118, child: Text('2', style: TextStyle(fontFamily: 'Prata', fontSize: 52, color: K.star, height: 1)))),
          const SizedBox(height: 16),
          Text('Ми помітили 2 закономірності про тебе', textAlign: TextAlign.center, style: pr(30, h: 1.15)),
          const SizedBox(height: 16),
          _teaser('Про людей', 'Найкращі вечори в тебе з тими, хто', 'пише першим наступного ранку', 'І це точно не зовнішність.'),
          const SizedBox(height: 8),
          _teaser('Про тебе', 'Ти кінчаєш удвічі частіше, коли', "не п'єш і не поспішаєш", 'Сама б не здогадалась.'),
        ];
      case PaywallKind.limit:
        final next = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
        final n = int.parse(_monthCount(s));
        return [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: gapped([
              for (var i = 0; i < freeEntriesPerMonth; i++)
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: K.acc,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: i == freeEntriesPerMonth - 1 ? [BoxShadow(color: K.a(.6), blurRadius: 22)] : null,
                    ),
                  ),
                ),
            ], 8, horizontal: true)),
          ),
          const SizedBox(height: 20),
          Text('Цього місяця ти записала $n ${plural(n, 'зустріч', 'зустрічі', 'зустрічей')}', textAlign: TextAlign.center, style: pr(30, h: 1.15)),
          const SizedBox(height: 10),
          Text('Нові записи відкриються 1 ${monthsGen[next.month - 1]}. Або вже зараз з Premium.', textAlign: TextAlign.center, style: rw(14, color: K.soft, h: 1.5)),
        ];
      case PaywallKind.match:
        final me = s.profile.name.trim();
        final nm = (widget.name ?? '').trim();
        return [
          const SizedBox(height: 4),
          Center(
            child: SizedBox(
              width: 200, height: 118,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: 0, top: 23,
                  child: _avatarRing(
                    Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment(-.64, -.77), end: Alignment(.64, .77), colors: [K.acc, K.haze])),
                      alignment: Alignment.center,
                      child: Text(me.isEmpty ? 'V' : me[0].toUpperCase(), style: pr(26, color: K.bg, h: 1)),
                    ),
                    K.a(.6),
                  ),
                ),
                Positioned(
                  right: 0, top: 23,
                  child: _avatarRing(Blob(seed: nm.isEmpty ? 0 : nm.codeUnits.fold(0, (a, b) => a + b), w: 64, h: 64, circle: true), K.soft.withValues(alpha: .5)),
                ),
                Positioned(
                  left: 58, top: 0,
                  child: Transform.rotate(
                    angle: -3 * math.pi / 180,
                    child: Container(
                      width: 84, height: 118,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(begin: const Alignment(-.34, -1), end: const Alignment(.34, 1), colors: [K.a(.6), K.haze.withValues(alpha: .3)]),
                        boxShadow: [
                          BoxShadow(color: K.a(.55), blurRadius: 44, offset: const Offset(0, 24), spreadRadius: -18),
                          BoxShadow(color: const Color(0x9908070C), blurRadius: 40, offset: const Offset(0, 20), spreadRadius: -16),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(begin: Alignment(-.17, -1), end: Alignment(.17, 1), colors: [Color(0xFF2E2A3B), Color(0xFF1D1B26)]),
                          border: Border.all(color: K.a(.35)),
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: RadialGradient(center: const Alignment(0, -.2), radius: .9, colors: [K.a(.22), K.a(0)], stops: const [0, .6])))),
                          ImageFiltered(imageFilter: _blur7, child: Text('XVII', style: pr(34))),
                          Ico(BS.lock, size: 22, color: K.star),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text(nm.isEmpty ? 'Твій метч уже пораховано' : 'Твій метч з ${instrCase(nm)} уже пораховано', textAlign: TextAlign.center, style: pr(30, h: 1.15)),
          const SizedBox(height: 16),
          _teaser('Стосунки', 'Він думає про тебе частіше, ніж зізнається. Особливо', 'коли дрочить у душі', null),
          const SizedBox(height: 8),
          _teaser('Секс', 'Найбільше його заводить,', 'коли ти береш у рот і не поспішаєш', null),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final y = plan == 'y';
    final legal = 'Підписка продовжується автоматично: ${y ? '\$39,99 на рік' : '\$6,99 на місяць'}. Скасувати можна в App Store щонайменше за 24 години до кінця періоду.';
    final cta = switch (widget.kind) { PaywallKind.main => 'Відкрити закономірності', PaywallKind.limit => 'Записувати без ліміту', PaywallKind.match => 'Відкрити метч' };
    final next = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    final skip = switch (widget.kind) { PaywallKind.main => 'Продовжити безкоштовно', PaywallKind.limit => 'Почекаю до ${monthsGen[next.month - 1]}', PaywallKind.match => 'Повернутись' };

    Widget planBtn((String, String, String, String, String) p) {
      final on = plan == p.$1;
      return Semantics(
        selected: on,
        button: true,
        child: Press(
          onTap: () => setState(() => plan = p.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: on ? Color.alphaBlend(K.a(.1), K.bg) : K.hour,
              border: Border.all(color: on ? K.acc : K.w(.1), width: 1.5),
              boxShadow: on ? [BoxShadow(color: K.a(.55), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -18)] : null,
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? K.acc : K.w(.3), width: on ? 6 : 1.5)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(p.$2, style: rw(15, w: FontWeight.w700)),
                    if (p.$3.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999)),
                        alignment: Alignment.center,
                        child: Text(p.$3, style: rw(11, color: K.bg, w: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(p.$4, style: rw(12, color: K.muted2)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(p.$5, style: pr(21, h: 1)),
                const SizedBox(height: 2),
                Text('на місяць', style: rw(11, color: K.muted2)),
              ]),
            ]),
          ),
        ),
      );
    }

    Widget ben(String t) => Row(children: [
          const Ico(Svgs.star4, size: 12, color: K.acc),
          const SizedBox(width: 10),
          Flexible(child: Text(t, style: rw(13))),
        ]);

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned(left: -60, top: -20, child: EGlow(w: 510, h: 420, colors: [K.a(.22), K.haze.withValues(alpha: .08), K.a(0)], stops: const [0, .45, .7])),
        starDot(58, 130, 2, K.star, .6),
        starDot(320, 200, 3, K.star, .45),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h - 76),
              child: IntrinsicHeight(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    IconBtn(svg: BS.close, label: 'Закрити', onTap: () => Navigator.of(context).maybePop()),
                    const Spacer(),
                    Press(
                      onTap: () => dToast(context, 'Активних покупок не знайдено'),
                      child: SizedBox(height: 44, child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Відновити покупки', style: rw(13, color: K.soft, w: FontWeight.w600))))),
                    ),
                  ]),
                  ..._hero(s),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: ben('Повна мапа')), const SizedBox(width: 12), Expanded(child: ben('Порівняння людей'))]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: ben('Wrapped щомісяця')), const SizedBox(width: 12), Expanded(child: ben('Астро-метч'))]),
                  const Spacer(),
                  const SizedBox(height: 12),
                  for (final p in _plans) ...[planBtn(p), const SizedBox(height: 8)],
                  const SizedBox(height: 4),
                  _ShineCta(text: s.profile.premium ? 'У тебе вже Premium' : cta, onTap: s.profile.premium ? null : () => _buy(s)),
                  const SizedBox(height: 10),
                  Text(legal, textAlign: TextAlign.center, style: rw(10.5, color: K.muted2, h: 1.45)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Press(onTap: () => go(context, const DocScreen(doc: termsDoc)), child: Padding(padding: const EdgeInsets.all(4), child: Text('Умови', style: rw(10.5, color: K.soft).copyWith(decoration: TextDecoration.underline, decorationColor: K.soft)))),
                    Text('·', style: rw(10.5, color: K.muted2)),
                    Press(onTap: () => go(context, const DocScreen(doc: privacyDoc)), child: Padding(padding: const EdgeInsets.all(4), child: Text('Приватність', style: rw(10.5, color: K.soft).copyWith(decoration: TextDecoration.underline, decorationColor: K.soft)))),
                  ]),
                  Press(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(skip, textAlign: TextAlign.center, style: rw(13, color: K.muted2))),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

final _blur7 = ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5);

/// Кільце з конічним градієнтом, що повільно обертається
class _SpinRing extends StatefulWidget {
  final double size;
  final Widget child;
  const _SpinRing({required this.size, required this.child});
  @override
  State<_SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<_SpinRing> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      c.stop();
    } else if (!c.isAnimating) {
      c.repeat();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size, height: widget.size,
        child: Stack(alignment: Alignment.center, children: [
          RotationTransition(turns: c, child: CustomPaint(size: Size.square(widget.size), painter: _RingPainter())),
          widget.child,
        ]),
      );
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final sw = r * .11;
    final center = Offset(r, r);
    final rect = Rect.fromCircle(center: center, radius: r);
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: const GradientRotation(-math.pi / 2),
      colors: [K.acc, K.haze, K.haze.withValues(alpha: 0), K.acc],
    ).createShader(rect);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..color = K.a(.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, r - sw / 2, glow);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..shader = shader;
    canvas.drawCircle(center, r - sw / 2, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// .cta з відблиском, що пробігає раз на 3.6 с
class _ShineCta extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  const _ShineCta({required this.text, this.onTap});
  @override
  State<_ShineCta> createState() => _ShineCtaState();
}

class _ShineCtaState extends State<_ShineCta> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !c.isAnimating) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) c.repeat();
      });
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final off = widget.onTap == null;
    return Press(
      onTap: widget.onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: off ? K.w(.06) : K.acc,
          boxShadow: off ? null : const [BoxShadow(color: Color(0x8C08070C), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -12)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
            if (!off)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: c,
                  builder: (_, __) {
                    // відблиск 30% ширини їде зліва (-40%) направо (130%) за перші 45% циклу
                    final t = (c.value / .45).clamp(0.0, 1.0);
                    final left = -.4 + t * 1.7;
                    return Align(
                      alignment: Alignment(2 * left / .7 - 1, 0),
                      child: FractionallySizedBox(
                        widthFactor: .3,
                        heightFactor: 1,
                        child: Transform(
                          transform: Matrix4.skewX(-.32),
                          child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x73FFFFFF), Color(0x00FFFFFF)]))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Center(child: Text(widget.text, style: rw(16, color: off ? K.haze : K.bg, w: FontWeight.w700))),
          ]),
      ),
    );
  }
}

// =====================================================================
// Підписка
// =====================================================================
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  Widget _pb(String t, {double size = 14, double gap = 10}) => Row(children: [
        Container(
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: K.a(.6), blurRadius: 8)], shape: BoxShape.circle),
          child: const Ico(Svgs.star4, size: 14, color: K.acc),
        ),
        SizedBox(width: gap),
        Expanded(child: Text(t, style: rw(size, color: const Color(0xFFE6E2EB)))),
      ]);

  Widget _bi(Color bg, Color fg) => Container(
        width: 42, height: 42,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        alignment: Alignment.center,
        child: Ico(BS.arrow, size: 14, color: fg),
      );

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final premium = s.profile.premium;
    final restore = Press(
      onTap: () => dToast(context, 'Активних покупок не знайдено'),
      child: SizedBox(height: 44, child: Center(child: Text('Відновити покупки', style: rw(15, color: K.soft, w: FontWeight.w500)))),
    );

    final premiumBody = <Widget>[
      // картка Premium
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: K.w(.03),
          border: Border.all(color: K.w(.07)),
          boxShadow: [BoxShadow(color: K.a(.45), blurRadius: 60, offset: const Offset(0, 30), spreadRadius: -30)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: 186,
            child: Stack(children: [
              const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-.34, -1), end: Alignment(.34, 1), colors: [Color(0xFF2F2A3A), Color(0xFF1E1B26)])))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.bottomLeft, radius: 1.1, colors: [K.haze.withValues(alpha: .35), K.haze.withValues(alpha: 0)], stops: const [0, .6])))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 1.2, colors: [K.a(.45), K.a(0)], stops: const [0, .6])))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0x00FFFFFF), const Color(0x17FFFFFF), const Color(0x00FFFFFF)], stops: const [.35, .48, .6])))),
              Positioned(left: 8, top: 8, right: 8, bottom: 8, child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: K.accSoft.withValues(alpha: .22))))),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(center: Alignment(0, -.4), colors: [Color(0xFFF6A890), K.acc]), boxShadow: [BoxShadow(color: K.a(.6), blurRadius: 10)]),
                      alignment: Alignment.center,
                      child: Ico(BS.check, size: 9, color: K.bg),
                    ),
                    const SizedBox(width: 7),
                    Text('Активна', style: rw(12, w: FontWeight.w500)),
                    const Spacer(),
                    Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: K.a(.8), blurRadius: 10)]), child: const Ico(Svgs.star4, size: 22, color: K.acc)),
                  ]),
                  const Spacer(),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Colors.white, Color(0xFFEBC2B4)], stops: [0, .3, 1]).createShader(r),
                    child: Text('Premium', style: pr(38, h: 1.05)),
                  ),
                  const SizedBox(height: 4),
                  Text('Тестовий доступ · без оплати', style: rw(13, color: K.soft2)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: K.accSoft.withValues(alpha: .16)))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Image.asset('assets/img/logo.webp', width: 62, semanticLabel: 'Vespr'),
                      const Spacer(),
                      Text('поки ввімкнено', style: rw(11, color: K.muted)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
          Text('Що в тебе відкрито', style: rw(12, color: K.muted, w: FontWeight.w500, ls: .24)),
          _pb('Без лімітів'),
          _pb('Порівняння і метчі'),
          _pb('Повна мапа і Wrapped'),
        ], 12)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: K.w(.03), border: Border.all(color: K.w(.07))),
        child: Column(children: [
          for (final kv in const [('Наступне списання', 'немає'), ('Продовження', 'вручну'), ('Як увімкнено', 'тестовий перемикач')]) ...[
            if (kv.$1 != 'Наступне списання') Container(height: 1, color: K.w(.06)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                Text(kv.$1, style: rw(14, color: K.muted2)),
                const Spacer(),
                Text(kv.$2, style: rw(14, w: FontWeight.w500)),
              ]),
            ),
          ],
        ]),
      ),
    ];

    final freeBody = <Widget>[
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), color: K.w(.025), border: Border.all(color: K.w(.06))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(children: [
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment(-.34, -1), end: Alignment(.34, 1), colors: [Color(0xFF2A2733), Color(0xFF211F29)])))),
            Positioned(left: 8, top: 8, right: 8, bottom: 8, child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.07))))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    height: 24,
                    padding: const EdgeInsets.fromLTRB(9, 0, 10, 0),
                    decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.1))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.soft))),
                      const SizedBox(width: 6),
                      Text('Твій план', style: rw(11, color: K.soft2, w: FontWeight.w500, ls: .22)),
                    ]),
                  ),
                  const Spacer(),
                  Ico(BS.starO, size: 20, color: const Color(0xFF8F89A6)),
                ]),
                const SizedBox(height: 26),
                Text('Безкоштовний', style: pr(34, color: const Color(0xFFE6E2EB), h: 1.05)),
                const SizedBox(height: 16),
                ...gapped([
                  for (final f in [(BS.mic, '$freeEntriesPerMonth записів і 3 голосові на місяць'), (BS.people, 'До $freePeople людей'), (BS.starO, 'Знак і аркан, нагороди')])
                    Row(children: [
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.1))),
                        alignment: Alignment.center,
                        child: Ico(f.$1, size: 13, color: K.muted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f.$2, style: rw(13, color: const Color(0xFFBDB8CC)))),
                    ]),
                ], 10),
              ]),
            ),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: onBase(RadialGradient(center: Alignment.centerLeft, radius: 1.2, colors: [K.a(.16), K.a(0)], stops: const [0, .7]), K.w(.02)),
          border: Border.all(color: K.a(.22)),
        ),
        child: Row(children: [
          Transform.rotate(
            angle: -6 * math.pi / 180,
            child: Container(
              width: 84, height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(begin: Alignment(-.34, -1), end: Alignment(.34, 1), colors: [Color(0xFF3A2E35), Color(0xFF1E1B26)]),
                border: Border.all(color: K.accSoft.withValues(alpha: .25)),
                boxShadow: [BoxShadow(color: K.a(.4), blurRadius: 24, offset: const Offset(0, 12), spreadRadius: -12)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: K.a(.9), blurRadius: 6)]), child: const Ico(Svgs.star4, size: 14, color: K.acc)),
                Text('Premium', style: pr(14, h: 1)),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: gapped([
              Text('У Premium', style: rw(12, color: K.muted, w: FontWeight.w500, ls: .24)),
              _pb('Без лімітів, порівняння і метчі', size: 13, gap: 8),
              _pb('Повна мапа і Wrapped щомісяця', size: 13, gap: 8),
            ], 8)),
          ),
        ]),
      ),
    ];

    return DScroll(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (premium)
          Press(
            onTap: () => s.updateProfile((x) => x.premium = false),
            child: Container(
              height: 54,
              padding: const EdgeInsets.fromLTRB(24, 0, 6, 0),
              decoration: BoxDecoration(
                color: K.star,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: K.w(.4), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -18)],
              ),
              child: Row(children: [
                Expanded(child: Text('Вимкнути тестовий Premium', style: rw(15, color: K.bg, w: FontWeight.w700))),
                _bi(K.bg.withValues(alpha: .08), K.bg),
              ]),
            ),
          )
        else
          Press(
            onTap: () => go(context, const PaywallScreen()),
            child: Container(
              height: 58,
              padding: const EdgeInsets.fromLTRB(24, 0, 6, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const RadialGradient(center: Alignment.topLeft, radius: 2.4, colors: [Color(0xFFF6A890), K.acc], stops: [0, .6]),
                boxShadow: [BoxShadow(color: K.a(.65), blurRadius: 32, offset: const Offset(0, 16), spreadRadius: -16)],
              ),
              child: Row(children: [
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Перейти на Premium', style: rw(15, color: K.bg, w: FontWeight.w700)),
                    Text('від \$3,33 на місяць', style: rw(11, color: K.bg.withValues(alpha: .7), w: FontWeight.w500)),
                  ]),
                ),
                _bi(K.bg.withValues(alpha: .08), K.bg),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        restore,
      ]),
      children: [
        BoardHeader('Підписка', right: premium ? SizedBox(width: 70, child: Image.asset('assets/img/logo.webp', width: 70, semanticLabel: 'Vespr')) : null),
        ...(premium ? premiumBody : freeBody),
        const SizedBox(height: 60),
      ],
    );
  }
}

// =====================================================================
// Документи
// =====================================================================
class DocScreen extends StatelessWidget {
  final LegalDoc doc;
  const DocScreen({super.key, required this.doc});

  List<InlineSpan> _spans(String t) {
    final out = <InlineSpan>[];
    final re = RegExp('⟦(.*?)⟧');
    var i = 0;
    for (final m in re.allMatches(t)) {
      if (m.start > i) out.add(TextSpan(text: t.substring(i, m.start)));
      out.add(TextSpan(text: m.group(1), style: TextStyle(color: K.accSoft, backgroundColor: K.a(.1))));
      i = m.end;
    }
    if (i < t.length) out.add(TextSpan(text: t.substring(i)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final body = rw(14, color: K.soft2, h: 1.62);
    return DScroll(
      padding: const EdgeInsets.fromLTRB(22, 58, 22, 40),
      gap: 0,
      children: [
        const BoardHeader('Документи'),
        const SizedBox(height: 26),
        Text(doc.title, style: pr(32, h: 1.15)),
        const SizedBox(height: 8),
        Text(doc.updated, style: rw(12, color: K.muted)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: onBase(RadialGradient(center: Alignment.topLeft, radius: 1.4, colors: [K.a(.14), K.a(0)], stops: const [0, .6]), K.card2),
            border: Border.all(color: K.a(.16)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Коротко', style: rw(12, color: K.accSoft, w: FontWeight.w500, ls: .24)),
            const SizedBox(height: 10),
            ...gapped([
              for (final t in doc.tldr)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 8, right: 10), decoration: const BoxDecoration(shape: BoxShape.circle, color: K.acc)),
                  Expanded(child: Text.rich(TextSpan(children: _spans(t)), style: rw(14, color: const Color(0xFFE6E2EB), h: 1.5))),
                ]),
            ], 9),
          ]),
        ),
        for (final sec in doc.secs) ...[
          const SizedBox(height: 28),
          Text.rich(TextSpan(children: [TextSpan(text: '${sec.n}  ', style: rw(16, color: K.haze)), TextSpan(text: sec.title)]), style: rw(16, w: FontWeight.w500, h: 1.35)),
          const SizedBox(height: 8),
          for (final b in sec.blocks)
            Padding(
              padding: EdgeInsets.only(bottom: b.startsWith('• ') ? 4 : 10, left: b.startsWith('• ') ? 4 : 0),
              child: b.startsWith('• ')
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('•  ', style: body),
                      Expanded(child: Text.rich(TextSpan(children: _spans(b.substring(2))), style: body)),
                    ])
                  : Text.rich(TextSpan(children: _spans(b)), style: body),
            ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: K.w(.07)))),
          child: Text.rich(TextSpan(children: _spans(doc.foot)), style: rw(12, color: K.muted, h: 1.6)),
        ),
      ],
    );
  }
}

// =====================================================================
// Резервна копія (файл)
// =====================================================================
class BackupScreen extends StatefulWidget {
  final bool export;
  const BackupScreen({super.key, required this.export});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final pw = TextEditingController(), pw2 = TextEditingController();
  bool busy = false;
  String? msg;
  bool ok = false;

  @override
  void dispose() {
    pw.dispose();
    pw2.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final s = Store.read(context);
    setState(() {
      busy = true;
      msg = null;
    });
    try {
      if (widget.export) {
        final name = await exportBackup(s.db, pw.text);
        if (!mounted) return;
        setState(() {
          ok = true;
          msg = "Готово: $name. Збережи файл і запам'ятай пароль — без нього копію не відкрити.";
        });
      } else {
        final text = await pickBackupText();
        if (!mounted) return;
        if (text == null) {
          setState(() => busy = false);
          return;
        }
        final DB db = await decryptBackup(text, pw.text);
        db.profile.onboarded = true;
        await s.replaceAll(db);
        if (!mounted) return;
        setState(() {
          ok = true;
          msg = 'Відновлено: ${db.entries.length} записів, ${db.people.length} людей.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        ok = false;
        msg = e is BackupError ? e.message : 'Не вдалося: $e';
      });
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.export;
    final valid = pw.text.length >= 6 && (!exp || pw.text == pw2.text);
    return Screen(
      footer: [Btn(busy ? 'Зачекай…' : (exp ? 'Створити файл копії' : 'Обрати файл і відновити'), onTap: busy || !valid ? null : _run)],
      children: [
        const Header(),
        H1(exp ? 'Зберегти' : 'Відновити', accent: exp ? 'копію' : 'з копії'),
        Txt(
            exp
                ? "Усі записи, люди й налаштування в одному зашифрованому файлі. Збережи його на Google Диск, в iCloud Drive, Telegram «Збережене» або на комп'ютер."
                : 'Обери файл .vespr і введи пароль, з яким його створювала. Усі поточні дані на телефоні буде замінено.',
            muted: true),
        Field(label: 'Пароль копії · мінімум 6 символів', controller: pw, obscure: true, onChanged: (_) => setState(() {})),
        if (exp) Field(label: 'Повтори пароль', controller: pw2, obscure: true, onChanged: (_) => setState(() {})),
        if (busy) const Center(child: CircularProgressIndicator(color: C.accent)),
        if (msg != null) VCard(border: ok ? C.green : C.red, child: Txt(msg!)),
      ],
    );
  }
}

// =====================================================================
// Видалити все
// =====================================================================
class DeleteAllScreen extends StatefulWidget {
  const DeleteAllScreen({super.key});
  @override
  State<DeleteAllScreen> createState() => _DeleteAllScreenState();
}

class _DeleteAllScreenState extends State<DeleteAllScreen> {
  final txt = TextEditingController();
  @override
  void dispose() {
    txt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final ok = txt.text.trim().toUpperCase() == 'ВИДАЛИТИ';
    final ne = s.entries.length, np = s.people.length;

    Widget li(String svg, String? big, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.1))),
              alignment: Alignment.center,
              child: Ico(svg, size: 14, color: K.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  if (big != null) TextSpan(text: '$big ', style: pr(20, h: 1.1)),
                  TextSpan(text: text),
                ]),
                style: rw(14, color: const Color(0xFFD7D3E0)),
              ),
            ),
          ]),
        );

    Widget nt(String text, {bool warn = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Ico(warn ? BS.warn : BS.card, size: 15, color: warn ? K.red : K.muted)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: rw(warn ? 14 : 13, color: warn ? const Color(0xFFE6E2EB) : K.muted, h: 1.5))),
        ]);

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 76, 24, 170),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(center: Alignment(0, -.4), colors: [Color(0x38E25C5C), Color(0x0FE25C5C)]),
                    border: Border.all(color: K.red.withValues(alpha: .32)),
                    boxShadow: const [BoxShadow(color: Color(0x38E25C5C), blurRadius: 34)],
                  ),
                  alignment: Alignment.center,
                  child: Ico(BS.trash, size: 26, color: K.red),
                ),
              ),
              Text('Видалити все назавжди?', style: pr(32, h: 1.12)),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: K.w(.025), border: Border.all(color: K.w(.06))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(23), color: K.card2, border: Border(top: BorderSide(color: K.w(.08)))),
                  child: Column(children: [
                    li(BS.mic, '$ne', '${plural(ne, 'запис', 'записи', 'записів')} з оцінками і голосовими'),
                    Container(height: 1, color: K.w(.07)),
                    li(BS.people, '$np', '${plural(np, 'людина', 'людини', 'людей')} і їхні картки'),
                    Container(height: 1, color: K.w(.07)),
                    li(BS.starO, null, 'А ще мапа, питання, PIN і налаштування'),
                  ]),
                ),
              ),
              nt('Відновити не можна, якщо ти не зберігала копію файлом.', warn: true),
              nt('Підписка від цього не скасується. Керувати нею можна в налаштуваннях App Store.'),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(text: 'Щоб підтвердити, напиши ', children: [TextSpan(text: 'ВИДАЛИТИ', style: rw(13, w: FontWeight.w600, ls: .78))]),
                  style: rw(13, color: K.muted),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: easeD,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: ok ? const [BoxShadow(color: Color(0x1FE25C5C), spreadRadius: 4)] : null,
                  ),
                  child: DInput(
                    controller: txt,
                    hint: 'ВИДАЛИТИ',
                    label: 'Напиши ВИДАЛИТИ',
                    style: rw(16, w: FontWeight.w600, ls: .96),
                    caps: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
            ], 18)),
          ),
        ),
        Positioned(
          left: 24, right: 24, bottom: 24,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Press(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(999)),
                alignment: Alignment.center,
                child: Text('Скасувати', style: rw(16, color: K.bg, w: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              enabled: ok,
              button: true,
              child: Press(
                onTap: !ok
                    ? null
                    : () async {
                        await PinService.clear();
                        await s.wipe();
                        if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: easeD,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ok ? const Color(0xFFD9544F) : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ok ? const Color(0xFFD9544F) : K.w(.1)),
                    boxShadow: ok ? const [BoxShadow(color: Color(0xB3D9544F), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -14)] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text('Видалити все', style: rw(16, color: ok ? Colors.white : K.muted2, w: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
