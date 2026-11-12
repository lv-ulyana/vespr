// Примітиви, перенесені з дизайн-дошок «Vespr — дизайн апки» один в один:
// ті самі кольори, радіуси, розміри шрифтів і SVG-іконки.
// Екрани малюються в системі координат макета (ширина 390) і масштабуються під екран.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Навігатор апки (для переходів з-під екрана блокування)
final appNav = GlobalKey<NavigatorState>();

// ---------- Кольори з макета ----------
class K {
  static const bg = Color(0xFF17161F);
  static const hour = Color(0xFF2B2836);
  static const card2 = Color(0xFF25222F);
  static const star = Color(0xFFF1EEF2);
  static const muted = Color(0xFFA49EB8);
  static const muted2 = Color(0xFF9A94B0);
  static const haze = Color(0xFF8C86A3);
  static const soft = Color(0xFFB9B4CB);
  static const soft2 = Color(0xFFC9C4D6);
  static const acc = Color(0xFFF08A6C);
  static const accSoft = Color(0xFFF4A189);
  static const green = Color(0xFF9FCBA9);
  static const red = Color(0xFFF2827A);
  static const dimC = Color(0xFF5E5874);
  static Color w(double a) => star.withValues(alpha: a); // rgba(241,238,242,a)
  static Color a(double a) => acc.withValues(alpha: a); // rgba(240,138,108,a)
}

/// Крива з макета: cubic-bezier(.32,.72,0,1)
const easeD = Cubic(.32, .72, 0, 1);
const easeOut = Cubic(.16, 1, .3, 1);

TextStyle rw(double size, {Color color = K.star, FontWeight w = FontWeight.w400, double? h, double? ls}) =>
    TextStyle(fontFamily: 'Raleway', fontSize: size, color: color, fontWeight: w, height: h, letterSpacing: ls, decoration: TextDecoration.none);
TextStyle pr(double size, {Color color = K.star, double? h, double ls = -.01}) =>
    TextStyle(fontFamily: 'Prata', fontSize: size, color: color, height: h, letterSpacing: size * ls, decoration: TextDecoration.none);

/// Заголовок Prata з акцентною частиною: «Трохи» + «про тебе»
Widget titleAcc(List<(String, bool)> parts, double size, {double h = 1.1, TextAlign align = TextAlign.left}) => Text.rich(
      TextSpan(children: [for (final p in parts) TextSpan(text: p.$1, style: p.$2 ? const TextStyle(color: K.accSoft) : null)]),
      style: pr(size, h: h),
      textAlign: align,
    );

// ---------- Кадр макета ----------
/// Малює екран у координатах макета: ширина завжди 390, висота — скільки влазить.
/// На широкому екрані (компʼютер) апка стоїть по центру, як телефон.
class DFrame extends StatelessWidget {
  final Widget Function(BuildContext context, double h) builder;
  final Color bg;
  const DFrame({super.key, required this.builder, this.bg = K.bg});
  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(builder: (context, c) {
              final s = c.maxWidth / 390;
              final h = c.maxHeight / s;
              return FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(width: 390, height: h, child: ClipRect(child: builder(context, h))),
              );
            }),
          ),
        ),
      );
}

/// Те саме, але контент прокручується (довгі екрани макета: 930, 1180…)
class DScroll extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;
  final Widget? bottom; // закріплена кнопка внизу
  final List<Widget> overlay;
  const DScroll({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(20, 58, 20, 22), this.gap = 16, this.bottom, this.overlay = const []});
  @override
  Widget build(BuildContext context) => DFrame(
        builder: (context, h) => Stack(children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: padding.copyWith(bottom: padding.bottom + (bottom != null ? 80 : 0)),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h - padding.vertical - (bottom != null ? 80 : 0)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(children, gap)),
              ),
            ),
          ),
          if (bottom != null) Positioned(left: padding.left, right: padding.right, bottom: padding.bottom, child: bottom!),
          ...overlay,
        ]),
      );
}

List<Widget> gapped(List<Widget> xs, double g, {bool horizontal = false}) {
  final out = <Widget>[];
  for (var i = 0; i < xs.length; i++) {
    if (i > 0) out.add(horizontal ? SizedBox(width: g) : SizedBox(height: g));
    out.add(xs[i]);
  }
  return out;
}

