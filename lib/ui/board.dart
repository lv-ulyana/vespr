import 'package:flutter/material.dart';

import 'd.dart';

/// Спільні шматки дошок «Налаштування», «Експорт», «Імпорт», «Таблиця», «Підписка».
/// Класи з макета: .gl .grp .row .ic .val .sw .tabs .opt .chip .note .ghost .xopt .xbtn.

String _s(String inner, {double sw = 1.8, String extra = ''}) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="$sw" $extra>$inner</svg>';

class BS {
  static final chev = _s('<path d="M9 5l7 7-7 7"/>', sw: 2);
  static final ext = _s('<path d="M7 17L17 7M8 7h9v9"/>', sw: 2);
  static final restore = _s('<path d="M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5"/>');
  static final wrapped = _s('<rect x="4" y="3" width="16" height="18" rx="3"/><path d="M8 8h8M8 12h5"/>');
  static final download = _s('<path d="M12 3v12M7 10l5 5 5-5M5 21h14"/>');
  static final upload = _s('<path d="M12 15V3M7 8l5-5 5 5M5 21h14"/>');
  static final table = _s('<rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="M3 10h18M9 4v16"/>');
  static final bell = _s('<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21h4"/>');
  static final lock = _s('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>');
  static final dots = _s('<circle cx="6" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="18" cy="12" r="1.4"/>');
  static final square = _s('<rect x="4" y="4" width="16" height="16" rx="4"/>');
  static final eyeOff = _s('<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><path d="M4 4l16 16"/>');
  static final cloud = _s('<path d="M7 18a5 5 0 0 1-.5-10A6 6 0 0 1 18 8.5 4.5 4.5 0 0 1 17.5 18z"/><path d="M12 11v5M9.5 13.5 12 11l2.5 2.5"/>');
  static final cal = _s('<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/>');
  static final calPlus = _s('<rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 10h18M8 3v4M16 3v4M12 13v5M9.5 15.5h5"/>', sw: 2);
  static final globe = _s('<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>');
  static final heart = _s('<path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z"/>');
  static final people = _s('<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9" r="2.5"/>');
  static final trash = _s('<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>');
  static final list = _s('<path d="M4 6h16M4 12h16M4 18h10"/>');
  static final list3 = _s('<path d="M4 6h16M4 12h16M4 18h16"/>');
  static final clock = _s('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>');
  static final info = _s('<circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.4v.1"/>');
  static final phone = _s('<rect x="7" y="2" width="10" height="20" rx="2.5"/><path d="M11 18h2"/>');
  static final file = _s('<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>');
  static final caret = _s('<path d="M6 9l6 6 6-6"/>', sw: 2.4);
  static final close = _s('<path d="M6 6l12 12M18 6L6 18"/>');
  static final mic = _s('<rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>', sw: 1.7);
  static final starO = _s('<path d="M12 1l2.6 8.4L23 12l-8.4 2.6L12 23l-2.6-8.4L1 12l8.4-2.6z"/>', sw: 1.4);
  static final check = _s('<path d="M5 12.5l4.5 4.5L19 7.5"/>', sw: 3, extra: 'stroke-linecap="round" stroke-linejoin="round"');
  static final arrow = _s('<path d="M5 12h14M13 6l6 6-6 6"/>', sw: 2, extra: 'stroke-linecap="round"');
  static final warn = _s('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.4v.1"/>', sw: 1.7, extra: 'stroke-linecap="round"');
  static final card = _s('<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/>', sw: 1.7);
}

/// Шапка: кнопка назад, назва по центру, щось справа
class BoardHeader extends StatelessWidget {
  final String title;
  final Widget? right;
  final VoidCallback? onBack;
  const BoardHeader(this.title, {super.key, this.right, this.onBack});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Row(children: [
          BackBtn(onTap: onBack),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: rw(15, w: FontWeight.w600))),
          right ?? const SizedBox(width: 44),
        ]),
      );
}

/// .gl — підпис групи
class GLabel extends StatelessWidget {
  final String text;
  const GLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: rw(12, color: K.muted, w: FontWeight.w500, ls: .24)),
      );
}

/// Підпис + вміст
Widget labeled(String label, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [GLabel(label), child]);

