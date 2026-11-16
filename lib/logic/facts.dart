// Картка «Думка дня» на головній: короткі теплі думки в голосі Vespr і кілька старих цитат.
// Друга частина виділяється жирним. Довжина — щоб влізти в маленьку картку (≈80 знаків).

class DayFact {
  final String plain, accent;
  /// Думка, а не факт: інший підпис над карткою, акцент — це автор або ключові слова
  final bool thought;
  const DayFact(this.plain, this.accent, {this.thought = false});
  String get label => thought ? 'Думка дня' : 'Факт дня';
}

/// «Думка дня»: теплі короткі думки в голосі Vespr і кілька цитат, які давно в суспільному надбанні
/// (переклад наш). 
const dayThoughts = <DayFact>[
  DayFact('Тобі не треба заслуговувати ', 'на ніжність', thought: true),
  DayFact('«Ні» — це ', 'повне речення', thought: true),
  DayFact('Бажання не зобов’язане приходити ', 'за розкладом', thought: true),
  DayFact('Хороший вечір починається з того, що ', 'тобі спокійно', thought: true),
  DayFact('Хотіти більшого — ', 'не забагато', thought: true),
  DayFact('Тіло пам’ятає, де йому було добре. ', 'Слухай його', thought: true),
  DayFact('Метелики — це приємно. ', 'Спокій — це надійно', thought: true),
  DayFact('Сказати, чого хочеш, — ', 'сміливо, а не соромно', thought: true),
  DayFact('Найкращий секс там, де ', 'можна сміятись', thought: true),
  DayFact('Не треба вдавати, ', 'щоб тебе любили', thought: true),
  DayFact('Друге побачення ', 'не обов’язкове', thought: true),
  DayFact('Твоє задоволення — не бонус, а ', 'частина плану', thought: true),
  DayFact('Повільно — ', 'теж темп', thought: true),
  DayFact('Піти посеред вечора — ', 'теж вибір', thought: true),
  DayFact('Іноді найкраще побачення — ', 'з собою', thought: true),
  DayFact('Червоний прапорець не стає рожевим ', 'від гарної кави', thought: true),
  DayFact('У цій історії ти ', 'головна героїня, а не глядачка', thought: true),
  DayFact('Ніжність і пристрасть ', 'не сперечаються', thought: true),
  DayFact('Вір тому, як тобі після, ', 'а не обіцянкам до', thought: true),
  DayFact('Межі сьогодні можуть бути іншими, ніж учора. ', 'Це нормально', thought: true),
  DayFact('Хто чує тебе за столом, ', 'чує і в ліжку', thought: true),
  DayFact('Пауза в побаченнях — ', 'теж частина пошуку', thought: true),
  DayFact('Тобі можна хотіти ', 'і ніжно, і сміливо', thought: true),
  DayFact('Хімію не видно в анкеті. ', 'Її видно в записах', thought: true),
  // Оскар Вайлд, «Ідеальний чоловік», 1895
  DayFact('Любити себе — це початок роману на все життя. ', '— Оскар Вайлд', thought: true),
  // Джейн Остін, «Емма», 1815
  DayFact('Ніщо не чарує так, як ніжне серце. ', '— Джейн Остін', thought: true),
  // Леся Українка, «Хто вам сказав, що я слабка…»
  DayFact('Хто вам сказав, що я слабка, що я корюся долі? ', '— Леся Українка', thought: true),
];

/// Що показуємо в картці: тільки думки
const dayCards = dayThoughts;

/// Картка на сьогодні: щодня нова, по колу, однакова впродовж дня
DayFact factOfDay([DateTime? now]) {
  final d = now ?? DateTime.now();
  final day = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2026)).inDays;
  return dayCards[day % dayCards.length];
}
