# Deploying Admin Panel to mosque-admin.randrdevelopers.co.za

## Current Setup
```
http://mosque-admin.randrdevelopers.co.za/
├── Your old API code (plain PHP)
└── Admin needs to go here
```

## Goal: Add Admin Panel to Same Domain

```
http://mosque-admin.randrdevelopers.co.za/
├── /api/              ← Old API (existing `/public/api/` files)
├── /admin/            ← Admin web panel (NEW)
└── /v2/               ← New API endpoints (if migrating)
```

## Three Deployment Options

### Option 1: Admin Panel at /admin (RECOMMENDED)

**Structure:**
```
/home/cpanel_user/public_html/
├── api/                    (existing old API)
├── admin/                  (NEW admin panel)
│   ├── index.html
│   ├── app.js
│   ├── auth.js
│   ├── api.js
│   ├── config.js
│   ├── styles.css
│   ├── .htaccess
│   └── README.md
└── .htaccess               (configure routing)
```

**URLs:**
- Admin Dashboard: `http://mosque-admin.randrdevelopers.co.za/admin`
- Admin API: `http://mosque-admin.randrdevelopers.co.za/api/v2/admin/*`

**Setup:**
```bash
# 1. SSH into cPanel server
ssh user@mosque-admin.randrdevelopers.co.za

# 2. Navigate to public_html
cd /home/cpanel_user/public_html

# 3. Create admin directory
mkdir -p admin

# 4. Copy admin web files (from your local machine)
# Option A: If you have git access
cd admin
git clone <repo> .
# Or just copy these files:
# - index.html
# - app.js
# - auth.js
# - api.js
# - config.js
# - styles.css
# - .htaccess

# 5. Configure admin panel to use your API
# Edit admin/config.js:
nano config.js

# Change API_BASE_URL to:
API_BASE_URL: 'http://mosque-admin.randrdevelopers.co.za/api/v2'
# (or https:// if you have SSL)
```

**admin/.htaccess (for SPA routing):**
```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /admin/
    
    # Allow direct access to files/folders
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    
    # Route everything else to index.html
    RewriteRule ^(.*)$ index.html [QSA,L]
</IfModule>

# Security headers
<IfModule mod_headers.c>
    Header set X-Content-Type-Options "nosniff"
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-XSS-Protection "1; mode=block"
</IfModule>

# Caching
<FilesMatch "\.(js|css)$">
    Header set Cache-Control "public, max-age=3600"
</FilesMatch>

<FilesMatch "\.(html)$">
    Header set Cache-Control "public, max-age=0, must-revalidate"
</FilesMatch>
```

---

### Option 2: Admin Panel at Root (Advanced)

**Structure:**
```
/home/cpanel_user/public_html/
├── api/               (old API in subfolder)
├── app.js, app.css    (admin panel files at root)
├── index.html
└── .htaccess          (careful routing needed)
```

**URLs:**
- Admin Dashboard: `http://mosque-admin.randrdevelopers.co.za/`
- Old API: `http://mosque-admin.randrdevelopers.co.za/api/...`

⚠️ **Complex** - requires careful .htaccess configuration to separate API requests from admin panel routes.

---

### Option 3: Admin on Subdomain

**Structure:**
```
admin.mosque-admin.randrdevelopers.co.za/
├── index.html
├── app.js
├── config.js
└── .htaccess
```

**URLs:**
- Admin Dashboard: `http://admin.mosque-admin.randrdevelopers.co.za/`
- API: `http://mosque-admin.randrdevelopers.co.za/api/...`

**Steps:**
1. Create subdomain in cPanel: `admin.mosque-admin.randrdevelopers.co.za`
2. Upload admin panel files to new subdomain's public_html
3. Update config.js API_BASE_URL

---

## Step-by-Step: Deploy to /admin (Option 1)

### Step 1: Prepare Files

Create a deployment package:

```bash
# On your local machine
cd /development/side-projects/salaah-time-fast-duah/admin-web

# Create tarball
tar -czf admin-panel.tar.gz \
  index.html \
  app.js \
  auth.js \
  api.js \
  config.js \
  styles.css \
  .htaccess

# Or just zip it
zip -r admin-panel.zip \
  index.html app.js auth.js api.js config.js styles.css .htaccess
```

### Step 2: Upload to Server

**Option A: Using SCP**
```bash
scp admin-panel.tar.gz user@mosque-admin.randrdevelopers.co.za:/home/cpanel_user/
```

**Option B: Using cPanel File Manager**
1. Login to cPanel
2. File Manager → public_html
3. Create folder: admin
4. Upload files to /admin folder

**Option C: Using Git (if repo is accessible)**
```bash
cd /home/cpanel_user/public_html
mkdir admin
cd admin
git clone <repo-url> .
```

### Step 3: Extract and Setup

```bash
# SSH into server
ssh user@mosque-admin.randrdevelopers.co.za

# Navigate to directory
cd /home/cpanel_user/public_html

# If uploaded as tarball:
tar -xzf admin-panel.tar.gz -C admin/
rm admin-panel.tar.gz

# If uploaded as zip:
unzip admin-panel.zip -d admin/
rm admin-panel.zip

# Check files
ls -la admin/
```

### Step 4: Update Configuration

```bash
# Edit config.js
nano admin/config.js
```

Update API_BASE_URL **based on your setup**:

