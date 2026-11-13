// Спільне для тестів верстки: справжні шрифти і пошук проблем з текстом.
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const _fams = {
  'Onest': 'Onest_',
  'Prata': 'Prata_',
  'Raleway': 'Raleway_',
  'PlexMono': 'IBMPlexMono_',
  'Cormorant': 'CormorantGaramond_',
  'Montserrat': 'Montserrat_',
  'Oswald': 'Oswald_',
  'Zodiac': 'NotoZodiac',
};

Future<void> loadFonts() async {
  final files = Directory('assets/fonts').listSync().whereType<File>().where((f) => f.path.endsWith('.ttf')).toList();
  for (final e in _fams.entries) {
    final l = FontLoader(e.key);
    for (final f in files.where((f) => f.uri.pathSegments.last.startsWith(e.value))) {
      l.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await l.load();
  }
}

class Issue {
  final String what;
  const Issue(this.what);
  @override
  String toString() => what;
}

/// Чи видно цей вузол: не під нульовою прозорістю і не в Offstage
bool _visible(RenderObject r) {
  RenderObject? c = r;
  RenderObject? p = r;
  while (p != null) {
    if (p is RenderOpacity && p.opacity < .05) return false;
    if (p is RenderAnimatedOpacity && p.opacity.value < .05) return false;
    if (p is RenderOffstage && p.offstage) return false;
    // IndexedStack (вкладки): видно тільки поточну дитину
    if (p is RenderIndexedStack && c != p) {
      final kids = <RenderObject>[];
      p.visitChildren(kids.add);
      if (kids.indexOf(c!) != p.index) return false;
    }
    c = p;
    p = p.parent;
  }
  return true;
}

class _Para {
  final List<Rect> lines; // «чорнильні» рядки: без порожнього міжрядкового простору
  final Rect rect;
  final String t;
  final RenderViewportBase? vp; // вертикальна прокрутка
  final double rest; // скільки ще можна прокрутити вниз
  _Para(this.lines, this.rect, this.t, this.vp, this.rest);
}

/// Тексти, що обрізані, вилазять за край екрана або налазять один на одного
List<Issue> scanText(RenderObject root, String tag, {double width = 390}) {
  final out = <Issue>[];
  final paras = <_Para>[];
  void walk(RenderObject r) {
    if (r is RenderParagraph && r.hasSize && r.attached && _visible(r)) {
      final full = r.text.toPlainText();
      final t = full.trim();
      if (t.isNotEmpty) {
        final m = r.getTransformTo(null);
        // справжні межі гліфів з урахуванням повороту/масштабу
        final boxes = r.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: full.length));
        final local = boxes.isEmpty ? Offset.zero & r.size : boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b));
        final rect = MatrixUtils.transformRect(m, local);
        // рядок — без інтерліньяжу: верх 18% і низ 12% бокса це повітря
        final lines = [
          for (final b in boxes)
            if (b.toRect().height > 0)
              MatrixUtils.transformRect(m, Rect.fromLTRB(b.left, b.top + (b.bottom - b.top) * .18, b.right, b.bottom - (b.bottom - b.top) * .12)),
        ];
        // повністю поза екраном збоку (сусідні сторінки PageView) — не видно
        if (rect.right < 0 || rect.left > width) {
          r.visitChildren(walk);
          return;
        }
        RenderViewportBase? vp;
        var hScroll = false;
        for (RenderObject? p = r.parent; p != null; p = p.parent) {
          if (p is RenderViewportBase) {
            if (p.axis == Axis.horizontal) {
              hScroll = true;
            } else {
              vp ??= p;
            }
          }
        }
        var rest = 0.0;
        final off = vp?.offset;
        if (off is ScrollPosition && off.hasContentDimensions) rest = off.maxScrollExtent - off.pixels;
        paras.add(_Para(lines.isEmpty ? [rect] : lines, rect, t, vp, rest));
        if (r.didExceedMaxLines) out.add(Issue('$tag: обрізано «$t»'));
        // біжучі стрічки й горизонтальні стрічки чипів свідомо ширші за екран
        if (!hScroll && t.length < 60 && (rect.right > width + 1 || rect.left < -1)) {
          out.add(Issue('$tag: за краєм екрана «$t» ${rect.left.toStringAsFixed(0)}..${rect.right.toStringAsFixed(0)}'));
        }
      }
    }
    r.visitChildren(walk);
  }

  bool hit(List<Rect> a, List<Rect> b) {
    for (final x in a) {
      for (final y in b) {
        final i = x.intersect(y);
        if (i.width <= 3 || i.height <= 3) continue;
        final minH = x.height < y.height ? x.height : y.height;
        if (i.height < minH * .3) continue;
        final small = [x.width * x.height, y.width * y.height].reduce((p, q) => p < q ? p : q);
        if (i.width * i.height > small * .2) return true;
      }
    }
    return false;
  }

  List<Rect> up(_Para p) => [for (final l in p.lines) l.shift(Offset(0, -p.rest))];

  walk(root);
  for (var i = 0; i < paras.length; i++) {
    for (var j = i + 1; j < paras.length; j++) {
      final a = paras[i], b = paras[j];
      // біжучі стрічки (довгий повторюваний текст під кутом) не рахуємо
      if (a.t.length >= 60 || b.t.length >= 60) continue;
      if (!hit(a.lines, b.lines)) continue;
      // текст у прокрутці під закріпленою панеллю: ок, якщо прокруткою його можна вивести
      if (a.vp != b.vp) {
        final la = a.vp == null ? a.lines : up(a);
        final lb = b.vp == null ? b.lines : up(b);
        if (!hit(la, lb)) continue;
      }
      out.add(Issue('$tag: налазять «${a.t}» і «${b.t}»'));
    }
  }
  return out;
}