// ---------- SVG з макета ----------
/// Іконка з SVG-розмітки макета (вставлена як є). currentColor = [color].
class Ico extends StatelessWidget {
  final String svg;
  final double size;
  final Color color;
  const Ico(this.svg, {super.key, this.size = 20, this.color = K.star});
  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, width: size, height: size, theme: SvgTheme(currentColor: color));
}

String _stroke(String inner, {double sw = 1.6, String extra = ''}) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="$sw" $extra>$inner</svg>';

class Svgs {
  static final back = _stroke('<path d="M15 5l-7 7 7 7"/>');
  static final arrowR = _stroke('<path d="M5 12h14M13 6l6 6-6 6"/>', sw: 2);
  static final arrowL = _stroke('<path d="M19 12H5M11 6l-6 6 6 6"/>', sw: 2);
  static final lock = _stroke('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>');
  static final lockDot = _stroke('<rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/><circle cx="12" cy="16" r="1.2" fill="currentColor" stroke="none"/>', extra: 'stroke-linecap="round"');
  static final lockOpen = _stroke('<rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8 11V8a4 4 0 0 1 7.5-2"/><circle cx="12" cy="16" r="1.2" fill="currentColor" stroke="none"/>', extra: 'stroke-linecap="round"');
  static final mic = _stroke('<rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>', sw: 2);
  static final mic2 = _stroke('<rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/>', sw: 2.2);
  static const star4 = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 1l2.6 8.4L23 12l-8.4 2.6L12 23l-2.6-8.4L1 12l8.4-2.6z"/></svg>';
  static final trend = _stroke('<path d="M3 17l6-6 4 4 8-8M15 7h6v6"/>', sw: 2);
  static final people = _stroke('<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9" r="2.5"/><path d="M16 14.5a5 5 0 0 1 5.5 5"/>', sw: 2);
  static final del = _stroke('<path d="M9 5h11a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H9l-6-7z"/><path d="M12 9.5l5 5M17 9.5l-5 5"/>', sw: 1.5);
  static final faceId = _stroke('<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2M9 9v1.5M15 9v1.5M12 9v4h-1M9.5 16a4 4 0 0 0 5 0"/>', sw: 1.5);
  static final check = _stroke('<path d="M5 12.5l4.5 4.5L19 7.5"/>', sw: 3.5);
  static final camera = _stroke('<path d="M4 8h3l2-2.5h6L17 8h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>', sw: 1.7);
  static final gallery = _stroke('<rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-9 9"/>', sw: 1.7);
  static final chevR = _stroke('<path d="M9 5l7 7-7 7"/>', sw: 2, extra: 'stroke-linecap="round"');
  static final trash = _stroke('<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>', sw: 1.7, extra: 'stroke-linecap="round"');
  static final tick = _stroke('<path d="M5 12l5 5L20 7"/>', sw: 2.2, extra: 'stroke-linecap="round" stroke-linejoin="round"');
}

// ---------- Кнопки й дрібниці ----------
void tap() => HapticFeedback.selectionClick();

/// Натискання як у макеті: :active{transform:scale(.97)}
class Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const Press({super.key, required this.child, this.onTap, this.scale = .97, this.label});
  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool down = false;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: widget.onTap != null,
        label: widget.label,
        child: MouseRegion(
          cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onTap == null ? null : (_) => setState(() => down = true),
            onTapCancel: () => setState(() => down = false),
            onTapUp: (_) => setState(() => down = false),
            onTap: widget.onTap == null ? null : () { tap(); widget.onTap!(); },
            child: AnimatedScale(scale: down ? widget.scale : 1, duration: const Duration(milliseconds: 120), curve: easeOut, child: widget.child),
          ),
        ),
      );
}

/// .iconbtn — кругла кнопка 44 на #2B2836
class IconBtn extends StatelessWidget {
  final String svg;
  final VoidCallback? onTap;
  final String label;
  const IconBtn({super.key, required this.svg, required this.onTap, required this.label});
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        label: label,
        child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.hour), alignment: Alignment.center, child: Ico(svg, size: 20)),
      );
}

class BackBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const BackBtn({super.key, this.onTap});
  @override
  Widget build(BuildContext context) => IconBtn(svg: Svgs.back, label: 'Назад', onTap: onTap ?? () => Navigator.of(context).maybePop());
}

/// .cta — помаранчева кнопка 56
class Cta extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool arrow;
  final FontWeight weight;
  const Cta(this.text, {super.key, this.onTap, this.arrow = false, this.weight = FontWeight.w600});
  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    final fg = off ? K.haze : K.bg;
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: easeD,
        height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: off ? K.w(.06) : K.acc),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: rw(16, color: fg, w: weight)),
          if (arrow) ...[const SizedBox(width: 10), Ico(Svgs.arrowR, size: 18, color: fg)],
        ]),
      ),
    );
  }
}

