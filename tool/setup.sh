#!/usr/bin/env bash
# Один раз після розпакування: створює папки android/ та ios/ і налаштовує їх під Vespr.
# Запуск з папки проєкту:  bash tool/setup.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "› Створюю android/ та ios/ ..."
flutter create . --org app.vespr --project-name vespr --platforms=android,ios

echo "› Android: відбиток пальця потребує FlutterFragmentActivity"
MA=$(find android/app/src/main -name 'MainActivity.kt' | head -1)
PKG=$(grep '^package' "$MA")
cat > "$MA" <<EOF
$PKG

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
EOF

echo "› Android: minSdk 23 (захищене сховище і відбиток)"
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] || continue
  perl -pi -e 's/minSdk\s*=\s*flutter\.minSdkVersion/minSdk = 23/; s/minSdkVersion\s+flutter\.minSdkVersion/minSdkVersion 23/' "$f"
done

echo "› Android: тема AppCompat, щоб вікно відбитка не падало на Android 8 і старших"
for f in android/app/src/main/res/values/styles.xml android/app/src/main/res/values-night/styles.xml; do
  [ -f "$f" ] || continue
  perl -pi -e 's#parent="\@android:style/Theme\.[A-Za-z.]+"#parent="Theme.AppCompat.DayNight.NoActionBar"#g' "$f"
done
if [ -f android/app/build.gradle.kts ] && ! grep -q 'androidx.appcompat' android/app/build.gradle.kts; then
  printf '\ndependencies {\n    implementation("androidx.appcompat:appcompat:1.7.0")\n}\n' >> android/app/build.gradle.kts
elif [ -f android/app/build.gradle ] && ! grep -q 'androidx.appcompat' android/app/build.gradle; then
  printf "\ndependencies {\n    implementation 'androidx.appcompat:appcompat:1.7.0'\n}\n" >> android/app/build.gradle
fi

echo "› Android: дозволяємо відкривати календар телефону"
MF=android/app/src/main/AndroidManifest.xml
if ! grep -q 'vnd.android.cursor.item/event' "$MF"; then
  perl -0pi -e 's#</manifest>#    <queries>\n        <intent>\n            <action android:name="android.intent.action.INSERT" />\n            <data android:mimeType="vnd.android.cursor.item/event" />\n        </intent>\n    </queries>\n</manifest>#' "$MF"
fi
perl -pi -e 's/android:label="vespr"/android:label="Vespr"/' "$MF"

echo "› Android: читання календаря для імпорту (Android показує одне вікно «Календар»; Vespr у календар нічого не пише сам)"
if ! grep -q 'android.permission.READ_CALENDAR' "$MF"; then
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.READ_CALENDAR" />\n    <uses-permission android:name="android.permission.WRITE_CALENDAR" />#' "$MF"
fi

echo "› iOS: тексти дозволів (Face ID, календар)"
PL=ios/Runner/Info.plist
add() { /usr/libexec/PlistBuddy -c "Add :$1 string '$2'" "$PL" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :$1 '$2'" "$PL"; }
if [ -x /usr/libexec/PlistBuddy ]; then
  add NSFaceIDUsageDescription "Vespr відкривається за Face ID, щоб записи бачила тільки ти."
  add NSCalendarsUsageDescription "Щоб додати зустрічі в календар і перенести з нього ті, які ти обереш."
  add NSCalendarsWriteOnlyAccessUsageDescription "Щоб додати заплановані зустрічі у твій календар."
  add NSCalendarsFullAccessUsageDescription "Щоб перенести у Vespr події з календаря, які ти обереш. Сам календар не змінюємо."
  add NSContactsUsageDescription "Календар може запитати контакти для запрошень. Vespr їх не читає."
  add CFBundleDisplayName "Vespr"
else
  echo "  (PlistBuddy нема — це не Mac. Для iOS додай ці ключі в ios/Runner/Info.plist вручну, див. README)"
fi

echo "› Залежності"
flutter pub get

echo "✓ Готово. Підключи телефон або запусти емулятор і виконай: flutter run"
