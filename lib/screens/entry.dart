// Запис зустрічі один в один з дошками «Entry», «EntryView», «EntryActions», «EntryDate», «EntryMove».
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../logic/triggers.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go, goReplace;
import 'onboarding.dart' show AddPersonScreen;
import 'settings.dart' show PaywallKind, PaywallScreen, QuestionsScreen;

/// Тон оцінки (для старих місць, що його питають)
Color toneOf(int v) => v >= 4 ? K.green : v <= 2 ? K.red : K.acc;

const _sliders = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/></svg>';
const _flagIc = '<svg viewBox="0 0 24 24"><path d="M6 21V4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M6 4h12l-2.6 4.2L18 12.4H6z" fill="currentColor"/></svg>';
const _chevDown = '<svg viewBox="0 0 24 24" fill="none" stroke="#A49EB8" stroke-width="2.2"><path d="M6 9l6 6 6-6"/></svg>';
const _dots = '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>';
const _pen = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M4 20h4L19 9l-4-4L4 16z"/></svg>';
const _cal = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>';
const _move = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0M16 8h6M19 5l3 3-3 3"/></svg>';
const _note = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z"/></svg>';

/// Групи тегів у порядку з дошки «Entry» → «Що було»
const _groups = <(String, List<String>, List<String>)>[
  ('Перед', ['ax_talk', 'ax_alco', 'ax_state', 'ax_chat'], []),
  ('Де і коли', ['ax_where', 'ax_start', 'ax_time', 'ax_plan', 'ax_len'], []),
  ('Темп', ['ax_fore', 'ax_speed', 'ax_mood', 'ax_tone', 'ax_count'], []),
  ('Що робили', ['ax_light'], ['kiss', 'oral_me', 'oral_him', 'newpos', 'toys', 'fantasy', 'shower', 'new']),
  ('Фінал', ['ax_o_me', 'ax_o_him', 'ax_real'], []),
  ('Захист і тіло', ['ax_prot', 'ax_body'], ['period']),
  ('Ти', ['ax_said', 'ax_limit', 'ax_init'], ['stop', 'praise']),
  ('Після', ['ax_close', 'ax_night', 'ax_text'], []),
];

TagAxis? _axis(String id) {
  for (final a in axes) {
    if (a.id == id) return a;
  }
  return null;
}

/// Коротка назва вечора з тегів: «Вечеря, потім у нього»
String entryTitle(Entry e) {
  final t = e.tags.toSet();
  final start = t.contains('restaurant')
      ? 'Вечеря'
      : t.contains('bar')
          ? 'Бар'
          : t.contains('neutral')
              ? 'Кава, прогулянка'
              : t.contains('straight_home')
                  ? 'Одразу вдома'
                  : null;
  final where = t.contains('his') ? 'у нього' : t.contains('mine') ? 'у мене' : t.contains('hotel') ? 'готель' : null;
  if (start != null && where != null && start != 'Одразу вдома') return '$start, потім $where';
  if (start != null) return start;
  if (where != null) return cap(where);
  return e.hadSex ? 'Зустріч і секс' : 'Побачення';
}

String _heroFor(Entry e) {
  final t = e.tags.toSet();
  if (t.contains('bar')) return 'assets/img/bar.jpg';
  if (t.contains('neutral')) return 'assets/img/sky.jpg';
  if (t.contains('straight_home')) return 'assets/img/city.jpg';
  return 'assets/img/dinner.jpg';
}

/// Аватарка людини (градієнт як на дошках)
class PAvatar extends StatelessWidget {
  final double size;
  final int seed;
  const PAvatar({super.key, this.size = 22, this.seed = 0});
  @override
  Widget build(BuildContext context) => Blob(seed: seed, w: size, h: size, circle: true, blur: size / 12);
}

/// Яке «фото» в людини: демо-люди мають свої з макета, решта — за id
int seedOf(String id) => const {'p_arch': 0, 'p_mark': 1, 'p_d': 2}[id] ?? id.codeUnits.fold<int>(0, (a, b) => a + b);

