// Веб-версія: віддати файл браузеру як завантаження (запасний шлях, якщо «Поділитися» недоступне).
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadBytes(List<int> bytes, String name, String mime) {
  final blob = web.Blob(<web.BlobPart>[Uint8List.fromList(bytes).toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(a);
  a.click();
  a.remove();
  Future<void>.delayed(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}
