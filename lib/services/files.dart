import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../logic/export.dart';
import 'download_stub.dart' if (dart.library.js_interop) 'download_web.dart';

/// Записує текстовий файл у тимчасову папку і відкриває системне «Поділитися»:
/// Google Диск, Таблиці, Календар, Telegram, Файли — куди вона сама обере.
Future<void> shareTextFile(String name, String content, String mime, {String? subject, Rect? origin}) async {
  if (kIsWeb) {
    // Браузер: на айфоні й Android відкриється «Поділитися», на компʼютері — просто завантаження
    final bytes = utf8.encode(content);
    try {
      final r = await Share.shareXFiles([XFile.fromData(bytes, mimeType: mime, name: name)], subject: subject);
      if (r.status != ShareResultStatus.unavailable) return;
    } catch (_) {}
    downloadBytes(bytes, name, mime);
    return;
  }
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$name');
  await f.writeAsString(content, flush: true);
  // На iPad вікно «Поділитися» потребує точки прив'язки
  await Share.shareXFiles([XFile(f.path, mimeType: mime, name: name)], subject: subject, sharePositionOrigin: origin ?? const Rect.fromLTWH(0, 0, 1, 1));
}

/// Картинка чи інший бінарний файл у системне «Поділитися» (у браузері — завантаження, якщо не вийшло)
Future<void> shareBytesFile(String name, List<int> bytes, String mime) async {
  if (kIsWeb) {
    try {
      final r = await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), mimeType: mime, name: name)]);
      if (r.status != ShareResultStatus.unavailable) return;
    } catch (_) {}
    downloadBytes(bytes, name, mime);
    return;
  }
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(f.path, mimeType: mime, name: name)], sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1));
}

/// Одна зустріч одразу у вікно створення події календаря телефону.
/// У веб-версії вікна календаря нема — віддаємо файл .ics з цією однією зустріччю.
Future<bool> addMeetingToPhoneCalendar(Meeting m, String name, CalendarOptions o) async {
  if (kIsWeb) {
    final one = DB(profile: Profile(), people: [Person(id: m.personId, name: name, createdAt: '')], entries: [], meetings: [m]);
    await shareTextFile('vespr-${m.date}.ics', buildIcs(one, o), 'text/calendar', subject: 'Vespr: зустріч');
    return true;
  }
  final start = meetingStart(m);
  final event = Event(
    title: meetingTitle(m, name, o.quiet),
    description: '',
    location: o.place && m.place != null ? placeLabel(m.place) : '',
    startDate: start,
    endDate: start.add(const Duration(hours: meetingHours)),
    iosParams: IOSParams(reminder: o.remind ? const Duration(hours: 1) : null),
    androidParams: AndroidParams(),
  );
  return Add2Calendar.addEvent2Cal(event);
}

// ---------- Резервна копія: AES-256-GCM, ключ з пароля через PBKDF2 ----------
const _iterations = 20000;

Future<SecretKey> _key(String password, List<int> salt, int iterations) =>
    Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256).deriveKeyFromPassword(password: password, nonce: salt);

Future<String> exportBackup(DB db, String password) async {
  final salt = SecretKeyData.random(length: 16).bytes;
  final key = await _key(password, salt, _iterations);
  final box = await AesGcm.with256bits().encrypt(utf8.encode(jsonEncode(db.toJson())), secretKey: key);
  final payload = jsonEncode({
    'app': 'vespr', 'v': 2, 'kdf': 'pbkdf2-sha256', 'iter': _iterations,
    'salt': base64.encode(salt), 'nonce': base64.encode(box.nonce), 'mac': base64.encode(box.mac.bytes), 'data': base64.encode(box.cipherText),
  });
  final name = 'vespr-${fileStamp()}.vespr';
  await shareTextFile(name, payload, 'application/octet-stream', subject: 'Копія Vespr');
  return name;
}

/// Обраний файл: назва + байти. Без фільтра за типом, бо на частині телефонів фільтр за .csv/.ics ховає потрібні файли.
Future<({String name, List<int> bytes})?> pickFileBytes() async {
  final f = await openFile();
  if (f == null) return null;
  return (name: f.name, bytes: await f.readAsBytes());
}

Future<String?> pickBackupText() async {
  final f = await pickFileBytes();
  return f == null ? null : utf8.decode(f.bytes, allowMalformed: true);
}

class BackupError implements Exception {
  final String message;
  const BackupError(this.message);
  @override
  String toString() => message;
}

Future<DB> decryptBackup(String text, String password) async {
  Map<String, dynamic> p;
  try {
    p = jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    throw const BackupError('Це не файл копії Vespr');
  }
  if (p['app'] != 'vespr' || p['v'] != 2) throw const BackupError('Це не файл копії Vespr або він з іншої версії');
  final key = await _key(password, base64.decode(p['salt'] as String), (p['iter'] as num).toInt());
  final box = SecretBox(base64.decode(p['data'] as String), nonce: base64.decode(p['nonce'] as String), mac: Mac(base64.decode(p['mac'] as String)));
  List<int> clear;
  try {
    clear = await AesGcm.with256bits().decrypt(box, secretKey: key);
  } on SecretBoxAuthenticationError {
    throw const BackupError('Неправильний пароль');
  }
  final db = DB.fromJson(jsonDecode(utf8.decode(clear)) as Map<String, dynamic>);
  return db;
}
