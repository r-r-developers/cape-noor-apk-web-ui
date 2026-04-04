# Quick Reference: Google Play Store & App Bundle

## What's Needed for Google Play Store

✅ **App Bundle (AAB)** - Not APK!
- Format: `.aab` (app-release.aab)
- Size: 30-50 MB
- Must be signed with keystore
- Generated from: `flutter build appbundle --release`

✅ **Signing Key** - Create once, use forever
- Created with: `keytool -genkey`
- Stored in: `~/cape-noor-release-key.jks`
- Cannot be changed after upload
- **Keep it safe!**

✅ **Store Listing** 
- Screenshots (2-8 minimum)
- App icon (512x512px)
- Feature graphic (1024x500px)
- Description (4000 chars max)
- Privacy policy URL

✅ **Account**
- Google Play Developer account ($25 one-time)
- Business profile completed

---

## 3-Minute Quick Build

```bash
# 1. One-time setup (first time only)
keytool -genkey -v -keystore ~/cape-noor-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cape-noor-key

# 2. Configure Flutter (first time only)
# Edit android/key.properties with keystore path and passwords

# 3. Build bundle (every release)
cd /development/side-projects/salaah-time-fast-duah
bash build-release-bundle.sh

# 4. Output is ready at:
# flutter/build/app/outputs/bundle/release/app-release.aab
```

---

## Full Build Command (Manual)

```bash
cd /development/side-projects/salaah-time-fast-duah/flutter

export PATH="/opt/flutter/bin:/usr/lib/android-sdk/platform-tools:$PATH"
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

flutter build appbundle --release --no-pub
```

---

## Upload Steps (Google Play Console)

1. Go to: https://play.google.com/console
2. Select: Cape Noor app
3. Click: **Release** → **New Release**
4. Upload: `app-release.aab`
5. Add release notes
6. Click: **Submit for review**
7. Wait: 24-72 hours for approval

---

## File Locations

| What | Where |
|-----|-------|
| Signing Key | `~/cape-noor-release-key.jks` |
| Key Config | `android/key.properties` |
| App Bundle | `flutter/build/app/outputs/bundle/release/app-release.aab` |
| Version | `flutter/pubspec.yaml` |

---

## Key Credentials (Save Securely!)

```
Keystore File: ~/cape-noor-release-key.jks
Key Alias: cape-noor-key
Store Password: ______________ (you set)
Key Password: ________________ (you set)
```

---

## Version Format

Edit `flutter/pubspec.yaml`:

```yaml
version: 1.0.0+1
       ↑     ↑
   Human  Android
   Version Version
```

- Increment for each release
- Example: `1.0.0+1` → `1.0.1+2` (bug fix)
- Example: `1.0.0+1` → `1.1.0+2` (new feature)

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Keystore not found" | Check `~/cape-noor-release-key.jks` exists |
| Build fails | Run: `flutter doctor -v` |
| App rejected | Check Play Console rejection reason |
| Too large | Enable minification in `build.gradle` |

---

## Documentation Files

- **README-flutter.md** - Complete build and test guide (includes Section 6b - App Bundle)
- **GOOGLE_PLAY_STORE.md** - Full publication guide (50+ pages)
- **build-release-bundle.sh** - Automated build script
- **QUICK_DEPLOY_CHECKLIST.md** - Admin panel deployment (on cPanel)

---

## When Ready to Publish

✅ Follow: [GOOGLE_PLAY_STORE.md](GOOGLE_PLAY_STORE.md) - Complete step-by-step guide

📱 Or use quick build: `bash build-release-bundle.sh`

🚀 Then upload to Play Console and wait for approval!

---

## Before First Upload Checklist

- [ ] Keystore created
- [ ] android/key.properties configured
- [ ] App icon prepared (512x512px)
- [ ] 2-8 screenshots ready
- [ ] Feature graphic ready (1024x500px)
- [ ] Store description written
- [ ] Privacy policy created
- [ ] Version set: 1.0.0+1
- [ ] Google Play developer account created ($25)
- [ ] Test on real device

---

See full guide: [GOOGLE_PLAY_STORE.md](GOOGLE_PLAY_STORE.md)