/// .grp — картка-група з рядками, лінії між рядками з відступом [inset]
class Grp extends StatelessWidget {
  final List<Widget> children;
  final double inset;
  const Grp(this.children, {super.key, this.inset = 60});
  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(Padding(padding: EdgeInsets.only(left: inset), child: Container(height: 1, color: K.w(.06))));
      out.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: K.card2,
        borderRadius: BorderRadius.circular(22),
        border: Border(top: BorderSide(color: K.w(.07))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out),
    );
  }
}

/// .ic — квадратик з іконкою
class IcBox extends StatelessWidget {
  final String svg;
  final bool fill;
  const IcBox(this.svg, {super.key, this.fill = false});
  @override
  Widget build(BuildContext context) => Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: K.w(.07))),
        alignment: Alignment.center,
        child: Ico(svg, size: 16, color: K.acc),
      );
}

/// .sw — маленький перемикач 48×30
class SwS extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  final String label;
  const SwS({super.key, required this.on, required this.onChanged, required this.label});
  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            tap();
            onChanged(!on);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: easeD,
              width: 48, height: 30,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: on ? K.acc : K.w(.08)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: easeD,
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  margin: const EdgeInsets.all(4),
                  width: 22, height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: on ? K.star : K.haze),
                ),
              ),
            ),
          ),
        ),
      );
}

/// .row — рядок групи: іконка, назва (+підпис), значення / перемикач / стрілка
class GRow extends StatelessWidget {
  final String? icon;
  final String title;
  final String? sub, value;
  final Widget? trailing;
  final String? arrow; // svg праворуч; null — без стрілки
  final VoidCallback? onTap;
  final Color? color;
  final Widget? lead;
  const GRow({super.key, this.lead, this.icon, required this.title, this.sub, this.value, this.trailing, this.arrow, this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: sub != null ? 10 : 0),
        child: Row(children: [
          if (lead != null) ...[lead!, const SizedBox(width: 14)] else if (icon != null) ...[IcBox(icon!), const SizedBox(width: 14)],
          Expanded(
            child: sub == null
                ? Text(title, style: rw(15, color: color ?? K.star))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(title, style: rw(15, color: color ?? K.star)),
                    const SizedBox(height: 2),
                    Text(sub!, style: rw(12, color: K.muted, h: 1.35)),
                  ]),
          ),
          if (value != null) ...[const SizedBox(width: 8), Flexible(flex: 0, child: Text(value!, style: rw(13, color: K.muted), maxLines: 1, overflow: TextOverflow.ellipsis))],
          if (arrow != null) ...[const SizedBox(width: 6), Ico(arrow!, size: 14, color: K.muted)],
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, highlightColor: K.w(.03), splashColor: Colors.transparent, child: row),
    );
  }
}

/// .tabs — сегмент з двох-трьох вкладок (світла вибрана)
class Tabs extends StatelessWidget {
  final List<(String, String?)> items; // назва, svg
  final int index;
  final ValueChanged<int> onChanged;
  const Tabs({super.key, required this.items, required this.index, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    tap();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: easeD,
                    height: 44,
                    decoration: BoxDecoration(color: i == index ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (items[i].$2 != null) ...[Ico(items[i].$2!, size: 15, color: i == index ? K.bg : K.muted2), const SizedBox(width: 8)],
                      Text(items[i].$1, style: rw(14, color: i == index ? K.bg : K.muted2, w: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// .opt — велика картка-вибір з іконкою (у парі)
class OptCard extends StatelessWidget {
  final bool on;
  final String svg, title, sub;
  final VoidCallback onTap;
  const OptCard({super.key, required this.on, required this.svg, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
        selected: on,
        button: true,
        child: Press(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeD,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: on
                  ? onBase(RadialGradient(center: Alignment.topLeft, radius: 1.4, colors: [K.a(.16), K.a(0)], stops: const [0, .6]), K.w(.03))
                  : onBase(null, K.w(.025)),
              border: Border.all(color: on ? K.a(.6) : K.w(.08)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32, height: 32,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: K.a(.1), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Ico(svg, size: 16, color: K.acc),
              ),
              Text(title, style: rw(15, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(sub, style: rw(12, color: K.muted, h: 1.35)),
            ]),
          ),
        ),
      );
}

/// Дві картки .opt поруч однакової висоти
Widget optPair(Widget a, Widget b) => IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b)]),
    );

/// .chip
class DChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final double height;
  const DChip(this.label, {super.key, this.on = false, this.onTap, this.height = 36});
  @override
  Widget build(BuildContext context) => Semantics(
        selected: on,
        button: true,
        child: Press(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeD,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: on ? K.a(.14) : K.w(.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? K.acc : K.w(.1)),
            ),
            alignment: Alignment.center,
            child: Text(label, style: rw(13, color: on ? K.star : K.soft2, w: FontWeight.w500)),
          ),
        ),
      );
}

