// «Люди»: перенесено з дошок Partners, PartnersEmpty, PartnersPast, Partner,
// PartnerNoDate, PersonActions, HallOfShame один в один.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../logic/stats.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
import 'entry.dart' show EntryForm, EntryView, PAvatar, entryTitle, seedOf;
import 'onboarding.dart' show AddPersonScreen;

// ---------- Іконки з дошок ----------
const _icSearch = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>';
const _icPlus = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>';
const _icPlusThin = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>';
const _icUpRight = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M7 17L17 7M9 7h8v8"/></svg>';
const _icArchive = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="5" rx="1.5"/><path d="M5 9v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9M10 13h4"/></svg>';
const _icTrash = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/></svg>';
const _icEye = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>';
const _icMore = '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>';
const _icPen = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 20h4L19 9l-4-4L4 16z"/></svg>';
const _icPen17 = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="M4 20h4L19 9l-4-4L4 16z"/></svg>';
const _icRings = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="9" cy="12" r="5.5"/><circle cx="15" cy="12" r="5.5"/></svg>';
const _icColumns = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><path d="M8 4v16M16 4v16M4 9h8M12 15h8"/></svg>';
const _icSpark = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z"/></svg>';
const _icFlagLine = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21V4M5 4h11l-2 4 2 4H5"/></svg>';
const _icLock = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>';
const _icFlagBadge = '<svg viewBox="0 0 30 38"><rect x="3" y="2" width="2.4" height="35" rx="1.2" fill="#E6E1EA"/><path d="M5 3C11 1 15 5 21 3s7 1 8 1v12c-2 0-4-2-8 0s-10-2-16 0z" fill="#F08A6C"/></svg>';
const _icCrownBadge = '<svg viewBox="0 0 34 28"><path d="M4 21L2 7.5l8 6L17 2l7 11.5 8-6L30 21z" fill="#EBBE7E"/><rect x="4" y="22" width="26" height="4" rx="1.6" fill="#EBBE7E"/></svg>';
const _icCrown = '<svg viewBox="0 0 34 28"><defs><linearGradient id="cg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FBE6BF"/><stop offset=".55" stop-color="#EBBE7E"/><stop offset="1" stop-color="#C98F55"/></linearGradient></defs><path d="M4 21L2 7.5l8 6L17 2l7 11.5 8-6L30 21z" fill="url(#cg)" stroke="#FFF1D6" stroke-opacity=".55" stroke-width=".8" stroke-linejoin="round"/><rect x="4" y="21.6" width="26" height="4" rx="1.6" fill="url(#cg)"/><circle cx="17" cy="16" r="1.9" fill="#F08A6C"/><circle cx="10.5" cy="17.4" r="1.2" fill="#9FCBA9"/><circle cx="23.5" cy="17.4" r="1.2" fill="#9FCBA9"/><circle cx="2" cy="7.5" r="1.4" fill="#FBE6BF"/><circle cx="17" cy="2" r="1.6" fill="#FBE6BF"/><circle cx="32" cy="7.5" r="1.4" fill="#FBE6BF"/></svg>';
const _icFlagPole = '<svg viewBox="0 0 30 38"><rect x="3" y="2" width="2" height="35" rx="1" fill="#E6E1EA"/><circle cx="4" cy="2.4" r="2.2" fill="#F1EEF2"/></svg>';
const _icFlagCloth = '<svg viewBox="0 0 24 16"><path d="M0 1C6-1 10 3 16 1s7 1 8 1v12c-2 0-4-2-8 0s-10-2-16 0z" fill="#F08A6C"/><path d="M0 1C6-1 10 3 16 1s7 1 8 1v3C20 5 18 3 16 4S6 2 0 4z" fill="#FFB49C" opacity=".55"/></svg>';

// ---------- Допоміжне ----------
const _glyphs = {
  'Овен': '♈', 'Телець': '♉', 'Близнюки': '♊', 'Рак': '♋', 'Лев': '♌', 'Діва': '♍',
  'Терези': '♎', 'Скорпіон': '♏', 'Стрілець': '♐', 'Козеріг': '♑', 'Водолій': '♒', 'Риби': '♓',
};
String glyphOf(String sign) => _glyphs[sign] ?? '✦';
const _symFonts = ['Apple Symbols', 'Segoe UI Symbol', 'Noto Sans Symbols 2', 'Noto Sans Symbols'];

const monthsShort = ['січ', 'лют', 'бер', 'квіт', 'трав', 'черв', 'лип', 'серп', 'вер', 'жовт', 'лист', 'груд'];

/// Короткі назви прапорців для «пігулок» (повні — у каталозі)
const _flagShort = {
  'flag_g_asks': 'Питав про межі', 'flag_g_no': 'Поважав «ні»', 'flag_g_walk': 'Провів', 'flag_g_listen': 'Слухав',
  'flag_g_remember': "Запам'ятав", 'flag_g_ontime': 'Вчасно', 'flag_g_paid': 'Заплатив', 'flag_g_gift': 'Квіти',
  'flag_g_condom': 'Подбав про захист', 'flag_g_texts': 'Написав після', 'flag_g_word': 'Тримав слово', 'flag_g_kind': 'Чемний',
  'flag_r_phone': 'Телефон', 'flag_r_self': 'Про себе', 'flag_r_late': 'Запізнився', 'flag_r_ex': 'Колишня',
  'flag_r_cheap': 'Копійки', 'flag_r_jab': 'Підколи', 'flag_r_drunk': "П'яний", 'flag_r_jealous': 'Ревнував',
  'flag_r_gone': 'Зник', 'flag_r_lie': 'Брехав', 'flag_r_push': 'Тиснув',
};
String flagShort(String id) => _flagShort[id] ?? flagById(id)?.label ?? id;

String _meets(int n) => '$n ${plural(n, 'зустріч', 'зустрічі', 'зустрічей')}';

/// Знахідний відмінок для прізвиська: «Архітектора», «Марка», «Олю». Не впевнені — лишаємо як є.
String accus(String name, String gender) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty || parts.first.isEmpty) return name;
  var w = parts.first;
  final cyr = RegExp(r'^[А-ЯҐЄІЇа-яґєії]+$');
  if (!cyr.hasMatch(w)) return name;
  final last = w[w.length - 1].toLowerCase();
  if (gender == 'f') {
    if (last == 'а') {
      w = '${w.substring(0, w.length - 1)}у';
    } else if (last == 'я') {
      w = '${w.substring(0, w.length - 1)}ю';
    } else {
      return name;
    }
  } else {
    if ('бвгґджзклмнпрстфхцчшщ'.contains(last)) {
      w = '$wа';
    } else if (last == 'й') {
      w = '${w.substring(0, w.length - 1)}я';
    } else if (last == 'о') {
      w = '${w.substring(0, w.length - 1)}а';
    } else {
      return name;
    }
  }
  return [w, ...parts.skip(1)].join(' ');
}

/// Підпис рядка зустрічі: «Ресторан · у нього»
String entrySub(Entry e) {
  final t = e.tags.toSet();
  final place = t.contains('restaurant')
      ? 'Ресторан'
      : t.contains('bar')
          ? 'Бар'
          : t.contains('neutral')
              ? 'Прогулянка'
              : t.contains('straight_home')
                  ? 'Одразу вдома'
                  : null;
  final where = t.contains('his') ? 'у нього' : t.contains('mine') ? 'у мене' : t.contains('hotel') ? 'готель' : null;
  final parts = [if (place != null) place, if (where != null) where];
  final sub = parts.join(' · ');
  if (parts.isNotEmpty && sub != entryTitle(e)) return sub;
  if (e.note.isNotEmpty) return e.note;
  return e.hadSex ? 'Був секс' : 'Тільки побачення';
}

/// Мій метч з людиною: аркан пари, якщо в обох є повна дата
class PairMatch {
  final int arc;
  final String ease; // легко | складніше
  final String line;
  const PairMatch(this.arc, this.ease, this.line);
}

PairMatch? matchOf(Profile me, Person p) {
  final a = astroOf(p.birth, p.signOnly), m = astroOf(me.birth);
  if (a?.arc == null || m?.arc == null) return null;
  final pa = pairArcana(m!.arc!, a!.arc!);
  return PairMatch(pa, zodiacEase(m.sign, a.sign).toLowerCase(), 'Ти ${m.romanNum} + ${p.gender == 'f' ? 'вона' : 'він'} ${a.romanNum} · ${a.signName}');
}

