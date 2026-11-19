import 'package:flutter_test/flutter_test.dart';
import 'package:vespr/l10n/tr.dart';

void main() {
  test('жіночі форми: прапорці, займенники, винятки', () {
    expect(femUk('Провів, викликав таксі'), 'Провела, викликала таксі');
    expect(femUk('Наскільки тебе тягне до нього?'), 'Наскільки тебе тягне до неї?');
    expect(femUk('Збережи його в iCloud'), 'Збережи його в iCloud'); // «його» про річ не чіпаємо
    expect(femUk('з чоловіками'), 'з чоловіками'); // вибір в онбордингу
    expect(femUk('Від цього залежать «він» чи «вона» в питаннях'), 'Від цього залежать «він» чи «вона» в питаннях');
  });
  test('жіночі форми англійською', () {
    setLang('en');
    expect(tr(femUk('Сидів у телефоні')).toLowerCase(), contains('her'));
    expect(tr(femUk('Наскільки ти йому довіряєш?')).toLowerCase(), contains('her'));
    expect(tr('Дно · ср, 21 жовт'), 'Low · Wed, Oct 21');
    setLang('uk');
  });
}
