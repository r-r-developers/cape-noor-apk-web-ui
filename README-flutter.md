# Salaah App - Build and Test Guide

This README is for day-to-day local testing so you can build/install the app yourself after each code change.

## 1. Prerequisites (Linux)

- Flutter SDK installed at `/opt/flutter`
- Android SDK installed at `/usr/lib/android-sdk`
- JDK 17 installed at `/usr/lib/jvm/java-17-openjdk-amd64`
- `adb` available from Android platform-tools

If these paths change, update the commands below.

## 2. One-time Environment Setup (per terminal)

Run this before building:

```bash
export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

Go to the Flutter project:

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter
```

## 3. Get Dependencies

```bash
flutter pub get
```

## 4. Build APK

### Debug APK (fast, best for testing)

```bash
flutter build apk --debug --no-pub
```

Output file:

- `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (closer to production)

```bash
flutter build apk --release --no-pub
```

Output file:

- `build/app/outputs/flutter-apk/app-release.apk`

## 5. Run on Emulator

### Start emulator (if not already running)

```bash
/usr/lib/android-sdk/emulator/emulator -avd salaah_test -gpu host -no-boot-anim -no-audio
```

In another terminal, verify device:

```bash
adb devices
```

You should see `emulator-5554` (or similar) as `device`.

### Install APK and launch app

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.salaah.salaah_app/com.salaah.salaah_app.MainActivity
```

## 6. Install on Physical Phone (USB)

1. Enable Developer Options and USB debugging on phone.
2. Connect phone via USB.
3. Verify with `adb devices`.
4. Install:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If you use release APK, replace with `app-release.apk`.

## 7. Useful Checks

### Check Flutter setup

```bash
flutter doctor -v
```

### Check app process after launch

```bash
adb shell pidof com.salaah.salaah_app
```

### Watch runtime logs

```bash
adb logcat | grep -i -E "flutter|dio|exception|error"
```

## 8. API Base URL

App defaults to:

- `https://mosque-admin.randrdevelopers.co.za/v2`

Defined in:

- `lib/main.dart`

You can override at build/run time with Dart define:

```bash
flutter run --dart-define=API_URL=https://your-url.example/v2
```

## 9. Quick Daily Flow

Use this sequence after a code change:

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter
export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
flutter pub get
flutter build apk --debug --no-pub
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.salaah.salaah_app/com.salaah.salaah_app.MainActivity
```

## 10. Current API Expectations

Core endpoints expected for app features:

- `/v2/quran/surahs`
- `/v2/quran/surahs/{number}`
- `/v2/quran/search?q=...`
- `/v2/times/today`
- `/v2/times?month=YYYY-MM`
- `/v2/duas/categories`

Mosque management remains in the PHP admin/web workflow.
