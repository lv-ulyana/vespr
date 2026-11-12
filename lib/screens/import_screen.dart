import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/import_csv.dart';
import '../logic/import_ics.dart';
import '../services/files.dart';
import '../services/phone_calendar.dart';
import '../ui/board.dart';
import '../ui/d.dart';

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
        if (mounted) dToast(context, 'Це файл Excel. Збережи його як CSV: Файл → Зберегти як → CSV. У Google Таблицях: Файл → Завантажити → CSV.');
        return;
      }
      final t = parseCsv(decodeTextFile(f.bytes));
      if (t.header.isEmpty) {
        if (mounted) dToast(context, 'Файл порожній або це не таблиця');
        return;
      }
      setState(() {
        fileName = f.name;
        table = t;
        mapping = autoMap(t.header);
      });
    } catch (e) {
      if (mounted) dToast(context, 'Не вдалося прочитати файл: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickField(int col) async {
    final current = mapping[col];
    final options = <String?>[...pickableFields, if (current != null && !pickableFields.contains(current)) current, null];
    final picked = await showSheet<String>(
      context,
      (ctx) => Sheet(children: [
        sheetTitle('Що в стовпці?'),
        sheetText('«${table!.header[col]}»'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              for (final f in options) XOpt(title: fieldLabel(f), on: f == current, onTap: () => Navigator.pop(ctx, f ?? '-')),
            ], 8)),
          ),
        ),
        sheetCancel(ctx),
      ]),
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
    dToast(context, 'Додали ${plan.entries.length} ${plural(plan.entries.length, 'запис', 'записи', 'записів')}');
    Navigator.of(context).maybePop();
  }

  List<Widget> _tableTab(AppStore s) {
    final t = table;
    final missing = t == null ? <String>[] : missingRequired(mapping);
    final plan = t == null || missing.isNotEmpty ? null : planCsvImport(t, mapping, s.db, newId: uid);
    return [
      const _Step(1, 'Файл'),
      Grp([
        GRow(
          title: t == null ? 'Обрати файл .csv' : (fileName ?? 'таблиця.csv'),
          sub: t == null ? 'З Excel, Google Таблиць, Numbers або експорту Vespr' : '${t.rows.length} ${plural(t.rows.length, 'рядок', 'рядки', 'рядків')} · роздільник ${sepLabel(t.sep)}',
          onTap: busy ? null : _pickCsv,
          trailing: DChip(t == null ? 'Обрати' : 'Інший', height: 32, onTap: busy ? null : _pickCsv),
          lead: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: K.green.withValues(alpha: .16), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Ico(BS.table, size: 17, color: K.green),
          ),
        ),
      ]),
      if (t == null)
        NoteBox('Excel: Файл → Зберегти як → CSV. Google Таблиці: Файл → Завантажити → CSV. Потрібні хоча б три стовпці: дата, людина, оцінка 1–5.'),
      if (t != null) ...[
        const _Step(2, 'Стовпці'),
        Grp(inset: 0, [
          for (var i = 0; i < t.header.length; i++)
            InkWell(
              onTap: () => _pickField(i),
              highlightColor: K.w(.03),
              splashColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 14, child: Text(mapping[i] != null ? '✓' : '—', style: rw(14, color: mapping[i] != null ? K.green : K.accSoft))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.header[i].isEmpty ? 'Стовпець ${i + 1}' : t.header[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(14, color: mapping[i] != null ? K.star : K.muted))),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      constraints: const BoxConstraints(maxWidth: 170),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: K.w(.05), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.1))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(fieldLabel(mapping[i]), overflow: TextOverflow.ellipsis, style: rw(12, color: mapping[i] != null ? K.soft2 : K.muted))),
                        const SizedBox(width: 6),
                        Ico(BS.caret, size: 10, color: K.soft2),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            missing.isNotEmpty ? 'Обери стовпець для: ${missing.map(fieldLabel).join(', ')}' : "Обов'язкові тільки дата, людина і оцінка 1–5. Таблицю з експорту Vespr впізнаємо повністю: питання, прапорці, теги.",
            style: rw(12, color: missing.isNotEmpty ? K.accSoft : K.haze, h: 1.5),
          ),
        ),
      ],
      if (plan != null) ...[
        const _Step(3, 'Що буде'),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _SumTile('${plan.entries.length}', plural(plan.entries.length, 'запис додамо', 'записи додамо', 'записів додамо')),
            const SizedBox(width: 8),
            _SumTile('${plan.newPeople.length}', plan.newPeople.isEmpty ? 'нових людей' : '${plural(plan.newPeople.length, 'нова людина', 'нові людини', 'нових людей')}: ${plan.newPeople.map((p) => p.name).take(3).join(', ')}${plan.newPeople.length > 3 ? '…' : ''}'),
            const SizedBox(width: 8),
            _SumTile('${plan.duplicates}', 'пропустимо: такий запис уже є'),
          ]),
        ),
        NoteBox([
          if (plan.skipped.isNotEmpty)
            '${plan.skipped.take(3).map((r) => 'Рядок ${r.line}: ${r.reason}').join('; ')}${plan.skipped.length > 3 ? '…' : ''} — пропустимо.',
          'Ліміт безкоштовної версії на імпорт не діє.',
        ].join(' ')),
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
    final picked = await showSheet<String>(
      context,
      (ctx) => Sheet(children: [
        sheetTitle('Хто це?'),
        sheetText('«${c.event.title.isEmpty ? 'Без назви' : c.event.title}»'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              for (final p in people) XOpt(title: p.name, sub: p.isPast ? 'минулі' : null, on: p.id == c.personId, onTap: () => Navigator.pop(ctx, p.id)),
              for (final e in newPeople.entries) XOpt(title: e.value, sub: 'нова', on: e.key == c.personId, onTap: () => Navigator.pop(ctx, e.key)),
              XOpt(title: 'Нова людина…', color: K.accSoft, radio: false, onTap: () => Navigator.pop(ctx, '+')),
            ], 8)),
          ),
        ),
        sheetCancel(ctx),
      ]),
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
    return showSheet<String>(
      context,
      (ctx) => Sheet(children: [
        sheetTitle('Як його звати?'),
        DInput(controller: ctl, label: "Ім'я", hint: "Ім'я або прізвисько", style: rw(16), caps: TextCapitalization.words, onSubmitted: (v) => Navigator.pop(ctx, v.trim())),
        Padding(padding: const EdgeInsets.only(top: 4), child: Cta('Додати', onTap: () => Navigator.pop(ctx, ctl.text.trim()))),
        sheetCancel(ctx),
      ]),
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
    dToast(context, 'Додали ${ms.length} ${plural(ms.length, 'зустріч', 'зустрічі', 'зустрічей')}${past > 0 ? '. Минулі чекають оцінки на головній' : ''}');
    Navigator.of(context).maybePop();
  }

  List<Widget> _calendarTab(AppStore s) {
    final list = choices;
    final visible = list == null ? <EventChoice>[] : list.where((c) => !onlyKnown || c.personId != null || c.on).toList();
    return [
      if (kIsWeb)
        NoteBox('У веб-версії календар телефону недоступний. Експортуй календар у файл .ics (Google Календар: Налаштування → Імпорт і експорт) і обери його тут.'),
      if (!kIsWeb)
        optPair(
          OptCard(on: src == _Src.phone, svg: BS.phone, title: 'Календар телефону', sub: 'Google або Apple, без файлів', onTap: () => setState(() {
                src = _Src.phone;
                choices = null;
              })),
          OptCard(on: src == _Src.file, svg: BS.file, title: 'Файл .ics', sub: 'Експорт з Outlook чи іншого календаря', onTap: () => setState(() {
                src = _Src.file;
                choices = fileEvents.isEmpty ? null : buildChoices(_inSpan(fileEvents), s.db);
              })),
        ),
      chipsWrap([for (final r in _Range.values) DChip(_rangeLabels[r]!, on: range == r, onTap: () => _changeRange(r, s))]),
      if (list == null)
        GhostBtn(
          busy ? 'Зачекай…' : (src == _Src.phone ? 'Показати події' : 'Обрати файл .ics'),
          svg: src == _Src.phone ? BS.cal : BS.file,
          onTap: busy ? null : () => src == _Src.phone ? _loadPhone(s) : _pickIcs(s),
        ),
      if (calError != null) Text(calError!, style: rw(12, color: K.accSoft, h: 1.5)),
      if (src == _Src.file && icsName != null && list != null) Text('$icsName · ${fileEvents.length} подій у файлі', style: rw(12, color: K.haze)),
      if (list != null && list.isEmpty) Text('За цей період подій нема.', style: rw(14, color: K.muted)),
      if (list != null && list.isNotEmpty && list.any((c) => c.personId == null))
        chipsWrap([
          DChip('Де впізнали людину', on: onlyKnown, onTap: () => setState(() => onlyKnown = true)),
          DChip('Усі події · ${list.length}', on: !onlyKnown, onTap: () => setState(() => onlyKnown = false)),
        ]),
      if (visible.isNotEmpty)
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
          for (final c in visible.take(80))
            _EventPick(
              c: c,
              who: c.personId == null ? null : (newPeople[c.personId] ?? s.personName(c.personId!)),
              onToggle: c.already ? null : () => setState(() => c.on = !c.on),
              onWho: () => _pickPerson(c, s),
            ),
        ], 8)),
      if (visible.length > 80) Text('Показали перші 80. Звузь період, щоб побачити решту.', style: rw(12, color: K.haze)),
      if (list != null && list.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Людину вгадуємо за назвою події. «Хто це?» — тапни й обери або додай нову. Майбутні стануть запланованими зустрічами, минулі — зустрічами, які лишилось оцінити.', style: rw(12, color: K.haze, h: 1.5)),
        ),
      NoteBox('Читаємо тільки події, які ти обереш. У самому календарі нічого не змінюємо.', svg: BS.lock),
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
        cta = Cta(busy ? 'Зачекай…' : 'Імпортувати $n ${plural(n, 'запис', 'записи', 'записів')}', onTap: busy || plan == null || n == 0 ? null : () => _importCsv(s, plan));
      }
    } else if (choices != null) {
      final chosen = choices!.where((c) => c.on && !c.already).toList();
      final noWho = chosen.any((c) => c.personId == null);
      cta = Cta(
        busy ? 'Зачекай…' : (noWho ? 'Обери, хто це, у позначених' : 'Додати ${chosen.length} ${plural(chosen.length, 'зустріч', 'зустрічі', 'зустрічей')}'),
        onTap: busy || chosen.isEmpty || noWho ? null : () => _importCal(s, chosen),
      );
    }

    return DScroll(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
      bottom: cta,
      children: [
        const BoardHeader('Імпорт'),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          titleAcc(const [('Перенести\n', false), ('старі записи', true)], 34),
          const SizedBox(height: 8),
          Text('З таблиці, яку вела сама, або з календаря.', style: rw(14, color: K.muted, h: 1.5)),
        ]),
        Tabs(items: const [('Таблиця', null), ('Календар', null)], index: cal ? 1 : 0, onChanged: (i) => setState(() => cal = i == 1)),
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
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: K.acc, shape: BoxShape.circle),
          child: Text('$n', style: rw(11, color: K.bg, w: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        Text(text, style: rw(12, color: K.muted, w: FontWeight.w600)),
      ]);
}