/// Колір значка зодіаку: помаранчевий, якщо стихії ладнають
Color _zColor(Profile me, Person p) {
  final a = astroOf(p.birth, p.signOnly), m = astroOf(me.birth);
  if (a == null || m == null) return K.haze;
  return zodiacEase(m.sign, a.sign) == 'Легко' ? K.acc : K.haze;
}

/// Пунктирна рамка (border:1px dashed)
class _Dashed extends CustomPainter {
  final Color c;
  final double r;
  const _Dashed(this.c, this.r);
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & s).deflate(.5), Radius.circular(r)));
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, d + 3), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed o) => o.c != c;
}

class _Glyph extends StatelessWidget {
  final String sign;
  final Color color;
  final double size;
  const _Glyph(this.sign, {required this.color, this.size = 22});
  @override
  Widget build(BuildContext context) => Text(
        glyphOf(sign),
        semanticsLabel: sign,
        style: TextStyle(fontFamily: 'Zodiac', fontSize: size, height: 1, color: color, fontFamilyFallback: _symFonts, decoration: TextDecoration.none),
      );
}

// =====================================================================
// Вкладка «Люди»
// =====================================================================
class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});
  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  bool past = false, search = false;
  final q = TextEditingController();
  final dismissed = <String>{}; // «Ні» на пропозицію перенести в минулі
  String? openId; // картка з відкритими діями свайпу

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    if (s.people.isEmpty) return const _PeopleEmpty();
    final needle = q.text.trim().toLowerCase();
    bool hit(Person p) => needle.isEmpty || p.name.toLowerCase().contains(needle);
    final now = s.people.where((p) => !p.isPast && hit(p)).toList();
    final pastL = s.people.where((p) => p.isPast && hit(p)).toList()..sort((a, b) => (b.pastAt ?? '').compareTo(a.pastAt ?? ''));
    // за останнім записом: свіжі вгорі
    String lastOf(Person p) => personStats(s.entries, p.id).last ?? p.createdAt;
    now.sort((a, b) => lastOf(b).compareTo(lastOf(a)));

    // пропозиція «З Д. не було записів 36 днів»
    Person? stale;
    int staleDays = 0;
    for (final p in now) {
      final l = personStats(s.entries, p.id).last;
      if (l == null || dismissed.contains(p.id)) continue;
      final d = daysBetween(l, today());
      if (d >= 30 && d > staleDays) {
        stale = p;
        staleDays = d;
      }
    }

    final staleP = stale;
    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Rise(
              child: Row(children: [
                Expanded(child: Text('Моя колекція', style: pr(34, h: 1), maxLines: 1, overflow: TextOverflow.fade, softWrap: false)),
                const SizedBox(width: 10),
                IconBtn(svg: _icSearch, label: 'Пошук', onTap: () => setState(() { search = !search; if (!search) q.clear(); })),
                const SizedBox(width: 10),
                Press(
                  label: 'Додати людину',
                  onTap: () => go(context, const AddPersonScreen()),
                  child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.acc), alignment: Alignment.center, child: const Ico(_icPlus, size: 19, color: K.bg)),
                ),
              ]),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: easeD,
              child: search
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: DInput(controller: q, label: 'Пошук', hint: "Ім'я або прізвисько", style: rw(15), height: 48, radius: 999, onChanged: (_) => setState(() {})),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 18),
            Rise(
              delay: .05,
              child: Row(children: [
                _FilterChip('Зараз', !past, () => setState(() => past = false)),
                const SizedBox(width: 8),
                _FilterChip('Минулі', past, () => setState(() => past = true)),
              ]),
            ),
            const SizedBox(height: 16),
            Rise(delay: .1, child: _QuickTiles(people: s.people)),
            if (!past) ...[
              const SizedBox(height: 16),
              if (now.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(needle.isEmpty ? 'Усі в минулих. Нова людина з’явиться тут.' : 'Нікого з таким ім’ям', style: rw(13, color: K.muted, h: 1.45)),
                ),
              for (var i = 0; i < now.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Rise(
                  delay: .15 + math.min(i, 4) * .05,
                  child: _SwipeCard(
                    key: ValueKey(now[i].id),
                    person: now[i],
                    open: openId == now[i].id,
                    onOpen: (v) => setState(() => openId = v ? now[i].id : null),
                  ),
                ),
              ],
              if (staleP != null) ...[
                const SizedBox(height: 10),
                _StaleBanner(
                  person: staleP,
                  days: staleDays,
                  onYes: () => personToPast(context, staleP),
                  onNo: () => setState(() => dismissed.add(staleP.id)),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Text(
                pastL.isEmpty ? 'Тут будуть ті, з ким усе. Їх записи лишаються в мапі, порівняннях і Wrapped.' : 'Їх записи лишаються в мапі, порівняннях і Wrapped. Повернути можна будь-коли.',
                style: rw(13, color: K.muted, h: 1.45),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < pastL.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Rise(delay: .1 + math.min(i, 4) * .05, child: _PastCard(pastL[i])),
              ],
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.on, this.onTap);
  @override
  Widget build(BuildContext context) => Semantics(
        selected: on,
        button: true,
        child: Press(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: easeD,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: on ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999), border: Border.all(color: on ? K.star : K.w(.12))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: rw(13, color: on ? K.bg : K.muted2, w: FontWeight.w500))]),
          ),
        ),
      );
}

/// Дві плитки: «Порівняти двох» і «Зала ганьби»
class _QuickTiles extends StatelessWidget {
  final List<Person> people;
  const _QuickTiles({required this.people});

  Widget _arr() => Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.07)), alignment: Alignment.center, child: const Ico(_icUpRight, size: 12, color: K.soft));

  Widget _tile({required List<Gradient> bg, required Widget head, required String t1, required String t2, required VoidCallback onTap}) => Expanded(
        child: Press(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: K.w(.06)),
              boxShadow: const [BoxShadow(color: Color(0xD908060E), blurRadius: 32, offset: Offset(0, 16), spreadRadius: -22)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(children: [
                for (final g in bg) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: g))),
                Positioned(left: 0, right: 0, top: 0, child: Container(height: 1, color: const Color(0x12FFFFFF))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 32, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: head), _arr()])),
                    const SizedBox(height: 14),
                    Text(t1, style: rw(15, w: FontWeight.w600, ls: -.075)),
                    const SizedBox(height: 3),
                    Text(t2, style: rw(12, color: K.soft)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final two = people.take(2).toList();
    Widget av(int seed) => Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2C2836)),
          alignment: Alignment.center,
          child: PAvatar(size: 32, seed: seed),
        );
    return Row(children: [
      _tile(
        bg: [
          const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF302B3A), Color(0xFF27242F)]),
          RadialGradient(center: Alignment.topLeft, radius: 1.3, colors: [K.a(.30), K.a(0)], stops: const [0, .62]),
        ],
        head: SizedBox(
          width: 70, height: 38,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: -2, top: -2, child: av(two.isNotEmpty ? seedOf(two[0].id) : 0)),
            Positioned(left: 18, top: -2, child: av(two.length > 1 ? seedOf(two[1].id) : 1)),
            Positioned(
              left: 19, top: 25,
              child: Container(
                height: 20, padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF2C2836), width: 2)),
                alignment: Alignment.center,
                child: Text('vs', style: rw(11, color: K.bg, w: FontWeight.w600, h: 1, ls: .2)),
              ),
            ),
          ]),
        ),
        t1: 'Порівняти двох',
        t2: 'Секс і особистість',
        onTap: () => dToast(context, 'Порівняння переносимо з дизайну наступним'),
      ),
      const SizedBox(width: 8),
      _tile(
        bg: [
          const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E2B38), Color(0xFF27242F)]),
          RadialGradient(center: Alignment.topLeft, radius: 1, colors: [K.a(.16), K.a(0)], stops: const [0, .6]),
          RadialGradient(center: Alignment.bottomRight, radius: 1, colors: [K.green.withValues(alpha: .14), K.green.withValues(alpha: 0)], stops: const [0, .6]),
        ],
        head: Row(children: [
          Container(height: 28, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: K.a(.14), borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Transform.rotate(angle: -.17, child: const Ico(_icFlagBadge, size: 15))),
          const SizedBox(width: 5),
          Container(height: 28, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: K.green.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Transform.rotate(angle: -.21, child: const Ico(_icCrownBadge, size: 15))),
        ]),
        t1: 'Зала ганьби',
        t2: 'і зала слави',
        onTap: () => go(context, const ShameScreen()),
      ),
    ]);
  }
}

