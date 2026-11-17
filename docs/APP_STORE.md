# Vespr → App Store: що готово і що лишилось

## Вже в коді
- **Оплата через Apple** (`lib/services/purchases.dart`, пакет `in_app_purchase`). Тестового Premium більше нема.
  - ID підписок: `app.vespr.premium.monthly` ($6.99/міс) і `app.vespr.premium.yearly` ($39.99/рік).
  - «Відновити покупки» справді питає App Store.
  - Строк дії: дата останньої транзакції + період (+3 дні запасу). Продовження App Store надсилає при запуску апки.
- **Пейвол без вигаданих фактів.** Справжні закономірності, коли їх 2+, інакше — що саме порахує Premium.
  - Під кнопкою: списання з Apple ID, автопродовження, як скасувати, посилання на Умови і Приватність.
- **«Подивитись на прикладі» на першому екрані.** Вигадані люди й записи без Premium. Вийти: Налаштування → «Почати своє».
- **Публічні сторінки** (з `lib/data/legal.dart`, генерує `tool/legal_pages.py` під час збірки):
  - https://lv-ulyana.github.io/vespr/privacy.html (+ `privacy-uk.html`)
  - https://lv-ulyana.github.io/vespr/terms.html (+ `terms-uk.html`)
- **`tool/setup.sh` для iOS:**
  - тільки iPhone;
  - тексти дозволів англійською (Info.plist) і українською (uk.lproj);
  - `PrivacyInfo.xcprivacy`.

## Перед відправкою (потрібен акаунт Apple Developer)
1. Заповнити в політиці й умовах назву (ФОП/компанія), країну і контактний email (окремий, не особистий). Зараз там позначки ⟦…⟧.
2. App Store Connect → підписки:
   - одна група «Vespr Premium», дві підписки з ID вище, ціни;
   - локалізації назв (en, uk).
3. App Privacy: «Data Not Collected».
4. Вікова категорія: відверті сексуальні теми (часто/інтенсивно) → 18+.
5. Privacy Policy URL і Terms (EULA) URL — посилання вище. У описі апки також посилання на Terms of Use.
6. Прогнати на справжньому iPhone:
   - покупку в Sandbox, відновлення;
   - Face ID, голос, календар, сповіщення.

## Нотатки для рецензента (App Review Information → Notes)
```
Vespr has no accounts and no login: all data stays on the device.
To see the app with sample data, on the first screen tick "I'm 18 or older"
and tap "See an example first". This loads made-up people and dates
(map, comparisons, monthly Wrapped, awards). To start clean: Settings → Start my own.
Premium is an auto-renewable subscription (monthly / yearly) via In-App Purchase;
"Restore purchases" is on the paywall and in Settings → Subscription.
Voice notes use Apple's on-device speech recognition when available; audio is never stored.
```
