# Plan: Salaah App — PHP API v2 + Flutter App

## Context
- Existing: PHP plain-PHP app (Cape Town prayer times, mosque branding, admin panel)
- Target: Slim 4 REST API v2 + full-featured Flutter/Dart app (Muslim Pro equivalent)
- Platforms: Android + iOS + Flutter Web
- Auth: JWT (access 15min + refresh 30d) — replaces sessions
- Prayer data: Keep scraping masjids.co.za (Cape Town only)
- Quran data: AlQuran.cloud API (free, no key, absolute audio CDN URLs)
- Offline: Full offline via Drift (SQLite) + bundled assets
- Push: Firebase FCM + flutter_local_notifications
- User accounts: Both admin users (existing) + app users (new)

## Key External Services
- masjids.co.za — prayer times source (scrape monthly, disk-cache)
- api.alquran.cloud — Quran text + audio CDN (server-side proxy + cache)
- Firebase — FCM push notifications
- Facebook Graph API — mosque photo import (existing)

## New DB Tables (app_*)
- app_users (id, name, email, password_hash, is_active, ...)
- refresh_tokens (id, app_user_id, token_hash, expires_at, revoked)
- device_tokens (id, app_user_id nullable, token, platform, mosque_slug nullable)
- prayer_logs (id, app_user_id, date, prayer, status)
- quran_bookmarks (id, app_user_id, surah, ayah, note)
- user_settings (id, app_user_id, key, value)
- duas_categories (id, name_ar, name_en, icon)
- duas (id, category_id, title_ar, title_en, arabic, transliteration, translation, reference)

## Repository Structure
```
salaah-app/
  old_application/     (untouched)
  api/                 (new PHP Slim 4 API)
    composer.json
    public/index.php   (entry point)
    src/
      Controllers/
      Middleware/      (JwtMiddleware, CorsMiddleware, RateLimitMiddleware)
      Models/
      Services/        (AuthService, QuranService, FcmService, PrayerService)
      Routes/
    migrations/
    seeds/             (Duas seed data)
    config/
    cache/             (quran/, prayer-times/)
  flutter/
    lib/
      core/            (api/, auth/, storage/, theme/, router/)
      features/        (12 feature modules)
    assets/            (duas.json bundled, adhan MP3s, SVG icons)
    android/ ios/ web/
```

## Phase 1: PHP API v2

### 1A — Foundation
1. Init Slim 4 project with Composer (slim/slim, slim/psr7, firebase/php-jwt, vlucas/phpdotenv)
2. DB connection + env config (.env based, cPanel compatible)
3. CORS middleware
4. JWT middleware (validate access token, attach user to request)
5. Rate limit middleware (simple sliding window in DB or APCu)
6. Error handler (JSON error responses)

### 1B — Auth (App Users)
7. POST /v2/auth/register
8. POST /v2/auth/login → {accessToken, refreshToken, user}
9. POST /v2/auth/refresh → new access token
10. POST /v2/auth/logout → revoke refresh token
11. POST /v2/auth/forgot-password
12. POST /v2/auth/reset-password
13. GET /v2/auth/me (JWT required)

### 1C — Prayer Times & Mosques (public)
14. GET /v2/times?month=YYYY-MM (keep scraper, same cache)
15. GET /v2/times/today
16. GET /v2/mosques — list all
17. GET /v2/mosques/default
18. GET /v2/mosques/{slug}
19. GET /v2/mosques/{slug}/times?month=YYYY-MM (with adhan offsets applied)

### 1D — Qibla + Calendar
20. GET /v2/qibla?lat=&lng= (Haversine bearing to Kaaba, pure PHP)
21. GET /v2/calendar/hijri?date=YYYY-MM-DD (Gregorian→Hijri formula)
22. GET /v2/calendar/events?month= (static Islamic events JSON)

### 1E — Quran Proxy
23. GET /v2/quran/surahs — proxy AlQuran.cloud /v1/meta, cache surah list
24. GET /v2/quran/surahs/{n} — proxy surah with Arabic + en.asad + ar.alafasy audio, disk-cache
25. GET /v2/quran/juz/{n}
26. GET /v2/quran/search?q=
27. GET /v2/quran/audio-url — returns CDN absolute URL for alafasy

### 1F — Duas
28. GET /v2/duas/categories
29. GET /v2/duas/categories/{id}
30. GET /v2/duas/{id}
31. Seed migration: populate ~200 duas across 15 categories from public domain sources

### 1G — User Endpoints (JWT required)
32. GET/PUT /v2/user/settings
33. POST /v2/user/device-token, DELETE /v2/user/device-token
34. GET /v2/user/prayer-log?month=
35. POST /v2/user/prayer-log {prayer, date, status}
36. GET/POST/DELETE /v2/user/bookmarks/quran

