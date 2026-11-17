// Підписка Premium через App Store (і Google Play) — пакет in_app_purchase.
// Сервера нема, тож строк дії рахуємо з дати останньої транзакції + період підписки (+3 дні запасу).
// Продовження App Store надсилає новою транзакцією при запуску апки — тоді строк зсувається далі.
// У веб-версії і в тестах оплати нема: available == false.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/store.dart';

class Purchases {
  static const monthly = 'app.vespr.premium.monthly';
  static const yearly = 'app.vespr.premium.yearly';
  static const ids = {monthly, yearly};

  static bool get available => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  static AppStore? _store;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static final products = <String, ProductDetails>{};

  /// Повідомлення для екрана оплати (помилка покупки тощо)
  static final message = ValueNotifier<String?>(null);

  /// Йде покупка: показуємо очікування на кнопці
  static final busy = ValueNotifier<bool>(false);

  static Future<void> init(AppStore store) async {
    _store = store;
    expireCheck();
    if (!available) return;
    try {
      _sub ??= InAppPurchase.instance.purchaseStream.listen(_onUpdates, onError: (_) => busy.value = false);
      if (await InAppPurchase.instance.isAvailable()) await _loadProducts();
    } catch (_) {}
  }

  static Future<void> _loadProducts() async {
    final r = await InAppPurchase.instance.queryProductDetails(ids);
    for (final p in r.productDetails) {
      products[p.id] = p;
    }
  }

  /// Ціна з магазину (у валюті людини) або запасна з дизайну
  static String price(String id, String fallback) => products[id]?.price ?? fallback;

  /// Минув строк — вимикаємо Premium (продовження прийде новою транзакцією)
  static void expireCheck() {
    final s = _store;
    if (s == null || !s.profile.premium) return;
    final until = s.profile.counters['premUntil'] ?? 0;
    if (until > 0 && until < DateTime.now().millisecondsSinceEpoch) {
      s.updateProfile((p) => p.premium = false);
    }
  }

  static Future<void> _onUpdates(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (!ids.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant(p);
          busy.value = false;
        case PurchaseStatus.error:
          busy.value = false;
          message.value = 'Оплата не пройшла. Гроші не списано, спробуй ще раз.';
        case PurchaseStatus.canceled:
          busy.value = false;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  static Future<void> _grant(PurchaseDetails p) async {
    final s = _store;
    if (s == null) return;
    final ms = int.tryParse(p.transactionDate ?? '') ?? DateTime.now().millisecondsSinceEpoch;
    final days = p.productID == yearly ? 366 : 31;
    final until = DateTime.fromMillisecondsSinceEpoch(ms).add(Duration(days: days + 3)).millisecondsSinceEpoch;
    if (until < DateTime.now().millisecondsSinceEpoch) return; // стара, вже закінчена підписка
    if (until <= (s.profile.counters['premUntil'] ?? 0) && s.profile.premium) return;
    await s.updateProfile((x) {
      x.premium = true;
      x.counters['premUntil'] = until;
      x.counters['premPlan'] = p.productID == yearly ? 12 : 1;
    });
  }

  /// Купити: результат прийде через purchaseStream. Повертає текст помилки або null.
  static Future<String?> buy(bool year) async {
    if (!available) return null;
    try {
      if (!await InAppPurchase.instance.isAvailable()) return 'App Store зараз недоступний. Перевір інтернет і спробуй ще раз.';
      if (products.isEmpty) await _loadProducts();
      final pd = products[year ? yearly : monthly];
      if (pd == null) return 'Не вдалося завантажити підписку з App Store. Спробуй трохи пізніше.';
      busy.value = true;
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
      return null;
    } catch (_) {
      busy.value = false;
      return 'Оплата не пройшла. Гроші не списано, спробуй ще раз.';
    }
  }

  /// Відновити покупки: чекаємо відповіді магазину кілька секунд. true — Premium активний.
  static Future<bool> restore() async {
    if (!available) return false;
    try {
      await InAppPurchase.instance.restorePurchases();
      for (var i = 0; i < 16; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (_store?.profile.premium == true) return true;
      }
    } catch (_) {}
    return _store?.profile.premium == true;
  }
}
