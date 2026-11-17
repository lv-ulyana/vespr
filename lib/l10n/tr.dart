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

/// Чи можна лишити шматок як є: перекладено повністю, або це одне ім'я з великої (Марк, Оля).
bool _ok(String src, String out) => !_cyr.hasMatch(out) || (out == src && RegExp(r"^[А-ЯІЇЄҐ][А-Яа-яІіЇїЄєҐґʼ'’.\-]*$").hasMatch(src.trim()));

/// Повний переклад або null.
String? _try(String s) {
  final ex = enExact[s];
  if (ex != null) return ex;
  final t = s.trim();
  if (t.isEmpty) return s;
  if (t != s) {
    final e2 = _try(t);
    if (e2 != null) return s.replaceFirst(t, e2);
  }
  // шаблони: вставки мають перекластися або бути іменами/числами
  for (final tp in _templates) {
    final mm = tp.re.firstMatch(s);
    if (mm == null) continue;
    var out = tp.en;
    var good = true;
    for (final name in mm.groupNames) {
      final src = mm.namedGroup(name) ?? '';
      final tv = tr(src);
      if (!_ok(src, tv) && src.trim().split(RegExp(r'\s+')).length > 2) {
        good = false;
        break;
      }
      out = out.replaceAll('{${name.substring(1)}}', tv);
    }
    if (good) return out;
  }
  if (s.contains('\n')) {
    final ls = s.split('\n');
    final out = ls.map(tr).toList();
    return out.join('\n');
  }
  // регістр: «провів, викликав таксі» → як «Провів, …»; «ДІВА · ЗЕМЛЯ» → як «Діва · Земля»
  final f0 = t[0];
  if (t == s && f0 != f0.toUpperCase() && _cyr.hasMatch(f0)) {
    final up = _try(f0.toUpperCase() + s.substring(1));
    if (up != null && up.isNotEmpty && !_lowerKeep.hasMatch(up)) return up[0].toLowerCase() + up.substring(1);
  }
  if (t == s && s == s.toUpperCase() && s != s.toLowerCase()) {
    final low = s.toLowerCase();
    final title = low.replaceAllMapped(RegExp(r"(^|[\s·(«“—-]+)([а-яіїєґa-z])"), (x) => '${x.group(1)}${x.group(2)!.toUpperCase()}');
    final r = _try(title) ?? _try(low[0].toUpperCase() + low.substring(1));
    if (r != null) return r.toUpperCase();
  }
  // кілька речень: кожне окремо
  final sent = s.split(RegExp(r'(?<=[.!?…])\s+'));
  if (sent.length > 1) {
    final out = sent.map(_try).toList();
    if (out.every((x) => x != null)) return out.join(' ');
  }
  // хвостова пунктуація: «У нього…», «Кава:»
  final pm = RegExp(r'^([\s\S]*?)([.…:;!?,]+)$').firstMatch(s);
  if (pm != null && pm.group(1)!.isNotEmpty) {
    final core = _try(pm.group(1)!);
    if (core != null) return core + pm.group(2)!;
  }
  // перелік через роздільники: «Пізно, після 22:00, Ресторан», «Mark · пт, 13 лист»
  for (final sep in const [' · ', ' — ', ' + ', ' / ', '; ', ', ', ' і ', ' та ', ' й ']) {
    if (!s.contains(sep)) continue;
    final parts = s.split(sep);
    final out = <String>[];
    var good = true;
    for (final p in parts) {
      final tv = tr(p);
      if (!_ok(p, tv)) {
        good = false;
        break;
      }
      out.add(tv);
    }
    if (good) return out.join(const {' і ': ' and ', ' та ': ' and ', ' й ': ' and '}[sep] ?? sep);
  }
  // короткі рядки — по словах (дати, «3 рази», «пн, 16 лист»), тільки якщо перекладено все
  final words = s.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).length;
  if (words <= 5) {
    final out = s.replaceAllMapped(RegExp(r"[А-Яа-яІіЇїЄєҐґʼ'’]+"), (x) => enWords[x.group(0)!] ?? enWords[x.group(0)!.toLowerCase()] ?? enExact[x.group(0)!] ?? x.group(0)!);
    final rest = RegExp(r"[А-Яа-яІіЇїЄєҐґʼ'’]+").allMatches(out).map((x) => x.group(0)!);
    if (rest.every((x) => _ok(x, x))) return out;
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
