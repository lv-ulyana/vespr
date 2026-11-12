const monthsNom = ['січень', 'лютий', 'березень', 'квітень', 'травень', 'червень', 'липень', 'серпень', 'вересень', 'жовтень', 'листопад', 'грудень'];
const monthsGen = ['січня', 'лютого', 'березня', 'квітня', 'травня', 'червня', 'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня'];
const monthsLoc = ['січні', 'лютому', 'березні', 'квітні', 'травні', 'червні', 'липні', 'серпні', 'вересні', 'жовтні', 'листопаді', 'грудні'];
// DateTime.weekday: 1 = понеділок … 7 = неділя
const weekdays = ['', 'понеділок', 'вівторок', 'середа', 'четвер', 'пʼятниця', 'субота', 'неділя'];
const weekdaysShort = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'нд'];

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime parseIso(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2], 12);
}

String iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String monthKey(String isoDate) => isoDate.substring(0, 7);
String addDays(String isoDate, int n) => iso(parseIso(isoDate).add(Duration(days: n)));
int daysBetween(String a, String b) => parseIso(b).difference(parseIso(a)).inDays;

/// «14.09.2001» → «2001-09-14» або null
String? parseUA(String s) {
  final m = RegExp(r'^(\d{1,2})[.\-/ ](\d{1,2})[.\-/ ](\d{4})$').firstMatch(s.trim());
  if (m == null) return null;
  final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), y = int.parse(m.group(3)!);
  final dt = DateTime(y, mo, d);
  if (dt.year != y || dt.month != mo || dt.day != d) return null;
  if (y < 1920 || dt.isAfter(DateTime.now())) return null;
  return iso(dt);
}

String toUA(String? isoDate) => isoDate == null ? '' : isoDate.split('-').reversed.join('.');

/// маска вводу: цифри → ДД.ММ.РРРР
String maskDate(String s) {
  final d = s.replaceAll(RegExp(r'\D'), '');
  final c = d.length > 8 ? d.substring(0, 8) : d;
  final parts = <String>[];
  if (c.isNotEmpty) parts.add(c.substring(0, c.length < 2 ? c.length : 2));
  if (c.length > 2) parts.add(c.substring(2, c.length < 4 ? c.length : 4));
  if (c.length > 4) parts.add(c.substring(4));
  return parts.join('.');
}

/// «пт, 14 листопада»
String human(String isoDate) {
  final d = parseIso(isoDate);
  return '${weekdaysShort[d.weekday]}, ${d.day} ${monthsGen[d.month - 1]}';
}

String plural(int n, String one, String few, String many) {
  final a = n.abs() % 100, b = a % 10;
  if (a > 10 && a < 20) return many;
  if (b == 1) return one;
  if (b >= 2 && b <= 4) return few;
  return many;
}

/// число з комою: 4,6
String fmt(double v, [int digits = 1]) => v.isFinite ? v.toStringAsFixed(digits).replaceAll('.', ',') : '—';
