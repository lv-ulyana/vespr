// «Мапа»: перенесено з дошок Map, MapEarly і MyArcana.
// Усі цифри рахуються з твоїх записів; блок ховається, коли даних замало.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/arcana_more.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'people.dart' show flagShort;
import 'awards.dart' show nearestAwardLine;
import 'settings.dart' show PaywallScreen;

const _freeFactors = 2;
const _full = 6; // скільки записів до повної мапи

// ---------- Людські назви факторів ----------
/// id тегу → (як на мапі, як у реченні)
const _nice = <String, (String, String)>{
  'talk': ('Розмова до', 'розмова'),
  'notalk': ('Без розмови', 'мовчанка'),
  'fore': ('Довга прелюдія', 'довга прелюдія'),
  'nofore': ('Без прелюдії', 'без прелюдії'),
  'slow': ('Повільний темп', 'повільний темп'),
  'rush': ('Поспіх', 'поспіх'),
  'sober': ('Тверезо', 'тверезість'),
  'alco1': ('Келих-два', 'келих-два'),
  'alco2': ('Алкоголь', 'алкоголь'),
  'fresh': ('У ресурсі', 'ресурс'),
  'tired': ('Втома', 'втома'),
  'chat': ('Флірт до', 'флірт'),
  'nochat': ('Без флірту', 'без флірту'),
  'planned': ('План', 'план'),
  'spont': ('Спонтанно', 'спонтанність'),
  'quick': ('Коротко', 'коротка зустріч'),
  'long_eve': ('Цілий вечір', 'цілий вечір'),
  'his': ('У нього', 'його територія'),
  'mine': ('У мене', 'твоя територія'),
  'hotel': ('Готель', 'готель'),
  'restaurant': ('Ресторан', 'ресторан'),
  'bar': ('Бар', 'бар'),
  'neutral': ('Кава, парк', 'прогулянка'),
  'straight_home': ('Одразу вдома', 'одразу вдома'),
  'day': ('До 22:00', 'вечір до 22:00'),
  'late': ('Пізно', 'пізній час'),
  'tender': ('Ніжно', 'ніжність'),
  'passion': ('Пристрасно', 'пристрасть'),
  'play': ('Сміялись', 'сміх'),
  'serious': ('Серйозно', 'серйозність'),
  'light': ('При світлі', 'світло'),
  'dark': ('У темряві', 'темрява'),
  'o_me': ('Твій оргазм', 'твій оргазм'),
  'o_fake': ('Симулювала', 'симуляція'),
};
String niceLabel(Effect e) => _nice[e.id]?.$1 ?? (e.kind == 'flag' ? flagShort(e.id) : e.label);
String niceNoun(Effect e) => _nice[e.id]?.$2 ?? e.label.toLowerCase();

/// Записи, у яких є цей фактор
bool _has(Entry e, Effect f) {
  switch (f.kind) {
    case 'flag':
      return e.flags.contains(f.id);
    case 'fact':
      final p = f.id.split(':');
      return e.facts[p[0]] == int.tryParse(p[1]);
  }
  return e.tags.contains(f.id);
}

String _sgn(double v) => '${v >= 0 ? '+' : '−'}${fmt(v.abs())}';
String _recs(int n) => '$n ${plural(n, 'запис', 'записи', 'записів')}';

const _wdAcc = ['понеділок', 'вівторок', 'середу', 'четвер', 'пʼятницю', 'суботу', 'неділю'];
const _wdShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'нд'];
String _onDay(int i) => '${i == 1 ? 'у' : 'в'} ${_wdAcc[i]}';

const _qShort = {
  'sx_pleasure': 'Тобі добре', 'sx_care': 'Дбали', 'sx_fore': 'Прелюдія', 'sx_pace': 'Темп', 'sx_heard': 'Почули', 'sx_self': 'Собою',
  'sx_finish': 'Фінал', 'sx_chem': 'Хімія', 'sx_after': 'Після', 'sx_length': 'Тривалість', 'sx_ask': 'Сказала', 'sx_react': 'Реагував',
  'sx_safe': 'Безпека', 'sx_relax': 'Розслабилась', 'sx_lead': 'Вела',
};

const _icShare = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M12 3v13M7 8l5-5 5 5M5 14v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5"/></svg>';
const _icUp = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6"><path d="M5 15l7-7 7 7"/></svg>';
const _icDown = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6"><path d="M5 9l7 7 7-7"/></svg>';
const _icLock = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>';
const _icStarLine = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z"/></svg>';
const _icStarFill = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z"/></svg>';
const _icHeart = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/></svg>';
const _icMoon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/></svg>';

TextStyle _cap() => rw(12, color: K.muted2);
Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(18), Decoration? deco}) => Container(
      padding: padding,
      decoration: deco ?? BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(28)),
      child: child,
    );
Widget _h2(String t) => Text(t, style: pr(24, h: 1.15));

// =====================================================================
class MapTab extends StatefulWidget {
  final ValueChanged<int>? onTab;
  const MapTab({super.key, this.onTab});
  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  String period = '3m'; // m | 3m | all
  int sel = 0;

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    if (s.entries.length < _full) return _MapEarly(entries: s.entries);

    final days = period == 'm' ? 30 : period == '3m' ? 90 : null;
    final from = days == null ? null : addDays(today(), -days);
    var es = s.entries.where((e) => from == null || e.date.compareTo(from) >= 0).toList();
    if (es.length < 3) es = s.entries; // за короткий період нема з чого рахувати
    final eff = effects(es);
    final pos = eff.where((e) => e.delta > 0).toList();
    final neg = eff.where((e) => e.delta < 0).toList();
    final ppl = es.map((e) => e.personId).toSet().length;
    final premium = s.profile.premium;

    // індекс і зміна
    final idx = avg(es.map((e) => e.overall));
    double? delta;
    String deltaTxt = '';
    if (days != null) {
      final prev = s.entries.where((e) => e.date.compareTo(addDays(today(), -2 * days)) >= 0 && e.date.compareTo(from!) < 0).map((e) => e.overall);
      if (prev.length >= 2) {
        delta = idx - avg(prev);
        deltaTxt = '${_sgn(delta)} за ${days == 30 ? 'місяць' : '3 місяці'}';
      }
    } else {
      final sorted = [...s.entries]..sort((a, b) => a.date.compareTo(b.date));
      final k = math.max(2, sorted.length ~/ 3);
      if (sorted.length >= 6) {
        delta = avg(sorted.skip(sorted.length - k).map((e) => e.overall)) - avg(sorted.take(k).map((e) => e.overall));
        deltaTxt = '${_sgn(delta)} від початку';
      }
    }

