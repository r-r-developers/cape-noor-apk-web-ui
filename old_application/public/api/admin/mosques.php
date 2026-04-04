<?php
/**
 * Mosque CRUD — database-backed, role-aware.
 *
 * Routes (matched by .htaccess):
 *   GET    /api/admin/mosques                       list all (filtered by role)
 *   POST   /api/admin/mosques                       create  (super_admin only)
 *   GET    /api/admin/mosques/{slug}                get one
 *   PUT    /api/admin/mosques/{slug}                update  (approved or pending)
 *   DELETE /api/admin/mosques/{slug}                delete  (super_admin only)
 *   POST   /api/admin/mosques/{slug}/auto-approve   toggle auto-approve flag
 */

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';
require_once __DIR__ . '/../../lib/Mail.php';

$user = requireAuth();

// ── Parse slug and sub-action from URI ────────────────────────────────────────
$uri       = strtok($_SERVER['REQUEST_URI'], '?');
$parts     = explode('/mosques', $uri, 2);
$tail      = isset($parts[1]) ? trim($parts[1], '/') : '';
$segments  = $tail !== '' ? explode('/', $tail, 2) : [];
$slug      = $segments[0] ?? null;
$subAction = $segments[1] ?? null;
$method    = $_SERVER['REQUEST_METHOD'];

// ── Helpers ───────────────────────────────────────────────────────────────────

function jsonBody(): array { return json_decode(file_get_contents('php://input'), true) ?: []; }

function respond(array $payload, int $status = 200): never {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function mosqueRow(string $slug): ?array {
    $stmt = db()->prepare('SELECT * FROM mosques WHERE slug = ?');
    $stmt->execute([$slug]);
    $row = $stmt->fetch();
    if (!$row) return null;
    foreach (['announcements', 'social_media', 'sponsors'] as $f) {
        $row[$f] = json_decode($row[$f] ?? '[]', true) ?? [];
    }
    return $row;
}

function rowToProfile(array $row): array {
    return [
        'slug'             => $row['slug'],
        'name'             => $row['name'],
        'logo'             => $row['logo'],
        'contact'          => ['address' => $row['address'] ?? '', 'phone' => $row['phone'] ?? '', 'website' => $row['website'] ?? ''],
        'features'         => ['showFasting' => (bool)$row['show_fasting'], 'showSidebars' => (bool)($row['show_sidebars'] ?? 1)],
        'colors'           => ['primary' => $row['color_primary'], 'gold' => $row['color_gold'], 'background' => $row['color_bg']],
        'announcements'    => $row['announcements'] ?? [],
        'socialMedia'      => $row['social_media']  ?? [],
        'sponsors'         => $row['sponsors']       ?? [],
        'adhanOffsets'     => !empty($row['adhan_offsets']) ? (json_decode($row['adhan_offsets'], true) ?: null) : null,
        'facebookPageId'   => $row['facebook_page_id'],
        'facebookPageName' => $row['facebook_page_name'],
        'autoApprove'      => (bool)$row['auto_approve'],
        'isDefault'        => (bool)$row['is_default'],
        'shortId'          => $row['short_id'],
    ];
}

function applyChanges(string $slug, array $data): array {
    db()->prepare("
        UPDATE mosques SET
            name=:name, logo=:logo, address=:address, phone=:phone, website=:website,
            show_fasting=:show_fasting, show_sidebars=:show_sidebars,
            color_primary=:color_primary, color_gold=:color_gold,
            color_bg=:color_bg, announcements=:announcements, social_media=:social_media,
            sponsors=:sponsors, adhan_offsets=:adhan_offsets
        WHERE slug=:slug
    ")->execute([
        ':name'          => $data['name']                                    ?? '',
        ':logo'          => $data['logo']                                    ?? null,
        ':address'       => $data['contact']['address']                      ?? '',
        ':phone'         => $data['contact']['phone']                        ?? '',
        ':website'       => $data['contact']['website']                      ?? '',
        ':show_fasting'  => ($data['features']['showFasting']  ?? true)  ? 1 : 0,
        ':show_sidebars' => ($data['features']['showSidebars'] ?? true)  ? 1 : 0,
        ':color_primary' => $data['colors']['primary']                       ?? '#22c55e',
        ':color_gold'    => $data['colors']['gold']                          ?? '#d4af37',
        ':color_bg'      => $data['colors']['background']                    ?? '#0a0f1a',
        ':announcements' => json_encode($data['announcements']               ?? []),
        ':social_media'  => json_encode($data['socialMedia']                 ?? []),
        ':sponsors'      => json_encode($data['sponsors']                    ?? []),
        ':adhan_offsets' => isset($data['adhanOffsets']) ? json_encode($data['adhanOffsets']) : null,
        ':slug'          => $slug,
    ]);
    return mosqueRow($slug);
}

