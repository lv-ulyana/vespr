// Пропозиції прапорців з тексту нотатки (або розшифровки голосу).
// Тригери — основи слів, шукаємо на початку слова. Якщо за 1–2 слова перед тригером
// стоїть «не», «ні» чи «без» — тег не ставимо, а для прапорців з negOpposite пропонуємо протилежний.
// Сама відмітка ніколи не ставиться автоматично, лише пропонується чипом.
import '../data/catalog.dart';

const _neg = {'не', 'ні', 'без', 'not', 'no', 'never', 'without', "didn't", "don't", "doesn't", "wasn't", "isn't", "won't", 'didnt', 'dont'};

/// Англійські тригери для тих самих прапорців (основи слів, шукаємо на початку слова).
const _enTriggers = <String, List<String>>{
  'flag_g_asks': ['asked if', 'asked me if', 'comfortable', 'is it ok', 'checked in'],
  'flag_g_no': ['accepted', 'respected', 'took no', 'understood'],
  'flag_g_walk': ['walked me', 'taxi', 'uber', 'cab', 'drove me', 'took me home'],
  'flag_g_listen': ['listen', 'asked about me', 'curious', 'interested in'],
  'flag_g_remember': ['remember'],
  'flag_g_ontime': ['on time', 'early', 'punctual'],
  'flag_g_paid': ['paid', 'picked up the', 'got the check', 'treated me'],
  'flag_g_gift': ['flower', 'bouquet', 'gift', 'surprise'],
  'flag_g_condom': ['had one with', 'brought condom'],
  'flag_g_texts': ['texted', 'messaged', 'got home safe', 'home safe'],
  'flag_g_word': ['as we agreed', 'as promised', 'kept his word', 'kept her word', 'kept his promise'],
  'flag_g_kind': ['polite', 'kind to', 'the waiter', 'the waitress', 'nice to'],
  'flag_r_phone': ['phone', 'scroll', 'texting', 'instagram', 'screen'],
  'flag_r_self': ['about himself', 'about herself', 'himself', 'narciss', 'interrupt', 'talked over'],
  'flag_r_late': ['was late', 'showed up late', 'came late', 'running late', 'ran late', 'minutes late', 'kept me waiting'],
  'flag_r_ex': ['his ex', 'her ex', 'ex girlfriend', 'ex boyfriend', 'ex wife'],
  'flag_r_cheap': ['split the', 'every penny', 'venmo', 'cheap', 'pay me back'],
  'flag_r_jab': ['jab', 'weird joke', 'comment about my', 'mean joke', 'negged'],
  'flag_r_drunk': ['drunk', 'wasted', 'hammered'],
  'flag_r_jealous': ['jealous', 'where were you', 'controll', 'checked my phone'],
  'flag_r_gone': ['ghost', 'disappear', 'ignor', 'left me on read', "didn't text", "didn't reply", "hasn't texted"],
  'flag_r_lie': ['lie', 'lied', 'lying', "didn't add up"],
  'flag_r_push': ['push', 'pressur', 'rushed', 'insist', 'talked me into'],
  'flag_c_stop': ["didn't stop", 'kept going when', 'ignored my stop'],
  'flag_c_condom': ['took off the condom', 'removed the condom', 'refused a condom', 'refused condom', 'stealth'],
  'flag_c_photo': ['without asking', 'without permission', 'filmed me', 'took photos of me'],
};

Iterable<String> _trigs(Flag f) => [...f.triggers, ...?_enTriggers[f.id]];
String _norm(String s) => s.toLowerCase().replaceAll(RegExp('[’ʼ`]'), "'");

List<String> suggestFlags(String text) {
  final t = _norm(text);
  if (t.trim().isEmpty) return [];
  final words = t.split(RegExp(r"[^a-zа-щьюяґєії'0-9]+")).where((w) => w.isNotEmpty).toList();
  final found = <String>{};
  for (final f in flags) {
    for (final trig in _trigs(f)) {
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
        final negated = !_neg.contains(tw.first) && before.any(_neg.contains);
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
    for (final trig in _trigs(f)) {
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
        final negAt = _neg.contains(tw.first) ? -1 : [for (var j = from; j < i; j++) j].lastWhere((j) => _neg.contains(words[j]), orElse: () => -1);
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