/// Картка людини зі свайпом вліво: «У минулі» і «Видалити»
class _SwipeCard extends StatefulWidget {
  final Person person;
  final bool open;
  final ValueChanged<bool> onOpen;
  const _SwipeCard({super.key, required this.person, required this.open, required this.onOpen});
  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  static const full = 168.0; // 76 + 8 + 76 + 8
  double dx = 0;
  bool drag = false;

  @override
  void didUpdateWidget(_SwipeCard o) {
    super.didUpdateWidget(o);
    if (!drag) dx = widget.open ? full : 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = widget.person;
    final st = personStats(s.entries, p.id);
    final a = astroOf(p.birth, p.signOnly);
    final t = (dx / full).clamp(0.0, 1.0);
    Widget action(String svg, String label, Color bg, VoidCallback onTap) => Expanded(
          child: Press(
            onTap: () {
              widget.onOpen(false);
              onTap();
            },
            child: Container(
              height: 112,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: 76,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Ico(svg, size: 20, color: K.bg),
                    const SizedBox(height: 6),
                    Text(label, style: rw(12, color: K.bg, w: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ),
        );

    return GestureDetector(
      onHorizontalDragStart: (_) => drag = true,
      onHorizontalDragUpdate: (e) => setState(() => dx = (dx - e.delta.dx).clamp(0.0, full + 20)),
      onHorizontalDragEnd: (e) {
        drag = false;
        final v = e.primaryVelocity ?? 0;
        final open = v < -300 || (v <= 300 && dx > full / 2);
        setState(() => dx = open ? full : 0);
        widget.onOpen(open);
      },
      child: AnimatedContainer(
        duration: drag ? Duration.zero : const Duration(milliseconds: 450),
        curve: easeD,
        height: 112,
        child: LayoutBuilder(builder: (context, c) {
          final reveal = math.min(dx, full + 20);
          return Row(children: [
            SizedBox(
              width: c.maxWidth - reveal,
              child: Press(
                scale: t > 0 ? 1 : .97,
                label: p.name,
                onTap: () {
                  if (widget.open) {
                    widget.onOpen(false);
                  } else {
                    go(context, PersonView(personId: p.id));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(26)),
                  child: Row(children: [
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.08))),
                      child: Blob(seed: seedOf(p.id), w: 92 - 36 * t, h: 92, radius: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (a != null && t < .5) ...[_Glyph(a.signName, color: _zColor(s.profile, p)), const SizedBox(height: 6)],
                        Text(p.name, style: rw(17, w: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Ico(Svgs.star4, size: 12, color: K.acc),
                          const SizedBox(width: 4),
                          Text(st.n > 0 ? fmt(st.overall) : '—', style: rw(12)),
                          const SizedBox(width: 10),
                          Flexible(child: Text(t > .5 ? _meets(st.n) : '${_meets(st.n)} · ${relLabel(p.rel)}', style: rw(12, color: K.muted2), maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            if (reveal > 1)
              SizedBox(
                width: reveal,
                child: Row(children: [
                  const SizedBox(width: 8),
                  action(_icArchive, 'У минулі', K.haze, () => personToPast(context, p)),
                  const SizedBox(width: 8),
                  action(_icTrash, 'Видалити', K.acc, () => personDelete(context, p)),
                ]),
              ),
          ]);
        }),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  final Person person;
  final int days;
  final VoidCallback onYes, onNo;
  const _StaleBanner({required this.person, required this.days, required this.onYes, required this.onNo});
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _Dashed(K.w(.16), 20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(children: [
            Expanded(child: Text('З ${person.name} не було записів $days ${plural(days, 'день', 'дні', 'днів')}. Перенести в минулі?', style: rw(13, color: K.soft, h: 1.4))),
            const SizedBox(width: 10),
            Press(onTap: onYes, child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text('Так', style: rw(13, color: K.bg, w: FontWeight.w600)))),
            const SizedBox(width: 10),
            Press(onTap: onNo, child: Container(height: 44, constraints: const BoxConstraints(minWidth: 44), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text('Ні', style: rw(13, w: FontWeight.w600)))),
          ]),
        ),
      );
}

class _PastCard extends StatelessWidget {
  final Person p;
  const _PastCard(this.p);
  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final st = personStats(s.entries, p.id);
    final last = st.last ?? p.pastAt;
    final when = last == null ? '' : ' · до ${monthsGen[parseIso(last).month - 1]}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(26), border: Border.all(color: K.w(.07))),
      child: Row(children: [
        Expanded(
          child: Press(
            onTap: () => go(context, PersonView(personId: p.id)),
            child: Row(children: [
              Blob(seed: seedOf(p.id), w: 64, h: 64, radius: 18, grey: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: rw(16, color: K.soft2, w: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${_meets(st.n)}$when', style: rw(12, color: K.muted2), maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
                  const SizedBox(height: 4),
                  Text(_reason(p), style: rw(12, color: K.haze)),
                ]),
              ),
            ]),
          ),
        ),
        Press(
          onTap: () async {
            final st0 = (p.pastReason, p.pastAt);
            await s.updatePerson(p.id, (x) { x.status = 'now'; x.pastReason = null; x.pastAt = null; });
            if (!context.mounted) return;
            undoToast(context, '${p.name} знову в «Зараз»', () => s.updatePerson(p.id, (x) { x.status = 'past'; x.pastReason = st0.$1; x.pastAt = st0.$2; }), action: 'Скасувати', bottom: 106);
          },
          child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.12))), alignment: Alignment.center, child: Text('Повернути', style: rw(13, w: FontWeight.w600))),
        ),
      ]),
    );
  }
}

String _reason(Person p) {
  final f = p.gender == 'f';
  switch (p.pastReason) {
    case 'gone':
      return f ? 'Вона зникла' : 'Він зник';
    case 'faded':
      return 'Само згасло';
    case 'ended':
      return 'Я завершила';
    case 'night':
      return 'Одна ніч';
  }
  return p.rel == 'night' ? 'Одна ніч' : 'У минулих';
}

/// PartnersEmpty: ілюстрація з трьох карток, «Поки нікого»
class _PeopleEmpty extends StatelessWidget {
  const _PeopleEmpty();
  @override
  Widget build(BuildContext context) {
    Widget sk(double w, [Color? c]) => Container(height: 7, width: w, decoration: BoxDecoration(color: c ?? K.w(.07), borderRadius: BorderRadius.circular(4)));
    Widget card({required double left, required double top, required double rot, required double delay, required Widget child, required BoxDecoration deco}) => Positioned(
          left: left, top: top,
          child: Rise(
            delay: delay,
            dy: 30,
            child: Transform.rotate(angle: rot * math.pi / 180, child: Container(width: 120, height: 156, padding: const EdgeInsets.fromLTRB(14, 16, 14, 16), decoration: deco, child: child)),
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Люди', style: pr(34, h: 44 / 34)),
        const SizedBox(height: 14),
        SizedBox(
          height: 236,
          child: Stack(clipBehavior: Clip.none, children: [
            const Positioned(left: 25, top: -2, child: EGlow(w: 300, h: 240, colors: [Color(0x33F08A6C), Color(0x0017161F)], stops: [0, 1])),
            card(
              left: 20, top: 44, rot: -12, delay: .05,
              deco: BoxDecoration(color: const Color(0xFF211E2A), borderRadius: BorderRadius.circular(24), border: Border.all(color: K.w(.06))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.06))),
                const SizedBox(height: 14),
                sk(64), const SizedBox(height: 8), sk(46), const Spacer(), sk(57),
              ]),
            ),
            card(
              left: 108, top: 24, rot: -3, delay: .15,
              deco: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(begin: Alignment(-.2, -1), end: Alignment(.2, 1), colors: [Color(0xFF302B3C), Color(0xFF25222F)]),
                border: Border(top: BorderSide(color: K.w(.1))),
                boxShadow: const [BoxShadow(color: Color(0xF209080E), blurRadius: 40, offset: Offset(0, 24), spreadRadius: -22)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Blob(seed: 0, w: 92, h: 74, radius: 14, blur: .3),
                const SizedBox(height: 12),
                sk(64, K.w(.16)), const SizedBox(height: 8), sk(46),
              ]),
            ),
            card(
              left: 194, top: 42, rot: 9, delay: .25,
              deco: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF201B25),
                gradient: RadialGradient(center: const Alignment(0, -.1), radius: .7, colors: [K.a(.16), K.a(0)]),
                border: Border.all(color: K.a(.35)),
                boxShadow: [BoxShadow(color: K.a(.45), blurRadius: 44, offset: const Offset(0, 24), spreadRadius: -22)],
              ),
              child: Press(
                label: 'Додати людину',
                onTap: () => go(context, const AddPersonScreen()),
                child: CustomPaint(
                  painter: _Dashed(K.a(.35), 18),
                  child: Center(
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(center: Alignment(0, -.4), colors: [Color(0xFFF6A890), K.acc]), boxShadow: [BoxShadow(color: K.a(.55), blurRadius: 22)]),
                      alignment: Alignment.center,
                      child: const Ico(_icPlusThin, size: 22, color: K.bg),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Center(child: titleAcc([('Поки ', false), ('нікого', true)], 28, h: 1.2)),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 290,
            child: Text('Побачення, стосунки чи одна ніч: додай першу людину. Після кількох записів зможеш порівнювати.', textAlign: TextAlign.center, style: rw(14, color: K.muted2, h: 1.5)),
          ),
        ),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: gapped([
          for (final f in [(_icColumns, 'Порівняння'), (_icSpark, 'Метч зірок'), (_icFlagLine, 'Прапорці')])
            Container(
              height: 28,
              padding: const EdgeInsets.fromLTRB(10, 0, 11, 0),
              decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.08))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Ico(f.$1, size: 13, color: K.accSoft), const SizedBox(width: 6), Text(f.$2, style: rw(12, color: K.soft2, w: FontWeight.w500))]),
            ),
        ], 8, horizontal: true)),
        const SizedBox(height: 22),
        Center(
          child: Press(
            onTap: () => go(context, const AddPersonScreen()),
            child: Container(
              height: 56,
              padding: const EdgeInsets.fromLTRB(26, 0, 6, 0),
              decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: K.a(.7), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -14)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Додати людину', style: rw(16, color: K.bg, w: FontWeight.w700)),
                const SizedBox(width: 14),
                Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2417161F)), alignment: Alignment.center, child: const Ico(_icPlusThin, size: 22, color: K.bg)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Ico(_icLock, size: 12, color: K.muted2),
          const SizedBox(width: 6),
          Text('Бачиш тільки ти, все лишається на телефоні', style: rw(12, color: K.muted2)),
        ]),
      ]),
    );
  }
}