// ── GET list ──────────────────────────────────────────────────────────────────
if ($method === 'GET' && !$slug) {
    if ($user['role'] === 'super_admin') {
        $rows = db()->query('SELECT * FROM mosques ORDER BY is_default DESC, name ASC')->fetchAll();
    } else {
        $slugs = array_column($user['mosques'], 'mosque_slug');
        if (empty($slugs)) respond(['success' => true, 'mosques' => []]);
        $in   = implode(',', array_fill(0, count($slugs), '?'));
        $stmt = db()->prepare("SELECT * FROM mosques WHERE slug IN ({$in}) ORDER BY name ASC");
        $stmt->execute($slugs);
        $rows = $stmt->fetchAll();
    }
    foreach ($rows as &$r) {
        foreach (['announcements', 'social_media', 'sponsors'] as $f) {
            $r[$f] = json_decode($r[$f] ?? '[]', true) ?? [];
        }
    }
    respond(['success' => true, 'mosques' => array_map('rowToProfile', $rows)]);
}

// ── GET single ────────────────────────────────────────────────────────────────
if ($method === 'GET' && $slug) {
    if (!canManageMosque($user, $slug)) respond(['success' => false, 'error' => 'Forbidden'], 403);
    $row = mosqueRow($slug);
    if (!$row) respond(['success' => false, 'error' => 'Not found'], 404);
    respond(['success' => true, 'profile' => rowToProfile($row)]);
}

// ── POST auto-approve toggle ──────────────────────────────────────────────────
if ($method === 'POST' && $slug && $subAction === 'auto-approve') {
    if (!canApproveMosque($user, $slug)) respond(['success' => false, 'error' => 'Forbidden'], 403);
    $row = mosqueRow($slug);
    if (!$row) respond(['success' => false, 'error' => 'Not found'], 404);
    $newVal = !$row['auto_approve'];
    db()->prepare('UPDATE mosques SET auto_approve=? WHERE slug=?')->execute([$newVal ? 1 : 0, $slug]);
    respond(['success' => true, 'autoApprove' => $newVal]);
}

