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

echo "› Android: вимикаємо lintVital для плагінів (баг AGP ламає release-збірку file_selector)"
for f in android/build.gradle.kts android/build.gradle; do
  [ -f "$f" ] || continue
  grep -q 'lintVital' "$f" || printf '\nsubprojects {\n    tasks.matching { it.name.contains("lintVital") }.configureEach { enabled = false }\n}\n' >> "$f"
done

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

echo "› Android: нагадування за годину до зустрічі (локальні сповіщення)"
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] || continue
  if ! grep -q 'desugar_jdk_libs' "$f"; then
    if [[ "$f" == *.kts ]]; then
      perl -0pi -e 's#compileOptions \{#compileOptions {\n        isCoreLibraryDesugaringEnabled = true#' "$f"
      printf '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n' >> "$f"
    else
      perl -0pi -e 's#compileOptions \{#compileOptions {\n        coreLibraryDesugaringEnabled true#' "$f"
      printf "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n" >> "$f"
    fi
  fi
done
if ! grep -q 'POST_NOTIFICATIONS' "$MF"; then
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />#' "$MF"
fi
if ! grep -q 'ScheduledNotificationReceiver' "$MF"; then
  perl -0pi -e 's#</application>#    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n            <intent-filter>\n                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n                <action android:name="android.intent.action.QUICKBOOT_POWERON" />\n            </intent-filter>\n        </receiver>\n    </application>#' "$MF"
fi

echo "› Android: мікрофон і системне розпізнавання мови (голосовий запис)"
if ! grep -q 'android.permission.RECORD_AUDIO' "$MF"; then
  perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.RECORD_AUDIO" />#' "$MF"
fi
if ! grep -q 'android.speech.RecognitionService' "$MF"; then
  perl -0pi -e 's#<queries>#<queries>\n        <intent>\n            <action android:name="android.speech.RecognitionService" />\n        </intent>#' "$MF"
fi

echo "› iOS: тільки iPhone (без iPad)"
perl -pi -e 's/TARGETED_DEVICE_FAMILY = "1,2";/TARGETED_DEVICE_FAMILY = 1;/g' ios/Runner.xcodeproj/project.pbxproj