    final nodes = [...pos.take(5), ...neg.take(2)];
    if (sel >= nodes.length) sel = 0;
    final factors = [...pos.take(4), ...neg.take(2)];
    final shown = premium ? factors : factors.take(_freeFactors).toList();
    // формула: найсильніші позитивні теги з різних груп (від «Схоже»)
    final f = <Effect>[];
    for (final e in pos.where((x) => x.kind == 'tag')) {
      if (f.any((x) => x.group == e.group)) continue;
      f.add(e);
      if (f.length == 3) break;
    }

    return Stack(children: [
      const Positioned(left: -80, top: -40, child: EGlow(w: 550, h: 620, colors: [Color(0x29F08A6C), Color(0x0F8C86A3), Color(0x0017161F)], stops: [0, .45, .7])),
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            Rise(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Мапа', style: pr(36, h: 1)),
                    const SizedBox(height: 8),
                    Text('з ${es.length} ${plural(es.length, 'запису', 'записів', 'записів')} · $ppl ${plural(ppl, 'людина', 'людини', 'людей')}', style: _cap()),
                  ]),
                ),
                IconBtn(svg: _icShare, label: 'Поділитися безпечною версією', onTap: () => _shareSheet(context, idx: idx, pos: pos, neg: neg)),
              ]),
            ),
            Rise(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  for (final p in [('m', 'Місяць'), ('3m', '3 місяці'), ('all', 'Увесь час')])
                    Expanded(
                      child: Semantics(
                        selected: period == p.$1,
                        button: true,
                        child: Press(
                          onTap: () => setState(() { period = p.$1; sel = 0; }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: easeD,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: period == p.$1 ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                            child: Text(p.$2, style: rw(13, color: period == p.$1 ? K.bg : K.muted2, w: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            // 1. сузір'я
            Rise(
              delay: .1,
              child: _Constellation(
                key: ValueKey('c$period'),
                nodes: nodes,
                entries: es,
                sel: sel,
                onSel: (i) => setState(() => sel = i),
              ),
            ),
            // 2. індекс
            Rise(
              delay: .2,
              child: _card(
                child: Row(children: [
                  _Ring(key: ValueKey('r$period'), v: idx.isFinite ? idx : 0),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Індекс задоволення', style: _cap()),
                      if (delta != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: (delta >= 0 ? K.acc : K.haze).withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Ico(delta >= 0 ? _icUp : _icDown, size: 12, color: delta >= 0 ? K.acc : K.soft),
                            const SizedBox(width: 6),
                            Text(deltaTxt, style: rw(13, color: delta >= 0 ? K.acc : K.soft, w: FontWeight.w700)),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('Середнє «Як загалом?» за обраний період', style: rw(13, color: K.soft, h: 1.4)),
                    ]),
                  ),
                ]),
              ),
            ),
            // 3. портрет
            if (pos.isNotEmpty)
              Rise(
                delay: .2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Твій портрет', style: _cap()),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Тобі добре, коли є '),
                        TextSpan(text: '${_join(pos.take(3).map(niceNoun).toList())}.', style: const TextStyle(color: K.acc)),
                        if (neg.isNotEmpty) TextSpan(text: ' ${cap(niceNoun(neg.first))} тебе вимикає.'),
                      ]),
                      style: pr(25, h: 1.28),
                    ),
                  ]),
                ),
              ),
            // 4. фактори
            Rise(
              delay: .3,
              child: _card(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _h2('Що вмикає і вимикає'),
                  const SizedBox(height: 6),
                  Text('Наскільки оцінка вища чи нижча, ніж зазвичай', style: _cap()),
                  const SizedBox(height: 16),
                  if (factors.isEmpty)
                    Text('Поки нічого не вибивається більше ніж на 0,5. Записуй з деталями, так мапа швидше знайде твоє.', style: rw(13, color: K.soft, h: 1.45))
                  else
                    ...gapped([
                      for (var i = 0; i < shown.length; i++) _FactorRow(f: shown[i], max: factors.map((x) => x.delta.abs()).reduce(math.max), delay: .2 + i * .1),
                    ], 14),
                  if (!premium && factors.length > _freeFactors) ...[
                    const SizedBox(height: 14),
                    _LockCard(title: 'Ще ${factors.length - _freeFactors} ${plural(factors.length - _freeFactors, 'фактор', 'фактори', 'факторів')}', sub: 'Повна мапа відкривається з Premium', onTap: () => go(context, const PaywallScreen())),
                  ],
                ]),
              ),
            ),
            // 5. формула
            if (f.isNotEmpty) Rise(delay: .3, child: _Ticket(f: f, neg: neg, entries: es)),
            // 6. закономірності
            ..._patterns(es),
            if (nearestAwardLine(s) case final line?)
              Rise(
                delay: .3,
                child: Press(
                  onTap: () => widget.onTab?.call(3),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(begin: Alignment(-.6, -1), end: Alignment(.6, 1), colors: [K.acc, Color(0xFFD27E70), Color(0xFF6E6382)], stops: [0, .45, 1]),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Майже нагорода', style: rw(12, color: const Color(0xB317161F), w: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(line, style: pr(24, color: K.bg, h: 1.25)),
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: K.bg, borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Усі нагороди', style: rw(13, w: FontWeight.w700)), const SizedBox(width: 8), Ico(Svgs.arrowR, size: 14)]),
                      ),
                    ]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text("Закономірність з'являється, коли є щонайменше 3 записи з цим фактором", textAlign: TextAlign.center, style: rw(12, color: K.muted2, h: 1.5)),
            ),
          ], 16)),
        ),
      ),
    ]);
  }

  List<Widget> _patterns(List<Entry> es) {
    final out = <Widget>[];
    // дні тижня
    final byDay = List.generate(7, (_) => <int>[]);
    for (final e in es) {
      byDay[parseIso(e.date).weekday - 1].add(e.overall);
    }
    final dayAvg = byDay.map((x) => x.isEmpty ? double.nan : avg(x)).toList();
    final filled = dayAvg.where((x) => x.isFinite).length;
    if (filled >= 3) {
      var best = 0;
      for (var i = 1; i < 7; i++) {
        if (!dayAvg[best].isFinite || (dayAvg[i].isFinite && dayAvg[i] > dayAvg[best])) best = i;
      }
      final all = avg(es.map((e) => e.overall));
      out.add(_WeekCard(avgs: dayAvg, best: best, diff: dayAvg[best] - all));
    }
    // порядок зустрічей з людиною
    final byIdx = List.generate(5, (_) => <int>[]);
    final ids = es.map((e) => e.personId).toSet();
    for (final id in ids) {
      final mine = es.where((e) => e.personId == id).toList()..sort((a, b) => a.date.compareTo(b.date));
      if (mine.length < 2) continue;
      for (var i = 0; i < mine.length; i++) {
        byIdx[math.min(i, 4)].add(mine[i].overall);
      }
    }
    final idxAvg = byIdx.where((x) => x.isNotEmpty).map(avg).toList();
    if (idxAvg.length >= 3) out.add(_OrderCard(vals: idxAvg));
    // ритм
    final timed = es.where((e) => e.tags.contains('day') || e.tags.contains('late')).toList();
    if (timed.length >= 3) out.add(_RhythmCard(entries: timed));
    // радар
    final qs = <String, List<int>>{};
    for (final e in es) {
      e.ratings.forEach((k, v) {
        if (_qShort.containsKey(k)) (qs[k] ??= []).add(v);
      });
    }
    final axesQ = (qs.entries.where((x) => x.value.length >= 2).toList()..sort((a, b) => b.value.length.compareTo(a.value.length))).take(6).toList();
    if (axesQ.length >= 3) out.add(_RadarCard(items: [for (final a in axesQ) (_qShort[a.key]!, avg(a.value))]));
    if (out.isEmpty) return out;
    return [Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: _h2('Закономірності')), for (var i = 0; i < out.length; i++) Rise(delay: .3, child: out[i])];
  }
}

