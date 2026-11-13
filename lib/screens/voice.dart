// Голосовий запис (дошка Voice): говориш — бачиш розшифровку, прапорці підсвічуються,
// «Готово, перевірити» відкриває звичайну форму запису з нотаткою і вибраними прапорцями.
// Звук ніде не зберігається, лише текст. Розпізнавання — системне: на телефоні намагаємось
// без інтернету; коли так не виходить (і завжди в браузері) — питаємо дозволу один раз.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/catalog.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/triggers.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go, goReplace;
import 'entry.dart' show EntryForm, PAvatar;
import 'onboarding.dart' show AddPersonScreen;
import 'settings.dart' show PaywallKind, PaywallScreen;

const freeVoicePerMonth = 3;
const _icClose = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M6 6l12 12M18 6L6 18"/></svg>';
const _icMic = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>';
String _voiceKey() => 'voice:${today().substring(0, 7)}';

/// Відкрити голосовий запис з урахуванням ліміту безкоштовної версії
void openVoice(BuildContext context, {String? personId, String? date, bool before = false, bool replace = false}) {
  final nav = replace ? goReplace : go;
  final s = Store.read(context);
  if (s.people.where((p) => !p.isPast).isEmpty) {
    nav(context, const AddPersonScreen());
    return;
  }
  if (!s.profile.premium && (s.profile.counters[_voiceKey()] ?? 0) >= freeVoicePerMonth) {
    nav(context, const PaywallScreen(kind: PaywallKind.limit));
    return;
  }
  nav(context, VoiceScreen(personId: personId, date: date, before: before));
}

enum _St { init, listening, paused, needNet, noMic }

