@echo off
echo === Criando projeto Flutter ===
call flutter create --org com.cadastro --project-name cadastro_fotos app
echo === Copiando arquivos do app ===
xcopy /E /Y /I app_src app
echo === Ajustando permissoes Android ===
powershell -ExecutionPolicy Bypass -File patch_manifest.ps1
cd app
call flutter pub get
echo === Gerando APK ===
call flutter build apk --release
echo.
echo APK: app\build\app\outputs\flutter-apk\app-release.apk
pause
