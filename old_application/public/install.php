<?php
/**
 * install.php — Database setup & first-run wizard
 *
 * Visit https://yourdomain.com/install.php ONCE after uploading the app.
 * Creates all tables and the initial super-admin account.
 *
 * DELETE THIS FILE after setup is complete.
 */

// ── Security: only allow running from the web if a setup token is confirmed ──
// (or block completely in .htaccess after first run)

error_reporting(E_ALL);
ini_set('display_errors', '1');

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/lib/Db.php';

$message = '';
$success = false;
$step    = 'check';

// ── Handle form submission ────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['run_install'])) {
    try {
        $pdo = db();
        runMigration($pdo);

        $adminEmail    = filter_var(trim($_POST['admin_email'] ?? ''), FILTER_VALIDATE_EMAIL);
        $adminUsername = preg_replace('/[^a-z0-9_]/', '', strtolower(trim($_POST['admin_username'] ?? '')));
        $adminPassword = $_POST['admin_password'] ?? '';

        if (!$adminEmail || strlen($adminUsername) < 3 || strlen($adminPassword) < 8) {
            throw new InvalidArgumentException('Email is required, username ≥ 3 chars, password ≥ 8 chars.');
        }

        // Check if a super_admin already exists
        $existing = $pdo->query("SELECT COUNT(*) FROM users WHERE role = 'super_admin'")->fetchColumn();
        if ($existing > 0) {
            throw new RuntimeException('A super admin already exists. Installation has already been run.');
        }

        $hash = password_hash($adminPassword, PASSWORD_BCRYPT, ['cost' => 12]);
        $stmt = $pdo->prepare(
            "INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, 'super_admin')"
        );
        $stmt->execute([$adminUsername, $adminEmail, $hash]);

        $success = true;
        $step    = 'done';

        // Auto-delete this file so it cannot be re-run
        if (@unlink(__FILE__)) {
            $message = "Installation complete! Your super-admin account is ready. install.php has been deleted automatically.";
        } else {
            $message = "Installation complete! Your super-admin account is ready. <strong>Could not auto-delete install.php — please delete it manually.</strong>";
        }

    } catch (Throwable $e) {
        $message = 'Error: ' . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8');
        $step    = 'error';
    }
} else {
    // Pre-flight check
    try {
        db();
        $step = 'ready';
    } catch (Throwable $e) {
        $message = 'Cannot connect to database: ' . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8');
        $step    = 'db_error';
    }
}