class VoiceScreen extends StatefulWidget {
  final String? personId, date;
  final bool before;
  /// Для тестів і прев'ю: готова розшифровка без мікрофона
  final String? demoText;
  const VoiceScreen({super.key, this.personId, this.date, this.before = false, this.demoText});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with SingleTickerProviderStateMixin {
  late bool before = widget.before;
  String personId = '';
  late String date;
  String done = '', live = '';
  final picked = <String>{};
  _St st = _St.init;
  int secs = 0;
  Timer? tick;
  SpeechToText? stt;
  bool tried = false; // уже пробували без інтернету
  late final wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  String get text => [done, live].where((x) => x.trim().isNotEmpty).join(' ').trim();

  @override
  void initState() {
    super.initState();
    final s = Store.read(context);
    final active = s.people.where((p) => !p.isPast).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final last = [...s.entries]..sort((a, b) => b.date.compareTo(a.date));
    personId = widget.personId ?? (last.isNotEmpty ? last.first.personId : (active.isNotEmpty ? active.first.id : ''));
    date = widget.date ?? today();
    if (widget.demoText != null) {
      done = widget.demoText!;
      st = _St.paused;
      secs = 18;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    tick?.cancel();
    wave.dispose();
    stt?.cancel();
    super.dispose();
  }

  bool get _net => (Store.read(context).profile.counters['opt:voiceNet'] ?? 0) == 1;

  Future<void> _start() async {
    if (!mounted) return;
    if (kIsWeb && !_net) {
      setState(() => st = _St.needNet);
      return;
    }
    try {
      stt ??= SpeechToText();
      final ok = await stt!.initialize(onError: _onError, onStatus: _onStatus);
      if (!ok) {
        if (mounted) setState(() => st = _St.noMic);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => st = _St.noMic);
      return;
    }
    await _listen();
  }

  Future<String> _locale() async {
    try {
      final ls = await stt!.locales();
      final uk = ls.where((l) => l.localeId.toLowerCase().startsWith('uk')).firstOrNull;
      if (uk != null) return uk.localeId;
    } catch (_) {}
    return kIsWeb ? 'uk-UA' : 'uk_UA';
  }

  Future<void> _listen() async {
    if (!mounted || stt == null) return;
    final loc = await _locale();
    final onDevice = !kIsWeb && !_net;
    tried = tried || onDevice;
    setState(() => st = _St.listening);
    wave.repeat();
    tick?.cancel();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && st == _St.listening) setState(() => secs++);
    });
    try {
      await stt!.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            live = r.recognizedWords;
            if (r.finalResult) _commit();
          });
        },
        localeId: loc,
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 10),
        listenOptions: SpeechListenOptions(onDevice: onDevice, partialResults: true, listenMode: ListenMode.dictation, cancelOnError: true),
      );
    } catch (_) {
      _toPaused();
    }
  }

  void _commit() {
    if (live.trim().isNotEmpty) done = [done, live].where((x) => x.trim().isNotEmpty).join(' ').trim();
    live = '';
  }

  void _toPaused() {
    tick?.cancel();
    wave.stop();
    if (!mounted) return;
    setState(() {
      _commit();
      if (st == _St.listening) st = _St.paused;
    });
  }

  void _onStatus(String s) {
    if ((s == 'notListening' || s == 'done') && st == _St.listening) _toPaused();
  }

  void _onError(SpeechRecognitionError e) {
    final m = e.errorMsg.toLowerCase();
    tick?.cancel();
    wave.stop();
    if (!mounted) return;
    setState(() {
      _commit();
      if (m.contains('permission') || m.contains('not-allowed') || m.contains('not_allowed')) {
        st = _St.noMic;
      } else if (!kIsWeb && !_net && (m.contains('language') || m.contains('device') || m.contains('not_supported') || m.contains('unavailable'))) {
        // без інтернету українську розпізнати не вийшло — питаємо, чи можна через систему
        st = _St.needNet;
      } else {
        st = _St.paused;
      }
    });
  }

  Future<void> _allowNet() async {
    await Store.read(context).updateProfile((p) => p.counters['opt:voiceNet'] = 1);
    if (!mounted) return;
    setState(() => st = _St.init);
    if (stt == null) {
      await _start();
    } else {
      await _listen();
    }
  }

  Future<void> _toggle() async {
    if (st == _St.listening) {
      await stt?.stop();
      _toPaused();
    } else if (st == _St.paused) {
      await _listen();
    }
  }

  Future<void> _finish() async {
    if (st == _St.listening) await stt?.stop();
    _toPaused();
    final t = text;
    final s = Store.read(context);
    if (t.isNotEmpty && widget.demoText == null) await s.updateProfile((p) => p.counters[_voiceKey()] = (p.counters[_voiceKey()] ?? 0) + 1);
    if (!mounted) return;
    if (before) {
      if (t.isNotEmpty) {
        final d = parseIso(today());
        await s.updatePerson(personId, (p) => p.notes = [p.notes.trim(), '${d.day} ${monthsGen[d.month - 1]}, до зустрічі: $t'].where((x) => x.isNotEmpty).join('\n'));
        if (mounted) dToast(context, 'Додано в нотатки');
      }
      if (mounted) Navigator.pop(context);
    } else {
      goReplace(context, EntryForm(personId: personId, date: date, note: t.isEmpty ? null : t, flags: picked.toList()));
    }
  }

  void _taps() => goReplace(context, EntryForm(personId: personId, date: date));

  void _pickWho() {
    final s = Store.read(context);
    final active = s.people.where((p) => !p.isPast).toList();
    showSheet(context, (ctx) => Sheet(children: [
          Text('З ким', style: pr(24, h: 1.1)),
          for (final p in active)
            Press(
              onTap: () {
                setState(() => personId = p.id);
                Navigator.pop(ctx);
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: p.id == personId ? K.w(.06) : K.w(.025), border: Border.all(color: p.id == personId ? K.acc : K.w(.07))),
                child: Row(children: [PAvatar(size: 32, pid: p.id), const SizedBox(width: 12), Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(15, w: FontWeight.w500)))]),
              ),
            ),
        ]));
  }

  // ---------- верстка ----------
  Widget _seg(String label, bool on, VoidCallback onTap) => Press(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: easeD,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: on ? K.star : Colors.transparent),
          child: Text(label, style: rw(14, color: on ? K.bg : K.muted2, w: FontWeight.w500)),
        ),
      );

  Widget _ring() => SizedBox(
        width: 220, height: 220,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: -30, top: -30, right: -30, bottom: -30,
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [K.a(st == _St.listening ? .35 : .18), K.a(0)], stops: const [0, .92]))),
          ),
          Positioned.fill(child: CustomPaint(painter: _RingPainter())),
          Center(
            child: AnimatedBuilder(
              animation: wave,
              builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                for (final (i, h) in const [22.0, 40.0, 58.0, 34.0, 50.0, 26.0, 44.0, 20.0].indexed)
                  Container(
                    width: 3,
                    height: h * (st == _St.listening ? .4 + .6 * (.5 - .5 * math.cos(2 * math.pi * ((wave.value - i * .125) % 1))) : .4),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: st == _St.listening ? K.star : K.w(.45), borderRadius: BorderRadius.circular(2)),
                  ),
              ]),
            ),
          ),
        ]),
      );

  /// Розшифровка з підкресленими прапорцями
  Widget _transcript(List<FlagHit> hits) {
    final t = text;
    final base = rw(14, color: K.soft, h: 1.55);
    if (t.isEmpty) {
      return Text(st == _St.listening ? 'Слухаю…' : 'Тут з’явиться текст.', style: base.copyWith(color: K.haze));
    }
    final spans = <InlineSpan>[];
    var at = 0;
    for (final h in hits) {
      if (h.start > at) spans.add(TextSpan(text: t.substring(at, h.start)));
      final neg = flagById(h.flagId)?.kind != FlagKind.g;
      // підкреслення з відступом: сам текст малюємо тінню вище, а лінія лишається під ним
      spans.add(TextSpan(
        text: t.substring(h.start, h.end),
        style: base.copyWith(
          color: Colors.transparent,
          shadows: const [Shadow(color: K.star, offset: Offset(0, -3))],
          decoration: TextDecoration.underline,
          decorationColor: neg ? const Color(0xFFE0524C) : K.green.withValues(alpha: .7),
          decorationThickness: 1.5,
        ),
      ));
      at = h.end;
    }
    if (at < t.length) spans.add(TextSpan(text: t.substring(at)));
    if (live.isNotEmpty) spans.add(TextSpan(text: ' …', style: base.copyWith(color: K.haze)));
    return Text.rich(TextSpan(style: base, children: spans));
  }

  Widget _chip(String id) {
    final f = flagById(id);
    if (f == null) return const SizedBox.shrink();
    final on = picked.contains(id), neg = f.kind != FlagKind.g;
    return Press(
      onTap: () => setState(() => on ? picked.remove(id) : picked.add(id)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: easeD,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: neg && on ? K.acc : null,
          gradient: neg && on
              ? null
              : RadialGradient(center: Alignment.topLeft, radius: 1.6, colors: [on ? K.green.withValues(alpha: .2) : (neg ? K.a(.16) : K.w(.03)), on ? K.green.withValues(alpha: 0) : (neg ? K.a(0) : K.w(.03))], stops: const [0, .6]),
          border: Border.all(color: neg && on ? Colors.transparent : (on ? K.green.withValues(alpha: .45) : (neg ? K.a(.35) : K.w(.1)))),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(f.label, style: rw(13, color: neg && on ? K.bg : (on ? K.star : const Color(0xFFD7D3E0)), w: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _card() {
    final t = text;
    final hits = flagHits(t);
    final sugg = <String>[];
    for (final h in hits) {
      if (!sugg.contains(h.flagId)) sugg.add(h.flagId);
    }
    final kids = <Widget>[];
    if (st == _St.needNet || st == _St.noMic) {
      final mic = st == _St.noMic;
      kids.addAll([
        Text(mic ? 'Мікрофон недоступний' : 'Розпізнавання мови', style: rw(15, w: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
          mic
              ? 'Дозволь Vespr мікрофон у налаштуваннях телефону або браузера. Або заповни запис тапами, це теж хвилина.'
              : kIsWeb
                  ? 'У браузері мову розпізнає Google або Apple: звук іде на їхні сервери, назад приходить текст. Vespr зберігає тільки текст, сам звук ніде не лишається.'
                  : 'Без інтернету цей телефон українську не розпізнає. Можна через Apple чи Google: звук піде на їхні сервери, назад прийде текст. Vespr зберігає тільки текст.',
          style: rw(13, color: K.soft, h: 1.5),
        ),
        const SizedBox(height: 14),
        if (!mic) ...[Cta('Добре, розпізнавати', onTap: _allowNet), const SizedBox(height: 4)],
        Press(onTap: _taps, child: SizedBox(height: 44, child: Center(child: Text('Заповнити тапами', style: rw(14, color: mic ? K.star : K.muted, w: FontWeight.w600))))),
      ]);
    } else {
      kids.addAll([
        Row(children: [
          Text('Розшифровка', style: rw(15, w: FontWeight.w600)),
          const Spacer(),
          Text(before ? 'додасться в нотатки' : 'збережеться як нотатка', style: rw(12, color: K.muted2)),
        ]),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height < 760 ? 88 : 132),
          child: SingleChildScrollView(reverse: true, child: SizedBox(width: double.infinity, child: _transcript(hits))),
        ),
        if (!before && sugg.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Знайшли прапорці. Додати?', style: rw(12, color: K.muted, w: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final id in sugg) _chip(id)]),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Press(
            label: st == _St.listening ? 'Пауза' : 'Продовжити',
            onTap: st == _St.init ? null : _toggle,
            child: Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: K.bg),
              alignment: Alignment.center,
              child: st == _St.listening
                  ? Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 2; i++) Container(width: 4, height: 14, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(1)))])
                  : const Ico(_icMic, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Cta(before ? 'Готово' : 'Готово, перевірити', onTap: _finish)),
        ]),
      ]);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: K.card2,
        borderRadius: BorderRadius.circular(32),
        border: Border(top: BorderSide(color: K.w(.09))),
        boxShadow: const [BoxShadow(color: Color(0xCC09080E), blurRadius: 60, offset: Offset(0, -20), spreadRadius: -20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: kids),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.person(personId);
    final mm = secs ~/ 60, ss = secs % 60;
    return DFrame(
      builder: (context, h) => Stack(children: [
        // фон: сяйво і зірки
        const Positioned(left: -40, top: 60, width: 470, height: 470, child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x388C86A3), Color(0x0017161F)], stops: [0, .92])))),
        starDot(52, 210, 2, K.star, .5),
        starDot(330, 170, 3, K.star, .4),
        starDot(300, 420, 2, K.acc, .8),
        starDot(80, 400, 2, K.star, .3),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 58, 12, 12),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  IconBtn(svg: _icClose, label: 'Закрити', onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: K.w(.04), border: Border.all(color: K.w(.07))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _seg('До зустрічі', before, () => setState(() => before = true)),
                      _seg('Після', !before, () => setState(() => before = false)),
                    ]),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ]),
              ),
              const SizedBox(height: 26),
              Press(
                label: 'Змінити людину',
                onTap: _pickWho,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xCC2B2836)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    PAvatar(size: 22, pid: personId),
                    const SizedBox(width: 8),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Text(p?.name ?? 'Хто він?', maxLines: 1, overflow: TextOverflow.ellipsis, style: rw(13))),
                    const SizedBox(width: 6),
                    const Ico('<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M6 9l6 6 6-6"/></svg>', size: 11, color: K.muted),
                  ]),
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final timer = Text('$mm:${ss.toString().padLeft(2, '0')}', style: pr(34, ls: .02, h: 1.2));
                  final hint = Text(before ? 'Що чекаєш від зустрічі? Ми запишемо текстом.' : 'Говори як подрузі. Ми запишемо текстом.', textAlign: TextAlign.center, style: rw(12, color: K.muted2));
                  // як на дошці: кільце за 26 px під людиною, під ним таймер (разом ~295 px);
                  // коли розшифровка довга і місця мало — кільце менше, а зовсім мало — тільки таймер
                  final k = (c.maxHeight - 34) / 295;
                  if (k < .6) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [timer, if (c.maxHeight > 90) ...[const SizedBox(height: 4), hint]]));
                  }
                  return Align(
                    alignment: k >= 1 ? Alignment.topCenter : Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: k >= 1 ? 26 : 0),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Transform.scale(scale: math.min(1, k), child: SizedBox(width: 220, height: 220 * math.min(1, k), child: OverflowBox(maxHeight: 220, child: _ring()))),
                        SizedBox(height: 14 * math.min(1, k)),
                        timer,
                        const SizedBox(height: 4),
                        hint,
                      ]),
                    ),
                  );
                }),
              ),
              _card(),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Кільце з conic-gradient: F08A6C → 8C86A3 → прозоре → F08A6C
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 3.7;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.3
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: const GradientRotation(-math.pi / 2),
        colors: const [K.acc, Color(0xFF8C86A3), Color(0x1A8C86A3), K.acc],
        stops: const [0, .33, .66, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(_RingPainter o) => false;
}