// =====================================================================
// Дії з людиною (PersonActions): меню, «у минулі», видалення, тост
// =====================================================================
Future<void> personActions(BuildContext context, Person p, {bool fromCard = true}) async {
  final s = Store.read(context);
  final st = personStats(s.entries, p.id);
  final since = st.first ?? (p.createdAt.length >= 10 ? p.createdAt : today());
  final what = await showSheet<String>(
    context,
    (ctx) => DFrame(
      bg: Colors.transparent,
      builder: (ctx, h) => Stack(children: [
        Positioned.fill(child: GestureDetector(onTap: () => Navigator.pop(ctx))),
        Positioned(
          left: 12, right: 12, bottom: 16,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: K.card2,
                borderRadius: BorderRadius.circular(28),
                border: Border(top: BorderSide(color: K.w(.09))),
                boxShadow: const [BoxShadow(color: Color(0xCC09080E), blurRadius: 60, offset: Offset(0, -20), spreadRadius: -20)],
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(top: -4, left: 0, right: 0, child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: K.w(.18), borderRadius: BorderRadius.circular(2))))),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: K.a(.4))),
                        child: PAvatar(size: 38, seed: seedOf(p.id)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: pr(20, h: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${st.n} ${plural(st.n, 'запис', 'записи', 'записів')} · з ${monthsGen[parseIso(since.substring(0, 10)).month - 1]}', style: rw(12, color: K.muted)),
                        ]),
                      ),
                    ]),
                  ),
                  _ActRow(svg: _icPen17, title: 'Редагувати', sub: "Ім'я, фото, дата, нотатки", onTap: () => Navigator.pop(ctx, 'edit')),
                  if (p.isPast)
                    _ActRow(svg: _icArchive, title: 'Повернути в «Зараз»', sub: 'Знову в списку людей', onTap: () => Navigator.pop(ctx, 'back'), line: true)
                  else
                    _ActRow(svg: _icArchive, title: 'Перенести в минулі', sub: 'Записи лишаться в мапі', onTap: () => Navigator.pop(ctx, 'past'), line: true),
                  _ActRow(svg: _icTrash, title: 'Видалити людину і записи', sub: 'Назавжди, без відновлення', red: true, onTap: () => Navigator.pop(ctx, 'delete'), line: true),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            Press(
              onTap: () => Navigator.pop(ctx),
              child: Container(height: 54, decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.08))), alignment: Alignment.center, child: Text('Скасувати', style: rw(15, w: FontWeight.w600))),
            ),
          ]),
        ),
      ]),
    ),
  );
  if (!context.mounted) return;
  switch (what) {
    case 'edit':
      go(context, AddPersonScreen(personId: p.id));
    case 'past':
      await personToPast(context, p);
    case 'back':
      final st0 = (p.pastReason, p.pastAt);
      await s.updatePerson(p.id, (x) { x.status = 'now'; x.pastReason = null; x.pastAt = null; });
      if (context.mounted) undoToast(context, '${p.name} знову в «Зараз»', () => s.updatePerson(p.id, (x) { x.status = 'past'; x.pastReason = st0.$1; x.pastAt = st0.$2; }), action: 'Скасувати');
    case 'delete':
      await personDelete(context, p, popAfter: !fromCard);
  }
}

