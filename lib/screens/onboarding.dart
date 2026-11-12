import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/store.dart';
import '../logic/astro.dart';
import '../logic/dates.dart';
import '../ui/kit.dart';
import '../ui/pin_pad.dart';
import '../ui/theme.dart';
import 'people.dart';

/// Завершення онбордингу: позначаємо і повертаємось на корінь (там уже головна)
Future<void> finishOnboarding(BuildContext context) async {
  await Store.read(context).updateProfile((p) => p.onboarded = true);
  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
}

class Welcome extends StatefulWidget {
  const Welcome({super.key});
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool adult = false;
  @override
  Widget build(BuildContext context) => Screen(
        scroll: false,
        footer: [Btn('Почати', onTap: adult ? () => go(context, const AboutYou()) : null)],
        children: [
          const Spacer(),
          const Logo(size: 46),
          Text.rich(
            TextSpan(text: 'Щоденник побачень, який з кожним записом ', children: [TextSpan(text: 'краще знає, що тобі подобається.', style: TextStyle(color: C.accentSoft))]),
            style: T.serif(30),
          ),
          const Txt('Записи живуть тільки на твоєму телефоні. Без акаунта, без пошти, без серверів.', muted: true),
          const Spacer(),
          VCard(
            onTap: () => setState(() => adult = !adult),
            border: adult ? C.accent : C.line2,
            color: Colors.transparent,
            child: Row(children: [
              Checkbox(value: adult, onChanged: (v) => setState(() => adult = v ?? false), activeColor: C.accent, checkColor: C.bg, side: const BorderSide(color: C.haze, width: 1.5)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Мені є 18 років', style: T.body(15, C.text, FontWeight.w600)),
                  const Txt('Тут відверто про секс і стосунки.', small: true, muted: true),
                ]),
              ),
            ]),
          ),
        ],
      );
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = maskDate(newValue.text);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

final dateFormatter = _DateFormatter();

/// Картка «Твоя карта»: знак і аркан
class AstroCard extends StatelessWidget {
  final Astro a;
  final bool full;
  const AstroCard(this.a, {super.key, this.full = true});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF08A6C), Color(0xFFC9796E), Color(0xFF5E5674), Color(0xFF2B2836)], stops: [0, .38, .78, 1]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('✦ Твоя карта', style: T.body(12, C.text, FontWeight.w600)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            SizedBox(width: 80, child: Txt('Знак', small: true, color: C.text.withValues(alpha: .75))),
            Text(a.signName, style: T.serif(28)),
          ]),
          if (a.arc != null)
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              SizedBox(width: 80, child: Txt('Аркан ${a.romanNum}', small: true, color: C.text.withValues(alpha: .75))),
              Expanded(child: Text(a.arcanaName!, style: T.serif(28))),
            ]),
          if (full && a.arc != null) ...[
            const SizedBox(height: 10),
            Txt('${arcana[a.arc!].core} ${arcana[a.arc!].love}'),
          ],
        ]),
      );
}

/// «Трохи про тебе» — і в онбордингу, і з налаштувань
class AboutYou extends StatefulWidget {
  const AboutYou({super.key});
  @override
  State<AboutYou> createState() => _AboutYouState();
}

class _AboutYouState extends State<AboutYou> {
  late final TextEditingController name, date;
  @override
  void initState() {
    super.initState();
    final p = Store.read(context).profile;
    name = TextEditingController(text: p.name);
    date = TextEditingController(text: toUA(p.birth));
  }

  @override
  void dispose() {
    name.dispose();
    date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Store.of(context);
    final iso = parseUA(date.text);
    final a = iso == null ? null : astroOf(iso);
    final ok = name.text.trim().isNotEmpty && iso != null;
    return Screen(
      footer: [
        Btn(store.profile.onboarded ? 'Зберегти' : 'Далі', onTap: !ok ? null : () async {
          await store.updateProfile((p) { p.name = name.text.trim(); p.birth = iso; });
          if (!context.mounted) return;
          if (store.profile.onboarded) {
            Navigator.pop(context);
          } else {
            go(context, const SetupScreen());
          }
        }),
      ],
      children: [
        const Header(),
        const H1('Трохи', accent: 'про тебе'),
        const Txt("Ім'я бачиш тільки ти. За датою покажемо знак і аркан.", muted: true),
        Field(label: 'Як тебе звати', hint: "Ім'я", controller: name, onChanged: (_) => setState(() {})),
        Field(label: 'Дата народження', hint: 'ДД.ММ.РРРР', controller: date, keyboard: TextInputType.number, formatters: [dateFormatter], onChanged: (_) => setState(() {})),
        if (date.text.length == 10 && iso == null) const Txt('Перевір дату', small: true, color: C.red),
        if (a != null) AstroCard(a),
      ],
    );
  }
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = Store.of(context);
    final p = store.profile;
    return Screen(
      footer: [
        Btn('Далі', onTap: () {
          if (p.pinEnabled) {
            go(context, const PinNewScreen(onboarding: true));
          } else {
            go(context, const PersonEdit(onboarding: true));
          }
        }),
      ],
      children: [
        const Header(),
        const H1('З ким ти', accent: 'зустрічаєшся?'),
        Seg<String>(options: [for (final d in datingOptions) SegOpt(d.id, d.label)], value: p.dating, onChange: (v) => store.updateProfile((x) => x.dating = v)),
        const Label('Приватність'),
        VCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SwitchRow(title: 'PIN-код або відбиток', sub: 'Питаємо щоразу, коли відкриваєш Vespr', value: p.pinEnabled, onChanged: (v) => store.updateProfile((x) => x.pinEnabled = v)),
        ),
        const Txt('Без акаунта і пошти. Якщо забудеш PIN, увійти можна тільки скинувши дані, тож краще ввімкни і відбиток.', small: true, muted: true),
      ],
    );
  }
}

class PinNewScreen extends StatelessWidget {
  final bool onboarding;
  const PinNewScreen({super.key, this.onboarding = false});
  @override
  Widget build(BuildContext context) => Screen(
        scroll: false,
        children: [
          const Header(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: PinEntry(
                  create: true,
                  onDone: () async {
                    await Store.read(context).updateProfile((p) => p.pinEnabled = true);
                    if (!context.mounted) return;
                    if (onboarding) {
                      goReplace(context, const PersonEdit(onboarding: true));
                    } else {
                      toast(context, 'PIN збережено');
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      );
}
