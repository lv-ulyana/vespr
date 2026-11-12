import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../logic/export.dart';
import '../logic/stats.dart';
import '../logic/texts.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'calendar.dart';
import 'entry.dart';
import 'people.dart';
import 'settings.dart';
import 'wrapped.dart';

String _greet() {
  final h = DateTime.now().hour;
  return h < 5 ? 'Доброї ночі' : h < 12 ? 'Доброго ранку' : h < 18 ? 'Привіт' : 'Добрий вечір';
}

class HomeTab extends StatelessWidget {
  final ValueChanged<int> onTab;
  const HomeTab({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final p = s.profile;
    final month = monthKey(today());
    final monthEntries = s.entries.where((e) => monthKey(e.date) == month).toList();
    final limitHit = !p.premium && monthEntries.length >= freeEntriesPerMonth;

    String insight;
    if (s.entries.length < 3) {
      insight = fewText(3 - s.entries.length);
    } else {
      final eff = effects(s.entries);
      final f = formula(eff);
      if (f.length == 3) {
        insight = say('formula', {'t1': f[0].label.toLowerCase(), 't2': f[1].label.toLowerCase(), 't3': f[2].label.toLowerCase()});
      } else if (eff.isEmpty) {
        insight = 'Поки жодна звичка не вибивається. Записуй далі.';
      } else {
        final top = eff.first;
        insight = top.delta > 0
            ? say('tagUp', {'tag': top.label.toLowerCase(), 'd': d1(top.delta)}, top.id)
            : say('tagDown', {'tag': top.label, 'd': d1(top.delta), 'n': top.nWith}, top.id);
      }
    }

    final recent = [...s.entries]..sort((a, b) => b.date != a.date ? b.date.compareTo(a.date) : b.createdAt.compareTo(a.createdAt));
    final now = DateTime.now();
    final prevMonth = iso(DateTime(now.year, now.month - 1, 1)).substring(0, 7);
    final prevCount = s.entries.where((e) => monthKey(e.date) == prevMonth).length;
    final next = plannedMeetings(s.meetings);
    // минулі зустрічі (зокрема з імпорту календаря), про які ще нема запису — за останні 60 днів
    final unrated = unratedMeetings(s.meetings, s.entries).where((m) => daysBetween(m.date, today()) <= 60).toList();

    return Screen(children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Txt(_greet(), muted: true),
            Text(p.name.isEmpty ? 'ти' : p.name, style: T.serif(30)),
          ]),
        ),
        RoundIcon(icon: Icons.calendar_month_outlined, label: 'Календар', onTap: () => go(context, const CalendarScreen())),
        const SizedBox(width: 8),
        Semantics(button: true, label: 'Налаштування', child: GestureDetector(onTap: () => go(context, const SettingsScreen()), child: Avatar(p.name.isEmpty ? 'V' : p.name, size: 44))),
      ]),
      VCard(
        color: C.warm,
        border: const Color(0x40F08A6C),
        onTap: s.entries.length >= 3 ? () => onTab(2) : null,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('✦ Твоя мапа каже', style: T.body(12, C.accentSoft, FontWeight.w600)),
          const SizedBox(height: 6),
          Text(insight, style: T.serif(19).copyWith(height: 1.4)),
        ]),
      ),
      if (next.isNotEmpty)
        VCard(
          onTap: () => go(context, MeetingForm(meetingId: next.first.id)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('До зустрічі', style: T.body(12, C.accent, FontWeight.w600)),
                Text('${s.personName(next.first.personId)}, ${next.first.date == today() ? 'сьогодні' : human(next.first.date)} ${next.first.time}', style: T.serif(20)),
                if (next.first.place != null) Txt(placeLabel(next.first.place), small: true, muted: true),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.haze),
          ]),
        ),
      if (unrated.isNotEmpty && !limitHit)
        VCard(
          onTap: () => go(context, EntryForm(personId: unrated.first.personId, date: unrated.first.date)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Лишилось оцінити', style: T.body(12, C.accent, FontWeight.w600)),
                Text('${s.personName(unrated.first.personId)}, ${human(unrated.first.date)}', style: T.serif(20)),
                if (unrated.length > 1) Txt('і ще ${unrated.length - 1} ${plural(unrated.length - 1, 'зустріч', 'зустрічі', 'зустрічей')}', small: true, muted: true),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.haze),
          ]),
        ),
      if (limitHit)
        VCard(
          border: C.accent,
          onTap: () => go(context, const PaywallScreen()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$freeEntriesPerMonth з $freeEntriesPerMonth записів цього місяця', style: T.body(15, C.text, FontWeight.w600)),
            const Txt('Нові записи відкриються 1-го числа. Або вже зараз з Premium.', small: true, muted: true),
          ]),
        )
      else
        Btn('Записати зустріч', icon: Icons.edit_note_rounded, onTap: () => go(context, s.people.isEmpty ? const PersonEdit() : const EntryForm())),
      Row(children: [
        StatTile(monthsNom[now.month - 1], '${monthEntries.length}', suffix: p.premium ? null : ' з $freeEntriesPerMonth'),
        const SizedBox(width: 10),
        StatTile('середня', monthEntries.isEmpty ? '—' : fmt(avg(monthEntries.map((e) => e.overall))), suffix: monthEntries.isEmpty ? null : '/5'),
      ]),
      if (prevCount > 0 || monthEntries.isNotEmpty)
        VCard(
          color: C.pink,
          border: Colors.transparent,
          onTap: () => go(context, WrappedScreen(month: prevCount > 0 ? prevMonth : month)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Wrapped', style: T.onest(24, C.navy)),
            const SizedBox(height: 4),
            Text(prevCount > 0 ? 'Твій ${monthsNom[DateTime(now.year, now.month - 1).month - 1]} готовий ›' : '${cap(monthsNom[now.month - 1])} поки збирається ›', style: T.body(14, C.navy, FontWeight.w600)),
          ]),
        ),
      if (recent.isNotEmpty) const Label('Останні записи'),
      for (final e in recent.take(5))
        VCard(
          padding: const EdgeInsets.all(12),
          onTap: () => go(context, EntryView(entryId: e.id)),
          child: Row(children: [
            Avatar(s.personName(e.personId)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.personName(e.personId), style: T.body(15, C.text, FontWeight.w600)),
                Txt('${human(e.date)}${e.hadSex ? ' · був секс' : ''}', small: true, muted: true),
              ]),
            ),
            Text('${e.overall}', style: T.serif(22, C.accentSoft)),
          ]),
        ),
      if (s.entries.isEmpty)
        VCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Перший запис', style: T.body(15, C.text, FontWeight.w600)),
            const Txt('Після трьох записів покажемо, що тобі справді подобається. Кожен запис запалює зірку.', small: true, muted: true),
          ]),
        ),
    ]);
  }
}