// =====================================================================
// Форма запису: «Як пройшло?»
// =====================================================================
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
  bool hadSex = true;
  Map<String, int> ratings = {};
  List<String> tags = [];
  List<String> flagIds = [];
  Map<String, int> factVals = {};
  final note = TextEditingController();
  String tab = 'sex';
  final open = <String>{};

  @override
  void initState() {
    super.initState();
    final s = Store.read(context);
    prev = widget.entryId == null ? null : s.entry(widget.entryId!);
    final active = s.people.where((p) => !p.isPast).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      // остання людина, з якою був запис, інакше найновіша
      final last = [...s.entries]..sort((a, b) => b.date.compareTo(a.date));
      personId = widget.personId ?? (last.isNotEmpty ? last.first.personId : (active.isNotEmpty ? active.first.id : ''));
      date = widget.date ?? today();
    }
    note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  void _axisPick(TagAxis ax, String opt) => setState(() {
        final ids = ax.all.map((o) => o.id).toSet();
        final was = tags.contains(opt);
        tags.removeWhere(ids.contains);
        if (!was) tags.add(opt);
      });

  void _toggle(List<String> list, String id) => setState(() => list.contains(id) ? list.remove(id) : list.add(id));

  Future<void> _save(AppStore s) async {
    if (personId.isEmpty) {
      _pickWho(s);
      return;
    }
    final sexTagIds = tagIndex.entries.where((x) => x.value.sexOnly).map((x) => x.key).toSet();
    final cleanTags = hadSex ? tags : tags.where((t) => !sexTagIds.contains(t)).toList();
    final cleanRatings = Map<String, int>.fromEntries(ratings.entries.where((r) => r.key != 'sx_overall' && (hadSex || !r.key.startsWith('sx_'))));
    if (hadSex) cleanRatings['sx_overall'] = overall;
    final cleanFacts = Map<String, int>.fromEntries(factVals.entries.where((f) => hadSex || f.key != 'f_stam'));
    final e = Entry(
      id: prev?.id ?? uid(),
      personId: personId,
      date: date,
      overall: overall,
      hadSex: hadSex,
      ratings: cleanRatings,
      tags: cleanTags,
      flags: flagIds,
      facts: cleanFacts,
      note: note.text.trim(),
      createdAt: prev?.createdAt ?? DateTime.now().toIso8601String(),
    );
    await s.saveEntry(e);
    if (!mounted) return;
    if (prev != null) {
      Navigator.pop(context);
    } else {
      goReplace(context, EntryView(entryId: e.id));
    }
  }

  Future<void> _pickWho(AppStore s) async {
    final r = await showSheet<(String, String)>(context, (_) => _WhoWhenSheet(personId: personId, date: date));
    if (r != null) setState(() { personId = r.$1; date = r.$2; });
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    final person = s.person(personId);
    final he = person?.gender == 'f' ? 'Вона' : 'Він';
    final monthCount = entriesInMonth(s.entries, monthKey(date), exceptId: prev?.id);
    final limit = prev == null && !p.premium && monthCount >= freeEntriesPerMonth;

    final sexQs = sexQuestions.where((q) => q.id == 'sx_overall' || q.always || p.sexQs.contains(q.id)).toList();
    final ptQs = partnerQuestions.where((q) => p.ptQs.contains(q.id)).toList();
    String done(List<Question> qs) => '${qs.where((q) => q.id == 'sx_overall' ? overall > 0 : (ratings[q.id] ?? 0) > 0).length}';
    final tagCount = tags.length + flagIds.length;
    final tabsDef = [
      ('sex', 'Секс', done(sexQs) != '0'),
      ('partner', he, done(ptQs) != '0' || flagIds.isNotEmpty),
      ('tags', 'Що було', tagCount > 0),
      ('facts', 'Факти', factVals.isNotEmpty),
    ];

    final ok = overall > 0 && personId.isNotEmpty;

    return DFrame(
      builder: (context, h) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 58, 20, 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 44,
            child: Row(children: [
              const BackBtn(),
              Expanded(
                child: Center(
                  child: Press(
                    onTap: prev == null ? () => _pickWho(s) : null,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                      decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        PAvatar(seed: seedOf(personId)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(person == null ? 'З ким?' : '${person.name} · ${human(date).replaceAll('листопада', 'лист').replaceAll('жовтня', 'жовт')}', style: rw(12), overflow: TextOverflow.ellipsis)),
                        if (prev == null) ...[const SizedBox(width: 4), const Ico(_chevDown, size: 11)],
                      ]),
                    ),
                  ),
                ),
              ),
              IconBtn(svg: _sliders, label: 'Мої питання', onTap: () => go(context, const QuestionsScreen())),
            ]),
          ),
          const SizedBox(height: 16),
          titleAcc([('Як ', false), ('пройшло', true), ('?', false)], 34),
          const SizedBox(height: 14),
          // таби
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.07))),
            child: Row(children: [
              for (final t in tabsDef)
                Expanded(
                  child: Press(
                    onTap: () => setState(() => tab = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: easeD,
                      height: 44,
                      decoration: BoxDecoration(color: tab == t.$1 ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(t.$2, style: rw(14, color: tab == t.$1 ? K.bg : K.muted2, w: FontWeight.w500)),
                        if (t.$3) Container(margin: const EdgeInsets.only(left: 5, bottom: 10), width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: K.acc, boxShadow: tab == t.$1 ? null : [BoxShadow(color: K.a(.8), blurRadius: 6)])),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: switch (tab) {
                  'sex' => _sexTab(sexQs),
                  'partner' => _partnerTab(ptQs, person),
                  'tags' => _tagsTab(),
                  _ => _factsTab(s, person),
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (limit)
            _cta('Записувати без ліміту', () => goReplace(context, const PaywallScreen(kind: PaywallKind.limit)))
          else
            _cta(prev == null ? 'Зберегти запис' : 'Зберегти зміни', ok ? () => _save(s) : null, hint: overall == 0 ? 'Постав «Як загалом?»' : null),
        ]),
      ),
    );
  }

  Widget _cta(String text, VoidCallback? onTap, {String? hint}) => Press(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          padding: const EdgeInsets.fromLTRB(26, 0, 6, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: onBase(onTap == null ? null : const RadialGradient(center: Alignment.topLeft, radius: 4, colors: [Color(0xFFF6A890), K.acc], stops: [0, .6]), onTap == null ? K.w(.06) : null),
            boxShadow: onTap == null ? null : [BoxShadow(color: K.a(.7), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -14)]),
          child: Row(children: [
            Expanded(child: Text(onTap == null && hint != null ? hint : text, style: rw(16, color: onTap == null ? K.haze : K.bg, w: FontWeight.w700))),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: onTap == null ? Colors.transparent : const Color(0x1F17161F)),
              alignment: Alignment.center,
              child: Ico(Svgs.check, size: 16, color: onTap == null ? K.haze : K.bg),
            ),
          ]),
        ),
      );

  // ---- рядок з зірками ----
  Widget _qRow(String text, int value, ValueChanged<int> onChange) => Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.fromLTRB(16, 7, 8, 7),
        decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.05))),
        child: Row(children: [
          Expanded(child: Text(text, style: rw(14, h: 1.35))),
          const SizedBox(width: 10),
          Semantics(
            label: text,
            value: value == 0 ? 'без оцінки' : '$value з 5',
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var v = 1; v <= 5; v++)
                Press(
                  scale: .85,
                  label: '$v з 5',
                  onTap: () => onChange(value == v ? 0 : v),
                  child: SizedBox(
                    width: 28, height: 44,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(boxShadow: v <= value ? [BoxShadow(color: K.a(.35), blurRadius: 8)] : null, shape: BoxShape.circle),
                        child: Ico(Svgs.star4, size: 18, color: v <= value ? K.acc : K.w(.16)),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      );

  Widget _seg(List<(String, String)> opts, String? cur, ValueChanged<String> pick) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: K.w(.07))),
        child: Row(children: gapped([
          for (final o in opts)
            Expanded(
              child: Press(
                onTap: () => pick(o.$1),
                child: Semantics(
                  selected: cur == o.$1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: easeD,
                    constraints: const BoxConstraints(minHeight: 38),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: cur == o.$1 ? K.acc : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    child: Text(o.$2, textAlign: TextAlign.center, style: rw(12.5, color: cur == o.$1 ? K.bg : K.soft, w: FontWeight.w600, h: 1.15)),
                  ),
                ),
              ),
            ),
        ], 3, horizontal: true)),
      );

  Widget _list(List<Widget> xs, {double gap = 6}) => ListView(padding: EdgeInsets.zero, children: gapped(xs, gap));

  Widget _sexTab(List<Question> qs) => _list([
        Text('Був секс?', style: rw(13, w: FontWeight.w600)),
        _seg(const [('y', 'Так'), ('n', 'Ні, тільки побачення')], hadSex ? 'y' : 'n', (v) => setState(() => hadSex = v == 'y')),
        if (!hadSex) Text('Питання про секс пропускаємо. У Wrapped цей вечір піде як побачення: оцінюємо сам вечір і його.', style: rw(12, color: K.muted2, h: 1.45)),
        const SizedBox(height: 6),
        if (hadSex)
          for (final q in qs)
            q.id == 'sx_overall'
                ? _qRow(q.text, overall, (v) => setState(() => overall = v))
                : _qRow(q.text, ratings[q.id] ?? 0, (v) => setState(() => v == 0 ? ratings.remove(q.id) : ratings[q.id] = v))
        else
          _qRow('Як загалом пройшов вечір?', overall, (v) => setState(() => overall = v)),
      ]);

  Widget _flagBox(bool pos, Person? person) {
    final list = flags.where((f) => pos ? f.kind == FlagKind.g : f.kind != FlagKind.g).toList();
    final key = pos ? 'green' : 'red';
    final isOpen = open.contains(key);
    final shown = isOpen ? list : [for (var i = 0; i < list.length; i++) if (i < 4 || flagIds.contains(list[i].id)) list[i]];
    final hidden = list.length - shown.length;
    final c = pos ? K.green : K.acc;
    final n = list.where((f) => flagIds.contains(f.id)).length;
    final sugg = suggestFlags(note.text).where((id) => !flagIds.contains(id) && list.any((f) => f.id == id)).toSet();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.withValues(alpha: .2)),
        gradient: onBase(RadialGradient(center: Alignment.topLeft, radius: 1.4, colors: [c.withValues(alpha: .14), c.withValues(alpha: 0)], stops: const [0, .6]), K.w(.02))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: .14), border: Border.all(color: c.withValues(alpha: .35)), boxShadow: [BoxShadow(color: c.withValues(alpha: .2), blurRadius: 14)]),
            alignment: Alignment.center,
            child: Ico(_flagIc, size: 14, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pos ? 'Зелені прапорці' : 'Червоні прапорці', style: rw(14, w: FontWeight.w500)),
              Text(pos ? 'йдуть у Залу слави' : 'йдуть у Залу ганьби', style: rw(11, color: K.muted)),
            ]),
          ),
          if (n > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(999)),
              child: Text('$n', style: rw(11, color: K.bg, w: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final f in shown)
            _tg(f.label, flagIds.contains(f.id), () => _toggle(flagIds, f.id), kind: pos ? 1 : 2, suggested: sugg.contains(f.id), critical: f.kind == FlagKind.c),
          if (hidden > 0 || isOpen) _more(key, isOpen ? 'Згорнути' : 'ще $hidden'),
        ]),
      ]),
    );
  }

  /// .tg — чип; kind 0 звичайний, 1 зелений, 2 червоний
  Widget _tg(String label, bool on, VoidCallback onTap, {int kind = 0, bool suggested = false, bool critical = false}) {
    final onColor = kind == 1 ? K.green : (critical ? K.red : K.acc);
    final border = kind == 1 ? K.green.withValues(alpha: .22) : kind == 2 ? K.a(.22) : K.w(.1);
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: easeD,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: on ? onColor : K.w(.03),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? Colors.transparent : (suggested ? onColor : border), width: suggested && !on ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (suggested && !on) ...[Ico(Svgs.star4, size: 10, color: onColor), const SizedBox(width: 6)],
          Text(label, style: rw(13, color: on ? K.bg : const Color(0xFFD7D3E0), w: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _more(String key, String label) => Press(
        onTap: () => setState(() => open.contains(key) ? open.remove(key) : open.add(key)),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.16))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: rw(13, color: K.muted2, w: FontWeight.w500))]),
        ),
      );

  Widget _partnerTab(List<Question> qs, Person? person) => _list([
        _flagBox(true, person),
        const SizedBox(height: 8),
        _flagBox(false, person),
        const SizedBox(height: 14),
        Row(children: [Text('Оцінки', style: rw(12, color: K.muted, w: FontWeight.w500, ls: .24)), const Spacer(), Text('1–5', style: rw(12, color: K.haze, w: FontWeight.w500))]),
        for (final q in qs) _qRow(person?.gender == 'f' ? _fem(q.text) : q.text, ratings[q.id] ?? 0, (v) => setState(() => v == 0 ? ratings.remove(q.id) : ratings[q.id] = v)),
        if (qs.isEmpty) Text('Питань про людину не обрано. Додай їх у «Мої питання».', style: rw(13, color: K.muted)),
      ]);

  String _fem(String t) => t.replaceAll('до нього', 'до неї').replaceAll('він ', 'вона ').replaceAll('з ним', 'з нею').replaceAll('Наскільки він', 'Наскільки вона');

  Widget _tagsTab() {
    final widgets = <Widget>[
      Text("Обирай один бік з пари. Не пам'ятаєш або не про це, просто пропусти.", style: rw(12, color: K.muted2, h: 1.45)),
    ];
    for (final g in _groups) {
      final axs = g.$2.map(_axis).whereType<TagAxis>().where((a) => hadSex || !a.sexOnly).toList();
      final chips = g.$3.map((id) => (id, tagLabel(id))).where((c) => hadSex || !(tagIndex[c.$1]?.sexOnly ?? false)).toList();
      if (axs.isEmpty && chips.isEmpty) continue;
      final isOpen = open.contains(g.$1);
      final showAll = isOpen || axs.length - 2 <= 1;
      final shown = showAll ? axs : [for (var i = 0; i < axs.length; i++) if (i < 2 || axs[i].all.any((o) => tags.contains(o.id))) axs[i]];
      final hidden = axs.length - shown.length;
      final filled = axs.where((a) => a.all.any((o) => tags.contains(o.id))).length + chips.where((c) => tags.contains(c.$1)).length;
      widgets.add(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(g.$1, style: rw(13, w: FontWeight.w500, ls: .26)),
          const Spacer(),
          if (filled > 0) Text('$filled', style: rw(12, color: K.haze, w: FontWeight.w500)),
        ]),
        for (final a in shown)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(left: 2, bottom: 5), child: Text(a.title, style: rw(11.5, color: K.haze))),
            _seg([for (final o in a.all) (o.id, o.label)], a.all.map((o) => o.id).firstWhere(tags.contains, orElse: () => ''), (v) => _axisPick(a, v)),
          ]),
        if (chips.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: [for (final c in chips) _tg(c.$2, tags.contains(c.$1), () => _toggle(tags, c.$1))]),
        if (hidden > 0 || (isOpen && axs.length - 2 > 1)) Align(alignment: Alignment.centerLeft, child: _more(g.$1, isOpen ? 'Згорнути' : 'ще $hidden')),
      ], 10)));
    }
    widgets.add(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text('Нотатка для себе', style: rw(12, color: K.muted, w: FontWeight.w500)), const Spacer(), Text("необов'язково", style: rw(12, color: K.haze, w: FontWeight.w500))]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: K.w(.1))),
        child: TextField(
          controller: note,
          minLines: 3,
          maxLines: 8,
          cursorColor: K.acc,
          style: rw(14, h: 1.5),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: "Що хочеш запам'ятати про цей вечір", hintStyle: rw(14, color: K.haze, w: FontWeight.w500)),
        ),
      ),
      if (suggestFlags(note.text).any((id) => !flagIds.contains(id))) ...[
        const SizedBox(height: 8),
        Text('У нотатці є схоже на прапорці. Вони підсвічені на вкладці «${Store.read(context).person(personId)?.gender == 'f' ? 'Вона' : 'Він'}».', style: rw(12, color: K.accSoft, h: 1.4)),
      ],
    ]));
    return _list(widgets, gap: 20);
  }

  Widget _factsTab(AppStore s, Person? person) {
    Widget slider(Fact f) {
      final v = factVals[f.id];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(22), border: Border.all(color: K.w(.04))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(f.label, style: rw(13, color: K.muted, w: FontWeight.w500))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(v == null ? '—' : f.steps[v], style: pr(22, h: 1)),
              if (v != null && f.hint != null) ...[const SizedBox(height: 3), Text(f.hint![v], style: rw(11, color: K.muted2))],
            ]),
          ]),
          const SizedBox(height: 14),
          StepSlider(value: v, onChanged: (x) => setState(() => factVals[f.id] = x)),
          Row(children: [
            for (var i = 0; i < f.steps.length; i++)
              Expanded(
                child: Press(
                  onTap: () => setState(() => factVals[f.id] = i),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Text(f.steps[i], textAlign: TextAlign.center, style: rw(11, color: v == i ? K.star : K.haze, w: v == i ? FontWeight.w600 : FontWeight.w500, h: 1.25))),
                ),
              ),
          ]),
        ]),
      );
    }

    final fs = facts.where((f) => f.id != 'f_init' && (hadSex || f.id != 'f_stam')).toList();
    final init = facts.firstWhere((f) => f.id == 'f_init');
    const sizeL = ['Скромно', 'Золотий стандарт', 'Вражає', 'Гігант'];
    return _list([
      for (final f in fs) slider(f),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(22), border: Border.all(color: K.w(.04))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(init.label, style: rw(13, color: K.muted, w: FontWeight.w500)),
          const SizedBox(height: 12),
          _seg([for (var i = 0; i < init.steps.length; i++) ('$i', init.steps[i])], factVals['f_init']?.toString(), (v) => setState(() {
                final n = int.parse(v);
                factVals['f_init'] == n ? factVals.remove('f_init') : factVals['f_init'] = n;
              })),
        ]),
      ),
      if (person != null && hadSex)
        Press(
          onTap: () async {
            final v = await showSheet<int>(context, (_) => _SizeSheet(current: person.size));
            if (v != null) {
              await s.updatePerson(person.id, (x) => x.size = v);
              if (mounted) dToast(this.context, 'Збережено в картці');
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(22), border: Border.all(color: K.w(.08))),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Розмір · вказується один раз', style: rw(12, color: K.muted, w: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(person.size == null ? '—' : sizeL[person.size!], style: pr(18)),
                ]),
              ),
              Text('змінити', style: rw(12, color: K.accSoft, w: FontWeight.w500)),
              const SizedBox(width: 12),
              Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.05), border: Border.all(color: K.w(.08))), alignment: Alignment.center, child: Ico(Svgs.chevR, size: 14, color: K.soft2)),
            ]),
          ),
        ),
    ], gap: 10);
  }
}

