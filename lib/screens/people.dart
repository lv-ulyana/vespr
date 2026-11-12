import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../logic/texts.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'entry.dart';
import 'onboarding.dart';
import 'settings.dart';
import 'table_screen.dart';

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    if (s.people.isEmpty) {
      return Screen(
        footer: [Btn('Додати людину', onTap: () => go(context, const PersonEdit()))],
        children: const [
          H1('Поки', accent: 'нікого'),
          Txt('Побачення, стосунки чи одна ніч: додай першу людину. Після кількох записів зможеш порівнювати.', muted: true),
          Txt('Бачиш тільки ти, все лишається на телефоні.', small: true, muted: true),
        ],
      );
    }
    final now = s.people.where((p) => !p.isPast).toList();
    final past = s.people.where((p) => p.isPast).toList();
    final shame = hallOfShame(s.people, s.entries).where((x) => x.red > 0).toList();
    return Screen(children: [
      Row(children: [
        const Expanded(child: H1('Люди')),
        RoundIcon(icon: Icons.table_chart_outlined, label: 'Усі записи таблицею', onTap: () => go(context, const TableScreen())),
        const SizedBox(width: 8),
        RoundIcon(icon: Icons.add, label: 'Додати людину', accent: true, onTap: () => go(context, const PersonEdit())),
      ]),
      if (shame.isNotEmpty)
        VCard(
          color: const Color(0xFF3A2530),
          border: const Color(0x4DF2827A),
          onTap: () => go(context, const ShameScreen()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Зала ганьби', style: T.body(12, C.red, FontWeight.w600)),
            Text('Лідер: ${shame.first.person.name}', style: T.serif(20)),
            Txt('${shame.first.red} ${plural(shame.first.red, 'прапорець', 'прапорці', 'прапорців')} за ${shame.first.meets} ${plural(shame.first.meets, 'зустріч', 'зустрічі', 'зустрічей')} ›', small: true, muted: true),
          ]),
        ),
      for (final p in now) _PersonRow(p),
      if (past.isNotEmpty) const Label('Минулі'),
      for (final p in past) _PersonRow(p),
    ]);
  }
}

class _PersonRow extends StatelessWidget {
  final Person p;
  const _PersonRow(this.p);
  @override
  Widget build(BuildContext context) {
    final st = personStats(Store.of(context).entries, p.id);
    return VCard(
      padding: const EdgeInsets.all(12),
      onTap: () => go(context, PersonView(personId: p.id)),
      child: Row(children: [
        Avatar(p.name, past: p.isPast),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: T.body(15, C.text, FontWeight.w600)),
            Txt('${st.n} ${plural(st.n, 'зустріч', 'зустрічі', 'зустрічей')} · ${p.isPast ? pastReasonLabel(p.pastReason) : relLabel(p.rel)}', small: true, muted: true),
          ]),
        ),
        Text(st.n > 0 ? fmt(st.overall) : '—', style: T.serif(22, st.n > 0 ? C.accentSoft : C.dim)),
      ]),
    );
  }
}

class PersonEdit extends StatefulWidget {
  final String? personId;
  final bool onboarding;
  const PersonEdit({super.key, this.personId, this.onboarding = false});
  @override
  State<PersonEdit> createState() => _PersonEditState();
}

class _PersonEditState extends State<PersonEdit> {
  late final TextEditingController name, date, notes;
  String rel = 'date';
  bool noDate = false;
  int? signOnly, size, met, want;

  @override
  void initState() {
    super.initState();
    final p = widget.personId == null ? null : Store.read(context).person(widget.personId!);
    name = TextEditingController(text: p?.name ?? '');
    date = TextEditingController(text: toUA(p?.birth));
    notes = TextEditingController(text: p?.notes ?? '');
    if (p != null) {
      rel = p.rel;
      noDate = p.birth == null;
      signOnly = p.signOnly;
      size = p.size;
      met = p.met;
      want = p.want;
    }
  }

  @override
  void dispose() {
    name.dispose();
    date.dispose();
    notes.dispose();
    super.dispose();
  }

