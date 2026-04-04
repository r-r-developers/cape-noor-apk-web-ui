# cPanel Deployment Guide

## What changed

The app has been rewritten from Node.js (Express) to PHP so it can run on
standard cPanel shared hosting — no Node.js required.

The frontend HTML/CSS/JavaScript is **unchanged**; only the server-side code
has been replaced with PHP equivalents.

---

## Requirements on your cPanel host

| Requirement | Notes |
|---|---|
| PHP 8.1 or newer | PHP 7.4 works with minor tweaks (remove `match`, `str_starts_with`, `never` return type) |
| `php_curl` extension | Almost always enabled on shared hosts |
| `php_dom` + `php_libxml` | Needed for HTML scraping; enabled by default |
| `php_fileinfo` | For MIME-type validation of uploads; enabled by default |
| Apache `mod_rewrite` | Enabled by default on all cPanel servers |
| Write access to `data/`, `cache/`, `uploads/` | Set directory permissions to 755 |

---

## Files to upload

Upload the **entire contents of the `public/` folder** to your `public_html/`
directory (or whatever folder your domain points to).

```
public_html/
├── .htaccess                   ← URL rewriting + short /000 mosque routes
├── config.php                  ← ⚠ Edit DB/SMTP credentials here
├── index.php                   ← Main page (was index.html)
├── app.js
├── style.css
├── install.php                 ← Run once then delete
├── api/
│   ├── auth/
│   │   ├── login.php
│   │   ├── logout.php
│   │   ├── me.php
│   │   ├── forgot-password.php
│   │   └── reset-password.php
│   ├── times.php
│   ├── profile.php             ← Returns adhanOffsets + showSidebars
│   ├── fetch-images.php
│   ├── admin/
│   │   ├── mosques.php         ← CRUD + short_id auto-assign
│   │   ├── settings.php        ← SMTP + adhan alert offsets
│   │   ├── users.php
│   │   ├── pending-changes.php
│   │   ├── set-default.php
│   │   ├── download-image.php
│   │   └── upload/
│   │       ├── logo.php
│   │       └── sponsor.php
│   └── facebook/
│       ├── auth.php
│       ├── save-page.php
│       └── fetch-photos.php
├── admin/
│   ├── index.php               ← Auth-guarded (was index.html)
│   ├── login.php               ← Server-side session check (was login.html)
│   ├── admin.js
│   ├── admin.css
│   └── facebook/
│       └── callback.php
├── lib/
│   ├── Auth.php
│   ├── Db.php
│   └── Mail.php
├── cache/
│   └── .htaccess
└── uploads/
    ├── logos/
    └── sponsors/
```

---

## Step-by-step setup

### 1. Edit `config.php`

Open `public/config.php` and update:

```php
define('ADMIN_USERNAME', 'your-admin-username');
define('ADMIN_PASSWORD', 'a-strong-password');   // ← Change this!
```

If you plan to use the Facebook integration, also fill in `FACEBOOK_APP_ID`,
`FACEBOOK_APP_SECRET`, and `FACEBOOK_REDIRECT_URI`.

### 2. Upload files

Use cPanel File Manager or an FTP client to upload everything from `public/`
to `public_html/`.

### 3. Copy the data file

Copy `data/mosques.json` (from this project root) to `public_html/data/mosques.json`.

### 4. Set directory permissions

In cPanel File Manager, set these directories to **755** (or 775 if the web
server runs as a different user):

- `public_html/data/`
- `public_html/cache/`
- `public_html/uploads/`
- `public_html/uploads/logos/`
- `public_html/uploads/sponsors/`
- `public_html/uploads/social/`

PHP must be able to **write** to these directories.

### 5. Test

Visit `https://yourdomain.com/` — prayer times should load.

Visit `https://yourdomain.com/admin/` — your browser will ask for the admin
credentials you set in `config.php`.

---

## How caching works

Prayer times are scraped from masjids.co.za **once per month** and stored in
`cache/YYYY-MM.json`. Subsequent visitors read from the cache instantly
without hitting the external site.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Blank page / 500 error | Check PHP error logs in cPanel → Logs → Error Log |
| "Prayer times table not found" | The scrape site changed its HTML — check `public_html/cache/` is writable |
| Uploads fail | Make sure `uploads/logos/` and `uploads/sponsors/` exist and are writable (chmod 755) |
| Admin API returns 404 | Confirm `mod_rewrite` is enabled and `.htaccess` was uploaded |
| Admin API returns 401 unexpectedly | Some PHP-CGI setups don't forward HTTP Auth; add to `.htaccess`: `RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]` and add `CGIPassAuth On` |


now I want you to had the following 

for example on the mosque page 
Fajr
05:36
salaah starts at 
it should so the time salaah begins 
Fajr
05:36
salaah starts at 05:37

mosque admins needs to inform thier users that the time pray will start so they arrive on time 