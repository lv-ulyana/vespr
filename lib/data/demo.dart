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
  Entry e(String p, int ago, int overall, bool sex, List<String> tags, List<String> flags, [String note = '', Map<String, int> facts = const {}]) => Entry(
        id: 'demo${i++}', personId: p, date: d(ago), overall: overall, hadSex: sex,
        ratings: {...(sex ? _rates(overall, tags) : {}), ..._him(p)}, tags: tags, flags: flags, note: note, createdAt: d(ago),
        facts: {
          // бюджет вечора: 0 прогулянка, 1 кава/бар, 2 ресторан
          'f_budget': tags.contains('restaurant') ? 2 : (tags.contains('bar') ? 1 : 0),
          ...facts,
        },
      );
  final entries = [
    e('p_arch', 55, 5, true, ['late', 'neutral', 'his', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him', 'condom'], ['flag_g_walk', 'flag_g_listen'], 'Довго гуляли, потім у нього'),
    e('p_arch', 47, 4, true, ['day', 'restaurant', 'mine', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_asks']),
    e('p_mark', 40, 2, true, ['late', 'bar', 'his', 'notalk', 'nofore', 'rush', 'alco1', 'o_him'], ['flag_r_phone', 'flag_r_ex'], 'Весь вечір у телефоні'),
    e('p_arch', 33, 5, true, ['day', 'restaurant', 'his', 'talk', 'fore', 'slow', 'sober', 'o_multi', 'o_him'], ['flag_g_walk', 'flag_g_paid']),
    e('p_mark', 28, 2, true, ['late', 'bar', 'mine', 'notalk', 'nofore', 'rush', 'alco2', 'o_him'], ['flag_r_phone', 'flag_r_push']),
    e('p_d', 24, 3, false, ['day', 'bar', 'talk', 'alco1'], ['flag_r_late', 'flag_r_ex'], 'Запізнився на 40 хвилин'),
    e('p_mark', 16, 3, true, ['late', 'straight_home', 'his', 'notalk', 'nofore', 'rush', 'alco1', 'o_him'], ['flag_r_phone'], '', {'f_stam': 0}),
    e('p_arch', 20, 5, true, ['late', 'restaurant', 'his', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_listen'], '', {'f_stam': 3}),
    e('p_arch', 9, 4, true, ['day', 'neutral', 'mine', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him_no'], ['flag_g_walk']),
    e('p_arch', 4, 5, true, ['late', 'restaurant', 'his', 'talk', 'fore', 'slow', 'sober', 'o_me', 'o_him'], ['flag_g_texts', 'flag_g_remember'], 'Найкращий вечір місяця'),
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


/// Демо-оцінки «Він»: Архітектор уважний, Марк — ні (для «Битви місяця»)
Map<String, int> _him(String p) => p == 'p_arch'
    ? {'pt_hears': 5, 'pt_limits': 5, 'pt_pull': 4, 'pt_free': 4}
    : (p == 'p_mark' ? {'pt_hears': 3, 'pt_limits': 3, 'pt_pull': 5, 'pt_free': 3} : {'pt_hears': 3, 'pt_limits': 4});

/// Демо-відповіді на питання: залежать від тегів, щоб мапа мала що показати
Map<String, int> _rates(int o, List<String> t) {
  int c(int v) => v.clamp(1, 5);
  return {
    'sx_overall': o,
    'sx_pleasure': c(o),
    'sx_care': c(t.contains('talk') ? o : o - 1),
    'sx_fore': c(t.contains('fore') ? o : 2),
    'sx_pace': c(t.contains('rush') ? 2 : o - 1),
    'sx_heard': c(t.contains('notalk') ? o - 1 : o),
    'sx_self': c(o),
  };
}