Widget chipsWrap(List<Widget> xs) => Wrap(spacing: 6, runSpacing: 6, children: xs);

/// .note — примітка з іконкою
class NoteBox extends StatelessWidget {
  final String svg, text;
  final Color? iconColor;
  const NoteBox(this.text, {super.key, String? svg, this.iconColor}) : svg = svg ?? '';
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.07))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Ico(svg.isEmpty ? BS.info : svg, size: 15, color: iconColor ?? K.acc)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: rw(12, color: K.muted, h: 1.5))),
        ]),
      );
}

/// .cta з іконкою зліва
class CtaIco extends StatelessWidget {
  final String text;
  final String? svg;
  final VoidCallback? onTap;
  final double height, size;
  const CtaIco(this.text, {super.key, this.svg, this.onTap, this.height = 56, this.size = 16});
  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    final fg = off ? K.haze : K.bg;
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: easeD,
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: off ? K.w(.06) : K.acc),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (svg != null) ...[Ico(svg!, size: 17, color: fg), const SizedBox(width: 8)],
          Flexible(child: Text(text, style: rw(size, color: fg, w: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

/// .ghost — прозора кнопка 48 з рамкою
class GhostBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final String? svg;
  const GhostBtn(this.text, {super.key, this.onTap, this.svg});
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: K.w(.04), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.1))),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (svg != null) ...[Ico(svg!, size: 16, color: onTap == null ? K.haze : K.star), const SizedBox(width: 8)],
            Text(text, style: rw(14, color: onTap == null ? K.haze : K.star, w: FontWeight.w500)),
          ]),
        ),
      );
}

// ---------- шторки (.xsheet) ----------
Widget sheetTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(t, style: pr(24, h: 1.15)));
Widget sheetText(String t) => Text(t, style: rw(13, color: K.muted, h: 1.45));

/// .xopt — варіант у шторці з радіо праворуч
class XOpt extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? lead;
  final bool on, radio;
  final Color? color;
  final VoidCallback onTap;
  const XOpt({super.key, required this.title, this.sub, this.lead, this.on = false, this.radio = true, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
        selected: on,
        button: true,
        child: Press(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: on ? onBase(RadialGradient(center: Alignment.topLeft, radius: 1.4, colors: [K.a(.14), K.a(0)], stops: const [0, .6]), K.w(.03)) : onBase(null, K.w(.025)),
              border: Border.all(color: on ? K.a(.55) : K.w(.07)),
            ),
            child: Row(children: [
              if (lead != null) ...[lead!, const SizedBox(width: 12)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, style: rw(15, color: color ?? K.star, w: FontWeight.w500)),
                  if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: rw(12, color: K.muted))),
                ]),
              ),
              if (radio)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 22, height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: on ? K.acc : Colors.transparent, border: Border.all(color: on ? K.acc : K.w(.25), width: 1.5)),
                  alignment: Alignment.center,
                  child: on ? Ico(Svgs.tick, size: 12, color: K.bg) : null,
                ),
            ]),
          ),
        ),
      );
}

/// .xbtn.g — текстова кнопка «Скасувати»
Widget sheetCancel(BuildContext context, [String text = 'Скасувати']) => Press(
      onTap: () => Navigator.pop(context),
      child: SizedBox(height: 44, child: Center(child: Text(text, style: rw(15, w: FontWeight.w600)))),
    );

/// Світіння згори сторінки (radial-gradient ellipse rgba(240,138,108,.12))
Widget topGlow() => Positioned(
      left: -60, top: -80,
      child: IgnorePointer(child: EGlow(w: 520, h: 420, colors: [K.a(.12), K.a(0)], stops: const [0, .68])),
    );
