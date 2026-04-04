<?php
// POST /api/auth/login  { username, password }

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
$username = trim($body['username'] ?? '');
$password = $body['password'] ?? '';

if (!$username || !$password) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Username and password are required']);
    exit;
}

// Look up by username OR email
$stmt = db()->prepare(
    'SELECT id, username, email, password_hash, role, is_active
       FROM users
      WHERE (username = ? OR email = ?)
      LIMIT 1'
);
$stmt->execute([$username, $username]);
$user = $stmt->fetch();

if (!$user || !$user['is_active'] || !password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'Invalid username or password']);
    exit;
}

// Rotate session ID on login (session fixation protection)
_bootAuth();
session_regenerate_id(true);
$_SESSION['user_id'] = $user['id'];

echo json_encode([
    'success' => true,
    'user'    => [
        'id'       => $user['id'],
        'username' => $user['username'],
        'email'    => $user['email'],
        'role'     => $user['role'],
    ],
]);
