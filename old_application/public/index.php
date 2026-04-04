<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/lib/Db.php';

// Load the mosque profile server-side so we can pre-render title & colors
$mosqueSlug  = trim($_GET['mosque']   ?? '');
$mosqueShort = trim($_GET['short_id'] ?? '');
try {
    if ($mosqueShort && preg_match('/^[0-9]{3}$/', $mosqueShort)) {
        $stmt = db()->prepare('SELECT * FROM mosques WHERE short_id = ? LIMIT 1');
        $stmt->execute([$mosqueShort]);
    } elseif ($mosqueSlug) {
        $stmt = db()->prepare('SELECT * FROM mosques WHERE slug = ? LIMIT 1');
        $stmt->execute([$mosqueSlug]);
    } else {
        $stmt = db()->query('SELECT * FROM mosques WHERE is_default = 1 LIMIT 1');
    }
    $mosqueRow = $stmt->fetch();
} catch (Throwable $e) {
    $mosqueRow = null;
}

$pageTitle    = $mosqueRow ? htmlspecialchars($mosqueRow['name']) . ' — Salaah Times' : 'Salaah Times — Cape Town';
$colorPrimary = htmlspecialchars($mosqueRow['color_primary'] ?? '#22c55e');
$colorGold    = htmlspecialchars($mosqueRow['color_gold']    ?? '#d4af37');
$colorBg      = htmlspecialchars($mosqueRow['color_bg']      ?? '#0a0f1a');
$showSidebars = (bool)($mosqueRow['show_sidebars'] ?? 1);
$resolvedSlug = $mosqueRow['slug'] ?? null;
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title><?= $pageTitle ?></title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Inter:wght@300;400;600&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="style.css?v=2" />
  <?php if ($mosqueRow): ?>
  <style>
    :root {
      --green: <?= $colorPrimary ?>;
      --gold: <?= $colorGold ?>; --gold-text: <?= $colorGold ?>;
      --bg: <?= $colorBg ?>;
    }
  </style>
  <?php endif; ?>
</head>
<body<?= !$showSidebars ? ' class="no-sidebars"' : '' ?>>
  <div id="app" class="app-grid">

    <!-- LEFT SIDEBAR: SPONSORS -->
    <aside id="sponsors-left" class="sponsors-sidebar sponsors-left" hidden>
      <div class="sponsor-display">
        <img id="sponsor-left-img" src="" alt="Sponsor" />
      </div>
    </aside>

    <!-- MAIN CONTENT CENTER -->
    <div class="main-column">

      <!-- HEADER -->
      <header class="site-header">
        <h1 class="site-title">أوقات الصلاة</h1>
        <p class="site-subtitle-en">Salaah Times — Cape Town</p>
        <p id="live-clock" class="live-clock"></p>
      </header>

      <!-- MOSQUE PROFILE -->
      <div id="mosque-profile" class="mosque-profile" hidden>
        <img id="mosque-logo" class="mosque-logo" alt="" />
        <div id="mosque-contact" class="mosque-contact"></div>
      </div>

      <!-- ANNOUNCEMENTS -->
      <div id="announcements" class="announcements-section" hidden></div>

      <!-- LOADING STATE -->
      <div id="loading-state" class="state-message">Loading prayer times…</div>

      <!-- ERROR STATE -->
      <div id="error-state" class="state-message state-error" hidden></div>

      <!-- MAIN CONTENT (hidden until data loads) -->
      <main id="main-content" hidden>

      <!-- COUNTDOWN TO NEXT PRAYER -->
      <section class="countdown-section">
        <p id="next-label" class="next-label">Next Prayer</p>
        <div id="countdown" class="countdown">--:--:--</div>
      </section>

      <!-- PRAYER TIME CARDS -->
      <section class="section prayer-section">
        <h2 class="section-title">Prayer Times</h2>
        <div id="prayer-grid" class="prayer-grid">
          <!-- Cards injected by app.js -->
        </div>
      </section>

      <!-- FASTING SECTION -->
      <section class="section fasting-section">
        <h2 class="section-title">Fasting</h2>
        <div class="fasting-grid">
          <div class="fasting-card">
            <span class="fasting-icon">🌙</span>
            <span class="fasting-label">Sehri ends</span>
            <span id="sehri-time" class="fasting-time">--:--</span>
            <span class="fasting-note">Fajr</span>
          </div>
          <div class="fasting-card">
            <span class="fasting-icon">☀️</span>
            <span class="fasting-label">Iftar</span>
            <span id="iftar-time" class="fasting-time">--:--</span>
            <span class="fasting-note">Maghrib</span>
          </div>
        </div>
      </section>

      <!-- ADHAN ALERTS -->
      <section class="section alerts-section">
        <button id="alerts-btn" class="alerts-btn" type="button">
          🔔 Enable Adhan Alerts
        </button>
        <p class="alerts-desc">
          Alerts at 1 hour, 15 minutes, and at prayer time
        </p>
      </section>

    </main>

    </div>
    <!-- END MAIN COLUMN -->

    <!-- RIGHT SIDEBAR: SPONSORS -->
    <aside id="sponsors-right" class="sponsors-sidebar sponsors-right" hidden>
      <div class="sponsor-display">
        <img id="sponsor-right-img" src="" alt="Sponsor" />
      </div>
    </aside>

  </div>
  <!-- END APP GRID -->

  <!-- TOAST BANNER (alert notification) -->
  <div id="alert-banner" class="alert-banner" role="alert" aria-live="assertive"></div>

  <!-- ADHAN AUDIO -->
  <audio id="adhan-audio" src="/audio/adhan.mp3" preload="auto"></audio>

  <?php if ($resolvedSlug): ?>
  <script>window.__MOSQUE_SLUG__ = <?= json_encode($resolvedSlug) ?>;</script>
  <?php endif; ?>
  <script src="app.js"></script>
</body>
</html>
