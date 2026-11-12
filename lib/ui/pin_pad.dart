import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin.dart';
import 'theme.dart';

const pinLength = 4;

class Logo extends StatelessWidget {
  final double size;
  final Color color;
  const Logo({super.key, this.size = 34, this.color = C.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('vesp', style: T.serif(size, color)),
        Container(
          width: size * 0.18, height: size * 0.18,
          margin: EdgeInsets.fromLTRB(size * 0.08, size * 0.12, size * 0.08, 0),
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.accent, boxShadow: [BoxShadow(color: C.accent.withValues(alpha: 0.7), blurRadius: 10)]),
        ),
        Text('r', style: T.serif(size, color)),
      ]);
}

class PinDots extends StatelessWidget {
  final int n;
  final bool error;
  const PinDots({super.key, required this.n, this.error = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < pinLength; i++)
            Container(
              width: 14, height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < n ? (error ? C.red : C.accent) : Colors.transparent,
                border: Border.all(color: error ? C.red : (i < n ? C.accent : C.line2), width: 1.5),
              ),
            ),
        ]),
      );
}

class PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final String? extraLabel;
  final VoidCallback? onExtra;
  const PinPad({super.key, required this.onDigit, required this.onDelete, this.extraLabel, this.onExtra});

  Widget _key(String label, VoidCallback onTap, {String? a11y, IconData? icon}) => Semantics(
        button: true,
        label: a11y ?? label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () { HapticFeedback.lightImpact(); onTap(); },
          child: Container(
            width: 76, height: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0AF1EEF2)),
            child: icon != null ? Icon(icon, color: C.text) : Text(label, style: label.length > 1 ? T.body(12, C.text, FontWeight.w500) : T.serif(28)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> xs) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [xs[0], const SizedBox(width: 22), xs[1], const SizedBox(width: 22), xs[2]]));
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final r in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']]) row([for (final k in r) _key(k, () => onDigit(k))]),
      row([
        extraLabel != null && onExtra != null ? _key(extraLabel!, onExtra!) : const SizedBox(width: 76),
        _key('0', () => onDigit('0')),
        _key('', onDelete, a11y: 'Стерти', icon: Icons.backspace_outlined),
      ]),
    ]);
  }
}

/// Введення PIN: перевірка існуючого або створення нового (двічі)
class PinEntry extends StatefulWidget {
  final bool create;
  final String? createHint;
  final VoidCallback onDone;
  const PinEntry({super.key, required this.create, required this.onDone, this.createHint});
  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  String code = '';
  String? first;
  bool error = false;
  bool bio = false;

  @override
  void initState() {
    super.initState();
    if (!widget.create) _tryBio();
  }

  Future<void> _tryBio() async {
    if (await PinService.biometricAvailable()) {
      if (!mounted) return;
      setState(() => bio = true);
      if (await PinService.biometricUnlock()) widget.onDone();
    }
  }

  Future<void> _add(String d) async {
    if (code.length >= pinLength) return;
    final c = code + d;
    setState(() { code = c; error = false; });
    if (c.length < pinLength) return;
    if (!widget.create) {
      if (await PinService.check(c)) {
        widget.onDone();
      } else {
        HapticFeedback.heavyImpact();
        setState(() => error = true);
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) setState(() => code = '');
      }
      return;
    }
    if (first == null) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) setState(() { first = c; code = ''; });
    } else if (first == c) {
      await PinService.setPin(c);
      widget.onDone();
    } else {
      setState(() { error = true; first = null; });
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) setState(() => code = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.create ? (first == null ? 'Придумай PIN' : 'Повтори PIN') : 'Введи PIN';
    final sub = widget.create
        ? (error ? 'PIN не збігся, спробуй ще' : (widget.createHint ?? '4 цифри. Знатимеш тільки ти.'))
        : (error ? 'Неправильний PIN' : ' ');
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: T.serif(28)),
      const SizedBox(height: 6),
      SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(sub, textAlign: TextAlign.center, style: T.body(13, error ? C.red : C.muted)),
        ),
      ),
      PinDots(n: code.length, error: error),
      PinPad(
        onDigit: _add,
        onDelete: () => setState(() => code = code.isEmpty ? code : code.substring(0, code.length - 1)),
        extraLabel: bio && !widget.create ? 'Відбиток' : null,
        onExtra: () async { if (await PinService.biometricUnlock()) widget.onDone(); },
      ),
    ]);
  }
}
