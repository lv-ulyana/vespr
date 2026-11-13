import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/wrapped_layers.dart';

/// Анімації слайдів Wrapped — ті самі keyframes, що в макеті:
/// wrStc / wrPop (стікер вискакує з обертом), wrUp / wrRise / wrNtf (виїжджає знизу),
/// wrSpinIn (закручується), wrGrow / wrGrowX (стовпчик росте), wrDraw (каракуля малюється),
/// wrTw (іскра мерехтить), wrWob (пляма гойдається), wrBob / wrFloat (стікер пливе), wrMarq (біжуча стрічка).

const _ease = Cubic(.2, .8, .2, 1);
double _deg(double d) => d * math.pi / 180;
double _lerp(double a, double b, double t) => a + (b - a) * t;

class WAnim extends StatefulWidget {
  final String anim;
  final int delay, dur;
  final bool loop;
  final Offset? origin; // центр обертання відносно віджета
  final Widget child;
  const WAnim(this.anim, {super.key, this.delay = 0, this.dur = 700, this.loop = false, this.origin, required this.child});
  @override
  State<WAnim> createState() => _WAnimState();
}

class _WAnimState extends State<WAnim> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.dur <= 0 ? 700 : widget.dur));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      c.value = widget.loop ? 0 : 1;
      return;
    }
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (!mounted) return;
      widget.loop ? c.repeat() : c.forward();
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: c, builder: (_, child) => _frame(c.value, child!), child: widget.child);

  Widget _frame(double v, Widget child) {
    final o = widget.origin;
    Widget tf(Matrix4 m, double op) {
      Widget w = Transform(transform: m, origin: o, alignment: o == null ? Alignment.center : null, child: child);
      if (op < 1) w = Opacity(opacity: op.clamp(0.0, 1.0), child: w);
      return w;
    }

    switch (widget.anim) {
      case 'wrStc':
      case 'wrPop':
      case 'vpop':
        final e = _ease.transform(v);
        final rot0 = widget.anim == 'wrPop' ? -22.0 : -25.0;
        final peak = widget.anim == 'wrPop' ? 12.0 : 0.0;
        double s, r, op;
        if (e < .7) {
          final k = e / .7;
          s = _lerp(.3, 1.08, k);
          r = _lerp(rot0, peak, k);
          op = k;
        } else {
          final k = (e - .7) / .3;
          s = _lerp(1.08, 1, k);
          r = _lerp(peak, 0, k);
          op = 1;
        }
        return tf(Matrix4.identity()
          ..rotateZ(_deg(r))
          ..scale(s, s), op);
      case 'wrUp':
      case 'vrise':
      case 'wrRise':
        final e = _ease.transform(v);
        final d = widget.anim == 'wrRise' ? 40.0 : (widget.anim == 'vrise' ? 14.0 : 26.0);
        return tf(Matrix4.translationValues(0, d * (1 - e), 0), e);
      case 'wrNtf':
        final e = _ease.transform(v);
        final s = _lerp(.9, 1, e);
        return tf(Matrix4.translationValues(0, -14 * (1 - e), 0)..scale(s, s), e);
      case 'wrSpinIn':
        final e = _ease.transform(v);
        final s = _lerp(.6, 1, e);
        return tf(Matrix4.identity()
          ..rotateZ(_deg(-120 * (1 - e)))
          ..scale(s, s), e);
      case 'wrGrow':
        final e = _ease.transform(v);
        return Transform(transform: Matrix4.diagonal3Values(1, e, 1), alignment: Alignment.bottomCenter, child: child);
      case 'wrGrowX':
        final e = _ease.transform(v);
        return Transform(transform: Matrix4.diagonal3Values(e, 1, 1), alignment: Alignment.centerLeft, child: child);
      case 'wrGrowXR':
        final e = _ease.transform(v);
        return Transform(transform: Matrix4.diagonal3Values(e, 1, 1), alignment: Alignment.centerRight, child: child);
      case 'wrDraw':
        final e = const Cubic(.6, .1, .2, 1).transform(v);
        return ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: e.clamp(0.001, 1.0), child: child));
      case 'wrTw':
        final k = math.sin(v * math.pi); // 0 → 1 → 0
        final s = _lerp(.55, 1, k);
        return tf(Matrix4.identity()
          ..rotateZ(_deg(45 * k))
          ..scale(s, s), _lerp(.25, 1, k));
      case 'wrWob':
        final k = (1 - math.cos(v * 2 * math.pi)) / 2;
        final s = _lerp(1, 1.05, k);
        return tf(Matrix4.identity()
          ..rotateZ(_deg(9 * k))
          ..scale(s, s), 1);
      case 'wrBob':
      case 'wrFloat':
        final k = (1 - math.cos(v * 2 * math.pi)) / 2;
        final dy = widget.anim == 'wrBob' ? -8.0 : -12.0;
        final dr = widget.anim == 'wrBob' ? 12.0 : 6.0;
        return tf(Matrix4.translationValues(0, dy * k, 0)..rotateZ(_deg(dr * k)), 1);
      case 'wrSpin':
        return tf(Matrix4.rotationZ(v * 2 * math.pi), 1);
      default:
        return child;
    }
  }
}

/// Анімовані шари слайда, вирізані з макета
List<Widget> wrappedLayers(int slide) => [
      for (final l in wLayers[slide] ?? const <WL>[])
        Positioned(
          left: l.x, top: l.y, width: l.w, height: l.h,
          child: WAnim(
            l.anim,
            delay: l.delay,
            dur: l.dur,
            loop: l.loop,
            origin: Offset(l.ox - l.x, l.oy - l.y),
            child: Image.asset('assets/wrapped/${l.file}', fit: BoxFit.fill, gaplessPlayback: true),
          ),
        ),
    ];

/// Біжучий рядок для стрічок-скотчу
class WMarquee extends StatefulWidget {
  final Widget child;
  final double width; // ширина одного повтору
  final int seconds;
  final bool reverse;
  const WMarquee({super.key, required this.child, required this.width, this.seconds = 18, this.reverse = false});
  @override
  State<WMarquee> createState() => _WMarqueeState();
}

class _WMarqueeState extends State<WMarquee> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false) && !c.isAnimating) c.repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, child) {
          final v = widget.reverse ? 1 - c.value : c.value;
          return Transform.translate(offset: Offset(-widget.width * v, 0), child: child);
        },
        child: widget.child,
      );
}
