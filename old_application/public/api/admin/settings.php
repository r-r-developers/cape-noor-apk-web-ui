<?php
// GET  /api/admin/settings  — returns current SMTP settings (super_admin only)
// PUT  /api/admin/settings  — update SMTP settings

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';
require_once __DIR__ . '/../../lib/Mail.php';

$user = requireRole('super_admin');

$method = $_SERVER['REQUEST_METHOD'];

$SMTP_KEYS = ['smtp_host', 'smtp_port', 'smtp_username', 'smtp_password', 'smtp_secure', 'smtp_from_email', 'smtp_from_name'];
$OTHER_KEYS = ['adhan_offsets'];

if ($method === 'GET') {
    $rows = db()->query("SELECT `key`, value FROM settings")->fetchAll();
    $cfg  = [];
    foreach ($rows as $r) {
        $cfg[$r['key']] = $r['key'] === 'smtp_password' ? '••••••••' : $r['value'];
    }
    // Fill defaults from config.php for any missing keys
    $defaults = [
        'smtp_host'       => SMTP_HOST,
        'smtp_port'       => (string)SMTP_PORT,
        'smtp_username'   => SMTP_USERNAME,
        'smtp_password'   => SMTP_PASSWORD ? '••••••••' : '',
        'smtp_secure'     => SMTP_SECURE,
        'smtp_from_email' => SMTP_FROM_EMAIL,
        'smtp_from_name'  => SMTP_FROM_NAME,
    ];
    foreach ($defaults as $k => $v) {
        if (!isset($cfg[$k])) $cfg[$k] = $v;
    }
    echo json_encode(['success' => true, 'settings' => $cfg]);
    exit;
}

if ($method === 'PUT') {
    $body = json_decode(file_get_contents('php://input'), true) ?: [];
    $stmt = db()->prepare("INSERT INTO settings (`key`,value) VALUES (?,?) ON DUPLICATE KEY UPDATE value=VALUES(value)");

    foreach ($SMTP_KEYS as $key) {
        if (!isset($body[$key])) continue;
        // Don't overwrite password if the placeholder was sent back
        if ($key === 'smtp_password' && $body[$key] === '••••••••') continue;
        $stmt->execute([$key, $body[$key]]);
    }

    // Handle adhan_offsets: validate it's a JSON array of non-negative integers
    if (isset($body['adhan_offsets'])) {
        $raw     = $body['adhan_offsets'];
        $decoded = is_string($raw) ? json_decode($raw, true) : $raw;
        if (is_array($decoded)) {
            $clean = array_values(array_unique(array_filter(
                array_map('intval', $decoded),
                fn($v) => $v >= 0 && $v <= 1440
            )));
            rsort($clean); // descending: furthest offset fires first
            $stmt->execute(['adhan_offsets', json_encode($clean)]);
        }
    }

    // Test mode: send a test email if requested
    if (!empty($body['test_email'])) {
        $to = filter_var(trim($body['test_email']), FILTER_VALIDATE_EMAIL);
        if ($to) {
            try {
                (new Mailer())->send($to, $to, 'SMTP test — ' . APP_NAME, '<p>SMTP is working correctly.</p>');
                echo json_encode(['success' => true, 'test' => 'Test email sent to ' . $to]);
            } catch (Throwable $e) {
                http_response_code(500);
                echo json_encode(['success' => false, 'error' => 'SMTP test failed: ' . $e->getMessage()]);
            }
            exit;
        }
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'error' => 'Method not allowed']);
