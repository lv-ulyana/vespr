import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../logic/texts.dart';
import '../logic/triggers.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'people.dart';
import 'settings.dart';

Tone toneOf(FlagKind k) => k == FlagKind.g ? Tone.g : Tone.r;

/// Запис після зустрічі. Обов'язкове лише «Як пройшло?» і «Був секс?».
/// Не позначене означає «не позначила», а не «не було», і в розрахунки не йде.
class EntryForm extends StatefulWidget {
  final String? entryId;
  final String? personId;
  final String? date;
  const EntryForm({super.key, this.entryId, this.personId, this.date});
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  Entry? prev;
  String personId = '';
  late String date;
  int overall = 0;
  bool? hadSex;
  Map<String, int> ratings = {};
  List<String> tags = [];
  List<String> flagIds = [];
  Map<String, int> factVals = {};
  final note = TextEditingController();
  bool more = false;

  @override
  void initState() {
    super.initState();
    final s = Store.read(context);
    prev = widget.entryId == null ? null : s.entry(widget.entryId!);
    final active = s.people.where((p) => !p.isPast).toList();
    final e = prev;
    if (e != null) {
      personId = e.personId;
      date = e.date;
      overall = e.overall;
      hadSex = e.hadSex;
      ratings = Map.of(e.ratings);
      tags = List.of(e.tags);
      flagIds = List.of(e.flags);
      factVals = Map.of(e.facts);
      note.text = e.note;
    } else {
      personId = widget.personId ?? (active.length == 1 ? active.first.id : '');
      date = widget.date ?? today();
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _toggleAxis(TagAxis ax, String opt) => setState(() {
        if (tags.contains(opt)) {
          tags.remove(opt);
        } else {
          final ids = ax.all.map((o) => o.id).toSet();
          tags.removeWhere(ids.contains);
          tags.add(opt);
        }
      });

  void _toggle(List<String> list, String id) => setState(() {
        if (list.contains(id)) {
          list.remove(id);
        } else {
          list.add(id);
        }
      });

  void _rate(String id, int v) => setState(() {
        if (v == 0) {
          ratings.remove(id);
        } else {
          ratings[id] = v;
        }
      });

  Future<void> _save(AppStore s) async {
    final sex = hadSex == true;
    final sexTagIds = tagIndex.entries.where((x) => x.value.sexOnly).map((x) => x.key).toSet();
    final cleanTags = sex ? tags : tags.where((t) => !sexTagIds.contains(t)).toList();
    final cleanRatings = Map<String, int>.fromEntries(ratings.entries.where((r) => sex || !r.key.startsWith('sx_')));
    if (sex) cleanRatings['sx_overall'] = overall;
    final cleanFacts = Map<String, int>.fromEntries(factVals.entries.where((f) => sex || f.key != 'f_stam'));
    final e = Entry(
      id: prev?.id ?? uid(),
      personId: personId,
      date: date,
      overall: overall,
      hadSex: sex,
      ratings: cleanRatings,
      tags: cleanTags,
      flags: flagIds,
      facts: cleanFacts,
      note: note.text.trim(),
      createdAt: prev?.createdAt ?? DateTime.now().toIso8601String(),
    );
    await s.saveEntry(e);
    if (mounted) goReplace(context, EntryView(entryId: e.id));
  }

  Widget _q(Question q) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(q.text, style: T.body(14, C.text, FontWeight.w500)),
          const SizedBox(height: 8),
          Rating(value: ratings[q.id] ?? 0, onChange: (v) => _rate(q.id, v), size: 38),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    final monthCount = entriesInMonth(s.entries, monthKey(date), exceptId: prev?.id);
    if (prev == null && !p.premium && monthCount >= freeEntriesPerMonth) {
      return Screen(
        footer: [
          Btn('Записувати без ліміту', onTap: () => goReplace(context, const PaywallScreen())),
          Btn('Почекаю до наступного місяця', kind: BtnKind.ghost, onTap: () => Navigator.pop(context)),
        ],
        children: const [
          Header(),
          H1('Цього місяця ти записала', accent: '$freeEntriesPerMonth зустрічей'),
          Txt('Нові записи відкриються 1-го числа. Або вже зараз з Premium.', muted: true),
        ],
      );
    }
    final people = prev != null ? s.people : s.people.where((x) => !x.isPast).toList();
    final suggestions = suggestFlags(note.text).where((f) => !flagIds.contains(f)).toList();
    final sex = hadSex == true;
    final sexQs = sexQuestions.where((q) => q.id != 'sx_overall' && (q.always || p.sexQs.contains(q.id))).toList();
    final ptQs = partnerQuestions.where((q) => p.ptQs.contains(q.id)).toList();
    final groups = <String>[...{...axes.map((a) => a.group), ...solos.map((x) => x.group)}];
    final canSave = personId.isNotEmpty && overall > 0 && hadSex != null;
    final person = s.person(personId);

    return Screen(
      footer: [Btn(prev == null ? 'Зберегти запис' : 'Зберегти', onTap: canSave ? () => _save(s) : null)],
      children: [
        Header(title: prev == null ? 'Новий запис' : 'Редагувати запис'),
        const Label('З ким'),
        Chips([
          for (final x in people) ChipX(x.name, on: personId == x.id, onTap: () => setState(() => personId = x.id)),
          if (prev == null) ChipX('+ Нова', on: false, onTap: () => go(context, const PersonEdit())),
        ]),
        const Label('Коли'),
        Row(children: [
          IconButton(onPressed: () => setState(() => date = addDays(date, -1)), icon: const Icon(Icons.chevron_left_rounded, color: C.text), tooltip: 'Попередній день'),
          Expanded(child: Text(date == today() ? 'Сьогодні' : human(date), textAlign: TextAlign.center, style: T.body(15, C.text, FontWeight.w600))),
          IconButton(
            onPressed: date.compareTo(today()) >= 0 ? null : () => setState(() => date = addDays(date, 1)),
            icon: Icon(Icons.chevron_right_rounded, color: date.compareTo(today()) >= 0 ? C.dim : C.text),
            tooltip: 'Наступний день',
          ),
        ]),
        VCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(children: [
            if (person != null) Row(mainAxisAlignment: MainAxisAlignment.center, children: [Avatar(person.name, size: 28), const SizedBox(width: 8), Txt(person.name, muted: true)]),
            const SizedBox(height: 8),
            Text('Як пройшло?', style: T.serif(24)),
            const SizedBox(height: 12),
            FittedBox(fit: BoxFit.scaleDown, child: Rating(value: overall, onChange: (v) => setState(() => overall = v), size: 48)),
            const SizedBox(height: 8),
            Txt(overall > 0 ? rateWord(overall) : "обов'язкове питання", small: true, muted: true),
          ]),
        ),
        const Label('Був секс?'),
        Seg<bool>(options: const [SegOpt(true, 'Так'), SegOpt(false, 'Ні, тільки побачення')], value: hadSex, onChange: (v) => setState(() => hadSex = v)),
        if (hadSex == false) const Txt('Питання про секс пропускаємо. Оцінка вище — про вечір загалом.', small: true, muted: true),
        if (sex) ...[const Label('Секс'), for (final q in sexQs) _q(q)],
        if (hadSex != null) ...[
          const Label('Він'),
          for (final q in ptQs) _q(q),
          const Label('Прапорці'),
          const Txt('Що він робив. Позначай, якщо було.', small: true, muted: true),
          Chips([for (final f in flags.where((f) => f.kind == FlagKind.g)) ChipX(f.label, tone: Tone.g, on: flagIds.contains(f.id), onTap: () => _toggle(flagIds, f.id))]),
          Chips([for (final f in flags.where((f) => f.kind == FlagKind.r)) ChipX(f.label, tone: Tone.r, on: flagIds.contains(f.id), onTap: () => _toggle(flagIds, f.id))]),
          Chips([for (final f in flags.where((f) => f.kind == FlagKind.c)) ChipX('‼ ${f.label}', tone: Tone.r, on: flagIds.contains(f.id), onTap: () => _toggle(flagIds, f.id))]),
          Field(label: "Нотатка для себе · необов'язково", hint: 'Говори як подрузі: що було, що сподобалось, що ні', controller: note, maxLines: 4, onChanged: (_) => setState(() {})),
          if (suggestions.isNotEmpty)
            VCard(
              border: C.accent,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Txt('Знайшли прапорці в нотатці. Додати?', small: true, color: C.accentSoft),
                const SizedBox(height: 8),
                Chips([for (final id in suggestions) ChipX('+ ${flagById(id)?.label ?? id}', on: false, tone: toneOf(flagById(id)?.kind ?? FlagKind.g), onTap: () => setState(() => flagIds.add(id)))]),
              ]),
            ),
          TextButton(
            onPressed: () => setState(() => more = !more),
            style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
            child: Text(more ? 'Сховати деталі' : 'Ще деталі: де, коли, темп, фінал ›', style: T.body(14, C.accentSoft, FontWeight.w600)),
          ),
          if (more) ...[
            const Txt("Обирай один бік з пари. Не пам'ятаєш — просто пропусти.", small: true, muted: true),
            for (final g in groups)
              if (sex || axes.any((a) => a.group == g && !a.sexOnly) || solos.any((x) => x.group == g && !x.sexOnly))
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Label(g),
                  const SizedBox(height: 8),
                  for (final ax in axes.where((a) => a.group == g && (sex || !a.sexOnly)))
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: Chips([for (final o in ax.all) ChipX(o.label, on: tags.contains(o.id), onTap: () => _toggleAxis(ax, o.id))])),
                  for (final so in solos.where((x) => x.group == g && (sex || !x.sexOnly)))
                    Chips([for (final o in so.tags) ChipX(o.label, on: tags.contains(o.id), onTap: () => _toggle(tags, o.id))]),
                ]),
            for (final f in facts.where((f) => sex || f.id != 'f_stam')) ...[
              Label(f.label),
              Seg<int>(
                options: [for (var i = 0; i < f.steps.length; i++) SegOpt(i, f.steps[i])],
                value: factVals[f.id],
                onChange: (v) => setState(() {
                  if (factVals[f.id] == v) {
                    factVals.remove(f.id);
                  } else {
                    factVals[f.id] = v;
                  }
                }),
              ),
              if (f.hint != null && factVals[f.id] != null) Txt(f.hint![factVals[f.id]!], small: true, muted: true),
            ],
            const Label('Ти сама'),
            for (final q in selfQuestions) _q(q),
          ],
        ],
      ],
    );
  }
}

