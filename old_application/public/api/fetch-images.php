<?php
// POST /api/fetch-images  { "url": "https://...", "limit": 5 }
// Fetches <img> tags from a web page and returns their URLs.

header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../lib/Db.php';
require_once __DIR__ . '/../lib/Auth.php';

$user = requireAuth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$body  = json_decode(file_get_contents('php://input'), true) ?: [];
$url   = trim($body['url'] ?? '');
$limit = min((int)($body['limit'] ?? 5), 50);

if (!$url) {
    http_response_code(400);
    echo json_encode(['error' => 'URL is required']);
    exit;
}

$parsed = parse_url($url);
if (!$parsed || !in_array($parsed['scheme'] ?? '', ['http', 'https'], true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid URL — must start with http:// or https://']);
    exit;
}

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_USERAGENT      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    CURLOPT_TIMEOUT        => 10,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS      => 5,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$html      = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($html === false || $curlError) {
    http_response_code(500);
    echo json_encode([
        'error'   => 'Failed to fetch images from URL',
        'details' => $curlError,
        'hint'    => 'Facebook pages use JavaScript rendering. Try right-clicking images → "Copy image address" instead.',
    ]);
    exit;
}

libxml_use_internal_errors(true);
$dom = new DOMDocument();
$dom->loadHTML($html);
libxml_clear_errors();

$xpath  = new DOMXPath($dom);
$scheme = $parsed['scheme'] ?? 'https';
$origin = $scheme . '://' . ($parsed['host'] ?? '');

$images = [];
$seen   = [];

foreach ($xpath->query('//img') as $img) {
    $src = $img->getAttribute('src') ?: $img->getAttribute('data-src');
    if (!$src) continue;

    // Resolve relative URLs
    if (str_starts_with($src, '//')) {
        $src = $scheme . ':' . $src;
    } elseif (str_starts_with($src, '/')) {
        $src = $origin . $src;
    } elseif (!str_starts_with($src, 'http')) {
        $src = rtrim($url, '/') . '/' . ltrim($src, '/');
    }

    // Skip tiny images (icons, tracking pixels)
    $w = (int)$img->getAttribute('width');
    $h = (int)$img->getAttribute('height');
    if (($w > 0 && $w < 100) || ($h > 0 && $h < 100)) continue;

    // Skip common non-photo patterns
    if (preg_match('/icon|logo|avatar/i', $src)) continue;

    if (isset($seen[$src])) continue;
    $seen[$src] = true;

    $images[] = ['url' => $src, 'alt' => $img->getAttribute('alt') ?: ''];
}

$topImages = array_slice($images, 0, $limit);
echo json_encode(['success' => true, 'images' => $topImages, 'total' => count($images)]);