echo "› iOS: тексти дозволів — англійською в Info.plist, українською в uk.lproj"
PL=ios/Runner/Info.plist
add() { /usr/libexec/PlistBuddy -c "Add :$1 string $2" "$PL" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :$1 $2" "$PL"; }
# ключ | англійською | українською
PERMS=(
  "NSFaceIDUsageDescription|Vespr opens with Face ID so only you can see your records.|Vespr відкривається за Face ID, щоб записи бачила тільки ти."
  "NSCalendarsUsageDescription|To add dates to your calendar and bring in the events you choose.|Щоб додати зустрічі в календар і перенести з нього ті, які ти обереш."
  "NSCalendarsWriteOnlyAccessUsageDescription|To add your planned dates to your calendar.|Щоб додати заплановані зустрічі у твій календар."
  "NSCalendarsFullAccessUsageDescription|To bring the calendar events you choose into Vespr. Your calendar itself isn’t changed.|Щоб перенести у Vespr події з календаря, які ти обереш. Сам календар не змінюємо."
  "NSPhotoLibraryUsageDescription|To add a photo of a person. It stays on this phone only.|Щоб додати фото людини. Воно лишається тільки на цьому телефоні."
  "NSMicrophoneUsageDescription|To record by voice how a date went. The audio isn’t saved, only the text.|Щоб записати голосом, як пройшла зустріч. Звук не зберігається, лише текст."
  "NSSpeechRecognitionUsageDescription|To turn your voice into the text of a note. The audio isn’t saved.|Щоб перетворити твій голос на текст нотатки. Звук не зберігається."
  "NSContactsUsageDescription|Vespr never asks for your contacts. The calendar module can technically read event attendees, so Apple requires this line.|Vespr не просить доступу до контактів. Календарний модуль технічно вміє читати учасників подій, тому Apple вимагає цей рядок."
)
mkdir -p ios/Runner/en.lproj ios/Runner/uk.lproj
: > ios/Runner/en.lproj/InfoPlist.strings
: > ios/Runner/uk.lproj/InfoPlist.strings
for row in "${PERMS[@]}"; do
  IFS='|' read -r key en uk <<< "$row"
  [ -x /usr/libexec/PlistBuddy ] && add "$key" "\"$en\""
  printf '"%s" = "%s";\n' "$key" "$en" >> ios/Runner/en.lproj/InfoPlist.strings
  printf '"%s" = "%s";\n' "$key" "$uk" >> ios/Runner/uk.lproj/InfoPlist.strings
done
if [ -x /usr/libexec/PlistBuddy ]; then
  add CFBundleDisplayName Vespr
  /usr/libexec/PlistBuddy -c "Delete :CFBundleLocalizations" "$PL" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations array" -c "Add :CFBundleLocalizations:0 string en" -c "Add :CFBundleLocalizations:1 string uk" "$PL"
else
  echo "  (PlistBuddy нема — це не Mac. iOS налаштовується тільки на Mac)"
fi

echo "› iOS: маніфест приватності (PrivacyInfo.xcprivacy)"
cat > ios/Runner/PrivacyInfo.xcprivacy <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- Vespr не відстежує і нічого не збирає: усе лишається на телефоні -->
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<!-- налаштування й записи у UserDefaults (shared_preferences) — тільки для самої апки -->
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array><string>CA92.1</string></array>
		</dict>
		<!-- дати файлів у папці апки (резервна копія, експорт) -->
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array><string>C617.1</string></array>
		</dict>
	</array>
</dict>
</plist>
XML

echo "› iOS: додаю маніфест і переклади дозволів у проєкт Xcode"
RB='
require "xcodeproj"
p = Xcodeproj::Project.open("ios/Runner.xcodeproj")
t = p.targets.find { |x| x.name == "Runner" }
g = p.main_group["Runner"]
res = t.resources_build_phase
unless g.files.any? { |f| f.path == "PrivacyInfo.xcprivacy" }
  res.add_file_reference(g.new_reference("PrivacyInfo.xcprivacy"))
end
vg = g.children.find { |c| c.display_name == "InfoPlist.strings" } || g.new_variant_group("InfoPlist.strings")
%w[en uk].each do |l|
  path = "#{l}.lproj/InfoPlist.strings"
  next if vg.files.any? { |f| f.path == path }
  r = vg.new_reference(path)
  r.name = l
end
res.add_file_reference(vg) unless res.files_references.include?(vg)
regions = p.root_object.known_regions
%w[en uk].each { |l| regions << l unless regions.include?(l) }
p.save
'
if [ "$(uname)" != Darwin ]; then
  echo "  (не Mac — пропускаю)"
elif ruby -e 'require "xcodeproj"' 2>/dev/null || gem install --user-install xcodeproj >/dev/null 2>&1; then
  ruby -e "$RB" || echo "  ! Не вийшло автоматично. У Xcode перетягни ios/Runner/PrivacyInfo.xcprivacy та папки en.lproj і uk.lproj у групу Runner."
else
  echo "  ! Нема інструмента xcodeproj. У Xcode перетягни ios/Runner/PrivacyInfo.xcprivacy та папки en.lproj і uk.lproj у групу Runner."
fi

echo "› Іконка апки (темна, одна для всіх): iOS 1024 + Android mipmap"
IC=ios/Runner/Assets.xcassets/AppIcon.appiconset
rm -f "$IC"/*.png
cp assets/icon/app_icon.png "$IC/app_icon.png"
cat > "$IC/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "app_icon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
for d in assets/icon/android/mipmap-*; do
  cp "$d/ic_launcher.png" "android/app/src/main/res/$(basename "$d")/ic_launcher.png"
done

echo "› Залежності"
flutter pub get

echo "✓ Готово. Підключи телефон або запусти емулятор і виконай: flutter run"
