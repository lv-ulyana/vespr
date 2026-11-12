// 33 нагороди з дошки Achievements. Кожна рахується з записів, людей і лічильників подій.
import 'dart:math' as math;

import '../data/catalog.dart';
import '../data/models.dart';
import 'astro.dart';
import 'dates.dart';

class AchDef {
  final String id, name, desc;
  final bool shame;
  final List<int> th;
  final (String, String, String)? unit; // одиниця для «ще N …»
  const AchDef(this.id, this.name, this.desc, this.shame, this.th, [this.unit]);
}

const achDefs = <AchDef>[
  AchDef('rake', 'Граблі', 'Той самий червоний прапорець у різних людей. Хлопці різні, історія та сама.', true, [1, 2, 3, 5, 10]),
  AchDef('gold', 'Золотий стандарт', "Вечори поспіль на 5. Запам'ятай, як це.", false, [3, 5, 10], ('вечір', 'вечори', 'вечорів')),
  AchDef('boomerang', 'Бумеранг', 'Повернула людину з минулих. Ми попереджали.', true, [1, 2, 3]),
  AchDef('nomaybe', 'Без «а раптом»', 'Відправила в минулі одразу після поганої зустрічі.', false, [1]),
  AchDef('blind', 'Сліпа зона', 'Червоні прапорці, після яких ти все одно пішла далі.', true, [3, 5, 10]),
  AchDef('astro', 'Астрологиня', 'Різні знаки зодіаку. Науковий підхід.', false, [4, 8, 12], ('знак', 'знаки', 'знаків')),
  AchDef('ghosted', 'Ghosted', 'Перенесла в минулі з причиною «Він зник».', true, [1, 3, 5]),
  AchDef('maybe', 'Ну а раптом', 'Знову зустрілась з тим, кого оцінила на 1–2.', true, [1, 3]),
  AchDef('redcolor', 'Червоний — мій колір', 'Червоних прапорців більше, ніж зелених, а оцінка 4+.', true, [1]),
  AchDef('sport', 'Спортивний інтерес', 'Три «Одна ніч» за місяць.', true, [3]),
  AchDef('nightmore', 'Ніч з продовженням', '«Одна ніч» переросла в 4+ зустрічі. Відкривається після «Спортивного інтересу».', false, [4], ('зустріч', 'зустрічі', 'зустрічей')),
  AchDef('ex', 'Колишній — теж людина', 'Додала когось з типом «Колишній».', true, [1, 2, 3]),
  AchDef('confess', 'Остання сповідь', 'Запис о 3-й ночі.', true, [1]),
  AchDef('love', 'Хтось тут закохався', '5 зустрічей з однією людиною за 2 тижні.', false, [5], ('зустріч', 'зустрічі', 'зустрічей')),
  AchDef('oscar', 'Оскар', 'Позначила «Вдавала» в записі.', true, [1, 3, 5]),
  AchDef('happy', 'Хеппі-енд', 'Кінчала. Позначено в записі.', false, [1, 5, 10]),
  AchDef('saiddone', 'Сказала і зробила', 'Бажання «до зустрічі» позначене «Вийшло».', false, [1, 5, 10]),
  AchDef('green', 'Зелене світло', 'Зустріч з 3+ зеленими прапорцями.', false, [3, 5, 10], ('зустріч', 'зустрічі', 'зустрічей')),
  AchDef('clean', 'Чиста історія', '5 зустрічей поспіль без червоних прапорців.', false, [5], ('зустріч', 'зустрічі', 'зустрічей')),
  AchDef('gentleman', 'Кавалер', 'Провів, заплатив і прийшов вчасно в одну зустріч.', false, [1]),
  AchDef('hotweek', 'Гарячий тиждень', '5 записів за тиждень, 8 за два, 12 за місяць.', false, [5, 8, 12], ('запис', 'записи', 'записів')),
  AchDef('comeback', 'Повернення героїні', 'Запис після 30+ днів тиші.', false, [1]),
  AchDef('newyear', 'Новорічна', 'Запис 31 грудня або 1 січня.', false, [1]),
  AchDef('elements', 'Стихійне лихо', 'Усі 4 стихії зодіаку.', false, [4], ('стихія', 'стихії', 'стихій')),
  AchDef('stars', 'Зірки зійшлись', 'Метч «легко» і зустріч на 5.', false, [1]),
  AchDef('hardcore', 'Хардкор', 'Три Скорпіони поспіль.', true, [3]),
  AchDef('bar', 'Барна душа', 'Зустрічі в барі.', false, [5, 10], ('зустріч', 'зустрічі', 'зустрічей')),
  AchDef('thumbelina', 'Дюймовочка', 'Три людини з розміром «Скромно».', false, [3]),
  AchDef('giant', 'Гігантоманія', 'Три людини з розміром «Гігант».', false, [3]),
  AchDef('revision', 'Ревізія', 'Переглянула картку колишнього 3 рази за тиждень.', true, [3]),
  AchDef('monastery', 'Монастир', 'Без «Інтрижки». Місяць, 3, 6 і 12.', false, [1, 3, 6, 12], ('місяць', 'місяці', 'місяців')),
  AchDef('norake', 'Нуль граблів', '90 днів без повтору червоного прапорця.', false, [90], ('день', 'дні', 'днів')),
  AchDef('season', 'Повний сезон', 'Записи 12 тижнів поспіль.', false, [12], ('тиждень', 'тижні', 'тижнів')),
];