String _join(List<String> xs) => xs.length <= 1 ? xs.join() : '${xs.sublist(0, xs.length - 1).join(', ')} і ${xs.last}';

// ---------- Сузір'я ----------
class _Constellation extends StatefulWidget {
  final List<Effect> nodes;
  final List<Entry> entries;
  final int sel;
  final ValueChanged<int> onSel;
  const _Constellation({super.key, required this.nodes, required this.entries, required this.sel, required this.onSel});
  @override
  State<_Constellation> createState() => _ConstellationState();
}

class _ConstellationState extends State<_Constellation> with TickerProviderStateMixin {
  late final intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      pulse.repeat();
      Future.delayed(const Duration(milliseconds: 10800), () {
        if (mounted) pulse.animateTo(1, duration: Duration(milliseconds: ((1 - pulse.value) * 3600).round()));
      });
    } else {
      intro.value = 1;
    }
  }

  @override
  void dispose() {
    intro.dispose();
    pulse.dispose();
    super.dispose();
  }

  static const posSlots = [Offset(62, 74), Offset(168, 44), Offset(262, 102), Offset(132, 150), Offset(226, 200)];
  static const negSlots = [Offset(48, 228), Offset(282, 248)];

  List<Offset> _slots() {
    var p = 0, n = 0;
    return [for (final e in widget.nodes) e.delta > 0 ? posSlots[p++] : negSlots[n++]];
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.nodes;
    final slots = _slots();
    final e = nodes.isEmpty ? null : nodes[widget.sel];
    String detail = '';
    if (e != null) {
      final w = widget.entries.where((x) => _has(x, e)).map((x) => x.overall);
      final wo = widget.entries.where((x) => !_has(x, e)).map((x) => x.overall);
      detail = '${niceLabel(e)}: «Як загалом?» в середньому ${fmt(avg(w))}, без цього ${fmt(avg(wo))}. ${e.level}, ${_recs(e.nWith)}.';
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: K.w(.07)),
        gradient: const RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF2E2A3B), Color(0xFF1D1B26), K.bg], stops: [0, .6, 1]),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        titleAcc([("Сузір'я ", false), ('твого', true), (' задоволення', false)], 24, h: 1.15),
        const SizedBox(height: 6),
        Text('Що яскравіше світить, то сильніше впливає. Тапни на зірку, щоб побачити цифри.', style: _cap().copyWith(height: 1.4)),
        const SizedBox(height: 10),
        if (nodes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text('Зірки загоряться, коли щось почне помітно впливати на оцінку.', textAlign: TextAlign.center, style: rw(13, color: K.soft, h: 1.45)),
          )
        else ...[
          Center(
            child: GestureDetector(
              onTapUp: (d) {
                var best = -1;
                var bd = 1e9;
                for (var i = 0; i < slots.length; i++) {
                  final dist = (slots[i] - d.localPosition).distance;
                  if (dist < bd) {
                    bd = dist;
                    best = i;
                  }
                }
                if (best >= 0 && bd < 40) widget.onSel(best);
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([intro, pulse]),
                builder: (_, __) => CustomPaint(
                  size: const Size(314, 270),
                  painter: _SkyPainter(nodes: nodes, slots: slots, sel: widget.sel, t: intro.value, p: pulse.value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: nodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final on = i == widget.sel, p = nodes[i].delta > 0;
                return Semantics(
                  selected: on,
                  button: true,
                  child: Press(
                    onTap: () => widget.onSel(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? (p ? K.acc : K.haze) : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? (p ? K.acc : K.haze) : K.w(.12)),
                      ),
                      child: Text(niceLabel(nodes[i]), style: rw(12, color: on ? K.bg : K.soft, w: FontWeight.w600)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(widget.sel),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0x9917161F), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Text(_sgn(e!.delta), style: pr(28, h: 1, color: e.delta > 0 ? K.acc : K.soft)),
                const SizedBox(width: 14),
                Expanded(child: Text(detail, style: rw(13, color: const Color(0xFFD7D3E0), h: 1.45))),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final List<Effect> nodes;
  final List<Offset> slots;
  final int sel;
  final double t, p;
  _SkyPainter({required this.nodes, required this.slots, required this.sel, required this.t, required this.p});

  static const twinkles = [Offset(22, 30), Offset(296, 22), Offset(210, 140), Offset(30, 150), Offset(120, 250), Offset(300, 180), Offset(160, 20)];
  static const links = [(0, 1), (1, 2), (0, 3), (3, 2), (3, 4)];

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas c, Size s) {
    final maxD = nodes.map((e) => e.delta.abs()).fold<double>(.1, math.max);
    for (var i = 0; i < twinkles.length; i++) {
      final a = .2 + .7 * (.5 + .5 * math.sin((p + i / 7) * 2 * math.pi));
      c.drawCircle(twinkles[i], 1.1, Paint()..color = K.star.withValues(alpha: a));
    }
    final posIdx = [for (var i = 0; i < nodes.length; i++) if (nodes[i].delta > 0) i];
    final lp = Paint()
      ..color = K.acc.withValues(alpha: .55)
      ..strokeWidth = 1.2;
    for (var k = 0; k < links.length; k++) {
      final (a, b) = links[k];
      if (a >= posIdx.length || b >= posIdx.length) continue;
      final pa = slots[posIdx[a]], pb = slots[posIdx[b]];
      final q = Curves.easeInOut.transform(_seg(.15 + k * .1, .45 + k * .1));
      if (q > 0) c.drawLine(pa, Offset.lerp(pa, pb, q)!, lp);
    }
    for (var i = 0; i < nodes.length; i++) {
      final e = nodes[i], o = slots[i], pos = e.delta > 0;
      final r = 5 + 5 * (e.delta.abs() / maxD);
      final col = pos ? K.acc : K.haze;
      final pop = Curves.easeOutBack.transform(_seg(.1 + i * .05, .35 + i * .05));
      if (pos) {
        final ph = (p + i * .11) % 1;
        final k = .5 + .5 * math.sin(ph * 2 * math.pi);
        c.drawCircle(o, r * 2.4 * (1 + .35 * k) * pop, Paint()..color = col.withValues(alpha: .2 + .3 * k));
      }
      c.drawCircle(o, r * pop, Paint()..color = col.withValues(alpha: pos ? 1 : .75));
      if (i == sel) {
        c.drawCircle(o, r * pop, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = K.star);
      }
      final tp = TextPainter(
        text: TextSpan(text: niceLabel(e), style: rw(11, w: FontWeight.w600, color: i == sel ? K.star : (pos ? const Color(0xFFD7D3E0) : K.haze))),
        textDirection: TextDirection.ltr,
      )..layout();
      // підпис праворуч або ліворуч, щоб не вилазив за край
      final right = o.dx < s.width / 2;
      final dx = right ? o.dx + r + 6 : o.dx - r - 6 - tp.width;
      final dy = o.dy - r - tp.height - 2 < 0 ? o.dy + r + 2 : o.dy - r - tp.height + 1;
      tp.paint(c, Offset(dx.clamp(0, s.width - tp.width), dy));
    }
  }

  @override
  bool shouldRepaint(_SkyPainter o) => true;
}

// ---------- Кільце індексу ----------
class _Ring extends StatelessWidget {
  final double v;
  const _Ring({super.key, required this.v});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v / 5),
        duration: const Duration(milliseconds: 1600),
        curve: const Cubic(.65, 0, .35, 1),
        builder: (_, x, __) => SizedBox(
          width: 120, height: 120,
          child: CustomPaint(
            painter: _RingPainter(x),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(fmt(v), style: pr(32, h: 1)),
                const SizedBox(height: 4),
                Text('з 5', style: rw(11, color: K.haze, w: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double v;
  _RingPainter(this.v);
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCircle(center: s.center(Offset.zero), radius: 50);
    c.drawCircle(r.center, 50, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = K.bg);
    if (v <= 0) return;
    c.drawArc(r, -math.pi / 2, 2 * math.pi * v, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF7C2B1), K.acc]).createShader(r));
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v;
}

// ---------- Рядок фактора ----------
class _FactorRow extends StatelessWidget {
  final Effect f;
  final double max, delay;
  const _FactorRow({required this.f, required this.max, required this.delay});
  @override
  Widget build(BuildContext context) {
    final pos = f.delta > 0;
    final frac = (f.delta.abs() / math.max(max, .1)) * .36 / .5; // частка від половини доріжки
    return Row(children: [
      SizedBox(
        width: 118,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(niceLabel(f), style: rw(13, h: 1.25), maxLines: 2),
          const SizedBox(height: 2),
          Text('з ${_recs(f.nWith)}', style: rw(11, color: K.muted2)),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: 26,
          child: LayoutBuilder(builder: (context, c) {
            final half = c.maxWidth / 2;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: frac),
              duration: Duration(milliseconds: 1000 + (delay * 1000).round()),
              curve: Interval(delay / (1 + delay), 1, curve: easeOut),
              builder: (_, x, __) {
                final w = half * x;
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned(left: half, top: -4, bottom: -4, child: Container(width: 1, color: K.w(.12))),
                  Positioned(
                    top: 5, height: 16,
                    left: pos ? half : half - w,
                    width: w,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: pos ? const BorderRadius.horizontal(left: Radius.circular(2), right: Radius.circular(8)) : const BorderRadius.horizontal(left: Radius.circular(8), right: Radius.circular(2)),
                        gradient: LinearGradient(colors: pos ? const [Color(0xFFD27E70), K.acc] : const [K.haze, K.dimC]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: pos ? half + w + 6 : null,
                    right: pos ? null : half + w + 6,
                    child: Text(_sgn(f.delta), style: rw(12, w: FontWeight.w700, color: pos ? K.acc : K.soft)),
                  ),
                ]);
              },
            );
          }),
        ),
      ),
    ]);
  }
}

class _LockCard extends StatelessWidget {
  final String title, sub;
  final VoidCallback onTap;
  const _LockCard({required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(30), border: Border.all(color: K.w(.06))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(24), border: Border(top: BorderSide(color: K.w(.08)))),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: K.a(.12), border: Border.all(color: K.a(.32)), boxShadow: [BoxShadow(color: K.a(.25), blurRadius: 18)]),
                alignment: Alignment.center,
                child: const Ico(_icLock, size: 16, color: K.accSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: rw(14, w: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(sub, style: rw(12, color: K.muted)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

// ---------- Квиток «Формула твого ідеального вечора» ----------
class _Ticket extends StatelessWidget {
  final List<Effect> f, neg;
  final List<Entry> entries;
  const _Ticket({required this.f, required this.neg, required this.entries});
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF6B6580);
    final proven = entries.where((e) => f.every((x) => _has(e, x))).length;
    final title = cap(_join(f.map(niceNoun).toList()));
    final fields = <(String, String)>[
      for (final x in f) (x.group, niceLabel(x)),
      if (neg.isNotEmpty) ('Краще без', niceLabel(neg.first)),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: K.star,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Stack(clipBehavior: Clip.none, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Формула твого ідеального вечора', style: rw(12, color: ink, w: FontWeight.w600)),
            const SizedBox(height: 8),
            Padding(padding: EdgeInsets.only(right: proven > 0 ? 100 : 0), child: Text(title, style: pr(28, color: K.bg, h: 1.1))),
            const SizedBox(height: 22),
            SizedBox(
              height: 2,
              child: Stack(clipBehavior: Clip.none, children: [
                CustomPaint(size: const Size(double.infinity, 2), painter: _DashLine()),
                Positioned(left: -34, top: -14, child: Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg))),
                Positioned(right: -34, top: -14, child: Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg))),
              ]),
            ),
            const SizedBox(height: 14),
            Wrap(runSpacing: 12, children: [
              for (final x in fields)
                FractionallySizedBox(
                  widthFactor: .5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(x.$1, style: rw(11, color: ink)),
                      const SizedBox(height: 3),
                      Text(x.$2, style: rw(14, color: K.bg, w: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
          ]),
          if (proven > 0)
            Positioned(
              right: -2, top: -2,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1300),
                curve: const Interval(.45, 1, curve: Cubic(.34, 1.8, .64, 1)),
                builder: (_, k, child) => Opacity(opacity: k.clamp(0, 1), child: Transform.scale(scale: 1.8 - .8 * k, child: child)),
                child: Transform.rotate(
                  angle: -14 * math.pi / 180,
                  child: Container(
                    width: 86, height: 86,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB4502F), width: 1.5)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('ПЕРЕВІРЕНО', style: rw(10, color: const Color(0xFFA8492B), w: FontWeight.w700, ls: .4)),
                      Text('$proven', style: pr(24, color: const Color(0xFFA8492B), h: 1)),
                      Text(plural(proven, 'РАЗ', 'РАЗИ', 'РАЗІВ'), style: rw(10, color: const Color(0xFFA8492B), w: FontWeight.w700, ls: .4)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _DashLine extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x2E17161F)
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < s.width; x += 7) {
      c.drawLine(Offset(x, 0), Offset(math.min(x + 4, s.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashLine o) => false;
}

// ---------- Закономірності ----------
class _WeekCard extends StatelessWidget {
  final List<double> avgs;
  final int best;
  final double diff;
  const _WeekCard({required this.avgs, required this.best, required this.diff});
  @override
  Widget build(BuildContext context) => _card(
        deco: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF24212E), Color(0xFF2B2532)]),
          border: Border(top: BorderSide(color: K.w(.07))),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(right: -40, bottom: -60, child: EGlow(w: 260, h: 180, colors: [K.a(.22), K.a(0)], stops: const [0, .7])),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Найкраще тобі ${_onDay(best)}', style: pr(20, h: 1.15)),
            const SizedBox(height: 4),
            Text(diff > .05 ? 'На ${fmt(diff)} вище за середнє' : 'Майже як у середньому', style: _cap()),
            const SizedBox(height: 14),
            SizedBox(
              height: 96,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: avgs[i].isFinite ? avgs[i] / 5 * 72 : 4),
                        duration: Duration(milliseconds: 900 + i * 70),
                        curve: Interval(i * .07, 1, curve: const Cubic(.34, 1.3, .64, 1)),
                        builder: (_, h, __) => Container(
                          width: i == best ? 24 : 14,
                          height: math.max(0, h),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(4)),
                            gradient: i == best
                                ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD3C4), K.acc, Color(0xFFD9694A)], stops: [0, .55, 1])
                                : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: avgs[i].isFinite ? [const Color(0x8CCDC8DE), K.haze.withValues(alpha: .18)] : [K.w(.08), K.w(.08)]),
                            boxShadow: i == best ? [BoxShadow(color: K.a(.55), blurRadius: 24)] : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_wdShort[i], style: rw(11, color: i == best ? K.accSoft : const Color(0xFF8F89A6), w: i == best ? FontWeight.w600 : FontWeight.w400, ls: .2)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ]),
      );
}

