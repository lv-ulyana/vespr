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

/// Тексти, що обрізані, вилазять за край екрана або налазять один на одного
List<Issue> scanText(RenderObject root, String tag, {double width = 390}) {
  final out = <Issue>[];
  final paras = <(Rect, String)>[];
  void walk(RenderObject r) {
    if (r is RenderParagraph && r.hasSize && r.attached && _visible(r)) {
      final t = r.text.toPlainText().trim();
      if (t.isNotEmpty) {
        // справжні межі гліфів з урахуванням повороту/масштабу
        final boxes = r.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: r.text.toPlainText().length));
        final local = boxes.isEmpty ? Offset.zero & r.size : boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b));
        final rect = MatrixUtils.transformRect(r.getTransformTo(null), local);
        // повністю поза екраном збоку (сусідні сторінки PageView) — не видно
        if (rect.right < 0 || rect.left > width) {
          r.visitChildren(walk);
          return;
        }
        paras.add((rect, t));
        if (r.didExceedMaxLines) out.add(Issue('$tag: обрізано «$t»'));
        // біжучі стрічки свідомо ширші за екран
        if (t.length < 60 && (rect.right > width + 1 || rect.left < -1)) {
          out.add(Issue('$tag: за краєм екрана «$t» ${rect.left.toStringAsFixed(0)}..${rect.right.toStringAsFixed(0)}'));
        }
      }
    }
    r.visitChildren(walk);
  }

  walk(root);
  for (var i = 0; i < paras.length; i++) {
    for (var j = i + 1; j < paras.length; j++) {
      final a = paras[i], b = paras[j];
      if (a.$2.length >= 60 && b.$2.length >= 60) continue;
      final x = a.$1.intersect(b.$1);
      if (x.width <= 3 || x.height <= 3) continue;
      final minH = a.$1.height < b.$1.height ? a.$1.height : b.$1.height;
      // рядки один під одним з тісним інтерліньяжем перекриваються трохи — це не налізання
      if (x.height < minH * .35) continue;
      final small = [a.$1.width * a.$1.height, b.$1.width * b.$1.height].reduce((p, q) => p < q ? p : q);
      if (x.width * x.height > small * .25) out.add(Issue('$tag: налазять «${a.$2}» і «${b.$2}»'));
    }
  }
  return out;
}
