<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../lib/Db.php';
require_once __DIR__ . '/../lib/Auth.php';

// Server-side auth guard — unauthenticated users never receive this page
$currentUser = getCurrentUser();
if (!$currentUser) {
    header('Location: /admin/login.php');
    exit;
}

$roleLabels = [
    'super_admin'  => '&#x1F511; Super Admin',
    'mosque_admin' => '&#x1F54C; Mosque Admin',
    'maintainer'   => '&#x270F;&#xFE0F; Maintainer',
];
$userBadge   = htmlspecialchars($currentUser['username']) . ' (' . ($roleLabels[$currentUser['role']] ?? htmlspecialchars($currentUser['role'])) . ')';
$isSuperAdmin = $currentUser['role'] === 'super_admin';
$canManage    = in_array($currentUser['role'], ['super_admin', 'mosque_admin'], true);
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Admin — Salaah Times (<?= htmlspecialchars($currentUser['username']) ?>)</title>
  <link rel="stylesheet" href="admin.css?v=3" />
</head>
<body>
  <div class="admin-container">

    <!-- HEADER -->
    <header class="admin-header">
      <h1>Salaah Times Admin</h1>
      <div style="display:flex;align-items:center;gap:1rem;">
        <span id="user-badge" class="user-badge"><?= $userBadge ?></span>
        <a href="/" class="btn btn-secondary">← Site</a>
        <button id="logout-btn" class="btn btn-secondary">Logout</button>
      </div>
    </header>

    <!-- TABS -->
    <nav class="admin-tabs" id="admin-tabs">
      <button class="tab-btn active" data-tab="mosques">Mosques</button>
      <button class="tab-btn" data-tab="pending" id="tab-pending" <?= !$canManage ? 'hidden' : '' ?>>
        Pending <span id="pending-badge" class="badge" hidden></span>
      </button>
      <button class="tab-btn" data-tab="users" id="tab-users" <?= !$canManage ? 'hidden' : '' ?>>Users</button>
      <button class="tab-btn" data-tab="settings" id="tab-settings" <?= !$isSuperAdmin ? 'hidden' : '' ?>>Settings</button>
    </nav>

    <main class="admin-main">

      <!-- TAB: MOSQUES -->
      <div id="tab-panel-mosques" class="tab-panel">
        <section class="admin-section">
          <div class="section-header">
            <h2>Mosques</h2>
            <button id="add-mosque-btn" class="btn btn-primary" <?= !$isSuperAdmin ? 'hidden' : '' ?>>+ Add Mosque</button>
          </div>
          <div id="mosque-list" class="mosque-list">Loading&hellip;</div>
        </section>

        <section id="edit-section" class="admin-section" hidden>
          <div class="section-header">
            <h2 id="form-title">Add Mosque</h2>
            <button id="cancel-edit-btn" class="btn btn-secondary">Cancel</button>
          </div>
          <form id="mosque-form" class="mosque-form">
            <input type="hidden" id="edit-slug" />
            <div class="form-group">
              <label for="slug">Slug (URL identifier)*</label>
              <input type="text" id="slug" required pattern="[a-z0-9-]+" placeholder="e.g., masjid-al-azhar" />
              <small>Lowercase letters, numbers, hyphens only</small>
            </div>
            <div class="form-group">
              <label for="name">Mosque Name*</label>
              <input type="text" id="name" required />
            </div>
            <div class="form-group">
              <label for="logo-upload">Logo Image</label>
              <input type="file" id="logo-upload" accept="image/*" />
              <img id="logo-preview" class="image-preview" style="display:none;" alt="Logo preview" />
              <p id="logo-current" class="current-file"></p>
            </div>
            <fieldset class="form-group">
              <legend>Contact Information</legend>
              <label for="address">Address</label><input type="text" id="address" />
              <label for="phone">Phone</label><input type="tel" id="phone" />
              <label for="website">Website</label><input type="url" id="website" placeholder="https://" />
            </fieldset>
            <fieldset class="form-group">
              <legend>Features</legend>
              <label class="checkbox-label">
                <input type="checkbox" id="show-fasting" checked /> Show Fasting Section
              </label>
              <label class="checkbox-label">
                <input type="checkbox" id="show-sidebars" checked /> Show Sponsor Sidebars <small>(uncheck for full-screen mode)</small>
              </label>
              <label class="checkbox-label" id="auto-approve-row" hidden>
                <input type="checkbox" id="auto-approve" /> Auto-approve maintainer changes
              </label>
            </fieldset>
            <fieldset class="form-group">
              <legend>Colors</legend>
              <label for="color-primary">Primary</label>
              <input type="color" id="color-primary" value="#22c55e" />
              <label for="color-gold">Accent (Gold)</label>
              <input type="color" id="color-gold" value="#d4af37" />
              <label for="color-bg">Background</label>
              <input type="color" id="color-bg" value="#0a0f1a" />
            </fieldset>
            <div class="form-group">
              <label for="announcements">Announcements (one per line)</label>
              <textarea id="announcements" rows="4"></textarea>
            </div>
            <div class="form-group">
              <label>Social Media (Left Sidebar)</label>
              <div id="social-list" class="sponsors-list"></div>
              <div style="display:flex;gap:.5rem;margin-top:.5rem;flex-wrap:wrap;">
                <button type="button" id="add-social-btn" class="btn btn-secondary">+ Upload Image</button>
                <button type="button" id="download-from-url-btn" class="btn btn-primary">📥 Paste &amp; Download URLs</button>
              </div>
            </div>
            <div class="form-group">
              <label>Sponsor Images (Right Sidebar)</label>
              <div id="sponsors-list" class="sponsors-list"></div>
              <button type="button" id="add-sponsor-btn" class="btn btn-secondary">+ Add Sponsor</button>
            </div>
            <fieldset class="form-group">
              <legend>Adhan Alert Times <small style="font-weight:400;color:var(--text-muted)">(per prayer)</small></legend>
              <p style="color:var(--text-muted);font-size:.85rem;margin-bottom:.75rem;">Set how many minutes before each prayer the adhan fires. 0 = at prayer time.</p>
              <div id="mosque-adhan-offsets"></div>
            </fieldset>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Save Mosque</button>
              <button type="button" id="delete-mosque-btn" class="btn btn-danger" hidden>Delete Mosque</button>
            </div>
          </form>
        </section>
      </div>

      <!-- TAB: PENDING CHANGES -->
      <div id="tab-panel-pending" class="tab-panel" hidden>
        <section class="admin-section">
          <div class="section-header">
            <h2>Pending Changes</h2>
            <button class="btn btn-secondary" onclick="loadPendingChanges()">↺ Refresh</button>
          </div>
          <div id="pending-list">Loading&hellip;</div>
        </section>
      </div>

      <!-- TAB: USERS -->
      <div id="tab-panel-users" class="tab-panel" hidden>
        <section class="admin-section">
          <div class="section-header">
            <h2>Users</h2>
            <button id="add-user-btn" class="btn btn-primary">+ Add User</button>
          </div>
          <div id="user-list">Loading&hellip;</div>
        </section>
        <section id="user-edit-section" class="admin-section" hidden>
          <div class="section-header">
            <h2 id="user-form-title">Add User</h2>
            <button id="cancel-user-btn" class="btn btn-secondary">Cancel</button>
          </div>
          <form id="user-form" class="mosque-form">
            <input type="hidden" id="user-edit-id" />
            <div class="form-group">
              <label for="user-username">Username*</label>
              <input type="text" id="user-username" pattern="[a-z0-9_]+" placeholder="lowercase, letters/numbers/_" />
            </div>
            <div class="form-group">
              <label for="user-email">Email*</label>
              <input type="email" id="user-email" />
            </div>
            <div class="form-group">
              <label for="user-role">Role*</label>
              <select id="user-role">
                <option value="maintainer">Maintainer — submits changes for approval</option>
                <option value="mosque_admin">Mosque Admin — approves changes, manages mosque</option>
                <option value="super_admin">Super Admin — full access</option>
              </select>
            </div>
            <div class="form-group">
              <label for="user-mosque">Assign to Mosque</label>
              <select id="user-mosque"><option value="">— none —</option></select>
              <label class="checkbox-label" style="margin-top:.5rem;">
                <input type="checkbox" id="user-can-approve" />
                Grant approval rights on this mosque
              </label>
            </div>
            <div class="form-group">
              <label for="user-password">Password <small id="pw-hint">(min 8 chars)</small></label>
              <input type="password" id="user-password" autocomplete="new-password" />
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Save User</button>
              <button type="button" id="toggle-active-btn" class="btn btn-secondary" hidden>Deactivate / Reactivate</button>
            </div>
          </form>
        </section>
      </div>

      <!-- TAB: SETTINGS -->
      <div id="tab-panel-settings" class="tab-panel" hidden>
        <section class="admin-section">
          <div class="section-header"><h2>SMTP / Email Settings</h2></div>
          <form id="smtp-form" class="mosque-form">
            <div class="form-group">
              <label for="smtp-host">SMTP Host</label>
              <input type="text" id="smtp-host" placeholder="smtp.gmail.com" />
            </div>
            <div class="form-group">
              <label for="smtp-port">Port</label>
              <input type="number" id="smtp-port" value="587" />
            </div>
            <div class="form-group">
              <label for="smtp-secure">Security</label>
              <select id="smtp-secure">
                <option value="tls">TLS / STARTTLS (port 587)</option>
                <option value="ssl">SSL (port 465)</option>
                <option value="">None</option>
              </select>
            </div>
            <div class="form-group">
              <label for="smtp-username">Username</label>
              <input type="text" id="smtp-username" autocomplete="username" />
            </div>
            <div class="form-group">
              <label for="smtp-password">Password <small>(blank = keep current)</small></label>
              <input type="password" id="smtp-password" autocomplete="current-password" />
            </div>
            <div class="form-group">
              <label for="smtp-from-email">From Email</label>
              <input type="email" id="smtp-from-email" />
            </div>
            <div class="form-group">
              <label for="smtp-from-name">From Name</label>
              <input type="text" id="smtp-from-name" />
            </div>
            <div class="form-group">
              <label for="smtp-test-email">Send Test Email To <small>(optional)</small></label>
              <input type="email" id="smtp-test-email" placeholder="test@example.com" />
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Save SMTP Settings</button>
            </div>
          </form>
        </section>

        <section class="admin-section">
          <div class="section-header"><h2>Change My Password</h2></div>
          <form id="password-form" class="mosque-form">
            <div class="form-group">
              <label for="new-password">New Password</label>
              <input type="password" id="new-password" minlength="8" autocomplete="new-password" />
            </div>
            <div class="form-group">
              <label for="confirm-password">Confirm Password</label>
              <input type="password" id="confirm-password" autocomplete="new-password" />
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Update Password</button>
            </div>
          </form>
        </section>
      </div>

    </main>
  </div>

  <script>
    // Bootstrap data injected server-side
    window.__CURRENT_USER__ = <?= json_encode([
        'id'       => $currentUser['id'],
        'username' => $currentUser['username'],
        'role'     => $currentUser['role'],
        'mosques'  => $currentUser['mosques'],
    ], JSON_HEX_TAG | JSON_HEX_AMP) ?>;
  </script>
  <script src="admin.js"></script>
</body>
</html>