/// Три риски кроків онбордингу (28×3)
class StepBars extends StatelessWidget {
  final int n, of;
  const StepBars(this.n, {super.key, this.of = 3});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Крок $n з $of',
        child: Row(mainAxisSize: MainAxisSize.min, children: gapped([
          for (var i = 1; i <= of; i++)
            AnimatedContainer(duration: const Duration(milliseconds: 400), width: 28, height: 3, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: i <= n ? K.acc : K.w(.14))),
        ], 6, horizontal: true)),
      );
}

/// Шапка з кнопкою назад, кроками по центру і чимось справа
class StepHeader extends StatelessWidget {
  final int step;
  final Widget? right;
  final VoidCallback? onBack;
  const StepHeader(this.step, {super.key, this.right, this.onBack});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Stack(alignment: Alignment.center, children: [
          Center(child: StepBars(step)),
          Align(alignment: Alignment.centerLeft, child: BackBtn(onTap: onBack)),
          if (right != null) Align(alignment: Alignment.centerRight, child: right),
        ]),
      );
}

/// Радіальне світіння-пляма з макета
class Glow extends StatelessWidget {
  final double w, h;
  final List<Color> colors;
  final List<double> stops;
  final bool circle;
  const Glow({super.key, required this.w, required this.h, required this.colors, required this.stops, this.circle = false});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            gradient: RadialGradient(colors: colors, stops: stops, radius: .707), // CSS farthest-corner
          ),
        ),
      );
}

/// Еліптичне світіння: CSS «radial-gradient(ellipse, …)» розтягнутий по прямокутнику
class EGlow extends StatelessWidget {
  final double w, h;
  final List<Color> colors;
  final List<double> stops;
  const EGlow({super.key, required this.w, required this.h, required this.colors, required this.stops});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          width: w,
          height: h,
          child: Transform.scale(
            scaleY: h / w,
            child: OverflowBox(
              maxHeight: w,
              child: Container(
                width: w,
                height: w,
                // CSS ellipse farthest-corner ≈ півдіагоналі; беремо .707 від сторони
                decoration: BoxDecoration(gradient: RadialGradient(colors: colors, stops: stops, radius: .707)),
              ),
            ),
          ),
        ),
      );
}

/// Крапка-зірка на фоні
Widget starDot(double l, double t, double s, Color c, double o) =>
    Positioned(left: l, top: t, child: Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: o))));

/// .sw — перемикач 52×32
class Sw extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  final String label;
  const Sw({super.key, required this.on, required this.onChanged, required this.label});
  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        label: label,
        child: Press(
          onTap: () => onChanged(!on),
          scale: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeD,
            width: 52, height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: on ? K.acc : K.w(.08)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: easeD,
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.all(4),
                width: 24, height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: on ? K.star : K.haze),
              ),
            ),
          ),
        ),
      );
}

/// .ck — круглий чекбокс з галочкою
class Ck extends StatelessWidget {
  final bool on;
  final double size;
  const Ck(this.on, {super.key, this.size = 24});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: easeD,
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: on ? K.acc : Colors.transparent, border: Border.all(color: on ? K.acc : K.w(.25), width: 1.5)),
        alignment: Alignment.center,
        child: on ? Ico(Svgs.tick, size: size * .55, color: K.bg) : null,
      );
}

/// Поява знизу (.in1/.in2/.in3 і .stg > *): 0.7 c, затримка
class Rise extends StatefulWidget {
  final Widget child;
  final double delay; // секунди
  final double dy;
  const Rise({super.key, required this.child, this.delay = 0, this.dy = 18});
  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
      if (mounted) c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // «Зменшити рух» у системі — показуємо одразу, без анімації
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) c.value = 1;
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: c, curve: easeOut);
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (_, child) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, (1 - a.value) * widget.dy), child: child)),
    );
  }
}

/// Поле вводу з макета (.field input / .inp)
class DInput extends StatefulWidget {
  final TextEditingController controller;
  final double height, radius;
  final TextStyle style;
  final TextAlign align;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final FocusNode? focus;
  final String? hint;
  final String? label;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization caps;
  final int lines;
  const DInput({super.key, required this.controller, this.height = 56, this.radius = 18, required this.style, this.align = TextAlign.left, this.keyboard, this.formatters, this.onChanged, this.focus, this.hint, this.label, this.action, this.onSubmitted, this.caps = TextCapitalization.none, this.lines = 1});
  @override
  State<DInput> createState() => _DInputState();
}