class EntryView extends StatefulWidget {
  final String entryId;
  const EntryView({super.key, required this.entryId});
  @override
  State<EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView> {
  bool confirm = false;

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final e = s.entry(widget.entryId);
    if (e == null) return const Screen(children: [Header(), Txt('Запис не знайдено.', muted: true)]);
    final name = s.personName(e.personId);
    final all = entriesOf(s.entries, e.personId);
    final isBest = all.length > 1 && all.every((x) => x.overall <= e.overall) && all.where((x) => x.overall == e.overall).length == 1;
    final rated = e.ratings.entries.where((r) => r.key != 'sx_overall').toList();

    Widget block(String prefix, String title) {
      final rows = rated.where((r) => r.key.startsWith(prefix)).toList();
      if (rows.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Label(title),
        const SizedBox(height: 6),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [Expanded(child: Txt(qById(r.key)?.text ?? r.key)), Text('${r.value}', style: T.serif(18))]),
          ),
      ]);
    }

    return Screen(children: [
      Header(right: TextButton(onPressed: () => go(context, EntryForm(entryId: e.id)), child: Text('Редагувати', style: T.body(14, C.text, FontWeight.w600)))),
      Row(children: [
        Avatar(name, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: T.serif(24)),
            Txt('${human(e.date)} · ${e.hadSex ? 'був секс' : 'тільки побачення'}', small: true, muted: true),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${e.overall}', style: T.serif(40, C.accentSoft)), Txt(rateWord(e.overall), small: true, muted: true)]),
      ]),
      if (isBest) const Txt('✦ Найкраща зустріч з ним', small: true, color: C.accentSoft),
      if (isUnsafe(e))
        VCard(color: const Color(0x14F2827A), border: C.red, child: Text(say('critical'), style: T.serif(17).copyWith(height: 1.4))),
      if (e.note.isNotEmpty) ...[const Label('Нотатка'), Txt(e.note)],
      if (e.flags.isNotEmpty) ...[
        const Label('Прапорці'),
        Chips([for (final f in e.flags) ChipX(flagById(f)?.label ?? f, on: true, tone: toneOf(flagById(f)?.kind ?? FlagKind.r))]),
      ],
      block('sx_', 'Секс'),
      block('pt_', 'Він'),
      block('sf_', 'Ти сама'),
      if (e.tags.isNotEmpty) ...[const Label('Що було'), Chips([for (final t in e.tags) ChipX(tagLabel(t), on: true)])],
      for (final f in facts.where((f) => e.facts[f.id] != null))
        Row(children: [Expanded(child: Txt(f.label, muted: true)), Txt(f.steps[e.facts[f.id]!])]),
      const SizedBox(height: 12),
      confirm
          ? VCard(
              border: C.danger,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Видалити запис?', style: T.body(15, C.text, FontWeight.w600)),
                const Txt('Його оцінки зникнуть з мапи і порівнянь. Wrapped перерахується.', small: true, muted: true),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Btn('Видалити', kind: BtnKind.danger, onTap: () async { await s.deleteEntry(e.id); if (context.mounted) Navigator.pop(context); })),
                  const SizedBox(width: 8),
                  Expanded(child: Btn('Скасувати', kind: BtnKind.ghost, onTap: () => setState(() => confirm = false))),
                ]),
              ]),
            )
          : Btn('Видалити запис', kind: BtnKind.ghost, onTap: () => setState(() => confirm = true)),
    ]);
  }
}
