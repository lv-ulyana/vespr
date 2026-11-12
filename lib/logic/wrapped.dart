// Генератор Wrapped без ШІ: умови перевіряються згори вниз, у шаблон підставляються справжні цифри.
// Принципи: тільки факти; нема даних — нема слайду; стьобемо хлопців, не її; болюче — окремо і ніколи в сторіз.
import '../data/catalog.dart';
import '../data/models.dart';
import 'dates.dart';
import 'stats.dart';

enum SlideTheme { navy, pink, yellow }

class SlideRow {
  final String label, value;
  const SlideRow(this.label, this.value);
}

class Slide {
  final String key, title;
  final SlideTheme theme;
  final String? eyebrow, accent, big, bigLabel, caption;
  final List<SlideRow> rows;
  final bool private;
  const Slide({required this.key, required this.theme, required this.title, this.eyebrow, this.accent, this.big, this.bigLabel, this.caption, this.rows = const [], this.private = false});
}

class Wrapped {
  final String month, label;
  final List<Slide> slides;
  final bool mini;
  final int count;
  const Wrapped(this.month, this.label, this.slides, this.mini, this.count);
}

const freeSlides = 3;

String _mode(List<String> xs) {
  final c = <String, int>{};
  for (final x in xs) {
    c[x] = (c[x] ?? 0) + 1;
  }
  return (c.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
}

String _times(int n) => '$n ${plural(n, 'раз', 'рази', 'разів')}';

Wrapped buildWrapped(String month, List<Entry> all, List<Person> people) {
  final y = int.parse(month.substring(0, 4)), m = int.parse(month.substring(5, 7));
  final label = '${cap(monthsNom[m - 1])} $y';
  final es = all.where((e) => monthKey(e.date) == month).toList()..sort((a, b) => a.date.compareTo(b.date));
  String nm(String id) => people.firstWhere((p) => p.id == id, orElse: () => Person(id: '', name: '—', createdAt: '')).name;
  final slides = <Slide>[];
  final ppl = es.map((e) => e.personId).toSet().toList();

  if (es.isEmpty) {
    slides.add(Slide(key: 'empty', theme: SlideTheme.navy, eyebrow: label, title: 'Сезон', accent: 'пледу', big: '0', bigLabel: 'побачень', caption: 'Плед, серіал, какао. Найздоровіші стосунки місяця.'));
    return Wrapped(month, label, slides, true, 0);
  }
  final overall = avg(es.map((e) => e.overall));

  // 1. Обкладинка
  slides.add(Slide(
    key: 'cover', theme: SlideTheme.pink, eyebrow: label, title: '${cap(monthsNom[m - 1])}:',
    accent: ppl.length == 1 ? 'з ${nm(ppl.first)}' : 'звіт про виживання',
    big: fmt(overall), bigLabel: 'середня оцінка · ${rateWord(overall)}',
    caption: '${es.length} ${plural(es.length, 'зустріч', 'зустрічі', 'зустрічей')}, ${ppl.length} ${plural(ppl.length, 'людина', 'людини', 'людей')}.',
  ));

  // Міні-Wrapped: 1–2 записи
  if (es.length < 3) {
    final bestMini = (es.toList()..sort((a, b) => b.overall.compareTo(a.overall))).first;
    slides.add(Slide(
      key: 'mini', theme: SlideTheme.navy, eyebrow: 'Твій місяць · перші кроки',
      title: '${es.length} ${plural(es.length, 'запис', 'записи', 'записів')} —', accent: 'гарний старт',
      rows: [SlideRow('Побачень', '${es.length}'), SlideRow('Людей', '${ppl.length}'), SlideRow('Найкращий вечір', '${bestMini.overall}/5')],
      caption: 'Ще ${3 - es.length} — і буде повний Wrapped з рекордами і нагородами.',
    ));
    return Wrapped(month, label, slides, true, es.length);
  }

  // 2. Найкращий вечір (нічия — останній)
  final best = (es.toList()..sort((a, b) => b.overall != a.overall ? b.overall.compareTo(a.overall) : b.date.compareTo(a.date))).first;
  final bd = parseIso(best.date);
  slides.add(Slide(
    key: 'best', theme: SlideTheme.yellow, eyebrow: 'Найкращий вечір', title: '${cap(weekdays[bd.weekday])},',
    accent: '${bd.day} ${monthsGen[m - 1]}', big: '${best.overall}/5', bigLabel: nm(best.personId),
    caption: best.tags.isEmpty ? 'Без деталей, але точно вогонь.' : best.tags.take(3).map(tagLabel).join(' · '),
  ));

  // 3. Секс місяця (тільки коли був, мінімум 2)
  final sx = es.where((e) => e.hadSex).toList();
  if (sx.length >= 2) {
    final s = avg(sx.map((e) => e.ratings['sx_overall'] ?? e.overall));
    final om = sx.where((e) => e.tags.contains('o_me') || e.tags.contains('o_multi')).length;
    final oh = sx.where((e) => e.tags.contains('o_him')).length;
    final rows = [SlideRow('Секс', '${fmt(s)}/5 — ${rateWord(s)}')];
    if (sx.any((e) => e.tags.any((t) => t.startsWith('o_')))) {
      rows.add(SlideRow('Ти кінчала', '$om з ${sx.length}'));
      rows.add(SlideRow('Він', '$oh з ${sx.length}'));
    }
    slides.add(Slide(
      key: 'sex', theme: SlideTheme.navy, eyebrow: 'Секс місяця', title: _times(sx.length), accent: rateWord(s), rows: rows,
      caption: oh > om ? 'Рахунок $oh:$om не на твою користь.' : (om > 0 ? 'Рахунок на твою користь. Так і треба.' : null),
    ));
  } else if (sx.isEmpty) {
    slides.add(Slide(key: 'nosex', theme: SlideTheme.yellow, eyebrow: 'Обкладинка місяця', title: 'Тільки', accent: 'побачення', big: '${es.length}', bigLabel: 'побачень · 0 сексу', caption: 'Оцінюємо вечори і хлопців.'));
  }

  // 4. Хто був поруч (нічия — обидва)
  if (ppl.length > 1) {
    final cnt = ppl.map((id) {
      final pe = es.where((e) => e.personId == id).toList();
      return (id: id, n: pe.length, a: avg(pe.map((e) => e.overall)));
    }).toList()
      ..sort((a, b) => b.n.compareTo(a.n));
    final top = cnt.where((c) => c.n == cnt.first.n).toList();
    slides.add(Slide(
      key: 'people', theme: SlideTheme.pink, eyebrow: 'Хто був поруч', title: top.map((c) => nm(c.id)).join(' і '),
      accent: top.length > 1 ? 'нічия' : 'частіше за всіх',
      rows: cnt.take(4).map((c) => SlideRow(nm(c.id), '${c.n} · ${c.n >= 2 ? fmt(c.a) : 'рано судити'}')).toList(),
    ));
  }

  // 5. Зала ганьби: найбільше червоних (без критичних)
  final reds = ppl.map((id) {
    final f = es.where((e) => e.personId == id).expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.r)).toList();
    return (id: id, f: f);
  }).where((x) => x.f.isNotEmpty).toList()
    ..sort((a, b) => b.f.length.compareTo(a.f.length));
  if (reds.isNotEmpty) {
    final r = reds.first;
    final top = _mode(r.f);
    slides.add(Slide(
      key: 'shame', theme: SlideTheme.pink, eyebrow: 'Зала ганьби', title: nm(r.id),
      accent: '${r.f.length} ${plural(r.f.length, 'прапорець', 'прапорці', 'прапорців')}',
      big: '×${r.f.where((x) => x == top).length}', bigLabel: flagById(top)?.label ?? '', caption: 'Ти це бачиш, і ми теж.',
    ));
  }

  // 6. Зелений прапорець місяця
  final greens = es.expand((e) => e.flags.where((x) => flagById(x)?.kind == FlagKind.g)).toList();
  if (greens.length >= 2) {
    final g = _mode(greens);
    slides.add(Slide(key: 'green', theme: SlideTheme.yellow, eyebrow: 'Зелений прапорець', title: flagById(g)?.label ?? '', big: '×${greens.where((x) => x == g).length}', bigLabel: 'за місяць', caption: 'Це вже характер, а не випадок.'));
  }

  // 7. Формула вечора (за всіма записами, від «Закономірність»)
  final form = formula(effects(all));
  if (form.length >= 2) {
    slides.add(Slide(key: 'formula', theme: SlideTheme.navy, eyebrow: 'Твоя формула', title: 'Ідеальний', accent: 'вечір', rows: form.map((x) => SlideRow(x.label, '+${fmt(x.delta)}')).toList(), caption: 'Збережи скріншот.'));
  }

  // 8. Типаж
  final t = _typaj(es, people);
  if (t != null) slides.add(t);

  // 9. Варто помітити — спокійно, без жартів, тільки для неї
  int tagN(String id) => es.where((e) => e.tags.contains(id)).length;
  final sore = <SlideRow>[];
  if (tagN('pain') > 0) sore.add(SlideRow('Був дискомфорт', _times(tagN('pain'))));
  final push = es.where((e) => e.flags.contains('flag_r_push')).length;
  if (push > 0) sore.add(SlideRow('Він тиснув і квапив', _times(push)));
  if (tagN('silent') > 0) sore.add(SlideRow('Промовчала, чого хочеш', '${tagN('silent')} з ${es.length}'));
  if (tagN('limit_missed') > 0) sore.add(SlideRow('Хотіла, але не сказала', '${tagN('limit_missed')}'));
  if (tagN('noprot') > 0) sore.add(SlideRow('Без захисту', '${tagN('noprot')}'));
  if (sore.isNotEmpty) {
    slides.add(Slide(key: 'notice', theme: SlideTheme.navy, eyebrow: 'Тільки для тебе', title: 'Варто', accent: 'помітити', rows: sore.take(3).toList(), private: true, caption: 'Тіло не бреше. Ти маєш право сказати «стоп» у будь-який момент.'));
  }

  // 10. Фінал
  slides.add(Slide(key: 'end', theme: SlideTheme.pink, eyebrow: label, title: 'До зустрічі', accent: 'у ${monthsLoc[m % 12]}', caption: 'Записуй далі — наступний буде ще чесніший.'));
  return Wrapped(month, label, slides, false, es.length);
}