class _ActRow extends StatelessWidget {
  final String svg, title, sub;
  final bool red, line;
  final VoidCallback onTap;
  const _ActRow({required this.svg, required this.title, required this.sub, required this.onTap, this.red = false, this.line = false});
  @override
  Widget build(BuildContext context) {
    final c = red ? K.red : K.star;
    return Press(
      scale: 1,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(border: line ? Border(top: BorderSide(color: K.w(.06))) : null),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: red ? const Color(0x1AE25C5C) : null, border: Border.all(color: red ? K.red.withValues(alpha: .3) : K.w(.1))),
            alignment: Alignment.center,
            child: Ico(svg, size: 16, color: red ? K.red : K.soft2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: rw(15, color: c, w: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(sub, style: rw(12, color: red ? K.red.withValues(alpha: .75) : K.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Лист «{ім'я} у минулі» з причинами
Future<void> personToPast(BuildContext context, Person p) async {
  final s = Store.read(context);
  final f = p.gender == 'f';
  final reasons = [('ended', 'Я завершила'), ('gone', f ? 'Вона зникла' : 'Він зник'), ('faded', 'Само згасло')];
  final r = await showSheet<(bool, String?)>(context, (ctx) {
    String? pick;
    return StatefulBuilder(
      builder: (ctx, set) => Sheet(children: [
        Text('${p.name} у минулі', style: pr(26, h: 1.15)),
        Text('Записи лишаться в мапі і порівняннях. Повернути можна будь-коли.', style: rw(14, color: K.soft, h: 1.5)),
        Padding(padding: const EdgeInsets.only(top: 4), child: Text('Що сталось? Можна пропустити', style: rw(12, color: K.muted2))),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in reasons)
            Semantics(
              selected: pick == x.$1,
              button: true,
              child: Press(
                onTap: () => set(() => pick = pick == x.$1 ? null : x.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: easeD,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: pick == x.$1 ? K.star : K.w(.03), borderRadius: BorderRadius.circular(999), border: Border.all(color: pick == x.$1 ? K.star : K.w(.1))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Text(x.$2, style: rw(13, color: pick == x.$1 ? K.bg : const Color(0xFFE6E2EB), w: FontWeight.w500))]),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Press(
          onTap: () => Navigator.pop(ctx, (true, pick)),
          child: Container(height: 54, decoration: BoxDecoration(color: K.star, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: K.w(.4), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -18)]), alignment: Alignment.center, child: Text('Перенести', style: rw(15, color: K.bg, w: FontWeight.w700))),
        ),
        Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Скасувати', style: rw(15, w: FontWeight.w700))))),
      ]),
    );
  });
  if (r == null || !r.$1) return;
  await s.updatePerson(p.id, (x) { x.status = 'past'; x.pastReason = r.$2; x.pastAt = today(); });
  if (!context.mounted) return;
  undoToast(context, '${p.name} у минулих', () => s.updatePerson(p.id, (x) { x.status = 'now'; x.pastReason = null; x.pastAt = null; }));
}

/// Лист «Видалити Архітектора і 5 записів?»
Future<void> personDelete(BuildContext context, Person p, {bool popAfter = false}) async {
  final s = Store.read(context);
  final es = entriesOf(s.entries, p.id);
  final ms = s.db.meetings.where((m) => m.personId == p.id).toList();
  final f = p.gender == 'f';
  final yes = await showSheet<String>(context, (ctx) => Sheet(children: [
        Text(es.isEmpty ? 'Видалити ${accus(p.name, p.gender)}?' : 'Видалити ${accus(p.name, p.gender)} і ${es.length} ${plural(es.length, 'запис', 'записи', 'записів')}?', style: pr(26, h: 1.15)),
        Text('Оцінки зникнуть з мапи і порівнянь. Відновити не можна.', style: rw(14, color: K.soft, h: 1.5)),
        if (!p.isPast)
          Press(
            onTap: () => Navigator.pop(ctx, 'past'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.08))),
              child: Row(children: [
                const Ico(_icArchive, size: 18, color: K.haze),
                const SizedBox(width: 12),
                Expanded(child: Text('Може, краще в минулі? Записи збережуться, а ${f ? 'вона зникне' : 'він зникне'} зі списку.', style: rw(13, h: 1.4, w: FontWeight.w500))),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        Press(
          onTap: () => Navigator.pop(ctx, 'delete'),
          child: Container(height: 54, decoration: BoxDecoration(color: const Color(0xFFD9544F), borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0xB3D9544F), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -14)]), alignment: Alignment.center, child: Text('Видалити назавжди', style: rw(15, color: Colors.white, w: FontWeight.w700))),
        ),
        Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Скасувати', style: rw(15, w: FontWeight.w700))))),
      ]));
  if (!context.mounted) return;
  if (yes == 'past') return personToPast(context, p);
  if (yes != 'delete') return;
  final overlay = appNav.currentState?.overlay ?? Overlay.of(context);
  final nav = Navigator.of(context);
  if (popAfter) nav.pop(); // спершу закриваємо картку, потім видаляємо
  await s.deletePerson(p.id);
  if (!overlay.mounted) return;
  undoToast(overlay.context, '${p.name}: видалено', () => s.importBatch(people: [p], entries: es, meetings: ms), overlay: overlay);
}

// =====================================================================
// Картка людини (Partner / PartnerNoDate)
// =====================================================================
class PersonView extends StatefulWidget {
  final String personId;
  const PersonView({super.key, required this.personId});
  @override
  State<PersonView> createState() => _PersonViewState();
}

class _PersonViewState extends State<PersonView> {
  bool reveal = false; // «Показати фото» — прибирає розмиття
  final dd = TextEditingController(), mm = TextEditingController();
  final fm = FocusNode();

  @override
  void dispose() {
    dd.dispose();
    mm.dispose();
    fm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.person(widget.personId);
    if (p == null) {
      return DScroll(children: [const Align(alignment: Alignment.centerLeft, child: BackBtn()), Text('Людину не знайдено', style: rw(15, color: K.muted))]);
    }
    final st = personStats(s.entries, p.id);
    final es = entriesOf(s.entries, p.id).reversed.toList();
    final a = astroOf(p.birth, p.signOnly);
    final m = matchOf(s.profile, p);
    final f = p.gender == 'f';
    final since = st.first ?? (p.createdAt.length >= 10 ? p.createdAt.substring(0, 10) : today());
    final flags = st.flagCounts.where((x) => x.kind != FlagKind.c).take(3).toList();
    const sizeT = ['Скромно', 'Стандарт', 'Вражає', 'Гігант'];
    final dot = Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.45)));
    final metaStyle = rw(12, color: K.w(.78), ls: .12);

    final third = st.orgN > 0
        ? _Stat('Кінчала', '${st.orgMe}', ' з ${st.orgN}')
        : _Stat('Зустрічі', '${st.n}', '');

    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Stack(children: [
              // фото-героїня
              SizedBox(height: 356, width: double.infinity, child: _Hero(seed: seedOf(p.id), sharp: reveal, grey: p.isPast)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 148, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Rise(
                    child: Row(children: [
                      if (a != null)
                        Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(shape: BoxShape.circle, color: K.acc), alignment: Alignment.center, child: _Glyph(a.signName, color: K.bg, size: 11))
                      else
                        CustomPaint(painter: _Dashed(K.w(.6), 10), child: Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 6), alignment: Alignment.center, child: Text('?', style: rw(11, color: K.w(.85), w: FontWeight.w600, h: 1)))),
                      Flexible(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: a?.signName ?? 'Без дати'),
                            WidgetSpan(alignment: PlaceholderAlignment.middle, child: dot),
                            TextSpan(text: p.isPast ? _reason(p) : relLabel(p.rel)),
                            WidgetSpan(alignment: PlaceholderAlignment.middle, child: dot),
                            TextSpan(text: 'з ${monthsGen[parseIso(since).month - 1]}'),
                            if (p.size != null) ...[
                              WidgetSpan(alignment: PlaceholderAlignment.middle, child: dot),
                              WidgetSpan(alignment: PlaceholderAlignment.middle, child: _SizeBars(p.size!)),
                              TextSpan(text: ' ${sizeT[p.size!]}'),
                            ],
                          ]),
                          style: metaStyle,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Rise(delay: .05, child: Text(p.name, style: pr(44, h: 1, ls: -.02), maxLines: 2)),
                  if (flags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Rise(
                      delay: .1,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(children: gapped([for (final x in flags) _GlassFlag(flagShort(x.id), x.n, neg: x.kind != FlagKind.g)], 6, horizontal: true)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Rise(delay: .15, child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [K.w(0), K.w(.22), K.w(.22), K.w(0)], stops: const [0, .18, .82, 1])))),
                  const SizedBox(height: 14),
                  Rise(
                    delay: .2,
                    child: IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(child: _Stat('Загалом', st.n > 0 ? fmt(st.overall) : '—', st.n > 0 ? '/5' : '')),
                        _vline(),
                        Expanded(child: _Stat('Секс', st.sexN > 0 ? fmt(st.sex) : '—', st.sexN > 0 ? '/5' : '')),
                        _vline(),
                        Expanded(child: third),
                      ]),
                    ),
                  ),
                  if (p.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Rise(
                      delay: .25,
                      child: Press(
                        onTap: () => go(context, AddPersonScreen(personId: p.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(20)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(padding: EdgeInsets.only(top: 1), child: Ico(_icPen, size: 18, color: K.acc)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f ? 'Нотатки про неї' : 'Нотатки про нього', style: rw(12, color: K.muted2, w: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(p.notes, style: rw(13, h: 1.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Rise(
                    delay: .3,
                    child: m != null
                        ? _MatchCard(m: m, onTap: () => _matchSheet(context, p, m))
                        : (p.birth == null || a?.arc == null)
                            ? _NoDateCard(
                                f: f, dd: dd, mm: mm, fm: fm,
                                onChanged: () => setState(() {}),
                                onSave: () async {
                                  final d = int.tryParse(dd.text), mo = int.tryParse(mm.text);
                                  if (d == null || mo == null || mo < 1 || mo > 12 || d < 1 || d > DateTime(2000, mo + 1, 0).day) {
                                    dToast(context, 'Перевір день і місяць');
                                    return;
                                  }
                                  FocusScope.of(context).unfocus();
                                  await s.updatePerson(p.id, (x) { x.birth = '0000-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}'; x.signOnly = null; });
                                  if (context.mounted && s.profile.birth == null) dToast(context, 'Знак пораховано. Для метчу додай і свою дату в налаштуваннях');
                                },
                              )
                            : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 18),
                  Rise(
                    delay: .35,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Зустрічі', style: rw(15, w: FontWeight.w600)),
                      const Spacer(),
                      if (es.length > 3)
                        Press(
                          onTap: () => _allSheet(context, p, es),
                          child: Row(children: [Text('Усі ${es.length}', style: rw(12, color: K.muted2, w: FontWeight.w600)), const SizedBox(width: 3), Ico(Svgs.chevR, size: 12, color: K.muted2)]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Rise(
                    delay: .4,
                    child: es.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(22)),
                            child: Text('Ще жодного запису. Перша зустріч з’явиться тут.', style: rw(13, color: K.muted, h: 1.45)),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              color: K.hour,
                              child: Column(children: [
                                for (var i = 0; i < math.min(3, es.length); i++) _MeetRow(es[i], line: i > 0),
                              ]),
                            ),
                          ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        // скляні кнопки
        Positioned(
          left: 20, right: 20, top: 58,
          child: Row(children: [
            _GlassBtn(svg: Svgs.back, label: 'Назад', onTap: () => Navigator.of(context).maybePop()),
            const Spacer(),
            _GlassBtn(svg: _icEye, label: reveal ? 'Розмити фото' : 'Показати фото', onTap: () => setState(() => reveal = !reveal)),
            const SizedBox(width: 8),
            _GlassBtn(svg: _icMore, label: 'Ще', onTap: () => personActions(context, p, fromCard: false)),
          ]),
        ),
        // низ: порівняти + новий запис
        Positioned(
          left: 20, right: 20, bottom: 22,
          child: Row(children: [
            Press(
              label: 'Порівняти',
              onTap: () => dToast(context, 'Порівняння переносимо з дизайну наступним'),
              child: Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: K.hour), alignment: Alignment.center, child: const Ico(_icRings, size: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Press(
                onTap: () => go(context, EntryForm(personId: p.id)),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(color: K.acc, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Ico(_icPlus, size: 18, color: K.bg), const SizedBox(width: 8), Text('Новий запис', style: rw(15, color: K.bg, w: FontWeight.w700))]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _vline() => Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: K.w(.1));
}

class _Hero extends StatelessWidget {
  final int seed;
  final bool sharp, grey;
  const _Hero({required this.seed, required this.sharp, required this.grey});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        Widget x = Stack(children: [
          Positioned.fill(child: Blob(seed: seed, w: c.maxWidth, h: 356, radius: 0, blur: 0, grey: grey)),
          // темна «фігура» з макета (.kb)
          Positioned(
            left: 120, top: 70,
            child: _KenBurns(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                child: Container(width: 150, height: 190, decoration: const BoxDecoration(color: Color(0x8C2B2836), borderRadius: BorderRadius.vertical(top: Radius.circular(75), bottom: Radius.circular(60)))),
              ),
            ),
          ),
        ]);
        x = AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: sharp ? KeyedSubtree(key: const ValueKey(1), child: x) : ImageFiltered(key: const ValueKey(0), imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3, tileMode: TileMode.decal), child: x),
        );
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, .72, 1]).createShader(r),
          child: Stack(children: [
            Positioned.fill(child: ClipRect(child: x)),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0017161F), Color(0x0017161F), Color(0x5917161F), K.bg], stops: [0, .4, .75, 1]),
                ),
              ),
            ),
          ]),
        );
      });
}