**If old API is at `/api`:**
```javascript
const CONFIG = {
    API_BASE_URL: 'http://mosque-admin.randrdevelopers.co.za/api/v2',
    // ... rest of config
};
```

**If old API is at `/` (root):**
```javascript
const CONFIG = {
    API_BASE_URL: 'http://mosque-admin.randrdevelopers.co.za/v2',
    // ... rest of config
};
```

**With SSL (https):**
```javascript
const CONFIG = {
    API_BASE_URL: 'https://mosque-admin.randrdevelopers.co.za/api/v2',
    // ... rest of config
};
```

### Step 5: Set Permissions

```bash
# Make files readable by web server
chmod 755 admin/
chmod 644 admin/*.html admin/*.js admin/*.css admin/.htaccess

# If .htaccess has issues, try:
chmod 644 admin/.htaccess
```

### Step 6: Test

Open in browser:
```
http://mosque-admin.randrdevelopers.co.za/admin
```

You should see a login screen.

### Step 7: Configure API Endpoint in Admin Panel

In your browser's developer console (F12):

```javascript
// Check current API URL
console.log(CONFIG.API_BASE_URL);

// If wrong, change it:
window.setApiBaseUrl('http://mosque-admin.randrdevelopers.co.za/api/v2');

// Or edit the file and reload
```

---

## Troubleshooting

### Issue: "Connection refused" when logging in

**Cause:** Wrong API URL in config.js

**Fix:**
```bash
# Check where your actual API endpoints are
curl -I http://mosque-admin.randrdevelopers.co.za/api/v2/mosques
curl -I http://mosque-admin.randrdevelopers.co.za/v2/mosques
# See which one responds with 200

# Update config.js URL accordingly
```

### Issue: 404 Not Found trying to access /admin

**Cause:** Files not uploaded or directory doesn't exist

**Fix:**
```bash
# Check files exist
ls -la /home/cpanel_user/public_html/admin/

# Check .htaccess has correct RewriteBase
head -5 /home/cpanel_user/public_html/admin/.htaccess
# Should show: RewriteBase /admin/
```

### Issue: "Cannot find module" or blank page

**Cause:** Relative paths broken

**Fix:**
```bash
# Check if mod_rewrite is enabled
curl -I http://mosque-admin.randrdevelopers.co.za/admin/nonexistent
# Should 200 (rewritten to index.html), not 404

# If not, enable in .htaccess:
# Make sure both files at root and /admin/.htaccess have RewriteEngine On
```

### Issue: JavaScript files not loading

**Cause:** MIME type or caching issue

**Fix:**
```bash
# Clear browser cache (Ctrl+Shift+Del)
# Or hard refresh (Ctrl+F5)

# Check Content-Type headers
curl -I http://mosque-admin.randrdevelopers.co.za/admin/app.js
# Should show: Content-Type: application/javascript
```

### Issue: "CORS error" in console

**Cause:** Your API doesn't have CORS headers

**Fix:** Add to your API's .htaccess or PHP code:

```php
// At top of your API entry point (e.g., api/index.php)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
```

Or in .htaccess:
```apache
<IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "*"
    Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header set Access-Control-Allow-Headers "Content-Type, Authorization"
</IfModule>
```

---

## Full Directory Structure After Setup

```
/home/cpanel_user/public_html/
├── .htaccess                          (main routing)
├── api/                               (your old API)
│   ├── index.php
│   ├── auth/
│   │   ├── login.php
│   │   └── ...
│   ├── times.php
│   └── ...
├── admin/                             (NEW admin panel)
│   ├── .htaccess                      (SPA routing)
│   ├── index.html
│   ├── app.js
│   ├── auth.js
│   ├── api.js
│   ├── config.js
│   ├── styles.css
│   ├── nginx.conf                     (for reference, not used)
│   ├── Dockerfile                     (for reference, not used)
│   └── README.md
└── (other files/folders from your cPanel site)
```

---

## Quick Start (Copy-Paste Commands)

```bash
# 1. SSH to server
ssh user@mosque-admin.randrdevelopers.co.za

# 2. Create admin directory
mkdir -p /home/cpanel_user/public_html/admin

# 3. Download admin web files directly from GitHub
cd /home/cpanel_user/public_html/admin
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/index.html
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/app.js
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/auth.js
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/api.js
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/config.js
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/styles.css
wget https://github.com/r-r-developers/cape-noor-apk-web-ui/raw/main/admin-web/.htaccess

# 4. Update config.js with your API URL
# Option A: Using sed (automated)
sed -i "s|http://localhost:8080/api|http://mosque-admin.randrdevelopers.co.za/api/v2|g" config.js

# Option B: Edit manually
nano config.js

# 5. Set correct permissions
chmod 755 .
chmod 644 *.html *.js *.css .htaccess

# 6. Test
curl -I http://mosque-admin.randrdevelopers.co.za/admin
```

---

## Summary

✅ **Yes, you can deploy the admin panel to `mosque-admin.randrdevelopers.co.za/admin`**

- Admin panel: `http://mosque-admin.randrdevelopers.co.za/admin`
- Old API: `http://mosque-admin.randrdevelopers.co.za/api/v2` (or wherever it is)
- Same domain, different paths
- Easy to manage, good security separation

**Next steps:**
1. SSH to your server
2. Create `/admin` folder in public_html
3. Copy admin-web files there
4. Update config.js with correct API_BASE_URL
5. Access at `/admin`