### 1H — FCM + Admin
37. FCM service class (send via FCM HTTP v1 API)
38. POST /v2/admin/notifications/broadcast (JWT admin only)
39. Migrate all existing admin endpoints to /v2/admin/* with JWT

### 1I — Migrations & Deployment
40. Write all migration SQL files
41. Install script updates
42. cPanel deployment guide update

## Phase 2: Flutter App

### 2A — Project Foundation
1. `flutter create salaah_app` with org com.salaah.times
2. Add all packages to pubspec.yaml (riverpod, go_router, dio, drift, firebase, etc.)
3. Core theme system (dark Islamic aesthetic — deep navy, gold, green accent — like Muslim Pro)
4. go_router route tree (splash → onboarding → main shell → feature routes)
5. Dio API client with JWT interceptor (auto-refresh on 401)
6. Drift DB schema (prayer_times, quran_cache, prayer_logs, bookmarks, duas_cache)
7. Secure storage for JWT tokens

### 2B — Auth Feature
8. Splash screen (animated logo)
9. Onboarding (mosque selection, notification permission, 3-screen walkthrough)
10. Login screen
11. Register screen
12. Forgot password screen
13. AuthNotifier (Riverpod) + persistent login

### 2C — Home (Prayer Times)
14. Fetch prayer times from /v2/mosques/{slug}/times
15. Store in Drift, serve offline
16. Home screen: Hijri date bar, current prayer highlight, 5 prayer cards, live countdown timer, Sehri/Iftar strip
17. Mosque branding: logo, colors from mosque profile applied as ThemeData overrides
18. Announcements carousel
19. Sponsor/social sidebars (optional, Web only most likely)

### 2D — Adhan Notifications
20. flutter_local_notifications setup (Android heads-up, iOS critical)
21. Schedule next 7 days of prayers on app start + settings change
22. Per-prayer toggle + offset (minutes before/at) from user settings
23. Adhan audio playback via just_audio on notification tap
24. FCM handler: mosque announcements as push banners
25. Background WorkManager reschedule (android_alarm_manager_plus or workmanager)

### 2E — Quran Feature
26. Surah list screen (search + filter by juz/name)
27. Surah reader screen: Arabic text (Uthmani), English translation toggle
28. Ayah audio playback (just_audio, per-ayah + auto-advance)
29. Surah-level playback (playlist)
30. Bookmark ayah (save to Drift, sync to API)
31. Search Quran screen
32. Cache surahs to Drift on first read (offline)

### 2F — Duas Feature
33. Duas bundled as assets/duas.json (loaded from bundle, no network for offline)
34. Categories grid screen
35. Duas list screen (Arabic + transliteration + translation)
36. Dua detail: large Arabic text, audio if available, share button
37. Dhikr mode: auto-advance with timer

### 2G — Qibla
38. flutter_qiblah widget integration
39. Compass screen: animated needle pointing to Kaaba
40. Show bearing in degrees + cardinal direction
41. Location permission flow

### 2H — Islamic Calendar
42. Monthly grid with Hijri dates overlaid
43. Islamic event markers (Ramadan, Eid ul-Fitr, Eid ul-Adha, etc.)
44. Event detail bottom sheet
45. Hijri date shown on home screen

### 2I — Prayer Tracker
46. Daily prayer checklist (5 prayers, mark each as prayed/missed/qadha)
47. Sync to API for logged-in users, local-only for guests
48. Weekly streak widget
49. Monthly calendar heatmap

### 2J — Tasbeeh Counter
50. Large tap area with haptic feedback
51. Preset dhikr options (SubhanAllah, Alhamdulillah, Allahu Akbar) + custom
52. Target count (33, 99, custom) with milestone vibration + sound
53. Session history (Hive or Drift)

### 2K — Mosque Profiles
54. Mosque list screen (search by name)
55. Mosque detail screen: logo, contact info, announcements, prayer times
56. Follow mosque (save preference, receive FCM from that mosque)
57. Social media image gallery (from mosque profile)

### 2L — Settings
58. Notification settings: per-prayer on/off, offset, adhan audio selection
59. App theme: dark/light/auto
60. Madhab preference (Shafi/Hanafi — for Asr)
61. Account: profile, change password, logout
62. About + feedback

### 2M — Platform Configs
63. Android: FCM setup, notification channels, icon, splash
64. iOS: FCM setup, notification permissions, capabilities, icons
65. Web: PWA manifest, service worker for offline, web-specific layout adjustments

## Critical Design Decisions
- Riverpod providers per feature, with AsyncNotifier pattern
- go_router ShellRoute for bottom nav (Home, Quran, Qibla, Mosques, More)
- All API calls through a single `ApiClient` class (dio)
- JWT refresh: Dio interceptor catches 401, calls /v2/auth/refresh, retries
- Offline-first: Drift local DB is source of truth; API syncs in background
- Quran audio: stream from AlQuran.cloud CDN directly (no proxying needed in app)
- Duas: bundled JSON asset (no network needed)

## Verification Steps
- PHP: PHPUnit tests for auth, prayer time parsing, Qibla calculation
- PHP: Postman/Bruno collection for all v2 endpoints
- Flutter: Widget tests for home screen prayer timer
- Flutter: Integration test for auth flow (login, JWT refresh, logout)
- Flutter: Test offline mode (airplane mode, verify prayer times still load)
- Flutter: Test notification scheduling (mock time, verify correct triggers)
- Manual: Full flow on Android emulator + iOS simulator
- Manual: Web build (flutter build web) loads and shows prayer times
