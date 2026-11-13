// Порівняння двох людей за дошками ComparePick / CompareSex / ComparePersona / CompareStars:
// шапка з двома людьми, вкладки «Секс · Він · Зірки», дзеркальні смужки по питаннях
// і картка «Висновок». Цифри тільки з записів; де в когось нема відповідей — «мало даних».
import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../ui/board.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'entry.dart' show PAvatar, seedOf;
import 'people.dart' show PersonView;
import 'settings.dart' show PaywallScreen;

const _lilac = Color(0xFFD7D3E0);
const _star = 'M12 1l2.6 8.4L23 12l-8.4 2.6L12 23l-2.6-8.4L1 12l8.4-2.6z';
final _icSwap = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M7 4L3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7"/></svg>';
final _icChev = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M9 6l6 6-6 6"/></svg>';

/// Короткі підписи питань, як на дошках
const _short = {
  'sx_pleasure': 'Наскільки тобі було добре',
  'sx_care': 'Наскільки дбали про тебе',
  'sx_fore': 'Прелюдії вистачало',
  'sx_pace': 'Темп підходив',
  'sx_finish': 'Задоволена фіналом',
  'sx_heard': 'Тебе почули',
  'sx_self': 'Могла бути собою',
  'sx_chem': 'Збіглась хімія',
  'sx_after': 'Тепло після',
  'sx_length': 'Тривалість підходила',
  'sx_ask': 'Легко сказати, чого хочеш',
  'sx_react': 'Реагував на підказки',
  'sx_safe': 'Почувалась у безпеці',
  'sx_relax': 'Вдалось розслабитись',
  'sx_lead': 'Вела сама',
  'pt_word': 'Тримає слово',
  'pt_pull': 'Тягне до нього',
  'pt_hears': 'Чує тебе',
  'pt_limits': 'Поважає межі',
  'pt_talk': 'Цікаво говорити не про секс',
  'pt_free': 'Вільно без ревнощів і контролю',
  'pt_more': 'Хочеш більшого',
  'pt_desired': 'Почуваєшся бажаною',
  'pt_trust': 'Довіряєш йому',
  'pt_steady': 'Без зникань',
  'pt_pleasure': 'Цікавиться твоїм задоволенням',
  'pt_curious': 'Цікавиться тобою',
  'pt_laugh': 'Смішно разом',
  'pt_calm': 'Спокійно поруч',
  'pt_effort': 'Вкладається часом',
  'pt_values': 'Збігаються цінності',
};

/// Відкрити порівняння: без Premium — пейвол; менше двох людей — підказка
void openCompare(BuildContext context, {String? personId}) {
  final s = Store.read(context);
  if (!s.profile.premium) {
    go(context, const PaywallScreen());
    return;
  }
  final ppl = s.people.where((p) => entriesOf(s.entries, p.id).isNotEmpty).toList();
  if (ppl.length < 2) {
    dToast(context, 'Порівняння відкриється, коли буде двоє людей із записами');
    return;
  }
  go(context, CompareScreen(personId: personId));
}

