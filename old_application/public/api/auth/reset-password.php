<?php
// POST /api/auth/reset-password  { token, password }

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$body     = json_decode(file_get_contents('php://input'), true) ?: [];
$token    = trim($body['token']    ?? '');
$password = $body['password'] ?? '';

if (!$token || strlen($password) < 8) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Token and a password of at least 8 characters are required']);
    exit;
}

$stmt = db()->prepare(
    'SELECT pr.id, pr.user_id, pr.expires_at, pr.used, u.email, u.username
       FROM password_resets pr
       JOIN users u ON u.id = pr.user_id
      WHERE pr.token = ?
      LIMIT 1'
);
$stmt->execute([$token]);
$reset = $stmt->fetch();

if (!$reset || $reset['used'] || strtotime($reset['expires_at']) < time()) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'This reset link is invalid or has expired']);
    exit;
}

$hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
db()->prepare('UPDATE users SET password_hash = ? WHERE id = ?')->execute([$hash, $reset['user_id']]);
db()->prepare('UPDATE password_resets SET used = 1 WHERE id = ?')->execute([$reset['id']]);

echo json_encode(['success' => true, 'message' => 'Password updated. You can now log in.']);
