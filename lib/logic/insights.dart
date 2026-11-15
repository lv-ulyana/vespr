// «Твоя мапа каже» на головній: щодня інше спостереження, але тільки з того,
// що справді є в записах (ті самі пороги, що й на мапі). Імена не відмінюємо:
// ім'я завжди стоїть першим, через двокрапку.
import '../data/catalog.dart';
import '../data/models.dart';
import 'dates.dart';
import 'stats.dart';

String _x(int n) => '$n ${plural(n, 'раз', 'рази', 'разів')}';
const _wdAcc = ['понеділок', 'вівторок', 'середу', 'четвер', 'пʼятницю', 'суботу', 'неділю'];

/// Усі правдиві спостереження на зараз, від найсильніших
List<String> homeInsights(List<Person> people, List<Entry> entries) {
  final out = <String>[];
  final eff = effects(entries);
  final f = formula(eff);
  if (f.length == 3) out.add('Твій ідеальний вечір: ${f[0].label.toLowerCase()}, ${f[1].label.toLowerCase()} і ${f[2].label.toLowerCase()}.');

  // найсильніші фактори: два вгору, два вниз
  final ups = eff.where((e) => e.delta > 0).take(2).toList();
  final downs = eff.where((e) => e.delta < 0).take(2).toList();
  for (final (i, e) in ups.indexed) {
    out.add(i.isEven ? '«${e.label}»: плюс ${fmt(e.delta)} до вечора. Схоже, це твоє.' : '«${e.label}» піднімає вечір на ${fmt(e.delta)}. Цифри не брешуть.');
  }
  for (final (i, e) in downs.indexed) {
    out.add(i.isEven ? '«${e.label}»: мінус ${fmt(-e.delta)} до вечора, і вже ${_x(e.nWith)}.' : '«${e.label}» опускає вечір на ${fmt(-e.delta)}. Варто помітити.');
  }

  // день тижня: щонайменше 3 записи в цей день і різниця від 0,5
  if (entries.length >= 6) {
    final all = avg(entries.map((e) => e.overall));
    int? best;
    var bestV = 0.0;
    for (var d = 0; d < 7; d++) {
      final xs = entries.where((e) => parseIso(e.date).weekday - 1 == d).map((e) => e.overall).toList();
      if (xs.length < 3) continue;
      final v = avg(xs);
      if (v - all >= .5 && v > bestV) {
        best = d;
        bestV = v;
      }
    }
    if (best != null) out.add('Найкраще тобі ${best == 1 ? 'у' : 'в'} ${_wdAcc[best]}: в середньому ${fmt(bestV)} проти ${fmt(all)}.');
  }

  // люди: тільки нинішні
  for (final p in people.where((p) => !p.isPast)) {
    final st = personStats(entries, p.id);
    if (st.n < 3) continue;
    if (st.trend == 'up') out.add('${p.name}: останні три зустрічі кращі за попередні три. Росте.');
    if (st.trend == 'down') out.add('${p.name}: останні три зустрічі слабші за попередні три. Це вже не випадковість.');
    final g = st.gap;
    if (g != null && g > 0) out.add('${p.name}: у ліжку ${fmt(st.sex)}, а як людина ${fmt(st.him)}. Тілу добре, голові менше.');
    if (g != null && g < 0) out.add('${p.name}: як людина ${fmt(st.him)}, а в ліжку поки ${fmt(st.sex)}.');
    for (final fc in st.flagCounts.where((x) => x.n >= 3).take(1)) {
      if (fc.kind == FlagKind.g) out.add('${p.name}, «${fc.label}»: уже ${_x(fc.n)}. Це характер, а не випадок.');
      if (fc.kind == FlagKind.r) out.add('${p.name}, «${fc.label}»: уже ${_x(fc.n)}. Ти це бачиш, і мапа теж.');
    }
  }
  return out;
}

/// Одне спостереження на сьогодні (не стрибає впродовж дня)
String? insightOfDay(List<Person> people, List<Entry> entries, [DateTime? now]) {
  final xs = homeInsights(people, entries);
  if (xs.isEmpty) return null;
  final d = now ?? DateTime.now();
  final day = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2026)).inDays;
  return xs[day % xs.length];
}
