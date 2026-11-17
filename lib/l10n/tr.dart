// Переклад інтерфейсу. Увесь код пише українською, а англійська підставляється
// в момент показу: власний віджет [Text] (замість стандартного) пропускає текст через [tr].
//
// Як шукається переклад:
//  1. точний збіг у словнику [enExact];
//  2. шаблони зі вставками ([enTpl]): «{0}: останні три зустрічі…» → «{0}: the last three…»,
//     вставки самі перекладаються, якщо вони українські (місяць, «рази» тощо);
//  3. кілька рядків — кожен окремо;
//  4. короткі рядки (дати, «3 рази») — по словах ([enWords]).
// Не знайшли — лишаємо як є (тест tests/en_test.dart ловить такі місця).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' as w;

import 'en.dart';

String _lang = 'uk';
String get appLang => _lang;
bool get isEn => _lang == 'en';
void setLang(String l) {
  if (l == _lang) return;
  _lang = l;
  _cache.clear();
}

final _cyr = RegExp('[А-Яа-яІіЇїЄєҐґ]');
final _cache = <String, String>{};

class _Tpl {
  final RegExp re;
  final String en;
  final int lits; // скільки «справжнього» тексту в шаблоні — довші пробуємо першими
  _Tpl(this.re, this.en, this.lits);
}

List<_Tpl>? _tpls;
List<_Tpl> get _templates => _tpls ??= () {
      final xs = <_Tpl>[];
      enTpl.forEach((uk, en) {
        final parts = uk.split(RegExp(r'\{\d+\}'));
        final idx = RegExp(r'\{(\d+)\}').allMatches(uk).map((x) => int.parse(x.group(1)!)).toList();
        final b = StringBuffer('^');
        for (var i = 0; i < parts.length; i++) {
          b.write(RegExp.escape(parts[i]));
          if (i < idx.length) b.write('(?<g${idx[i]}>[\\s\\S]*?)');
        }
        b.write(r'$');
        xs.add(_Tpl(RegExp(b.toString()), en, parts.join().length));
      });
      xs.sort((a, b) => b.lits.compareTo(a.lits));
      return xs;
    }();

/// Перекласти рядок для показу
String tr(String s) {
  if (_lang != 'en' || s.isEmpty || !_cyr.hasMatch(s)) return s;
  return _cache[s] ??= _translate(s);
}

/// Підставити значення в шаблон і перекласти: trf('Ще {0} записи', [n])
String trf(String uk, List<Object?> args) {
  var s = uk;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return tr(s);
}

String _translate(String s) {
  final ex = enExact[s];
  if (ex != null) return ex;
  final t = s.trim();
  if (t != s) {
    final e2 = enExact[t];
    if (e2 != null) return s.replaceFirst(t, e2);
  }
  for (final tp in _templates) {
    final mm = tp.re.firstMatch(s);
    if (mm == null) continue;
    var out = tp.en;
    for (final name in mm.groupNames) {
      final i = name.substring(1);
      out = out.replaceAll('{$i}', tr(mm.namedGroup(name) ?? ''));
    }
    return out;
  }
  if (s.contains('\n')) return s.split('\n').map(tr).join('\n');
  // короткі рядки — по словах (дати, «3 рази», «пн, 16 лист»)
  final words = s.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).length;
  if (words <= 5) {
    return s.replaceAllMapped(RegExp(r"[А-Яа-яІіЇїЄєҐґʼ'’]+"), (x) => enWords[x.group(0)!] ?? enWords[x.group(0)!.toLowerCase()] ?? enExact[x.group(0)!] ?? x.group(0)!);
  }
  if (kDebugMode) debugPrint('[tr] нема перекладу: $s');
  return s;
}

w.InlineSpan _trSpan(w.InlineSpan sp) {
  if (sp is w.TextSpan) {
    return w.TextSpan(
      text: sp.text == null ? null : tr(sp.text!),
      style: sp.style,
      recognizer: sp.recognizer,
      mouseCursor: sp.mouseCursor,
      onEnter: sp.onEnter,
      onExit: sp.onExit,
      semanticsLabel: sp.semanticsLabel == null ? null : tr(sp.semanticsLabel!),
      locale: sp.locale,
      spellOut: sp.spellOut,
      children: sp.children?.map(_trSpan).toList(),
    );
  }
  return sp;
}

/// Текст, що перекладається. Підміняє стандартний `Text` у всіх файлах апки
/// (`import 'package:flutter/material.dart' hide Text;` + цей файл).
class Text extends w.StatelessWidget {
  final String? data;
  final w.InlineSpan? textSpan;
  final w.TextStyle? style;
  final w.StrutStyle? strutStyle;
  final w.TextAlign? textAlign;
  final w.TextDirection? textDirection;
  final w.Locale? locale;
  final bool? softWrap;
  final w.TextOverflow? overflow;
  final w.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final w.TextWidthBasis? textWidthBasis;
  final w.TextHeightBehavior? textHeightBehavior;
  final w.Color? selectionColor;
  /// false — показати як є (імена, нотатки — те, що написала вона)
  final bool translate;

  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : textSpan = null;

  const Text.rich(
    w.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : data = null;

  @override
  w.Widget build(w.BuildContext context) {
    final sl = semanticsLabel == null ? null : (translate ? tr(semanticsLabel!) : semanticsLabel);
    if (data != null) {
      return w.Text(translate ? tr(data!) : data!,
          style: style, strutStyle: strutStyle, textAlign: textAlign, textDirection: textDirection, locale: locale, softWrap: softWrap, overflow: overflow,
          textScaler: textScaler, maxLines: maxLines, semanticsLabel: sl, textWidthBasis: textWidthBasis, textHeightBehavior: textHeightBehavior, selectionColor: selectionColor);
    }
    return w.Text.rich(translate ? _trSpan(textSpan!) : textSpan!,
        style: style, strutStyle: strutStyle, textAlign: textAlign, textDirection: textDirection, locale: locale, softWrap: softWrap, overflow: overflow,
        textScaler: textScaler, maxLines: maxLines, semanticsLabel: sl, textWidthBasis: textWidthBasis, textHeightBehavior: textHeightBehavior, selectionColor: selectionColor);
  }
}

// щоб material-віджети теж могли отримати переклад вручну
typedef MText = m.Text;
