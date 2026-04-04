<?php
// POST /api/facebook/fetch-photos  { pageId, accessToken, limit? }
// Fetches uploaded photos from a Facebook Page via the Graph API.

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
$pageId      = trim($body['pageId']      ?? '');
$accessToken = trim($body['accessToken'] ?? '');
$limit       = min((int)($body['limit']  ?? 5), 100);

if (!$pageId || !$accessToken) {
    http_response_code(400);
    echo json_encode(['error' => 'pageId and accessToken are required']);
    exit;
}

$graphUrl = 'https://graph.facebook.com/v18.0/' . urlencode($pageId) . '/photos?' . http_build_query([
    'access_token' => $accessToken,
    'type'         => 'uploaded',
    'fields'       => 'id,images,created_time,name',
    'limit'        => $limit,
]);

$ch = curl_init($graphUrl);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 10,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$response  = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($response === false || $curlError) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to connect to Facebook API', 'details' => $curlError]);
    exit;
}

$data = json_decode($response, true);

if (!isset($data['data'])) {
    $fbError = $data['error'] ?? null;
    $hint    = '';
    if ($fbError) {
        if (($fbError['code'] ?? 0) === 190) {
            $hint = 'Access token is invalid or expired. Please re-authenticate.';
        } elseif (($fbError['code'] ?? 0) === 100) {
            $hint = 'Invalid Page ID. Use the numeric Page ID, not the page username.';
        }
    }
    http_response_code(500);
    echo json_encode([
        'error'   => $fbError['message'] ?? 'No photos returned from Facebook API',
        'details' => $fbError,
        'hint'    => $hint,
    ]);
    exit;
}

$photos = [];
foreach ($data['data'] as $photo) {
    $largeImage = $photo['images'][0] ?? null;
    if (!$largeImage) continue;
    $photos[] = [
        'url'         => $largeImage['source'],
        'alt'         => $photo['name'] ?? 'Facebook Photo',
        'createdTime' => $photo['created_time'] ?? null,
    ];
}

echo json_encode(['success' => true, 'photos' => $photos, 'total' => count($photos)]);
