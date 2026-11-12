import 'package:flutter/material.dart';

import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../logic/texts.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'entry.dart';
import 'settings.dart';

const _freeEffects = 2;

class MapTab extends StatefulWidget {
  const MapTab({super.key});
  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  String period = 'all'; // 3 | 6 | all

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    if (s.entries.length < 3) {
      return Screen(children: [
        const H1("Сузір'я", accent: 'твого задоволення'),
        const Txt('Після трьох записів Vespr покаже закономірності, яких ти не помічала.', muted: true),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.auto_awesome, size: 34, color: i < s.entries.length ? C.accent : C.dim)),
          ]),
        ),
        Txt(fewText(3 - s.entries.length), muted: true, align: TextAlign.center),
        Btn('Записати', onTap: () => go(context, const EntryForm())),
      ]);
    }
    final from = period == 'all' ? null : addDays(today(), -int.parse(period) * 30);
    final es = s.entries.where((e) => from == null || e.date.compareTo(from) >= 0).toList();
    final eff = effects(es);
    final f = formula(eff);
    final ppl = es.map((e) => e.personId).toSet().length;
    final visible = s.profile.premium ? eff : eff.take(_freeEffects).toList();
    final monthAgo = addDays(today(), -30);
    final recent = avg(s.entries.where((e) => e.date.compareTo(monthAgo) >= 0).map((e) => e.overall));
    final before = avg(s.entries.where((e) => e.date.compareTo(monthAgo) < 0).map((e) => e.overall));

    return Screen(children: [
      Txt('Мапа з ${es.length} ${plural(es.length, 'запису', 'записів', 'записів')} · $ppl ${plural(ppl, 'людина', 'людини', 'людей')}', small: true, muted: true),
      const H1("Сузір'я", accent: 'твого задоволення'),
      Seg<String>(options: const [SegOpt('3', '3 місяці'), SegOpt('6', '6 місяців'), SegOpt('all', 'Увесь час')], value: period, onChange: (v) => setState(() => period = v)),
      VCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Txt('Індекс задоволення · останні 30 днів', small: true, muted: true),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmt(recent), style: T.serif(40)),
            const SizedBox(width: 10),
            if (recent.isFinite && before.isFinite)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('${recent >= before ? '▲' : '▼'} ${d1(recent - before)} до попереднього', style: T.body(13, recent >= before ? C.green : C.red, FontWeight.w600)),
              ),
          ]),
        ]),
      ),
      if (f.isNotEmpty)
        VCard(
          color: C.warm,
          border: const Color(0x40F08A6C),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✦ Формула твого вечора', style: T.body(12, C.accentSoft, FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              f.length == 3 ? say('formula', {'t1': f[0].label.toLowerCase(), 't2': f[1].label.toLowerCase(), 't3': f[2].label.toLowerCase()}) : f.map((x) => x.label).join(' + '),
              style: T.serif(19).copyWith(height: 1.4),
            ),
          ]),
        ),
      const Label('Що вмикає і вимикає'),
      const Txt('Наскільки «Як загалом?» вище чи нижче, ніж зазвичай. Показуємо, тільки коли є щонайменше 3 записи з обох боків.', small: true, muted: true),
      if (eff.isEmpty) const VCard(child: Txt('Поки нічого не вибивається більше ніж на 0,5. Записуй з деталями — так мапа швидше знайде твоє.', muted: true)),
      for (final x in visible)
        VCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.label, style: T.body(14, C.text, FontWeight.w600)),
                Txt('${x.level} · ${x.nWith} проти ${x.nWithout}', small: true, muted: true),
              ]),
            ),
            Text('${x.delta > 0 ? '+' : '−'}${d1(x.delta)}', style: T.serif(22, x.delta > 0 ? C.green : C.red)),
          ]),
        ),
      if (!s.profile.premium && eff.length > _freeEffects)
        VCard(
          border: C.accent,
          onTap: () => go(context, const PaywallScreen()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ще ${eff.length - _freeEffects} закономірностей', style: T.body(15, C.text, FontWeight.w600)),
            const Txt('Повна мапа відкривається з Premium ›', small: true, muted: true),
          ]),
        ),
    ]);
  }
}