/// Повзунок на 4 кроки з макета (рейка, крапки, біла ручка)
class StepSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  final int steps;
  const StepSlider({super.key, required this.value, required this.onChanged, this.steps = 4});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final l = w * .125, span = w * .75;
        int at(double x) => (((x - l) / span) * (steps - 1)).round().clamp(0, steps - 1);
        final v = value;
        final x = v == null ? null : l + span * v / (steps - 1);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (e) => onChanged(at(e.localPosition.dx)),
          onHorizontalDragUpdate: (e) => onChanged(at(e.localPosition.dx)),
          child: SizedBox(
            height: 44,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(left: l, width: span, top: 21, child: Container(height: 2, decoration: BoxDecoration(color: K.w(.12), borderRadius: BorderRadius.circular(1)))),
              if (x != null) AnimatedPositioned(duration: const Duration(milliseconds: 300), curve: easeD, left: l, width: x - l, top: 21, child: Container(height: 2, color: K.acc)),
              for (var i = 0; i < steps; i++)
                Positioned(left: l + span * i / (steps - 1) - 3, top: 19, child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: v != null && i <= v ? K.acc : const Color(0xFF3A3646)))),
              if (x != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: easeD,
                  left: x - 9, top: 13,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: K.star, boxShadow: [const BoxShadow(color: Color(0x7308060E), blurRadius: 6, offset: Offset(0, 2)), BoxShadow(color: K.a(.14), spreadRadius: 4)]),
                  ),
                ),
            ]),
          ),
        );
      });
}

