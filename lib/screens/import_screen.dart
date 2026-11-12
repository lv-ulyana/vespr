import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/import_csv.dart';
import '../logic/import_ics.dart';
import '../services/files.dart';
import '../services/phone_calendar.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';

/// Імпорт: записи з таблиці (CSV) або зустрічі з календаря (телефон чи файл .ics).
/// Ліміт безкоштовної версії на імпорт не діє: це її старі дані. Дизайн: дошки «14.2» і «14.3».
class ImportScreen extends StatefulWidget {
  final bool calendar;
  const ImportScreen({super.key, this.calendar = false});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

enum _Src { phone, file }

enum _Range { next30, past3, past12 }

const _rangeLabels = {_Range.next30: 'Наступні 30 днів', _Range.past3: 'Минулі 3 місяці', _Range.past12: 'Минулий рік'};

class _ImportScreenState extends State<ImportScreen> {
  late bool cal = widget.calendar;
  bool busy = false;

  // ---- таблиця ----
  String? fileName;
  CsvTable? table;
  List<String?> mapping = [];

  // ---- календар ----
  _Src src = kIsWeb ? _Src.file : _Src.phone; // у браузері календар телефону недоступний
  _Range range = _Range.next30;
  List<CalEvent> fileEvents = [];
  String? icsName;
  List<EventChoice>? choices;
  bool onlyKnown = true;
  final Map<String, String> newPeople = {}; // тимчасовий id → ім'я нової людини
  String? calError;

