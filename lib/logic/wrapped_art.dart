// Вибір запечених картинок Wrapped за мовою: англійська бере свої варіанти там, де в макеті є текст.
import '../l10n/tr.dart';
import 'wrapped_layers.dart';
import 'wrapped_layers_en.dart';

/// Шлях до файла шару (en:… — з assets/wrapped_en/)
String wArt(String f) => f.startsWith('en:') ? 'assets/wrapped_en/${f.substring(3).replaceFirst('.webp', '.$wVEn.webp')}' : wAsset(f);

/// Фон слайда
String wBase(int k) {
  final n = 's${k.toString().padLeft(2, '0')}.webp';
  return isEn && wBaseEn.contains(k) ? wArt('en:$n') : wAsset(n);
}

/// Анімовані шари слайда
List<WL> wLayersOf(int k) => (isEn ? wLayersEn[k] : null) ?? wLayers[k] ?? const <WL>[];

/// Ім'я файла без префікса мови (для таблиць зсувів тощо)
String wPlain(String f) => f.startsWith('en:') ? f.substring(3) : f;
