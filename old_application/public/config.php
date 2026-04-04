<?php
// ─────────────────────────────────────────────────────────────────────────────
// Application Configuration — edit these values before deploying
// ─────────────────────────────────────────────────────────────────────────────

// ── Database (MySQL/MariaDB — provided by cPanel / Docker env vars) ───────────
define('DB_HOST',    getenv('DB_HOST') ?: 'localhost');
define('DB_NAME',    getenv('DB_NAME') ?: 'randrdev_mosque');   // ← set for cPanel
define('DB_USER',    getenv('DB_USER') ?: 'randrdev_mosque');   // ← set for cPanel
define('DB_PASS',    getenv('DB_PASS') ?: 'WFVd~@z%K(Cy.I4?'); // ← set for cPanel
define('DB_CHARSET', 'utf8mb4');

// ── SMTP defaults (can be overridden via Admin → Settings in the UI) ──────────
define('SMTP_HOST',       'mail.randrdevelopers.co.za');
define('SMTP_PORT',       465);
define('SMTP_USERNAME',   'no-reply@randrdevelopers.co.za');
define('SMTP_PASSWORD',   'Rustin10!');
define('SMTP_SECURE',     'ssl');   // 'tls' (STARTTLS on 587) or 'ssl' (port 465)
define('SMTP_FROM_EMAIL', 'no-reply@randrdevelopers.co.za');
define('SMTP_FROM_NAME',  'Salaah Times');

// ── App ───────────────────────────────────────────────────────────────────────
define('APP_URL',  'https://mosque-demo.randrdevelopers.co.za');  // ← no trailing slash
define('APP_NAME', 'Salaah Times');

// ── Facebook OAuth (only needed if using Facebook integration) ────────────────
define('FACEBOOK_APP_ID',      '');
define('FACEBOOK_APP_SECRET',  '');
// Set to: https://yourdomain.com/admin/facebook/callback
define('FACEBOOK_REDIRECT_URI', '');

// ── File paths — __DIR__ is the web root (public_html) ───────────────────────
define('CACHE_DIR',  __DIR__ . '/cache');
define('UPLOAD_DIR', __DIR__ . '/uploads');

// ── Session lifetime ──────────────────────────────────────────────────────────
#define('SESSION_LIFETIME', 3600 * 8); // 8 hours
define('SESSION_LIFETIME', 60 * 10); // 10 minutes
