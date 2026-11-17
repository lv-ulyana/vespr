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
  _good.clear();
}

final _cyr = RegExp('[А-Яа-яІіЇїЄєҐґ]');
final _cache = <String, String>{};
// англійське слово, яке не можна писати з малої (I, I’m)
final _lowerKeep = RegExp(r"^I(\b|’|')");

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

String _translate(String s) => _try(s) ?? _fallback(s);

final _busy = <String>{};
final _good = <String, String>{};

/// Ім'я з великої (Марк, Олександр-Максиміліан, Костянтин Вікторович) — лишаємо як є
bool _isName(String s) {
  final ws = s.trim().split(RegExp(r'\s+'));
  return ws.length <= 3 && ws.every((x) => RegExp(r"^[А-ЯІЇЄҐ][а-яіїєґʼ'’\-А-ЯІЇЄҐ]*\.?$").hasMatch(x));
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Повний переклад (без українських слів, крім імен) або null.
String? _try(String s) {
  if (!_cyr.hasMatch(s)) return s;
  final g = _good[s];
  if (g != null) return g;
  if (!_busy.add(s)) return null;
  try {
    final r = _try0(s);
    if (r != null) _good[s] = r;
    return r;
  } finally {
    _busy.remove(s);
  }
}

String? _try0(String s) {
  final ex = enExact[s];
  if (ex != null) return ex;
  final t = s.trim();
  if (t != s) {
    final r = _try(t);
    return r == null ? null : s.replaceFirst(t, r);
  }
  // ВЕЛИКИМИ: перекладаємо як звичайний текст і знову робимо великими
  if (s == s.toUpperCase() && s != s.toLowerCase()) {
    final low = s.toLowerCase();
    final title = low.replaceAllMapped(RegExp(r"(^|[\s·(«“—\-]+)([а-яіїєґa-z])"), (x) => '${x.group(1)}${x.group(2)!.toUpperCase()}');
    for (final c in [low, _cap(low), title]) {
      final r = _try(c);
      if (r != null) return r.toUpperCase();
    }
  }
  // з малої: «провів, викликав таксі» → як «Провів, …»
  final f0 = s[0];
  if (f0 != f0.toUpperCase() && _cyr.hasMatch(f0)) {
    final up = _try(_cap(s));
    if (up != null && up.isNotEmpty && !_lowerKeep.hasMatch(up)) return up[0].toLowerCase() + up.substring(1);
  }
  // шаблони: вставки мають перекластися або бути іменами/числами
  for (final tp in _templates) {
    final mm = tp.re.firstMatch(s);
    if (mm == null) continue;
    var out = tp.en;
    var good = true;
    for (final name in mm.groupNames) {
      final src = mm.namedGroup(name) ?? '';
      if (src == s) {
        good = false;
        break;
      }
      final tv = _try(src) ?? (_isName(src) ? src : null);
      if (tv == null) {
        good = false;
        break;
      }
      out = out.replaceAll('{${name.substring(1)}}', tv);
    }
    if (good) return out;
  }
  // кілька рядків, кілька речень
  for (final re in [RegExp(r'\n'), RegExp(r'(?<=[.!?…])\s+')]) {
    if (!re.hasMatch(s)) continue;
    final seps = re.allMatches(s).map((m) => m.group(0)!).toList();
    final parts = s.split(re);
    final out = StringBuffer();
    var good = true;
    for (var i = 0; i < parts.length; i++) {
      final r = _try(parts[i]) ?? (_isName(parts[i]) ? parts[i] : null);
      if (r == null) {
        good = false;
        break;
      }
      out.write(r);
      if (i < seps.length) out.write(seps[i]);
    }
    if (good) return out.toString();
  }
  // хвостова пунктуація: «У нього…», «Кава:»
  final pm = RegExp(r'^([\s\S]*?)([.…:;!?,]+)$').firstMatch(s);
  if (pm != null && pm.group(1)!.isNotEmpty) {
    final core = _try(pm.group(1)!);
    if (core != null) return core + pm.group(2)!;
  }
  // перелік через роздільники
  for (final sep in const [' ✦ ', ' · ', ' — ', ' + ', ' / ', '; ', ', ', ': ', ' і ', ' та ', ' й ']) {
    if (!s.contains(sep)) continue;
    final parts = s.split(sep);
    final out = <String>[];
    var good = true;
    for (final p in parts) {
      final r = _try(p) ?? (_isName(p) ? p : null);
      if (r == null) {
        good = false;
        break;
      }
      out.add(r);
    }
    if (good) return out.join(const {' і ': ' and ', ' та ': ' and ', ' й ': ' and '}[sep] ?? sep);
  }
  // короткі рядки — по словах (дати, «3 рази», «пн, 16 лист»), тільки якщо перекладено все
  final words = s.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).length;
  if (words <= 5) {
    var good = true;
    final out = s.replaceAllMapped(RegExp(r"[А-Яа-яІіЇїЄєҐґʼ'’]+"), (x) {
      final w0 = x.group(0)!;
      final r = enWords[w0] ?? enWords[w0.toLowerCase()] ?? enExact[w0];
      if (r == null && !_isName(w0)) good = false;
      return r ?? w0;
    });
    if (good) return out;
  }
  return null;
}

String _fallback(String s) {
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