class Ach {
  final AchDef d;
  final int v;
  const Ach(this.d, this.v);
  int get lv => d.th.where((t) => v >= t).length;
  bool get earned => lv > 0;
  bool get started => v > 0;
  bool get max => lv >= d.th.length;
  int get next => max ? d.th.last : d.th[lv];
  int get prev => lv == 0 ? 0 : d.th[lv - 1];
  double get frac => max ? 1 : ((v - prev) / (next - prev)).clamp(0.0, 1.0);
  String get img => 'assets/img/ach/${d.id}.webp';
}

bool _red(String f) => flagById(f)?.kind == FlagKind.r;
bool _green(String f) => flagById(f)?.kind == FlagKind.g;

/// Найдовша серія записів поспіль (за датою), де виконується умова
int _streak(List<Entry> es, bool Function(Entry) ok) {
  var best = 0, cur = 0;
  for (final e in es) {
    cur = ok(e) ? cur + 1 : 0;
    best = math.max(best, cur);
  }
  return best;
}

/// Максимум записів у будь-якому вікні з [days] днів
int _window(List<String> dates, int days) {
  var best = 0;
  for (var i = 0; i < dates.length; i++) {
    final end = addDays(dates[i], days - 1);
    best = math.max(best, dates.skip(i).takeWhile((d) => d.compareTo(end) <= 0).length);
  }
  return best;
}

String weekKey(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return iso(monday);
}

