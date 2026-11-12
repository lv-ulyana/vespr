import 'package:flutter/material.dart';

/// Токени з бренд-борда Vespr: Dusk, Hour, Haze, Afterglow, Star.
class C {
  static const bg = Color(0xFF17161F); // Dusk
  static const surface = Color(0xFF2B2836); // Hour
  static const card = Color(0xFF2A2734);
  static const line = Color(0x14F1EEF2);
  static const line2 = Color(0x24F1EEF2);
  static const text = Color(0xFFF1EEF2); // Star
  static const muted = Color(0xFFA49EB8);
  static const haze = Color(0xFF8C86A3); // Haze
  static const dim = Color(0xFF5E5874);
  static const accent = Color(0xFFF08A6C); // Afterglow
  static const accentSoft = Color(0xFFF4A189);
  static const accentBg = Color(0x1FF08A6C);
  static const green = Color(0xFF9FCBA9);
  static const red = Color(0xFFF2827A);
  static const danger = Color(0xFFD9544F);
  static const warm = Color(0xFF3A2E36);
  // Wrapped
  static const navy = Color(0xFF0E0D1F);
  static const pink = Color(0xFFFF9AD5);
  static const hotPink = Color(0xFFFF5C8A);
  static const yellow = Color(0xFFFFC83D);
}

class T {
  static TextStyle serif(double size, [Color color = C.text]) => TextStyle(fontFamily: 'Prata', fontSize: size, color: color, height: 1.15, letterSpacing: -0.2);
  static TextStyle body([double size = 14, Color color = C.text, FontWeight w = FontWeight.w400]) =>
      TextStyle(fontFamily: 'Raleway', fontSize: size, color: color, fontWeight: w, height: 1.45);
  static TextStyle label = const TextStyle(fontFamily: 'Raleway', fontSize: 11, color: C.haze, fontWeight: FontWeight.w600, letterSpacing: 1.4);
  static TextStyle onest(double size, Color color) => TextStyle(fontFamily: 'Onest', fontWeight: FontWeight.w800, fontSize: size, color: color, height: 1.0, letterSpacing: -1.2);
  static TextStyle corm(double size, Color color, {bool italic = false}) =>
      TextStyle(fontFamily: 'Cormorant', fontSize: size, color: color, fontWeight: italic ? FontWeight.w500 : FontWeight.w600, fontStyle: italic ? FontStyle.italic : FontStyle.normal, height: 1.15);
}

ThemeData vesprTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true, fontFamily: 'Raleway');
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: base.colorScheme.copyWith(primary: C.accent, secondary: C.accentSoft, surface: C.bg, onSurface: C.text, error: C.red),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.accent, selectionColor: Color(0x61F08A6C), selectionHandleColor: C.accent),
    splashFactory: NoSplash.splashFactory,
    snackBarTheme: const SnackBarThemeData(backgroundColor: C.surface, contentTextStyle: TextStyle(fontFamily: 'Raleway', color: C.text)),
  );
}
