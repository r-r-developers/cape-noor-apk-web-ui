<?php
// POST /api/facebook/save-page  { mosqueSlug, pageId, pageName, accessToken }
// Stores the selected Facebook Page credentials in the mosque profile.

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';

$user = requireAuth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$body        = json_decode(file_get_contents('php://input'), true) ?: [];
$mosqueSlug  = trim($body['mosqueSlug']  ?? '');
$pageId      = trim($body['pageId']      ?? '');
$pageName    = trim($body['pageName']    ?? '');
$accessToken = trim($body['accessToken'] ?? '');

if (!$mosqueSlug || !$pageId || !$accessToken) {
    http_response_code(400);
    echo json_encode(['error' => 'mosqueSlug, pageId, and accessToken are required']);
    exit;
}

if (!canManageMosque($user, $mosqueSlug)) {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden']);
    exit;
}

$check = db()->prepare('SELECT 1 FROM mosques WHERE slug=?');
$check->execute([$mosqueSlug]);
if (!$check->fetch()) {
    http_response_code(404);
    echo json_encode(['error' => 'Mosque not found']);
    exit;
}

db()->prepare(
    'UPDATE mosques SET facebook_page_id=?, facebook_page_name=?, facebook_access_token=? WHERE slug=?'
)->execute([$pageId, $pageName, $accessToken, $mosqueSlug]);

echo json_encode(['success' => true]);
