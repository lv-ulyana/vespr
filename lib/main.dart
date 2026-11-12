import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/store.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'services/pin.dart';
import 'ui/pin_pad.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  final store = AppStore();
  await store.load();
  runApp(Store(store: store, child: const VesprApp()));
}

class VesprApp extends StatelessWidget {
  const VesprApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vespr',
        debugShowCheckedModeBanner: false,
        theme: vesprTheme(),
        locale: const Locale('uk'),
        supportedLocales: const [Locale('uk'), Locale('en')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        // Блокування лежить поверх усієї навігації, тож закриває будь-який відкритий екран
        builder: (context, child) => LockLayer(child: child ?? const SizedBox()),
        home: const Root(),
      );
}

class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) => Store.of(context).profile.onboarded ? const Shell() : const Welcome();
}

/// PIN-код поверх апки. Через 30 секунд у фоні апка блокується знову.
class LockLayer extends StatefulWidget {
  final Widget child;
  const LockLayer({super.key, required this.child});
  @override
  State<LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends State<LockLayer> with WidgetsBindingObserver {
  static const relock = Duration(seconds: 30);
  bool unlocked = false;
  bool? pinExists;
  DateTime? away;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  Future<void> _check() async {
    final v = await PinService.hasPin();
    if (mounted) setState(() => pinExists = v);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) away = DateTime.now();
    if (state == AppLifecycleState.resumed && away != null && DateTime.now().difference(away!) > relock) {
      setState(() { unlocked = false; pinExists = null; });
      _check();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Store.of(context).profile;
    // Під час онбордингу PIN щойно створено — не просимо його одразу ж ввести
    if (!p.onboarded) unlocked = true;
    final locked = p.onboarded && p.pinEnabled && !unlocked;
    return Stack(children: [
      widget.child,
      if (locked)
        Positioned.fill(
          child: Scaffold(
            backgroundColor: C.bg,
            body: pinExists == null
                ? const SizedBox()
                : SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Logo(),
                          const SizedBox(height: 28),
                          PinEntry(
                            key: ValueKey(pinExists),
                            // PIN увімкнено, але його нема (дані відновились на новому телефоні) — задаємо новий
                            create: !pinExists!,
                            createHint: 'Дані відновлено. На новому телефоні PIN треба задати знову.',
                            onDone: () => setState(() { unlocked = true; pinExists = true; }),
                          ),
                        ]),
                      ),
                    ),
                  ),
          ),
        ),
    ]);
  }
}
