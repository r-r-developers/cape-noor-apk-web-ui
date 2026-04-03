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

## 6b. Build App Bundle for Google Play Store

### Generate Signing Key (one-time only)

⚠️ **IMPORTANT:** Keep this key safe, you can't change it later!

```bash
keytool -genkey -v -keystore ~/cape-noor-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cape-noor-key \
  -keypass your_key_password \
  -storepass your_store_password
```

This creates `cape-noor-release-key.jks` in your home directory.

**Store these credentials securely:**
- Key alias: `cape-noor-key`
- Key password: (what you entered)
- Store password: (what you entered)

### Configure Signing (one-time setup)

Create `android/key.properties`:

```bash
cat > android/key.properties << 'EOF'
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=cape-noor-key
storeFile=/path/to/cape-noor-release-key.jks
EOF
```

Then edit `android/app/build.gradle` to use it:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Build Signed App Bundle

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter

# Set environment
export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Build app bundle
flutter build appbundle --release --no-pub
```

Output file:

- `build/app/outputs/bundle/release/app-release.aab`

This is what you upload to Google Play Store!

### Quick Build Command (after setup)

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter
flutter build appbundle --release --no-pub
```

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

## 11. Google Play Store Submission

### Prerequisites

1. **Google Play Developer Account** ($25 one-time fee)
   - Register at https://play.google.com/console
   - Complete business profile

2. **Build signed app bundle** (see Section 6b)

3. **App Store Listing Info:**
   - App name: Cape Noor
   - Short description: Prayer times, Quran, duas with mosque management
   - Full description: See below
   - Screenshots: 2-8 screenshots of key features
   - Featured graphic: 1024x500px banner
   - App icon: 512x512px (high quality)
   - Category: Lifestyle
   - Content rating: Complete questionnaire
   - Privacy policy: Must have one

### Store Listing Content

**Short Description (50 chars max):**
```
Prayer times, Quran, duas for Cape Town
```

**Full Description (4000 chars max):**
```
Cape Noor - Prayer Times & Quranic Companion

Features:
• Accurate prayer times for mosques in Cape Town
• Complete Quran with Arabic, transliteration & translation
• Daily duas (supplications) with categories
• Qibla compass to find prayer direction
• Islamic calendar with Hijri dates
• Tasbeeh counter with haptic feedback
• Prayer time notifications
• Offline mode - no internet required
• Dark Islamic theme
• Fast & lightweight

Perfect for Muslims seeking a reliable prayer time app combined with essential Islamic resources.

Contact: support@cape-noor.app
Privacy: https://cape-noor.app/privacy
```

### Step-by-Step Upload to Google Play

1. **Go to Google Play Console**
   - https://play.google.com/console
   - Sign in with your Google account

2. **Create New App**
   - Click "Create app"
   - App name: Cape Noor
   - Default language: English
   - App or game: App
   - Category: Lifestyle
   - Free or paid: Free

3. **Setup Store Listing**
   - Short description (50 chars)
   - Full description (4000 chars)
   - Upload screenshots (2-8 minimum)
   - Upload feature graphic (1024x500px)
   - Upload app icon (512x512px)
   - Select content rating (family-friendly)

4. **Upload App Bundle**
   - Go to "Release" → "Production"
   - Click "Create new release"
   - Upload `app-release.aab` from:
     ```
     flutter/build/app/outputs/bundle/release/app-release.aab
     ```
   - Add release notes (e.g., "Version 1.0 - Initial launch")

5. **Privacy & Permissions**
   - Complete privacy questionnaire
   - List permissions used:
     - Location (for Qibla compass)
     - Notifications (for prayer reminders)
   - Link to privacy policy

6. **Content Rating**
   - Complete IARC questionnaire
   - Should rate as "Everyone" or "Everyone 3+"

7. **Review & Submit**
   - Check all required fields are filled ✓
   - Click "Submit for review"
   - Wait 24-72 hours for approval

### After Launch

**Monitor & Update:**

```bash
# Check crash reports
# Google Play Console → Analytics → OS → Crashes

# Build updates with version bump
# Edit: flutter/pubspec.yaml
# version: 1.0.0+1  →  version: 1.1.0+2

# Rebuild bundle
cd flutter
flutter build appbundle --release --no-pub

# Upload new bundle to Play Console
# Release → Production → Create new release
```

### Troubleshooting Play Store Upload

**Issue: "You must complete your account registration"**
- Complete Google Play Developer profile first
- Add payment method to account

**Issue: "App bundle cannot be successfully installed"**
- Check minSdkVersion in `android/app/build.gradle`
- Should be: `minSdkVersion 21` (Android 5.0+)

**Issue: "App uses permissions but doesn't request them"**
- Check `android/app/src/AndroidManifest.xml`
- Add required permissions:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ```

**Issue: "App rejected - policy violation"**
- Common issues:
  - No privacy policy
  - Crashes on startup
  - Missing app icon
  - Misleading description
- Check rejection reason in Play Console → Resolution center

### Versioning Strategy

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Big feature changes (1.0 → 2.0)
- **MINOR**: New features (1.0 → 1.1)
- **PATCH**: Bug fixes (1.0 → 1.0.1)
- **BUILD**: Internal build number (1, 2, 3...)

Always increment BUILD number for each Play Store upload.
