<?php
// POST /api/admin/set-default  { "slug": "..." }

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';

$user = requireRole('super_admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true) ?: [];
$slug = trim($body['slug'] ?? '');

if (!$slug) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'slug is required']);
    exit;
}

$check = db()->prepare('SELECT 1 FROM mosques WHERE slug=?');
$check->execute([$slug]);
if (!$check->fetch()) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => "Mosque \"{$slug}\" not found"]);
    exit;
}

db()->exec('UPDATE mosques SET is_default=0');
db()->prepare('UPDATE mosques SET is_default=1 WHERE slug=?')->execute([$slug]);

echo json_encode(['success' => true]);
