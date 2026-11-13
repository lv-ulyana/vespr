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
enum WK { cover, receipt, best, sex, orgasm, match, matrix, battle, phone, fame, longest, fastest, budget, wishes, notice, awards, glow, closed, ticket }

/// Людина на слайді: справжнє ім'я і безпечна підміна («Він №1»)
class WP {
  final String id, name, safe;
  const WP(this.id, this.name, this.safe);
  String show(bool safeMode) => safeMode ? safe : name;
}

class WRow {
  final String label, value;
  final String? sub;
  final int kind; // 0 звичайний, 1 червоний, 2 зелений, 3 жовтий акцент, 4 закреслений
  final WP? who;
  const WRow(this.label, this.value, {this.sub, this.kind = 0, this.who});
}

class WSlide {
  final WK k;
  final String title1, title2; // два рядки заголовка; title2 — акцентний (рожевий на темному)
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
  const WSlide(this.k, this.title1, this.title2,
      {this.capSafe, this.capFull, this.rows = const [], this.score = 0, this.score2 = 0, this.n1 = 0, this.n2 = 0, this.a = '', this.b = '', this.c = '', this.who = const [], this.ints = const [], this.flags = const [], this.private = false});
  String? cap(bool safe) => safe ? capSafe : (capFull ?? capSafe);
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

Wrapped buildWrapped(String month, DB db) {
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
    out.add(WSlide(WK.cover, '$nom:', 'сезон пледу', capSafe: '0 побачень. Плед, серіал, какао. Найздоровіші стосунки місяця.'));
    out.add(WSlide(WK.closed, nom, 'закрито', score: double.nan, capSafe: '${cap(monthsNom[m % 12])}, ми готові. Майже.'));
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

  // 0. Обкладинка
  out.add(WSlide(WK.cover, '$nom:', 'звіт про виживання',
      capSafe: '$n ${plural(n, 'побачення', 'побачення', 'побачень')}, ${ids.length} ${plural(ids.length, menWord.$1, menWord.$2, menWord.$3)}'
          '${awards.isEmpty ? '.' : awards.length == 1 ? ' і одна нагорода, якою не похвалишся.' : ' і ${awards.length} ${plural(awards.length, 'нагорода', 'нагороди', 'нагород')}.'}'));

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
        if (sx.isNotEmpty) WRow('Секс', '${sxAvg.round()}/5'),
        if (tagN('alco1') > 0) WRow('«Келих-два»', '${tagN('alco1')} шт'),
        if (tagN('alco2') > 0) WRow('«Більше»', '${tagN('alco2')} шт'),
        WRow('Ред-флаги', '${reds.length} шт', kind: 1),
        WRow('Грін-флаги', '${greens.length} шт', kind: 2),
      ]));

  if (n < 3) {
    out.add(WSlide(WK.closed, nom, 'закрито', score: overall, capSafe: 'Ще ${3 - n} — і буде повний Wrapped з рекордами й нагородами.'));
    return Wrapped(month, label, monthsNom[m - 1], monthsGen[m - 1], out, n);
  }

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
    out.add(WSlide(WK.sex, 'Секс у ${monthsLoc[m - 1]}:', rateWord(s), score: s, rows: rows.take(4).toList(), capSafe: cp));

    // 4. Оргазми місяця (приватний у сторіз)
    if (sx.any((e) => e.tags.any((t) => t.startsWith('o_')))) {
      final om = sx.where((e) => e.tags.contains('o_me') || e.tags.contains('o_multi')).length;
      final oh = sx.where((e) => e.tags.contains('o_him')).length;
      final multi = sx.where((e) => e.tags.contains('o_multi')).toList();
      final fake = sx.where((e) => e.tags.contains('o_fake')).length;
      final parts = <String>[
        oh > om ? 'Рахунок $oh:$om не на твою користь.' : (om > oh ? 'Рахунок $om:$oh на твою користь.' : 'Рахунок $om:$oh, нічия.'),
        if (multi.isNotEmpty) 'Кілька за ніч: ${_times(multi.length)}, ${_shortDate(multi.last.date)}.',
        fake == 0 ? 'Вдавала: 0, так і тримай.' : 'Вдавала: $fake.',
      ];
      out.add(WSlide(WK.orgasm, 'Оргазми', 'місяця', n1: om, n2: oh, score: sx.length.toDouble(), capSafe: parts.join(' '), private: true));
    }
  }

  // 5. Метч місяця: людина з найкращою сумою характер + секс (мінімум 2 зустрічі і секс)
  final cand = ids.where((id) => es.where((e) => e.personId == id).length >= 2 && sx.any((e) => e.personId == id)).toList();
  if (cand.isNotEmpty) {
    double ch(String id) => avg(es.where((e) => e.personId == id).map((e) => e.overall));
    double sv(String id) => avg(sx.where((e) => e.personId == id).map((e) => e.ratings['sx_overall'] ?? e.overall));
    cand.sort((a, b) => (ch(b) + sv(b)).compareTo(ch(a) + sv(a)));
    final id = cand.first;
    final c = ch(id), s = sv(id);
    final p = db.people.where((x) => x.id == id).firstOrNull;
    final me = astroOf(db.profile.birth), him = p == null ? null : astroOf(p.birth, p.signOnly);
    final word = (c + s) / 2 >= 4.3 ? 'повне комбо' : ((c + s) / 2 >= 3.5 ? 'майже комбо' : 'так собі комбо');
    out.add(WSlide(WK.match, 'Метч місяця:', word,
        score: c,
        score2: s,
        who: [wp(id)],
        a: me?.signName ?? '',
        b: him?.signName ?? '',
        c: me != null && him != null ? 'зірки кажуть: ${zodiacEase(me.sign, him.sign).toLowerCase()}' : ''));
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
  if (byCount.length >= 2) {
    final a = byCount[0], b = byCount[1];
    final qa = quad(a), qb = quad(b);
    out.add(WSlide(WK.matrix, 'Матриця', 'типажів',
        who: [wp(a), wp(b)],
        ints: [qa, qb],
        capSafe: 'Один ${qPhrase[qa]}. Другий: ${qPhrase[qb]}.',
        capFull: '${wp(a).name} ${qPhrase[qa]}. ${wp(b).name}: ${qPhrase[qb]}.'));

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
      out.add(WSlide(WK.battle, 'Битва місяця', '',
          who: [wp(a), wp(b), wp(win)],
          n1: pa,
          n2: pb,
          rows: rows,
          capSafe: 'Рахунок ${sa >= sb ? sa : sb} : ${sa >= sb ? sb : sa}. Fatality: ${sa >= sb ? 'гравець 1' : 'гравець 2'} просто $fatal.',
          capFull: 'Рахунок ${sa >= sb ? sa : sb} : ${sa >= sb ? sb : sa}. Fatality: ${wp(win).name} просто $fatal.'));
    }
  }

  // 8. Конкурентка айфона
  final ph = es.where((e) => e.flags.contains('flag_r_phone')).toList();
  if (ph.length >= 2) {
    final shown = es.length > 7 ? es.sublist(es.length - 7) : es;
    final who = <String, int>{};
    for (final e in ph) {
      who[e.personId] = (who[e.personId] ?? 0) + 1;
    }
    final full = (who.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).map((x) => '${x.value == 1 ? 'раз' : _times(x.value)} ${wp(x.key).name}').join(', ');
    out.add(WSlide(WK.phone, 'Твій типаж:', 'конкурентка айфона',
        flags: shown.map((e) => e.flags.contains('flag_r_phone')).toList(),
        n1: ph.length,
        n2: n - ph.length,
        capSafe: '$n ${plural(n, 'вечір', 'вечори', 'вечорів')}: ${_times(ph.length)} виграв екран, ${_times(n - ph.length)} ти.',
        capFull: '$n ${plural(n, 'вечір', 'вечори', 'вечорів')}: ${_times(ph.length)} виграв екран, ${_times(n - ph.length)} ти. ${cap(full)}.'));
  }

  // 9. Зала слави: найбільше зелених прапорців
  final gBy = <String, List<String>>{};
  for (final e in es) {
    gBy.putIfAbsent(e.personId, () => []).addAll(e.flags.where((x) => flagById(x)?.kind == FlagKind.g));
  }
  final fameId = gBy.entries.where((x) => x.value.length >= 3).toList()..sort((x, y) => y.value.length.compareTo(x.value.length));
  if (fameId.isNotEmpty) {
    final g = fameId.first.value;
    final cnt = <String, int>{};
    for (final x in g) {
      cnt[x] = (cnt[x] ?? 0) + 1;
    }
    final top = (cnt.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).take(3).toList();
    out.add(WSlide(WK.fame, 'Зала слави:', 'він знає, хто він',
        who: [wp(fameId.first.key)],
        rows: [for (final t in top) WRow(flagById(t.key)?.label ?? '', '×${t.value}', sub: '${t.value / top.first.value}')],
        capSafe: 'Виявляється, так можна було.'));
  }

  // 10–11. Рекорди витривалості
  final stam = sx.where((e) => e.facts['f_stam'] != null).toList();
  final longE = stam.where((e) => e.facts['f_stam'] == 3).toList();
  if (longE.isNotEmpty) {
    final e = (longE..sort((a, b) => (b.ratings['sx_overall'] ?? b.overall).compareTo(a.ratings['sx_overall'] ?? a.overall))).first;
    out.add(WSlide(WK.longest, 'Рекорд місяця:', 'незламний', rows: [
      const WRow('Найдовший секс', '40+ хв'),
      WRow(' · ${_shortDate(e.date)}', '${e.ratings['sx_overall'] ?? e.overall}/5', who: wp(e.personId)),
      if (e.tags.contains('multi')) const WRow('Заходів за ніч', '2+'),
    ]));
  }
  final fastE = stam.where((e) => e.facts['f_stam'] == 0).toList();
  if (fastE.isNotEmpty) {
    final e = fastE.last;
    final fin = e.tags.contains('o_me') || e.tags.contains('o_multi');
    out.add(WSlide(WK.fastest, 'Рекорд місяця:', 'спринтер', rows: [
      const WRow('Найшвидший секс', 'до 5 хв'),
      WRow(' · ${_shortDate(e.date)}', '${e.ratings['sx_overall'] ?? e.overall}/5', who: wp(e.personId)),
      WRow('Твій фінал', fin ? 'встигла' : 'не встигла'),
    ]));
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
    out.add(WSlide(WK.budget, 'Бюджет місяця:', '$gifts ${plural(gifts, 'квітка', 'квітки', 'квітів')}',
        a: '~$total',
        rows: [
          if (rest.isNotEmpty) WRow('Ресторани ×${rest.length}', '~$restSum', sub: '${restSum / mx}'),
          if (cafe.isNotEmpty) WRow('Кава ×${cafe.length}', '~$cafeSum', sub: '${cafeSum / mx}'),
          WRow('Квіти', '$gifts', sub: gifts == 0 ? '0' : '0.2', kind: gifts == 0 ? 4 : 0),
        ],
        capSafe: 'Заплатив сам: $paid з $n ${plural(n, 'вечора', 'вечорів', 'вечорів')}. ${paid * 2 >= n ? 'Джентльмен.' : 'Бухгалтерія плаче.'}'));
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
    out.add(WSlide(WK.wishes, 'Ти хотіла:', 'вийшло $ok із ${wr.length}', rows: wr.take(3).toList(), n1: ok, n2: wr.length));
  }

  // 14. Варто помітити — спокійно, без жартів, тільки для неї
  final sore = <WRow>[];
  void addSore(String title, bool Function(Entry) f) {
    final hit = es.where(f).toList();
    if (hit.isEmpty) return;
    final e = hit.last;
    sore.add(WRow(title, '${_times(hit.length)} · ${_longDate(e.date)}', who: wp(e.personId)));
  }
  addSore('Хотіла сказати «ні» і не сказала', (e) => e.tags.contains('limit_missed'));
  addSore('Без захисту', (e) => e.tags.contains('noprot'));
  addSore('Був дискомфорт', (e) => e.tags.contains('pain'));
  addSore('Він тиснув і квапив', (e) => e.flags.contains('flag_r_push'));
  if (sore.isNotEmpty) {
    out.add(WSlide(WK.notice, 'Варто помітити', '', rows: sore.take(2).toList(), private: true, capSafe: 'Це не вирок і не жарт. Просто факт, щоб ти його бачила.'));
  }

  // 15. Нагороди місяця
  if (awards.isNotEmpty) {
    out.add(WSlide(WK.awards, '+${awards.length} ${plural(awards.length, 'нагорода', 'нагороди', 'нагород')}', '',
        rows: [for (final a in awards.take(3)) WRow(a.lv > 1 ? '${a.d.name} · рівень ${a.lv}' : a.d.name, '', sub: a.d.desc)]));
  }

  // 16. Цей місяць проти минулого
  final prev = DateTime(y, m - 1, 1);
  final pk = iso(prev).substring(0, 7);
  final pes = all.where((e) => monthKey(e.date) == pk).toList();
  if (pes.isNotEmpty) {
    final po = avg(pes.map((e) => e.overall));
    final pr = pes.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).length;
    final ps = pes.where((e) => e.tags.contains('said')).length;
    final cs = tagN('said');
    var score = 0;
    if (overall > po) score++;
    if (reds.length < pr) score++;
    if (cs > ps) score++;
    final verdict = score >= 2 ? 'glow up' : (score == 1 ? 'нічия' : 'відкат');
    final parts = [
      overall > po ? 'Оцінка вище' : (overall < po ? 'Оцінка нижче' : 'Оцінка та сама'),
      reds.length < pr ? 'прапорців менше' : (reds.length > pr ? 'прапорців більше' : 'прапорців стільки ж'),
    ];
    out.add(WSlide(WK.glow, '$nom vs', '${monthsNom[prev.month - 1]}: $verdict',
        rows: [
          WRow('Середня', fmt(overall), sub: fmt(po), kind: overall >= po ? 1 : 3),
          WRow('Ред-флаги', '${reds.length}', sub: '$pr', kind: reds.length <= pr ? 3 : 1),
          WRow('Сказала', '$cs', sub: '$ps', kind: cs >= ps ? 1 : 3),
        ],
        ints: [bd.day, DateTime(y, m, 1).weekday],
        a: nom,
        b: monthsNom[prev.month - 1].substring(0, 3),
        c: monthsNom[m - 1].substring(0, 3),
        capSafe: '${parts.join(', ')}${cs > ps ? ', і ти частіше кажеш, чого хочеш.' : '.'}'));
  }

  // 17. Місяць закрито
  out.add(WSlide(WK.closed, nom, 'закрито',
      score: overall,
      capSafe: '${pes.isNotEmpty && reds.length < pes.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).length ? 'Граблі стали меншими. ' : ''}${cap(monthsNom[m % 12])}, ми готові. Майже.'));

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
