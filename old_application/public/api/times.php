<?php
// GET /api/times?month=YYYY-MM
// Scrapes prayer times from masjids.co.za and returns JSON.
// Results are file-cached so the site is only scraped once per month.

header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

// ── Validate input ────────────────────────────────────────────────────────────

$month = trim($_GET['month'] ?? '');
if (!preg_match('/^\d{4}-\d{2}$/', $month)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'month parameter required in YYYY-MM format']);
    exit;
}

// ── Check file cache ──────────────────────────────────────────────────────────

if (!is_dir(CACHE_DIR)) {
    mkdir(CACHE_DIR, 0755, true);
}

$cacheFile = CACHE_DIR . '/' . $month . '.json';
if (file_exists($cacheFile)) {
    $cached = file_get_contents($cacheFile);
    echo json_encode(['success' => true, 'month' => $month, 'data' => json_decode($cached, true)]);
    exit;
}

// ── Fetch page with cURL ──────────────────────────────────────────────────────

$url = "https://www.masjids.co.za/salaahtimes/capetown/{$month}";
$ch  = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; SalaahTimesApp/1.0)',
    CURLOPT_HTTPHEADER     => ['Accept: text/html,application/xhtml+xml'],
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS      => 5,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$html      = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($html === false || $curlError) {
    http_response_code(502);
    echo json_encode(['success' => false, 'error' => 'Failed to fetch prayer times: ' . $curlError]);
    exit;
}

// ── Parse HTML ────────────────────────────────────────────────────────────────

libxml_use_internal_errors(true);
$dom = new DOMDocument();
$dom->loadHTML($html);
libxml_clear_errors();

$xpath  = new DOMXPath($dom);
$tables = $dom->getElementsByTagName('table');

$targetTable = null;

// Strategy 1: find the table whose first row mentions 'fajr'
foreach ($tables as $table) {
    $firstRow = $xpath->query('.//tr[1]', $table)->item(0);
    if ($firstRow && stripos($firstRow->textContent, 'fajr') !== false) {
        $targetTable = $table;
        break;
    }
}

// Strategy 2: first table that has rows with ≥ 8 cells
if (!$targetTable) {
    foreach ($tables as $table) {
        $rows = $xpath->query('.//tr', $table);
        foreach ($rows as $row) {
            if ($xpath->query('.//td', $row)->length >= 8) {
                $targetTable = $table;
                break 2;
            }
        }
    }
}

if (!$targetTable) {
    http_response_code(502);
    echo json_encode(['success' => false, 'error' => 'Prayer times table not found — site structure may have changed']);
    exit;
}

// ── Extract rows ──────────────────────────────────────────────────────────────
// Table columns: Date(0) Day(1) Fajr(2) Thuhr(3) Asr-S(4) Asr-H(5) Maghrib(6) Isha(7)

$times = [];
foreach ($xpath->query('.//tr', $targetTable) as $row) {
    $cells = $xpath->query('.//td', $row);
    if ($cells->length < 8) continue;

    $get  = fn(int $i): string => trim($cells->item($i)->textContent);
    $fajr = $get(2);

    if (!preg_match('/^\d{1,2}:\d{2}$/', $fajr)) continue;

    $times[] = [
        'date'    => $get(0),   // "20 Mar"
        'day'     => $get(1),   // "Fri"
        'fajr'    => $get(2),   // "05:33"
        'thuhr'   => $get(3),   // "12:57"
        'asr'     => $get(4),   // "16:21" (Shafi'i)
        'maghrib' => $get(6),   // "19:01" (skip Asr-H at index 5)
        'isha'    => $get(7),   // "20:10"
    ];
}

if (empty($times)) {
    http_response_code(502);
    echo json_encode(['success' => false, 'error' => "Parsed zero rows from {$url} — site structure may have changed"]);
    exit;
}

// ── Write cache & respond ─────────────────────────────────────────────────────

file_put_contents($cacheFile, json_encode($times, JSON_UNESCAPED_UNICODE));
echo json_encode(['success' => true, 'month' => $month, 'data' => $times]);
