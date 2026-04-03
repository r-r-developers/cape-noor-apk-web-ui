# Google Play Store Publication Guide

## Overview

This guide walks you through publishing **Cape Noor** to Google Play Store, including:
- Creating signed app bundle
- Setting up store listing
- Uploading to Play Store
- Managing post-launch updates

## Quick Start (5-10 minutes if already signed)

```bash
# Step 1: Build signed bundle
cd /development/side-projects/salaah-time-fast-duah
bash build-release-bundle.sh

# Step 2: Upload to Google Play Store console
# Output file: flutter/build/app/outputs/bundle/release/app-release.aab

# Step 3: Wait for approval (24-72 hours)
```

---

## Part 1: One-Time Setup

### 1.1 Create Google Play Developer Account

**Cost:** $25 (one-time)

1. Go to https://play.google.com/console
2. Sign in with Google account
3. Accept terms & conditions
4. Pay $25 registration fee
5. Complete business profile

### 1.2 Generate Signing Key

⚠️ **CRITICAL:** This key cannot be changed later. Treat it like your password.

```bash
# Generate the key
keytool -genkey -v -keystore ~/cape-noor-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cape-noor-key \
  -keypass your_key_password \
  -storepass your_store_password
```

When prompted, fill in these details:
```
First and Last Name: Cape Noor Team
Organizational Unit: Development
Organization: Your Company/Self
City: Cape Town
State: Western Cape
Country Code: ZA
```

**Save these credentials somewhere secure:**
- Keystore path: `~/cape-noor-release-key.jks`
- Store password: (your_store_password)
- Key alias: `cape-noor-key`
- Key password: (your_key_password)

### 1.3 Configure Flutter for Signing

Create `android/key.properties`:

```bash
cat > android/key.properties << 'EOF'
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=cape-noor-key
storeFile=/path/to/cape-noor-release-key.jks
EOF
```

**IMPORTANT:** Replace paths and passwords with your actual values.

This file tells Flutter how to sign the APK/bundle.

### 1.4 Verify Configuration

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter

# List keys in keystore
keytool -list -v -keystore ~/cape-noor-release-key.jks -alias cape-noor-key

# Should show your key details
```

---

## Part 2: Building the App Bundle

### 2.1 Prerequisites

```bash
# Android SDK
export ANDROID_SDK_ROOT=/usr/lib/android-sdk

# Java
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Flutter
export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
```

### 2.2 Build Script

**Option A: Automated (Recommended)**

```bash
cd /development/side-projects/salaah-time-fast-duah
chmod +x build-release-bundle.sh
./build-release-bundle.sh
```

**Option B: Manual**

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter
flutter build appbundle --release --no-pub
```

### 2.3 Output

The signed bundle will be at:
```
flutter/build/app/outputs/bundle/release/app-release.aab
```

Size should be 30-50 MB.

---

## Part 3: Store Listing Setup

### 3.1 Create New App

1. Go to **Google Play Console** → **Create app**
2. Fill in:
   - **App name:** Cape Noor
   - **Default language:** English
   - **App or game:** App
   - **Category:** Lifestyle
   - **Free or paid:** Free

### 3.2 Store Listing Details

Go to **Store Listing** → Fill in:

**Short Description (50 characters max):**
```
Prayer times, Quran, duas for Cape Town
```

**Full Description (4000 characters):**
```
Cape Noor - Prayer Times & Quranic Companion

Islamic prayer times and Quranic resources for Muslims in Cape Town.

KEY FEATURES:

📍 Prayer Times
- Accurate prayer times for major Cape Town mosques
- Automatic timezone and location detection
- Prayer time notifications with Adhan audio

📖 Quran
- Complete Quran text in Arabic
- English translations and transliteration
- Audio recitation by professional Quranic reader
- Search across entire Quran
- Bookmark favorite verses
- Offline access

🤲 Duas (Supplications)
- 200+ authentic duas organized by category
- Arabic text with English translations
- Audio pronunciation
- Daily reminders

🧭 Islamic Tools
- Qibla compass using device compass
- Islamic calendar with Hijri dates
- Event reminders for Islamic holidays
- Tasbeeh (prayer) counter

⚙️ Additional Features
- Dark theme optimized for night prayer
- Lightweight and fast
- No ads or in-app purchases
- Works offline
- Privacy-focused, no personal data collection

SUPPORT:
Contact us at: support@cape-noor.app
Privacy Policy: https://cape-noor.app/privacy

Cape Noor is developed with love for the Muslim community.
```

### 3.3 Screenshots

Upload 2-8 screenshots showing:

1. **Home screen** (Prayer times)
2. **Quran reader**
3. **Duas list**
4. **Qibla compass**
5. **Settings/Notifications**

Requirements:
- Minimum 320x569px
- Maximum 3840x2160px
- JPG or PNG format
- Realistic phone screenshots recommended

**Tip:** Create screenshots using:
```bash
# Screenshot from emulator
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./
```

### 3.4 Graphics

**Feature Graphic (1024x500px):**
- Show app name "Cape Noor"
- Display key features: prayer times, Quran, duas
- Eye-catching Islamic design

**App Icon (512x512px):**
- High quality PNG
- No transparency needed (Google creates variants)
- Display at different sizes to verify clarity

### 3.5 Content Rating

Complete the IARC questionnaire:

