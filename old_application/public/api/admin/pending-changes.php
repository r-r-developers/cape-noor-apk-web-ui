<?php
/**
 * Pending changes management.
 *
 * Routes:
 *   GET  /api/admin/pending-changes                    list (filtered by role)
 *   POST /api/admin/pending-changes/{id}/approve       approve and apply
 *   POST /api/admin/pending-changes/{id}/reject        reject
 */

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';
require_once __DIR__ . '/../../lib/Mail.php';

$user = requireAuth();

// ── Parse id and sub-action ───────────────────────────────────────────────────
$uri       = strtok($_SERVER['REQUEST_URI'], '?');
$parts     = explode('/pending-changes', $uri, 2);
$tail      = isset($parts[1]) ? trim($parts[1], '/') : '';
$segments  = $tail !== '' ? explode('/', $tail, 2) : [];
$changeId  = isset($segments[0]) && ctype_digit($segments[0]) ? (int)$segments[0] : null;
$subAction = $segments[1] ?? null;
$method    = $_SERVER['REQUEST_METHOD'];

function respond(array $p, int $s = 200): never {
    http_response_code($s);
    echo json_encode($p, JSON_UNESCAPED_UNICODE);
    exit;
}

function jsonBody(): array { return json_decode(file_get_contents('php://input'), true) ?: []; }

// ── Helper: also used in mosques.php as standalone; re-declare safely ─────────
if (!function_exists('applyPendingChange')) {
    function applyPendingChange(string $mosqueSlug, array $data): void {
        db()->prepare("
            UPDATE mosques SET
                name=:name, logo=:logo, address=:address, phone=:phone, website=:website,
                show_fasting=:show_fasting, color_primary=:color_primary,
                color_gold=:color_gold, color_bg=:color_bg,
                announcements=:announcements, social_media=:social_media, sponsors=:sponsors
            WHERE slug=:slug
        ")->execute([
            ':name'          => $data['name']                           ?? '',
            ':logo'          => $data['logo']                           ?? null,
            ':address'       => $data['contact']['address']             ?? '',
            ':phone'         => $data['contact']['phone']               ?? '',
            ':website'       => $data['contact']['website']             ?? '',
            ':show_fasting'  => ($data['features']['showFasting'] ?? true) ? 1 : 0,
            ':color_primary' => $data['colors']['primary']              ?? '#22c55e',
            ':color_gold'    => $data['colors']['gold']                 ?? '#d4af37',
            ':color_bg'      => $data['colors']['background']           ?? '#0a0f1a',
            ':announcements' => json_encode($data['announcements']      ?? []),
            ':social_media'  => json_encode($data['socialMedia']        ?? []),
            ':sponsors'      => json_encode($data['sponsors']           ?? []),
            ':slug'          => $mosqueSlug,
        ]);
    }
}

// ── GET list ──────────────────────────────────────────────────────────────────
if ($method === 'GET' && !$changeId) {
    if ($user['role'] === 'super_admin') {
        $stmt = db()->query(
            "SELECT pc.*, u.username AS submitter_name, m.name AS mosque_name,
                    r.username AS reviewer_name
               FROM pending_changes pc
               JOIN users u ON u.id = pc.submitted_by
               JOIN mosques m ON m.slug = pc.mosque_slug
          LEFT JOIN users r ON r.id = pc.reviewed_by
              ORDER BY pc.created_at DESC"
        );
        $rows = $stmt->fetchAll();
    } elseif ($user['role'] === 'mosque_admin') {
        $slugs = array_column($user['mosques'], 'mosque_slug');
        if (empty($slugs)) respond(['success' => true, 'changes' => []]);
        $in   = implode(',', array_fill(0, count($slugs), '?'));
        $stmt = db()->prepare(
            "SELECT pc.*, u.username AS submitter_name, m.name AS mosque_name,
                    r.username AS reviewer_name
               FROM pending_changes pc
               JOIN users u ON u.id = pc.submitted_by
               JOIN mosques m ON m.slug = pc.mosque_slug
          LEFT JOIN users r ON r.id = pc.reviewed_by
              WHERE pc.mosque_slug IN ({$in})
              ORDER BY pc.created_at DESC"
        );
        $stmt->execute($slugs);
        $rows = $stmt->fetchAll();
    } else {
        // Maintainers see their own submissions
        $stmt = db()->prepare(
            "SELECT pc.*, u.username AS submitter_name, m.name AS mosque_name,
                    r.username AS reviewer_name
               FROM pending_changes pc
               JOIN users u ON u.id = pc.submitted_by
               JOIN mosques m ON m.slug = pc.mosque_slug
          LEFT JOIN users r ON r.id = pc.reviewed_by
              WHERE pc.submitted_by = ?
              ORDER BY pc.created_at DESC"
        );
        $stmt->execute([$user['id']]);
        $rows = $stmt->fetchAll();
    }

    // Decode changes JSON
    foreach ($rows as &$row) {
        $row['changes'] = json_decode($row['changes'] ?? '{}', true) ?? [];
    }

    respond(['success' => true, 'changes' => $rows]);
}

