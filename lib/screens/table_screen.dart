import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../logic/dates.dart';
import '../ui/board.dart';
import '../ui/d.dart';
import '../ui/kit.dart' show go;
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

    return DScroll(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 24),
      bottom: Row(children: [
        Expanded(child: GhostBtn('Імпорт', onTap: () => go(context, const ImportScreen()))),
        const SizedBox(width: 8),
        Expanded(child: CtaIco('Експорт', height: 48, size: 15, onTap: () => go(context, const ExportScreen()))),
      ]),
      children: [
        BoardHeader('Таблиця', right: IconBtn(svg: BS.download, label: 'Експорт', onTap: () => go(context, const ExportScreen()))),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          titleAcc(const [('Усі записи\n', false), ('одним списком', true)], 34),
          const SizedBox(height: 8),
          Text('Тапни на стовпець, щоб відсортувати. Тапни на рядок, щоб відкрити запис.', style: rw(14, color: K.muted, h: 1.5)),
        ]),
        if (withEntries.length > 1)
          chipsWrap([
            DChip('Усі', on: who == null, onTap: () => setState(() => who = null)),
            for (final p in withEntries) DChip(p.name, on: who == p.id, onTap: () => setState(() => who = p.id)),
          ]),
        if (rows.isEmpty)
          Press(
            onTap: () => go(context, const ImportScreen()),
            child: NoteBox('Записів поки нема. Вела раніше в таблиці чи календарі? Перенеси їх сюди ›', svg: BS.upload),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('${rows.length} ${plural(rows.length, 'запис', 'записи', 'записів')} · середня ${fmt(mean)}', style: rw(12, color: K.haze)),
          ),
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
    final label = Text('$t${on ? (desc ? ' ↓' : ' ↑') : ''}', style: rw(11, color: on ? K.star : K.muted, w: FontWeight.w600, ls: .44));
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
            child: Text(t, style: num ? pr(16, h: 1.1) : rw(muted ? 12 : 13, color: muted ? K.muted : K.star, w: FontWeight.w500)),
          ),
        ),
      );

  Widget _pills(Entry e, VoidCallback onTap) {
    int count(FlagKind k) => e.flags.where((f) => flagById(f)?.kind == k).length;
    final g = count(FlagKind.g), r = count(FlagKind.r) + count(FlagKind.c);
    Widget pill(int n, Color c) => Container(
          constraints: const BoxConstraints(minWidth: 18),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: c.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
          child: Text('$n', textAlign: TextAlign.center, style: rw(11, color: c, w: FontWeight.w600)),
        );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(mainAxisSize: MainAxisSize.min, children: [pill(g, K.green), const SizedBox(width: 4), pill(r, K.red)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String tagsOf(Entry e) {
      final t = e.tags.where((x) => !sensitiveTags.contains(x)).map(tagLabel).toList();
      return t.isEmpty ? '—' : (t.length > 3 ? '${t.take(3).join(', ')}…' : t.join(', '));
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: K.card2, borderRadius: BorderRadius.circular(20), border: Border.all(color: K.w(.06))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(horizontalInside: BorderSide(color: K.w(.06))),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: K.hour),
              children: [
                _head('Дата', by: _Sort.date),
                _head('Людина'),
                _head('Загалом', by: _Sort.overall, right: true),
                _head('Секс', right: true),
                _head('Прапорці'),
                _head('Що було'),
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
    );
  }
}