/// Варіант у листі (.xopt) з радіо-кружечком
Widget xOpt({required Widget child, required bool on, required VoidCallback onTap, Widget? lead}) => Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: easeD,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? K.a(.55) : K.w(.07)),
          gradient: onBase(on ? RadialGradient(center: Alignment.topLeft, radius: 1.6, colors: [K.a(.14), K.a(0)], stops: const [0, .6]) : null, on ? null : K.w(.025))),
        child: Row(children: [
          if (lead != null) ...[lead, const SizedBox(width: 12)],
          Expanded(child: child),
          Ck(on, size: 22),
        ]),
      ),
    );

class _SizeSheet extends StatelessWidget {
  final int? current;
  const _SizeSheet({this.current});
  @override
  Widget build(BuildContext context) {
    const sizeL = ['Скромно', 'Золотий стандарт', 'Вражає', 'Гігант'];
    return Sheet(children: [
      Text('Розмір', style: pr(24, h: 1.15)),
      Text('Вказується один раз і зберігається в картці людини. Запис нікуди не дінеться.', style: rw(13, color: K.muted, h: 1.45)),
      for (var i = 0; i < 4; i++) xOpt(child: Text(sizeL[i], style: rw(15, w: FontWeight.w500)), on: current == i, onTap: () => Navigator.pop(context, i)),
      _ghostBtn(context, 'Скасувати'),
    ]);
  }
}

