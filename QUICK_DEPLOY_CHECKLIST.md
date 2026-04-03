# Quick Deploy: Admin Panel to mosque-admin.randrdevelopers.co.za

## TL;DR - What to Do

You want:
```
http://mosque-admin.randrdevelopers.co.za/
├── /api/           ← Your existing old API (don't touch)
└── /admin/         ← NEW admin panel here
```

## Step-by-Step (5 minutes)

### 1️⃣ Connect to Your Server

```bash
# On your local machine (Mac/Linux/WSL)
ssh cpanel_user@mosque-admin.randrdevelopers.co.za
# (or use FileZilla/cPanel File Manager)
```

### 2️⃣ Create Admin Folder

```bash
cd /home/cpanel_user/public_html
mkdir admin
cd admin
```

### 3️⃣ Get Admin Files

**Option A: Git Clone**
```bash
git clone https://github.com/r-r-developers/cape-noor-apk-web-ui.git temp
cp temp/admin-web/* .
rm -rf temp
```

**Option B: Download Directly**
```bash
# Download each file
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/index.html
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/app.js
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/auth.js
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/api.js
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/config.js
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/styles.css
curl -O https://raw.githubusercontent.com/r-r-developers/cape-noor-apk-web-ui/main/admin-web/.htaccess
```

**Option C: Upload via cPanel**
1. Go to cPanel → File Manager
2. Navigate to public_html
3. Create folder named `admin`
4. Upload these files to /admin:
   - index.html
   - app.js
   - auth.js
   - api.js
   - config.js
   - styles.css
   - .htaccess

### 4️⃣ Update Configuration

```bash
# You MUST figure out where your API lives first!
# Your old API is probably at one of these:

# Option 1: Root level
curl -I http://mosque-admin.randrdevelopers.co.za/v2/mosques

# Option 2: In /api subdirectory
curl -I http://mosque-admin.randrdevelopers.co.za/api/v2/mosques

# Option 3: Old file-based structure
curl -I http://mosque-admin.randrdevelopers.co.za/api/auth/login.php

# Once you find which works, edit config.js:
nano config.js
```

**Update the API_BASE_URL based on what worked above:**

```javascript
// If your API responds at: http://mosque-admin.randrdevelopers.co.za/api/v2/mosques
// Change line to:
API_BASE_URL: 'http://mosque-admin.randrdevelopers.co.za/api/v2'

// If it responds at: http://mosque-admin.randrdevelopers.co.za/v2/mosques
// Change line to:
API_BASE_URL: 'http://mosque-admin.randrdevelopers.co.za/v2'

// If you have HTTPS/SSL (https://mosque-admin....")
// Use: https://mosque-admin.randrdevelopers.co.za/api/v2
```

Save with: `Ctrl+X` then `Y` then `Enter`

### 5️⃣ Fix Permissions

```bash
chmod 755 .
chmod 644 *.html *.js *.css .htaccess
```

### 6️⃣ Test It!

Open in browser:
```
http://mosque-admin.randrdevelopers.co.za/admin
```

You should see a login screen!

---

## Verify Your API Endpoint

**CRITICAL:** Before step 4, figure out where your API is!

```bash
# Test all possible locations:

# Test 1
curl -v http://mosque-admin.randrdevelopers.co.za/v2/mosques 2>&1 | grep HTTP

# Test 2
curl -v http://mosque-admin.randrdevelopers.co.za/api/v2/mosques 2>&1 | grep HTTP

# Test 3
curl -v http://mosque-admin.randrdevelopers.co.za/api/mosques 2>&1 | grep HTTP

# The one that returns "HTTP/1.1 200" is your API base URL
# Use that in config.js
```

---

## Troubleshooting

### Problem: "ERR_CONNECTION_REFUSED"
- Admin panel file not found or .htaccess broken
- **Fix:** Check files exist: `ls -la /home/cpanel_user/public_html/admin/`

### Problem: "Connection refused" when logging in
- Admin panel found but can't reach API
- **Fix:** Config.js has wrong API_BASE_URL
- **Test:** `curl http://mosque-admin.randrdevelopers.co.za/api/v2/mosques`

### Problem: "CORS error" in browser console
- API doesn't allow cross-origin requests
- **Fix:** Add to your API's .htaccess or index.php:
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: *');
header('Access-Control-Allow-Headers: *');
```

### Problem: Blank white page
- JavaScript error
- **Fix:** 
  1. Press F12 to open browser console
  2. Look for red errors
  3. Check if files are loading (Network tab)
  4. Check file paths in .htaccess match /admin/

### Problem: Page works but login fails
- Right API, but wrong credentials or database issue
- **Fix:**
  1. Make sure you have admin user in your database
  2. Use correct username/password
  3. Check API error in browser console

---

## Final Checklist

- [ ] I know where my API is (e.g., /api/v2 or just /v2)
- [ ] Admin folder created at /home/cpanel_user/public_html/admin/
- [ ] All 7 files uploaded to /admin/
- [ ] config.js has correct API_BASE_URL
- [ ] Permissions set (chmod 755 . && chmod 644 *.* .htaccess)
- [ ] Can access http://mosque-admin.randrdevelopers.co.za/admin in browser
- [ ] See login screen
- [ ] Know admin username/password for your database
- [ ] Can log in

---

## Alternative: Deploy Admin to Subdomain

If you prefer separate domain:

1. In cPanel → Addon Domains or Subdomains
2. Create: admin.mosque-admin.randrdevelopers.co.za
3. Upload admin files to that subdomain's public_html
4. Update config.js to point API to main domain:
   ```javascript
   API_BASE_URL: 'http://mosque-admin.randrdevelopers.co.za/api/v2'
   ```
5. Access at: http://admin.mosque-admin.randrdevelopers.co.za/

---

## Your Current Architecture (After Deployment)

```
┌─────────────────────────────────────────────────────┐
│  Browser at admin.randrdevelopers.co.za/admin        │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │ Admin Web Dashboard     │
        │ (HTML/JS/CSS)           │
        │ Makes AJAX calls to:    │
        │ /api/v2/admin/users     │
        │ /api/v2/admin/mosques   │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────────────┐
        │ Your Old API                    │
        │ (Plain PHP at /api/)            │
        │ Handles /api/v2/* requests      │
        │ Connects to: cape_noor_db       │
        └────────────┬────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  MySQL Database         │
        │  (cape_noor_db)         │
        └─────────────────────────┘
```

---

## Next: Update Flutter App Too

Once admin panel is working, you should also update your Flutter app:

```bash
cd flutter
flutter build apk \
  --dart-define=API_URL=http://mosque-admin.randrdevelopers.co.za/api/v2
```

Or if using https:
```bash
flutter build apk \
  --dart-define=API_URL=https://mosque-admin.randrdevelopers.co.za/api/v2
```

---

## Questions?

If anything fails, check:
1. `/home/cpanel_user/public_html/admin/` - all files there?
2. Browser console (F12) - any errors?
3. Network tab - what calls are failing?
4. Make sure API_BASE_URL in config.js is 100% correct

Good luck! 🚀