List<Ach> computeAchievements(DB db, {String? todayIso}) {
  final now = todayIso ?? iso(DateTime.now());
  final es = [...db.entries]..sort((a, b) => a.date.compareTo(b.date) != 0 ? a.date.compareTo(b.date) : a.createdAt.compareTo(b.createdAt));
  final people = db.people;
  final c = db.profile.counters;
  Person? pp(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  final byPerson = <String, List<Entry>>{};
  for (final e in es) {
    (byPerson[e.personId] ??= []).add(e);
  }
  final v = <String, int>{};

  // Граблі: червоні прапорці, що були в 2+ різних людей
  final redPeople = <String, Set<String>>{};
  for (final e in es) {
    for (final f in e.flags.where(_red)) {
      (redPeople[f] ??= {}).add(e.personId);
    }
  }
  v['rake'] = redPeople.values.where((s) => s.length >= 2).length;
  v['gold'] = _streak(es, (e) => e.overall == 5);
  v['boomerang'] = c['boomerang'] ?? 0;
  v['nomaybe'] = people.where((p) {
    if (!p.isPast || p.pastAt == null) return false;
    final mine = byPerson[p.id];
    if (mine == null || mine.isEmpty) return false;
    final last = mine.last;
    return last.overall <= 2 && daysBetween(last.date, p.pastAt!) <= 1;
  }).length;
  var blind = 0, maybe = 0;
  for (final mine in byPerson.values) {
    for (var i = 0; i < mine.length - 1; i++) {
      if (mine[i].flags.any(_red)) blind++;
      if (mine[i].overall <= 2) maybe++;
    }
  }
  v['blind'] = blind;
  v['maybe'] = maybe;
  final astros = people.map((p) => astroOf(p.birth, p.signOnly)).whereType<Astro>().toList();
  v['astro'] = astros.map((a) => a.sign).toSet().length;
  v['elements'] = astros.map((a) => a.el).toSet().length;
  v['ghosted'] = people.where((p) => p.isPast && p.pastReason == 'gone').length;
  v['redcolor'] = es.where((e) => e.overall >= 4 && e.flags.where(_red).length > e.flags.where(_green).length).length;
  final nightStarts = people.where((p) => p.rel == 'night' && byPerson[p.id] != null).map((p) => byPerson[p.id]!.first.date).toList()..sort();
  v['sport'] = _window(nightStarts, 30);
  v['nightmore'] = people.where((p) => p.rel == 'night').map((p) => byPerson[p.id]?.length ?? 0).fold(0, math.max);
  v['ex'] = people.where((p) => p.rel == 'ex').length;
  v['confess'] = es.where((e) {
    final t = DateTime.tryParse(e.createdAt)?.toLocal();
    return t != null && t.hour >= 2 && t.hour < 5;
  }).length;
  v['love'] = byPerson.values.map((m) => _window(m.map((e) => e.date).toList(), 14)).fold(0, math.max);
  v['oscar'] = es.where((e) => e.tags.contains('o_fake')).length;
  v['happy'] = es.where((e) => e.tags.contains('o_me') || e.tags.contains('o_multi')).length;
  v['saiddone'] = c['saiddone'] ?? 0;
  v['green'] = es.where((e) => e.flags.where(_green).length >= 3).length;
  v['clean'] = _streak(es, (e) => !e.flags.any(_red));
  v['gentleman'] = es.where((e) => e.flags.contains('flag_g_walk') && e.flags.contains('flag_g_paid') && e.flags.contains('flag_g_ontime')).length;
  final dates = es.map((e) => e.date).toList();
  final w7 = _window(dates, 7), w14 = _window(dates, 14), w30 = _window(dates, 30);
  v['hotweek'] = w30 >= 12 && w14 >= 8 && w7 >= 5 ? 12 : (w14 >= 8 && w7 >= 5 ? 8 : math.min(w7, 7));
  var comeback = 0;
  for (var i = 1; i < es.length; i++) {
    if (daysBetween(es[i - 1].date, es[i].date) >= 30) comeback++;
  }
  v['comeback'] = comeback;
  v['newyear'] = es.where((e) => e.date.endsWith('-12-31') || e.date.endsWith('-01-01')).length;
  final me = astroOf(db.profile.birth);
  v['stars'] = me == null
      ? 0
      : es.where((e) {
          final a = astroOf(pp(e.personId)?.birth, pp(e.personId)?.signOnly);
          return e.overall == 5 && a != null && zodiacEase(me.sign, a.sign) == 'Легко';
        }).length;
  // Хардкор: Скорпіони поспіль у порядку додавання
  final added = [...people]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  var run = 0, hard = 0;
  for (final p in added) {
    run = astroOf(p.birth, p.signOnly)?.signName == 'Скорпіон' ? run + 1 : 0;
    hard = math.max(hard, run);
  }
  v['hardcore'] = hard;
  v['bar'] = es.where((e) => e.tags.contains('bar')).length;
  v['thumbelina'] = people.where((p) => p.size == 0).length;
  v['giant'] = people.where((p) => p.size == 3).length;
  v['revision'] = c.entries.where((x) => x.key.startsWith('rev:')).map((x) => x.value).fold(0, math.max);
  // Монастир: повні місяці без записів з «Інтрижкою»
  if (es.isEmpty) {
    v['monastery'] = 0;
  } else {
    final flings = es.where((e) => pp(e.personId)?.rel == 'fling').map((e) => e.date).toList();
    final from = flings.isEmpty ? es.first.date : flings.last;
    v['monastery'] = daysBetween(from, now) ~/ 30;
  }
  // Нуль граблів: днів від останнього повтору червоного прапорця
  if (es.isEmpty) {
    v['norake'] = 0;
  } else {
    final seen = <String>{};
    String? lastRepeat;
    for (final e in es) {
      for (final f in e.flags.where(_red)) {
        if (seen.contains(f)) lastRepeat = e.date;
        seen.add(f);
      }
    }
    v['norake'] = math.max(0, daysBetween(lastRepeat ?? es.first.date, now));
  }
  // Повний сезон: тижнів поспіль із записами
  final weeks = es.map((e) => weekKey(parseIso(e.date))).toSet().toList()..sort();
  var wRun = 0, wBest = 0;
  String? prevW;
  for (final w in weeks) {
    wRun = prevW != null && addDays(prevW, 7) == w ? wRun + 1 : 1;
    wBest = math.max(wBest, wRun);
    prevW = w;
  }
  v['season'] = wBest;

  return [for (final d in achDefs) Ach(d, v[d.id] ?? 0)];
}

/// Найближча до відкриття нагорода (для мапи)
Ach? nearestAch(List<Ach> all) {
  final open = all.where((a) => !a.max && a.started && !a.d.shame).toList()..sort((a, b) => b.frac.compareTo(a.frac));
  return open.isEmpty ? null : open.first;
}
