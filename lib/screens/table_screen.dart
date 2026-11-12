import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../ui/kit.dart';
import '../ui/theme.dart';
import 'entry.dart';
import 'export_screen.dart';
import 'import_screen.dart';

/// Усі записи таблицею. Фільтр по людині, сортування за датою чи оцінкою, тап — відкрити запис.
/// Дизайн: дошка «14.1 Усі записи таблицею».
class TableScreen extends StatefulWidget {
  final String? personId;
  const TableScreen({super.key, this.personId});
  @override
  State<TableScreen> createState() => _TableScreenState();
}

enum _Sort { date, overall }

class _TableScreenState extends State<TableScreen> {
  late String? who = widget.personId;
  _Sort sort = _Sort.date;
  bool desc = true;

  void _tapSort(_Sort s) => setState(() {
        if (sort == s) {
          desc = !desc;
        } else {
          sort = s;
          desc = true;
        }
      });

  @override
  Widget build(BuildContext context) {
    final s = Store.of(context);
    final withEntries = s.people.where((p) => s.entries.any((e) => e.personId == p.id)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final rows = s.entries.where((e) => who == null || e.personId == who).toList();
    int cmp(Entry a, Entry b) {
      final c = sort == _Sort.date ? a.date.compareTo(b.date) : a.overall.compareTo(b.overall);
      final r = c != 0 ? c : a.date.compareTo(b.date);
      return desc ? -r : r;
    }

    rows.sort(cmp);
    final mean = rows.isEmpty ? 0.0 : rows.map((e) => e.overall).reduce((a, b) => a + b) / rows.length;

    return Screen(
      footer: [
        Row(children: [
          Expanded(child: Btn('Імпорт', kind: BtnKind.ghost, icon: Icons.file_upload_outlined, onTap: () => go(context, const ImportScreen()))),
          const SizedBox(width: 8),
          Expanded(child: Btn('Експорт', icon: Icons.file_download_outlined, onTap: () => go(context, const ExportScreen()))),
        ]),
      ],
      children: [
        const Header(title: 'Таблиця'),
        const H1('Усі записи', accent: 'одним списком'),
        const Txt('Тапни на стовпець, щоб відсортувати. Тапни на рядок, щоб відкрити запис.', muted: true),
        if (withEntries.length > 1)
          Chips([
            ChipX('Усі', on: who == null, onTap: () => setState(() => who = null)),
            for (final p in withEntries) ChipX(p.name, on: who == p.id, onTap: () => setState(() => who = p.id)),
          ]),
        if (rows.isEmpty)
          VCard(
            onTap: () => go(context, const ImportScreen()),
            child: const Txt('Записів поки нема. Вела раніше в таблиці чи календарі? Перенеси їх сюди ›', muted: true),
          )
        else
          _Grid(
            rows: rows,
            names: {for (final p in s.people) p.id: p.name},
            sort: sort,
            desc: desc,
            onSort: _tapSort,
            onOpen: (e) => go(context, EntryView(entryId: e.id)),
          ),
        if (rows.isNotEmpty)
          Txt('${rows.length} ${plural(rows.length, 'запис', 'записи', 'записів')} · середня ${fmt(mean)}', small: true, muted: true),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Entry> rows;
  final Map<String, String> names;
  final _Sort sort;
  final bool desc;
  final ValueChanged<_Sort> onSort;
  final ValueChanged<Entry> onOpen;
  const _Grid({required this.rows, required this.names, required this.sort, required this.desc, required this.onSort, required this.onOpen});

  Widget _head(String t, {_Sort? by, bool right = false}) {
    final on = by != null && by == sort;
    final label = Text('$t${on ? (desc ? ' ↓' : ' ↑') : ''}', style: T.body(11, on ? C.text : C.muted, FontWeight.w600));
    final cell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Align(alignment: right ? Alignment.centerRight : Alignment.centerLeft, child: label),
    );
    if (by == null) return cell;
    return Semantics(button: true, label: 'Сортувати: $t', child: InkWell(onTap: () => onSort(by), child: cell));
  }

  Widget _cell(String t, {bool num = false, bool muted = false, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Align(
            alignment: num ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(t, style: num ? T.serif(16) : T.body(muted ? 12 : 13, muted ? C.muted : C.text, FontWeight.w500)),
          ),
        ),
      );

  Widget _pills(Entry e, VoidCallback onTap) {
    int count(FlagKind k) => e.flags.where((f) => flagById(f)?.kind == k).length;
    final g = count(FlagKind.g), r = count(FlagKind.r) + count(FlagKind.c);
    Widget pill(int n, Color c) => Container(
          constraints: const BoxConstraints(minWidth: 20),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: c.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
          child: Text('$n', textAlign: TextAlign.center, style: T.body(11, c, FontWeight.w600)),
        );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(mainAxisSize: MainAxisSize.min, children: [pill(g, C.green), const SizedBox(width: 4), pill(r, C.red)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String tagsOf(Entry e) {
      final t = e.tags.where((x) => !sensitiveTags.contains(x)).map(tagLabel).toList();
      return t.isEmpty ? '—' : (t.length > 3 ? '${t.take(3).join(', ')}…' : t.join(', '));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: C.card,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(horizontalInside: BorderSide(color: C.line)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: C.surface),
                children: [
                  _head('ДАТА', by: _Sort.date),
                  _head('ЛЮДИНА'),
                  _head('ЗАГАЛОМ', by: _Sort.overall, right: true),
                  _head('СЕКС', right: true),
                  _head('ПРАПОРЦІ'),
                  _head('ЩО БУЛО'),
                ],
              ),
              for (final e in rows)
                TableRow(children: [
                  _cell(toUA(e.date), muted: true, onTap: () => onOpen(e)),
                  _cell(names[e.personId] ?? '—', onTap: () => onOpen(e)),
                  _cell('${e.overall}', num: true, onTap: () => onOpen(e)),
                  _cell(e.hadSex ? '${e.ratings['sx_overall'] ?? e.overall}' : '—', num: true, onTap: () => onOpen(e)),
                  _pills(e, () => onOpen(e)),
                  _cell(tagsOf(e), muted: true, onTap: () => onOpen(e)),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
