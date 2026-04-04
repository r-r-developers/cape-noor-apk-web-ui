<?php
// GET /api/profile?mosque=<slug>
// Returns the mosque profile for the given slug (or the default mosque).

header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../lib/Db.php';

$mosqueSlug  = trim($_GET['mosque']   ?? '');
$mosqueShort = trim($_GET['short_id'] ?? '');

if ($mosqueShort) {
    $stmt = db()->prepare('SELECT * FROM mosques WHERE short_id = ? LIMIT 1');
    $stmt->execute([$mosqueShort]);
} elseif ($mosqueSlug) {
    $stmt = db()->prepare('SELECT * FROM mosques WHERE slug=?');
    $stmt->execute([$mosqueSlug]);
} else {
    $stmt = db()->query('SELECT * FROM mosques WHERE is_default=1 LIMIT 1');
}

$row = $stmt->fetch();

if (!$row) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'Mosque profile not found']);
    exit;
}

foreach (['announcements', 'social_media', 'sponsors'] as $f) {
    $row[$f] = json_decode($row[$f] ?? '[]', true) ?? [];
}

// Load per-mosque adhan offsets (object keyed by prayer name)
$adhanOffsets = null;
if (!empty($row['adhan_offsets'])) {
    $decoded = json_decode($row['adhan_offsets'], true);
    if (is_array($decoded)) $adhanOffsets = $decoded;
}

$profile = [
    'slug'             => $row['slug'],
    'name'             => $row['name'],
    'logo'             => $row['logo'],
    'contact'          => ['address' => $row['address'] ?? '', 'phone' => $row['phone'] ?? '', 'website' => $row['website'] ?? ''],
    'features'         => ['showFasting' => (bool)$row['show_fasting'], 'showSidebars' => (bool)($row['show_sidebars'] ?? 1)],
    'colors'           => ['primary' => $row['color_primary'], 'gold' => $row['color_gold'], 'background' => $row['color_bg']],
    'announcements'    => $row['announcements'],
    'socialMedia'      => $row['social_media'],
    'sponsors'         => $row['sponsors'],
    'facebookPageId'   => $row['facebook_page_id'],
    'facebookPageName' => $row['facebook_page_name'],
    'adhanOffsets'     => $adhanOffsets,
    'shortId'          => $row['short_id'],
];

echo json_encode(['success' => true, 'profile' => $profile], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
