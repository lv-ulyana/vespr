import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../services/files.dart';
import '../services/pin.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'export_screen.dart';
import 'import_screen.dart';
import 'onboarding.dart';
import 'pin_screens.dart';
import 'table_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    final a = astroOf(p.birth);
    Widget group(List<Widget> xs) => VCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(children: xs));
    return Screen(children: [
      const Header(title: 'Налаштування'),
      VCard(
        onTap: () => go(context, const AboutYou()),
        child: Row(children: [
          Avatar(p.name.isEmpty ? 'V' : p.name, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: T.serif(22)),
              Txt([if (a != null) '${a.signName} · Аркан ${a.romanNum} ${a.arcanaName}', toUA(p.birth)].join(' · '), small: true, muted: true),
            ]),
          ),
        ]),
      ),
      const Label('Підписка'),
      group([
        NavRow(title: p.premium ? 'Premium' : 'Безкоштовний план', sub: p.premium ? 'Без лімітів, повна мапа і Wrapped' : '$freeEntriesPerMonth записів на місяць, до $freePeople людей', icon: Icons.auto_awesome, onTap: () => go(context, const PaywallScreen())),
        SwitchRow(title: 'Тестовий Premium', sub: 'Тимчасово, поки нема оплати в магазині', value: p.premium, onChanged: (v) => s.updateProfile((x) => x.premium = v)),
      ]),
      const Label('Записи'),
      group([
        NavRow(title: 'Мої питання', value: '${p.sexQs.length} + ${p.ptQs.length}', icon: Icons.tune_rounded, onTap: () => go(context, const QuestionsScreen())),
        NavRow(title: 'Експорт', value: 'Таблиця, календар', icon: Icons.ios_share_rounded, onTap: () => go(context, const ExportScreen())),
        NavRow(title: 'Імпорт', value: 'З таблиці чи календаря', icon: Icons.file_upload_outlined, onTap: () => go(context, const ImportScreen())),
        NavRow(title: 'Усі записи таблицею', icon: Icons.table_chart_outlined, onTap: () => go(context, const TableScreen())),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Txt('З ким зустрічаєшся', small: true, muted: true),
            const SizedBox(height: 8),
            Seg<String>(options: [for (final d in datingOptions) SegOpt(d.id, d.label)], value: p.dating, onChange: (v) => s.updateProfile((x) => x.dating = v)),
          ]),
        ),
      ]),
      const Label('Приватність'),
      if (kIsWeb)
        const Txt(
          'Це веб-версія для тесту. Записи живуть тільки в цьому браузері на цьому телефоні. Додай Vespr на початковий екран '
          '(Safari → Поділитися → «На початковий екран»), інакше Safari може стерти дані, якщо довго не відкривати. Face ID тут нема, тільки PIN.',
          small: true,
          muted: true,
        ),
      group([
        SwitchRow(
          title: 'PIN і відбиток',
          sub: 'Питаємо при кожному відкритті',
          value: p.pinEnabled,
          onChanged: (v) async {
            if (v) {
              go(context, const PinNewScreen());
            } else {
              await PinService.clear();
              await s.updateProfile((x) => x.pinEnabled = false);
            }
          },
        ),
        if (p.pinEnabled) NavRow(title: 'Змінити PIN', icon: Icons.lock_outline_rounded, onTap: () => go(context, const PinNewScreen())),
      ]),
      const Label('Резервна копія'),
      group([
        NavRow(title: 'Зберегти копію', sub: 'Зашифрований файл: на Google Диск, iCloud Drive чи куди зручно', icon: Icons.cloud_upload_outlined, onTap: () => go(context, const BackupScreen(export: true))),
        NavRow(title: 'Відновити з копії', sub: 'Замінить усі дані на телефоні даними з файлу', icon: Icons.restore_rounded, onTap: () => go(context, const BackupScreen(export: false))),
      ]),
      const Txt('Телефон також сам копіює дані апки: Android у Google, iPhone в iCloud, якщо резервне копіювання ввімкнене.', small: true, muted: true),
      const Label('Дані'),
      group([
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [const Expanded(child: Txt('Записів', muted: true)), Txt('${s.entries.length}')])),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [const Expanded(child: Txt('Людей', muted: true)), Txt('${s.people.length}')])),
        NavRow(title: 'Видалити все', sub: 'Назавжди, без відновлення', icon: Icons.delete_outline_rounded, onTap: () => go(context, const DeleteAllScreen())),
      ]),
      const Txt('Vespr 0.2 · записи тільки на цьому телефоні', small: true, muted: true, align: TextAlign.center),
    ]);
  }
}

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    Widget list(List<Question> qs, List<String> chosen, void Function(List<String>) set) => Column(children: [
          for (final q in qs)
            Builder(builder: (_) {
              final on = q.always || chosen.contains(q.id);
              final full = !on && chosen.length >= maxChosen;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: full ? 0.4 : 1,
                  child: VCard(
                    color: on ? C.accentBg : Colors.transparent,
                    border: on ? C.accent : C.line,
                    padding: const EdgeInsets.all(14),
                    onTap: q.always || full ? null : () => set(on ? chosen.where((x) => x != q.id).toList() : [...chosen, q.id]),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(q.text, style: T.body(14, C.text, FontWeight.w500)),
                          Txt(q.always ? 'завжди' : q.dim, small: true, muted: true),
                        ]),
                      ),
                      Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, color: on ? C.accent : C.dim),
                    ]),
                  ),
                ),
              );
            }),
        ]);
    final sexChosen = p.sexQs.where((id) => sexQuestions.any((q) => q.id == id && !q.always)).toList();
    return Screen(children: [
      const Header(title: 'Налаштування'),
      const H1('Мої', accent: 'питання'),
      const Txt('Три базові питання є завжди. Решту обирай до 10 у кожній категорії. Вони однакові для всіх людей, тож їх можна порівнювати. Порівняння йде по вимірах, тому зміна набору нічого не ламає.', muted: true),
      Label('Секс · ${sexChosen.length} з $maxChosen'),
      list(sexQuestions, sexChosen, (v) => s.updateProfile((x) => x.sexQs = v)),
      Label('Він · ${p.ptQs.length} з $maxChosen'),
      list(partnerQuestions, p.ptQs, (v) => s.updateProfile((x) => x.ptQs = v)),
    ]);
  }
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String plan = 'y';
  bool note = false;
  static const plans = [
    ('y', 'Рік', '−52%', '\$39,99 одним платежем', '\$3,33'),
    ('m', 'Місяць', '', 'Можна скасувати будь-коли', '\$6,99'),
  ];
  @override
  Widget build(BuildContext context) {
    final premium = Store.of(context).profile.premium;
    return Screen(
      footer: [
        Btn(premium ? 'У тебе вже Premium' : 'Відкрити Premium', onTap: premium ? null : () => setState(() => note = true)),
        Btn('Не зараз', kind: BtnKind.ghost, onTap: () => Navigator.pop(context)),
      ],
      children: [
        const Header(),
        const H1('Vespr Premium', accent: 'без лімітів'),
        for (final x in ['Записи без ліміту і всі люди', 'Повна мапа задоволення', 'Повний Wrapped щомісяця', 'Метч зірок для кожної людини'])
          Text.rich(TextSpan(text: '✦  ', style: const TextStyle(color: C.accent), children: [TextSpan(text: x, style: const TextStyle(color: C.text))]), style: T.body(15, C.text, FontWeight.w500)),
        for (final pl in plans)
          VCard(
            color: plan == pl.$1 ? C.accentBg : Colors.transparent,
            border: plan == pl.$1 ? C.accent : C.line2,
            onTap: () => setState(() => plan = pl.$1),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(text: pl.$2, children: [if (pl.$3.isNotEmpty) TextSpan(text: '  ${pl.$3}', style: const TextStyle(color: C.accent))]), style: T.body(16, C.text, FontWeight.w700)),
                  Txt(pl.$4, small: true, muted: true),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(pl.$5, style: T.serif(22)), const Txt('на місяць', small: true, muted: true)]),
            ]),
          ),
        const Txt('Без пробного періоду. Продовжується автоматично, скасувати можна в Google Play або App Store.', small: true, muted: true),
        if (note)
          const VCard(border: C.accent, child: Txt("Оплата через Google Play і App Store з'явиться в першій збірці для магазинів. Поки можна ввімкнути «Тестовий Premium» у налаштуваннях.")),
      ],
    );
  }
}

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
    setState(() { busy = true; msg = null; });
    try {
      if (widget.export) {
        final name = await exportBackup(s.db, pw.text);
        if (!mounted) return;
        setState(() { ok = true; msg = "Готово: $name. Збережи файл і запам'ятай пароль — без нього копію не відкрити."; });
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
        setState(() { ok = true; msg = 'Відновлено: ${db.entries.length} записів, ${db.people.length} людей.'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { ok = false; msg = e is BackupError ? e.message : 'Не вдалося: $e'; });
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
        Txt(exp
            ? "Усі записи, люди й налаштування в одному зашифрованому файлі. Збережи його на Google Диск, в iCloud Drive, Telegram «Збережене» або на комп'ютер."
            : 'Обери файл .vespr і введи пароль, з яким його створювала. Усі поточні дані на телефоні буде замінено.', muted: true),
        Field(label: 'Пароль копії · мінімум 6 символів', controller: pw, obscure: true, onChanged: (_) => setState(() {})),
        if (exp) Field(label: 'Повтори пароль', controller: pw2, obscure: true, onChanged: (_) => setState(() {})),
        if (busy) const Center(child: CircularProgressIndicator(color: C.accent)),
        if (msg != null) VCard(border: ok ? C.green : C.red, child: Txt(msg!)),
      ],
    );
  }
}

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
    return Screen(
      footer: [
        Btn('Скасувати', kind: BtnKind.light, onTap: () => Navigator.pop(context)),
        Btn('Видалити все', kind: BtnKind.danger, onTap: !ok ? null : () async {
          await PinService.clear();
          await s.wipe();
          if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        }),
      ],
      children: [
        const Header(),
        const H1('Видалити все назавжди?'),
        VCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Txt('${s.entries.length} записів з оцінками'),
            Txt('${s.people.length} людей і їхні картки'),
            const Txt('А ще мапа, питання, PIN і налаштування', muted: true),
          ]),
        ),
        const Txt('Відновити не можна, якщо ти не зберігала копію файлом.'),
        Field(label: 'Щоб підтвердити, напиши ВИДАЛИТИ', hint: 'ВИДАЛИТИ', controller: txt, onChanged: (_) => setState(() {})),
      ],
    );
  }
}
