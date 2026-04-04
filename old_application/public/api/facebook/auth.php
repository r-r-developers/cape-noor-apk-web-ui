<?php
// GET /api/facebook/auth?mosqueSlug=<slug>
// Returns the Facebook OAuth authorization URL.

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';

$user = requireAuth();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

if (!FACEBOOK_APP_ID) {
    http_response_code(500);
    echo json_encode(['error' => 'Facebook App ID not configured. Please set FACEBOOK_APP_ID in config.php.']);
    exit;
}

$mosqueSlug = trim($_GET['mosqueSlug'] ?? '');
if (!$mosqueSlug) {
    http_response_code(400);
    echo json_encode(['error' => 'mosqueSlug is required']);
    exit;
}

$state       = base64_encode(json_encode(['mosqueSlug' => $mosqueSlug]));
$redirectUri = FACEBOOK_REDIRECT_URI ?: (
    (isset($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'] . '/admin/facebook/callback'
);

$authUrl = 'https://www.facebook.com/v18.0/dialog/oauth?' . http_build_query([
    'client_id'    => FACEBOOK_APP_ID,
    'redirect_uri' => $redirectUri,
    'state'        => $state,
    'scope'        => 'pages_show_list,pages_read_engagement',
]);

echo json_encode(['success' => true, 'authUrl' => $authUrl]);
