#!/bin/bash
set -e
flutter create --org com.cadastro --project-name cadastro_fotos app
cp -R app_src/. app/
M=app/android/app/src/main/AndroidManifest.xml
grep -q "permission.INTERNET" $M || sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.CAMERA"/>\n    <application#' $M
cd app && flutter pub get && flutter build apk --release
echo "APK: app/build/app/outputs/flutter-apk/app-release.apk"
