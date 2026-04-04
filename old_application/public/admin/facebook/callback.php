<?php
/**
 * /admin/facebook/callback
 *
 * Handles the Facebook OAuth redirect. Uses a PHP session to pass the fetched
 * pages data to the page-selection step so credentials are never exposed in
 * JavaScript. Requires an active admin session.
 */
session_start();
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';

// ── Handle page selection (second pass — form POST) ───────────────────────────

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['page_index'])) {
    $pageIndex  = (int)$_POST['page_index'];
    $pages      = $_SESSION['fb_pages']      ?? [];
    $mosqueSlug = $_SESSION['fb_mosque_slug'] ?? '';

    if (empty($pages) || !$mosqueSlug) {
        showError('Session expired. Please start the Facebook authorization again.');
    }

    if (!isset($pages[$pageIndex])) {
        showError('Invalid page selection.');
    }

    $page = $pages[$pageIndex];

    // Save to the data file directly (no extra API call needed)
    $data = db()->prepare('SELECT 1 FROM mosques WHERE slug=?');
    $data->execute([$mosqueSlug]);
    if (!$data->fetch()) {
        showError("Mosque \"{$mosqueSlug}\" not found. It may have been deleted.");
    }

    db()->prepare(
        'UPDATE mosques SET facebook_page_id=?, facebook_page_name=?, facebook_access_token=? WHERE slug=?'
    )->execute([$page['id'], $page['name'], $page['access_token'], $mosqueSlug]);

    // Clear session data
    unset($_SESSION['fb_pages'], $_SESSION['fb_mosque_slug']);

    showSuccess(htmlspecialchars($page['name'], ENT_QUOTES, 'UTF-8'));
}

// ── OAuth callback (first pass — GET with ?code=...) ─────────────────────────

$code      = $_GET['code']              ?? '';
$state     = $_GET['state']             ?? '';
$fbError   = $_GET['error']             ?? '';
$fbErrDesc = $_GET['error_description'] ?? '';

if ($fbError) {
    showError(htmlspecialchars($fbErrDesc ?: $fbError, ENT_QUOTES, 'UTF-8'));
}

if (!$code || !$state) {
    showError('Missing authorization code or state parameter.');
}

$stateData  = json_decode(base64_decode($state), true);
$mosqueSlug = $stateData['mosqueSlug'] ?? '';

if (!$mosqueSlug) {
    showError('Invalid state parameter — mosque slug is missing.');
}

$redirectUri = FACEBOOK_REDIRECT_URI ?: (
    (isset($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'] . '/admin/facebook/callback'
);

// Exchange authorization code for user access token
$tokenUrl = 'https://graph.facebook.com/v18.0/oauth/access_token?' . http_build_query([
    'client_id'     => FACEBOOK_APP_ID,
    'client_secret' => FACEBOOK_APP_SECRET,
    'redirect_uri'  => $redirectUri,
    'code'          => $code,
]);

$ch = curl_init($tokenUrl);
curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15, CURLOPT_SSL_VERIFYPEER => true]);
$tokenRaw  = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($tokenRaw === false || $curlError) {
    showError('Failed to exchange code for token: ' . htmlspecialchars($curlError, ENT_QUOTES, 'UTF-8'));
}

$tokenData       = json_decode($tokenRaw, true);
$userAccessToken = $tokenData['access_token'] ?? '';
if (!$userAccessToken) {
    showError('Facebook did not return an access token.');
}

// Fetch pages the user manages
$ch = curl_init('https://graph.facebook.com/v18.0/me/accounts?access_token=' . urlencode($userAccessToken));
curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 10, CURLOPT_SSL_VERIFYPEER => true]);
$pagesRaw  = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($pagesRaw === false || $curlError) {
    showError('Failed to fetch Facebook pages: ' . htmlspecialchars($curlError, ENT_QUOTES, 'UTF-8'));
}

$pagesData = json_decode($pagesRaw, true);
$pages     = $pagesData['data'] ?? [];

if (empty($pages)) {
    showError("No Facebook Pages found. Make sure you are an admin of the page and granted the required permissions.");
}

// Store pages in session — no credentials go to JavaScript
$_SESSION['fb_pages']       = $pages;
$_SESSION['fb_mosque_slug'] = $mosqueSlug;

// ── Render page-selection UI ──────────────────────────────────────────────────
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Select Facebook Page</title>
  <style>
    body { font-family: sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
    h2   { color: #1e293b; }
    form { margin: 0; }
    .page-option { padding: 15px; margin: 10px 0; border: 2px solid #e2e8f0; border-radius: 6px; cursor: pointer; transition: border-color 0.2s; background: white; width: 100%; text-align: left; }
    .page-option:hover { border-color: #3b82f6; }
    .page-name { font-weight: 600; font-size: 1.1rem; color: #1e293b; }
    .page-id   { color: #64748b; font-size: 0.9rem; margin-top: 4px; }
    a { color: #3b82f6; }
  </style>
</head>
<body>
  <h2>Select Your Facebook Page</h2>
  <p>Choose which page to connect for <strong><?= htmlspecialchars($mosqueSlug, ENT_QUOTES, 'UTF-8') ?></strong>:</p>

  <?php foreach ($pages as $i => $page): ?>
    <form method="POST">
      <input type="hidden" name="page_index" value="<?= $i ?>" />
      <button type="submit" class="page-option">
        <div class="page-name"><?= htmlspecialchars($page['name'], ENT_QUOTES, 'UTF-8') ?></div>
        <div class="page-id">ID: <?= htmlspecialchars($page['id'], ENT_QUOTES, 'UTF-8') ?></div>
      </button>
    </form>
  <?php endforeach; ?>

  <p style="margin-top:24px"><a href="/admin">← Back to Admin Panel</a></p>
</body>
</html>
<?php

// ── Helper functions ──────────────────────────────────────────────────────────

function showError(string $message): never {
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Error</title></head><body>';
    echo '<h2>Facebook Authorization Failed</h2>';
    echo '<p>' . $message . '</p>';
    echo '<p><a href="/admin">← Back to Admin Panel</a></p>';
    echo '</body></html>';
    exit;
}

function showSuccess(string $pageName): never {
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Connected</title>';
    echo '<meta http-equiv="refresh" content="2;url=/admin" />';
    echo '</head><body>';
    echo '<h2>✅ Connected Successfully!</h2>';
    echo '<p>Facebook Page &ldquo;' . $pageName . '&rdquo; is now connected.</p>';
    echo '<p>Redirecting back to admin panel…</p>';
    echo '<p><a href="/admin">← Back to Admin Panel</a></p>';
    echo '</body></html>';
    exit;
}