class _DInputState extends State<DInput> {
  FocusNode? _own;
  FocusNode get f => widget.focus ?? (_own ??= FocusNode());
  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FocusBox(
        focus: f,
        height: widget.height,
        radius: widget.radius,
        top: widget.lines > 1,
        child: Semantics(
          label: widget.label,
          child: TextField(
            controller: widget.controller,
            focusNode: f,
            textAlign: widget.align,
            keyboardType: widget.keyboard,
            inputFormatters: widget.formatters,
            onChanged: widget.onChanged,
            textInputAction: widget.action,
            onSubmitted: widget.onSubmitted,
            textCapitalization: widget.caps,
            maxLines: widget.lines,
            minLines: widget.lines > 1 ? widget.lines : null,
            cursorColor: K.acc,
            style: widget.style,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: rw(14, color: K.haze, w: FontWeight.w500),
              contentPadding: widget.lines > 1 ? const EdgeInsets.fromLTRB(16, 16, 16, 16) : EdgeInsets.symmetric(horizontal: widget.align == TextAlign.left ? 16 : 0),
            ),
          ),
        ),
      );
}

class _FocusBox extends StatefulWidget {
  final FocusNode focus;
  final Widget child;
  final double height, radius;
  final bool top;
  const _FocusBox({required this.focus, required this.child, required this.height, required this.radius, this.top = false});
  @override
  State<_FocusBox> createState() => _FocusBoxState();
}

class _FocusBoxState extends State<_FocusBox> {
  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_on);
  }

  void _on() => setState(() {});

  @override
  void dispose() {
    widget.focus.removeListener(_on);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: easeD,
      height: widget.height,
      alignment: widget.top ? Alignment.topLeft : Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        color: f ? K.a(.05) : K.w(.03),
        border: Border.all(color: f ? K.a(.7) : K.w(.1)),
      ),
      child: widget.child,
    );
  }
}

/// Нижній лист (.xsheet / .sheet) з затемненням
Future<T?> showSheet<T>(BuildContext context, Widget Function(BuildContext) builder) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрити',
      barrierColor: const Color(0x990A090E),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionBuilder: (ctx, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: easeD);
        return Opacity(opacity: c.value, child: Transform.translate(offset: Offset(0, (1 - c.value) * 30), child: child));
      },
    );

class Sheet extends StatelessWidget {
  final List<Widget> children;
  const Sheet({super.key, required this.children});
  @override
  Widget build(BuildContext context) => DFrame(
        bg: Colors.transparent,
        builder: (context, h) => Stack(children: [
          Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(context))),
          Positioned(
            left: 12, right: 12, bottom: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
              decoration: BoxDecoration(
                color: K.card2,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0xCC09080E), blurRadius: 60, offset: Offset(0, -20), spreadRadius: -20)],
                border: Border(top: BorderSide(color: K.w(.09))),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(top: -18, left: 0, right: 0, child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: K.w(.18), borderRadius: BorderRadius.circular(2))))),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(children, 10)),
              ]),
            ),
          ),
        ]),
      );
}

/// Тост з макета (.xtoast): білий, з галочкою
void dToast(BuildContext context, String text) {
  final o = Overlay.of(context);
  late OverlayEntry e;
  e = OverlayEntry(
    builder: (_) => Positioned(
      left: 16, right: 16, bottom: 24,
      child: Rise(
        dy: 30,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -12)]),
            child: Row(children: [Ico(Svgs.tick, size: 16, color: K.bg), const SizedBox(width: 10), Expanded(child: Text(text, style: rw(14, color: K.bg, w: FontWeight.w600)))]),
          ),
        ),
      ),
    ),
  );
  o.insert(e);
  Future.delayed(const Duration(milliseconds: 2600), e.remove);
}

