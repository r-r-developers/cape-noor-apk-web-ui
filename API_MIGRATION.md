# API Migration Guide - Cape Noor System

## Current State

Your system has **TWO separate APIs**:

### Old API (Currently Used)
- **Live URL**: `https://mosque-admin.randrdevelopers.co.za/v2`
- **Type**: Plain PHP files (from old_application)
- **Your Flutter App Points Here**: YES ✓
- **Status**: Working, legacy

### New API (Just Built)
- **Location**: `/development/side-projects/salaah-time-fast-duah/api`
- **Type**: Slim 4 Framework + PHP 8.1+
- **Your Flutter App Points Here**: NO ✗
- **Status**: Ready, not deployed yet

## Why You Can't Just Replace It

| Aspect | Old API | New API | Issue |
|--------|---------|---------|-------|
| **Entry Point** | Direct files | `public/index.php` → Slim routing | cPanel doesn't auto-route to index.php |
| **Router** | File-based | Framework-based | URL structure completely different |
| **Dependencies** | None (plain PHP) | Composer + vendor/ | Needs build step |
| **Database Schema** | 1 set of tables | Extended with app_* tables | Incompatible |
| **Admin Users** | `users` table | `users` table (same) | ✓ Compatible |
| **Endpoints** | `/file.php` structure | `/v2/resource` structure | URL paths don't match |

## The Three Paths Forward

### Path 1: Deploy New API Separately (RECOMMENDED)

**What to do:**
1. Deploy new API to a NEW location (different domain/subdomain)
2. Keep old API running as-is
3. Update Flutter app to use new API URL
4. Gradually migrate endpoints

**Pros:**
- ✅ Zero downtime
- ✅ Can test before switching
- ✅ Easy rollback if issues
- ✅ Run both in parallel

**Cons:**
- ⚠️ Requires new hosting/domain
- ⚠️ Two databases to maintain (eventually)

---

### Path 2: In-Place Migration (RISKY)

**What to do:**
1. Backup old database & files
2. Replace `/public/api/` with Slim framework
3. Reconfigure cPanel routing
4. Run migrations

**Pros:**
- ✅ No new domain needed
- ✅ Single database location

**Cons:**
- ❌ Risk of breaking old app if something fails
- ❌ Complex .htaccess/.nginx config in cPanel
- ❌ No parallel testing possible

---

### Path 3: API Adapter Layer (HYBRID)

**What to do:**
1. Keep old cPanel API running
2. Add wrapper endpoints that proxy to new API
3. Gradually migrate endpoint-by-endpoint
4. Eventually remove old code

**Pros:**
- ✅ Gradual migration
- ✅ Test new endpoints one at a time
- ✅ Safe fallback to old code

**Cons:**
- ⚠️ Temporary complexity
- ⚠️ Performance overhead from proxying

---

## Implementation: Path 1 (Recommended)

### Step 1: Deploy New API to New Domain

```bash
# On your server (or new cPanel account)
domain=api-v2.cape-noor.com  # or api.randrdevelopers.co.za

# Create new public_html folder
mkdir -p /home/user/public_html_api_v2
cd /home/user/public_html_api_v2

# Clone/copy new API
git clone <repo-url> .

# Or if you can't use git:
# scp -r api/ user@server:/home/user/public_html_api_v2/

# Install dependencies
composer install --no-dev --optimize-autoloader

# Setup .env
cp .env.example .env
# Edit .env with database credentials

# Setup database
mysql < migrations/001_existing_tables.sql
mysql < migrations/002_app_user_tables.sql
mysql < migrations/003_duas_tables.sql

# Configure web server (cPanel auto-detects public/ folder)
```

### Step 2: Update Flutter App

In `flutter/lib/main.dart`:

```dart
ApiClient.init(baseUrl: const String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api-v2.cape-noor.com/api',  // ← Change this
));
```

Build new APK:
```bash
cd flutter
flutter build apk --dart-define=API_URL=https://api-v2.cape-noor.com/api
```

### Step 3: Test Endpoints

