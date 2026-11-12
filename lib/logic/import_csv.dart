// Імпорт записів з таблиці (CSV з Excel, Google Таблиць, Numbers або з нашого ж експорту).
// Обов'язкові стовпці: дата, людина, оцінка 1–5. Усе інше — якщо знайдеться.
// Дизайн: дошка «14.2 Імпорт · таблиця».
import 'dart:convert';

import '../data/catalog.dart';
import '../data/models.dart';
import 'dates.dart';

// ---------- Читання файлу ----------

/// Байти файлу → текст. Excel в українській Windows зберігає CSV у Windows-1251, тож якщо це не UTF-8 — пробуємо її.
String decodeTextFile(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return decodeCp1251(bytes);
  }
}

const _cp1251hi = {
  0x80: 'Ђ', 0x81: 'Ѓ', 0x82: '‚', 0x83: 'ѓ', 0x84: '„', 0x85: '…', 0x86: '†', 0x87: '‡', 0x88: '€', 0x89: '‰', 0x8A: 'Љ', 0x8B: '‹',
  0x8C: 'Њ', 0x8D: 'Ќ', 0x8E: 'Ћ', 0x8F: 'Џ', 0x90: 'ђ', 0x91: '‘', 0x92: '’', 0x93: '“', 0x94: '”', 0x95: '•', 0x96: '–', 0x97: '—',
  0x99: '™', 0x9A: 'љ', 0x9B: '›', 0x9C: 'њ', 0x9D: 'ќ', 0x9E: 'ћ', 0x9F: 'џ', 0xA0: ' ', 0xA1: 'Ў', 0xA2: 'ў', 0xA3: 'Ј',
  0xA4: '¤', 0xA5: 'Ґ', 0xA6: '¦', 0xA7: '§', 0xA8: 'Ё', 0xA9: '©', 0xAA: 'Є', 0xAB: '«', 0xAC: '¬', 0xAD: '­', 0xAE: '®',
  0xAF: 'Ї', 0xB0: '°', 0xB1: '±', 0xB2: 'І', 0xB3: 'і', 0xB4: 'ґ', 0xB5: 'µ', 0xB6: '¶', 0xB7: '·', 0xB8: 'ё', 0xB9: '№', 0xBA: 'є',
  0xBB: '»', 0xBC: 'ј', 0xBD: 'Ѕ', 0xBE: 'ѕ', 0xBF: 'ї',
};

String decodeCp1251(List<int> bytes) {
  final b = StringBuffer();
  for (final c in bytes) {
    if (c < 0x80) {
      b.writeCharCode(c);
    } else if (c >= 0xC0) {
      b.writeCharCode(0x410 + c - 0xC0); // А…я
    } else {
      b.write(_cp1251hi[c] ?? '�');
    }
  }
  return b.toString();
}

// ---------- Розбір CSV ----------

class CsvTable {
  final List<String> header;
  final List<List<String>> rows;
  final String sep;
  const CsvTable(this.header, this.rows, this.sep);
}

String sepLabel(String sep) => sep == '\t' ? 'Tab' : '«$sep»';