// ── POST approve ──────────────────────────────────────────────────────────────
if ($method === 'POST' && $changeId && $subAction === 'approve') {
    $stmt = db()->prepare('SELECT * FROM pending_changes WHERE id=?');
    $stmt->execute([$changeId]);
    $change = $stmt->fetch();

    if (!$change) respond(['success' => false, 'error' => 'Change not found'], 404);
    if ($change['status'] !== 'pending') respond(['success' => false, 'error' => 'This change is already ' . $change['status']], 400);
    if (!canApproveMosque($user, $change['mosque_slug'])) respond(['success' => false, 'error' => 'Forbidden'], 403);

    $data = json_decode($change['changes'], true) ?? [];
    applyPendingChange($change['mosque_slug'], $data);

    db()->prepare(
        'UPDATE pending_changes SET status="approved", reviewed_by=?, reviewed_at=NOW() WHERE id=?'
    )->execute([$user['id'], $changeId]);

    // Notify submitter
    $submitter = db()->prepare('SELECT email, username FROM users WHERE id=?');
    $submitter->execute([$change['submitted_by']]);
    $s = $submitter->fetch();
    $mosqueName = db()->prepare('SELECT name FROM mosques WHERE slug=?');
    $mosqueName->execute([$change['mosque_slug']]);
    $mosqName = $mosqueName->fetchColumn() ?: $change['mosque_slug'];
    $note = jsonBody()['note'] ?? '';
    try { (new Mailer())->sendChangeReviewed($s['email'], $s['username'], $mosqName, 'approved', $note); }
    catch (Throwable $e) { error_log('[mail] ' . $e->getMessage()); }

    respond(['success' => true]);
}

// ── POST reject ───────────────────────────────────────────────────────────────
if ($method === 'POST' && $changeId && $subAction === 'reject') {
    $stmt = db()->prepare('SELECT * FROM pending_changes WHERE id=?');
    $stmt->execute([$changeId]);
    $change = $stmt->fetch();

    if (!$change) respond(['success' => false, 'error' => 'Change not found'], 404);
    if ($change['status'] !== 'pending') respond(['success' => false, 'error' => 'This change is already ' . $change['status']], 400);
    if (!canApproveMosque($user, $change['mosque_slug'])) respond(['success' => false, 'error' => 'Forbidden'], 403);

    $note = trim(jsonBody()['note'] ?? '');
    db()->prepare(
        'UPDATE pending_changes SET status="rejected", reviewed_by=?, review_note=?, reviewed_at=NOW() WHERE id=?'
    )->execute([$user['id'], $note, $changeId]);

    $submitter = db()->prepare('SELECT email, username FROM users WHERE id=?');
    $submitter->execute([$change['submitted_by']]);
    $s = $submitter->fetch();
    $mosqueName = db()->prepare('SELECT name FROM mosques WHERE slug=?');
    $mosqueName->execute([$change['mosque_slug']]);
    $mosqName = $mosqueName->fetchColumn() ?: $change['mosque_slug'];
    try { (new Mailer())->sendChangeReviewed($s['email'], $s['username'], $mosqName, 'rejected', $note); }
    catch (Throwable $e) { error_log('[mail] ' . $e->getMessage()); }

    respond(['success' => true]);
}

respond(['success' => false, 'error' => 'Method not allowed'], 405);
