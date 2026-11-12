// Пропозиції прапорців з тексту нотатки (або розшифровки голосу).
// Тригери — основи слів, шукаємо на початку слова. Якщо за 1–2 слова перед тригером
// стоїть «не», «ні» чи «без» — тег не ставимо, а для прапорців з negOpposite пропонуємо протилежний.
// Сама відмітка ніколи не ставиться автоматично, лише пропонується чипом.
import '../data/catalog.dart';

const _neg = {'не', 'ні', 'без'};
String _norm(String s) => s.toLowerCase().replaceAll(RegExp('[’ʼ`]'), "'");

List<String> suggestFlags(String text) {
  final t = _norm(text);
  if (t.trim().isEmpty) return [];
  final words = t.split(RegExp(r"[^a-zа-щьюяґєії'0-9]+")).where((w) => w.isNotEmpty).toList();
  final found = <String>{};
  for (final f in flags) {
    for (final trig in f.triggers) {
      final tw = _norm(trig).split(RegExp(r'\s+'));
      for (var i = 0; i + tw.length <= words.length; i++) {
        var ok = true;
        for (var k = 0; k < tw.length; k++) {
          final w = words[i + k];
          final last = k == tw.length - 1;
          if (last ? !w.startsWith(tw[k]) : w != tw[k]) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        final before = words.sublist(i - 2 < 0 ? 0 : i - 2, i);
        final negated = tw.first != 'не' && before.any(_neg.contains);
        if (negated) {
          if (f.negOpposite != null) found.add(f.negOpposite!);
        } else {
          found.add(f.id);
        }
      }
    }
  }
  return found.toList();
}
