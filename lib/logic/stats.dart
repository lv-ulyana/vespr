// Уся аналітика — звичайна арифметика на телефоні. Правила з документа «логіка аналізу».
import '../data/catalog.dart';
import '../data/models.dart';
import 'dates.dart';

double avg(Iterable<num> xs) {
  if (xs.isEmpty) return double.nan;
  var s = 0.0;
  for (final x in xs) {
    s += x;
  }
  return s / xs.length;
}

String? levelFor(int n) => n >= 10 ? 'Точно' : n >= 6 ? 'Закономірність' : n >= 3 ? 'Схоже' : null;

class Effect {
  final String id, label, group, level, kind; // kind: tag | flag | fact
  final double delta;
  final int nWith, nWithout;
  const Effect(this.id, this.label, this.group, this.kind, this.delta, this.nWith, this.nWithout, this.level);
}

/// Ефект тегу: середнє «Як загалом?» з тегом мінус без нього.
/// Показуємо, якщо в меншій групі ≥3 записи і |Δ| ≥ 0,5.
List<Effect> effects(List<Entry> entries) {
  final out = <Effect>[];
  void push(String id, String label, String group, String kind, List<Entry> withE, List<Entry> withoutE) {
    final n = withE.length < withoutE.length ? withE.length : withoutE.length;
    final lv = levelFor(n);
    if (lv == null) return;
    final d = avg(withE.map((e) => e.overall)) - avg(withoutE.map((e) => e.overall));
    if (d.abs() < 0.5) return;
    out.add(Effect(id, label, group, kind, d, withE.length, withoutE.length, lv));
  }

  // осі: один бік проти другого; записи без цієї осі не рахуються
  for (final ax in axes) {
    final a = ax.a.map((o) => o.id).toSet(), b = ax.b.map((o) => o.id).toSet();
    final ea = entries.where((e) => e.tags.any(a.contains)).toList();
    final eb = entries.where((e) => e.tags.any(b.contains)).toList();
    for (final o in ax.all) {
      final mine = entries.where((e) => e.tags.contains(o.id)).toList();
      push(o.id, o.label, ax.group, 'tag', mine, a.contains(o.id) ? eb : ea);
    }
  }
  // теги без пари: тільки серед записів, де блок заповнений
  for (final s in solos) {
    final ids = s.tags.map((t) => t.id).toSet();
    final filled = entries.where((e) => e.tags.any(ids.contains)).toList();
    for (final t in s.tags) {
      push(t.id, t.label, s.group, 'tag', filled.where((e) => e.tags.contains(t.id)).toList(), filled.where((e) => !e.tags.contains(t.id)).toList());
    }
  }
  // прапорці (без критичних)
  for (final f in flags.where((f) => f.kind != FlagKind.c)) {
    push(f.id, f.label, 'Прапорці', 'flag', entries.where((e) => e.flags.contains(f.id)).toList(), entries.where((e) => !e.flags.contains(f.id)).toList());
  }
  // факти: кожна позиція як окремий тег
  for (final f in facts) {
    final filled = entries.where((e) => e.facts.containsKey(f.id)).toList();
    for (var i = 0; i < f.steps.length; i++) {
      push('${f.id}:$i', '${f.label}: ${f.steps[i]}', f.label, 'fact', filled.where((e) => e.facts[f.id] == i).toList(), filled.where((e) => e.facts[f.id] != i).toList());
    }
  }
  out.sort((x, y) => y.delta.abs().compareTo(x.delta.abs()));
  return out;
}

/// Формула ідеального вечора: топ-3 позитивні теги з різних груп, від «Закономірність»
List<Effect> formula(List<Effect> eff) {
  final res = <Effect>[];
  final groups = <String>{};
  for (final e in eff.where((x) => x.delta > 0 && x.kind == 'tag' && x.level != 'Схоже')) {
    if (groups.contains(e.group)) continue;
    groups.add(e.group);
    res.add(e);
    if (res.length == 3) break;
  }
  return res;
}

List<Entry> entriesOf(List<Entry> all, String personId) => all.where((e) => e.personId == personId).toList()..sort((a, b) => a.date.compareTo(b.date));

class FlagCount {
  final String id, label;
  final FlagKind kind;
  final int n;
  const FlagCount(this.id, this.label, this.kind, this.n);
}

