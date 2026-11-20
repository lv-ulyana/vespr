// Спільна логіка для «Ваш метч» і «Порівняти двох → Зірки»:
// що «каже» аркан людини про ліжко і чи підтверджують це записи; сила аспекту знаків.
import '../data/models.dart';
import 'match_texts.dart';
import 'stats.dart';

/// Результат перевірки «аркан каже — записи перевіряють»
class ClaimCheck {
  final BedClaim claim;
  final String qLabel; // питання, яким реально перевірили (основне або запасне)
  final List<int> vals;
  const ClaimCheck(this.claim, this.qLabel, this.vals);
  double get value => avg(vals);
  bool get hasData => vals.isNotEmpty;
  bool get ok => hasData && value >= okFrom;
  static const okFrom = 3.5;
}

/// [arc] — аркан людини (1–22). Беремо записи з сексом і середню оцінку за питанням аркана.
/// Якщо основне питання вимкнене і оцінок нема — запасне, яке є в записі завжди.
ClaimCheck claimCheck(List<Entry> all, String personId, int arc) {
  final bc = bedClaims[arc];
  final es = entriesOf(all, personId).where((e) => e.hadSex).toList();
  List<int> valsOf(String q) => es.map((e) => q == 'sx_overall' ? (e.ratings['sx_overall'] ?? e.overall) : e.ratings[q]).whereType<int>().toList();
  final main = valsOf(bc.q);
  if (main.isNotEmpty) return ClaimCheck(bc, bc.qLabel, main);
  final fb = valsOf(BedClaim.fallback);
  return fb.isNotEmpty ? ClaimCheck(bc, BedClaim.fallbackLabel, fb) : ClaimCheck(bc, bc.qLabel, const []);
}

/// Сила аспекту для порівняння: більше — краще.
/// Тригон > секстиль > один знак > опозиція > сусідні > квінконс > квадрат.
/// Усі «легкі» аспекти (0, 2, 4, 6) стоять вище за всі «складніші» (1, 3, 5).
const aspectRank = <int, int>{4: 6, 2: 5, 0: 4, 6: 3, 1: 2, 5: 1, 3: 0};
int aspectStrength(int a, int b) => aspectRank[aspectDistance(a, b)]!;
