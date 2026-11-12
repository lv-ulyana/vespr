// Демо-режим для показу і скріншотів: ?demo=1 у веб-версії.
// Вигадані люди і записи на останні два місяці; справжні дані не чіпаємо, якщо вони вже є.
import 'models.dart';
import 'store.dart';

DB demoDb([DateTime? now]) {
  final n = now ?? DateTime.now();
  String d(int daysAgo) => isoDate(n.subtract(Duration(days: daysAgo)));
  final people = [
    Person(id: 'p_arch', name: 'Архітектор', rel: 'rel', birth: '1995-10-03', met: 0, want: 2, notes: 'Креслить на серветках', createdAt: d(62)),
    Person(id: 'p_mark', name: 'Марк', rel: 'fling', signOnly: 7, met: 3, createdAt: d(61)),
    Person(id: 'p_d', name: 'Д.', rel: 'date', status: 'past', pastReason: 'gone', pastAt: d(20), createdAt: d(60)),
  ];
  var i = 0;
  Entry e(String p, int ago, int overall, bool sex, List<String> tags, List<String> flags, [String note = '']) => Entry(
        id: 'demo${i++}', personId: p, date: d(ago), overall: overall, hadSex: sex,
        ratings: sex ? {'sx_overall': overall} : {}, tags: tags, flags: flags, note: note, createdAt: d(ago),
      );
  final entries = [
    e('p_arch', 55, 5, true, ['neutral', 'his', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him', 'condom'], ['flag_g_walk', 'flag_g_listen'], 'Довго гуляли, потім у нього'),
    e('p_arch', 47, 4, true, ['restaurant', 'mine', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_asks']),
    e('p_mark', 40, 2, true, ['bar', 'his', 'notalk', 'nofore', 'rush', 'alco1', 'o_him'], ['flag_r_phone', 'flag_r_ex'], 'Весь вечір у телефоні'),
    e('p_arch', 33, 5, true, ['restaurant', 'his', 'talk', 'fore', 'slow', 'sober', 'o_multi', 'o_him'], ['flag_g_walk', 'flag_g_paid']),
    e('p_mark', 28, 2, true, ['bar', 'mine', 'notalk', 'nofore', 'rush', 'alco2', 'o_him'], ['flag_r_phone', 'flag_r_push']),
    e('p_d', 24, 3, false, ['bar', 'talk', 'alco1'], ['flag_r_late', 'flag_r_ex'], 'Запізнився на 40 хвилин'),
    e('p_mark', 16, 3, true, ['straight_home', 'his', 'notalk', 'nofore', 'rush', 'alco1', 'o_him'], ['flag_r_phone']),
    e('p_arch', 9, 4, true, ['neutral', 'mine', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him_no'], ['flag_g_walk']),
    e('p_arch', 4, 5, true, ['restaurant', 'his', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_texts', 'flag_g_remember'], 'Найкращий вечір місяця'),
  ];
  final meetings = [
    Meeting(id: 'demo_m1', personId: 'p_arch', date: isoDate(n.add(const Duration(days: 2))), time: '19:30', place: 'restaurant'),
    Meeting(id: 'demo_m2', personId: 'p_mark', date: d(2), time: '21:00', place: 'bar'),
  ];
  final profile = defaultProfile()
    ..name = 'Ляна'
    ..birth = '2005-09-09'
    ..onboarded = true
    ..pinEnabled = false
    ..premium = true;
  return DB(profile: profile, people: people, entries: entries, meetings: meetings..sort((a, b) => a.date.compareTo(b.date)));
}