class PersonStats {
  final int n, sexN, orgMe, orgHim, orgN, fake;
  final double overall, sex, him, redPerMeet;
  final List<FlagCount> flagCounts;
  final String? trend; // up | down
  final double? gap; // секс мінус «він», якщо |різниця| ≥ 1
  final String? first, last;
  const PersonStats({
    required this.n, required this.sexN, required this.orgMe, required this.orgHim, required this.orgN, required this.fake,
    required this.overall, required this.sex, required this.him, required this.redPerMeet, required this.flagCounts,
    this.trend, this.gap, this.first, this.last,
  });
  int get green => flagCounts.where((f) => f.kind == FlagKind.g).fold(0, (s, f) => s + f.n);
  int get red => flagCounts.where((f) => f.kind == FlagKind.r).fold(0, (s, f) => s + f.n);
}

PersonStats personStats(List<Entry> all, String personId) {
  final es = entriesOf(all, personId);
  final sexEs = es.where((e) => e.hadSex).toList();
  final sex = avg(sexEs.map((e) => e.ratings['sx_overall'] ?? e.overall));
  final him = avg(es.expand((e) => e.ratings.entries.where((r) => r.key.startsWith('pt_')).map((r) => r.value)));
  final fc = <String, int>{};
  for (final e in es) {
    for (final f in e.flags) {
      fc[f] = (fc[f] ?? 0) + 1;
    }
  }
  final counts = fc.entries.map((x) {
    final f = flagById(x.key);
    return FlagCount(x.key, f?.label ?? x.key, f?.kind ?? FlagKind.r, x.value);
  }).toList()
    ..sort((a, b) => b.n.compareTo(a.n));
  var redW = 0;
  for (final e in es) {
    for (final id in e.flags) {
      final f = flagById(id);
      if (f != null && f.kind != FlagKind.g) redW += f.weight;
    }
  }
  String? trend;
  if (es.length >= 6) {
    final last3 = avg(es.sublist(es.length - 3).map((e) => e.overall));
    final prev3 = avg(es.sublist(es.length - 6, es.length - 3).map((e) => e.overall));
    if (last3 - prev3 >= 0.5) trend = 'up';
    if (prev3 - last3 >= 0.5) trend = 'down';
  }
  final withO = sexEs.where((e) => e.tags.any(const {'o_me', 'o_multi', 'o_none_ok', 'o_none_sad'}.contains)).toList();
  final withH = sexEs.where((e) => e.tags.any(const {'o_him', 'o_him_no'}.contains)).toList();
  return PersonStats(
    n: es.length,
    sexN: sexEs.length,
    overall: avg(es.map((e) => e.overall)),
    sex: sex,
    him: him,
    orgMe: withO.where((e) => e.tags.contains('o_me') || e.tags.contains('o_multi')).length,
    orgHim: withH.where((e) => e.tags.contains('o_him')).length,
    orgN: withO.length,
    fake: sexEs.where((e) => e.tags.contains('o_fake')).length,
    flagCounts: counts,
    redPerMeet: es.isEmpty ? 0 : redW / es.length,
    trend: trend,
    gap: sex.isFinite && him.isFinite && (sex - him).abs() >= 1 ? sex - him : null,
    first: es.isEmpty ? null : es.first.date,
    last: es.isEmpty ? null : es.last.date,
  );
}

/// Сигнал безпеки обходить усі пороги
bool isUnsafe(Entry e) => e.flags.any((f) => flagById(f)?.kind == FlagKind.c) || (e.tags.contains('stop') && e.flags.contains('flag_r_push'));

class ShameRow {
  final Person person;
  final int meets, red;
  final double rate;
  const ShameRow(this.person, this.meets, this.red, this.rate);
}

/// Зала ганьби: вага червоних прапорців на зустріч (критичні сюди не йдуть)
List<ShameRow> hallOfShame(List<Person> people, List<Entry> entries) {
  final rows = <ShameRow>[];
  for (final p in people) {
    final es = entriesOf(entries, p.id);
    if (es.isEmpty) continue;
    final red = es.expand((e) => e.flags.where((f) => flagById(f)?.kind == FlagKind.r)).toList();
    final w = red.fold<int>(0, (s, f) => s + (flagById(f)?.weight ?? 0));
    rows.add(ShameRow(p, es.length, red.length, w / es.length));
  }
  rows.sort((a, b) => b.rate.compareTo(a.rate));
  return rows;
}

int entriesInMonth(List<Entry> entries, String month, {String? exceptId}) =>
    entries.where((e) => monthKey(e.date) == month && e.id != exceptId).length;