```bash
# Test new API is working
curl https://api-v2.cape-noor.com/api/v2/mosques

# Test authentication
curl -X POST https://api-v2.cape-noor.com/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

### Step 4: Update Apps Gradually

- ✅ Build new Flutter APK with new API URL
- ✅ Deploy to Play Store/TestFlight
- ✅ Keep old API running for old app versions
- ✅ Monitor both for issues
- ✅ Once stable, deprecate old API

---

## Implementation: Path 2 (In-Place) - Risky but Possible

### Step 1: Backup Everything

```bash
# Backup database
mysqldump -u user -p database > /backup/cape-noor-$(date +%s).sql

# Backup API files
tar -czf /backup/api-old-$(date +%s).tar.gz /path/to/api/

# Backup cPanel config
cp -r /etc/apache2/conf.d /backup/apache-conf-backup/
```

### Step 2: Prepare New Structure

```bash
cd /home/cpanel_user/public_html

# Move old api files to backup
mkdir -p api.old
mv api/* api.old/
mv api.old api_backup/

# Copy new Slim structure
cp -r /development/side-projects/salaah-time-fast-duah/api/public/* .
cp -r /development/side-projects/salaah-time-fast-duah/api/src .
cp -r /development/side-projects/salaah-time-fast-duah/api/vendor .
cp -r /development/side-projects/salaah-time-fast-duah/api/config .

# Install dependencies
composer install --no-dev
```

### Step 3: Configure cPanel/.htaccess

Create/update `.htaccess` in public_html:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    
    # Slim framework routing
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^ index.php [QSA,L]
</IfModule>
```

### Step 4: Update Database

```bash
mysql < api/migrations/002_app_user_tables.sql
mysql < api/migrations/003_duas_tables.sql
# Note: 001 may already exist in old database

# Verify new tables created
mysql -e "USE cape_noor_db; SHOW TABLES;"
```

### Step 5: Test & Monitor

```bash
# Test new API
curl https://mosque-admin.randrdevelopers.co.za/api/v2/mosques

# If breaks, restore:
rm -rf src config vendor api.json composer.lock
cp -r api_backup/api/* .
# Restore database from backup
mysql < /backup/cape-noor-TIMESTAMP.sql
```

---

## Quick Deployment Checklist

```
Deploy New API:
☐ Create new cPanel account or subdomain
☐ Setup SSL certificate (Let's Encrypt)
☐ Upload/clone new API code
☐ Run: composer install --no-dev
☐ Create .env with database credentials
☐ Run migrations: mysql < migrations/*.sql
☐ Test endpoints with curl
☐ Verify database has data

Update Flutter App:
☐ Update API_URL in main.dart or build-time
☐ Rebuild APK with new dart-define
☐ Test against new API
☐ Deploy to stores

Monitor:
☐ Check logs for errors
☐ Monitor both old & new API usage
☐ Keep old API running as fallback for 1-2 weeks
☐ Once all users migrated, decommission old API
```

---

## Endpoint Mapping

### Old API (hypothetical structure)
```
POST /api/auth/login.php
POST /api/auth/register.php
GET  /api/times.php?month=YYYY-MM
GET  /api/mosques.php
```

### New API (actual structure)
```
POST /v2/auth/login
POST /v2/auth/register
GET  /v2/times?month=YYYY-MM
GET  /v2/mosques
GET  /v2/admin/users (NEW)
GET  /v2/admin/users/{id} (NEW)
POST /v2/admin/users (NEW)
PUT  /v2/admin/users/{id} (NEW)
DELETE /v2/admin/users/{id} (NEW)
```

**Flutter app expects** `/v2/*` structure, so it's actually **already compatible** with the new API!

---

## Recommendation

### 🎯 Go with **Path 1: Separate Deployment**

1. **Deploy new API** to `https://api-v2.cape-noor.com/api` (or similar)
2. **Keep old API** at current location as fallback
3. **Update Flutter app** to point to new API
4. **Test for 1-2 weeks** in production
5. **Monitor error logs** for any failures
6. **Deprecate old API** once all users are on new version

**Timeline:**
- Week 1: Deploy new API, build new Flutter APK
- Week 2-3: Roll out to beta testers
- Week 3-4: Deploy to all users
- Week 4+: Keep monitoring, then decommission old API after 1 month

---

## Next Steps

What would you like me to do?

1. **Create deployment scripts** for cPanel automation
2. **Create database migration tool** (old schema → new schema)
3. **Create API compatibility checker** (test both APIs side-by-side)
4. **Help deploy to actual server** (provide exact commands)
5. **Create Flutter build script** with API URL parameter
