<?php
// GET /api/auth/me — returns the current authenticated user

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';

$user = requireAuth();

echo json_encode([
    'success' => true,
    'user'    => [
        'id'       => $user['id'],
        'username' => $user['username'],
        'email'    => $user['email'],
        'role'     => $user['role'],
        'mosques'  => $user['mosques'],
    ],
]);
