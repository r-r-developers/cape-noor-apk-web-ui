<?php
// POST /api/admin/upload/logo  (multipart, field name: "logo")

header('Content-Type: application/json');
require_once __DIR__ . '/../../../config.php';
require_once __DIR__ . '/../../../lib/Db.php';
require_once __DIR__ . '/../../../lib/Auth.php';

$user = requireAuth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

if (empty($_FILES['logo']) || $_FILES['logo']['error'] === UPLOAD_ERR_NO_FILE) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'No file uploaded']);
    exit;
}

$file = $_FILES['logo'];

if ($file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Upload error code: ' . $file['error']]);
    exit;
}

// 500 KB limit
if ($file['size'] > 500 * 1024) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'File too large (max 500 KB)']);
    exit;
}

// Validate MIME type from actual file content (not the browser-supplied type)
$finfo    = new finfo(FILEINFO_MIME_TYPE);
$mimeType = $finfo->file($file['tmp_name']);
$allowed  = ['image/jpeg', 'image/png', 'image/webp'];

if (!in_array($mimeType, $allowed, true)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Only JPEG, PNG, and WebP images are allowed']);
    exit;
}

$ext = match ($mimeType) {
    'image/png'  => '.png',
    'image/webp' => '.webp',
    default      => '.jpg',
};

$filename = 'logo-' . bin2hex(random_bytes(8)) . $ext;
$destDir  = UPLOAD_DIR . '/logos';

if (!is_dir($destDir)) {
    mkdir($destDir, 0755, true);
}

if (!move_uploaded_file($file['tmp_name'], $destDir . '/' . $filename)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to save file']);
    exit;
}

echo json_encode(['success' => true, 'path' => '/uploads/logos/' . $filename]);