// ── POST create ───────────────────────────────────────────────────────────────
if ($method === 'POST' && !$slug) {
    if ($user['role'] !== 'super_admin') respond(['success' => false, 'error' => 'Forbidden'], 403);
    $data  = jsonBody();
    $mSlug = preg_replace('/[^a-z0-9-]/', '', strtolower(trim($data['slug'] ?? '')));
    if (!$mSlug) respond(['success' => false, 'error' => 'A valid slug is required'], 400);

    $exists = db()->prepare('SELECT 1 FROM mosques WHERE slug=?');
    $exists->execute([$mSlug]);
    if ($exists->fetch()) respond(['success' => false, 'error' => "Mosque \"{$mSlug}\" already exists"], 400);

    $count     = (int)db()->query('SELECT COUNT(*) FROM mosques')->fetchColumn();
    $isDefault = ($count === 0) ? 1 : 0;

    // Auto-assign a zero-padded 3-digit short_id (000-999)
    $maxRow  = db()->query("SELECT MAX(CAST(short_id AS UNSIGNED)) AS m FROM mosques WHERE short_id IS NOT NULL")->fetch();
    $nextInt = ($maxRow && $maxRow['m'] !== null) ? ((int)$maxRow['m'] + 1) : 0;
    if ($nextInt > 999) respond(['success' => false, 'error' => 'Maximum mosque limit (1000) reached'], 400);
    $shortId = str_pad($nextInt, 3, '0', STR_PAD_LEFT);

    db()->prepare("
        INSERT INTO mosques (slug,name,logo,address,phone,website,show_fasting,show_sidebars,
            color_primary,color_gold,color_bg,announcements,social_media,sponsors,is_default,short_id,adhan_offsets)
        VALUES (:slug,:name,:logo,:address,:phone,:website,:show_fasting,:show_sidebars,
            :color_primary,:color_gold,:color_bg,'[]','[]','[]',:is_default,:short_id,NULL)
    ")->execute([
        ':slug'          => $mSlug,
        ':name'          => $data['name']                           ?? $mSlug,
        ':logo'          => $data['logo']                           ?? null,
        ':address'       => $data['contact']['address']             ?? '',
        ':phone'         => $data['contact']['phone']               ?? '',
        ':website'       => $data['contact']['website']             ?? '',
        ':show_fasting'  => ($data['features']['showFasting']  ?? true) ? 1 : 0,
        ':show_sidebars' => ($data['features']['showSidebars'] ?? true) ? 1 : 0,
        ':color_primary' => $data['colors']['primary']              ?? '#22c55e',
        ':color_gold'    => $data['colors']['gold']                 ?? '#d4af37',
        ':color_bg'      => $data['colors']['background']           ?? '#0a0f1a',
        ':is_default'    => $isDefault,
        ':short_id'      => $shortId,
    ]);
    respond(['success' => true, 'profile' => rowToProfile(mosqueRow($mSlug))]);
}

// ── PUT update ────────────────────────────────────────────────────────────────
if ($method === 'PUT' && $slug) {
    if (!canManageMosque($user, $slug)) respond(['success' => false, 'error' => 'Forbidden'], 403);
    $row = mosqueRow($slug);
    if (!$row) respond(['success' => false, 'error' => 'Not found'], 404);
    $data = jsonBody();

    // Maintainer without auto-approve → create pending change
    if ($user['role'] === 'maintainer' && !$row['auto_approve']) {
        db()->prepare(
            'INSERT INTO pending_changes (mosque_slug, submitted_by, changes) VALUES (?,?,?)'
        )->execute([$slug, $user['id'], json_encode($data)]);

        // Notify mosque admins by email
        $admins = db()->prepare(
            "SELECT u.email, u.username FROM user_mosques um
               JOIN users u ON u.id=um.user_id
              WHERE um.mosque_slug=? AND u.role='mosque_admin' AND u.is_active=1"
        );
        $admins->execute([$slug]);
        $mailer = null;
        foreach ($admins->fetchAll() as $admin) {
            try {
                $mailer ??= new Mailer();
                $mailer->sendPendingChangeNotification($admin['email'], $admin['username'], $row['name'], $user['username']);
            } catch (Throwable $e) { error_log('[mail] ' . $e->getMessage()); }
        }
        respond(['success' => true, 'pending' => true, 'message' => 'Change submitted for approval']);
    }

    // Direct apply (super_admin / mosque_admin / maintainer with auto_approve)
    respond(['success' => true, 'profile' => rowToProfile(applyChanges($slug, $data))]);
}

// ── DELETE ────────────────────────────────────────────────────────────────────
if ($method === 'DELETE' && $slug) {
    if ($user['role'] !== 'super_admin') respond(['success' => false, 'error' => 'Forbidden'], 403);
    $row = mosqueRow($slug);
    if (!$row) respond(['success' => false, 'error' => 'Not found'], 404);
    db()->prepare('DELETE FROM pending_changes WHERE mosque_slug=?')->execute([$slug]);
    db()->prepare('DELETE FROM user_mosques    WHERE mosque_slug=?')->execute([$slug]);
    db()->prepare('DELETE FROM mosques         WHERE slug=?')->execute([$slug]);
    if ($row['is_default']) {
        $next = db()->query('SELECT slug FROM mosques ORDER BY created_at ASC LIMIT 1')->fetchColumn();
        if ($next) db()->prepare('UPDATE mosques SET is_default=1 WHERE slug=?')->execute([$next]);
    }
    respond(['success' => true]);
}

respond(['success' => false, 'error' => 'Method not allowed'], 405);