  Widget _pick(List<String> opts, int? v, ValueChanged<int?> on) =>
      Chips([for (var i = 0; i < opts.length; i++) ChipX(opts[i], on: v == i, onTap: () => setState(() => on(v == i ? null : i)))]);

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final prev = widget.personId == null ? null : s.person(widget.personId!);
    final iso = noDate ? null : parseUA(date.text);
    final a = astroOf(iso, noDate ? signOnly : null);
    final active = s.people.where((p) => !p.isPast).length;
    final limited = prev == null && !s.profile.premium && active >= freePeople;

    Future<void> finish() async {
      if (widget.onboarding) {
        await finishOnboarding(context);
      } else if (context.mounted) {
        Navigator.pop(context);
      }
    }

    if (limited) {
      return Screen(
        footer: [Btn('Відкрити Premium', onTap: () => goReplace(context, const PaywallScreen())), Btn('Назад', kind: BtnKind.ghost, onTap: () => Navigator.pop(context))],
        children: const [
          Header(),
          H1('У безкоштовній версії', accent: 'до $freePeople людей'),
          Txt('Перенеси когось у минулі або відкрий Premium, щоб додавати без ліміту.', muted: true),
        ],
      );
    }

    final canSave = name.text.trim().isNotEmpty && (noDate || date.text.isEmpty || iso != null);
    return Screen(
      footer: [
        Btn(prev == null ? 'Додати' : 'Зберегти', onTap: !canSave ? null : () async {
          if (prev == null) {
            await s.addPerson(Person(
              id: uid(), name: name.text.trim(), rel: rel, birth: iso, signOnly: noDate ? signOnly : null,
              size: size, met: met, want: want, notes: notes.text.trim(), createdAt: DateTime.now().toIso8601String(),
            ));
          } else {
            await s.updatePerson(prev.id, (p) {
              p.name = name.text.trim();
              p.rel = rel;
              p.birth = iso;
              p.signOnly = noDate ? signOnly : null;
              p.size = size;
              p.met = met;
              p.want = want;
              p.notes = notes.text.trim();
            });
          }
          await finish();
        }),
      ],
      children: [
        Header(
          title: prev == null ? null : 'Картка людини',
          right: widget.onboarding ? TextButton(onPressed: finish, child: Text('Пізніше', style: T.body(13, C.muted, FontWeight.w500))) : null,
        ),
        H1(prev != null ? 'Редагувати' : (widget.onboarding ? 'Додай' : 'Нова людина'), accent: prev == null && widget.onboarding ? 'першу людину' : null),
        Field(label: 'Як його назвеш', hint: "Ім'я або прізвисько: «Архітектор»", controller: name, onChanged: (_) => setState(() {})),
        const Label('Хто він для тебе · можна змінити потім'),
        Chips([for (final r in rels) ChipX(r.label, on: rel == r.id, onTap: () => setState(() => rel = r.id))]),
        const Label('День народження'),
        if (!noDate) Field(hint: 'ДД.ММ.РРРР', controller: date, keyboard: TextInputType.number, formatters: [dateFormatter], onChanged: (_) => setState(() {})),
        Chips([ChipX('Не знаю дати', on: noDate, onTap: () => setState(() => noDate = !noDate))]),
        if (noDate) ...[
          const Txt('Знаєш тільки знак? Без дати аркан не порахуємо.', small: true, muted: true),
          Chips([for (var i = 0; i < signs.length; i++) ChipX(signs[i].name, on: signOnly == i, onTap: () => setState(() => signOnly = signOnly == i ? null : i))]),
        ],
        if (a != null)
          VCard(
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Txt('Знак', small: true, muted: true), Text(a.signName, style: T.serif(22))]),
              const SizedBox(width: 24),
              if (a.arc != null)
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Txt('Аркан ${a.romanNum}', small: true, muted: true), Text(a.arcanaName!, style: T.serif(22))])),
            ]),
          ),
        const Label('Розмір · вказується один раз, можна пізніше'),
        _pick(sizes, size, (v) => size = v),
        const Label('Де познайомились'),
        _pick(metOptions, met, (v) => met = v),
        const Label('Що хочеш з ним'),
        _pick(wantOptions, want, (v) => want = v),
        Field(label: 'Нотатки про нього', hint: "Познайомились на виставці. Не їсть м'ясо.", controller: notes, maxLines: 4),
      ],
    );
  }
}

