// PIN: створення (дошка «PinNew»), вхід (дошка «Pin») і «Забула PIN?» (дошка «PinForgot»).
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/pin.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'settings.dart' show DeleteAllScreen;

const _pinLen = 4;

/// Клавіатура з макета: кнопки 76, Prata 30, ряди через 16
class DKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? left;
  const DKeypad({super.key, required this.onDigit, required this.onDelete, this.left});

  Widget _key(String d) => Press(
        scale: .92,
        label: d,
        onTap: () => onDigit(d),
        child: Container(
          width: 76, height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(center: Alignment.topCenter, radius: 1.12, colors: [K.w(.08), K.w(.025)], stops: const [0, .7]),
            border: Border.all(color: K.w(.07)),
          ),
          child: Text(d, style: pr(30, ls: 0)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget w) => Expanded(child: Center(child: w));
    Widget row(List<Widget> xs) => Row(children: [for (final x in xs) cell(x)]);
    return Column(mainAxisSize: MainAxisSize.min, children: gapped([
      row([_key('1'), _key('2'), _key('3')]),
      row([_key('4'), _key('5'), _key('6')]),
      row([_key('7'), _key('8'), _key('9')]),
      row([
        left ?? const SizedBox(width: 76, height: 76),
        _key('0'),
        Press(scale: .92, label: 'Стерти', onTap: onDelete, child: SizedBox(width: 76, height: 76, child: Center(child: Ico(Svgs.del, size: 26)))),
      ]),
    ], 16));
  }
}

/// Крапки PIN (14, з світінням, коли заповнені)
class DDots extends StatelessWidget {
  final int n;
  final bool error;
  final bool all;
  const DDots(this.n, {super.key, this.error = false, this.all = false});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Введено цифр: $n з $_pinLen',
        child: Row(mainAxisSize: MainAxisSize.min, children: gapped([
          for (var i = 0; i < _pinLen; i++)
            AnimatedScale(
              scale: (i < n || all) && !error ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: easeOut,
                width: 14, height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: error ? const Color(0x40F28272) : (i < n || all ? K.acc : Colors.transparent),
                  border: Border.all(color: error ? K.red : (i < n || all ? K.acc : K.w(.35)), width: 1.5),
                  boxShadow: (i < n || all) && !error ? [BoxShadow(color: K.a(.6), blurRadius: 12)] : null,
                ),
              ),
            ),
        ], 18, horizontal: true)),
      );
}

/// Тремтіння при помилці
class Shake extends StatefulWidget {
  final Widget child;
  final int trigger;
  const Shake({super.key, required this.child, required this.trigger});
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (_, child) => Transform.translate(offset: Offset(math.sin(c.value * math.pi * 6) * 10 * (1 - c.value), 0), child: child),
      );
}

/// Значок замка в колі з світінням (.lk)
class LockBadge extends StatelessWidget {
  final double size;
  final String svg;
  const LockBadge({super.key, this.size = 56, String? svg}) : svg = svg ?? '';
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: const Alignment(0, -.4), colors: [K.a(.2), K.a(.06)]),
          border: Border.all(color: K.a(.3)),
          boxShadow: [BoxShadow(color: K.a(.25), blurRadius: 30)],
        ),
        alignment: Alignment.center,
        child: Ico(svg.isEmpty ? Svgs.lockDot : svg, size: size * .4, color: K.accSoft),
      );
}

// ---------- Новий PIN ----------
class PinNewScreen extends StatefulWidget {
  /// Що робити після збереження. Якщо null — повертаємось назад (зміна PIN з налаштувань).
  final void Function(BuildContext context)? onDone;
  final String doneLabel;
  const PinNewScreen({super.key, this.onDone, this.doneLabel = 'Відкрити Vespr'});
  @override
  State<PinNewScreen> createState() => _PinNewScreenState();
}

class _PinNewScreenState extends State<PinNewScreen> {
  String first = '', cur = '';
  int step = 1; // 1 придумай, 2 повтори, 3 готово
  bool mismatch = false;
  int shake = 0;