Widget _ghostBtn(BuildContext context, String t, [VoidCallback? onTap]) =>
    Press(onTap: onTap ?? () => Navigator.pop(context), child: SizedBox(height: 44, child: Center(child: Text(t, style: rw(15, w: FontWeight.w500)))));

Widget _primaryBtn(String t, VoidCallback? onTap, {bool danger = false}) => Press(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: onTap == null ? K.w(.06) : (danger ? const Color(0xFFD9544F) : K.acc),
          boxShadow: danger ? [const BoxShadow(color: Color(0xB3D9544F), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -14)] : null,
        ),
        child: Text(t, style: rw(15, color: danger ? Colors.white : (onTap == null ? K.haze : K.bg), w: danger ? FontWeight.w700 : FontWeight.w600)),
      ),
    );

/// Календар-місяць для вибору дати (майбутні дні недоступні)
class MonthGrid extends StatefulWidget {
  final String value;
  final String? current;
  final ValueChanged<String> onPick;
  final bool future; // true — можна тільки сьогодні й далі (планування)
  const MonthGrid({super.key, required this.value, required this.onPick, this.current, this.future = false});
  @override
  State<MonthGrid> createState() => MonthGridState();
}

class MonthGridState extends State<MonthGrid> {
  late DateTime month = DateTime(parseIso(widget.value).year, parseIso(widget.value).month);
  @override
  Widget build(BuildContext context) {
    final first = month;
    final lead = first.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final t = today();
    final canNext = widget.future || DateTime(month.year, month.month + 1).isBefore(DateTime.now().add(const Duration(days: 1)));
    return Column(children: [
      Row(children: [
        Text('${cap(monthsNom[month.month - 1])} ${month.year}', style: rw(13, color: K.muted)),
        const Spacer(),
        Press(onTap: () => setState(() => month = DateTime(month.year, month.month - 1)), label: 'Попередній місяць', child: SizedBox(width: 36, height: 36, child: Center(child: Ico(Svgs.back, size: 16, color: K.soft2)))),
        Press(
          onTap: canNext ? () => setState(() => month = DateTime(month.year, month.month + 1)) : null,
          label: 'Наступний місяць',
          child: SizedBox(width: 36, height: 36, child: Center(child: Transform.flip(flipX: true, child: Ico(Svgs.back, size: 16, color: canNext ? K.soft2 : K.dimC)))),
        ),
      ]),
      const SizedBox(height: 6),
      Row(children: [for (final w in const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд']) Expanded(child: Text(w, textAlign: TextAlign.center, style: rw(11, color: K.haze)))]),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        childAspectRatio: 46 / 40,
        children: [
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var d = 1; d <= days; d++)
            () {
              final iso = '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
              final fut = widget.future ? iso.compareTo(t) < 0 : iso.compareTo(t) > 0;
              final sel = iso == widget.value;
              final cur = iso == widget.current && !sel;
              return Press(
                onTap: fut ? null : () => widget.onPick(iso),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: easeD,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: sel ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(12), border: cur ? Border.all(color: K.a(.55)) : null),
                  child: Text('$d', style: rw(14, color: sel ? K.bg : fut ? K.dimC : K.soft2, w: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }(),
        ],
      ),
    ]);
  }
}

/// Лист «З ким і коли» для нового запису
class _WhoWhenSheet extends StatefulWidget {
  final String personId, date;
  const _WhoWhenSheet({required this.personId, required this.date});
  @override
  State<_WhoWhenSheet> createState() => _WhoWhenSheetState();
}

class _WhoWhenSheetState extends State<_WhoWhenSheet> {
  late String pid = widget.personId, date = widget.date;
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final people = s.people.where((p) => !p.isPast).toList();
    return Sheet(children: [
      Text('З ким і коли', style: pr(26, h: 1.15)),
      for (final p in people.take(4))
        xOpt(
          on: pid == p.id,
          onTap: () => setState(() => pid = p.id),
          lead: PAvatar(size: 40, seed: seedOf(p.id)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: rw(15, w: FontWeight.w500)),
            Text('${s.entries.where((e) => e.personId == p.id).length} ${plural(s.entries.where((e) => e.personId == p.id).length, 'зустріч', 'зустрічі', 'зустрічей')}', style: rw(12, color: K.muted)),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Press(
          onTap: () async {
            final id = await go<String>(context, const AddPersonScreen());
            if (id != null) setState(() => pid = id);
          },
          child: SizedBox(height: 44, child: Row(mainAxisSize: MainAxisSize.min, children: [const Ico('<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>', size: 14, color: K.accSoft), const SizedBox(width: 8), Text('Нова людина', style: rw(13, color: K.accSoft, w: FontWeight.w500))])),
        ),
      ),
      MonthGrid(value: date, onPick: (d) => setState(() => date = d)),
      _primaryBtn('Готово', pid.isEmpty ? null : () => Navigator.pop(context, (pid, date))),
      _ghostBtn(context, 'Скасувати'),
    ]);
  }
}

// =====================================================================
// Перегляд запису
// =====================================================================
class EntryView extends StatefulWidget {
  final String entryId;
  const EntryView({super.key, required this.entryId});
  @override
  State<EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView> {
  bool openNote = false;

  Widget _stars(int v) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++) Padding(padding: const EdgeInsets.only(left: 3), child: Ico(Svgs.star4, size: 13, color: i <= v ? K.acc : K.w(.16))),
      ]);