class _OrderCard extends StatelessWidget {
  final List<double> vals;
  const _OrderCard({required this.vals});
  @override
  Widget build(BuildContext context) {
    const labels = ['1-ша', '2-га', '3-тя', '4-та', '5-та+'];
    final all = avg(vals);
    final rising = vals.last - vals.first;
    final title = rising >= .3 ? 'З кожною зустріччю краще' : rising <= -.3 ? 'Перші зустрічі найкращі' : 'Від зустрічі до зустрічі рівно';
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: pr(20, h: 1.15)),
        const SizedBox(height: 4),
        Text('«Як загалом?» за порядком зустрічі з тією самою людиною', style: _cap()),
        const SizedBox(height: 16),
        Stack(children: [
          Positioned(left: 18, right: 18, top: 18, child: Container(height: 1, color: K.w(.12))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < vals.length; i++)
              SizedBox(
                width: 40,
                child: Column(children: [
                  Rise(
                    delay: .25 + i * .12,
                    dy: 6,
                    child: Container(
                      width: 32, height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: vals[i] >= all
                          ? BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(center: Alignment(0, -.4), colors: [Color(0xFFF6A890), K.acc]), boxShadow: [BoxShadow(color: K.a(.7), blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -6)])
                          : BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1E1B25), border: Border.all(color: K.w(.12))),
                      alignment: Alignment.center,
                      child: vals[i] >= all ? const Ico(_icStarFill, size: 14, color: K.bg) : Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6B6580))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(labels[i], style: rw(11, color: const Color(0xFF8F89A6), ls: .2)),
                  const SizedBox(height: 8),
                  Text(fmt(vals[i]), style: pr(17, h: 1, color: vals[i] >= all ? K.star : const Color(0xFF8F89A6))),
                ]),
              ),
          ]),
        ]),
      ]),
    );
  }
}

