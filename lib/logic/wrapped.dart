// Wrapped без ШІ: 19 слайдів за дошкою «Wrapped». Кожен слайд має умову:
// нема даних — нема слайду. Цифри тільки справжні, тексти — шаблони з макета.
import '../data/catalog.dart';
import '../data/models.dart';
import 'achievements.dart';
import 'astro.dart';
import 'dates.dart';
import 'stats.dart';

const freeSlides = 3;

/// Номер дошки в макеті = номер фонового шару assets/wrapped/sNN.webp
enum WK {
  cover, receipt, best, sex, orgasm, match, matrix, battle, phone, fame, longest, fastest, budget, wishes, notice, awards, glow, closed, ticket,
  // кандидати з дошки «Інші кандидати» (WrappedMore): фони 19–33
  dossier, reviews, size, clown, rakes, oscars, init, alco, territory, after, voice, quarter, tarot, horo, archive,
  // «Він vs минулий місяць» (фон 35) і «Типаж» (фони 39–45, 47)
  himPrev, type,
}

/// Фони варіантів з тієї самої дошки: обкладинки, метч-роздвоєння, типажі, ганьба-колишня
abstract final class WArt {
  static const coverOne = 34, himPrev = 35, coverNoSex = 36, coverMini = 37, matchSplit = 38;
  static const detective = 39, artist = 40, serial = 41, auditor = 42, hr = 43, boss = 44, plaid = 45, clownEx = 46, night = 47;
}

/// Людина на слайді: справжнє ім'я і безпечна підміна («Він №1»)
class WP {
  final String id, name, safe;
  const WP(this.id, this.name, this.safe);
  String show(bool safeMode) => safeMode ? safe : name;
}

class WRow {
  final String label, value;
  final String? sub;
  final int kind; // 0 звичайний, 1 червоний, 2 зелений, 3 жовтий акцент, 4 закреслений; бюджет 5–7 ресторан/кава/квіти; 9 число фіналу; 10–12 іконки «Варто помітити»
  final WP? who;
  const WRow(this.label, this.value, {this.sub, this.kind = 0, this.who});
}

class WSlide {
  final WK k;
  final String title1, title2; // два рядки заголовка; title2 — акцентний (рожевий на темному)
  final String? title2Full; // title2 з іменем — для режиму з іменами
  final String? capSafe, capFull;
  final List<WRow> rows;
  final double score; // для кілець, бульбашок, сердечок
  final double score2;
  final int n1, n2;
  final String a, b, c; // довільні підписи слайду
  final List<WP> who;
  final List<int> ints;
  final List<bool> flags;
  final bool private;
  final int artOv; // фон іншого варіанта макета (WArt); -1 — за видом слайда
  final Map<String, String> x; // додаткові підписи слайду
  const WSlide(this.k, this.title1, this.title2,
      {this.title2Full,
      this.capSafe, this.capFull, this.rows = const [], this.score = 0, this.score2 = 0, this.n1 = 0, this.n2 = 0, this.a = '', this.b = '', this.c = '', this.who = const [], this.ints = const [], this.flags = const [], this.private = false, this.artOv = -1, this.x = const {}});
  /// Номер фону assets/wrapped/sNN.webp
  int get art => artOv >= 0 ? artOv : k.index;
  String? cap(bool safe) => safe ? capSafe : (capFull ?? capSafe);
  String t2(bool safe) => safe ? title2 : (title2Full ?? title2);
}

class Wrapped {
  final String month, label, monthNom, monthGen;
  final List<WSlide> slides;
  final int count;
  const Wrapped(this.month, this.label, this.monthNom, this.monthGen, this.slides, this.count);
}

/// Короткі назви питань про секс для «Найкраще / Найгірше»
const _sxShort = {
  'sx_pleasure': 'Задоволення',
  'sx_finish': 'Фінал',
  'sx_chem': 'Хімія',
  'sx_care': 'Дбали про тебе',
  'sx_heard': 'Тебе почули',
  'sx_after': 'Тепло після',
  'sx_fore': 'Прелюдія',
  'sx_pace': 'Темп',
  'sx_length': 'Тривалість',
  'sx_ask': 'Сказати, чого хочеш',
  'sx_react': 'Реакція на підказки',
  'sx_self': 'Бути собою',
  'sx_safe': 'Безпека',
  'sx_relax': 'Розслабитись',
  'sx_lead': 'Вести самій',
};

String _grn(int v) => v >= 1000 ? '${v ~/ 1000} ${(v % 1000).toString().padLeft(3, '0')}' : '$v';
String _times(int n) => '$n ${plural(n, 'раз', 'рази', 'разів')}';
String _shortDate(String d) {
  final x = parseIso(d);
  return '${weekdaysShort[x.weekday]}, ${x.day} ${monthsGen[x.month - 1].substring(0, 4)}';
}

String _longDate(String d) {
  final x = parseIso(d);
  return '${weekdaysShort[x.weekday]}, ${x.day} ${monthsGen[x.month - 1]}';
}

