// Імпорт зустрічей з календаря: файл .ics або календар телефону (див. services/phone_calendar.dart).
// Обидва джерела дають список CalEvent, далі логіка спільна.
// Дизайн: дошка «14.3 Імпорт · календар».
import '../data/models.dart';
import 'dates.dart';

class CalEvent {
  final String uid; // сталий id події в джерелі — щоб повторний імпорт не дублював
  final String title;
  final DateTime start; // локальний час
  final bool allDay;
  final String? location;
  const CalEvent({required this.uid, required this.title, required this.start, this.allDay = false, this.location});

  String get date => iso(start);
  String get time => allDay ? '20:00' : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
}

String _unescape(String s) =>
    s.replaceAll(r'\n', '\n').replaceAll(r'\N', '\n').replaceAll(r'\,', ',').replaceAll(r'\;', ';').replaceAll(r'\\', r'\');

/// «20251014», «20251014T200000», «20251014T170000Z» → (час, весь день?)
(DateTime, bool)? parseIcsDate(String value) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$').firstMatch(value.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
  if (m.group(4) == null) return (DateTime(y, mo, d), true);
  final h = int.parse(m.group(4)!), mi = int.parse(m.group(5)!), s = int.parse(m.group(6) ?? '0');
  // Z — це UTC, переводимо в місцевий час. TZID=… вважаємо місцевим: майже завжди це її ж пояс.
  final dt = m.group(7) != null ? DateTime.utc(y, mo, d, h, mi, s).toLocal() : DateTime(y, mo, d, h, mi, s);
  return (dt, false);
}

/// Розбір .ics: тільки VEVENT, скасовані пропускаємо, повтори (RRULE) беремо першою датою.
List<CalEvent> parseIcs(String text) {
  // «розгортаємо» перенесені рядки: рядок, що починається з пробілу чи Tab, — продовження попереднього
  final lines = <String>[];
  for (final raw in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
    if ((raw.startsWith(' ') || raw.startsWith('\t')) && lines.isNotEmpty) {
      lines[lines.length - 1] += raw.substring(1);
    } else {
      lines.add(raw);
    }
  }
  final out = <CalEvent>[];
  Map<String, String>? cur;
  var depth = 0; // VALARM всередині VEVENT ігноруємо
  for (final l in lines) {
    final up = l.trim().toUpperCase();
    if (up == 'BEGIN:VEVENT') {
      cur = {};
      depth = 0;
      continue;
    }
    if (cur == null) continue;
    if (up.startsWith('BEGIN:')) {
      depth++;
      continue;
    }
    if (up.startsWith('END:') && up != 'END:VEVENT') {
      depth--;
      continue;
    }
    if (up == 'END:VEVENT') {
      final st = cur['DTSTART'];
      final parsed = st == null ? null : parseIcsDate(st);
      if (parsed != null && (cur['STATUS'] ?? '').toUpperCase() != 'CANCELLED') {
        out.add(CalEvent(
          uid: cur['UID'] ?? '${cur['SUMMARY'] ?? ''}@${st!}',
          title: _unescape(cur['SUMMARY'] ?? '').trim(),
          start: parsed.$1,
          allDay: parsed.$2,
          location: cur['LOCATION'] == null ? null : _unescape(cur['LOCATION']!).trim(),
        ));
      }
      cur = null;
      continue;
    }
    if (depth > 0) continue;
    final colon = l.indexOf(':');
    if (colon <= 0) continue;
    final head = l.substring(0, colon);
    final semi = head.indexOf(';');
    final name = (semi < 0 ? head : head.substring(0, semi)).toUpperCase();
    if (cur.containsKey(name)) continue; // беремо перше значення
    cur[name] = l.substring(colon + 1);
  }
  return out;
}

// ---------- Хто це ----------

String _stem(String name) {
  final n = name.trim().toLowerCase();
  // «Марко» → «марк», «Діма» → «дім»: щоб збігалось і з «Марком», «Дімою»
  if (n.length > 3 && RegExp(r'[аяоейіїєьу]$').hasMatch(n)) return n.substring(0, n.length - 1);
  return n;
}

/// Людина, чиє ім'я є в назві події (з відмінками). Найдовше ім'я виграє: «Олександр» раніше за «Олекс».
Person? guessPerson(String title, List<Person> people) {
  final words = title.toLowerCase().split(RegExp(r"[^a-zа-яіїєґ'’ʼ0-9№]+")).where((w) => w.isNotEmpty).toList();
  Person? best;
  var bestLen = 0;
  for (final p in people) {
    final st = _stem(p.name);
    if (st.length < 2) continue;
    final nameWords = st.split(RegExp(r'\s+'));
    final first = nameWords.first;
    if (words.any((w) => w.startsWith(first)) && st.length > bestLen) {
      best = p;
      bestLen = st.length;
    }
  }
  return best;
}

/// Наші ж події з експорту Vespr — їх не імпортуємо назад
bool isVesprEvent(CalEvent e) => e.uid.endsWith('@vespr.app');

class EventChoice {
  final CalEvent event;
  bool on;
  String? personId; // null — «Хто це?»
  String? newName; // людина, яку додамо з цього імпорту
  final bool past;
  final bool already; // уже імпортована раніше
  EventChoice(this.event, {required this.on, this.personId, this.newName, required this.past, required this.already});
}

/// Список для екрана: відмічаємо ті, де вгадали людину, і ті, що ще не імпортовані
List<EventChoice> buildChoices(List<CalEvent> events, DB db, [DateTime? now]) {
  final t = iso(now ?? DateTime.now());
  final have = db.meetings.map((m) => m.extId).whereType<String>().toSet();
  final list = <EventChoice>[];
  final sorted = events.where((e) => !isVesprEvent(e)).toList()..sort((a, b) => a.start.compareTo(b.start));
  for (final e in sorted) {
    final p = guessPerson(e.title, db.people);
    final already = have.contains(e.uid);
    list.add(EventChoice(e, on: p != null && !already, personId: p?.id, past: e.date.compareTo(t) < 0, already: already));
  }
  return list;
}

/// «Бар», «ресторан», «кіно», «кава» у назві чи місці події → наше місце зі списку
String? placeFromText(String text) {
  final t = text.toLowerCase();
  const hints = {
    'bar': ['бар', 'паб', 'pub', 'bar'],
    'restaurant': ['ресторан', 'вечеря', 'restaurant', 'dinner'],
    'cafe': ['кафе', 'кава', 'кав\'ярн', 'coffee', 'cafe'],
    'cinema': ['кіно', 'фільм', 'cinema', 'movie'],
    'park': ['прогулян', 'парк', 'walk', 'park'],
  };
  for (final e in hints.entries) {
    if (e.value.any(t.contains)) return e.key;
  }
  return null;
}

/// Обрані події → зустрічі
List<Meeting> meetingsFromChoices(List<EventChoice> chosen, {required String Function() newId, required String Function(EventChoice c) personIdOf, DateTime? now}) {
  final t = iso(now ?? DateTime.now());
  return [
    for (final c in chosen)
      Meeting(
        id: newId(),
        personId: personIdOf(c),
        date: c.event.date,
        time: c.event.time,
        place: placeFromText('${c.event.location ?? ''} ${c.event.title}'),
        remind: c.event.date.compareTo(t) >= 0,
        extId: c.event.uid,
      ),
  ];
}
