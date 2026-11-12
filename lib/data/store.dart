import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'models.dart';

final _rnd = Random();
String uid() => DateTime.now().millisecondsSinceEpoch.toRadixString(36) + _rnd.nextInt(1 << 30).toRadixString(36);

String isoDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String today() => isoDate(DateTime.now());

Profile defaultProfile() => Profile(
      sexQs: sexQuestions.where((q) => q.def || q.always).map((q) => q.id).where((id) => id != 'sx_overall').toList(),
      ptQs: partnerQuestions.where((q) => q.def).map((q) => q.id).toList(),
    );

/// Сховище: один JSON у SharedPreferences. Даних небагато (сотні записів), тож цього достатньо.
/// Android автоматично копіює ці дані в Google (Auto Backup), iOS — в iCloud-копію телефону.
class AppStore extends ChangeNotifier {
  static const _key = 'vespr-db-v1';
  late SharedPreferences _prefs;
  DB db = DB(profile: defaultProfile(), people: [], entries: [], meetings: []);

  Profile get profile => db.profile;
  List<Person> get people => db.people;
  List<Entry> get entries => db.entries;
  List<Meeting> get meetings => db.meetings;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        db = DB.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // пошкоджені дані не стираємо мовчки: лишаємо копію поруч
        await _prefs.setString('$_key-broken', raw);
      }
    }
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(_key, jsonEncode(db.toJson()));
  }

  Person? person(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Entry? entry(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  String personName(String id) => person(id)?.name ?? '—';

  Future<void> updateProfile(void Function(Profile p) change) async {
    change(db.profile);
    await _save();
  }

  Future<String> addPerson(Person p) async {
    db.people.add(p);
    await _save();
    return p.id;
  }

  Future<void> updatePerson(String id, void Function(Person p) change) async {
    final p = person(id);
    if (p == null) return;
    change(p);
    await _save();
  }

  Future<void> deletePerson(String id) async {
    db.people.removeWhere((p) => p.id == id);
    db.entries.removeWhere((e) => e.personId == id);
    db.meetings.removeWhere((m) => m.personId == id);
    await _save();
  }

  Future<void> saveEntry(Entry e) async {
    final i = db.entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      db.entries[i] = e;
    } else {
      db.entries.add(e);
    }
    await _save();
  }

  Future<void> deleteEntry(String id) async {
    db.entries.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> saveMeeting(Meeting m) async {
    final i = db.meetings.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      db.meetings[i] = m;
    } else {
      db.meetings.add(m);
    }
    await _save();
  }

  Future<void> deleteMeeting(String id) async {
    db.meetings.removeWhere((m) => m.id == id);
    await _save();
  }

  /// Імпорт одним збереженням: нові люди, записи, зустрічі
  Future<void> importBatch({List<Person> people = const [], List<Entry> entries = const [], List<Meeting> meetings = const []}) async {
    db.people.addAll(people);
    db.entries.addAll(entries);
    db.meetings.addAll(meetings);
    await _save();
  }

  Future<void> replaceAll(DB next) async {
    db = next;
    await _save();
  }

  Future<void> wipe() async {
    db = DB(profile: defaultProfile(), people: [], entries: [], meetings: []);
    await _save();
  }
}

/// Доступ до сховища з будь-якого віджета: `Store.of(context)` (з підпискою на зміни).
class Store extends InheritedNotifier<AppStore> {
  const Store({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Store>()!.notifier!;
  static AppStore read(BuildContext context) => context.getInheritedWidgetOfExactType<Store>()!.notifier!;
}