class CompareScreen extends StatefulWidget {
  final String? personId;
  final int tab; // 0 секс, 1 він, 2 зірки
  const CompareScreen({super.key, this.personId, this.tab = 0});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<String> sel = [];
  int tab = 0;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    tab = widget.tab;
    final s = Store.read(context);
    // за замовчуванням — двоє з найбільшою кількістю записів (або обрана людина + найчастіша інша)
    final byN = s.people.where((p) => entriesOf(s.entries, p.id).isNotEmpty).toList()
      ..sort((a, b) => entriesOf(s.entries, b.id).length.compareTo(entriesOf(s.entries, a.id).length));
    final first = widget.personId ?? (byN.isNotEmpty ? byN.first.id : null);
    sel = [if (first != null) first, ...byN.map((p) => p.id).where((id) => id != first).take(1)];
  }

  void _pick() {
    var cur = [...sel];
    showSheet(context, (ctx) {
      final s = Store.read(context);
      return StatefulBuilder(builder: (ctx, setS) {
        void tog(String id) => setS(() {
              if (cur.contains(id)) {
                cur.remove(id);
              } else {
                cur.add(id);
                if (cur.length > 2) cur = cur.sublist(1);
              }
            });
        Widget row(Person p) {
          final i = cur.indexOf(p.id);
          final n = entriesOf(s.entries, p.id).length;
          final past = p.status == 'past';
          return Opacity(
            opacity: past ? .72 : 1,
            child: Press(
              onTap: () => tog(p.id),
              label: p.name,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: easeD,
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: i > -1 ? K.a(.08) : K.w(.025),
                  border: Border.all(color: i > -1 ? K.a(.55) : K.w(.07)),
                ),
                child: Row(children: [
                  PAvatar(size: 40, seed: seedOf(p.id)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(15, w: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text([
                        '$n ${plural(n, 'зустріч', 'зустрічі', 'зустрічей')}',
                        if (past && p.pastAt != null) 'до ${monthsGen[parseIso(p.pastAt!).month - 1]}' else if (relLabel(p.rel).isNotEmpty) relLabel(p.rel),
                      ].join(' · '), style: rw(12, color: K.muted)),
                    ]),
                  ),
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i > -1 ? K.acc : null, border: Border.all(color: i > -1 ? K.acc : K.w(.25), width: 1.5)),
                    alignment: Alignment.center,
                    child: Text(i > -1 ? '${i + 1}' : '', style: rw(11, color: K.bg, w: FontWeight.w600, h: 1)),
                  ),
                ]),
              ),
            ),
          );
        }

        final withE = s.people.where((p) => entriesOf(s.entries, p.id).isNotEmpty).toList();
        final now = withE.where((p) => p.status != 'past').toList(), past = withE.where((p) => p.status == 'past').toList();
        final ok = cur.length == 2;
        return Sheet(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text('Кого порівнюємо', style: pr(26, h: 1.15))),
            Text('${cur.length} з 2', style: rw(13, color: K.muted)),
          ]),
          ...now.map(row),
          if (past.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(2, 4, 2, 0), child: Text('Минулі', style: rw(12, color: K.muted2))),
          ...past.map(row),
          const SizedBox(height: 6),
          Press(
            onTap: ok
                ? () {
                    Navigator.pop(ctx);
                    setState(() => sel = cur);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 54,
              decoration: BoxDecoration(color: ok ? K.acc : K.w(.06), borderRadius: BorderRadius.circular(999)),
              alignment: Alignment.center,
              child: Text(ok ? 'Порівняти' : 'Обери ще одну людину', style: rw(15, color: ok ? K.bg : K.haze, w: FontWeight.w600)),
            ),
          ),
          Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Скасувати', style: rw(15, w: FontWeight.w600))))),
        ]);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final ps = [for (final id in sel) s.people.where((p) => p.id == id).firstOrNull].whereType<Person>().toList();
    if (ps.length < 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const ColoredBox(color: K.bg);
    }
    final a = ps[0], b = ps[1];
    final ea = entriesOf(s.entries, a.id), eb = entriesOf(s.entries, b.id);
    final sa = personStats(s.entries, a.id), sb = personStats(s.entries, b.id);

    final header = Row(children: [
      BackBtn(onTap: () => Navigator.maybePop(context)),
      Expanded(child: Center(child: Text('Порівняння', style: rw(15, w: FontWeight.w700)))),
      Semantics(
        button: true,
        label: 'Змінити людей',
        child: Press(onTap: _pick, child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.hour), alignment: Alignment.center, child: Ico(_icSwap, size: 19))),
      ),
    ]);

    Widget person(Person p, double v, bool left, String sub) => Expanded(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: K.bg, boxShadow: [BoxShadow(color: left ? K.acc : K.haze, spreadRadius: 2)]),
              child: PAvatar(size: 52, seed: seedOf(p.id)),
            ),
            const SizedBox(height: 6),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(14, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(v.isNaN ? '—' : fmt(v), style: pr(26, color: left ? K.acc : K.soft, h: 1)),
            const SizedBox(height: 6),
            Text(sub, style: rw(11, color: K.muted2)),
          ]),
        );

    final tabs = Tabs(items: const [('Секс', null), ('Він', null), ('Зірки', null)], index: tab, onChanged: (i) => setState(() => tab = i));

    final List<Widget> body;
    String verdict;
    String meta;
    if (tab < 2) {
      final sex = tab == 0;
      final qs = (sex ? sexQuestions : partnerQuestions).where((q) => q.id != 'sx_overall').toList();
      double q(List<Entry> es, String id) => avg(es.map((e) => e.ratings[id]).whereType<int>());
      final rows = <_Row>[];
      for (final x in qs) {
        final va = q(sex ? ea.where((e) => e.hadSex).toList() : ea, x.id), vb = q(sex ? eb.where((e) => e.hadSex).toList() : eb, x.id);
        if (va.isNaN && vb.isNaN) continue;
        rows.add(_Row(_short[x.id] ?? x.text, va, vb));
      }
      // спершу ті, де є обидві відповіді, і з найбільшою різницею — у макеті вміщається 8 / 7 рядків
      final both = rows.where((r) => !r.a.isNaN && !r.b.isNaN).toList()..sort((x, y) => (y.a - y.b).abs().compareTo((x.a - x.b).abs()));
      final one = rows.where((r) => r.a.isNaN || r.b.isNaN).toList();
      final shown = [...both, ...one].take(sex ? 8 : 7).toList();
      final head = Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        person(a, sex ? sa.sex : sa.him, true, sex ? 'середнє за сексом' : 'середнє за ним'),
        Text('vs', style: pr(22, color: K.muted2)),
        person(b, sex ? sb.sex : sb.him, false, sex ? 'середнє за сексом' : 'середнє за ним'),
      ]);
      final aWins = both.where((r) => r.a > r.b).toList(), bWins = both.where((r) => r.b > r.a).toList();
      final lead = aWins.length >= bWins.length ? a : b;
      final other = lead == a ? b : a;
      final otherBest = (lead == a ? bWins : aWins).firstOrNull;
      if (shown.isEmpty) {
        verdict = sex ? 'Ще нема оцінок сексу з обома. Після записів тут з’явиться різниця.' : 'Ще нема оцінок «Він» для обох. Заповни їх у записах.';
      } else if (both.isEmpty) {
        verdict = 'Порівнювати нема з чим: питання відповідені тільки для одного.';
      } else if (sex) {
        // імена не відмінюємо: «з Марк» звучить криво, тому речення будуємо без відмінків
        final orgA = sa.orgN == 0 ? '' : '${a.name}: ти кінчала у ${sa.orgMe} з ${sa.orgN} ${plural(sa.orgN, 'зустрічі', 'зустрічей', 'зустрічей')}. ';
        verdict = otherBest == null
            ? '$orgA${lead.name} кращий за всіма ${both.length} ${plural(both.length, 'питанням', 'питаннями', 'питаннями')}.'
            : '$orgA${lead.name} виграє ${lead == a ? aWins.length : bWins.length} з ${both.length}. ${other.name} сильніший у «${otherBest.label.toLowerCase()}».';
      } else {
        const verbs = {'flag_r_phone': 'сидить у телефоні', 'flag_r_late': 'запізнюється', 'flag_r_ex': 'згадує колишню', 'flag_r_self': 'говорить тільки про себе', 'flag_r_cheap': 'рахує копійки', 'flag_r_jab': 'підколює', 'flag_r_drunk': 'перебирає', 'flag_r_jealous': 'ревнує', 'flag_r_gone': 'зникає', 'flag_r_lie': 'бреше', 'flag_r_push': 'тисне'};
        final worse = sa.red > sb.red ? (a, sa) : (sb.red > sa.red ? (b, sb) : null);
        final rv = worse == null ? <String>[] : worse.$2.flagCounts.where((f) => f.kind == FlagKind.r).map((f) => verbs[f.id]).whereType<String>().take(2).toList();
        verdict = '${otherBest == null ? '${lead.name} сильніший за всіма питаннями.' : '${other.name} сильніший у «${otherBest.label.toLowerCase()}», ${lead.name} — у решті.'}${rv.isEmpty ? '' : ' Але ${worse!.$1.name} ${rv.join(' і ')}.'}';
      }
      meta = sex ? '${ea.where((e) => e.hadSex).length} і ${eb.where((e) => e.hadSex).length} ${plural(eb.where((e) => e.hadSex).length, 'зустріч', 'зустрічі', 'зустрічей')}' : '${shown.length} ${plural(shown.length, 'питання', 'питання', 'питань')}';
      body = [
        head,
        tabs,
        Column(children: gapped([for (final (k, r) in shown.indexed) _Bars(r, delay: k * 40)], 10)),
        if (!sex) _Flags(sa, sb),
      ];
    } else {
      final me = astroOf(s.profile.birth);
      String sub(Person p) {
        final x = astroOf(p.birth, p.signOnly);
        if (x == null) return 'дата народження невідома';
        return x.arc == null ? x.signName : '${x.signName} · ${x.romanNum} ${x.arcanaName}';
      }

      // аркани пари «легко», якщо аркан пари з любовно-гармонійних (Імператриця, Закохані, Колесо, Сила, Помірність, Зірка, Сонце, Світ)
      const easyArc = {3, 6, 10, 11, 14, 17, 19, 21};
      (int?, bool?, String?, bool?) pair(Person p) {
        final x = astroOf(p.birth, p.signOnly);
        if (x == null || me == null) return (null, null, null, null);
        final arc = x.arc == null || me.arc == null ? null : pairArcana(me.arc!, x.arc!);
        final els = me.el == x.el ? '${_elGen(me.el)} і ${_elGen(x.el)}'.replaceFirst(RegExp(r' і .*'), ' і ${_elGen(x.el)}') : '${_elGen(me.el)} і ${_elGen(x.el)}';
        return (arc, arc == null ? null : easyArc.contains(arc), els, zodiacEase(me.sign, x.sign) == 'Легко');
      }

      final pa = pair(a), pb = pair(b);
      int score((int?, bool?, String?, bool?) p) => (p.$2 == true ? 1 : 0) + (p.$4 == true ? 1 : 0);
      final recA = avg(ea.map((e) => e.overall)), recB = avg(eb.map((e) => e.overall));
      String side(bool? x, bool? y) => x == y ? 'нічия' : (x == true ? a.name : b.name);
      final arcS = side(pa.$2, pb.$2), zS = side(pa.$4, pb.$4);
      final recS = recA == recB ? 'нічия' : (recA > recB ? a.name : b.name);
      verdict = me == null
          ? 'Додай свою дату народження в налаштуваннях, щоб порівняти зірки.'
          : 'Аркани: $arcS. Зодіак: $zS. Записи: ${recS == 'нічия' ? 'нічия' : recS}.';
      meta = 'аркани · зодіак · записи';
      Widget card(Person p, (int?, bool?, String?, bool?) m, bool lead) => Press(
            onTap: () => go(context, PersonView(personId: p.id)),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: K.w(.025), border: Border.all(color: K.w(.06))),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: K.card2,
                ),
                foregroundDecoration: lead ? BoxDecoration(borderRadius: BorderRadius.circular(23), gradient: RadialGradient(center: Alignment.topLeft, radius: 1.1, colors: [K.a(.13), K.a(0)], stops: const [0, .6])) : null,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Row(children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [const BoxShadow(color: K.card2, spreadRadius: 2), BoxShadow(color: lead ? K.a(.6) : K.soft.withValues(alpha: .5), spreadRadius: 3)]),
                        child: PAvatar(size: 40, seed: seedOf(p.id)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(15, w: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(sub(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(12, color: K.muted)),
                        ]),
                      ),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.05), border: Border.all(color: K.w(.08))),
                        alignment: Alignment.center,
                        child: Ico(_icChev, size: 14, color: K.soft2),
                      ),
                    ]),
                  ),
                  _ln('Аркани', m.$1 == null ? '—' : '${roman[m.$1!]} ${arcana[m.$1!].name}', m.$2),
                  _ln('Зодіак', m.$3 ?? '—', m.$4),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: K.w(.06)))),
                    child: Text(m.$1 == null ? 'Додай дату народження людини, щоб побачити аркан пари.' : arcana[m.$1!].love, style: rw(13, color: const Color(0xFFBDB8CC), h: 1.45)),
                  ),
                ]),
              ),
            ),
          );
      body = [
        tabs,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(children: [
            Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [K.acc, K.haze]))),
            const SizedBox(width: 8),
            Expanded(child: Text(me == null ? 'Ти: дата народження не вказана' : 'Ти: ${me.signName}${me.arc == null ? '' : ' · ${me.romanNum} ${me.arcanaName}'}', style: rw(13, color: K.muted2))),
          ]),
        ),
        card(a, pa, score(pa) >= score(pb)),
        card(b, pb, score(pb) > score(pa)),
      ];
    }

    final vz = Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F2B3A), Color(0xFF25222E)]),
        border: Border.all(color: K.w(.05)),
        boxShadow: const [BoxShadow(color: Color(0xCC08060E), blurRadius: 40, offset: Offset(0, 18), spreadRadius: -24)],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(right: -36, bottom: -44, child: Opacity(opacity: .07, child: Ico('<svg viewBox="0 0 24 24"><path fill="currentColor" d="$_star"/></svg>', size: 120))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Ico('<svg viewBox="0 0 24 24"><path fill="currentColor" d="$_star"/></svg>', size: 12, color: K.acc),
            const SizedBox(width: 6),
            Text('Висновок', style: rw(12, color: K.accSoft, w: FontWeight.w600)),
            const Spacer(),
            Text(meta, style: rw(11, color: K.muted2)),
          ]),
          const SizedBox(height: 10),
          Text(verdict, style: pr(18, h: 1.38)),
        ]),
      ]),
    );

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned(
          left: -40, right: -40, top: -60, height: 520,
          child: IgnorePointer(
            child: Stack(children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(-.44, 0), radius: .55, colors: [K.a(.16), K.a(0)])))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(.48, 0), radius: .55, colors: [K.haze.withValues(alpha: .18), K.haze.withValues(alpha: 0)])))),
            ]),
          ),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h - 80),
              child: IntrinsicHeight(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ...gapped([header, ...body], 14),
                  const Spacer(),
                  const SizedBox(height: 14),
                  vz,
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

String _elGen(String el) => const {'Вогонь': 'Вогонь', 'Повітря': 'повітря', 'Земля': 'Земля', 'Вода': 'вода'}[el] ?? el;

Widget _ln(String k, String v, bool? easy) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: K.w(.06)))),
      child: Row(children: [
        SizedBox(width: 46, child: Text(k, style: rw(12, color: K.muted))),
        const SizedBox(width: 10),
        Expanded(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: pr(15))),
        if (easy != null) ...[
          const SizedBox(width: 10),
          Container(
            height: 24,
            padding: const EdgeInsets.fromLTRB(9, 0, 10, 0),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: easy ? K.a(.10) : K.w(.03), border: Border.all(color: easy ? K.a(.32) : K.w(.09))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: easy ? K.acc : null, border: easy ? null : Border.all(color: K.soft), boxShadow: easy ? [BoxShadow(color: K.a(.8), blurRadius: 8)] : null)),
              const SizedBox(width: 6),
              Text(easy ? 'Легко' : 'Складніше', style: rw(11, color: easy ? K.accSoft : K.soft2, w: FontWeight.w500, ls: .22)),
            ]),
          ),
        ],
      ]),
    );

