import 'package:flutter/material.dart';

import '../ui/theme.dart';
import 'home.dart';
import 'map.dart';
import 'people.dart';

/// Нижня навігація: Головна · Люди · Мапа
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: IndexedStack(index: tab, children: [HomeTab(onTab: (i) => setState(() => tab = i)), const PeopleTab(), const MapTab()]),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xFF1D1B27),
            indicatorColor: C.accentBg,
            labelTextStyle: WidgetStateProperty.resolveWith((s) => T.body(11, s.contains(WidgetState.selected) ? C.text : C.haze, FontWeight.w500)),
            iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.accent : C.haze)),
          ),
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            height: 68,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.wb_twilight_rounded), label: 'Головна'),
              NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Люди'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Мапа'),
            ],
          ),
        ),
      );
}