class _RhythmCard extends StatelessWidget {
  final List<Entry> entries;
  const _RhythmCard({required this.entries});
  static const hc = [Color(0xFF24212F), Color(0xFF3A3548), K.haze, Color(0xFFC98C80), K.acc];
  @override
  Widget build(BuildContext context) {
    final rows = [('до 22:00', 'day'), ('після 22', 'late')];
    Color cell(String tag, int d) {
      final xs = entries.where((e) => e.tags.contains(tag) && parseIso(e.date).weekday - 1 == d).map((e) => e.overall);
      if (xs.isEmpty) return hc[0];
      final v = avg(xs);
      return v < 2.5 ? hc[1] : v < 3.5 ? hc[2] : v < 4.3 ? hc[3] : hc[4];
    }

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _h2('Твій ритм'),
        const SizedBox(height: 6),
        Text('Коли зустрічі виходять найкращими', style: _cap()),
        const SizedBox(height: 14),
        Row(children: [
          const SizedBox(width: 57),
          for (final d in _wdShort) Expanded(child: Text(d, textAlign: TextAlign.center, style: rw(11, color: K.muted2))),
        ]),
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(children: [
              SizedBox(width: 57, child: Text(rows[r].$1, style: rw(11, color: K.muted2))),
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Rise(delay: .2 + (r * 7 + d) * .03, dy: 4, child: Container(height: 26, decoration: BoxDecoration(color: cell(rows[r].$2, d), borderRadius: BorderRadius.circular(7)))),
                  ),
                ),
            ]),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Text('гірше', style: rw(11, color: K.muted2)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 6, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: const LinearGradient(colors: [Color(0xFF24212F), K.haze, K.acc])))),
          const SizedBox(width: 8),
          Text('краще', style: rw(11, color: K.muted2)),
        ]),
      ]),
    );
  }
}