/// Тост з кнопкою «Повернути» і смужкою 5 с (.done у PersonActions)
void undoToast(BuildContext context, String text, Future<void> Function() undo, {OverlayState? overlay, String action = 'Повернути', double bottom = 24, bool bar = true}) {
  final o = overlay ?? Overlay.of(context);
  late OverlayEntry oe;
  var gone = false;
  void close() {
    if (gone) return;
    gone = true;
    oe.remove();
  }

  oe = OverlayEntry(
    builder: (_) => Positioned(
      left: 16, right: 16, bottom: bottom,
      child: Rise(
        dy: 30,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: K.star,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(children: [
                    Expanded(child: Text(text, style: rw(14, color: K.bg, w: FontWeight.w600))),
                    Press(
                      onTap: () async {
                        close();
                        await undo();
                      },
                      child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center, decoration: BoxDecoration(color: K.bg, borderRadius: BorderRadius.circular(999)), child: Text(action, style: rw(13, w: FontWeight.w700))),
                    ),
                  ]),
                ),
                if (bar) TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(seconds: 5),
                  onEnd: close,
                  builder: (_, v, __) => Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: v, child: Container(height: 3, color: K.acc))),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
  o.insert(oe);
}

// ---------- «Фото» людини ----------
/// Розмиті градієнтні «фото» людей з макета (поки нема справжніх фото).
/// Кожен шар = CSS radial-gradient(circle at x y, колір, transparent stop).
class BlobLayer {
  final double x, y, stop;
  final Color c;
  const BlobLayer(this.x, this.y, this.c, this.stop);
}

class BlobPal {
  final Color base;
  final List<BlobLayer> layers;
  const BlobPal(this.base, this.layers);
}

const blobPals = <BlobPal>[
  // Архітектор
  BlobPal(Color(0xFFC9796E), [BlobLayer(.7, .75, Color(0xFF7A6E8F), .6), BlobLayer(.3, .3, Color(0xFFF3B49C), .55)]),
  // Марк
  BlobPal(Color(0xFF6E6382), [BlobLayer(.25, .8, Color(0xFF3E3950), .6), BlobLayer(.6, .3, Color(0xFFB9B4CB), .5)]),
  // Д.
  BlobPal(Color(0xFF5E5674), [BlobLayer(.8, .2, Color(0xFFF08A6C), .45), BlobLayer(.4, .6, Color(0xFFE8D9D6), .5)]),
  // Бариста
  BlobPal(Color(0xFF6B6577), [BlobLayer(.75, .75, Color(0xFF3E3950), .6), BlobLayer(.35, .35, Color(0xFFD8CFC4), .5)]),
  // Олег
  BlobPal(Color(0xFF4E4760), [BlobLayer(.6, .4, Color(0xFFC9B8D6), .5)]),
];

class _BlobPainter extends CustomPainter {
  final BlobPal p;
  _BlobPainter(this.p);
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(r, Paint()..color = p.base);
    for (final l in p.layers) {
      final c = Offset(s.width * l.x, s.height * l.y);
      final dx = (l.x > .5 ? l.x : 1 - l.x) * s.width, dy = (l.y > .5 ? l.y : 1 - l.y) * s.height;
      final rad = Offset(dx, dy).distance; // farthest-corner
      canvas.drawRect(r, Paint()..shader = RadialGradient(colors: [l.c, l.c.withValues(alpha: 0)], stops: [0, l.stop]).createShader(Rect.fromCircle(center: c, radius: rad)));
    }
  }

  @override
  bool shouldRepaint(_BlobPainter o) => o.p != p;
}

/// Розмите «фото»: прямокутник/коло з радіусом [radius], розмиття як backdrop-filter:blur(8px)
class Blob extends StatelessWidget {
  final int seed;
  final double w, h, radius, blur;
  final bool circle, grey;
  const Blob({super.key, required this.seed, required this.w, required this.h, this.radius = 20, this.blur = 4, this.circle = false, this.grey = false});
  @override
  Widget build(BuildContext context) {
    Widget x = CustomPaint(size: Size(w, h), painter: _BlobPainter(blobPals[seed.abs() % blobPals.length]));
    if (blur > 0) x = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.mirror), child: x);
    if (grey) {
      x = ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[
        .5346, .4058, .0596, 0, 0, .1846, .7558, .0596, 0, 0, .1846, .4058, .4096, 0, 0, 0, 0, 0, 1, 0, // grayscale(.65)
      ]), child: ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[.85, 0, 0, 0, 0, 0, .85, 0, 0, 0, 0, 0, .85, 0, 0, 0, 0, 0, 1, 0]), child: x));
    }
    return SizedBox(
      width: w, height: h,
      child: circle ? ClipOval(child: x) : ClipRRect(borderRadius: BorderRadius.circular(radius), child: x),
    );
  }
}
