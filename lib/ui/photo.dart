// Фото людей. Зберігаються тільки на телефоні: маленький JPEG (до 360 px) у base64
// прямо в записі людини (той самий JSON у SharedPreferences, що й решта даних),
// тож потрапляють у резервну копію разом з людиною і зникають разом з нею.
// Показуються розмитими, поки в налаштуваннях увімкнено «Розмивати фото».
// Немає фото — малюємо градієнтну «пляму», як на дошках.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models.dart';
import '../data/store.dart';
import 'd.dart';

/// Яка «пляма» в людини без фото: демо-люди мають свої з макета, решта — за id
int seedOf(String id) => const {'p_arch': 0, 'p_mark': 1, 'p_d': 2}[id] ?? id.codeUnits.fold<int>(0, (a, b) => a + b);

final _cache = <String, (String, Uint8List)>{};

/// Байти фото людини (декодуємо base64 один раз)
Uint8List? photoBytes(Person? p) {
  final src = p?.photo;
  if (p == null || src == null || src.isEmpty) return null;
  final c = _cache[p.id];
  if (c != null && identical(c.$1, src)) return c.$2;
  try {
    final b = base64Decode(src);
    _cache[p.id] = (src, b);
    return b;
  } catch (_) {
    return null;
  }
}

/// Налаштування «Розмивати фото» (за замовчуванням увімкнено)
bool blurPhotos(AppStore? s) => s == null || (s.profile.counters['opt:blur'] ?? 1) == 1;

/// Вибрати фото з галереї: одразу зменшуємо до 360 px, щоб не роздувати сховище
Future<String?> pickPersonPhoto(BuildContext context) async {
  try {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 360, maxHeight: 360, imageQuality: 78, requestFullMetadata: false);
    if (x == null) return null;
    final b = await x.readAsBytes();
    if (b.length > 600 * 1024) {
      if (context.mounted) dToast(context, 'Фото завелике, вибери інше');
      return null;
    }
    return base64Encode(b);
  } catch (_) {
    if (context.mounted) dToast(context, 'Не вдалось відкрити фото');
    return null;
  }
}

const _greyM = <double>[.5346, .4058, .0596, 0, 0, .1846, .7558, .0596, 0, 0, .1846, .4058, .4096, 0, 0, 0, 0, 0, 1, 0];
const _dimM = <double>[.85, 0, 0, 0, 0, 0, .85, 0, 0, 0, 0, 0, .85, 0, 0, 0, 0, 0, 1, 0];

/// Фото людини (або пляма). [anon] — завжди пляма (для картинок, якими діляться).
/// [sharp] — без розмиття навіть якщо воно увімкнене («Показати фото»).
class PPhoto extends StatelessWidget {
  final String? pid;
  final Uint8List? bytes;
  final int? seed;
  final double w, h, radius, blur;
  final bool circle, grey, sharp, anon;
  const PPhoto({super.key, this.pid, this.bytes, this.seed, required this.w, required this.h, this.radius = 20, this.blur = 4, this.circle = false, this.grey = false, this.sharp = false, this.anon = false});

  @override
  Widget build(BuildContext context) {
    final st = context.dependOnInheritedWidgetOfExactType<Store>()?.notifier;
    final b = anon ? null : (bytes ?? (pid == null ? null : photoBytes(st?.person(pid!))));
    final sd = seed ?? (pid == null ? 0 : seedOf(pid!));
    if (b == null) return Blob(seed: sd, w: w, h: h, radius: radius, blur: blur, circle: circle, grey: grey);
    Widget x = Image.memory(b, width: w, height: h, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium);
    if (!sharp && blurPhotos(st)) {
      // достатньо, щоб обличчя не впізнавалось, але настрій фото лишався
      final sg = math.max(2.5, math.max(w, h) / 14);
      x = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: sg, sigmaY: sg, tileMode: TileMode.mirror), child: x);
    }
    if (grey) x = ColorFiltered(colorFilter: const ColorFilter.matrix(_greyM), child: ColorFiltered(colorFilter: const ColorFilter.matrix(_dimM), child: x));
    return SizedBox(width: w, height: h, child: circle ? ClipOval(child: x) : ClipRRect(borderRadius: BorderRadius.circular(radius), child: x));
  }
}

/// Кругла аватарка людини
class PAvatar extends StatelessWidget {
  final double size;
  final int seed;
  final String? pid;
  final bool anon;
  const PAvatar({super.key, this.size = 22, this.seed = 0, this.pid, this.anon = false});
  @override
  Widget build(BuildContext context) => PPhoto(pid: pid, seed: pid == null ? seed : null, w: size, h: size, circle: true, blur: size / 12, anon: anon);
}

/// Чи є в людини справжнє фото
bool hasPhoto(Person? p) => photoBytes(p) != null;
