// Моделі даних Vespr. Усе зберігається одним JSON на телефоні.

List<String> _strList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];
Map<String, int> _intMap(dynamic v) {
  if (v is! Map) return {};
  final out = <String, int>{};
  v.forEach((k, val) {
    if (val is num) out[k.toString()] = val.toInt();
  });
  return out;
}

int? _int(dynamic v) => v is num ? v.toInt() : null;
String? _str(dynamic v) => v?.toString();

class Profile {
  String name;
  String? birth; // YYYY-MM-DD
  String dating; // men | women | all
  bool pinEnabled;
  bool onboarded;
  bool premium; // тестовий перемикач, поки нема оплати
  String lang; // uk | en (англійська ще не перекладена)
  String appIcon; // dark | light
  List<String> sexQs;
  List<String> ptQs;
  Map<String, int> counters; // лічильники подій для нагород (повернення з минулих, перегляди…)

  Profile({
    this.name = '',
    this.birth,
    this.dating = 'men',
    this.pinEnabled = true,
    this.onboarded = false,
    this.premium = false,
    this.lang = 'uk',
    this.appIcon = 'dark',
    List<String>? sexQs,
    List<String>? ptQs,
    Map<String, int>? counters,
  })  : sexQs = sexQs ?? <String>[],
        ptQs = ptQs ?? <String>[],
        counters = counters ?? <String, int>{};

  Map<String, dynamic> toJson() => {
        'name': name,
        'birth': birth,
        'dating': dating,
        'pinEnabled': pinEnabled,
        'onboarded': onboarded,
        'premium': premium,
        'lang': lang,
        'appIcon': appIcon,
        'sexQs': sexQs,
        'ptQs': ptQs,
        'counters': counters,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: _str(j['name']) ?? '',
        birth: _str(j['birth']),
        dating: _str(j['dating']) ?? 'men',
        pinEnabled: j['pinEnabled'] != false,
        onboarded: j['onboarded'] == true,
        premium: j['premium'] == true,
        lang: _str(j['lang']) ?? 'uk',
        appIcon: _str(j['appIcon']) ?? 'dark',
        sexQs: _strList(j['sexQs']),
        ptQs: _strList(j['ptQs']),
        counters: _intMap(j['counters']),
      );
}

class Person {
  final String id;
  String name;
  String gender; // m | f
  String rel;
  String? birth; // РРРР-ММ-ДД; якщо рік невідомий — 0000-ММ-ДД
  int? signOnly;
  int? size;
  int? met;
  int? want;
  String notes;
  String status; // now | past
  String? pastReason;
  String? pastAt;
  final String createdAt;
  String? photo; // base64 JPEG до 360 px, тільки на телефоні

  Person({
    required this.id,
    required this.name,
    this.gender = 'm',
    this.rel = 'date',
    this.birth,
    this.signOnly,
    this.size,
    this.met,
    this.want,
    this.notes = '',
    this.status = 'now',
    this.pastReason,
    this.pastAt,
    required this.createdAt,
    this.photo,
  });

  bool get isPast => status == 'past';

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'gender': gender, 'rel': rel, 'birth': birth, 'signOnly': signOnly, 'size': size,
        'met': met, 'want': want, 'notes': notes, 'status': status, 'pastReason': pastReason,
        'pastAt': pastAt, 'createdAt': createdAt, if (photo != null) 'photo': photo,
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: _str(j['id']) ?? '',
        name: _str(j['name']) ?? '',
        gender: _str(j['gender']) ?? 'm',
        rel: _str(j['rel']) ?? 'date',
        birth: _str(j['birth']),
        signOnly: _int(j['signOnly']),
        size: _int(j['size']),
        met: _int(j['met']),
        want: _int(j['want']),
        notes: _str(j['notes']) ?? '',
        status: _str(j['status']) ?? 'now',
        pastReason: _str(j['pastReason']),
        pastAt: _str(j['pastAt']),
        createdAt: _str(j['createdAt']) ?? '',
        photo: _str(j['photo']),
      );
}

class Entry {
  final String id;
  String personId;
  String date; // YYYY-MM-DD
  int overall; // 1–5, обов'язкове
  bool hadSex;
  Map<String, int> ratings;
  List<String> tags;
  List<String> flags;
  Map<String, int> facts;
  String note;
  final String createdAt;

  Entry({
    required this.id,
    required this.personId,
    required this.date,
    required this.overall,
    required this.hadSex,
    Map<String, int>? ratings,
    List<String>? tags,
    List<String>? flags,
    Map<String, int>? facts,
    this.note = '',
    required this.createdAt,
  })  : ratings = ratings ?? {},
        tags = tags ?? [],
        flags = flags ?? [],
        facts = facts ?? {};

  Map<String, dynamic> toJson() => {
        'id': id, 'personId': personId, 'date': date, 'overall': overall, 'hadSex': hadSex,
        'ratings': ratings, 'tags': tags, 'flags': flags, 'facts': facts, 'note': note, 'createdAt': createdAt,
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: _str(j['id']) ?? '',
        personId: _str(j['personId']) ?? '',
        date: _str(j['date']) ?? '',
        overall: _int(j['overall']) ?? 3,
        hadSex: j['hadSex'] == true,
        ratings: _intMap(j['ratings']),
        tags: _strList(j['tags']),
        flags: _strList(j['flags']),
        facts: _intMap(j['facts']),
        note: _str(j['note']) ?? '',
        createdAt: _str(j['createdAt']) ?? '',
      );
}

/// Запланована зустріч (екран «Нова зустріч» і календар)
class Meeting {
  final String id;
  String personId;
  String date; // YYYY-MM-DD
  String time; // HH:MM
  String? place; // bar | restaurant | cafe | park | cinema | his | mine | other
  bool remind;
  String? extId; // id події в календарі, звідки імпортовано (щоб не дублювати)
  String? placeText; // своє місце: концерт, дача…

  Meeting({required this.id, required this.personId, required this.date, required this.time, this.place, this.remind = true, this.extId, this.placeText});

  Map<String, dynamic> toJson() => {'id': id, 'personId': personId, 'date': date, 'time': time, 'place': place, 'remind': remind, if (extId != null) 'extId': extId, if (placeText != null) 'placeText': placeText};

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: _str(j['id']) ?? '',
        personId: _str(j['personId']) ?? '',
        date: _str(j['date']) ?? '',
        time: _str(j['time']) ?? '20:00',
        place: _str(j['place']),
        remind: j['remind'] != false,
        extId: _str(j['extId']),
        placeText: _str(j['placeText']),
      );
}

class DB {
  Profile profile;
  List<Person> people;
  List<Entry> entries;
  List<Meeting> meetings;

  DB({required this.profile, required this.people, required this.entries, required this.meetings});

  Map<String, dynamic> toJson() => {
        'v': 1,
        'profile': profile.toJson(),
        'people': people.map((p) => p.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'meetings': meetings.map((m) => m.toJson()).toList(),
      };

  factory DB.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(dynamic v) =>
        v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    return DB(
      profile: j['profile'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['profile'] as Map)) : Profile(),
      people: list(j['people']).map(Person.fromJson).toList(),
      entries: list(j['entries']).map(Entry.fromJson).toList(),
      meetings: list(j['meetings']).map(Meeting.fromJson).toList(),
    );
  }
}
