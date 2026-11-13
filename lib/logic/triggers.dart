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

/// Де саме в тексті знайшли прапорець — для підкреслень у розшифровці голосу.
class FlagHit {
  final int start, end;
  final String flagId;
  const FlagHit(this.start, this.end, this.flagId);
}

/// Те саме, що [suggestFlags], але з позиціями у вихідному тексті (разом із «не» перед тригером).
List<FlagHit> flagHits(String text) {
  final t = _norm(text);
  if (t.trim().isEmpty || t.length != text.length) return [];
  final ws = RegExp(r"[a-zа-щьюяґєії'0-9]+").allMatches(t).toList();
  final words = [for (final m in ws) m.group(0)!];
  final hits = <FlagHit>[];
  for (final f in flags) {
    for (final trig in f.triggers) {
      final tw = _norm(trig).split(RegExp(r'\s+'));
      for (var i = 0; i + tw.length <= words.length; i++) {
        var ok = true;
        for (var k = 0; k < tw.length; k++) {
          final w = words[i + k];
          if (k == tw.length - 1 ? !w.startsWith(tw[k]) : w != tw[k]) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        final from = i - 2 < 0 ? 0 : i - 2;
        final negAt = tw.first == 'не' ? -1 : [for (var j = from; j < i; j++) j].lastWhere((j) => _neg.contains(words[j]), orElse: () => -1);
        final end = ws[i + tw.length - 1].end;
        if (negAt >= 0) {
          if (f.negOpposite != null) hits.add(FlagHit(ws[negAt].start, end, f.negOpposite!));
        } else {
          hits.add(FlagHit(ws[i].start, end, f.id));
        }
      }
    }
  }
  // перекриття: лишаємо довші й раніші
  hits.sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : b.end.compareTo(a.end));
  final out = <FlagHit>[];
  for (final h in hits) {
    if (out.isEmpty || h.start >= out.last.end) out.add(h);
  }
  return out;
}