  Widget _rateCard(String title, List<(String, int)> rows) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(4, 0, 0, 4), child: Text(title, style: rw(12, color: K.muted, w: FontWeight.w500, ls: .24))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(22), border: Border.all(color: K.w(.06))),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: K.w(.06)))),
                child: Row(children: [Expanded(child: Text(rows[i].$1, style: rw(14))), const SizedBox(width: 12), Semantics(label: '${rows[i].$2} з 5', child: _stars(rows[i].$2))]),
              ),
          ]),
        ),
      ]);

  Widget _flagPill(String t, int kind) {
    // 0 нейтральний, 1 зелений, 2 червоний
    final c = kind == 1 ? K.green : kind == 2 ? K.acc : null;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: c == null ? K.w(.03) : c.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c == null ? K.w(.1) : c.withValues(alpha: .32)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (c != null) ...[Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [BoxShadow(color: c.withValues(alpha: .7), blurRadius: 6)])), const SizedBox(width: 7)],
        Text(t, style: rw(12, color: kind == 1 ? const Color(0xFFB5DABD) : kind == 2 ? K.accSoft : K.soft2, w: FontWeight.w500)),
      ]),
    );
  }

  Future<void> _actions(AppStore s, Entry e) async {
    final p = s.person(e.personId);
    final r = await showSheet<String>(context, (ctx) => _ActionsSheet(entry: e, personName: p?.name ?? '—'));
    if (!mounted || r == null) return;
    switch (r) {
      case 'edit':
        go(context, EntryForm(entryId: e.id));
      case 'date':
        final d = await showSheet<String>(context, (_) => _DateSheet(entry: e));
        if (d != null && d != e.date) {
          final old = e.date;
          e.date = d;
          await s.saveEntry(e);
          if (mounted) _undoToast('Дату змінено', () async { e.date = old; await s.saveEntry(e); });
        }
      case 'move':
        final to = await showSheet<String>(context, (_) => _MoveSheet(entry: e));
        if (to != null && to != e.personId) {
          final old = e.personId;
          e.personId = to;
          await s.saveEntry(e);
          if (mounted) _undoToast('Запис перенесено до ${s.personName(to)}', () async { e.personId = old; await s.saveEntry(e); });
        }
      case 'delete':
        final yes = await showSheet<bool>(context, (_) => _DeleteSheet(entry: e, personName: p?.name ?? '—'));
        if (yes == true) {
          await s.deleteEntry(e.id);
          if (!mounted) return;
          final overlay = appNav.currentState?.overlay ?? Overlay.of(context);
          Navigator.of(context).pop();
          _undoToast('Запис видалено', () => s.saveEntry(e), overlay: overlay);
        }
    }
  }

  void _undoToast(String text, Future<void> Function() undo, {OverlayState? overlay}) => undoToast(context, text, undo, overlay: overlay);

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final e = s.entry(widget.entryId);
    if (e == null) return DFrame(builder: (_, __) => const SizedBox());
    final p = s.person(e.personId);
    final pf = s.profile;
    final f = p?.gender == 'f';
    final his = s.entries.where((x) => x.personId == e.personId).toList();
    final best = his.length > 1 && e.overall == his.map((x) => x.overall).reduce((a, b) => a > b ? a : b) && his.where((x) => x.overall == e.overall).length == 1;
    final sexRows = [
      for (final q in sexQuestions)
        if (q.id != 'sx_overall' && e.ratings[q.id] != null) (q.text, e.ratings[q.id]!, !(q.always || pf.sexQs.contains(q.id))),
    ];
    final ptRows = [for (final q in partnerQuestions) if (e.ratings[q.id] != null) (q.text, e.ratings[q.id]!)];
    final green = e.flags.where((x) => flagById(x)?.kind == FlagKind.g).toList();
    final red = e.flags.where((x) => flagById(x)?.kind != FlagKind.g).toList();
    final d = parseIso(e.date);
    final dateLabel = '${cap(const ['', 'понеділок', 'вівторок', 'середа', 'четвер', 'пʼятниця', 'субота', 'неділя'][d.weekday])}, ${d.day} ${monthsGen[d.month - 1]}';

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned(
          left: 0, right: 0, top: 0, height: 290,
          child: IgnorePointer(
            child: Stack(fit: StackFit.expand, children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([.74, .06, .02, 0, 0, .03, .76, .02, 0, 0, .03, .06, .72, 0, 0, 0, 0, 0, 1, 0]),
                child: Image.asset(_heroFor(e), fit: BoxFit.cover, alignment: const Alignment(0, -.3)),
              ),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x8C17161F), Color(0x4017161F), Color(0xB317161F), K.bg], stops: [0, .3, .7, 1]))),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x9917161F), Color(0x0017161F)], stops: [0, .7]))),
            ]),
          ),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              SizedBox(
                height: 44,
                child: Row(children: [
                  const BackBtn(),
                  Expanded(
                    child: Center(
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                        decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [PAvatar(seed: seedOf(e.personId)), const SizedBox(width: 8), Text('${p?.name ?? '—'} · ${e.hadSex ? 'після' : 'побачення'}', style: rw(12))]),
                      ),
                    ),
                  ),
                  IconBtn(svg: _dots, label: 'Дії із записом', onTap: () => _actions(s, e)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dateLabel, style: rw(13, color: K.w(.78))),
                const SizedBox(height: 6),
                Text(entryTitle(e), style: pr(30, h: 1.1)),
              ]),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(30), border: Border.all(color: K.w(.06))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: onBase(RadialGradient(center: Alignment.centerLeft, radius: 1.6, colors: [K.a(.24), const Color(0x0025222F)], stops: const [0, .65]), K.card2),
                    boxShadow: const [BoxShadow(color: Color(0xF209080E), blurRadius: 32, offset: Offset(0, 18), spreadRadius: -20)]),
                  child: Row(children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD3C4), K.acc]).createShader(r),
                      child: Text('${e.overall}', style: pr(54, h: 1, ls: 0, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.hadSex ? 'Як загалом?' : 'Як пройшов вечір?', style: rw(15, w: FontWeight.w500)),
                        if (best) ...[
                          const SizedBox(height: 4),
                          Row(children: [const Ico(Svgs.star4, size: 11, color: K.accSoft), const SizedBox(width: 6), Text(f ? 'Найкраща зустріч з нею' : 'Найкраща зустріч з ним', style: rw(12, color: K.accSoft))]),
                        ],
                      ]),
                    ),
                  ]),
                ),
              ),
              if (e.note.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(24), border: Border.all(color: K.w(.05))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Ico(_note, size: 13, color: K.accSoft), const SizedBox(width: 7), Text('Нотатка', style: rw(12, color: K.accSoft, w: FontWeight.w500))]),
                    const SizedBox(height: 10),
                    Text(!openNote && e.note.length > 140 ? '${e.note.substring(0, 118)}…' : e.note, style: rw(14, color: K.soft, h: 1.55)),
                    if (e.note.length > 140)
                      Press(onTap: () => setState(() => openNote = !openNote), child: SizedBox(height: 36, child: Align(alignment: Alignment.centerLeft, child: Text(openNote ? 'Згорнути' : 'Показати все', style: rw(13, color: K.acc, w: FontWeight.w600))))),
                  ]),
                ),
              if (sexRows.isNotEmpty) _rateCard('Секс', [for (final r in sexRows) (r.$1, r.$2)]),
              if (ptRows.isNotEmpty) _rateCard(f ? 'Вона' : 'Він', ptRows),
              if (green.isNotEmpty || red.isNotEmpty)
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final g in green) _flagPill(flagById(g)!.label, 1),
                  for (final r in red) _flagPill(flagById(r)?.label ?? r, 2),
                ]),
              if (e.tags.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: [for (final t in e.tags) _flagPill(tagLabel(t), 0)]),
              if (e.facts.isNotEmpty)
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final fc in facts)
                    if (e.facts[fc.id] != null) _flagPill('${fc.label}: ${fc.steps[e.facts[fc.id]!].toLowerCase()}', 0),
                ]),
              const SizedBox(height: 4),
              Press(
                onTap: () => go(context, EntryForm(entryId: e.id)),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.fromLTRB(26, 0, 6, 0),
                  decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: K.w(.4), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -18)]),
                  child: Row(children: [
                    Expanded(child: Text('Редагувати', style: rw(16, color: K.bg, w: FontWeight.w700))),
                    Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1417161F)), alignment: Alignment.center, child: const Ico(_pen, size: 15, color: K.bg)),
                  ]),
                ),
              ),
            ], 18)),
          ),
        ),
      ]),
    );
  }
}