class _RadarCard extends StatelessWidget {
  final List<(String, double)> items;
  const _RadarCard({required this.items});
  @override
  Widget build(BuildContext context) {
    var weak = 0;
    for (var i = 1; i < items.length; i++) {
      if (items[i].$2 < items[weak].$2) weak = i;
    }
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _h2('Твої питання в середньому'),
        const SizedBox(height: 6),
        Text('По всіх людях. Найслабше в тебе: ${items[weak].$1.toLowerCase()}', style: _cap()),
        const SizedBox(height: 28),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .2, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: const Cubic(.34, 1.3, .64, 1),
            builder: (_, k, __) => CustomPaint(size: const Size(314, 250), painter: _RadarPainter(items, weak, k)),
          ),
        ),
      ]),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<(String, double)> items;
  final int weak;
  final double k;
  _RadarPainter(this.items, this.weak, this.k);
  @override
  void paint(Canvas c, Size s) {
    const ctr = Offset(157, 125);
    final n = items.length;
    Offset pt(int i, double r) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return ctr + Offset(math.cos(a), math.sin(a)) * r;
    }

    Path poly(double Function(int) r) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final o = pt(i, r(i));
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75
      ..color = K.w(.10);
    c.drawPath(poly((_) => 100), grid);
    c.drawPath(poly((_) => 60), grid..color = K.w(.07));
    for (var i = 0; i < n; i++) {
      c.drawLine(ctr, pt(i, 100), Paint()
        ..color = K.w(.06)
        ..strokeWidth = .75);
    }
    final data = poly((i) => items[i].$2 / 5 * 100 * k);
    c.drawPath(data, Paint()..shader = RadialGradient(colors: [K.a(0), K.a(.12)]).createShader(Rect.fromCircle(center: ctr, radius: 100)));
    c.drawPath(data, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..color = K.a(.14));
    c.drawPath(data, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round
      ..color = K.accSoft);
    for (var i = 0; i < n; i++) {
      final o = pt(i, items[i].$2 / 5 * 100 * k);
      if (i == weak) {
        c.drawCircle(o, 11, Paint()..color = K.a(.14));
        c.drawCircle(o, 4.5, Paint()..color = K.bg);
        c.drawCircle(o, 4.5, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = K.acc);
      } else {
        c.drawCircle(o, 2.5, Paint()..color = K.star);
      }
      // підписи
      final lo = pt(i, 112);
      final tp = TextPainter(
        text: TextSpan(children: [
          TextSpan(text: '${items[i].$1}\n', style: rw(11, w: FontWeight.w500, color: i == weak ? K.accSoft : K.muted)),
          TextSpan(text: fmt(items[i].$2), style: rw(11, w: i == weak ? FontWeight.w600 : FontWeight.w500, color: i == weak ? K.accSoft : K.star)),
        ]),
        textAlign: lo.dx < ctr.dx - 5 ? TextAlign.right : lo.dx > ctr.dx + 5 ? TextAlign.left : TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = lo.dx < ctr.dx - 5 ? lo.dx - tp.width : lo.dx > ctr.dx + 5 ? lo.dx : lo.dx - tp.width / 2;
      final dy = lo.dy < ctr.dy - 60 ? lo.dy - tp.height : lo.dy > ctr.dy + 60 ? lo.dy : lo.dy - tp.height / 2;
      tp.paint(c, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter o) => o.k != k || o.items != items;
}

// ---------- Поділитися ----------
void _shareSheet(BuildContext context, {required double idx, required List<Effect> pos, required List<Effect> neg}) {
  var safe = true;
  String text() {
    final b = StringBuffer('Моя мапа у Vespr\n');
    if (safe) {
      if (pos.isNotEmpty) b.writeln('Мені добре, коли є ${_join(pos.take(3).map(niceNoun).toList())}.');
      if (neg.isNotEmpty) b.writeln('${cap(niceNoun(neg.first))} мене вимикає.');
    } else {
      b.writeln('Індекс задоволення ${fmt(idx)} з 5');
      for (final e in [...pos.take(3), ...neg.take(2)]) {
        b.writeln('${niceLabel(e)}: ${_sgn(e.delta)}');
      }
    }
    return b.toString().trim();
  }

  Future<void> go2(BuildContext ctx) async {
    final t = text();
    Navigator.pop(ctx);
    try {
      await Share.share(t);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: t));
      if (context.mounted) dToast(context, 'Скопійовано');
    }
  }

  showSheet(context, (ctx) => StatefulBuilder(
        builder: (ctx, set) => Sheet(children: [
          Text('Поділитися', style: pr(24, h: 1.15)),
          Text('Коротко про твою мапу. Записів і людей не видно.', style: rw(13, color: K.muted, h: 1.45)),
          Press(
            onTap: () => set(() => safe = !safe),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.07))),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Безпечна версія', style: rw(15, w: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('Без імен, оцінок і деталей', style: rw(12, color: K.muted)),
                  ]),
                ),
                IgnorePointer(child: Sw(on: safe, onChanged: (_) {}, label: 'Безпечна версія')),
              ]),
            ),
          ),
          Press(
            onTap: () => go2(ctx),
            child: Container(height: 54, decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text('Поділитися', style: rw(15, color: K.bg, w: FontWeight.w600))),
          ),
          Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Скасувати', style: rw(15, w: FontWeight.w600))))),
        ]),
      ));
}

// =====================================================================
// MapEarly: мало записів
// =====================================================================
class _MapEarly extends StatelessWidget {
  final List<Entry> entries;
  const _MapEarly({required this.entries});

  /// Перші спостереження: тег, з яким оцінка найвища / найнижча (≥2 записи)
  (String, String)? _obs(bool up) {
    if (entries.length < 3) return null;
    final all = avg(entries.map((e) => e.overall));
    String? bestId;
    var bestD = 0.0;
    var n = 0;
    final ids = entries.expand((e) => e.tags).toSet();
    for (final id in ids) {
      if (!_nice.containsKey(id)) continue;
      final xs = entries.where((e) => e.tags.contains(id)).map((e) => e.overall).toList();
      if (xs.length < 2) continue;
      final d = avg(xs) - all;
      if (up ? d > bestD + 1e-9 : d < bestD - 1e-9) {
        bestD = d;
        bestId = id;
        n = xs.length;
      }
    }
    if (bestId == null || bestD.abs() < .3) return null;
    final noun = _nice[bestId]!.$2;
    return up ? ('', noun) : ('$n', noun);
  }