String _mode(List<String> xs) {
  final c = <String, int>{};
  for (final x in xs) {
    c[x] = (c[x] ?? 0) + 1;
  }
  return (c.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
}

String _placeWord(Entry e) {
  final t = e.tags;
  final w = t.contains('restaurant')
      ? 'вечеря'
      : t.contains('bar')
          ? 'бар'
          : t.contains('neutral')
              ? 'кава'
              : t.contains('his')
                  ? 'у нього'
                  : t.contains('mine')
                      ? 'у тебе'
                      : t.contains('hotel')
                          ? 'готель'
                          : 'вечір';
  return w;
}

/// Рівні нагород на кінець місяця мінус на кінець попереднього
List<Ach> _newAwards(DB db, String month) {
  final y = int.parse(month.substring(0, 4)), m = int.parse(month.substring(5, 7));
  final end = iso(DateTime(y, m + 1, 0));
  final prevEnd = iso(DateTime(y, m, 0));
  DB cut(String upTo) => DB(profile: db.profile, people: db.people, entries: db.entries.where((e) => e.date.compareTo(upTo) <= 0).toList(), meetings: db.meetings);
  final now = computeAchievements(cut(end), todayIso: end);
  final before = {for (final a in computeAchievements(cut(prevEnd), todayIso: prevEnd)) a.d.id: a.lv};
  return now.where((a) => !a.d.shame && a.lv > (before[a.d.id] ?? 0)).toList();
}

/// Генератор Wrapped за дошкою «Генератор: як працює» артефакту «Vespr Wrapped»:
/// 0–2 записи → Міні-Wrapped (4 слайди); 3+ → 7 актів з лімітами слотів,
/// у межах акту — найвищий бал (сила × новизна × дані), один факт — один заголовок.
/// novelty: false — без порівняння з минулим місяцем (щоб не рахувати рекурсивно глибше).
Wrapped buildWrapped(String month, DB db, {bool novelty = true}) {
  final y = int.parse(month.substring(0, 4)), m = int.parse(month.substring(5, 7));
  final nom = cap(monthsNom[m - 1]);
  final label = '$nom $y';
  final all = db.entries;
  final es = all.where((e) => monthKey(e.date) == month).toList()..sort((a, b) => a.date.compareTo(b.date));
  final out = <WSlide>[];

  // люди місяця в порядку першої зустрічі
  final ids = <String>[];
  for (final e in es) {
    if (!ids.contains(e.personId)) ids.add(e.personId);
  }
  final wps = <String, WP>{};
  for (var i = 0; i < ids.length; i++) {
    final p = db.people.where((x) => x.id == ids[i]).firstOrNull;
    final f = p?.gender == 'f';
    wps[ids[i]] = WP(ids[i], p?.name ?? '—', '${f ? 'Вона' : 'Він'} №${i + 1}');
  }
  WP wp(String id) => wps[id] ?? WP(id, '—', 'Він');

  if (es.isEmpty) {
    out.add(const WSlide(WK.type, 'Сезон', 'пледу', artOv: WArt.plaid, a: '0', x: {'lab': 'побачень.\nі це ок'}, capSafe: '0 побачень. Плед, серіал, какао. Найздоровіші стосунки місяця.'));
    out.add(WSlide(WK.closed, nom, 'загорнуто.', score: double.nan, a: 'vespr · ${m.toString().padLeft(2, '0')}/${(y % 100).toString().padLeft(2, '0')}', b: 'до зустрічі в ${monthsLoc[m % 12]} ✦', capSafe: '${cap(monthsNom[m % 12])}, ми готові. Майже.'));
    return Wrapped(month, label, monthsNom[m - 1], monthsGen[m - 1], out, 0);
  }

  final n = es.length;
  final overall = avg(es.map((e) => e.overall));
  final sx = es.where((e) => e.hadSex).toList();
  final reds = es.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).toList();
  final greens = es.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.g)).toList();
  final awards = _newAwards(db, month);
  final menWord = db.profile.dating == 'women' ? ('жінка', 'жінки', 'жінок') : (db.profile.dating == 'all' ? ('людина', 'людини', 'людей') : ('чоловік', 'чоловіки', 'чоловіків'));
  int tagN(String t) => es.where((e) => e.tags.contains(t)).length;

  // 0. Обкладинка: текст підлаштовується під місяць
  final mini = n < 3;
  final men = '${ids.length} ${plural(ids.length, menWord.$1, menWord.$2, menWord.$3)}';
  final dates = '$n ${plural(n, 'побачення', 'побачення', 'побачень')}';
  final bestAll = es.map((e) => e.overall).reduce((a, b) => a > b ? a : b);
  if (mini) {
    out.add(WSlide(WK.cover, '$n ${plural(n, 'запис', 'записи', 'записів')} —', 'гарний старт',
        artOv: WArt.coverMini,
        n1: n,
        x: {'kick': 'Твій ${monthsNom[m - 1]} · перші кроки', 'left': 'ще ${3 - n} до повного Wrapped', 'prog': '$n з 3 записів', 'men': '${ids.length}', 'menL': plural(ids.length, menWord.$1, menWord.$2, menWord.$3), 'best': '$bestAll', 'dates': plural(n, 'побачення', 'побачення', 'побачень')},
        capSafe: 'З третім записом відкриються рекорди, хлопці і нагороди.'));
  } else if (sx.isEmpty) {
    out.add(WSlide(WK.cover, '$nom:', 'тільки|побачення',
        artOv: WArt.coverNoSex, n1: n, x: {'dates': plural(n, 'побачення', 'побачення', 'побачень')}, capSafe: 'Місяць розмов, келихів і перших вражень.'));
  } else if (ids.length == 1) {
    out.add(WSlide(WK.cover, nom, 'з ним',
        title2Full: 'і ${wp(ids.first).name}',
        artOv: WArt.coverOne,
        n1: n,
        score: overall,
        x: {'eves': plural(n, 'вечір', 'вечори', 'вечорів')},
        capSafe: overall >= 4 ? 'Один на весь місяць — і це було добре.' : (overall >= 3 ? 'Один на весь місяць. Є над чим попрацювати.' : 'Один на весь місяць. І це було важко.')));
  } else if (overall >= 4.3) {
    out.add(WSlide(WK.cover, '$nom:', 'звіт про|виживання', capSafe: 'Спойлер: кайфанула. $dates, $men, середня ${fmt(overall)}/5 — ${rateWord(overall)}.'));
  } else if (overall >= 3) {
    out.add(WSlide(WK.cover, '$nom:', 'звіт про|виживання', capSafe: '$dates, $men, середня ${fmt(overall)}/5 — ${rateWord(overall)}. Розбираємо.'));
  } else {
    out.add(WSlide(WK.cover, '$nom:', 'було погано.|Чесно', capSafe: '$dates, середня ${fmt(overall)}/5 — ${rateWord(overall)}. Далі — чому.'));
  }

  // 1. Чек
  final sxAvg = avg(sx.map((e) => e.ratings['sx_overall'] ?? e.overall));
  final lastDay = DateTime(y, m + 1, 0);
  out.add(WSlide(WK.receipt, 'Чек за витрачені нерви', '',
      a: 'ЧЕК № ${all.length.toString().padLeft(4, '0')}',
      b: '${lastDay.day.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}.$y 23:47',
      score: overall,
      rows: [
        WRow('Побачення', '$n шт'),
        WRow(cap(menWord.$3 == 'людей' ? 'Люди' : (menWord.$3 == 'жінок' ? 'Жінки' : 'Чоловіки')), '${ids.length} шт'),
        ...[
          if (sx.isNotEmpty) WRow('Секс', '${sxAvg.round()}/5'),
          if (tagN('alco1') > 0) WRow('«Келих-два»', '${tagN('alco1')} шт'),
          if (tagN('alco2') > 0) WRow('«Більше»', '${tagN('alco2')} шт'),
        ].take(2),
        WRow('Ред-флаги', '${reds.length} шт', kind: 1),
        WRow('Грін-флаги', '${greens.length} шт', kind: 2),
      ]));

  // 2. Найкращий вечір
  final best = (es.toList()..sort((a, b) => b.overall != a.overall ? b.overall.compareTo(a.overall) : b.date.compareTo(a.date))).first;
  final bd = parseIso(best.date);
  final bestWhat = '${_placeWord(best)}${best.hadSex ? ' + після' : ''}';
  final personAvg = avg(all.where((e) => e.personId == best.personId).map((e) => e.overall));
  out.add(WSlide(WK.best, 'Найкращий', 'вечір місяця',
      a: '${cap(weekdaysShort[bd.weekday])}, ${bd.day} ${monthsGen[m - 1]} ✦ $bestWhat ✦ ',
      b: best.hadSex ? '${best.ratings['sx_overall'] ?? best.overall}/5' : '${best.overall}/5',
      c: best.hadSex ? 'секс' : 'вечір',
      score: personAvg,
      who: [wp(best.personId)],
      capSafe: best.overall == 5 ? 'Планку підняли. Тримай.' : 'Найкраще, що було цього місяця.'));

  if (mini) {
    out.add(WSlide(WK.closed, nom, 'загорнуто.',
        score: overall,
        rows: _numbers(overall, n, ids.length, menWord, greens.length, reds.length),
        a: 'vespr · ${m.toString().padLeft(2, '0')}/${(y % 100).toString().padLeft(2, '0')}',
        b: 'до зустрічі в ${monthsLoc[m % 12]} ✦',
        capSafe: 'Ще ${3 - n} ${plural(3 - n, 'запис', 'записи', 'записів')} — і буде повний Wrapped з рекордами, хлопцями і нагородами.'));
    return Wrapped(month, label, monthsNom[m - 1], monthsGen[m - 1], out, n);
  }

  // кандидати актів 2–6: бал = сила × новизна × дані
  final meta = <WSlide, (double, int, String?)>{};
  void cand(WSlide sl, double strength, int recs, [String? fact]) {
    out.add(sl);
    meta[sl] = (strength.clamp(0.05, 1.0).toDouble(), recs, fact);
  }

  // 3. Секс місяця
  if (sx.length >= 2) {
    final s = sxAvg;
    final qAvg = <String, double>{};
    for (final q in _sxShort.keys) {
      final v = sx.map((e) => e.ratings[q]).whereType<int>().toList();
      if (v.length >= 2) qAvg[q] = avg(v);
    }
    final byScore = ([...sx]..sort((a, b) => (b.ratings['sx_overall'] ?? b.overall).compareTo(a.ratings['sx_overall'] ?? a.overall)));
    final top = byScore.first, bottom = byScore.last;
    final rows = <WRow>[];
    if (qAvg.length >= 2) {
      final sorted = qAvg.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      rows.add(WRow('Найкраще', fmt(sorted.first.value), sub: '«${_sxShort[sorted.first.key]}»', kind: 0));
      rows.add(WRow('Найгірше', fmt(sorted.last.value), sub: '«${_sxShort[sorted.last.key]}»', kind: 3));
    }
    rows.add(WRow('Топ · ${_shortDate(top.date)}', '${top.ratings['sx_overall'] ?? top.overall}/5', who: wp(top.personId)));
    if (bottom.id != top.id) rows.add(WRow('Дно · ${_shortDate(bottom.date)}', '${bottom.ratings['sx_overall'] ?? bottom.overall}/5', who: wp(bottom.personId), kind: 3));
    final low = _sxShort.keys.where((q) => bottom.ratings[q] != null).toList()..sort((a, b) => bottom.ratings[a]!.compareTo(bottom.ratings[b]!));
    String? cp;
    if (low.length >= 2 && bottom.ratings[low[1]]! <= 3) {
      cp = 'Найгірший підвели ${_sxShort[low[0]]!.toLowerCase()} (${bottom.ratings[low[0]]}/5) і ${_sxShort[low[1]]!.toLowerCase()} (${bottom.ratings[low[1]]}/5). Про це варто сказати вголос.';
    }
    cand(WSlide(WK.sex, 'Секс у ${monthsLoc[m - 1]}:', rateWord(s), score: s, rows: rows.take(4).toList(), capSafe: cp), ((s - 3).abs() / 2).clamp(.3, 1.0), sx.length);

    // 4. Оргазми місяця (приватний у сторіз)
    final finE = sx.where((e) => e.tags.any((t) => t.startsWith('o_'))).length;
    if (finE >= 3) {
      final om = sx.where((e) => e.tags.contains('o_me') || e.tags.contains('o_multi')).length;
      final oh = sx.where((e) => e.tags.contains('o_him')).length;
      final multi = sx.where((e) => e.tags.contains('o_multi')).toList();
      final fake = sx.where((e) => e.tags.contains('o_fake')).length;
      final parts = <String>[
        oh > om ? 'Рахунок $oh:$om не на твою користь.' : (om > oh ? 'Рахунок $om:$oh на твою користь.' : 'Рахунок $om:$oh, нічия.'),
        if (multi.isNotEmpty) 'Кілька за ніч: ${_times(multi.length)}, ${_shortDate(multi.last.date)}.',
        fake == 0 ? 'Вдавала: 0, так і тримай.' : 'Вдавала: $fake.',
      ];
      cand(WSlide(WK.orgasm, 'Оргазми', 'місяця', n1: om, n2: oh, score: sx.length.toDouble(), capSafe: parts.join(' '), private: true), (oh - om).abs() / finE + (fake > 0 ? .3 : 0), finE);
    }
  }

  // 5. Метч місяця: лідер за «Сексом з ним» і лідер за «Він» (люди з 2+ записами і сексом)
  final mc = ids.where((id) => es.where((e) => e.personId == id).length >= 2 && sx.any((e) => e.personId == id)).toList();
  if (mc.isNotEmpty) {
    double ch(String id) => avg(es.where((e) => e.personId == id).map((e) => e.overall));
    double sv(String id) => avg(sx.where((e) => e.personId == id).map((e) => e.ratings['sx_overall'] ?? e.overall));
    final bySex = [...mc]..sort((a, b) => sv(b).compareTo(sv(a)));
    final byChar = [...mc]..sort((a, b) => ch(b).compareTo(ch(a)));
    final sl = bySex.first, cl = byChar.first;
    final recs = es.where((e) => e.personId == sl || e.personId == cl).length;
    if (sl == cl) {
      final id = sl;
      final c = ch(id), s = sv(id);
      final p = db.people.where((x) => x.id == id).firstOrNull;
      final me = astroOf(db.profile.birth), him = p == null ? null : astroOf(p.birth, p.signOnly);
      final nobody = (c + s) / 2 < 3.5;
      cand(
          WSlide(WK.match, 'Метч місяця:', nobody ? 'ніхто' : 'повне комбо',
              score: c,
              score2: s,
              who: [wp(id)],
              a: nobody ? '' : (me?.signName ?? ''),
              b: nobody ? '' : (him?.signName ?? ''),
              c: me != null && him != null ? 'зірки кажуть: ${zodiacEase(me.sign, him.sign).toLowerCase()}' : '',
              capSafe: nobody ? 'Найкраще — ${fmt((c + s) / 2)}/5, це «${rateWord((c + s) / 2)}».' : null),
          ((c + s) / 2 - 3).abs() / 2,
          recs,
          nobody ? null : 'p:$id');
    } else {
      // роздвоєння: секс найкращий з одним, говорити — з іншим
      cand(
          WSlide(WK.match, 'Роздво', 'єння',
              artOv: WArt.matchSplit,
              score: ch(cl),
              score2: sv(sl),
              who: [wp(cl), wp(sl)],
              capSafe: 'Класика, яку ще ніхто не вирішив.'),
          .7,
          recs);
    }
  }

  // 6. Матриця типажів (дві найчастіші людини)
  final byCount = [...ids]..sort((a, b) => es.where((e) => e.personId == b).length.compareTo(es.where((e) => e.personId == a).length));
  int quad(String id) {
    final pe = es.where((e) => e.personId == id).toList();
    final hot = avg(pe.map((e) => e.hadSex ? (e.ratings['sx_overall'] ?? e.overall) : e.overall)) >= 3.5;
    final r = pe.expand((e) => e.flags.where((x) => flagById(x)?.kind != FlagKind.g)).length;
    final g = pe.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.g)).length;
    final safe = g > r;
    return hot ? (safe ? 0 : 1) : (safe ? 2 : 3); // 0 гаряче й безпечно, 1 гаряче й токсично, 2 надійно-нудно, 3 навіщо
  }

  const qPhrase = ['у Червоній книзі', 'класика, від якої мама просила тікати', 'надійний, але нудний', 'взагалі навіщо'];
  final twoPlus = byCount.where((id) => es.where((e) => e.personId == id).length >= 2).toList();
  if (twoPlus.length >= 2) {
    final a = twoPlus[0], b = twoPlus[1];
    final minRecs = es.where((e) => e.personId == b).length;
    final qa = quad(a), qb = quad(b);
    cand(WSlide(WK.matrix, 'Матриця', 'типажів',
        who: [wp(a), wp(b)],
        ints: [qa, qb],
        capSafe: 'Один ${qPhrase[qa]}. Другий: ${qPhrase[qb]}.',
        capFull: '${wp(a).name} ${qPhrase[qa]}. ${wp(b).name}: ${qPhrase[qb]}.'), qa == qb ? .4 : .6, minRecs);

    // 7. Битва місяця
    double q(String id, String key) => avg(es.where((e) => e.personId == id).map((e) => e.ratings[key]).whereType<int>());
    final keys = const [('pt_hears', 'Чує тебе'), ('pt_limits', 'Поважає межі'), ('pt_pull', 'Тягне до нього'), ('pt_free', 'Без ревнощів')];
    final rows = <WRow>[];
    var sa = 0, sb = 0;
    String fatal = '';
    var fatalDiff = -1.0;
    for (final k in keys) {
      final va = q(a, k.$1), vb = q(b, k.$1);
      if (va.isNaN || vb.isNaN) continue;
      if (va > vb) sa++;
      if (vb > va) sb++;
      rows.add(WRow(k.$2, '${va.round()}', sub: '${vb.round()}', kind: va > vb ? 1 : (vb > va ? 2 : 0)));
      if ((va - vb).abs() > fatalDiff) {
        fatalDiff = (va - vb).abs();
        fatal = k.$2.toLowerCase();
      }
    }
    if (rows.length >= 2) {
      final win = sa >= sb ? a : b;
      final pa = (avg(es.where((e) => e.personId == a).map((e) => e.overall)) / 5 * 100).round();
      final pb = (avg(es.where((e) => e.personId == b).map((e) => e.overall)) / 5 * 100).round();
      cand(WSlide(WK.battle, 'Битва місяця', '',
          who: [wp(a), wp(b), wp(win)],
          n1: pa,
          n2: pb,
          rows: rows,
          capSafe: 'Рахунок ${sa >= sb ? sa : sb} : ${sa >= sb ? sb : sa}. Fatality: ${sa >= sb ? 'гравець 1' : 'гравець 2'} просто $fatal.',
          capFull: 'Рахунок ${sa >= sb ? sa : sb} : ${sa >= sb ? sb : sa}. Fatality: ${wp(win).name} просто $fatal.'), .4 + .6 * (sa - sb).abs() / rows.length, minRecs);
    }
  }

  // 8. Конкурентка айфона
  final ph = es.where((e) => e.flags.contains('flag_r_phone')).toList();
  if (ph.length >= 3) {
    final shown = es.length > 7 ? es.sublist(es.length - 7) : es;
    final who = <String, int>{};
    for (final e in ph) {
      who[e.personId] = (who[e.personId] ?? 0) + 1;
    }
    final full = (who.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).map((x) => '${x.value == 1 ? 'раз' : _times(x.value)} ${wp(x.key).name}').join(', ');
    cand(WSlide(WK.phone, 'Твій типаж:', 'конкурентка айфона',
        flags: shown.map((e) => e.flags.contains('flag_r_phone')).toList(),
        n1: ph.length,
        n2: n - ph.length,
        capSafe: '$n ${plural(n, 'вечір', 'вечори', 'вечорів')}: ${_times(ph.length)} виграв екран, ${_times(n - ph.length)} ти.',
        capFull: '$n ${plural(n, 'вечір', 'вечори', 'вечорів')}: ${_times(ph.length)} виграв екран, ${_times(n - ph.length)} ти. ${cap(full)}.'), ph.length / n, ph.length, 'flag_r_phone');
  }

  // 9. Зала слави: найбільше зелених прапорців
  final gBy = <String, List<String>>{};
  for (final e in es) {
    gBy.putIfAbsent(e.personId, () => []).addAll(e.flags.where((x) => flagById(x)?.kind == FlagKind.g));
  }
  final fameId = gBy.entries.where((x) => x.value.length >= 3 && es.where((e) => e.personId == x.key).length >= 2).toList()..sort((x, y) => y.value.length.compareTo(x.value.length));
  if (fameId.isNotEmpty) {
    final g = fameId.first.value;
    final cnt = <String, int>{};
    for (final x in g) {
      cnt[x] = (cnt[x] ?? 0) + 1;
    }
    final top = (cnt.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).take(3).toList();
    final fRecs = es.where((e) => e.personId == fameId.first.key).length;
    cand(WSlide(WK.fame, 'Зала слави:', 'він знає, хто він',
        who: [wp(fameId.first.key)],
        rows: [for (final t in top) WRow(flagById(t.key)?.label ?? '', '×${t.value}', sub: '${t.value / top.first.value}')],
        capSafe: 'Виявляється, так можна було.'), g.length / (fRecs * 2), fRecs, 'p:${fameId.first.key}');
  }

  // 10–11. Рекорди витривалості
  final stam = sx.where((e) => e.facts['f_stam'] != null).toList();
  final longE = stam.where((e) => e.facts['f_stam'] == 3).toList();
  if (longE.isNotEmpty) {
    final e = (longE..sort((a, b) => (b.ratings['sx_overall'] ?? b.overall).compareTo(a.ratings['sx_overall'] ?? a.overall))).first;
    cand(WSlide(WK.longest, 'Рекорд місяця:', 'незламний', rows: [
      const WRow('Найдовший секс', '40+ хв'),
      WRow(' · ${_shortDate(e.date)}', '${e.ratings['sx_overall'] ?? e.overall}/5', who: wp(e.personId)),
      if (e.tags.contains('multi')) const WRow('Заходів за ніч', '2+'),
    ]), 1, longE.length);
  }
  final fastE = stam.where((e) => e.facts['f_stam'] == 0).toList();
  if (fastE.isNotEmpty) {
    final e = fastE.last;
    final fin = e.tags.contains('o_me') || e.tags.contains('o_multi');
    // одна людина 2+ рази до ~5 хв — це вже стиль
    final per = <String, int>{};
    for (final x in fastE) {
      per[x.personId] = (per[x.personId] ?? 0) + 1;
    }
    final serial = per.entries.where((x) => x.value >= 2).firstOrNull;
    cand(
        serial != null
            ? WSlide(WK.fastest, 'Серійний', 'спринтер', rows: [
                WRow('До ~5 хв', '${serial.value} ${plural(serial.value, 'раз', 'рази', 'разів')}'),
                WRow(' · ${_shortDate(fastE.where((x) => x.personId == serial.key).last.date)}', '${e.ratings['sx_overall'] ?? e.overall}/5', who: wp(serial.key)),
                WRow('Твій фінал', fin ? 'встигла' : 'не встигла'),
              ])
            : WSlide(WK.fastest, 'Рекорд місяця:', 'спринтер', rows: [
                const WRow('Найшвидший секс', 'до 5 хв'),
                WRow(' · ${_shortDate(e.date)}', '${e.ratings['sx_overall'] ?? e.overall}/5', who: wp(e.personId)),
                WRow('Твій фінал', fin ? 'встигла' : 'не встигла'),
              ]),
        1,
        fastE.length);
  }

  // 12. Бюджет: f_budget — категорії, тому суми приблизні (середина діапазону)
  final bud = es.where((e) => e.facts['f_budget'] != null).toList();
  if (bud.length >= 2) {
    const mid = [0, 150, 900, 2000];
    final rest = bud.where((e) => (e.facts['f_budget'] ?? 0) >= 2).toList();
    final cafe = bud.where((e) => e.facts['f_budget'] == 1).toList();
    final restSum = rest.fold<int>(0, (s, e) => s + mid[e.facts['f_budget']!.clamp(0, 3)]);
    final cafeSum = cafe.length * mid[1];
    final gifts = es.where((e) => e.flags.contains('flag_g_gift')).length;
    final paid = es.where((e) => e.flags.contains('flag_g_paid')).length;
    final total = restSum + cafeSum;
    final mx = [restSum, cafeSum, 1].reduce((a, b) => a > b ? a : b).toDouble();
    final prem = bud.where((e) => e.facts['f_budget'] == 3).length;
    cand(WSlide(WK.budget, 'Бюджет місяця:', prem >= 2 ? 'бізнес-клас' : '$gifts ${plural(gifts, 'квітка', 'квітки', 'квітів')}',
        a: '~${_grn(total)}',
        n1: paid,
        n2: n,
        rows: [
          if (rest.isNotEmpty) WRow('Ресторани ×${rest.length}', '~${_grn(restSum)}', sub: '${restSum / mx}', kind: 5),
          if (cafe.isNotEmpty) WRow('Кава ×${cafe.length}', '~${_grn(cafeSum)}', sub: '${cafeSum / mx}', kind: 6),
          WRow('Квіти', '$gifts', sub: gifts == 0 ? '0' : '0.2', kind: 7),
        ],
        c: 'заплатив сам: $paid з $n ${plural(n, 'вечора', 'вечорів', 'вечорів')}',
        capSafe: gifts == 0 ? 'Троянди були тільки на цьому фото.' : (paid * 2 >= n ? 'Квіти були. Джентльмен.' : 'Квіти були. Бухгалтерія все одно плаче.')), rest.length / n + (gifts == 0 ? .3 : 0) + (prem >= 2 ? .3 : 0), bud.length);
  }

  // 13. Ти хотіла: пари «вийшло / не вийшло» з тегів
  const wishes = [
    ('Не поспішати', ['fore'], ['nofore', 'rush']),
    ('Сказати, чого хочеш', ['said'], ['silent']),
    ('Позначити межу', ['limit'], ['limit_missed']),
    ('Подбати про захист', ['condom', 'contra'], ['noprot']),
  ];
  final wr = <WRow>[];
  for (final w in wishes) {
    final hit = es.where((e) => e.tags.any((t) => w.$2.contains(t) || w.$3.contains(t))).toList();
    if (hit.isEmpty) continue;
    final last = hit.last;
    final ok = last.tags.any((t) => w.$2.contains(t));
    wr.add(WRow(w.$1, '', sub: _shortDate(last.date), kind: ok ? 2 : 4));
  }
  if (wr.length >= 2) {
    final ok = wr.where((r) => r.kind == 2).length;
    cand(WSlide(WK.wishes, 'Ти хотіла:', 'вийшло $ok із ${wr.length}', rows: wr.take(3).toList(), n1: ok, n2: wr.length), .4 + .6 * ok / wr.length, wr.length);
  }

  // 14. Варто помітити — спокійно, без жартів і рейтингів, ніколи в сторіз.
  // Тривожні рядки за пріоритетом (максимум 3). Нема жодного — той самий слайд про хороше.
  // kind: 10 мовчання, 11 захист, 12 тіло/тиск, 13 хороше
  String who1(List<Entry> hit) {
    final w = hit.map((e) => wp(e.personId).name).toSet().toList();
    return w.length == 1 ? w.first : '${w.length} людей';
  }

  final alarms = <(WRow, String)>[]; // рядок + тема для підсумку
  final alarmIds = <String>[];
  void alarm(String title, List<Entry> hit, String sub, int kind, String theme) {
    if (hit.isEmpty) return;
    alarmIds.add(hit.last.id);
    alarms.add((WRow(title, sub, kind: kind), theme));
  }

  List<Entry> tagged(String t) => es.where((e) => e.tags.contains(t)).toList();
  List<Entry> flagged(String f) => es.where((e) => e.flags.contains(f)).toList();
  // найсерйозніше — критичні прапорці (не з таблиці макета, але про безпеку)
  for (final f in const ['flag_c_stop', 'flag_c_condom', 'flag_c_photo']) {
    final hit = flagged(f);
    alarm(flagById(f)!.label, hit, '${_times(hit.length)} · ${hit.isEmpty ? '' : '${_longDate(hit.last.date)}, ${who1(hit)}'}', f == 'flag_c_condom' ? 11 : 12, f == 'flag_c_condom' ? 'prot' : 'body');
  }
  final pain = tagged('pain');
  final painGood = avg(pain.map((e) => e.ratings['sx_pleasure']).whereType<int>());
  alarm('Був дискомфорт', pain, '${_times(pain.length)} · ${pain.isEmpty ? '' : who1(pain)}${painGood.isNaN ? '' : '. «Тобі добре» в ці вечори ${fmt(painGood)}/5'}', 12, 'body');
  final push = flagged('flag_r_push');
  alarm('Він тиснув і квапив', push, '${_times(push.length)} · ${push.isEmpty ? '' : '${_longDate(push.last.date)}, ${who1(push)}'}', 12, 'body');
  final lm = tagged('limit_missed');
  alarm('Хотіла сказати «ні» і не сказала', lm, '${_times(lm.length)} · ${lm.isEmpty ? '' : _longDate(lm.last.date)}', 10, 'silent');
  final np = tagged('noprot');
  alarm('Без захисту', np, '${_times(np.length)} · ${np.isEmpty ? '' : who1(np)}', 11, 'prot');
  final sil = tagged('silent');
  if (sil.length >= 3) alarm('Промовчала, чого хочеш', sil, '${sil.length} з $n разів', 10, 'silent');
  final selfV = sx.map((e) => e.ratings['sx_self']).whereType<int>().toList();
  if (selfV.length >= 2 && avg(selfV) <= 2.5) alarm('«Могла бути собою»: ${fmt(avg(selfV))}/5', sx, 'Найнижче з усіх питань місяця', 10, 'silent');
  final fake = tagged('o_fake');
  if (fake.length >= 2) alarm('Вдавала оргазм', fake, _times(fake.length), 12, 'other');
  final jeal = flagged('flag_r_jealous');
  if (jeal.length >= 2) alarm('Ревнував і контролював', jeal, '${_times(jeal.length)} · ${who1(jeal)}', 12, 'other');
  final lie = flagged('flag_r_lie');
  alarm('Брехав', lie, '${_times(lie.length)} · ${lie.isEmpty ? '' : who1(lie)}', 12, 'other');
  final drunk = es.where((e) => e.flags.contains('flag_r_drunk') && e.tags.contains('alco2')).toList();
  if (drunk.isNotEmpty) alarm('Обоє випили забагато', drunk, '${_longDate(drunk.last.date)}. Оцінка вечора ${drunk.last.overall}/5', 12, 'other');

  // хороше, за пріоритетом
  final goods = <WRow>[];
  void good(bool ok, String title, String sub) {
    if (ok) goods.add(WRow(title, sub, kind: 13));
  }

  final noOk = flagged('flag_g_no');
  good(noOk.isNotEmpty && push.isEmpty, 'Поважав твоє «ні»', _times(noOk.length));
  final protAll = sx.length >= 2 && sx.every((e) => e.tags.contains('condom') || e.tags.contains('contra'));
  good(protAll, 'Захист щоразу', flagged('flag_g_condom').isNotEmpty ? 'і він сам подбав про захист' : '${sx.length} з ${sx.length}');
  good(selfV.length >= 2 && avg(selfV) >= 4.5, '«Могла бути собою»: ${selfV.isEmpty ? '' : fmt(avg(selfV))}/5', 'Так і має бути');
  final heardV = sx.map((e) => e.ratings['sx_heard']).whereType<int>().toList();
  good(heardV.length >= 2 && avg(heardV) >= 4.5, '«Тебе почули»: ${heardV.isEmpty ? '' : fmt(avg(heardV))}/5', 'Щоразу');
  good(tagged('limit').isNotEmpty && push.isEmpty, 'Позначила межу, і її поважали', _times(tagged('limit').length));
  good(tagged('said').length >= 3, 'Сказала, чого хочеш', _times(tagged('said').length));
  good(sx.length >= 2 && sx.every((e) => e.tags.contains('comfy')), 'Тіло: комфортно щоразу', '${sx.length} з ${sx.length}');
  good(tagged('stop').isNotEmpty, 'Зупинила те, що не подобалось', _times(tagged('stop').length));
  final fakedBefore = all.any((e) => e.tags.contains('o_fake') && e.date.compareTo(es.first.date) < 0);
  good(fakedBefore && fake.isEmpty && sx.isNotEmpty, 'Не вдавала жодного разу', 'Цього місяця все справжнє');

  if (alarms.isNotEmpty || goods.isNotEmpty) {
    final rows = <WRow>[];
    String capTxt;
    if (alarms.isNotEmpty) {
      rows.addAll(alarms.take(3).map((x) => x.$1));
      // 1–2 тривожні рядки → останнім найсильніше хороше, щоб слайд не був лише про погане
      if (rows.length < 3 && goods.isNotEmpty) rows.add(WRow('А ще: ${goods.first.label[0].toLowerCase()}${goods.first.label.substring(1)}', goods.first.value, kind: 13));
      final theme = alarms.first.$2;
      final both = alarms.length >= 2 && alarmIds.length >= 2 && alarmIds[0] == alarmIds[1] ? '\nОбидва — один вечір.' : '';
      capTxt = switch (theme) {
            'body' => 'Ти маєш право зупинитись у будь-який момент.',
            'silent' => 'Спробуй сказати одну річ уголос.',
            'prot' => 'Це твоя безпека, не його зручність.',
            _ => 'Це не вирок і не жарт.\nПросто факт, щоб ти його бачила.',
          } +
          both;
    } else {
      rows.addAll(goods.take(3));
      capTxt = 'Жодного тривожного сигналу.\nТак і має бути — запамʼятай, як це відчувається.';
    }
    cand(WSlide(WK.notice, 'Варто помітити', '', rows: rows, private: true, capSafe: capTxt), 1, n);
  }

  // ---- Кандидати з дошки «Інші кандидати» (WrappedMore)
  Person? per(String id) => db.people.where((x) => x.id == id).firstOrNull;
  List<Entry> ofP(String id) => es.where((e) => e.personId == id).toList();
  double sexOf(Entry e) => (e.ratings['sx_overall'] ?? e.overall).toDouble();
  String nTimes(int k) => k == 2 ? 'двічі' : _times(k);
  // нова людина: перший запис з нею — цього місяця
  bool isNew(String id) => !all.any((e) => e.personId == id && e.date.compareTo('${es.first.date.substring(0, 8)}01') < 0);
  int countF(List<Entry> xs, String f) => xs.where((e) => e.flags.contains(f)).length;
  List<MapEntry<String, int>> redTop(List<Entry> xs) {
    final c = <String, int>{};
    for (final e in xs) {
      for (final f in e.flags.where((f) => flagById(f)?.kind == FlagKind.r)) {
        c[f] = (c[f] ?? 0) + 1;
      }
    }
    return c.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  // Особова справа: нова людина з 2+ записами; максимум дві — найкраща і найгірша
  final dossiers = ids.where((id) => isNew(id) && ofP(id).length >= 2).toList()..sort((a, b) => avg(ofP(b).map((e) => e.overall)).compareTo(avg(ofP(a).map((e) => e.overall))));
  for (final id in {if (dossiers.isNotEmpty) dossiers.first, if (dossiers.length > 1) dossiers.last}) {
    final pe = ofP(id);
    final a = avg(pe.map((e) => e.overall));
    final p = per(id);
    final ast = p == null ? null : astroOf(p.birth, p.signOnly);
    final num = ids.indexOf(id) + 1;
    final verdict = a >= 4 ? 'виправдано' : (a >= 3 ? 'умовно' : 'довічно в минулих');
    final top = redTop(pe).take(3).toList();
    cand(
        WSlide(WK.dossier, 'Особова', 'справа',
            who: [wp(id)],
            rows: [for (final t in top) WRow((flagById(t.key)?.label ?? '').toLowerCase(), '×${t.value}', sub: '|' * t.value.clamp(1, 6))],
            x: {
              'num': '№$num',
              'tab': 'справа · ${monthsNom[m - 1].substring(0, 4)}',
              'obj': "об'єкт №$num",
              'opened': 'відкрито ${parseIso(pe.first.date).day.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}',
              'sign': ast == null ? '—' : '${zodiacGlyph(ast.sign)} ${ast.signName}',
              'meet': '${pe.length}',
              'avg': '${fmt(a)} / 5',
              'stamp': 'Вирок: $verdict',
              'cap2': a >= 3 && a < 4 ? 'справа не закрита' : 'справу закрито',
            },
            capSafe: a >= 4 ? 'Претензій нема. Справу закрито.' : (a >= 3 ? 'Шанс є. Але з випробувальним терміном.' : 'Без права на апеляцію.')),
        ((a - 3.5).abs() / 1.5 + .3),
        pe.length,
        'p:$id');
  }

  // Відгуки покупців: 2+ людей, по картці на двох найчастіших
  if (ids.length >= 2) {
    final top2 = byCount.take(2).toList();
    const pros = {'flag_g_asks': 'Сам питає, що подобається', 'flag_g_listen': 'Слухає і розпитує', 'flag_g_walk': 'Проводжає додому', 'flag_g_paid': 'Платить сам', 'flag_g_ontime': 'Приходить вчасно', 'flag_g_gift': 'Квіти без приводу', 'flag_g_remember': "Пам'ятає деталі", 'flag_g_texts': 'Пише після', 'flag_g_no': 'Чує «ні»', 'flag_g_word': 'Тримає слово', 'flag_g_kind': 'Чемний з усіма', 'flag_g_condom': 'Сам подбав про захист'};
    const cons = {'flag_r_phone': 'Батарея сідає швидко', 'flag_r_late': 'доставка запізнюється', 'flag_r_self': 'Багато говорить про себе', 'flag_r_ex': 'У комплекті колишня', 'flag_r_cheap': 'Рахує копійки', 'flag_r_jab': 'Неприємні підколи', 'flag_r_drunk': "Буває занадто п'яний", 'flag_r_gone': 'Зникає після', 'flag_r_jealous': 'Ревнує', 'flag_r_lie': 'Щось не збігається', 'flag_r_push': 'Квапить'};
    final cards = <WRow>[];
    final stars = <int>[];
    for (final id in top2) {
      final pe = ofP(id);
      final st = avg(pe.map((e) => e.overall)).round().clamp(1, 5);
      stars.add(st);
      final g = <String, int>{}, r = <String, int>{};
      for (final e in pe) {
        for (final f in e.flags) {
          if (pros.containsKey(f)) g[f] = (g[f] ?? 0) + 1;
          if (cons.containsKey(f)) r[f] = (r[f] ?? 0) + 1;
        }
      }
      final gs = (g.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(2).map((x) => pros[x.key]!).toList();
      final rs = (r.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(2).map((x) => cons[x.key]!).toList();
      final plus = gs.isEmpty ? 'На фото такий самий' : gs.join('. ');
      final minus = rs.isEmpty ? '' : cap(rs.join(', ').toLowerCase());
      final quote = st >= 5 ? 'Рекомендую подругам. Ні, не рекомендую — це мій.' : (st >= 4 ? 'Беру ще раз. Без знижки.' : (st >= 3 ? 'Брала на пробу. Думаю.' : 'До кошика повторно не додам.'));
      cards.add(WRow(plus, '$st', sub: minus, who: wp(id)));
      cards.add(WRow(quote, '${pe.length * 4 + st}', kind: 0));
    }
    final ra = avg(stars);
    cand(
        WSlide(WK.reviews, 'Відгуки', 'покупців',
            rows: cards,
            score: ra,
            ints: [for (var k = 5; k >= 1; k--) stars.where((x) => x == k).length],
            x: {'cnt': '${stars.length} ${plural(stars.length, 'відгук', 'відгуки', 'відгуків')}', 'verdict': ra >= 4.5 ? 'Хіт продажів.' : (ra >= 3.5 ? 'Середина ринку.' : 'Акція не допомогла.'), 'date': '${monthsNom[m - 1].substring(0, 4)} $y'}),
        .45,
        ofP(top2[1]).length);
  }

  // Колекція (розмір): нові люди з розміром у картці. Тільки повна версія
  final sizeIds = ids.where((id) => isNew(id) && per(id)?.size != null).toList();
  if (sizeIds.isNotEmpty) {
    final withSize = ids.where((id) => per(id)?.size != null).toList();
    final small = withSize.where((id) => per(id)!.size == 0).length;
    final giant = withSize.where((id) => per(id)!.size == sizes.length - 1).length;
    cand(
        WSlide(WK.size, 'Розмір', 'місяця',
            private: true,
            rows: [for (final id in withSize.take(3)) WRow(sizes[per(id)!.size!.clamp(0, sizes.length - 1)], '${per(id)!.size}', who: wp(id), sub: sizeIds.contains(id) ? 'новий експонат' : 'розмір')],
            n1: small,
            n2: giant,
            x: {'of': 'з ${withSize.length}', 'intro': 'Твої позначки «розмір» за ${monthsNom[m - 1]}: хто що показав.'},
            capSafe: 'Подробиці — в закритому показі.'),
        .5,
        sizeIds.length);
  }

  // Зала ганьби: найчастіший червоний 2+ (без болючих — вони у «Варто помітити»)
  const noJoke = {'flag_r_push', 'flag_r_lie', 'flag_r_jealous'};
  const meme = {
    'flag_r_phone': 'Айфон, мабуть, гарніший.',
    'flag_r_late': 'Годинник, мабуть, декоративний.',
    'flag_r_self': 'Монолог на біс. Ти була глядачкою.',
    'flag_r_cheap': 'Скупий платить двічі. Цей — жодного.',
    'flag_r_jab': 'Стендап не вдався. Двічі.',
    'flag_r_drunk': 'Тост явно був зайвий.',
    'flag_r_gone': 'Був — і нема. Фокус без бісу.',
    'flag_r_ex': 'Ти не на побаченні, ти на груповій терапії.',
  };
  final shameTop = redTop(es).where((x) => !noJoke.contains(x.key) && x.value >= 2).firstOrNull;
  if (shameTop != null) {
    final f = shameTop.key;
    final hit = es.where((e) => e.flags.contains(f)).toList();
    final whoC = <String, int>{};
    for (final e in hit) {
      whoC[e.personId] = (whoC[e.personId] ?? 0) + 1;
    }
    final main = (whoC.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    final lab = (flagById(f)?.label ?? '').toLowerCase();
    final sp = lab.indexOf(' ');
    final ex = f == 'flag_r_ex';
    cand(
        WSlide(WK.clown, ex ? 'Колишня 👋' : 'Клоун', ex ? 'передає привіт' : 'місяця',
            artOv: ex ? WArt.clownEx : -1,
            who: [wp(main)],
            a: '×${shameTop.value}',
            x: {'lab': sp < 0 ? lab : '${lab.substring(0, sp)}\n${lab.substring(sp + 1)}'},
            capSafe: ex ? meme[f] : '${whoC.length > 1 ? '${whoC.length} людей' : 'Він'}. ${meme[f] ?? 'Без коментарів.'}',
            capFull: ex ? meme[f] : '${whoC.length > 1 ? whoC.keys.map((k) => wp(k).name).join(', ') : wp(main).name}. ${meme[f] ?? 'Без коментарів.'}'),
        (shameTop.value / n).clamp(.3, 1.0),
        hit.length,
        f);
  }

  // Мем «Граблі»: той самий червоний у 3+ різних людей
  for (final rt in redTop(es)) {
    if (noJoke.contains(rt.key)) continue;
    final ppl = es.where((e) => e.flags.contains(rt.key)).map((e) => e.personId).toSet().toList();
    if (ppl.length < 3) continue;
    const emo = {'flag_r_phone': '📱', 'flag_r_late': '⏱', 'flag_r_ex': '👻', 'flag_r_self': '🎙', 'flag_r_cheap': '🪙', 'flag_r_jab': '🗯', 'flag_r_drunk': '🍷', 'flag_r_gone': '💨'};
    const cases = {3: 'трьох', 4: 'чотирьох', 5: "п'ятьох", 6: 'шістьох'};
    const scene = {
      'flag_r_phone': 'дістали телефон на побаченні',
      'flag_r_late': 'запізнились на побачення',
      'flag_r_ex': 'згадали колишню на побаченні',
      'flag_r_self': 'говорили тільки про себе',
      'flag_r_cheap': 'рахували копійки в чеку',
      'flag_r_jab': 'пожартували невдало',
      'flag_r_drunk': 'перебрали на побаченні',
      'flag_r_gone': 'зникли після побачення',
    };
    final lab = (flagById(rt.key)?.label ?? '').toLowerCase();
    final best = ([...ppl]..sort((a, b) => avg(ofP(b).map((e) => e.overall)).compareTo(avg(ofP(a).map((e) => e.overall))))).first;
    final all3 = ppl.length <= 3 ? 'всі троє' : 'всі ${ppl.length}';
    cand(
        WSlide(WK.rakes, 'Різні хлопці.', 'Той самий|прапорець',
            who: [for (final id in ppl.take(3)) wp(id)],
            n1: ppl.length,
            x: {'pill': '${emo[rt.key] ?? '⚑'} $lab — у всіх ${cases[ppl.length] ?? ppl.length}', 'meme': 'Коли $all3 ${scene[rt.key] ?? lab}', 'lvl': 'граблі · рівень ${ppl.length}'},
            capSafe: 'Навіть найкращий раз попався. Проблема, схоже, не в них.',
            capFull: 'Навіть ${wp(best).name} раз попався. Проблема, схоже, не в них.'),
        .8,
        ppl.length,
        rt.key);
    break;
  }

  // Номінації: прапорці 2+ рази, що не стали заголовками вище
  final noms = <WRow>[];
  final redsBy = <String, int>{};
  for (final e in es) {
    redsBy[e.personId] = (redsBy[e.personId] ?? 0) + e.flags.where((f) => flagById(f)?.kind == FlagKind.r).length;
  }
  final walker = (redsBy.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).firstOrNull;
  if (walker != null && walker.value >= 3) {
    noms.add(WRow('Ходячий червоний прапорець', '⚑', sub: ': ${walker.value} червоних за ${ofP(walker.key).length} ${plural(ofP(walker.key).length, 'зустріч', 'зустрічі', 'зустрічей')}', who: wp(walker.key)));
  }
  void addNom(String f, String title, String icon, String Function(int k, String id) sub) {
    final hit = es.where((e) => e.flags.contains(f)).toList();
    if (hit.length < 2) return;
    final c = <String, int>{};
    for (final e in hit) {
      c[e.personId] = (c[e.personId] ?? 0) + 1;
    }
    final id = (c.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    noms.add(WRow(title, icon, sub: sub(hit.length, id), who: c.length == 1 ? wp(id) : null));
  }

  addNom('flag_r_late', 'Майстер спорту з запізнень', '⏱', (k, id) => ', ${nTimes(k)}. Годинник, мабуть, декоративний');
  addNom('flag_r_cheap', 'Золотий гаманець', '₴', (k, id) => 'Рахував копійки. Заплатив ${countF(es, 'flag_g_paid')} ${plural(countF(es, 'flag_g_paid'), 'раз', 'рази', 'разів')}');
  addNom('flag_r_self', 'Людина-подкаст', '◉', (k, id) => ', ${nTimes(k)} говорив тільки про себе');
  addNom('flag_r_jab', 'Стендап року', '✦', (k, id) => ', ${nTimes(k)}. Ніхто не сміявся');
  final gBest = (gBy.entries.where((x) => x.value.length >= 2).toList()..sort((a, b) => b.value.length.compareTo(a.value.length))).firstOrNull;
  if (noms.length >= 2 || (noms.isNotEmpty && gBest != null)) {
    const short = {'flag_g_walk': 'провів', 'flag_g_paid': 'заплатив', 'flag_g_ontime': 'вчасно', 'flag_g_listen': 'слухав', 'flag_g_asks': 'питав', 'flag_g_gift': 'квіти', 'flag_g_remember': "пам'ятав", 'flag_g_texts': 'написав', 'flag_g_no': 'чув «ні»', 'flag_g_word': 'слово', 'flag_g_kind': 'чемний', 'flag_g_condom': 'захист'};
    final gl = gBest == null ? <String>[] : (gBest.value.toSet().toList()..sort((a, b) => gBest.value.where((x) => x == b).length.compareTo(gBest.value.where((x) => x == a).length))).take(3).map((f) => short[f] ?? '').toList();
    cand(
        WSlide(WK.oscars, 'Оскари', 'місяця',
            rows: noms.take(3).toList(),
            who: [if (gBest != null) wp(gBest.key)],
            x: {'cer': 'церемонія · ${noms.take(3).length + (gBest == null ? 0 : 1)} ${plural(noms.take(3).length + (gBest == null ? 0 : 1), 'номінація', 'номінації', 'номінацій')}', 'g': gl.join('|')},
            capSafe: 'Промову ніхто не підготував.'),
        .55,
        n);
  }

  // Ініціатива в ліжку: 2+ записи, хтось 80%+
  final initE = sx.where((e) => e.tags.contains('init_me') || e.tags.contains('init_him')).toList();
  if (initE.length >= 2) {
    final me = initE.where((e) => e.tags.contains('init_me')).length;
    final him = initE.length - me;
    final hisIds = initE.map((e) => e.personId).toSet();
    final heWho = hisIds.length == 1 ? wp(hisIds.first) : null;
    if (me / initE.length >= .8 || him / initE.length >= .8) {
      final mine = me >= him;
      cand(
          WSlide(WK.init, 'Хто почав:', mine ? 'ти, $me з ${initE.length}' : 'він, $him з ${initE.length}',
              who: [if (heWho != null) heWho],
              n1: me,
              n2: him,
              a: mine ? '$me/${initE.length}' : '$him/${initE.length}',
              b: mine ? 'ти перша' : 'він перший',
              capSafe: mine ? 'Він чекав, поки ти все зробиш сама. Як на роботі, тільки без зарплати.' : 'Нарешті хтось старається.'),
          ((mine ? me : him) / initE.length - .5) * 2,
          initE.length,
          'init');
    }
  }

  // Алкоголь і секс: по 2+ записи тверезо і з алкоголем, різниця 0,7+
  final sober = sx.where((e) => e.tags.contains('sober')).toList();
  final drink = sx.where((e) => e.tags.contains('alco1') || e.tags.contains('alco2')).toList();
  if (sober.length >= 2 && drink.length >= 2) {
    final a = avg(sober.map(sexOf)), b = avg(drink.map(sexOf));
    if ((a - b).abs() >= .7) {
      final d = b - a;
      cand(
          WSlide(WK.alco, 'Алкоголь', 'і секс',
              score: a,
              score2: b,
              n1: sober.length,
              n2: drink.length,
              a: '${d > 0 ? '+' : '−'}${fmt(d.abs())}',
              capSafe: d < 0 ? 'Тверезий секс на ${fmt(-d)} бала кращий. Вино розслабляє, але не там, де треба.' : 'З келихом на ${fmt(d)} бала краще. Тільки знай міру.'),
          ((a - b).abs() / 2).clamp(.3, 1.0),
          sober.length + drink.length);
    }
  }

  // Чия територія: 3+ записи з полем, одна сторона 60%+
  final his = es.where((e) => e.tags.contains('his')).toList();
  final mineT = es.where((e) => e.tags.contains('mine')).toList();
  final terr = his.length + mineT.length + es.where((e) => e.tags.contains('hotel') || e.tags.contains('other')).length;
  if (terr >= 3 && (his.length / terr >= .6 || mineT.length / terr >= .6)) {
    final atHis = his.length >= mineT.length;
    final a = avg(his.map((e) => e.overall)), b = avg(mineT.map((e) => e.overall));
    cand(
        WSlide(WK.territory, 'Чия', 'територія',
            n1: atHis ? his.length : mineT.length,
            n2: terr,
            score: a,
            score2: b,
            a: atHis ? 'ночей\nу нього' : 'ночей\nу тебе',
            capSafe: atHis
                ? (b.isNaN || a >= b ? 'Ти вже знаєш, де в нього рушники. І там тобі краще.' : 'Ти вже знаєш, де в нього рушники. Але вдома тобі краще.')
                : 'Твоя територія — твої правила.'),
        ((atHis ? his.length : mineT.length) / terr - .5) * 2,
        terr);
  }

  // Після: близькість або хто написав першим, 2+
  final cud = tagN('cuddle'), cold = tagN('cold'), tMe = tagN('text_me'), tHim = tagN('text_him');
  if (cud + cold >= 2 || tMe + tHim >= 2) {
    cand(
        WSlide(WK.after, 'Після', '',
            n1: cud,
            n2: cud + cold,
            rows: [
              if (cud + cold >= 2) WRow('Одразу в телефони', '$cold'),
              if (tMe + tHim >= 2) WRow('Першим написав', 'ти $tMe · він $tHim'),
            ],
            capSafe: cold >= 2 ? '${cap(nTimes(cold))} — скрол рілсів спиною одне до одного.' : (cud >= 2 ? 'Обіймались частіше, ніж гортали. Так і має бути.' : null)),
        cold >= 2 ? .6 : .35,
        cud + cold + tMe + tHim);
  }

  // Твій голос: сказала, чого хочеш / позначила межу 2+, якщо нема «Ти хотіла»
  final said = tagN('said'), lim = tagN('limit');
  if (wr.length < 2 && (said >= 2 || lim >= 2)) {
    final prevSaid = all.where((e) => monthKey(e.date) == iso(DateTime(y, m - 1, 1)).substring(0, 7) && e.tags.contains('said')).length;
    final record = said > prevSaid;
    cand(
        WSlide(WK.voice, 'Голос є.', 'Користуйся.',
            n1: said,
            flags: [record],
            rows: [
              if (lim > 0) WRow('Позначила межу', _times(lim), kind: 2),
              if (tagN('praise') > 0) WRow('Похвалила, що сподобалось', _times(tagN('praise')), kind: 2),
              if (tagN('stop') > 0) WRow('Зупинила, що не подобалось', _times(tagN('stop')), kind: 2),
              if (tagN('limit_missed') > 0) WRow('Хотіла, не сказала', _times(tagN('limit_missed')), kind: 1),
            ].take(3).toList(),
            capSafe: said > prevSaid ? 'У ${monthsLoc[(m + 10) % 12]} було $prevSaid. Це рекорд.' : 'Минулого місяця — $prevSaid. Тримай рівень.'),
        (said + lim) / (n * 2) + .2,
        said + lim);
  }

  // Архів колишніх: хто пішов у минулі цього місяця через «Він зник»
  final gone = db.people.where((p) => p.status == 'past' && p.pastReason == 'gone' && p.pastAt != null && monthKey(p.pastAt!) == month).toList();
  if (gone.isNotEmpty) {
    final p = gone.first;
    final last = all.where((e) => e.personId == p.id).map((e) => e.date).fold<String?>(null, (a, b) => a == null || b.compareTo(a) > 0 ? b : a);
    final silence = last == null ? 0 : parseIso(p.pastAt!).difference(parseIso(last)).inDays;
    final idx = ids.indexOf(p.id);
    cand(
        WSlide(WK.archive, 'Архів', 'колишніх',
            who: [WP(p.id, p.name, idx < 0 ? 'Він' : '№${idx + 1}')],
            x: {'last': last == null ? '' : '${parseIso(last).day} ${monthsGen[parseIso(last).month - 1]}', 'silence': '$silence ${plural(silence, 'день', 'дні', 'днів')} тиші', 'reason': '«${pastReasonLabel(p.pastReason)}»'},
            capSafe: 'Зник — значить зник. Справу закрито без права повернення.'),
        .6,
        1,
        'p:${p.id}');
  }

  // Він vs минулий місяць: одна людина весь місяць і з нею 2+ записи минулого
  if (ids.length == 1) {
    final id = ids.first;
    final pp = all.where((e) => e.personId == id && monthKey(e.date) == iso(DateTime(y, m - 1, 1)).substring(0, 7)).toList();
    if (pp.length >= 2) {
      double q(List<Entry> xs, String k) => k == 'sex'
          ? avg(xs.where((e) => e.hadSex).map(sexOf))
          : (k == 'eve' ? avg(xs.map((e) => e.overall)) : avg(xs.map((e) => e.ratings[k]).whereType<int>()));
      const keys = [('sex', 'Секс'), ('pt_hears', 'Чує тебе'), ('sx_pace', 'Темп'), ('pt_limits', 'Поважає межі'), ('sx_fore', 'Прелюдія'), ('pt_trust', 'Довіра'), ('eve', 'Вечір')];
      final rows = <WRow>[];
      for (final k in keys) {
        final a = q(pp, k.$1), b = q(ofP(id), k.$1);
        if (a.isNaN || b.isNaN) continue;
        final d = b - a;
        rows.add(WRow(k.$2, fmt(b), sub: fmt(a), kind: d.abs() < .3 ? 0 : (d > 0 ? 2 : 1)));
        if (rows.length == 3) break;
      }
      if (rows.length >= 2) {
        final up = rows.where((r) => r.kind == 2).length, down = rows.where((r) => r.kind == 1).length;
        final still = rows.where((r) => r.kind == 0).firstOrNull;
        final drop = rows.where((r) => r.kind == 1).firstOrNull;
        final pl = monthsLoc[(m + 10) % 12];
        cand(
            WSlide(WK.himPrev, up >= down ? 'Краще, ніж' : 'Гірше, ніж', 'у $pl',
                artOv: WArt.himPrev,
                who: [wp(id)],
                rows: rows,
                x: {'cols': '${monthsNom[(m + 10) % 12].substring(0, 3)} → ${monthsNom[m - 1].substring(0, 3)}'},
                capSafe: drop != null
                    ? 'Що просіло: ${drop.label.toLowerCase()} ${drop.sub} → ${drop.value}. Прямо.'
                    : (still != null ? '${still.label} — єдине, що не зрушило. Варто сказати.' : 'Росте по всіх пунктах. Так і тримай.')),
            .4 + .2 * (up - down).abs(),
            pp.length + ofP(id).length,
            'p:$id');
      }
    }
  }

  // Типаж місяця: перший, що спрацював, згори вниз (телефон — окремий слайд вище)
  if (ph.length < 3) {
    final exP = es.where((e) => e.flags.contains('flag_r_ex')).map((e) => e.personId).toSet();
    final night = tagN('night');
    final nightM = tagN('night') + tagN('left');
    final cheap = countF(es, 'flag_r_cheap');
    final ghosts = db.people.where((p) => ids.contains(p.id) && (es.any((e) => e.personId == p.id && e.flags.contains('flag_r_gone')) || (p.status == 'past' && p.pastReason == 'gone'))).length;
    final fakeN = tagN('o_fake');
    final seconds = ids.where((id) => ofP(id).length >= 2).length;
    WSlide? ty;
    String? fact;
    if (exP.length >= 2) {
      ty = WSlide(WK.type, 'Детекторка 🕵️‍♀️', 'чужих ексів', artOv: WArt.detective, a: '${exP.length}', b: '/${ids.length}', x: const {'lab': 'згадали\nколишню'},
          capSafe: '${exP.length} з ${ids.length} згадали колишню. Ти не на побаченні, ти на груповій терапії.');
      fact = 'flag_r_ex';
    } else if (initE.length >= 2 && initE.where((e) => e.tags.contains('init_me')).length / initE.length >= .8) {
      final me = initE.where((e) => e.tags.contains('init_me')).length;
      ty = WSlide(WK.type, 'Ген', 'директорка', artOv: WArt.boss, a: '$me', b: '/${initE.length}', x: const {'lab': 'почала\nти'}, capSafe: 'Почала ти $me з ${initE.length}. Він працює на півставки.');
      fact = 'init';
    } else if (night >= 3) {
      ty = WSlide(WK.type, 'Нічна', 'зміна', artOv: WArt.night, a: '$night', b: '/$nightM', x: const {'lab': 'лишалась\nна ніч'}, capSafe: 'Лишалась $night з $nightM ночей. Сніданок у договір не входив.');
    } else if (ids.length >= 4) {
      ty = WSlide(WK.type, 'Серійна 🎯', 'стрільчиня', artOv: WArt.serial, n1: n, n2: ids.length, a: '$seconds',
          x: {'l1': plural(n, 'побачення', 'побачення', 'побачень'), 'l2': plural(ids.length, menWord.$1, menWord.$2, menWord.$3), 'l3': seconds == 1 ? 'продовження' : 'продовжень'},
          capSafe: '$n ${plural(n, 'побачення', 'побачення', 'побачень')}, ${ids.length} ${plural(ids.length, 'різний', 'різні', 'різних')} ${plural(ids.length, menWord.$1, menWord.$2, menWord.$3)}, $seconds ${seconds == 1 ? 'продовження' : 'продовжень'}. ${seconds == 0 ? 'Кастинг триває.' : 'Кастинг звужується.'}');
    } else if (cheap >= 2) {
      ty = WSlide(WK.type, 'Фінансова 🧮', 'аудиторка', artOv: WArt.auditor, a: '$cheap', x: const {'lab': 'рахував\nкопійки'}, capSafe: 'Він рахував копійки ${_times(cheap)}. Ти рахувала його прапорці. Нічия.');
      fact = 'flag_r_cheap';
    } else if (ghosts >= 2) {
      ty = WSlide(WK.type, 'Відділ 👻', 'кадрів', artOv: WArt.hr, a: '$ghosts', x: const {'lab': 'звільнились\nбез відпрацювання'}, capSafe: '$ghosts ${plural(ghosts, 'звільнився', 'звільнились', 'звільнились')} без відпрацювання. Ghosting — теж відповідь.');
      fact = 'flag_r_gone';
    } else if (fakeN >= 2) {
      ty = WSlide(WK.type, 'Заслужена', 'артистка 🎭', artOv: WArt.artist, private: true, a: '$fakeN', b: '/${sx.length}', x: const {'lab': 'вдавала\nцього місяця'},
          capSafe: 'Станіславський аплодує стоячи. Деталі — на закритому показі.', capFull: 'Вдавала ${_times(fakeN)} з ${sx.length}. Станіславський аплодує стоячи. Він нічого не помітив.');
    }
    if (ty != null) cand(ty, .75, n, fact);
  }

  // 15. Нагороди місяця
  final fixedEnd = <WSlide>[];
  fixedEnd.add(awards.isEmpty
      ? const WSlide(WK.awards, '0 нагород', '', capSafe: 'Чесно: цього місяця нічого не відкрилось.')
      : WSlide(WK.awards, '+${awards.length} ${plural(awards.length, 'нагорода', 'нагороди', 'нагород')}', '',
          rows: [for (final a in awards.take(3)) WRow(a.lv > 1 ? '${a.d.name} · рівень ${a.lv}' : a.d.name, '', sub: a.d.desc)]));

  // 16. Цей місяць проти минулого
  final prev = DateTime(y, m - 1, 1);
  final pk = iso(prev).substring(0, 7);
  final pes = all.where((e) => monthKey(e.date) == pk).toList();
  WSlide? glowS;
  if (pes.length >= 2) {
    final po = avg(pes.map((e) => e.overall));
    final pr = pes.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).length;
    final ps = pes.where((e) => e.tags.contains('said')).length;
    final cs = tagN('said');
    var score = 0;
    if (overall - po >= .3) score++;
    if (reds.length < pr) score++;
    if (cs > ps) score++;
    final verdict = score >= 2 ? 'glow up' : (score == 1 ? 'нічия' : 'відкат');
    final parts = [
      overall - po >= .3 ? 'Оцінка вище' : (po - overall >= .3 ? 'Оцінка нижче' : 'Оцінка без змін'),
      reds.length < pr ? 'прапорців менше' : (reds.length > pr ? 'прапорців більше' : 'прапорців стільки ж'),
    ];
    glowS = WSlide(WK.glow, '$nom vs', '${monthsNom[prev.month - 1]}: $verdict',
        rows: [
          WRow('Середня', fmt(overall), sub: fmt(po), kind: overall >= po ? 1 : 3),
          WRow('Ред-флаги', '${reds.length}', sub: '$pr', kind: reds.length <= pr ? 3 : 1),
          WRow('Сказала', '$cs', sub: '$ps', kind: cs >= ps ? 1 : 3),
        ],
        ints: [bd.day, DateTime(y, m, 1).weekday],
        a: nom,
        b: monthsNom[prev.month - 1].substring(0, 3),
        c: monthsNom[m - 1].substring(0, 3),
        capSafe: '${parts.join(', ')}${cs > ps ? ', і ти частіше кажеш, чого хочеш.' : '.'}');
  }

  // Таро / гороскоп / квартальний звіт: чергуються з «проти минулого»
  final opts = <WSlide>[if (glowS != null) glowS];
  final topRed = redTop(es).where((x) => x.value >= 2).firstOrNull;
  final newSign = ids.where((id) => isNew(id)).map(per).whereType<Person>().where((p) => astroOf(p.birth, p.signOnly) != null).firstOrNull;
  if (topRed != null || newSign != null) {
    final myArc = db.profile.birth == null ? 14 : arcanaOf(db.profile.birth!);
    final arc = reduce22(myArc + m);
    const advice = {
      'flag_r_phone': 'Якщо ще раз підеш на каву з тим, хто сидить у телефоні, вселенський баланс трісне і ти почнеш кусати людей. Зроби перерву.',
      'flag_r_late': 'Якщо знову чекатимеш пів години — не чекай. Карта каже: йди першою.',
      'flag_r_ex': 'Якщо знову почуєш про колишню — це не побачення, це сеанс. Не йди на другу зустріч.',
      'flag_r_self': 'Якщо знову слухатимеш монолог — дай йому мікрофон і йди додому.',
      'flag_r_cheap': 'Якщо знову ділитимете чек до гривні — карта радить ділити й прощання.',
      'flag_r_jab': 'Якщо знову підколюватиме — це не флірт. Не йди на другу зустріч.',
      'flag_r_drunk': 'Якщо знову перебере — вечір закінчується разом із його келихом.',
      'flag_r_gone': 'Якщо знову зникне — не шукай. Карта каже: ти не служба розшуку.',
    };
    final f = topRed?.key;
    final tip = f != null
        ? (advice[f] ?? 'Якщо знову ${(flagById(f)?.label ?? '').toLowerCase()} — не йди на другу зустріч.')
        : 'Новий знак на горизонті: ${astroOf(newSign!.birth, newSign.signOnly)!.signName}. Карта радить не поспішати.';
    opts.add(WSlide(WK.tarot, 'Таро', 'на ${monthsNom[m % 12]}', a: roman[arc], b: arcana[arc].name, capSafe: tip));
  }
  final me = db.profile.birth == null ? null : astroOf(db.profile.birth);
  if (me != null) {
    for (final id in ids) {
      final p = per(id);
      final hs = p == null ? null : astroOf(p.birth, p.signOnly);
      final ps = sx.where((e) => e.personId == id).toList();
      if (hs == null || ps.length < 2) continue;
      final easy = zodiacEase(me.sign, hs.sign) == 'Легко';
      final sv = avg(ps.map(sexOf));
      if (easy == sv >= 3.5) continue; // зорі й записи не сперечаються — нема слайда
      const verbs = {'flag_r_phone': 'сидить у телефоні', 'flag_r_late': 'запізнюється', 'flag_r_ex': 'згадує колишню', 'flag_r_self': 'говорить про себе', 'flag_r_cheap': 'рахує копійки', 'flag_r_jab': 'підколює', 'flag_r_drunk': 'перебирає', 'flag_r_jealous': 'ревнує', 'flag_r_gone': 'зникає', 'flag_r_lie': 'бреше', 'flag_r_push': 'квапить'};
      final rv = redTop(ofP(id)).map((x) => verbs[x.key]).whereType<String>().take(2).toList();
      opts.add(WSlide(WK.horo, 'Зорі брешуть,', 'метрики ні',
          who: [wp(id)],
          score: sv,
          a: '${me.signName} і ${hs.signName} — ${easy ? 'пристрасть' : 'складно'}',
          b: rv.isEmpty ? 'Без жодного прапорця.' : '${cap(rv.join(' і '))}.',
          capSafe: easy ? 'Довіряй таблиці, а не зорям.' : 'Зорі сумнівались. Записи — ні.'));
      break;
    }
  }
  if (m % 3 == 0) {
    final qm = [for (var k = 2; k >= 0; k--) iso(DateTime(y, m - k, 1)).substring(0, 7)];
    final qe = all.where((e) => qm.contains(monthKey(e.date))).toList();
    final active = qm.where((k) => qe.any((e) => monthKey(e.date) == k)).length;
    if (active >= 2) {
      final pq = [for (var k = 5; k >= 3; k--) iso(DateTime(y, m - k, 1)).substring(0, 7)];
      final pe = all.where((e) => pq.contains(monthKey(e.date))).toList();
      final idx = avg(qe.map((e) => e.overall));
      final pidx = avg(pe.map((e) => e.overall));
      final pct = pidx.isNaN ? null : ((idx / pidx - 1) * 100).round();
      final four = [for (var k = 3; k >= 0; k--) DateTime(y, m - k, 1)];
      final metQ = qe.map((e) => e.personId).toSet().where((id) => !all.any((e) => e.personId == id && e.date.compareTo('${qm.first}-01') < 0)).toList();
      final conv = metQ.isEmpty ? 0 : (metQ.where((id) => qe.where((e) => e.personId == id).length >= 2).length / metQ.length * 100).round();
      final qRed = qe.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).length;
      final ignored = qe.where((e) => e.flags.any((x) => flagById(x)?.kind == FlagKind.r) && all.any((o) => o.personId == e.personId && o.date.compareTo(e.date) > 0)).length;
      final fired = db.people.where((p) => p.pastAt != null && qm.contains(monthKey(p.pastAt!))).length;
      opts.insert(0, WSlide(WK.quarter, 'Квартальний', 'звіт',
          score: idx,
          ints: [for (final d in four) all.where((e) => monthKey(e.date) == iso(d).substring(0, 7)).isEmpty ? -1 : (avg(all.where((e) => monthKey(e.date) == iso(d).substring(0, 7)).map((e) => e.overall)) * 100).round()],
          rows: [for (final d in four) WRow(monthsNom[d.month - 1].substring(0, 3), '')],
          x: {
            'q': 'Q${(m - 1) ~/ 3 + 1} · ${m.toString().padLeft(2, '0')}/${(y % 100).toString().padLeft(2, '0')}',
            'pct': pct == null ? '' : '${pct >= 0 ? '▲' : '▼'} ${pct.abs()}%',
            'vs': 'рентабельність вечора\nдо ${monthsGen[DateTime(y, m - 3, 1).month - 1]}',
            'conv': '$conv%',
            'convL': conv >= 70 ? 'ринок перегрітий' : (conv >= 30 ? 'стабільний попит' : 'жорсткий відбір'),
            'risk': '$qRed/$ignored',
            'fired': '$fired',
            'stamp': idx >= 3.5 ? 'Аудит пройдено*' : 'Аудит не пройдено',
          },
          capSafe: idx >= 3.5 ? 'Рада директорів задоволена.\n*Майже.' : 'Рада директорів скликає нараду.'));
    }
  }
  if (opts.isNotEmpty) fixedEnd.add(m % 3 == 0 && opts.first.k == WK.quarter ? opts.first : opts[m % opts.length]);

  // ---- Відбір: акти 2–6 з лімітами слотів
  const acts = <WK, int>{
    WK.sex: 2, WK.orgasm: 2, // Секс
    WK.match: 3, WK.matrix: 3, WK.battle: 3, WK.dossier: 3, WK.reviews: 3, WK.size: 3, WK.archive: 3, WK.himPrev: 3, // Хлопці
    WK.phone: 4, WK.type: 4, WK.fame: 4, WK.clown: 4, WK.rakes: 4, WK.oscars: 4, // Прапорці
    WK.longest: 5, WK.fastest: 5, WK.budget: 5, WK.init: 5, WK.alco: 5, WK.territory: 5, WK.after: 5, // Рекорди
    WK.wishes: 6, WK.voice: 6, WK.notice: 6, // Ти
  };
  const slots = <int, (int, int)>{2: (0, 2), 3: (1, 3), 4: (1, 2), 5: (0, 3), 6: (0, 2)};
  // новизна: 0,5, якщо такий слайд уже був у минулому Wrapped
  final prevKinds = novelty ? buildWrapped(pk, db, novelty: false).slides.map((x) => x.k).toSet() : <WK>{};
  double dataF(int r) => r >= 4 ? 1 : (r >= 2 ? .7 : .4);
  final cands = out.where(meta.containsKey).toList();
  final score = {for (final c in cands) c: meta[c]!.$1 * (prevKinds.contains(c.k) ? .5 : 1) * dataF(meta[c]!.$2)};
  // один факт — один заголовок: факт забирає слайд з вищим балом, решта з тим самим фактом падає вниз
  final taken = <String>{};
  final demoted = <WSlide>{};
  for (final c in [...cands]..sort((a, b) => score[b]!.compareTo(score[a]!))) {
    final f = meta[c]!.$3;
    if (f == null) continue;
    if (!taken.add(f)) demoted.add(c);
  }
  final picked = <WSlide>[];
  for (final act in const [2, 3, 4, 5, 6]) {
    final (lo, hi) = slots[act]!;
    final inAct = cands.where((c) => acts[c.k] == act).toList()
      ..sort((a, b) {
        final da = demoted.contains(a) ? 1 : 0, dbb = demoted.contains(b) ? 1 : 0;
        return da != dbb ? da - dbb : score[b]!.compareTo(score[a]!);
      });
    // «Варто помітити» — завжди, якщо є підстава
    final chosen = <WSlide>[...inAct.where((c) => c.k == WK.notice)];
    for (final c in inAct) {
      if (chosen.length >= hi) break;
      if (chosen.contains(c)) continue;
      if (demoted.contains(c) && chosen.length >= lo) continue;
      chosen.add(c);
    }
    chosen.sort((a, b) => a.k.index.compareTo(b.k.index));
    picked.addAll(chosen);
  }
  out
    ..removeWhere(meta.containsKey)
    ..addAll(picked)
    ..addAll(fixedEnd);
  // головний факт місяця — слайд з найвищим балом; з нього речення для стрічки фіналу
  // приватні слайди («Варто помітити», оргазми) в стрічку фіналу не йдуть — вона потрапляє в сторіз
  final topSlide = (picked.where((x) => !x.private).toList()..sort((a, b) => score[b]!.compareTo(score[a]!))).firstOrNull;
  final mainFact = topSlide == null ? '' : '${topSlide.title1} ${topSlide.t2(true).replaceAll('|', ' ')}'.trim();

  // 17. Місяць загорнуто: топ-моменти з уже зібраних слайдів + твої числа
  out.add(WSlide(WK.closed, nom, 'загорнуто.',
      score: overall,
      rows: [..._moments(out), ..._numbers(overall, n, ids.length, menWord, greens.length, reds.length)],
      a: 'vespr · ${m.toString().padLeft(2, '0')}/${(y % 100).toString().padLeft(2, '0')}',
      b: 'до зустрічі в ${monthsLoc[m % 12]} ✦',
      capSafe: '${mainFact.isEmpty ? '' : '${mainFact.replaceAll(RegExp(r'[.:]$'), '')}. '}${pes.length >= 2 && reds.length < pes.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).length ? 'Граблі стали меншими. ' : ''}${cap(monthsNom[m % 12])}, ми готові. Майже.'));

  // 18. Квиток для чату
  final verdict = overall >= 4.3 ? '«це було гарно»' : (overall >= 3.3 ? '«жити можна»' : '«бувало й краще»');
  out.add(WSlide(WK.ticket, 'Для чату:', 'вердикт $verdict',
      who: [wp(best.personId)],
      a: '${_placeWord(best)} в ${weekdays[bd.weekday] == 'субота' ? 'суботу' : (weekdays[bd.weekday] == 'середа' ? 'середу' : (weekdays[bd.weekday] == 'пʼятниця' ? 'пʼятницю' : (weekdays[bd.weekday] == 'неділя' ? 'неділю' : weekdays[bd.weekday])))}',
      b: reds.isEmpty ? 'без зашкварів' : (flagById(_mode(reds))?.label.toLowerCase() ?? ''),
      n1: n,
      n2: awards.length,
      capSafe: 'Квиток без подробиць: кидай подругам у Telegram чи сторіз.'));

  return Wrapped(month, label, monthsNom[m - 1], monthsGen[m - 1], out, n);
}

/// Топ-моменти фіналу: беремо з уже зібраних слайдів, до 5
List<WRow> _moments(List<WSlide> out) {
  const order = [WK.best, WK.longest, WK.match, WK.budget, WK.fastest, WK.fame, WK.wishes];
  final r = <WRow>[];
  for (final k in order) {
    final s = out.where((x) => x.k == k).firstOrNull;
    if (s == null) continue;
    switch (k) {
      case WK.best:
        r.add(WRow('Найкращий вечір', s.b, who: s.who.firstOrNull));
      case WK.longest:
        r.add(const WRow('Рекорд', '40+ хвилин'));
      case WK.match:
        r.add(WRow('Метч місяця', fmt(s.score2 > s.score ? s.score2 : s.score), who: s.who.firstOrNull));
      case WK.budget:
        r.add(WRow('Бюджет', '${s.a} · ${s.title2}'));
      case WK.fastest:
        r.add(const WRow('Спринтер', 'до 5 хв'));
      case WK.fame:
        r.add(WRow('Зала слави', '', who: s.who.firstOrNull));
      case WK.wishes:
        r.add(WRow('Ти хотіла', s.title2));
      default:
    }
  }
  return r.take(5).toList();
}

/// «Твої числа» фіналу (kind 9)
List<WRow> _numbers(double overall, int n, int men, (String, String, String) menWord, int g, int r) => [
      WRow('бал', fmt(overall), kind: 9),
      WRow(plural(n, 'побачення', 'побачення', 'побачень'), '$n', kind: 9),
      WRow(plural(men, menWord.$1, menWord.$2, menWord.$3), '$men', kind: 9),
      WRow(plural(g, 'грін-флаг', 'грін-флаги', 'грін-флагів'), '$g', kind: 9),
      WRow(plural(r, 'ред-флаг', 'ред-флаги', 'ред-флагів'), '$r', kind: 9),
    ];

/// Карточка архіву: головна цифра місяця і підпис
(String, String) wrappedTeaser(String month, DB db) {
  final es = db.entries.where((e) => monthKey(e.date) == month).toList();
  if (es.isEmpty) return ('0', 'побачень. Сезон пледу');
  final ids = es.map((e) => e.personId).toSet();
  final reds = es.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).toList();
  final best = es.map((e) => e.overall).reduce((a, b) => a > b ? a : b);
  if (reds.length >= 2) {
    final by = <String>{for (final e in es.where((e) => e.flags.any((x) => flagById(x)?.kind == FlagKind.r))) e.personId};
    return ('${reds.length}', '${plural(reds.length, 'червоний прапорець', 'червоні прапорці', 'червоних прапорців')}${by.length == 1 ? (reds.length == 2 ? ', і обидва від одного' : ', і всі від одного') : ''}');
  }
  if (ids.length >= 2) return ('${ids.length}', '${plural(ids.length, 'нова людина', 'нових людини', 'нових людей')} за місяць');
  return ('$best', 'найкраща оцінка місяця');
}
