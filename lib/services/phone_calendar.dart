// Читання календаря телефону (Google Календар на Android, Календар на iPhone).
// Тільки читаємо події за обраний період; нічого в календарі не змінюємо.
import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:timezone/data/latest.dart' as tzdata;

import '../logic/import_ics.dart';

class CalendarAccessError implements Exception {
  final String message;
  const CalendarAccessError(this.message);
  @override
  String toString() => message;
}

bool _tzReady = false;

Future<List<CalEvent>> readPhoneCalendar(DateTime from, DateTime to) async {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  final plugin = dc.DeviceCalendarPlugin();
  var perm = await plugin.hasPermissions();
  if (perm.data != true) perm = await plugin.requestPermissions();
  if (perm.data != true) {
    throw const CalendarAccessError('Немає доступу до календаря. Дозволь його в налаштуваннях телефону: Vespr → Дозволи → Календар.');
  }
  final cals = await plugin.retrieveCalendars();
  final out = <CalEvent>[];
  for (final c in cals.data ?? <dc.Calendar>[]) {
    final id = c.id;
    if (id == null) continue;
    final res = await plugin.retrieveEvents(id, dc.RetrieveEventsParams(startDate: from, endDate: to));
    for (final e in res.data ?? <dc.Event>[]) {
      final start = e.start;
      if (start == null) continue;
      final allDay = e.allDay == true;
      final local = allDay ? DateTime(start.year, start.month, start.day) : DateTime.fromMillisecondsSinceEpoch(start.millisecondsSinceEpoch);
      out.add(CalEvent(
        uid: 'device:${e.eventId ?? '${start.millisecondsSinceEpoch}-${e.title}'}',
        title: (e.title ?? '').trim(),
        start: local,
        allDay: allDay,
        location: e.location,
      ));
    }
  }
  // той самий захід може бути в двох календарях (спільний і свій) — лишаємо один
  final seen = <String>{};
  return out.where((e) => seen.add('${e.title}|${e.start.toIso8601String()}')).toList();
}
