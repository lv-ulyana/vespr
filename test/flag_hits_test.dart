import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/logic/triggers.dart';

void main() {
  test('flagHits: позиції прапорців у розшифровці', () {
    const t = 'він не тиснув, сам спитав, чи мені комфортно, потім провів до хати. але піввечора сидів у телефоні';
    final h = flagHits(t);
    String part(FlagHit x) => t.substring(x.start, x.end);
    expect(h.map((x) => x.flagId).toSet(), containsAll({'flag_g_no', 'flag_g_asks', 'flag_g_walk', 'flag_r_phone'}));
    expect(part(h.firstWhere((x) => x.flagId == 'flag_g_no')), 'не тиснув');
    expect(part(h.firstWhere((x) => x.flagId == 'flag_r_phone')), 'телефоні');
    // без перекриттів
    for (var i = 1; i < h.length; i++) {
      expect(h[i].start >= h[i - 1].end, isTrue);
    }
    // ті самі прапорці, що й у звичайних підказках
    expect(h.map((x) => x.flagId).toSet(), suggestFlags(t).toSet());
  });

  test('flagHits: англійська', () {
    const t = "he didn't push, asked if I was comfortable, walked me home. but he was on his phone half the night and was late";
    final ids = flagHits(t).map((x) => x.flagId).toSet();
    expect(ids, containsAll({'flag_g_no', 'flag_g_asks', 'flag_g_walk', 'flag_r_phone', 'flag_r_late'}));
    expect(ids.contains('flag_r_push'), isFalse);
    expect(ids, suggestFlags(t).toSet());
  });
}
