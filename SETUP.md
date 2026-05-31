# Futura — Setup

## Prérequis
- Flutter SDK >= 3.2.0
- Android Studio ou VS Code
- Android SDK API 23+

## Installation

```bash
cd futura_app
flutter pub get
flutter run
```

## Configuration locale.properties
Modifie `android/local.properties` avec tes chemins :
```
sdk.dir=/home/ton_user/Android/Sdk
flutter.sdk=/home/ton_user/flutter
```

## Icône de l'application
Remplace `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` par une vraie icône.
Pour générer toutes les résolutions automatiquement :
```bash
flutter pub add flutter_launcher_icons --dev
# Configure flutter_icons dans pubspec.yaml puis :
dart run flutter_launcher_icons
```

## Widget home screen
Le widget Android est configuré dans :
- `android/app/src/main/kotlin/com/futura/app/FuturaWidgetProvider.kt`
- `android/app/src/main/res/layout/futura_widget_layout.xml`
- `android/app/src/main/res/xml/futura_widget_info.xml`

## Build APK
```bash
flutter build apk --release
# APK généré dans : build/app/outputs/flutter-apk/app-release.apk
```