1. Go to **Content Ratings**
2. Answer questions about app content:
   - Violence: No
   - Sexual content: No
   - Alcohol/tobacco: No
   - Language: No
   - Religion: Yes (Islamic content)
3. Verify rating: Should be "Everyone" or "Everyone 3+"

### 3.6 Privacy Policy

Create a privacy policy:

```
CAPE NOOR PRIVACY POLICY

Last Updated: April 2026

INFORMATION WE COLLECT:
- Prayer time preferences (stored locally)
- Qibla compass location (not stored, used in-session only)
- Prayer notification settings
- Bookmarked Quranic verses (stored locally)

INFORMATION WE DO NOT COLLECT:
- Personal identification data
- Email or phone number
- Browsing history
- Usage analytics (unless you opt-in)

DATA STORAGE:
- All user data stored on your device
- No data sent to external servers
- No third-party data sharing

CONTACT US:
support@cape-noor.app
```

Host this at: `https://cape-noor.app/privacy` (or similar)

### 3.7 Target Audience

- Target age: 13+ (Islamic guidance content)
- Category: Lifestyle / Religion
- Region: South Africa (initially)

---

## Part 4: Upload to Play Store

### 4.1 Release to Production

1. Go to **Google Play Console** → **Cape Noor** app
2. Click **Release** → **New Release**
3. In **App bundles and APKs** section:
   - Click **Browse files**
   - Upload: `app-release.aab`
4. Add **Release notes:**
   ```
   Cape Noor v1.0.0
   
   Initial release features:
   - Prayer times for Cape Town mosques
   - Complete Quran with translations
   - 200+ authentic duas
   - Qibla compass and Islamic calendar
   - Offline support
   ```
5. Review all fields are complete ✓
6. Click **Submit for review**

### 4.2 Wait for Approval

Typical review times:
- **Initial review:** 24-72 hours
- **Resubmissions:** Usually faster

Check status in **Play Console** → **Releases** → **Production**

---

## Part 5: Post-Launch Management

### 5.1 Monitor Crashes

```
Play Console → Analytics → Vitals → Crashes
```

Fix critical crashes by:
1. Identify crash logs
2. Fix bug in code
3. Increment version in `pubspec.yaml`
4. Build new bundle
5. Upload as new release

### 5.2 Version Numbering

Edit `flutter/pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD`

Examples:
- `1.0.0+1` → `1.0.1+2` (Bug fix)
- `1.0.0+1` → `1.1.0+2` (New feature)
- `1.0.0+1` → `2.0.0+2` (Major redesign)

**Always increment BUILD number!**

### 5.3 Update Process

```bash
# 1. Update pubspec.yaml
nano flutter/pubspec.yaml
# Change: version: 1.0.0+1 → 1.0.1+2

# 2. Build new bundle
cd /development/side-projects/salaah-time-fast-duah
bash build-release-bundle.sh

# 3. Upload to Play Console
# Release → Production → New Release
# Upload app-release.aab

# 4. Wait for review
```

### 5.4 User Feedback Management

Monitor and respond to:
- **Ratings & Reviews** → Reply within 24 hours
- **Common issues** → Reply to help users solve problems
- **Feature requests** → Consider for future updates

---

## Troubleshooting

### Issue: "Keystore file not found"

**Solution:**
```bash
keytool -list -keystore ~/cape-noor-release-key.jks
# Verify file path in android/key.properties
```

### Issue: "Invalid signature"

**Solution:**
```bash
# Verify keystore contents
keytool -list -v -keystore ~/cape-noor-release-key.jks \
  -alias cape-noor-key \
  -storepass YOUR_STORE_PASSWORD
```

### Issue: "Cannot sign build"

**Solution:**
```bash
# Check key.properties file exists
ls -l android/key.properties

# Rebuild with verbose output
flutter build appbundle --release -v
```

### Issue: "App rejected - minSdkVersion too low"

**Solution:**
Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21  // Android 5.0+
}
```

### Issue: "App is too large"

**Solution:**
- Enable ProGuard/R8 minification
- Split assets by ABI
- Remove unused dependencies

### Issue: "Missing app icon in Play Store"

**Solution:**
Ensure icon file exists:
```bash
ls -l android/app/src/main/res/mipmap-*/ic_launcher.png
```

---

## Checklist

**Before First Upload:**
- [ ] Keystore created and stored securely
- [ ] `android/key.properties` configured
- [ ] App name finalized: "Cape Noor"
- [ ] App icon (512x512px) prepared
- [ ] Feature graphic (1024x500px) prepared
- [ ] 2-8 screenshots prepared
- [ ] Store listing text written
- [ ] Privacy policy hosted
- [ ] Content rating questionnaire completed
- [ ] Target audience selected
- [ ] Version set in pubspec.yaml: 1.0.0+1

**Before Each Upload:**
- [ ] Version incremented
- [ ] Release notes written
- [ ] No debug logs remaining
- [ ] Tested on real device
- [ ] All API endpoints tested
- [ ] Offline mode tested
- [ ] Notifications tested

---

## Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Build & Release Guide](https://flutter.dev/docs/deployment/android)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Google Play Policies](https://play.google.com/about/developer-content-policy/)

---

## Support

For issues:
1. Check troubleshooting section above
2. Run `flutter doctor -v` to verify setup
3. Check Play Console rejection reason
4. Review build logs: `flutter build appbundle --release -v`
