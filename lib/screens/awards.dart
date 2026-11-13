// «Нагороди»: перенесено з дошок Achievements і AchievementCard.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../logic/achievements.dart';
import '../logic/dates.dart';
import '../ui/d.dart';

/// Дата першого відкриття рівня: зберігаємо в лічильниках як РРРРММДД
String _gotKey(Ach a) => 'got:${a.d.id}:${a.lv}';

String _dateOf(int? ymd) {
  if (ymd == null) return 'сьогодні';
  final m = (ymd ~/ 100) % 100, d = ymd % 100;
  const short = ['січ', 'лют', 'бер', 'квіт', 'трав', 'черв', 'лип', 'серп', 'вер', 'жовт', 'лист', 'груд'];
  return '$d ${short[m - 1]}';
}

class AwardsTab extends StatefulWidget {
  const AwardsTab({super.key});
  @override
  State<AwardsTab> createState() => _AwardsTabState();
}

class _AwardsTabState extends State<AwardsTab> {
  bool _saving = false;

  /// Запам'ятати дату для щойно відкритих рівнів
  void _stamp(AppStore s, List<Ach> all) {
    if (_saving) return;
    final miss = all.where((a) => a.earned && !s.profile.counters.containsKey(_gotKey(a))).toList();
    if (miss.isEmpty) return;
    _saving = true;
    final n = DateTime.now();
    final ymd = n.year * 10000 + n.month * 100 + n.day;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await s.updateProfile((p) {
        for (final a in miss) {
          p.counters[_gotKey(a)] = ymd;
        }
      });
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final all = computeAchievements(s.db);
    _stamp(s, all);
    final nOpen = all.where((a) => a.earned).length;
    return Stack(children: [
      const Positioned(left: -60, top: -60, child: EGlow(w: 520, h: 420, colors: [Color(0x1FF08A6C), Color(0x0017161F)], stops: [0, .65])),
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Rise(child: Text('Нагороди', style: pr(36, h: 1))),
            const SizedBox(height: 20),
            Rise(
              delay: .05,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text('$nOpen', style: pr(56, h: 1, color: K.accSoft, ls: -.02)),
                  const SizedBox(width: 8),
                  Text('/ ${all.length}', style: pr(24, h: 1, color: const Color(0xFF6F6985))),
                ]),
                const SizedBox(height: 8),
                Text('нагород відкрито', style: rw(13, color: K.soft2, ls: .26)),
                const SizedBox(height: 12),
                Container(
                  width: 180, height: 4,
                  decoration: BoxDecoration(color: K.w(.08), borderRadius: BorderRadius.circular(2)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: nOpen / all.length,
                    child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(colors: [Color(0xFFF6A890), K.acc]))),
                  ),
                ),
                const SizedBox(height: 8),
                Text(nOpen == all.length ? 'Відкрито все. Легенда.' : 'Ще ${all.length - nOpen} чекають на твої історії', style: rw(12, color: K.haze)),
              ]),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 16) / 3;
              return Wrap(spacing: 8, runSpacing: 22, children: [
                for (var i = 0; i < all.length; i++)
                  SizedBox(
                    width: w,
                    child: Rise(
                      delay: .1 + math.min(i, 9) * .04,
                      child: Press(
                        label: all[i].d.name,
                        onTap: () => _open(context, all[i]),
                        child: Column(children: [
                          _Medal(a: all[i], size: 92),
                          const SizedBox(height: 9),
                          SizedBox(
                            width: 100,
                            child: Text(all[i].d.name, textAlign: TextAlign.center, style: rw(12, w: FontWeight.w500, h: 1.3, color: all[i].earned ? const Color(0xFFE6E2EB) : K.haze)),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ]);
            }),
          ]),
        ),
      ),
    ]);
  }

  void _open(BuildContext context, Ach a) {
    final s = Store.read(context);
    final status = a.earned ? '${a.d.th.length > 1 ? 'Рівень ${a.lv} з ${a.d.th.length} · ' : ''}відкрито ${_dateOf(s.profile.counters[_gotKey(a)])}' : 'Ще не відкрито';
    showSheet(context, (ctx) => DFrame(
          bg: Colors.transparent,
          builder: (ctx, h) => Stack(children: [
            Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(ctx))),
            Positioned(
              left: 12, right: 12, bottom: 16,
              child: ConstrainedBox(constraints: BoxConstraints(maxHeight: h - 56), child: SingleChildScrollView(child: Container(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 14),
                decoration: BoxDecoration(
                  color: K.card2,
                  borderRadius: BorderRadius.circular(30),
                  border: Border(top: BorderSide(color: K.w(.09))),
                  boxShadow: const [BoxShadow(color: Color(0xCC09080E), blurRadius: 60, offset: Offset(0, -20), spreadRadius: -20)],
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(top: -22, left: 0, right: 0, child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: K.w(.18), borderRadius: BorderRadius.circular(2))))),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    _Medal(a: a, size: 132, sheet: true),
                    const SizedBox(height: 16),
                    Text(a.d.name, textAlign: TextAlign.center, style: pr(26, h: 1.15)),
                    const SizedBox(height: 10),
                    Text(status, style: rw(12, color: K.muted)),
                    const SizedBox(height: 10),
                    SizedBox(width: 290, child: Text(a.d.desc, textAlign: TextAlign.center, style: rw(14, color: K.soft, h: 1.5))),
                    if (!a.max) ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        Text(a.earned ? 'До рівня ${a.lv + 1}' : 'Прогрес', style: rw(12, color: K.muted)),
                        const Spacer(),
                        Text('${math.min(a.v, a.next)} з ${a.next}', style: rw(12)),
                      ]),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(color: K.w(.08), borderRadius: BorderRadius.circular(2)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (a.v / a.next).clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(colors: [Color(0xFFF6A890), K.acc]))),
                        ),
                      ),
                    ],
                    if (a.earned) ...[
                      const SizedBox(height: 18),
                      Press(
                        onTap: () async {
                          final t = 'Нова нагорода у Vespr: «${a.d.name}»${a.d.th.length > 1 ? ', рівень ${a.lv}' : ''}.';
                          Navigator.pop(ctx);
                          try {
                            await Share.share(t);
                          } catch (_) {
                            await Clipboard.setData(ClipboardData(text: t));
                            if (context.mounted) dToast(context, 'Скопійовано');
                          }
                        },
                        child: Container(height: 52, decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text('Поділитися', style: rw(15, color: K.bg, w: FontWeight.w600))),
                      ),
                    ],
                    Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, width: double.infinity, child: Center(child: Text('Закрити', style: rw(15, w: FontWeight.w600))))),
                  ]),
                ]),
              ))),
            ),
          ]),
        ));
  }
}