class _Row {
  final String label;
  final double a, b;
  const _Row(this.label, this.a, this.b);
}

/// Рядок порівняння: підпис по центру, ліва смужка росте вліво, права — вправо
class _Bars extends StatelessWidget {
  final _Row r;
  final int delay;
  const _Bars(this.r, {this.delay = 0});
  @override
  Widget build(BuildContext context) {
    final few = r.a.isNaN || r.b.isNaN;
    final aw = !few && r.a > r.b, bw = !few && r.b > r.a;
    String v(double x) => x.isNaN ? '–' : (x == x.roundToDouble() ? '${x.round()}' : fmt(x));
    Widget bar(double x, Color c, bool left) => Expanded(
          child: Align(
            alignment: left ? Alignment.centerRight : Alignment.centerLeft,
            child: Rise(
              delay: delay / 1000,
              child: FractionallySizedBox(
                widthFactor: x.isNaN ? 0 : (x / 5).clamp(0.0, 1.0),
                child: Container(height: 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ),
        );
    return Column(children: [
      Text.rich(
        TextSpan(children: [TextSpan(text: r.label), if (few) TextSpan(text: ' · мало даних', style: rw(11, color: K.muted2))]),
        textAlign: TextAlign.center,
        style: rw(12, color: few ? K.muted2 : K.soft, ls: .12),
      ),
      const SizedBox(height: 5),
      Row(children: [
        SizedBox(width: 26, child: Text(v(r.a), textAlign: TextAlign.center, style: pr(16, color: aw ? K.accSoft : K.muted2, h: 1))),
        const SizedBox(width: 8),
        bar(r.a, few ? K.haze.withValues(alpha: .2) : (aw ? K.acc : K.a(.28)), true),
        const SizedBox(width: 8),
        Container(width: 1, height: 14, color: K.w(.14)),
        const SizedBox(width: 8),
        bar(r.b, few ? K.haze.withValues(alpha: .2) : (bw ? _lilac : K.haze.withValues(alpha: .32)), false),
        const SizedBox(width: 8),
        SizedBox(width: 26, child: Text(v(r.b), textAlign: TextAlign.center, style: pr(16, color: bw ? K.star : K.muted2, h: 1))),
      ]),
    ]);
  }
}

/// Прапорці двох людей: зелені крапки, потім червоні
class _Flags extends StatelessWidget {
  final PersonStats a, b;
  const _Flags(this.a, this.b);
  @override
  Widget build(BuildContext context) {
    Widget pips(PersonStats s) {
      final g = s.green.clamp(0, 12), r = s.red.clamp(0, 12);
      Widget pip(Color c) => Container(width: 7, height: 7, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [BoxShadow(color: c.withValues(alpha: .4), blurRadius: 6)]));
      return Row(mainAxisSize: MainAxisSize.min, children: [
        for (var k = 0; k < g; k++) pip(K.green),
        if (g > 0 && r > 0) const SizedBox(width: 5),
        for (var k = 0; k < r; k++) pip(K.acc),
        if (g + r == 0) Text('без прапорців', style: rw(11, color: K.muted2)),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(children: [
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Прапорці: '),
            TextSpan(text: 'зелені', style: rw(12, color: K.green)),
            const TextSpan(text: ' і '),
            TextSpan(text: 'червоні', style: rw(12, color: K.acc)),
          ]),
          textAlign: TextAlign.center,
          style: rw(12, color: K.soft, ls: .12),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 4, 7, 0),
          child: Row(children: [Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: pips(a))), const Spacer(), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: pips(b)))]),
        ),
      ]),
    );
  }
}
