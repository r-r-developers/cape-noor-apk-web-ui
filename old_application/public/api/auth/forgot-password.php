<?php
// POST /api/auth/forgot-password  { email }
// Sends a password-reset link; always returns 200 to prevent user enumeration.

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';
require_once __DIR__ . '/../../lib/Mail.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$body  = json_decode(file_get_contents('php://input'), true) ?: [];
$email = strtolower(trim($body['email'] ?? ''));

// Always respond success to prevent user enumeration
$ok = ['success' => true, 'message' => 'If that email exists, a reset link has been sent.'];

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode($ok);
    exit;
}

$stmt = db()->prepare('SELECT id, username, email FROM users WHERE email = ? AND is_active = 1 LIMIT 1');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    echo json_encode($ok);
    exit;
}

// Invalidate previous tokens for this user
db()->prepare('DELETE FROM password_resets WHERE user_id = ?')->execute([$user['id']]);

$token     = bin2hex(random_bytes(32));
$expiresAt = date('Y-m-d H:i:s', time() + 3600);

db()->prepare(
    'INSERT INTO password_resets (user_id, token, expires_at) VALUES (?, ?, ?)'
)->execute([$user['id'], $token, $expiresAt]);

try {
    (new Mailer())->sendPasswordReset($user['email'], $user['username'], $token);
} catch (Throwable $e) {
    // Log but don't expose to client
    error_log('[mail error] ' . $e->getMessage());
}

echo json_encode($ok);