  @override
  Widget build(BuildContext context) {
    final n = entries.length;
    final ppl = entries.map((e) => e.personId).toSet().length;
    final up = _obs(true), dn = _obs(false);
    final left = _full - n;
    return Stack(children: [
      const Positioned(left: -80, top: -40, child: EGlow(w: 550, h: 520, colors: [Color(0x21F08A6C), Color(0x0017161F)], stops: [0, .65])),
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            Rise(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Мапа', style: pr(36, h: 1)),
                const SizedBox(height: 8),
                Text(n == 0 ? 'поки без записів' : 'з $n ${plural(n, 'запису', 'записів', 'записів')} · $ppl ${plural(ppl, 'людина', 'людини', 'людей')}', style: _cap()),
              ]),
            ),
            Rise(
              delay: .12,
              child: _shell(
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border(top: BorderSide(color: K.w(.08))),
                    gradient: onBase(RadialGradient(center: Alignment.topLeft, radius: 1.2, colors: [K.a(.14), K.a(0)], stops: const [0, .6]), K.card2)),
                  child: Row(children: [
                    _MiniSky(lit: math.min(n, _full)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Ще ${_recs(left)} до повної мапи', style: pr(20, h: 1.2)),
                        const SizedBox(height: 10),
                        Row(children: gapped([
                          for (var i = 0; i < _full; i++)
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  border: i < n ? null : Border.all(color: K.w(.14)),
                                  gradient: onBase(i < n ? const LinearGradient(colors: [Color(0xFFF6A890), K.acc]) : null, i < n ? null : Colors.transparent),
                                  boxShadow: i < n ? [BoxShadow(color: K.a(.45), blurRadius: 10)] : null),
                              ),
                            ),
                        ], 4, horizontal: true)),
                        const SizedBox(height: 10),
                        Text("Зірки сузір'я загоряються з кожним записом", style: _cap().copyWith(height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            if (up != null || dn != null) ...[
              Rise(
                delay: .24,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.fromLTRB(10, 0, 11, 0),
                    decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.08))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: K.acc, boxShadow: [BoxShadow(color: K.a(.7), blurRadius: 8)])),
                      const SizedBox(width: 7),
                      Text('на $n ${plural(n, 'записі', 'записах', 'записах')}', style: rw(11, color: K.soft, w: FontWeight.w500, ls: .2)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('Перші спостереження', style: pr(24, h: 1.15)),
                ]),
              ),
              Rise(
                delay: .24,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(30), border: Border.all(color: K.w(.06))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
                    if (up != null) _Obs(up: true, k: 'Що тебе вмикає', parts: [('Коли є ', false), (up.$2, true), (', тобі найкраще.', false)]),
                    if (dn != null) _Obs(up: false, k: 'Що тебе вимикає', parts: [(cap(dn.$2), true), (' ${dn.$1 == '2' ? 'обидва рази' : '${dn.$1} рази'} знижував оцінку.', false)]),
                  ], 6)),
                ),
              ),
            ] else
              Rise(
                delay: .24,
                child: Text(n < 3 ? 'Після трьох записів тут з’являться перші спостереження.' : 'Поки нічого не вибивається. Відмічай у записі, що було перед і як, так мапа швидше знайде твоє.', style: rw(13, color: K.soft, h: 1.45)),
              ),
            Rise(
              delay: .36,
              child: _shell(
                Container(
                  constraints: const BoxConstraints(minHeight: 72),
                  decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(24), border: Border(top: BorderSide(color: K.w(.08)))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: .45,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [_bar(90, 10, const Color(0xFF3A3548)), const SizedBox(width: 10), _bar(120, 12, K.acc)]),
                                const SizedBox(height: 10),
                                Row(children: [_bar(70, 10, const Color(0xFF3A3548)), const SizedBox(width: 10), _bar(80, 12, K.haze)]),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xEB25222F), Color(0x6625222F)], stops: [.3, 1])),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: K.a(.12), border: Border.all(color: K.a(.32)), boxShadow: [BoxShadow(color: K.a(.25), blurRadius: 18)]),
                            alignment: Alignment.center,
                            child: const Ico(_icLock, size: 16, color: K.accSoft),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Що вмикає і вимикає', style: rw(14, w: FontWeight.w500)),
                              const SizedBox(height: 3),
                              Text('Відкриється після $_full записів', style: rw(12, color: K.muted)),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ], 14)),
        ),
      ),
    ]);
  }

  static Widget _bar(double w, double h, Color c) => Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h / 2)));
  static Widget _shell(Widget child) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(30), border: Border.all(color: K.w(.06))),
        child: child,
      );
}

class _Obs extends StatelessWidget {
  final bool up;
  final String k;
  final List<(String, bool)> parts;
  const _Obs({required this.up, required this.k, required this.parts});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border(top: BorderSide(color: up ? const Color(0x59F4A189) : K.w(.07))),
          gradient: onBase(RadialGradient(center: Alignment.topRight, radius: 1.3, colors: [(up ? K.acc : K.haze).withValues(alpha: up ? .17 : .13), (up ? K.acc : K.haze).withValues(alpha: 0)], stops: const [0, .62]), K.card2),
          boxShadow: const [BoxShadow(color: Color(0xE609080E), blurRadius: 28, offset: Offset(0, 16), spreadRadius: -18)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Ico(up ? _icStarFill : _icStarLine, size: 12, color: up ? K.acc : K.haze), const SizedBox(width: 8), Text(k, style: rw(12, color: K.muted2, w: FontWeight.w500, ls: .12))]),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [for (final p in parts) TextSpan(text: p.$1, style: p.$2 ? TextStyle(color: up ? K.accSoft : K.soft) : null)]), style: pr(21, h: 1.32, ls: -.012)),
        ]),
      );
}

/// Маленьке сузір'я 112×112: зірки загоряються з кожним записом
class _MiniSky extends StatelessWidget {
  final int lit;
  const _MiniSky({required this.lit});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        builder: (_, t, __) => CustomPaint(size: const Size(112, 112), painter: _MiniSkyPainter(lit, t)),
      );
}

