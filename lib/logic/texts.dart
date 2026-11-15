// Шаблони речень. Голос Vespr — розумна подруга, яка вміє рахувати.
// Кожен шаблон має варіанти; беремо стабільно за ключем, щоб текст не стрибав при кожному перемальовуванні.
import 'dates.dart';

const _t = <String, List<String>>{
  'few': ['Ще {k} {w}, і скажемо щось точне.', 'Ще {k} {w} до перших висновків.'],
};

String say(String key, [Map<String, Object> v = const {}, String seed = '']) {
  final vars = _t[key]!;
  var h = 0;
  for (final c in (key + seed).codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final s = vars[h % vars.length].replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${v[m.group(1)] ?? ''}');
  return cap(s);
}

String d1(double x) => fmt(x.abs());
String fewText(int k) => say('few', {'k': k, 'w': plural(k, 'запис', 'записи', 'записів')});