class PersonView extends StatefulWidget {
  final String personId;
  const PersonView({super.key, required this.personId});
  @override
  State<PersonView> createState() => _PersonViewState();
}

class _PersonViewState extends State<PersonView> {
  String? mode; // past | delete

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.person(widget.personId);
    if (p == null) return const Screen(children: [Header(), Txt('Людину не знайдено.', muted: true)]);
    final st = personStats(s.entries, p.id);
    final es = entriesOf(s.entries, p.id).reversed.toList();
    final a = astroOf(p.birth, p.signOnly);
    final me = astroOf(s.profile.birth);

    final notes = <String>[];
    if (st.gap != null && st.gap! > 0) notes.add(say('bodyYes', {'name': p.name, 'sex': fmt(st.sex), 'him': fmt(st.him)}));
    if (st.gap != null && st.gap! < 0) notes.add(say('headYes', {'name': p.name, 'sex': fmt(st.sex)}));
    if (st.trend == 'up') notes.add(say('trendUp', {'name': p.name, 'v': fmt(st.overall)}));
    if (st.trend == 'down') notes.add(say('trendDown', {'name': p.name}));
    if (st.fake >= 2) notes.add(say('fake', {'name': p.name, 'k': st.fake, 'n': st.sexN}));
    for (final f in st.flagCounts) {
      if (f.kind == FlagKind.g && f.n >= 2) { notes.add(say('greenRepeat', {'flag': f.label, 'n': f.n})); break; }
    }
    for (final f in st.flagCounts) {
      if (f.kind == FlagKind.r && f.n >= 2) { notes.add(say('redRepeat', {'flag': f.label, 'n': f.n})); break; }
    }

