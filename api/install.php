#!/usr/bin/env php
<?php

/**
 * Salaah API v2 — Install Script
 *
 * Usage: php install.php
 *
 * Reads DB credentials from .env file (or environment), runs all migrations
 * in order, seeds duas, and creates the first super_admin user.
 *
 * Self-deletes after successful run.
 */

declare(strict_types=1);

require_once __DIR__ . '/vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->safeLoad();

echo "=== Salaah API v2 Install ===\n\n";

// ── DB Connection ─────────────────────────────────────────────────────────────
$host    = $_ENV['DB_HOST']    ?? 'localhost';
$port    = (int) ($_ENV['DB_PORT'] ?? 3306);
$dbname  = $_ENV['DB_NAME']    ?? '';
$user    = $_ENV['DB_USER']    ?? '';
$pass    = $_ENV['DB_PASS']    ?? '';

if (!$dbname || !$user) {
    die("Error: DB_NAME and DB_USER must be set in .env\n");
}

$dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";

try {
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    echo "✓ Database connected\n";
} catch (PDOException $e) {
    die("✗ Database connection failed: " . $e->getMessage() . "\n");
}

// ── Run Migrations ─────────────────────────────────────────────────────────────
$migrations = glob(__DIR__ . '/migrations/*.sql');
sort($migrations);

foreach ($migrations as $file) {
    $filename = basename($file);
    echo "  Running {$filename}... ";
    $sql = file_get_contents($file);

    try {
        $pdo->exec($sql);
        echo "✓\n";
    } catch (PDOException $e) {
        echo "✗ FAILED: " . $e->getMessage() . "\n";
        exit(1);
    }
}

// ── Seed Duas ─────────────────────────────────────────────────────────────────
$seedFile = __DIR__ . '/seeds/duas_seed.sql';
if (file_exists($seedFile)) {
    echo "  Seeding duas... ";
    $existing = $pdo->query('SELECT COUNT(*) AS c FROM duas')->fetch();
    if ($existing['c'] > 0) {
        echo "skipped (already seeded)\n";
    } else {
        $pdo->exec(file_get_contents($seedFile));
        echo "✓\n";
    }
}

// ── Create Super Admin ─────────────────────────────────────────────────────────
$existing = $pdo->query("SELECT COUNT(*) AS c FROM users WHERE role = 'super_admin'")->fetch();
if ($existing['c'] > 0) {
    echo "\n✓ Super admin already exists — skipping user creation.\n";
} else {
    echo "\n── Create Super Admin ──────────────────────────────────\n";
    $username = readline('Username: ');
    $email    = readline('Email: ');

    if (PHP_OS_FAMILY === 'Windows') {
        $password = readline('Password: ');
    } else {
        system('stty -echo');
        $password = readline('Password: ');
        system('stty echo');
        echo "\n";
    }

    if (!$username || !$email || strlen($password) < 8) {
        die("Error: username, email, and password (min 8 chars) are required\n");
    }

    $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    $stmt = $pdo->prepare(
        "INSERT INTO users (username, email, password_hash, role, is_active)
         VALUES (?, ?, ?, 'super_admin', 1)"
    );
    $stmt->execute([$username, $email, $hash]);
    echo "✓ Super admin created: {$username}\n";
}

// ── Cache directories ──────────────────────────────────────────────────────────
$dirs = [
    __DIR__ . '/cache',
    __DIR__ . '/cache/quran',
    __DIR__ . '/cache/prayer-times',
    __DIR__ . '/cache/di',
    __DIR__ . '/uploads',
    __DIR__ . '/uploads/logos',
    __DIR__ . '/uploads/sponsors',
];

foreach ($dirs as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
        echo "✓ Created directory: " . basename($dir) . "\n";
    }
}

echo "\n=== Installation complete! ===\n";
echo "Copy .env.example to .env and set your credentials before deploying.\n";
echo "Point your web server document root to: " . __DIR__ . "/public\n\n";

// Self-delete for security
unlink(__FILE__);
echo "(install.php has been deleted)\n";