  Future<void> _digit(String d) async {
    if (step == 3 || cur.length >= _pinLen) return;
    setState(() { cur += d; mismatch = false; });
    if (cur.length < _pinLen) return;
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    if (step == 1) {
      setState(() { first = cur; cur = ''; step = 2; });
    } else if (cur == first) {
      await PinService.setPin(cur);
      if (!mounted) return;
      await Store.read(context).updateProfile((p) => p.pinEnabled = true);
      setState(() => step = 3);
    } else {
      setState(() { mismatch = true; shake++; cur = ''; first = ''; step = 1; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = step == 1 ? 'Придумай новий PIN' : step == 2 ? 'Повтори його' : 'Готово';
    final sub = mismatch ? 'Не збіглось. Придумай ще раз' : step == 3 ? 'Новий PIN збережено. Записи на місці.' : step == 2 ? "Ще раз, щоб точно запам'ятати" : '4 цифри, які знаєш тільки ти';
    return DFrame(minH: 640, 
      builder: (context, h) => Stack(children: [
        Positioned(left: -60, top: -80, child: EGlow(w: 510, h: 460, colors: [K.a(.16), const Color(0x0017161F)], stops: const [0, .7])),
        Positioned(left: 20, top: 58, child: Navigator.of(context).canPop() && step != 3 ? const BackBtn() : const SizedBox()),
        Positioned(
          left: 32, right: 32, top: 110,
          child: Column(children: [
            const LockBadge(),
            const SizedBox(height: 12),
            Row(mainAxisSize: MainAxisSize.min, children: gapped([
              for (final i in [1, 2])
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: easeD,
                  width: step != 3 && i == step ? 34 : 22, height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: step == 3 || i < step ? K.a(.5) : i == step ? K.acc : K.w(.14),
                    boxShadow: step != 3 && i == step ? [BoxShadow(color: K.a(.6), blurRadius: 8)] : null,
                  ),
                ),
            ], 6, horizontal: true)),
            const SizedBox(height: 16),
            Text(title, style: pr(30, h: 1.15), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(sub, style: rw(14, color: mismatch ? K.red : K.muted2, h: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 26),
            Shake(trigger: shake, child: DDots(cur.length, all: step == 3, error: mismatch)),
          ]),
        ),
        Positioned(
          left: 36, right: 36, bottom: 76,
          child: AnimatedOpacity(
            opacity: step == 3 ? .25 : 1,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(ignoring: step == 3, child: DKeypad(onDigit: _digit, onDelete: () => setState(() => cur = cur.isEmpty ? cur : cur.substring(0, cur.length - 1)))),
          ),
        ),
        if (step == 3)
          Positioned(
            left: 0, right: 0, bottom: 18,
            child: Center(
              child: Rise(
                child: Press(
                  onTap: () => widget.onDone != null ? widget.onDone!(context) : Navigator.of(context).pop(),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.fromLTRB(22, 0, 5, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const RadialGradient(center: Alignment.topLeft, radius: 1.6, colors: [Color(0xFFF6A890), K.acc], stops: [0, .6]),
                      boxShadow: [BoxShadow(color: K.a(.7), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -14)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.onDone == null ? 'Готово' : widget.doneLabel, style: rw(15, color: K.bg, w: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Container(width: 38, height: 38, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1F17161F)), alignment: Alignment.center, child: Ico(Svgs.arrowR, size: 14, color: K.bg)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ---------- Вхід за PIN ----------
class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const PinLockScreen({super.key, required this.onUnlock});
  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String cur = '';
  bool bio = false, error = false, opening = false;
  int shake = 0;

  @override
  void initState() {
    super.initState();
    PinService.biometricAvailable().then((v) {
      if (!mounted) return;
      setState(() => bio = v);
      if (v) _bio();
    });
  }

  Future<void> _bio() async {
    if (await PinService.biometricUnlock()) widget.onUnlock();
  }

  Future<void> _digit(String d) async {
    if (cur.length >= _pinLen || opening) return;
    setState(() { cur += d; error = false; });
    if (cur.length < _pinLen) return;
    setState(() => opening = true);
    final ok = await PinService.check(cur);
    if (!mounted) return;
    if (ok) {
      widget.onUnlock();
    } else {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() { error = true; shake++; cur = ''; opening = false; });
    }
  }

  @override
  Widget build(BuildContext context) => DFrame(minH: 640, 
        builder: (context, h) => Stack(children: [
          Positioned(left: -60, top: -80, child: EGlow(w: 510, h: 460, colors: [K.a(.2), const Color(0x128C86A3), const Color(0x0017161F)], stops: const [0, .45, .7])),
          starDot(60, 110, 2, K.star, .5),
          starDot(322, 160, 3, K.star, .4),
          starDot(300, 300, 2, K.acc, .7),
          Positioned(
            left: 0, right: 0, top: 120,
            child: Column(children: [
              Image.asset('assets/img/logo.webp', width: 140, semanticLabel: 'Vespr'),
              const SizedBox(height: 14),
              Text(error ? 'Не той PIN. Ще раз' : opening ? 'Відкриваємо…' : 'Введи PIN-код', style: rw(15, color: error ? K.red : K.muted)),
              const SizedBox(height: 30),
              Shake(trigger: shake, child: DDots(cur.length, error: error)),
            ]),
          ),
          Positioned(
            left: 36, right: 36, bottom: 76,
            child: DKeypad(
              onDigit: _digit,
              onDelete: () => setState(() => cur = cur.isEmpty ? cur : cur.substring(0, cur.length - 1)),
              left: bio ? Press(scale: .92, label: 'Face ID', onTap: _bio, child: SizedBox(width: 76, height: 76, child: Center(child: Ico(Svgs.faceId, size: 30, color: K.acc)))) : null,
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 18,
            child: Center(
              child: Press(
                onTap: () => showSheet(context, (_) => _ForgotSheet(onUnlock: widget.onUnlock, onReset: () => go(context, const DeleteAllScreen()))),
                child: SizedBox(height: 44, child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Text('Забула PIN?', style: rw(13, color: K.muted, w: FontWeight.w500))))),
              ),
            ),
          ),
        ]),
      );
}

/// «Забула PIN?»: увійти кодом телефону або стерти все
class _ForgotSheet extends StatelessWidget {
  final VoidCallback onUnlock, onReset;
  const _ForgotSheet({required this.onUnlock, required this.onReset});

  Widget _opt({required Widget icon, required String title, required String sub, Color titleColor = K.star, required VoidCallback onTap}) => Press(
        onTap: onTap,
        scale: .99,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: rw(15, color: titleColor, w: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(sub, style: rw(12, color: K.muted, h: 1.35)),
              ]),
            ),
            Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.w(.1))), alignment: Alignment.center, child: Ico(Svgs.chevR, size: 13, color: K.soft2)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Sheet(children: [
        Row(children: [
          LockBadge(size: 44, svg: Svgs.lockOpen),
          const SizedBox(width: 12),
          Text('Забула PIN?', style: pr(28, h: 1.15)),
        ]),
        Text(
          kIsWeb
              ? 'Записи живуть тільки в цьому браузері. Пошти й пароля у Vespr немає, тож PIN можна лише скинути разом із записами.'
              : 'Записи живуть на цьому телефоні. Пошти й пароля у Vespr немає, тож є два способи.',
          style: rw(14, color: K.soft, h: 1.5),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            color: K.hour,
            child: Column(children: [
              if (!kIsWeb)
                _opt(
                  icon: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const RadialGradient(center: Alignment.topLeft, radius: 1.6, colors: [Color(0xFFF6A890), K.acc], stops: [0, .6])),
                    alignment: Alignment.center,
                    child: Ico(Svgs.faceId, size: 20, color: K.bg),
                  ),
                  title: 'Увійти кодом телефону',
                  sub: 'Face ID, відбиток або код телефону, потім новий PIN',
                  onTap: () async {
                    final ok = await PinService.deviceUnlock();
                    if (!ok || !context.mounted) return;
                    Navigator.pop(context);
                    onUnlock();
                    appNav.currentState?.push(MaterialPageRoute(builder: (_) => const PinNewScreen()));
                  },
                ),
              if (!kIsWeb) Container(height: 1, color: K.w(.06)),
              _opt(
                icon: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x14D9544F), border: Border.all(color: const Color(0x59F28272))),
                  alignment: Alignment.center,
                  child: Ico(Svgs.trash, size: 18, color: K.red),
                ),
                title: 'Скинути PIN і все стерти',
                titleColor: K.red,
                sub: kIsWeb ? 'Записи в цьому браузері зникнуть назавжди' : 'Якщо і телефон не відкривається',
                onTap: () {
                  Navigator.pop(context);
                  onReset();
                },
              ),
            ]),
          ),
        ),
        Press(onTap: () => Navigator.pop(context), child: SizedBox(height: 52, child: Center(child: Text('Згадала, назад', style: rw(14, color: K.soft2, w: FontWeight.w600))))),
      ]);
}