Slide? _typaj(List<Entry> es, List<Person> people) {
  final ppl = es.map((e) => e.personId).toSet();
  int flagN(String id) => es.where((e) => e.flags.contains(id)).length;
  final exPeople = es.where((e) => e.flags.contains('flag_r_ex')).map((e) => e.personId).toSet().length;
  Slide mk(String t, String a, String big, String bl, String cap) =>
      Slide(key: 'type', theme: SlideTheme.navy, eyebrow: 'Твій типаж місяця', title: t, accent: a, big: big, bigLabel: bl, caption: cap);
  if (exPeople >= 2 || flagN('flag_r_ex') >= 3) return mk('Детекторка', 'чужих ексів', '$exPeople/${ppl.length}', 'згадали колишню', 'Ти не на побаченні, ти на груповій терапії.');
  final fake = es.where((e) => e.tags.contains('o_fake')).length;
  final sx = es.where((e) => e.hadSex).length;
  if (fake >= 2) return mk('Заслужена', 'артистка', '$fake/$sx', 'вдавала', 'Станіславський аплодує стоячи. Він нічого не помітив.');
  final once = ppl.where((id) => es.where((e) => e.personId == id).length == 1).length;
  if (ppl.length >= 3 && once == ppl.length) return mk('Серійна', 'стрільчиня', '${es.length}·${ppl.length}·0', 'побачень · людей · продовжень', 'Кастинг триває.');
  if (flagN('flag_r_cheap') >= 2) return mk('Фінансова', 'аудиторка', '${flagN('flag_r_cheap')}', 'рахував копійки', 'Він рахував копійки. Ти рахувала його прапорці. Нічия.');
  final month = monthKey(es.first.date);
  final fired = people.where((p) => p.isPast && p.pastReason == 'gone' && p.pastAt != null && monthKey(p.pastAt!) == month).length;
  if (fired >= 2) return mk('Відділ', 'кадрів', '$fired', 'звільнились без відпрацювання', 'Ghosting — теж відповідь.');
  final initMe = es.where((e) => e.facts['f_init'] == 0).length;
  if (initMe == es.length) return mk('Ген', 'директорка', '$initMe/${es.length}', 'почала ти', 'Він працює на півставки.');
  return null;
}