class _KenBurns extends StatefulWidget {
  final Widget child;
  const _KenBurns({required this.child});
  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: Tween(begin: 1.1, end: 1.0).animate(CurvedAnimation(parent: c, curve: easeOut)), child: widget.child);
}

class _GlassBtn extends StatelessWidget {
  final String svg, label;
  final VoidCallback onTap;
  const _GlassBtn({required this.svg, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Press(
        label: label,
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x5917161F), border: Border.all(color: K.w(.18))),
              alignment: Alignment.center,
              child: Ico(svg, size: 19),
            ),
          ),
        ),
      );
}

class _SizeBars extends StatelessWidget {
  final int v;
  const _SizeBars(this.v);
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 10,
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: gapped([
          for (var i = 0; i < 4; i++) Container(width: 3, height: 4.0 + i * 2, decoration: BoxDecoration(color: i <= v ? K.star : K.w(.35), borderRadius: BorderRadius.circular(1))),
        ], 2, horizontal: true)),
      );
}

class _GlassFlag extends StatelessWidget {
  final String label;
  final int n;
  final bool neg;
  const _GlassFlag(this.label, this.n, {required this.neg});
  @override
  Widget build(BuildContext context) {
    final base = neg ? K.acc : K.green;
    final fg = neg ? const Color(0xFFFFE6DE) : const Color(0xFFE4F3E8);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 32,
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base.withValues(alpha: .22), base.withValues(alpha: .06), base.withValues(alpha: .12)], stops: const [0, .6, 1]),
            border: Border.all(color: (neg ? const Color(0xFFFFBEAA) : const Color(0xFFBEE6C8)).withValues(alpha: .22)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: rw(12, color: fg, w: FontWeight.w500, ls: .12)),
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: base.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
              alignment: Alignment.center,
              child: Text('$n', style: rw(11, color: fg, w: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value, suffix;
  const _Stat(this.label, this.value, this.suffix);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: rw(12, color: K.muted2, ls: .12)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(text: value, children: [if (suffix.isNotEmpty) TextSpan(text: suffix, style: rw(12, color: K.haze))]),
          style: pr(30, h: 1, ls: -.02),
          maxLines: 1,
        ),
      ]);
}

/// Мінікарта аркана: 48×66, нахил −4°, легке погойдування
class _ArcCard extends StatefulWidget {
  final String roman;
  final bool q;
  const _ArcCard({required this.roman, this.q = false});
  @override
  State<_ArcCard> createState() => _ArcCardState();
}

class _ArcCardState extends State<_ArcCard> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  @override
  void initState() {
    super.initState();
    if (!widget.q) c.repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: widget.q ? null : const LinearGradient(begin: Alignment(-.2, -1), end: Alignment(.2, 1), colors: [Color(0xFF2E2A3B), Color(0xFF1D1B26)]),
        border: widget.q ? null : Border.all(color: K.a(.35)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Ico(Svgs.star4, size: 9, color: K.acc),
        const SizedBox(height: 4),
        Text(widget.roman, style: pr(14, h: 1, ls: .02)),
        const SizedBox(height: 4),
        Container(width: 14, height: 1, color: K.a(.5)),
      ]),
    );
    final card = Container(
      width: 48, height: 66,
      padding: const EdgeInsets.all(3),
      decoration: widget.q
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(begin: const Alignment(-.4, -1), end: const Alignment(.4, 1), colors: [K.a(.55), K.haze.withValues(alpha: .25)]),
              boxShadow: const [BoxShadow(color: Color(0xCC08060E), blurRadius: 22, offset: Offset(0, 10), spreadRadius: -12)],
            ),
      child: inner,
    );
    final framed = widget.q ? CustomPaint(painter: _Dashed(K.a(.55), 10), child: card) : card;
    return AnimatedBuilder(
      animation: c,
      builder: (_, child) {
        final t = math.sin(c.value * 2 * math.pi);
        return Transform.translate(offset: Offset(0, widget.q ? 0 : -1 + t), child: Transform.rotate(angle: (widget.q ? -4 : (-3 + t)) * math.pi / 180, child: child));
      },
      child: framed,
    );
  }
}

class _MatchCard extends StatelessWidget {
  final PairMatch m;
  final VoidCallback onTap;
  const _MatchCard({required this.m, required this.onTap});
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: K.hour,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: K.w(.07)),
            gradient: RadialGradient(center: Alignment.centerLeft, radius: 1.4, colors: [K.a(.16), K.a(0)], stops: const [0, .6]),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            // зорі
            Positioned(right: 46, top: 2, child: _dot(.45, K.star)),
            Positioned(right: 86, top: 32, child: _dot(.3, K.star)),
            Positioned(right: 136, top: 10, child: _dot(.6, K.acc)),
            Positioned(right: 66, top: 46, child: _dot(.25, K.star)),
            Row(children: [
              _ArcCard(roman: roman[m.arc]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ваш метч', style: rw(11, color: K.muted2, w: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Flexible(child: Text(arcana[m.arc].name, style: pr(22, h: 1), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(height: 20, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: K.a(.16), borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text(m.ease, style: rw(11, color: K.accSoft, w: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 5),
                  Text(m.line, style: rw(12, color: K.muted2), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: K.w(.06)), alignment: Alignment.center, child: Ico(Svgs.chevR, size: 14, color: K.soft)),
            ]),
          ]),
        ),
      );

  static Widget _dot(double a, Color c) => Container(width: 2, height: 2, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: a)));
}