/// Медаль: кільце прогресу 3px, ілюстрація всередині, рівень у куточку
class _Medal extends StatelessWidget {
  final Ach a;
  final double size;
  final bool sheet;
  const _Medal({required this.a, required this.size, this.sheet = false});
  @override
  Widget build(BuildContext context) {
    final col = a.earned ? (a.d.shame ? K.red : K.acc) : (a.started ? K.green : Colors.transparent);
    final track = a.earned ? (a.d.shame ? K.red : K.acc).withValues(alpha: .28) : K.w(.08);
    final inset = size * (sheet ? 10 / 132 : 7 / 92);
    Widget img = Image.asset(a.started || a.earned ? a.img : 'assets/img/ach/unknown.webp', fit: BoxFit.cover);
    if (!a.earned && a.started) {
      img = Opacity(
        opacity: .8,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            .118, .395, .040, 0, -12, .118, .395, .040, 0, -12, .118, .395, .040, 0, -12, 0, 0, 0, 1, 0, // grayscale + brightness(.55)
          ]),
          child: img,
        ),
      );
    }
    return SizedBox(
      width: size, height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: a.started || a.earned ? a.frac : 0),
            duration: const Duration(milliseconds: 1100),
            curve: easeOut,
            builder: (_, f, __) => CustomPaint(painter: _RingP(f, col, track, sheet ? 2.5 * size / 92 : 3)),
          ),
        ),
        Positioned.fill(left: inset, top: inset, right: inset, bottom: inset, child: ClipOval(child: img)),
        if (a.earned && a.d.th.length > 1)
          Positioned(
            right: 0, top: 2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: a.d.shame ? K.red : K.acc, borderRadius: BorderRadius.circular(999), border: Border.all(color: sheet ? K.card2 : K.bg, width: 3)),
              alignment: Alignment.center,
              child: Text('${a.lv}', style: rw(11, color: K.bg, w: FontWeight.w700, h: 1)),
            ),
          ),
      ]),
    );
  }
}

class _RingP extends CustomPainter {
  final double f, sw;
  final Color c, track;
  _RingP(this.f, this.c, this.track, this.sw);
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2 * 43 / 46;
    final ctr = s.center(Offset.zero);
    canvas.drawCircle(ctr, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..color = track);
    if (f <= 0) return;
    canvas.drawArc(Rect.fromCircle(center: ctr, radius: r), -math.pi / 2, 2 * math.pi * f, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..color = c);
  }

  @override
  bool shouldRepaint(_RingP o) => o.f != f || o.c != c;
}

/// Рядок «найближча нагорода» для головної: (назва, прогрес 0–1, відкрито, усього)
({String? name, String? img, double frac, int open, int all}) awardsSummary(AppStore s) {
  final all = computeAchievements(s.db);
  final open = all.where((a) => a.earned).toList();
  final last = open.isEmpty ? null : open.reduce((x, y) => (s.profile.counters[_gotKey(x)] ?? 0) >= (s.profile.counters[_gotKey(y)] ?? 0) ? x : y);
  final near = nearestAch(all);
  final show = last ?? near;
  return (name: show?.d.name, img: show?.img, frac: open.length / all.length, open: open.length, all: all.length);
}

/// «Майже нагорода» для мапи
String? nearestAwardLine(AppStore s) {
  final a = nearestAch(computeAchievements(s.db));
  if (a == null) return null;
  final left = a.next - a.v;
  final u = a.d.unit;
  return u == null ? '«${a.d.name}»: ще $left до ${a.earned ? 'рівня ${a.lv + 1}' : 'відкриття'}' : '«${a.d.name}»: ще $left ${plural(left, u.$1, u.$2, u.$3)}';
}