// ── Database schema ───────────────────────────────────────────────────────────
function runMigration(PDO $pdo): void {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id            INT          AUTO_INCREMENT PRIMARY KEY,
            username      VARCHAR(50)  NOT NULL UNIQUE,
            email         VARCHAR(255) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            role          ENUM('super_admin','mosque_admin','maintainer') NOT NULL DEFAULT 'maintainer',
            is_active     TINYINT(1)   NOT NULL DEFAULT 1,
            created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS mosques (
            id                   INT          AUTO_INCREMENT PRIMARY KEY,
            slug                 VARCHAR(100) NOT NULL UNIQUE,
            name                 VARCHAR(255) NOT NULL,
            logo                 VARCHAR(500),
            address              VARCHAR(500),
            phone                VARCHAR(100),
            website              VARCHAR(500),
            show_fasting         TINYINT(1)   NOT NULL DEFAULT 1,
            color_primary        VARCHAR(20)  NOT NULL DEFAULT '#22c55e',
            color_gold           VARCHAR(20)  NOT NULL DEFAULT '#d4af37',
            color_bg             VARCHAR(20)  NOT NULL DEFAULT '#0a0f1a',
            announcements        JSON,
            social_media         JSON,
            sponsors             JSON,
            facebook_page_id     VARCHAR(100),
            facebook_page_name   VARCHAR(255),
            facebook_access_token TEXT,
            auto_approve         TINYINT(1)   NOT NULL DEFAULT 0,
            is_default           TINYINT(1)   NOT NULL DEFAULT 0,
            show_sidebars        TINYINT(1)   NOT NULL DEFAULT 1,
            short_id             CHAR(3)      NULL,
            adhan_offsets        JSON         NULL,
            created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uq_short_id (short_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // ── Migrate existing installs: add new columns if absent ─────────────────
    try { $pdo->exec("ALTER TABLE mosques ADD COLUMN show_sidebars TINYINT(1) NOT NULL DEFAULT 1"); } catch (Throwable $e) {}
    try { $pdo->exec("ALTER TABLE mosques ADD COLUMN short_id CHAR(3) NULL"); }              catch (Throwable $e) {}
    try { $pdo->exec("ALTER TABLE mosques ADD UNIQUE KEY uq_short_id (short_id)"); }         catch (Throwable $e) {}
    try { $pdo->exec("ALTER TABLE mosques ADD COLUMN adhan_offsets JSON NULL"); }             catch (Throwable $e) {}

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS user_mosques (
            id           INT          AUTO_INCREMENT PRIMARY KEY,
            user_id      INT          NOT NULL,
            mosque_slug  VARCHAR(100) NOT NULL,
            can_approve  TINYINT(1)   NOT NULL DEFAULT 0,
            UNIQUE KEY uq_user_mosque (user_id, mosque_slug),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS pending_changes (
            id           INT          AUTO_INCREMENT PRIMARY KEY,
            mosque_slug  VARCHAR(100) NOT NULL,
            submitted_by INT          NOT NULL,
            changes      JSON         NOT NULL,
            status       ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
            reviewed_by  INT,
            review_note  TEXT,
            created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            reviewed_at  DATETIME,
            FOREIGN KEY (submitted_by) REFERENCES users(id),
            FOREIGN KEY (reviewed_by)  REFERENCES users(id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS password_resets (
            id         INT         AUTO_INCREMENT PRIMARY KEY,
            user_id    INT         NOT NULL,
            token      VARCHAR(64) NOT NULL UNIQUE,
            expires_at DATETIME    NOT NULL,
            used       TINYINT(1)  NOT NULL DEFAULT 0,
            created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS settings (
            `key`      VARCHAR(100) PRIMARY KEY,
            value      TEXT         NOT NULL,
            updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Install — Salaah Times</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f1f5f9; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 2rem; }
    .card { background: #fff; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,.1); padding: 2rem; max-width: 480px; width: 100%; }
    h1 { margin-bottom: 0.5rem; font-size: 1.5rem; }
    p.sub { color: #64748b; margin-bottom: 1.5rem; font-size: 0.9rem; }
    .form-group { margin-bottom: 1rem; }
    label { display: block; font-weight: 600; font-size: 0.9rem; margin-bottom: 0.3rem; }
    input { width: 100%; padding: 0.6rem; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 0.95rem; }
    button { width: 100%; padding: 0.75rem; background: #3b82f6; color: #fff; border: none; border-radius: 4px; font-weight: 700; font-size: 1rem; cursor: pointer; margin-top: 0.5rem; }
    button:hover { background: #2563eb; }
    .msg { margin-top: 1rem; padding: 0.75rem 1rem; border-radius: 4px; font-size: 0.9rem; }
    .msg.ok  { background: #dcfce7; border: 1px solid #86efac; color: #166534; }
    .msg.err { background: #fee2e2; border: 1px solid #fca5a5; color: #991b1b; }
    .warn { background: #fef3c7; border: 1px solid #fbbf24; color: #92400e; padding: 0.75rem 1rem; border-radius: 4px; margin-bottom: 1.5rem; font-size: 0.9rem; }
  </style>
</head>
<body>
<div class="card">
  <h1>Salaah Times — Install</h1>
  <p class="sub">One-time database setup. Delete this file after completion.</p>

  <?php if ($step === 'db_error'): ?>
    <div class="msg err"><?= $message ?></div>
    <p style="margin-top:1rem;font-size:.85rem">Check your <code>config.php</code> DB credentials and ensure the database exists.</p>

  <?php elseif ($step === 'done'): ?>
    <div class="msg ok"><?= $message ?></div>
    <p style="margin-top:1rem;"><a href="/admin/">Go to Admin Panel →</a></p>

  <?php elseif ($step === 'error'): ?>
    <div class="msg err"><?= $message ?></div>
    <form method="POST">
      <button name="run_install" value="1">Retry</button>
    </form>

  <?php else: ?>
    <div class="warn">⚠️ <strong>This file will be deleted automatically after installation.</strong></div>

    <?php if ($message): ?>
      <div class="msg err"><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></div>
    <?php endif; ?>

    <form method="POST">
      <div class="form-group">
        <label for="admin_username">Super Admin Username</label>
        <input type="text" id="admin_username" name="admin_username" required minlength="3"
               placeholder="superadmin" pattern="[a-z0-9_]+" autocomplete="username" />
      </div>
      <div class="form-group">
        <label for="admin_email">Email Address</label>
        <input type="email" id="admin_email" name="admin_email" required
               placeholder="you@example.com" autocomplete="email" />
      </div>
      <div class="form-group">
        <label for="admin_password">Password (min 8 characters)</label>
        <input type="password" id="admin_password" name="admin_password" required minlength="8"
               autocomplete="new-password" />
      </div>
      <button type="submit" name="run_install" value="1">Run Installation</button>
    </form>
  <?php endif; ?>
</div>
</body>
</html>