/// Роздільник вгадуємо за першим рядком: «;» (наш експорт, Excel UA), «,» (Google Таблиці) або Tab.
String detectSep(String text) {
  final first = text.split(RegExp(r'\r?\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  var inQ = false;
  final count = {';': 0, ',': 0, '\t': 0};
  for (final ch in first.split('')) {
    if (ch == '"') inQ = !inQ;
    if (!inQ && count.containsKey(ch)) count[ch] = count[ch]! + 1;
  }
  var best = ';';
  for (final k in const ['\t', ';', ',']) {
    if (count[k]! > count[best]!) best = k;
  }
  return best;
}

/// CSV за RFC 4180: лапки, "" всередині лапок, переноси рядків у лапках.
CsvTable parseCsv(String text) {
  var t = text;
  if (t.startsWith('﻿')) t = t.substring(1);
  final sep = detectSep(t);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQ = false;
  for (var i = 0; i < t.length; i++) {
    final ch = t[i];
    if (inQ) {
      if (ch == '"') {
        if (i + 1 < t.length && t[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQ = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      inQ = true;
    } else if (ch == sep) {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < t.length && t[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  final nonEmpty = rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
  if (nonEmpty.isEmpty) return CsvTable(const [], const [], sep);
  return CsvTable(nonEmpty.first.map((h) => h.trim()).toList(), nonEmpty.skip(1).toList(), sep);
}

// ---------- Зіставлення стовпців ----------
// Ключі полів: date, person, overall, sex, rel, note, flags_g, flags_r, flags_c, tags, q:<id питання>, f:<id факту>.
// null — стовпець не беремо.

const requiredFields = ['date', 'person', 'overall'];

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'''[«»"'’?:!.*]'''), '').replaceAll(RegExp(r'\s+'), ' ').trim();

final Map<String, String> _synonyms = () {
  final m = <String, String>{};
  void add(String field, List<String> names) {
    for (final n in names) {
      m[_norm(n)] = field;
    }
  }

  add('date', ['Дата', 'date', 'коли', 'день зустрічі', 'дата зустрічі']);
  add('person', ['Людина', 'хто', 'з ким', "ім'я", 'імя', 'name', 'person', 'партнер', 'він']);
  add('overall', ['Як загалом', 'загалом', 'оцінка', 'бал', 'rating', 'overall', 'score', 'зірки']);
  add('sex', ['Був секс', 'секс', 'sex', 'було']);
  add('rel', ['Хто він', 'тип', 'стосунки']);
  add('note', ['Нотатка', 'нотатки', 'коментар', 'коментарі', 'note', 'notes', 'comment', 'опис']);
  add('flags_g', ['Зелені прапорці', 'зелені', 'green flags']);
  add('flags_r', ['Червоні прапорці', 'червоні', 'red flags']);
  add('flags_c', ['Критичні прапорці', 'критичні']);
  add('tags', ['Що було', 'теги', 'tags']);
  for (final q in allQuestions) {
    if (q.id != 'sx_overall') add('q:${q.id}', [q.text]);
  }
  for (final f in facts) {
    add('f:${f.id}', [f.label]);
  }
  return m;
}();

/// Для кожного стовпця — поле або null. Кожне поле береться один раз (перший збіг).
List<String?> autoMap(List<String> header) {
  final used = <String>{};
  final out = <String?>[];
  for (final h in header) {
    final f = _synonyms[_norm(h)];
    if (f == null || used.contains(f)) {
      out.add(null);
    } else {
      used.add(f);
      out.add(f);
    }
  }
  return out;
}

String fieldLabel(String? key) {
  if (key == null) return 'Не брати';
  switch (key) {
    case 'date':
      return 'Дата';
    case 'person':
      return 'Людина';
    case 'overall':
      return 'Як загалом';
    case 'sex':
      return 'Був секс';
    case 'rel':
      return 'Хто він';
    case 'note':
      return 'Нотатка';
    case 'flags_g':
      return 'Зелені прапорці';
    case 'flags_r':
      return 'Червоні прапорці';
    case 'flags_c':
      return 'Критичні прапорці';
    case 'tags':
      return 'Що було (теги)';
  }
  if (key.startsWith('q:')) return qById(key.substring(2))?.text ?? key;
  if (key.startsWith('f:')) return facts.where((f) => f.id == key.substring(2)).map((f) => f.label).firstOrNull ?? key;
  return key;
}

/// Поля, які можна обрати для стовпця вручну (без питань і фактів — їх впізнаємо лише за назвою)
const pickableFields = ['date', 'person', 'overall', 'sex', 'rel', 'note', 'tags', 'flags_g', 'flags_r'];

List<String> missingRequired(List<String?> mapping) => requiredFields.where((f) => !mapping.contains(f)).toList();

// ---------- Значення ----------

/// «14.10.2025», «14.10.25», «2025-10-14», «14/10/2025» → ISO або null. Майбутні дати не приймаємо.
String? parseAnyDate(String raw, [DateTime? now]) {
  final s = raw.trim().split(RegExp(r'[ T]')).first;
  int? y, mo, d;
  var m = RegExp(r'^(\d{4})[-./](\d{1,2})[-./](\d{1,2})$').firstMatch(s);
  if (m != null) {
    y = int.parse(m.group(1)!);
    mo = int.parse(m.group(2)!);
    d = int.parse(m.group(3)!);
  } else {
    m = RegExp(r'^(\d{1,2})[-./](\d{1,2})[-./](\d{2}|\d{4})$').firstMatch(s);
    if (m == null) return null;
    d = int.parse(m.group(1)!);
    mo = int.parse(m.group(2)!);
    y = int.parse(m.group(3)!);
    if (y < 100) y += 2000;
  }
  final dt = DateTime(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  final n = now ?? DateTime.now();
  if (y < 1990 || dt.isAfter(DateTime(n.year, n.month, n.day))) return null;
  return iso(dt);
}

/// «4», «4,6», «4.4», «вогонь» → 1…5 або null
int? parseRating(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  final w = rateWords.indexOf(s);
  if (w >= 1) return w;
  final v = double.tryParse(s.replaceAll(',', '.').replaceAll(RegExp(r'\s*/\s*5$'), ''));
  if (v == null || v < 1 || v > 5) return null;
  return v.round();
}

/// «так», «yes», «1», «+», «✓», будь-яка оцінка 1–5 → true
bool? parseYesNo(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;
  if (const ['так', 'та', 'yes', 'y', 'true', '+', '✓', '✔', 'x', 'х', 'був', 'було'].contains(s)) return true;
  if (const ['ні', 'no', 'n', 'false', '-', '—', '0', 'не було', 'не був'].contains(s)) return false;
  final v = double.tryParse(s.replaceAll(',', '.'));
  if (v != null) return v > 0;
  return null;
}

/// «Провів, викликав таксі, Заплатив» → id. Назви самі можуть містити кому, тож склеюємо шматки,
/// поки не знайдемо найдовший відомий збіг.
List<String> matchLabels(String raw, Map<String, String> byLabel) {
  final parts = raw.split(RegExp(r'[,;\n]')).map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
  final out = <String>[];
  var i = 0;
  while (i < parts.length) {
    var hit = false;
    for (var j = parts.length; j > i; j--) {
      final id = byLabel[_norm(parts.sublist(i, j).join(', '))];
      if (id != null) {
        out.add(id);
        i = j;
        hit = true;
        break;
      }
    }
    if (!hit) i++;
  }
  return out.toSet().toList();
}

final Map<String, String> _tagByLabel = {for (final e in tagIndex.entries) _norm(e.value.label): e.key};
final Map<String, String> _flagByLabel = {for (final f in flags) _norm(f.label): f.id};

// ---------- План імпорту ----------

class RowIssue {
  final int line; // номер рядка у файлі, як бачить людина (заголовок = 1)
  final String reason;
  const RowIssue(this.line, this.reason);
}

class CsvImportPlan {
  final List<Entry> entries;
  final List<Person> newPeople;
  final int duplicates;
  final List<RowIssue> skipped;
  const CsvImportPlan(this.entries, this.newPeople, this.duplicates, this.skipped);
}

String entryKey(String personId, String date, int overall) => '$personId|$date|$overall';

CsvImportPlan planCsvImport(CsvTable t, List<String?> mapping, DB db, {required String Function() newId, DateTime? now}) {
  final n = now ?? DateTime.now();
  final stamp = n.toIso8601String();
  int? col(String f) {
    final i = mapping.indexOf(f);
    return i < 0 ? null : i;
  }

  String cell(List<String> r, String f) {
    final i = col(f);
    return i == null || i >= r.length ? '' : r[i].trim();
  }

  final byName = <String, String>{for (final p in db.people) p.name.trim().toLowerCase(): p.id};
  final newPeople = <Person>[];
  final seen = <String>{for (final e in db.entries) entryKey(e.personId, e.date, e.overall)};
  final out = <Entry>[];
  final skipped = <RowIssue>[];
  var dups = 0;

  for (var i = 0; i < t.rows.length; i++) {
    final r = t.rows[i];
    final line = i + 2;
    final rawDate = cell(r, 'date');
    final date = parseAnyDate(rawDate, n);
    if (date == null) {
      skipped.add(RowIssue(line, rawDate.isEmpty ? 'нема дати' : '«$rawDate» — не дата'));
      continue;
    }
    final name = cell(r, 'person');
    if (name.isEmpty) {
      skipped.add(RowIssue(line, 'нема імені'));
      continue;
    }
    final rawO = cell(r, 'overall');
    final overall = parseRating(rawO);
    if (overall == null) {
      skipped.add(RowIssue(line, rawO.isEmpty ? 'нема оцінки' : '«$rawO» замість оцінки 1–5'));
      continue;
    }

    var pid = byName[name.toLowerCase()];
    if (pid == null) {
      final relRaw = _norm(cell(r, 'rel'));
      final rel = rels.where((x) => _norm(x.label) == relRaw).map((x) => x.id).firstOrNull ?? 'date';
      final p = Person(id: newId(), name: name, rel: rel, createdAt: stamp);
      newPeople.add(p);
      pid = p.id;
      byName[name.toLowerCase()] = pid;
    }

    final key = entryKey(pid, date, overall);
    if (seen.contains(key)) {
      dups++;
      continue;
    }
    seen.add(key);

    final ratings = <String, int>{};
    for (var c = 0; c < mapping.length; c++) {
      final f = mapping[c];
      if (f == null || !f.startsWith('q:') || c >= r.length) continue;
      final v = parseRating(r[c]);
      if (v != null) ratings[f.substring(2)] = v;
    }
    final factVals = <String, int>{};
    for (var c = 0; c < mapping.length; c++) {
      final f = mapping[c];
      if (f == null || !f.startsWith('f:') || c >= r.length) continue;
      final fact = facts.where((x) => x.id == f.substring(2)).firstOrNull;
      final step = fact?.steps.indexWhere((s) => _norm(s) == _norm(r[c])) ?? -1;
      if (fact != null && step >= 0) factVals[fact.id] = step;
    }
    final fl = <String>[for (final k in const ['flags_g', 'flags_r', 'flags_c']) ...matchLabels(cell(r, k), _flagByLabel)];
    final tags = matchLabels(cell(r, 'tags'), _tagByLabel);
    // секс: явний стовпець, інакше — якщо є відповіді на сексуальні питання
    final sexCell = parseYesNo(cell(r, 'sex'));
    final hadSex = sexCell ?? ratings.keys.any((id) => id.startsWith('sx_'));
    if (hadSex) ratings['sx_overall'] = ratings['sx_overall'] ?? overall;

    out.add(Entry(
      id: newId(),
      personId: pid,
      date: date,
      overall: overall,
      hadSex: hadSex,
      ratings: ratings,
      tags: tags,
      flags: fl.toSet().toList(),
      facts: factVals,
      note: cell(r, 'note'),
      createdAt: stamp,
    ));
  }
  // людей без жодного запису (усі їхні рядки — дублі чи криві) не створюємо
  final used = out.map((e) => e.personId).toSet();
  return CsvImportPlan(out, newPeople.where((p) => used.contains(p.id)).toList(), dups, skipped);
}
