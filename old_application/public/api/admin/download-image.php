<?php
// POST /api/admin/download-image  { "url": "https://..." }
// Downloads a remote image (max 2 MB) and stores it under uploads/social/.

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

$body = json_decode(file_get_contents('php://input'), true) ?: [];
$url  = trim($body['url'] ?? '');

if (!$url) {
    http_response_code(400);
    echo json_encode(['error' => 'URL is required']);
    exit;
}

// Only allow http/https to prevent SSRF against internal services
$parsed = parse_url($url);
if (!$parsed || !in_array($parsed['scheme'] ?? '', ['http', 'https'], true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid URL — must start with http:// or https://']);
    exit;
}

// Block private/loopback IP ranges (SSRF protection)
$host = $parsed['host'] ?? '';
if (filter_var($host, FILTER_VALIDATE_IP)) {
    $flags = FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE;
    if (!filter_var($host, FILTER_VALIDATE_IP, $flags)) {
        http_response_code(400);
        echo json_encode(['error' => 'Requests to private/internal IP addresses are not allowed']);
        exit;
    }
}

// Download (cap at 2 MB)
$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; SalaahTimesApp/1.0)',
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS      => 5,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$imgData     = curl_exec($ch);
$httpCode    = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
$curlError   = curl_error($ch);
curl_close($ch);

if ($imgData === false || $curlError) {
    http_response_code(500);
    echo json_encode(['error' => 'Download failed', 'details' => $curlError]);
    exit;
}

if ($httpCode === 403) {
    http_response_code(500);
    echo json_encode(['error' => 'Access denied — image may be protected']);
    exit;
}

if ($httpCode === 404) {
    http_response_code(500);
    echo json_encode(['error' => 'Image not found at URL']);
    exit;
}

if (strlen($imgData) > 2 * 1024 * 1024) {
    http_response_code(500);
    echo json_encode(['error' => 'Image too large (max 2 MB)']);
    exit;
}

// Validate MIME type from content
$finfo    = new finfo(FILEINFO_MIME_TYPE);
$mimeType = $finfo->buffer($imgData);
$allowed  = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

if (!in_array($mimeType, $allowed, true)) {
    http_response_code(400);
    echo json_encode(['error' => 'URL does not point to a supported image (JPEG, PNG, GIF, WebP)']);
    exit;
}

$ext = match ($mimeType) {
    'image/png'  => '.png',
    'image/gif'  => '.gif',
    'image/webp' => '.webp',
    default      => '.jpg',
};

$filename  = bin2hex(random_bytes(16)) . $ext;
$uploadDir = UPLOAD_DIR . '/social';

if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

file_put_contents($uploadDir . '/' . $filename, $imgData);

echo json_encode(['success' => true, 'path' => '/uploads/social/' . $filename]);
