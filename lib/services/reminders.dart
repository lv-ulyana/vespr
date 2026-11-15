// Нагадування за годину до зустрічі — локальні сповіщення телефону, без інтернету.
// Текст без імені й місця: «Через годину зустріч, о 20:00». Після зустрічі нічого не шлемо.
// У браузері сповіщення за розкладом неможливі, тож там це просто нічого не робить.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';

class Reminders {
  static final _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String _last = '';

  static Future<bool> _init() async {
    if (kIsWeb) return false;
    if (_ready) return true;
    try {
      tzdata.initializeTimeZones();
      await _p.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Попросити дозвіл на сповіщення (коли вона вперше вмикає нагадування)
  static Future<void> ask() async {
    if (!await _init()) return;
    try {
      await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      await _p.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true);
    } catch (_) {}
  }

  /// Коли нагадати: за годину до початку
  static DateTime? at(Meeting m) {
    final d = DateTime.tryParse(m.date);
    final p = m.time.split(':');
    final h = int.tryParse(p[0]), mi = p.length > 1 ? int.tryParse(p[1]) : 0;
    if (d == null || h == null || mi == null) return null;
    return DateTime(d.year, d.month, d.day, h, mi).subtract(const Duration(hours: 1));
  }

  /// Переставити всі нагадування під поточний список зустрічей
  static Future<void> sync(List<Meeting> meetings) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final due = <(DateTime, Meeting)>[
      for (final m in meetings)
        if (m.remind && at(m) != null && at(m)!.isAfter(now)) (at(m)!, m),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    // iOS тримає до 64 запланованих сповіщень — беремо найближчі
    final take = due.take(48).toList();
    final key = take.map((x) => '${x.$1.toIso8601String()}|${x.$2.time}').join(',');
    if (key == _last) return;
    if (!await _init()) return;
    try {
      await _p.cancelAll();
      const details = NotificationDetails(
        android: AndroidNotificationDetails('meetings', 'Зустрічі', channelDescription: 'Нагадування за годину до зустрічі', importance: Importance.defaultImportance, priority: Priority.defaultPriority),
        iOS: DarwinNotificationDetails(),
      );
      for (final (i, x) in take.indexed) {
        await _p.zonedSchedule(
          i,
          'Vespr',
          'Через годину зустріч, о ${x.$2.time}.',
          tz.TZDateTime.from(x.$1.toUtc(), tz.UTC),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      _last = key;
    } catch (_) {}
  }
}
