import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

void tapFx() => HapticFeedback.selectionClick();

Future<T?> go<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
Future<T?> goReplace<T>(BuildContext context, Widget page) => Navigator.of(context).pushReplacement<T, void>(MaterialPageRoute(builder: (_) => page));
void goRoot(BuildContext context, Widget page) =>
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (_) => false);

/// Екран: темний фон з теплим світінням, скрол, нижня панель з кнопками
class Screen extends StatelessWidget {
  final List<Widget> children;
  final List<Widget>? footer;
  final bool scroll;
  final EdgeInsets padding;
  const Screen({super.key, required this.children, this.footer, this.scroll = true, this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 32)});

  @override
  Widget build(BuildContext context) {
    final body = scroll
        ? ListView(padding: padding, keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, children: _gap(children))
        : Padding(padding: padding, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(children)));
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        Positioned(
          left: -120, top: -160,
          child: IgnorePointer(
            child: Container(width: 420, height: 340, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0BF08A6C))),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Expanded(child: body),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _gap(footer!, 8)),
              ),
          ]),
        ),
      ]),
    );
  }

  static List<Widget> _gap(List<Widget> xs, [double g = 14]) {
    final out = <Widget>[];
    for (var i = 0; i < xs.length; i++) {
      if (i > 0) out.add(SizedBox(height: g));
      out.add(xs[i]);
    }
    return out;
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  const RoundIcon({super.key, required this.icon, required this.label, required this.onTap, this.accent = false});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent ? C.accent : C.surface),
            child: Icon(icon, size: 20, color: accent ? C.bg : C.text),
          ),
        ),
      );
}

class Header extends StatelessWidget {
  final String? title;
  final bool back;
  final Widget? right;
  final VoidCallback? onBack;
  const Header({super.key, this.title, this.back = true, this.right, this.onBack});
  @override
  Widget build(BuildContext context) => Row(children: [
        back
            ? RoundIcon(icon: Icons.chevron_left_rounded, label: 'Назад', onTap: onBack ?? () => Navigator.of(context).maybePop())
            : const SizedBox(width: 44),
        Expanded(child: Text(title ?? '', textAlign: TextAlign.center, style: T.body(15, C.text, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        right ?? const SizedBox(width: 44),
      ]);
}

class H1 extends StatelessWidget {
  final String text;
  final String? accent;
  final double size;
  const H1(this.text, {super.key, this.accent, this.size = 34});
  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(text: text, children: [if (accent != null) TextSpan(text: '\n$accent', style: const TextStyle(color: C.accentSoft))]),
        style: T.serif(size),
      );
}

class Txt extends StatelessWidget {
  final String text;
  final bool muted, small;
  final Color? color;
  final int? lines;
  final TextAlign? align;
  const Txt(this.text, {super.key, this.muted = false, this.small = false, this.color, this.lines, this.align});
  @override
  Widget build(BuildContext context) => Text(text,
      maxLines: lines,
      overflow: lines == null ? null : TextOverflow.ellipsis,
      textAlign: align,
      style: T.body(small ? 12 : 14, color ?? (muted ? C.muted : C.text)));
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(text.toUpperCase(), style: T.label));
}

enum BtnKind { primary, ghost, danger, light }

class Btn extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final BtnKind kind;
  final IconData? icon;
  const Btn(this.title, {super.key, this.onTap, this.kind = BtnKind.primary, this.icon});
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final bg = disabled
        ? const Color(0x0FF1EEF2)
        : switch (kind) { BtnKind.primary => C.accent, BtnKind.danger => C.danger, BtnKind.light => C.text, BtnKind.ghost => const Color(0x0AF1EEF2) };
    final fg = disabled ? C.haze : (kind == BtnKind.primary || kind == BtnKind.light ? C.bg : C.text);
    return Semantics(
      button: true,
      enabled: !disabled,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: kind == BtnKind.ghost && !disabled ? const BorderSide(color: C.line2) : BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: disabled ? null : () { tapFx(); onTap!(); },
          child: SizedBox(
            height: 54,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
              Flexible(child: Text(title, style: T.body(16, fg, FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    );
  }
}

enum Tone { a, g, r }

class ChipX extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final Tone tone;
  const ChipX(this.label, {super.key, required this.on, this.onTap, this.tone = Tone.a});
  @override
  Widget build(BuildContext context) {
    final col = switch (tone) { Tone.g => C.green, Tone.r => C.red, Tone.a => C.accent };
    return Semantics(
      button: onTap != null,
      selected: on,
      child: GestureDetector(
        onTap: onTap == null ? null : () { tapFx(); onTap!(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: on ? col.withValues(alpha: 0.15) : const Color(0x06F1EEF2),
            border: Border.all(color: on ? col : C.line2),
          ),
          child: Text(label, style: T.body(13, on ? C.text : C.muted, on ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class Chips extends StatelessWidget {
  final List<Widget> children;
  const Chips(this.children, {super.key});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

class Rating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;
  final double size;
  const Rating({super.key, required this.value, required this.onChange, this.size = 40});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var n = 1; n <= 5; n++)
          Padding(
            padding: EdgeInsets.only(right: n < 5 ? 8 : 0),
            child: Semantics(
              button: true,
              label: 'Оцінка $n',
              selected: n <= value,
              child: GestureDetector(
                onTap: () { tapFx(); onChange(value == n ? 0 : n); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size, height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: n <= value ? C.accent : Colors.transparent, border: Border.all(color: n <= value ? C.accent : C.line2)),
                  child: Text('$n', style: T.serif(size * 0.42, n <= value ? C.bg : C.muted)),
                ),
              ),
            ),
          ),
      ]);
}

class SegOpt<V> {
  final V id;
  final String label;
  const SegOpt(this.id, this.label);
}

class Seg<V> extends StatelessWidget {
  final List<SegOpt<V>> options;
  final V? value;
  final ValueChanged<V> onChange;
  const Seg({super.key, required this.options, required this.value, required this.onChange});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: o.id == value,
                child: GestureDetector(
                  onTap: () { tapFx(); onChange(o.id); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: o.id == value ? C.text : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                    child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body(13, o.id == value ? C.bg : C.muted, FontWeight.w600)),
                  ),
                ),
              ),
            ),
        ]),
      );
}

class VCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color border;
  final EdgeInsets padding;
  const VCard({super.key, required this.child, this.onTap, this.color = C.card, this.border = C.line, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

class Field extends StatelessWidget {
  final String? label, hint;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int maxLines;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? formatters;
  const Field({super.key, this.label, this.hint, required this.controller, this.keyboard, this.maxLines = 1, this.obscure = false, this.onChanged, this.formatters});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label!, style: T.body(12, C.muted, FontWeight.w500))),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          obscureText: obscure,
          onChanged: onChanged,
          inputFormatters: formatters,
          style: T.body(16, C.text, FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: T.body(14, C.haze, FontWeight.w500),
            filled: true,
            fillColor: const Color(0x08F1EEF2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0x1AF1EEF2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: C.accent)),
          ),
        ),
      ]);
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool past;
  const Avatar(this.name, {super.key, this.size = 40, this.past = false});
  static const _bgs = [Color(0xFFC9796E), Color(0xFF6E6382), Color(0xFF5E5674), Color(0xFF8C6F7E)];
  @override
  Widget build(BuildContext context) {
    final h = name.codeUnits.fold<int>(0, (s, c) => s + c) % _bgs.length;
    final t = name.trim();
    return Opacity(
      opacity: past ? 0.6 : 1,
      child: Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _bgs[h]),
        child: Text(t.isEmpty ? '?' : t.substring(0, 1).toUpperCase(), style: T.serif(size * 0.42)),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SwitchRow({super.key, required this.title, this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: T.body(15, C.text, FontWeight.w500)),
                  if (sub != null) Text(sub!, style: T.body(12, C.muted)),
                ]),
              ),
              const SizedBox(width: 12),
              Switch(value: value, onChanged: onChanged, activeTrackColor: C.accent, inactiveTrackColor: C.surface),
            ]),
          ),
        ),
      );
}

class NavRow extends StatelessWidget {
  final String title;
  final String? sub, value;
  final VoidCallback onTap;
  final IconData? icon;
  const NavRow({super.key, required this.title, this.sub, this.value, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            if (icon != null) ...[
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0x0AF1EEF2), border: Border.all(color: C.line)),
                child: Icon(icon, size: 16, color: C.accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: T.body(15, C.text, FontWeight.w500)),
                if (sub != null) Text(sub!, style: T.body(12, C.muted)),
              ]),
            ),
            if (value != null) Text(value!, style: T.body(13, C.muted)),
            const Icon(Icons.chevron_right_rounded, color: C.haze),
          ]),
        ),
      );
}

class Big extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const Big(this.text, {super.key, this.size = 40, this.color = C.text});
  @override
  Widget build(BuildContext context) => Text(text, style: T.serif(size, color));
}

class StatTile extends StatelessWidget {
  final String label, value;
  final String? suffix;
  const StatTile(this.label, this.value, {super.key, this.suffix});
  @override
  Widget build(BuildContext context) => Expanded(
        child: VCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Txt(label, small: true, muted: true),
            Text.rich(TextSpan(text: value, children: [if (suffix != null) TextSpan(text: suffix, style: T.body(13, C.muted))]), style: T.serif(26)),
          ]),
        ),
      );
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, shape: const StadiumBorder()));