  // ---------- таблиця ----------
  Future<void> _pickCsv() async {
    setState(() => busy = true);
    try {
      final f = await pickFileBytes();
      if (f == null) return;
      final lower = f.name.toLowerCase();
      if (lower.endsWith('.xlsx') || lower.endsWith('.xls') || lower.endsWith('.numbers')) {
        if (mounted) toast(context, 'Це файл Excel. Збережи його як CSV: Файл → Зберегти як → CSV. У Google Таблицях: Файл → Завантажити → CSV.');
        return;
      }
      final t = parseCsv(decodeTextFile(f.bytes));
      if (t.header.isEmpty) {
        if (mounted) toast(context, 'Файл порожній або це не таблиця');
        return;
      }
      setState(() {
        fileName = f.name;
        table = t;
        mapping = autoMap(t.header);
      });
    } catch (e) {
      if (mounted) toast(context, 'Не вдалося прочитати файл: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickField(int col) async {
    final current = mapping[col];
    final options = <String?>[...pickableFields, if (current != null && !pickableFields.contains(current)) current, null];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Стовпець «${table!.header[col]}» — це…', style: T.body(15, C.text, FontWeight.w600)),
          ),
          for (final f in options)
            ListTile(
              title: Text(fieldLabel(f), style: T.body(15, f == current ? C.accent : C.text, FontWeight.w500)),
              trailing: f == current ? const Icon(Icons.check_rounded, color: C.accent) : null,
              onTap: () => Navigator.pop(ctx, f ?? '-'),
            ),
        ]),
      ),
    );
    if (picked == null) return;
    setState(() {
      final f = picked == '-' ? null : picked;
      if (f != null) {
        for (var i = 0; i < mapping.length; i++) {
          if (mapping[i] == f) mapping[i] = null; // поле може бути тільки в одному стовпці
        }
      }
      mapping[col] = f;
    });
  }

  Future<void> _importCsv(AppStore s, CsvImportPlan plan) async {
    setState(() => busy = true);
    await s.importBatch(people: plan.newPeople, entries: plan.entries);
    if (!mounted) return;
    toast(context, 'Додали ${plan.entries.length} ${plural(plan.entries.length, 'запис', 'записи', 'записів')}');
    Navigator.of(context).maybePop();
  }

  List<Widget> _tableTab(AppStore s) {
    final t = table;
    final missing = t == null ? <String>[] : missingRequired(mapping);
    final plan = t == null || missing.isNotEmpty ? null : planCsvImport(t, mapping, s.db, newId: uid);
    return [
      const _Step(1, 'Файл'),
      VCard(
        onTap: busy ? null : _pickCsv,
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: C.green.withValues(alpha: .16), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.table_chart_outlined, size: 18, color: C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: t == null
                ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Txt('Обрати файл .csv'),
                    Txt('З Excel, Google Таблиць, Numbers або експорту Vespr', small: true, muted: true),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Txt(fileName ?? 'таблиця.csv', lines: 1),
                    Txt('${t.rows.length} ${plural(t.rows.length, 'рядок', 'рядки', 'рядків')} · роздільник ${sepLabel(t.sep)}', small: true, muted: true),
                  ]),
          ),
          Text(t == null ? 'Обрати' : 'Інший', style: T.body(13, C.accent, FontWeight.w600)),
        ]),
      ),
      if (t == null)
        const _Note(Icons.info_outline_rounded,
            'Excel: Файл → Зберегти як → CSV. Google Таблиці: Файл → Завантажити → CSV. Потрібні хоча б три стовпці: дата, людина, оцінка 1–5.'),
      if (t != null) ...[
        const _Step(2, 'Стовпці'),
        VCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            for (var i = 0; i < t.header.length; i++)
              InkWell(
                onTap: () => _pickField(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(mapping[i] != null ? Icons.check_rounded : Icons.remove_rounded, size: 16, color: mapping[i] != null ? C.green : C.dim),
                    const SizedBox(width: 10),
                    Expanded(child: Txt(t.header[i].isEmpty ? 'Стовпець ${i + 1}' : t.header[i], lines: 1, color: mapping[i] != null ? C.text : C.muted)),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 170),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0x0DF1EEF2), borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line2)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(fieldLabel(mapping[i]), overflow: TextOverflow.ellipsis, style: T.body(12, mapping[i] != null ? C.text : C.muted, FontWeight.w500))),
                        const Icon(Icons.expand_more_rounded, size: 16, color: C.haze),
                      ]),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
        if (missing.isNotEmpty)
          Txt('Обери стовпець для: ${missing.map(fieldLabel).join(', ')}', small: true, color: C.accentSoft)
        else
          const Txt("Таблицю з експорту Vespr впізнаємо повністю: питання, прапорці, теги, факти.", small: true, muted: true),
      ],
      if (plan != null) ...[
        const _Step(3, 'Що буде'),
        Row(children: [
          _SumTile('${plan.entries.length}', plural(plan.entries.length, 'запис додамо', 'записи додамо', 'записів додамо')),
          const SizedBox(width: 8),
          _SumTile('${plan.newPeople.length}', plan.newPeople.isEmpty ? 'нових людей' : 'нові: ${plan.newPeople.map((p) => p.name).take(3).join(', ')}${plan.newPeople.length > 3 ? '…' : ''}'),
          const SizedBox(width: 8),
          _SumTile('${plan.duplicates}', 'пропустимо: вже є'),
        ]),
        if (plan.skipped.isNotEmpty)
          _Note(Icons.error_outline_rounded,
              'Не візьмемо ${plan.skipped.length} ${plural(plan.skipped.length, 'рядок', 'рядки', 'рядків')}: ${plan.skipped.take(3).map((r) => 'рядок ${r.line} — ${r.reason}').join('; ')}${plan.skipped.length > 3 ? '…' : ''}'),
      ],
    ];
  }

  // ---------- календар ----------
  (DateTime, DateTime) _span() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return switch (range) {
      _Range.next30 => (day, day.add(const Duration(days: 31))),
      _Range.past3 => (DateTime(now.year, now.month - 3, now.day), day),
      _Range.past12 => (DateTime(now.year - 1, now.month, now.day), day),
    };
  }

  Future<void> _loadPhone(AppStore s) async {
    setState(() {
      busy = true;
      calError = null;
    });
    try {
      final (from, to) = _span();
      final evs = await readPhoneCalendar(from, to);
      if (!mounted) return;
      setState(() => _setChoices(evs, s));
    } catch (e) {
      if (mounted) setState(() => calError = e is CalendarAccessError ? e.message : 'Не вдалося прочитати календар: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickIcs(AppStore s) async {
    setState(() {
      busy = true;
      calError = null;
    });
    try {
      final f = await pickFileBytes();
      if (f == null) return;
      final evs = parseIcs(decodeTextFile(f.bytes));
      if (evs.isEmpty) {
        if (mounted) setState(() => calError = 'У файлі нема подій. Потрібен файл .ics — експорт календаря.');
        return;
      }
      fileEvents = evs;
      icsName = f.name;
      if (mounted) setState(() => _setChoices(_inSpan(evs), s));
    } catch (e) {
      if (mounted) setState(() => calError = 'Не вдалося прочитати файл: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<CalEvent> _inSpan(List<CalEvent> evs) {
    final (from, to) = _span();
    return evs.where((e) => !e.start.isBefore(from) && e.start.isBefore(to)).toList();
  }

  void _setChoices(List<CalEvent> evs, AppStore s) {
    choices = buildChoices(evs, s.db);
    onlyKnown = choices!.any((c) => c.personId != null);
  }

  void _changeRange(_Range r, AppStore s) {
    setState(() => range = r);
    if (src == _Src.phone && choices != null) {
      _loadPhone(s);
    } else if (src == _Src.file && fileEvents.isNotEmpty) {
      setState(() => _setChoices(_inSpan(fileEvents), s));
    }
  }

  Future<void> _pickPerson(EventChoice c, AppStore s) async {
    final people = [...s.people.where((p) => !p.isPast), ...s.people.where((p) => p.isPast)];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .7),
          child: ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('«${c.event.title.isEmpty ? 'Без назви' : c.event.title}» — це…', style: T.body(15, C.text, FontWeight.w600)),
            ),
            for (final p in people)
              ListTile(
                title: Text(p.name, style: T.body(15, p.id == c.personId ? C.accent : C.text, FontWeight.w500)),
                subtitle: p.isPast ? Text('минулі', style: T.body(12, C.muted)) : null,
                onTap: () => Navigator.pop(ctx, p.id),
              ),
            for (final e in newPeople.entries)
              ListTile(
                title: Text(e.value, style: T.body(15, e.key == c.personId ? C.accent : C.text, FontWeight.w500)),
                subtitle: Text('нова', style: T.body(12, C.muted)),
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined, color: C.accent),
              title: Text('Нова людина…', style: T.body(15, C.accent, FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, '+'),
            ),
          ]),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    var id = picked;
    if (picked == '+') {
      final name = await _askName();
      if (name == null || name.isEmpty) return;
      id = 'new:${uid()}';
      newPeople[id] = name;
    }
    setState(() {
      c.personId = id;
      c.on = true;
    });
  }

  Future<String?> _askName() {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text("Як його звати?", style: T.serif(22)),
        content: TextField(controller: ctl, autofocus: true, style: T.body(16), textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: "Ім'я або прізвисько")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Скасувати', style: T.body(14, C.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: Text('Додати', style: T.body(14, C.accent, FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _importCal(AppStore s, List<EventChoice> chosen) async {
    setState(() => busy = true);
    final stamp = DateTime.now().toIso8601String();
    final created = <String, Person>{};
    for (final c in chosen) {
      final pid = c.personId!;
      if (pid.startsWith('new:') && !created.containsKey(pid)) {
        created[pid] = Person(id: uid(), name: newPeople[pid]!, createdAt: stamp);
      }
    }
    final ms = meetingsFromChoices(chosen, newId: uid, personIdOf: (c) => created[c.personId!]?.id ?? c.personId!);
    await s.importBatch(people: created.values.toList(), meetings: ms);
    if (!mounted) return;
    final past = chosen.where((c) => c.past).length;
    toast(context, 'Додали ${ms.length} ${plural(ms.length, 'зустріч', 'зустрічі', 'зустрічей')}${past > 0 ? '. Минулі чекають оцінки на головній' : ''}');
    Navigator.of(context).maybePop();
  }

  List<Widget> _calendarTab(AppStore s) {
    final list = choices;
    final visible = list == null ? <EventChoice>[] : list.where((c) => !onlyKnown || c.personId != null || c.on).toList();
    return [
      if (kIsWeb)
        const _Note(Icons.info_outline_rounded, 'У веб-версії календар телефону недоступний. Експортуй календар у файл .ics (Google Календар: Налаштування → Імпорт і експорт) і обери його тут.'),
      if (!kIsWeb)
      Row(children: [
        _Source(on: src == _Src.phone, icon: Icons.smartphone_rounded, title: 'Календар телефону', sub: 'Google або Apple, без файлів', onTap: () => setState(() {
              src = _Src.phone;
              choices = null;
            })),
        const SizedBox(width: 8),
        _Source(on: src == _Src.file, icon: Icons.insert_drive_file_outlined, title: 'Файл .ics', sub: 'Експорт з Outlook чи іншого календаря', onTap: () => setState(() {
              src = _Src.file;
              choices = fileEvents.isEmpty ? null : buildChoices(_inSpan(fileEvents), s.db);
            })),
      ]),
      Chips([for (final r in _Range.values) ChipX(_rangeLabels[r]!, on: range == r, onTap: () => _changeRange(r, s))]),
      if (list == null)
        Btn(
          busy ? 'Зачекай…' : (src == _Src.phone ? 'Показати події' : 'Обрати файл .ics'),
          kind: BtnKind.ghost,
          icon: src == _Src.phone ? Icons.event_note_outlined : Icons.folder_open_outlined,
          onTap: busy ? null : () => src == _Src.phone ? _loadPhone(s) : _pickIcs(s),
        ),
      if (calError != null) Txt(calError!, small: true, color: C.accentSoft),
      if (src == _Src.file && icsName != null && list != null) Txt('$icsName · ${fileEvents.length} подій у файлі', small: true, muted: true),
      if (list != null && list.isEmpty) const Txt('За цей період подій нема.', muted: true),
      if (list != null && list.isNotEmpty && list.any((c) => c.personId == null))
        Chips([
          ChipX('Де впізнали людину', on: onlyKnown, onTap: () => setState(() => onlyKnown = true)),
          ChipX('Усі події · ${list.length}', on: !onlyKnown, onTap: () => setState(() => onlyKnown = false)),
        ]),
      for (final c in visible.take(80))
        _EventPick(
          c: c,
          who: c.personId == null ? null : (newPeople[c.personId] ?? s.personName(c.personId!)),
          onToggle: c.already ? null : () => setState(() => c.on = !c.on),
          onWho: () => _pickPerson(c, s),
        ),
      if (visible.length > 80) Txt('Показали перші 80. Звузь період, щоб побачити решту.', small: true, muted: true),
      if (list != null && list.isNotEmpty)
        const Txt('Людину вгадуємо за ім\'ям у назві події. «Хто це?» — тапни й обери. Майбутні стануть запланованими зустрічами, минулі — зустрічами, які лишилось оцінити.', small: true, muted: true),
      const _Note(Icons.lock_outline_rounded, 'Читаємо тільки події, які ти обереш. У самому календарі нічого не змінюємо.'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    Widget? cta;
    if (!cal) {
      final t = table;
      final plan = t == null || missingRequired(mapping).isNotEmpty ? null : planCsvImport(t, mapping, s.db, newId: uid);
      if (t != null) {
        final n = plan?.entries.length ?? 0;
        cta = Btn(busy ? 'Зачекай…' : 'Імпортувати $n ${plural(n, 'запис', 'записи', 'записів')}', onTap: busy || plan == null || n == 0 ? null : () => _importCsv(s, plan));
      }
    } else if (choices != null) {
      final chosen = choices!.where((c) => c.on && !c.already).toList();
      final noWho = chosen.any((c) => c.personId == null);
      cta = Btn(
        busy ? 'Зачекай…' : (noWho ? 'Обери, хто це, у позначених' : 'Додати ${chosen.length} ${plural(chosen.length, 'зустріч', 'зустрічі', 'зустрічей')}'),
        onTap: busy || chosen.isEmpty || noWho ? null : () => _importCal(s, chosen),
      );
    }

    return Screen(
      footer: cta == null ? null : [cta],
      children: [
        const Header(title: 'Імпорт'),
        const H1('Перенести', accent: 'старі записи'),
        const Txt('З таблиці, яку вела сама, або з календаря.', muted: true),
        Seg<bool>(options: const [SegOpt(false, 'Таблиця'), SegOpt(true, 'Календар')], value: cal, onChange: (v) => setState(() => cal = v)),
        ...(cal ? _calendarTab(s) : _tableTab(s)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step(this.n, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle),
            child: Text('$n', style: T.body(11, C.bg, FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text(text, style: T.body(12, C.muted, FontWeight.w600)),
        ]),
      );
}

class _SumTile extends StatelessWidget {
  final String big, sub;
  const _SumTile(this.big, this.sub);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big, style: T.serif(26)),
            Text(sub, style: T.body(11, C.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

class _Source extends StatelessWidget {
  final bool on;
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const _Source({required this.on, required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: VCard(
          color: on ? C.accentBg : const Color(0x06F1EEF2),
          border: on ? C.accent : C.line,
          padding: const EdgeInsets.all(14),
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: C.accent.withValues(alpha: .12)),
              child: Icon(icon, size: 16, color: C.accent),
            ),
            const SizedBox(height: 8),
            Text(title, style: T.body(14, C.text, FontWeight.w600)),
            Txt(sub, small: true, muted: true),
          ]),
        ),
      );
}

class _EventPick extends StatelessWidget {
  final EventChoice c;
  final String? who;
  final VoidCallback? onToggle;
  final VoidCallback onWho;
  const _EventPick({required this.c, required this.who, required this.onToggle, required this.onWho});
  @override
  Widget build(BuildContext context) {
    final e = c.event;
    final when = '${cap(human(e.date))}${e.allDay ? '' : ' · ${e.time}'}${c.past ? ' · було' : ''}${c.already ? ' · вже додано' : ''}';
    return Semantics(
      checked: c.on,
      child: VCard(
        onTap: onToggle,
        color: c.on ? C.accentBg : C.card,
        border: c.on ? const Color(0x99F08A6C) : C.line,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: c.on ? C.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: c.on ? C.accent : const Color(0x4DF1EEF2), width: 1.5),
            ),
            child: c.on ? const Icon(Icons.check_rounded, size: 15, color: C.bg) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title.isEmpty ? 'Без назви' : e.title, style: T.body(14, c.already ? C.muted : C.text, FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              Txt(when, small: true, muted: true),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: c.already ? null : onWho,
            child: Container(
              constraints: const BoxConstraints(minHeight: 32, maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: who != null ? C.accent.withValues(alpha: .14) : null,
                borderRadius: BorderRadius.circular(999),
                border: who == null ? Border.all(color: const Color(0x33F1EEF2)) : null,
              ),
              child: Text(who ?? 'Хто це?', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(12, who != null ? C.accentSoft : C.muted, FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x06F1EEF2), borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: C.accent),
          const SizedBox(width: 10),
          Expanded(child: Txt(text, small: true, muted: true)),
        ]),
      );
}