class _SumTile extends StatelessWidget {
  final String big, sub;
  const _SumTile(this.big, this.sub);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big, style: pr(26, h: 1.2)),
            Text(sub, style: rw(11, color: K.muted, h: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
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
    final on = c.on;
    return Semantics(
      checked: on,
      child: Press(
        onTap: onToggle,
        scale: .98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: easeD,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: on ? onBase(RadialGradient(center: Alignment.topLeft, radius: 1.4, colors: [K.a(.12), K.a(0)], stops: const [0, .6]), K.card2) : onBase(null, K.card2),
            border: Border.all(color: on ? K.a(.6) : K.w(.06)),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: on ? K.acc : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: on ? K.acc : K.w(.3), width: 1.5),
              ),
              alignment: Alignment.center,
              child: on ? Ico(Svgs.tick, size: 13, color: K.bg) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title.isEmpty ? 'Без назви' : e.title, style: rw(14, color: c.already ? K.muted : K.star, w: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(when, style: rw(12, color: K.muted)),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: c.already ? null : onWho,
              child: Container(
                height: 30,
                constraints: const BoxConstraints(maxWidth: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: who != null ? K.a(.14) : null,
                  borderRadius: BorderRadius.circular(999),
                  border: who == null ? Border.all(color: K.w(.2)) : null,
                ),
                child: Text(who ?? 'Хто це?', maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(12, color: who != null ? K.accSoft : K.soft2, w: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