class _NoDateCard extends StatelessWidget {
  final bool f;
  final TextEditingController dd, mm;
  final FocusNode fm;
  final VoidCallback onChanged, onSave;
  const _NoDateCard({required this.f, required this.dd, required this.mm, required this.fm, required this.onChanged, required this.onSave});
  @override
  Widget build(BuildContext context) {
    Widget inp(TextEditingController c, String hint, {FocusNode? focus, ValueChanged<String>? on}) => Container(
          height: 46,
          decoration: BoxDecoration(color: const Color(0x7317161F), borderRadius: BorderRadius.circular(14), border: Border.all(color: K.w(.1))),
          alignment: Alignment.center,
          child: TextField(
            controller: c,
            focusNode: focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            onChanged: (v) {
              onChanged();
              on?.call(v);
            },
            cursorColor: K.acc,
            style: pr(16),
            decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: hint, hintStyle: rw(13, color: K.haze, w: FontWeight.w500)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: K.hour,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: K.w(.07)),
        gradient: RadialGradient(center: Alignment.centerLeft, radius: 1.4, colors: [K.a(.16), K.a(0)], stops: const [0, .6]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const _ArcCard(roman: '?', q: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ваш метч чекає', style: rw(11, color: K.muted2, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(f ? 'Дізналась її день народження?' : 'Дізналась його день народження?', style: rw(15, w: FontWeight.w500, h: 1.3)),
              const SizedBox(height: 4),
              Text('Порахуємо знак, аркан і ваш метч', style: rw(12, color: K.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(flex: 100, child: inp(dd, 'День', on: (v) { if (v.length == 2) fm.requestFocus(); })),
          const SizedBox(width: 8),
          Expanded(flex: 100, child: inp(mm, 'Місяць', focus: fm)),
          const SizedBox(width: 8),
          Expanded(
            flex: 125,
            child: Press(
              onTap: onSave,
              child: Container(
                height: 46,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const RadialGradient(center: Alignment.topLeft, radius: 1.6, colors: [Color(0xFFF6A890), K.acc], stops: [0, .6])),
                alignment: Alignment.center,
                child: Text('Порахувати', style: rw(14, color: K.bg, w: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _MeetRow extends StatelessWidget {
  final Entry e;
  final bool line;
  const _MeetRow(this.e, {this.line = false});
  @override
  Widget build(BuildContext context) {
    final d = parseIso(e.date);
    return Press(
      scale: 1,
      onTap: () => go(context, EntryView(entryId: e.id)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 16, 11),
        decoration: BoxDecoration(border: line ? Border(top: BorderSide(color: K.w(.06))) : null),
        child: Row(children: [
          SizedBox(
            width: 34,
            child: Column(children: [
              Text('${d.day}', style: pr(20, h: 1)),
              const SizedBox(height: 3),
              Text(monthsShort[d.month - 1], style: rw(10, color: K.haze, w: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entryTitle(e), style: rw(14, w: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(entrySub(e), style: rw(12, color: K.muted2), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${e.overall}', style: pr(18, h: 1)),
            const SizedBox(height: 5),
            Row(children: gapped([for (var i = 1; i <= 5; i++) Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: i <= e.overall ? K.acc : K.w(.15)))], 2, horizontal: true)),
          ]),
        ]),
      ),
    );
  }
}

void _allSheet(BuildContext context, Person p, List<Entry> es) {
  final since = es.isEmpty ? null : parseIso(es.last.date);
  showSheet(context, (ctx) => Sheet(children: [
        Text('Усі зустрічі', style: pr(26, h: 1.15)),
        if (since != null) Text('${p.name} · з ${since.day} ${monthsGen[since.month - 1]}', style: rw(14, color: K.soft)),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .55),
          child: SingleChildScrollView(
            child: Column(children: gapped([
              for (final e in es)
                Press(
                  onTap: () {
                    Navigator.pop(ctx);
                    go(context, EntryView(entryId: e.id));
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: K.w(.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: K.w(.08))),
                    child: Row(children: [
                      SizedBox(width: 34, child: Column(children: [Text('${parseIso(e.date).day}', style: pr(18, h: 1)), Text(monthsShort[parseIso(e.date).month - 1], style: rw(10, color: K.haze))])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(entryTitle(e), style: rw(14, w: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(entrySub(e), style: rw(12, color: K.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      Text('${e.overall}', style: pr(18, color: K.accSoft)),
                    ]),
                  ),
                ),
            ], 8)),
          ),
        ),
        Press(onTap: () => Navigator.pop(ctx), child: Container(height: 54, decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(999), border: Border.all(color: K.w(.08))), alignment: Alignment.center, child: Text('Скасувати', style: rw(15, w: FontWeight.w600)))),
      ]));
}

void _matchSheet(BuildContext context, Person p, PairMatch m) {
  showSheet(context, (ctx) => Sheet(children: [
        Row(children: [
          _ArcCard(roman: roman[m.arc]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Аркан пари ${roman[m.arc]}', style: rw(12, color: K.muted2, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(arcana[m.arc].name, style: pr(26, h: 1.1)),
            ]),
          ),
        ]),
        Text(m.line, style: rw(13, color: K.muted2)),
        Text(arcana[m.arc].love, style: rw(14, color: K.soft, h: 1.5)),
        Text('Зодіак: ${m.ease}. Зірки як гра, записи як правда.', style: rw(12, color: K.haze, h: 1.45)),
        Press(onTap: () => Navigator.pop(ctx), child: SizedBox(height: 44, child: Center(child: Text('Закрити', style: rw(15, w: FontWeight.w700))))),
      ]));
}

/// Старі виклики `PersonEdit(personId: …)` ведуть на нову форму з дошки PersonEdit
class PersonEdit extends StatelessWidget {
  final String? personId;
  const PersonEdit({super.key, this.personId});
  @override
  Widget build(BuildContext context) => AddPersonScreen(personId: personId);
}

// =====================================================================
// Зала ганьби / Зала слави (HallOfShame)
// =====================================================================
class _HallRow {
  final Person p;
  final int meets, n;
  final double rate;
  final List<MapEntry<String, int>> flags;
  _HallRow(this.p, this.meets, this.n, this.rate, this.flags);
}

class ShameScreen extends StatefulWidget {
  final bool glory;
  const ShameScreen({super.key, this.glory = false});
  @override
  State<ShameScreen> createState() => _ShameScreenState();
}

class _ShameScreenState extends State<ShameScreen> {
  late bool glory = widget.glory;

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final kind = glory ? FlagKind.g : FlagKind.r;
    final col = glory ? K.green : K.acc;
    final rows = <_HallRow>[];
    final total = <String, int>{};
    for (final p in s.people) {
      final es = entriesOf(s.entries, p.id);
      if (es.isEmpty) continue;
      final c = <String, int>{};
      for (final e in es) {
        for (final f in e.flags) {
          if (flagById(f)?.kind == kind) {
            c[f] = (c[f] ?? 0) + 1;
            total[f] = (total[f] ?? 0) + 1;
          }
        }
      }
      final n = c.values.fold(0, (a, b) => a + b);
      if (n == 0) continue;
      final fl = c.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      rows.add(_HallRow(p, es.length, n, n / es.length, fl));
    }
    rows.sort((a, b) => b.rate.compareTo(a.rate));
    final sum = total.values.fold(0, (a, b) => a + b);
    final often = total.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = rows.isEmpty ? null : rows.first;
    final word = glory ? plural(sum, 'зелений прапорець', 'зелені прапорці', 'зелених прапорців') : plural(sum, 'червоний прапорець', 'червоні прапорці', 'червоних прапорців');

    String topLine(_HallRow r) {
      final first = r.flags.first;
      final lead = '${r.n} ${plural(r.n, 'прапорець', 'прапорці', 'прапорців')} за ${_meets(r.meets)}.';
      if (first.value >= 2) return '$lead Найчастіше: ${(flagById(first.key)?.label ?? '').toLowerCase()}, ${first.value} ${plural(first.value, 'раз', 'рази', 'разів')}.';
      return lead;
    }

    String insight() {
      if (often.isEmpty) return '';
      final f = often.first.key;
      final label = flagById(f)?.label ?? f;
      final withF = s.entries.where((e) => e.flags.contains(f)).toList();
      if (!glory) {
        final low = withF.where((e) => e.overall < 3).length;
        return '${flagShort(f)} твій найчастіший червоний прапорець. У $low з ${withF.length} таких вечорів «Як загалом?» було нижче 3.';
      }
      final without = s.entries.where((e) => !e.flags.contains(f)).toList();
      final d = avg(withF.map((e) => e.overall)) - avg(without.map((e) => e.overall));
      if (without.isEmpty || !d.isFinite || d <= 0.05) return '«$label» твій найчастіший зелений прапорець.';
      return 'Коли «${label.toLowerCase()}», «Як загалом?» у середньому на ${fmt(d)} вище. Це твій найсильніший зелений прапорець.';
    }

    return DFrame(
      builder: (context, h) => Stack(children: [
        // фонове світіння
        Positioned(left: -60, top: -80, child: EGlow(w: 520, h: 460, colors: [glory ? K.haze.withValues(alpha: .2) : K.a(.14), const Color(0x0017161F)], stops: const [0, .65])),
        Positioned(left: -180, bottom: -150, child: EGlow(w: 600, h: 520, colors: [col.withValues(alpha: glory ? .2 : .24), const Color(0x0017161F)], stops: const [0, .7])),
        Positioned(right: -200, bottom: -200, child: EGlow(w: 500, h: 520, colors: [K.haze.withValues(alpha: .18), const Color(0x0017161F)], stops: const [0, .7])),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
              SizedBox(
                height: 46,
                child: Stack(alignment: Alignment.center, children: [
                  const Align(alignment: Alignment.centerLeft, child: BackBtn()),
                  Container(
                    width: 210,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(999)),
                    child: Row(children: [
                      for (final x in [(false, 'Ганьба'), (true, 'Слава')])
                        Expanded(
                          child: Semantics(
                            selected: glory == x.$1,
                            button: true,
                            child: Press(
                              onTap: () => setState(() => glory = x.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: easeD,
                                height: 38,
                                decoration: BoxDecoration(color: glory == x.$1 ? K.star : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                                alignment: Alignment.center,
                                child: Text(x.$2, style: rw(13, color: glory == x.$1 ? K.bg : K.muted2, w: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
              Rise(
                key: ValueKey('t$glory'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(glory ? 'Зала слави' : 'Зала ганьби', style: pr(38, h: 1)),
                  const SizedBox(height: 8),
                  Text(sum == 0 ? (glory ? 'Поки жодного зеленого прапорця' : 'Поки жодного червоного прапорця') : '$sum $word · ${rows.length} ${plural(rows.length, 'людина', 'людини', 'людей')}', style: rw(13, color: K.muted2)),
                ]),
              ),
              if (top == null)
                Rise(
                  key: ValueKey('e$glory'),
                  delay: .1,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(22), border: Border.all(color: K.w(.06))),
                    child: Text(
                      glory
                          ? 'Познач у записі, що він зробив добре: провів, питав про межі, слухав. Тут з’явиться той, хто робить це найчастіше.'
                          : 'Тут з’являться ті, хто сидів у телефоні, запізнювався чи говорив тільки про себе. Поки таких немає.',
                      style: rw(14, color: K.soft, h: 1.5),
                    ),
                  ),
                )
              else ...[
                Rise(key: ValueKey('h$glory'), delay: .1, child: _HallHero(r: top, glory: glory, line: topLine(top))),
                if (rows.length > 1)
                  Rise(
                    key: ValueKey('r$glory'),
                    delay: .2,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Рейтинг', style: rw(15, w: FontWeight.w600)), const Spacer(), Text('на зустріч', style: rw(12, color: K.muted2))]),
                      for (var i = 1; i < rows.length; i++) _RankRow(rank: roman[i + 1], r: rows[i], max: top.rate, col: col),
                    ], 8)),
                  ),
                Rise(
                  key: ValueKey('o$glory'),
                  delay: .3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
                      Text('Найчастіше', style: rw(15, w: FontWeight.w600)),
                      for (var i = 0; i < math.min(4, often.length); i++)
                        Row(children: [
                          SizedBox(width: 150, child: Text(flagById(often[i].key)?.label ?? often[i].key, style: rw(13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 10),
                          Expanded(child: _Bar(v: often[i].value / often.first.value, color: col.withValues(alpha: 1 - i * .15), h: 6, track: K.w(.06), delay: .3 + i * .08)),
                          const SizedBox(width: 10),
                          SizedBox(width: 22, child: Text('${often[i].value}', textAlign: TextAlign.right, style: pr(16))),
                        ]),
                    ], 14)),
                  ),
                ),
                Rise(
                  key: ValueKey('i$glory'),
                  delay: .3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: K.w(.025), borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.06))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.only(top: 1), child: Ico(Svgs.star4, size: 20, color: col)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(insight(), style: rw(13, color: const Color(0xFFD7D3E0), h: 1.5))),
                    ]),
                  ),
                ),
              ],
            ], 16)),
          ),
        ),
      ]),
    );
  }
}

class _HallHero extends StatelessWidget {
  final _HallRow r;
  final bool glory;
  final String line;
  const _HallHero({required this.r, required this.glory, required this.line});
  @override
  Widget build(BuildContext context) {
    final col = glory ? K.green : K.acc;
    final fg = glory ? const Color(0xFFE4F3E8) : const Color(0xFFFFE6DE);
    return Press(
      onTap: () => go(context, PersonView(personId: r.p.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: col.withValues(alpha: .3)),
          boxShadow: const [BoxShadow(color: Color(0xE608060E), blurRadius: 44, offset: Offset(0, 22), spreadRadius: -28)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: BoxDecoration(
              color: K.hour,
              gradient: RadialGradient(center: Alignment.topRight, radius: 1.3, colors: [col.withValues(alpha: glory ? .2 : .28), col.withValues(alpha: 0)], stops: const [0, .6]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SizedBox(
                  width: 60, height: 60,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: const Alignment(-.4, -1), end: const Alignment(.4, 1), colors: [col, K.w(.08)], stops: const [0, .7])),
                      child: PAvatar(size: 56, seed: seedOf(r.p.id)),
                    ),
                    if (glory)
                      Positioned(left: -12, top: -19, child: Transform.rotate(angle: -24 * math.pi / 180, child: const SizedBox(width: 40, height: 33, child: Ico(_icCrown, size: 40))))
                    else
                      Positioned(
                        left: -4, top: -14,
                        child: Transform.rotate(
                          angle: -14 * math.pi / 180,
                          alignment: const Alignment(-.7, 1),
                          child: SizedBox(
                            width: 30, height: 38,
                            child: Stack(children: [const Ico(_icFlagPole, size: 38), Positioned(left: 5, top: 3, child: SizedBox(width: 24, height: 16, child: Ico(_icFlagCloth, size: 24)))]),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(glory ? 'Лідер слави' : 'Лідер ганьби', style: rw(12, color: col, w: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(r.p.name, style: pr(30, h: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(fmt(r.rate), style: pr(34, h: 1, ls: -.02)),
                  const SizedBox(height: 5),
                  Text('на зустріч', style: rw(11, color: K.muted2, w: FontWeight.w500)),
                ]),
              ]),
              Container(height: 1, margin: const EdgeInsets.fromLTRB(0, 16, 0, 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [col.withValues(alpha: .35), K.w(0)]))),
              Text(line, style: rw(14, color: const Color(0xFFD7D3E0), h: 1.5)),
              const SizedBox(height: 14),
              Wrap(spacing: 5, runSpacing: 5, children: [
                for (final f in r.flags.take(3))
                  Container(
                    height: 28,
                    padding: const EdgeInsets.fromLTRB(10, 0, 3, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [col.withValues(alpha: .22), col.withValues(alpha: .07)]),
                      border: Border.all(color: (glory ? const Color(0xFFBEE6C8) : const Color(0xFFFFBEAA)).withValues(alpha: .2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(flagShort(f.key), style: rw(12, color: fg, w: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Container(constraints: const BoxConstraints(minWidth: 20), height: 20, padding: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(color: col.withValues(alpha: .2), borderRadius: BorderRadius.circular(999)), alignment: Alignment.center, child: Text('${f.value}', style: rw(11, color: fg, w: FontWeight.w600))),
                    ]),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final String rank;
  final _HallRow r;
  final double max;
  final Color col;
  const _RankRow({required this.rank, required this.r, required this.max, required this.col});
  @override
  Widget build(BuildContext context) => Press(
        onTap: () => go(context, PersonView(personId: r.p.id)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(color: K.hour, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            SizedBox(width: 24, child: Text(rank, textAlign: TextAlign.center, style: pr(18, color: K.muted, h: 1))),
            const SizedBox(width: 12),
            PAvatar(size: 44, seed: seedOf(r.p.id)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.p.name, style: rw(15, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
                  Expanded(child: Text(r.flags.take(2).map((f) => '${flagShort(f.key)} ×${f.value}').join(' · '), style: rw(12, color: K.muted2), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 9),
                _Bar(v: max <= 0 ? 0 : r.rate / max, color: col, h: 3, track: K.bg, delay: .45),
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmt(r.rate), style: pr(22, h: 1)),
              const SizedBox(height: 3),
              Text('з ${_meets(r.meets)}', style: rw(11, color: K.muted)),
            ]),
          ]),
        ),
      );
}

/// Смужка, що виростає зліва (@keyframes grow)
class _Bar extends StatelessWidget {
  final double v, h, delay;
  final Color color, track;
  const _Bar({required this.v, required this.color, required this.h, required this.track, this.delay = 0});
  @override
  Widget build(BuildContext context) => Container(
        height: h,
        decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(h / 2)),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$v$color'),
          tween: Tween(begin: 0, end: v.clamp(0.0, 1.0)),
          duration: Duration(milliseconds: 1000 + (delay * 1000).round()),
          curve: Interval(delay / (1 + delay), 1, curve: easeOut),
          builder: (_, x, __) => FractionallySizedBox(widthFactor: x, child: Container(height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h / 2)))),
        ),
      );
}