    return Screen(children: [
      Header(right: TextButton(onPressed: () => go(context, PersonEdit(personId: p.id)), child: Text('Змінити', style: T.body(14, C.text, FontWeight.w600)))),
      Row(children: [
        Avatar(p.name, size: 64, past: p.isPast),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: T.serif(30)),
            Txt([
              p.isPast ? 'У минулих · ${pastReasonLabel(p.pastReason)}' : relLabel(p.rel),
              if (a != null) a.signName,
              if (p.size != null) sizes[p.size!],
            ].join(' · '), small: true, muted: true),
          ]),
        ),
      ]),
      Row(children: [
        StatTile('Загалом', st.n > 0 ? fmt(st.overall) : '—', suffix: '/5'),
        const SizedBox(width: 10),
        StatTile('Секс', st.sexN > 0 ? fmt(st.sex) : '—', suffix: '/5'),
        const SizedBox(width: 10),
        StatTile('Кінчала', st.orgN > 0 ? '${st.orgMe}/${st.orgN}' : '—'),
      ]),
      if (st.n == 1) const Txt('1 зустріч, рано судити.', small: true, muted: true),
      if (st.flagCounts.isNotEmpty)
        Chips([
          for (final f in st.flagCounts.where((f) => f.kind != FlagKind.c).take(6))
            ChipX('${f.label} ${f.n}', on: true, tone: f.kind == FlagKind.g ? Tone.g : Tone.r),
        ]),
      for (final n in notes) VCard(child: Text(n, style: T.serif(17).copyWith(height: 1.4))),
      if (a?.arc != null && me?.arc != null)
        Builder(builder: (_) {
          final m0 = me!, a0 = a!;
          final pa = pairArcana(m0.arc!, a0.arc!);
          return VCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✦ Ваш метч', style: T.body(12, C.accentSoft, FontWeight.w600)),
              Text('${roman[pa]} ${arcana[pa].name}', style: T.serif(22)),
              Txt('Ти ${m0.romanNum} + він ${a0.romanNum} · зодіак: ${zodiacEase(m0.sign, a0.sign)} (${m0.el} і ${a0.el})', small: true, muted: true),
              Txt(arcana[pa].love, small: true),
              const Txt('Зірки як гра. Записи як правда.', small: true, muted: true),
            ]),
          );
        })
      else if (a == null)
        VCard(onTap: () => go(context, PersonEdit(personId: p.id)), child: const Txt('Дізналась його день народження? Порахуємо знак, аркан і ваш метч ›')),
      if (p.notes.isNotEmpty) ...[const Label('Нотатки'), Txt(p.notes)],
      Btn('Новий запис', onTap: () => go(context, EntryForm(personId: p.id))),
      if (es.isNotEmpty) Label('Зустрічі · ${es.length}'),
      for (final e in es)
        VCard(
          padding: const EdgeInsets.all(12),
          onTap: () => go(context, EntryView(entryId: e.id)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(human(e.date), style: T.body(14, C.text, FontWeight.w600)),
                Txt('${e.hadSex ? 'Був секс' : 'Тільки побачення'}${e.note.isNotEmpty ? ' · ${e.note}' : ''}', small: true, muted: true, lines: 1),
              ]),
            ),
            Text('${e.overall}', style: T.serif(22, C.accentSoft)),
          ]),
        ),
      const Label('Дії'),
      if (!p.isPast)
        mode == 'past'
            ? VCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${p.name} у минулі', style: T.body(15, C.text, FontWeight.w600)),
                  const Txt('Записи лишаться в мапі і порівняннях. Повернути можна будь-коли. Що сталось?', small: true, muted: true),
                  const SizedBox(height: 8),
                  Chips([
                    for (final r in pastReasons)
                      ChipX(r.label, on: false, onTap: () { s.updatePerson(p.id, (x) { x.status = 'past'; x.pastReason = r.id; x.pastAt = today(); }); setState(() => mode = null); }),
                    ChipX('Пропустити', on: false, onTap: () { s.updatePerson(p.id, (x) { x.status = 'past'; x.pastReason = null; x.pastAt = today(); }); setState(() => mode = null); }),
                  ]),
                ]),
              )
            : Btn('Перенести в минулі', kind: BtnKind.ghost, onTap: () => setState(() => mode = 'past'))
      else
        Btn('Повернути з минулих', kind: BtnKind.ghost, onTap: () => s.updatePerson(p.id, (x) { x.status = 'now'; x.pastReason = null; x.pastAt = null; })),
      mode == 'delete'
          ? VCard(
              border: C.danger,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Видалити ${p.name} і ${st.n} ${plural(st.n, 'запис', 'записи', 'записів')}?', style: T.body(15, C.text, FontWeight.w600)),
                const Txt('Оцінки зникнуть з мапи і порівнянь. Відновити не можна.', small: true, muted: true),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Btn('Видалити', kind: BtnKind.danger, onTap: () async { await s.deletePerson(p.id); if (context.mounted) Navigator.pop(context); })),
                  const SizedBox(width: 8),
                  Expanded(child: Btn('Скасувати', kind: BtnKind.ghost, onTap: () => setState(() => mode = null))),
                ]),
              ]),
            )
          : Btn('Видалити людину і записи', kind: BtnKind.ghost, onTap: () => setState(() => mode = 'delete')),
    ]);
  }
}

class ShameScreen extends StatelessWidget {
  const ShameScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final list = hallOfShame(s.people, s.entries).where((x) => x.red > 0).toList();
    return Screen(children: [
      const Header(),
      const H1('Зала', accent: 'ганьби'),
      const Txt('Рейтинг на зустріч: сума ваг червоних прапорців поділена на кількість зустрічей. Критичні сюди не потрапляють.', muted: true),
      for (var i = 0; i < list.length; i++)
        Builder(builder: (_) {
          final x = list[i];
          final fl = <String, int>{};
          for (final e in entriesOf(s.entries, x.person.id)) {
            for (final f in e.flags.where((x) => flagById(x)?.kind == FlagKind.r)) {
              fl[f] = (fl[f] ?? 0) + 1;
            }
          }
          final top = fl.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return VCard(
            onTap: () => go(context, PersonView(personId: x.person.id)),
            child: Row(children: [
              SizedBox(width: 24, child: Text('${i + 1}', style: T.serif(22, i == 0 ? C.red : C.muted))),
              Avatar(x.person.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(x.person.name, style: T.body(15, C.text, FontWeight.w600)),
                  Txt(top.take(2).map((t) => '${flagById(t.key)?.label} ×${t.value}').join(' · '), small: true, muted: true),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt(x.rate), style: T.serif(20, C.red)),
                Txt('з ${x.meets} ${plural(x.meets, 'зустрічі', 'зустрічей', 'зустрічей')}', small: true, muted: true),
              ]),
            ]),
          );
        }),
    ]);
  }
}