// ---------- листи дій ----------
class _ActionsSheet extends StatelessWidget {
  final Entry entry;
  final String personName;
  const _ActionsSheet({required this.entry, required this.personName});

  Widget _it(BuildContext context, String id, String svg, String title, String sub, {bool red = false}) => Press(
        onTap: () => Navigator.pop(context, id),
        scale: .99,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: K.w(.06)))),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: red ? const Color(0x1AE25C5C) : null, border: Border.all(color: red ? const Color(0x4DF2827A) : K.w(.1))),
              alignment: Alignment.center,
              child: Ico(svg, size: 16, color: red ? K.red : K.soft2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: rw(15, color: red ? K.red : K.star, w: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub, style: rw(12, color: red ? K.red.withValues(alpha: .75) : K.muted)),
              ]),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = parseIso(entry.date);
    return DFrame(
      bg: Colors.transparent,
      builder: (context, h) => Stack(children: [
        Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(context))),
        Positioned(
          left: 12, right: 12, bottom: 16,
          child: ConstrainedBox(constraints: BoxConstraints(maxHeight: h - 56), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(28), border: Border(top: BorderSide(color: K.w(.09)))),
              child: Column(children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: K.w(.18), borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: K.w(.1))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${d.day}', style: pr(17, h: 1, ls: 0)),
                        Text(monthsGen[d.month - 1].substring(0, 4), style: rw(10, color: K.muted, w: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(entryTitle(entry), style: pr(18, h: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('$personName · оцінка ${entry.overall}', style: rw(12, color: K.muted)),
                      ]),
                    ),
                  ]),
                ),
                _it(context, 'edit', _pen, 'Редагувати', 'Оцінки, теги, нотатка'),
                _it(context, 'date', _cal, 'Змінити дату', 'Зараз ${human(entry.date)}'),
                _it(context, 'move', _move, 'Перенести на іншу людину', 'Якщо записала не туди'),
                _it(context, 'delete', Svgs.trash, 'Видалити запис', 'Оцінки зникнуть з мапи', red: true),
              ]),
            ),
            const SizedBox(height: 10),
            Press(
              onTap: () => Navigator.pop(context),
              child: Container(height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.08))), child: Text('Скасувати', style: rw(15, w: FontWeight.w600))),
            ),
          ]))),
        ),
      ]),
    );
  }
}

