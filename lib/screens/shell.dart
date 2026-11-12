import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../ui/d.dart';
import 'awards.dart';
import 'home.dart';
import 'map.dart';
import 'people.dart';

const _icHome = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/></svg>';
const _icPeople = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9" r="2.5"/><path d="M16 14.5a5 5 0 0 1 5.5 5"/></svg>';
const _icMap = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z"/></svg>';
const _icAward = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="9" r="6"/><path d="M8.5 13.8L7 22l5-2.6 5 2.6-1.5-8.2"/></svg>';

/// Нижня навігація з макета: плаваюча «пігулка» з розмиттям, 4 вкладки
class Shell extends StatefulWidget {
  final int initial;
  const Shell({super.key, this.initial = 0});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int tab = widget.initial;

  @override
  Widget build(BuildContext context) {
    const tabs = [(_icHome, 'Головна'), (_icPeople, 'Люди'), (_icMap, 'Мапа'), (_icAward, 'Нагороди')];
    return DFrame(
      builder: (context, h) => Stack(children: [
        Positioned.fill(
          child: IndexedStack(index: tab, children: [
            HomeTab(onTab: (i) => setState(() => tab = i)),
            const PeopleTab(),
            MapTab(onTab: (i) => setState(() => tab = i)),
            const AwardsTab(),
          ]),
        ),
        Positioned(
          left: 20, right: 20, bottom: 22,
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xDB2B2836),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: K.w(.08)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    for (var i = 0; i < tabs.length; i++)
                      Semantics(
                        selected: tab == i,
                        child: Press(
                          onTap: () => setState(() => tab = i),
                          child: SizedBox(
                            width: 64, height: 56,
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Ico(tabs[i].$1, size: 22, color: tab == i ? K.star : K.muted2),
                              const SizedBox(height: 4),
                              Text(tabs[i].$2, style: rw(11, color: tab == i ? K.star : K.muted2, w: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
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