class _MiniSkyPainter extends CustomPainter {
  final int lit;
  final double t;
  _MiniSkyPainter(this.lit, this.t);
  static const pts = [Offset(26, 34), Offset(62, 22), Offset(58, 62), Offset(90, 52), Offset(34, 86), Offset(84, 92)];
  static const rs = [6.0, 5.0, 4.5, 4.0, 4.0, 4.0];
  static const links = [(0, 1), (1, 2), (2, 3), (2, 4), (2, 5)];
  @override
  void paint(Canvas c, Size s) {
    for (final (a, b) in links) {
      final on = a < lit && b < lit;
      final p = Paint()
        ..strokeWidth = 1
        ..color = on ? K.acc.withValues(alpha: .5) : K.w(.25);
      if (on) {
        c.drawLine(pts[a], pts[b], p);
      } else {
        final d = pts[b] - pts[a];
        final len = d.distance;
        for (var x = 0.0; x < len; x += 7) {
          c.drawLine(pts[a] + d * (x / len), pts[a] + d * (math.min(x + 3, len) / len), p);
        }
      }
    }
    for (var i = 0; i < pts.length; i++) {
      if (i < lit) {
        final k = Curves.easeOutBack.transform(((t - i * .1) / .5).clamp(0.0, 1.0));
        if (i == 0) c.drawCircle(pts[i], 14 * k, Paint()..color = K.acc.withValues(alpha: .3));
        c.drawCircle(pts[i], rs[i] * k, Paint()..color = K.acc);
      } else {
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = K.w(.4);
        for (var a = 0.0; a < 2 * math.pi; a += math.pi / 4) {
          c.drawArc(Rect.fromCircle(center: pts[i], radius: 4), a, math.pi / 8, false, p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MiniSkyPainter o) => o.t != t || o.lit != lit;
}

// =====================================================================
// MyArcana
// =====================================================================
class MyArcanaScreen extends StatefulWidget {
  const MyArcanaScreen({super.key});
  @override
  State<MyArcanaScreen> createState() => _MyArcanaScreenState();
}

class _MyArcanaScreenState extends State<MyArcanaScreen> {
  String tab = 'char';

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final a = astroOf(s.profile.birth);
    final arc = a?.arc;
    final more = arc == null ? null : arcanaMore[arc];
    // збіг з мапою: топ-фактор у записах
    final eff = s.entries.length >= _full ? effects(s.entries).where((e) => e.delta > 0).toList() : <Effect>[];

    Widget box({required String title, required String text, String? icon, bool plus = false, bool minus = false}) => Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border(top: BorderSide(color: K.w(.08))),
            gradient: onBase(minus ? null : RadialGradient(center: Alignment.topRight, radius: 1.2, colors: [K.a(plus ? .2 : .14), K.a(0)], stops: const [0, .65]), K.card2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (plus || minus)
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: plus ? K.acc : null, border: minus ? Border.all(color: K.soft.withValues(alpha: .45)) : null, boxShadow: plus ? [BoxShadow(color: K.a(.55), blurRadius: 10)] : null),
                  alignment: Alignment.center,
                  child: Text(plus ? '+' : '−', style: rw(14, color: plus ? K.bg : K.soft, w: FontWeight.w600, h: 1)),
                )
              else if (icon != null)
                Ico(icon, size: 13, color: K.acc),
              const SizedBox(width: 8),
              Text(title, style: rw(12, color: plus ? K.accSoft : K.muted, w: FontWeight.w500, ls: .24)),
            ]),
            const SizedBox(height: 8),
            Text(text, style: rw(14, color: const Color(0xFFE6E2EB), h: 1.55)),
          ]),
        );

    return DFrame(
      builder: (context, h) => Stack(children: [
        const Positioned(left: 45, top: 90, child: Glow(w: 300, h: 340, colors: [Color(0x47F08A6C), Color(0x0017161F)], stops: [0, .65], circle: true)),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h - 80),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                  height: 44,
                  child: Stack(alignment: Alignment.center, children: [
                    Text('Мій аркан', style: rw(15, w: FontWeight.w700)),
                    const Align(alignment: Alignment.centerLeft, child: BackBtn()),
                  ]),
                ),
                const SizedBox(height: 16),
                if (a == null || arc == null || more == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('Додай свою дату народження в налаштуваннях, і тут з’явиться твій аркан.', textAlign: TextAlign.center, style: rw(14, color: K.soft, h: 1.5)),
                  )
                else ...[
                  Center(child: _TarotCard(roman: roman[arc], name: arcana[arc].name, top: '${a.signName.toUpperCase()} · ${a.el.toUpperCase()}')),
                  const SizedBox(height: 16),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(arcana[arc].core, textAlign: TextAlign.center, style: pr(19, h: 1.35))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.07))),
                    child: Row(children: [
                      for (final t in [('char', 'Характер'), ('love', 'Кохання'), ('bed', 'У ліжку')])
                        Expanded(
                          child: Semantics(
                            selected: tab == t.$1,
                            button: true,
                            child: Press(
                              onTap: () => setState(() => tab = t.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: easeD,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: tab == t.$1 ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                                child: Text(t.$2, style: rw(14, color: tab == t.$1 ? K.bg : K.muted2, w: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: KeyedSubtree(
                      key: ValueKey(tab),
                      child: tab == 'char'
                          ? IntrinsicHeight(
                              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                Expanded(child: box(title: 'У плюсі', text: more.plus, plus: true)),
                                const SizedBox(width: 10),
                                Expanded(child: box(title: 'У мінусі', text: more.minus, minus: true)),
                              ]),
                            )
                          : tab == 'love'
                              ? box(title: 'Кохання', text: arcana[arc].love, icon: _icHeart)
                              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  box(title: 'Ти в ліжку', text: more.bed, icon: _icMoon),
                                  if (eff.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(color: K.a(.08), borderRadius: BorderRadius.circular(22), border: Border.all(color: K.a(.3))),
                                      child: Row(children: [
                                        const Ico(_icStarFill, size: 20, color: K.acc),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text('А твої записи кажуть: ${niceNoun(eff.first)} в топі того, що працює.', style: rw(13, h: 1.4))),
                                      ]),
                                    ),
                                  ],
                                ]),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TarotCard extends StatelessWidget {
  final String roman, name, top;
  const _TarotCard({required this.roman, required this.name, required this.top});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: const Interval(.08, 1, curve: Cubic(.34, 1.3, .64, 1)),
        builder: (_, k, child) => Opacity(
          opacity: k.clamp(0, 1),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 1 / 700)
              ..rotateY((1 - k) * -22 * math.pi / 180)
              ..translate(0.0, (1 - k) * 14),
            child: child,
          ),
        ),
        child: Container(
          width: 176, height: 264,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: K.w(.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: K.w(.08)),
            boxShadow: [BoxShadow(color: K.a(.35), blurRadius: 60, offset: const Offset(0, 34), spreadRadius: -26), const BoxShadow(color: Color(0xCC08070C), blurRadius: 50, offset: Offset(0, 24), spreadRadius: -24)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment(-.3, -1), end: Alignment(.3, 1), colors: [Color(0xFF36314A), Color(0xFF25222F), Color(0xFF33262F)], stops: [0, .55, 1])),
              child: Stack(children: [
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.16), radius: .9, colors: [K.a(.22), K.a(0)], stops: const [0, .6])))),
                Positioned.fill(child: CustomPaint(painter: _RaysPainter())),
                Positioned.fill(child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: K.a(.4))))),
                Positioned.fill(child: Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), border: Border.all(color: K.a(.14))))),
                for (final al in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
                  Align(alignment: al, child: Padding(padding: const EdgeInsets.all(16), child: Ico(_icStarFill, size: 7, color: K.acc.withValues(alpha: .8)))),
                Positioned.fill(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 22, 10, 20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(top, style: rw(11, color: K.muted, w: FontWeight.w600, ls: 1.5)),
                    Column(children: [
                      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: K.a(.6), blurRadius: 12)], shape: BoxShape.circle), child: const Ico(_icStarFill, size: 22, color: K.acc)),
                      const SizedBox(height: 10),
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Colors.white, Color(0xFFEBC2B4)], stops: [0, .35, 1]).createShader(r),
                        child: Text(roman, style: pr(58, h: 1, color: Colors.white)),
                      ),
                    ]),
                    Text(name, textAlign: TextAlign.center, style: pr(20)),
                  ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height * .44);
    final p = Paint()
      ..strokeWidth = .6
      ..shader = RadialGradient(colors: [K.accSoft.withValues(alpha: .25), K.accSoft.withValues(alpha: 0)], stops: const [.25, 1]).createShader(Rect.fromCircle(center: ctr, radius: 70));
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      c.drawLine(ctr, ctr + Offset(math.cos(a), math.sin(a)) * 70, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter o) => false;
}