class _DateSheet extends StatefulWidget {
  final Entry entry;
  const _DateSheet({required this.entry});
  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late String d = widget.entry.date;
  @override
  Widget build(BuildContext context) {
    final p = parseIso(d);
    final wd = const ['', 'понеділок', 'вівторок', 'середа', 'четвер', 'пʼятниця', 'субота', 'неділя'][p.weekday];
    return Sheet(children: [
      Text('Змінити дату', style: pr(26, h: 1.15)),
      MonthGrid(value: d, current: widget.entry.date, onPick: (x) => setState(() => d = x)),
      Text(d == widget.entry.date ? 'Зараз $wd, ${p.day} ${monthsGen[p.month - 1]}. Майбутні дні недоступні, для них є «Нова зустріч».' : 'Нова дата: $wd, ${p.day} ${monthsGen[p.month - 1]}.', style: rw(13, color: K.muted, h: 1.5)),
      _primaryBtn('Зберегти дату', () => Navigator.pop(context, d)),
      _ghostBtn(context, 'Скасувати'),
    ]);
  }
}

class _MoveSheet extends StatefulWidget {
  final Entry entry;
  const _MoveSheet({required this.entry});
  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  String? to;
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final others = s.people.where((p) => p.id != widget.entry.personId).toList();
    return Sheet(children: [
      Text('Перенести запис', style: pr(26, h: 1.15)),
      Text('Зараз він у ${s.personName(widget.entry.personId)}. Оцінки, теги і прапорці перейдуть разом із записом.', style: rw(14, color: K.soft, h: 1.5)),
      for (final p in others.take(5))
        xOpt(
          on: to == p.id,
          onTap: () => setState(() => to = p.id),
          lead: PAvatar(size: 40, seed: seedOf(p.id)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: rw(15, w: FontWeight.w500)),
            Text('${s.entries.where((e) => e.personId == p.id).length} ${plural(s.entries.where((e) => e.personId == p.id).length, 'зустріч', 'зустрічі', 'зустрічей')}', style: rw(12, color: K.muted)),
          ]),
        ),
      if (others.isEmpty) Text('Інших людей поки нема.', style: rw(13, color: K.muted)),
      _primaryBtn('Перенести', to == null ? null : () => Navigator.pop(context, to)),
      _ghostBtn(context, 'Скасувати'),
    ]);
  }
}

class _DeleteSheet extends StatelessWidget {
  final Entry entry;
  final String personName;
  const _DeleteSheet({required this.entry, required this.personName});
  @override
  Widget build(BuildContext context) {
    final d = parseIso(entry.date);
    return Sheet(children: [
      Text('Видалити запис?', style: pr(26, h: 1.15)),
      Text('Зустріч з $personName ${d.day} ${monthsGen[d.month - 1]}. Її оцінки зникнуть з мапи і порівнянь.', style: rw(14, color: K.soft, h: 1.5)),
      const SizedBox(height: 6),
      _primaryBtn('Видалити', () => Navigator.pop(context, true), danger: true),
      _ghostBtn(context, 'Скасувати'),
    ]);
  }
}
