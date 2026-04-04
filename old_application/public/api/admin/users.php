<?php
/**
 * User management — super_admin can manage all; mosque_admin can add maintainers to their mosque.
 *
 * Routes:
 *   GET    /api/admin/users               list users (super_admin: all; mosque_admin: their mosque users)
 *   POST   /api/admin/users               create user (super_admin only)
 *   GET    /api/admin/users/{id}          get one
 *   PUT    /api/admin/users/{id}          update
 *   DELETE /api/admin/users/{id}          delete (super_admin only)
 *   POST   /api/admin/users/{id}/assign   assign user to a mosque
 *   DELETE /api/admin/users/{id}/assign   remove user from a mosque
 */

header('Content-Type: application/json');
require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../lib/Db.php';
require_once __DIR__ . '/../../lib/Auth.php';
require_once __DIR__ . '/../../lib/Mail.php';

$admin = requireAuth();
if (!in_array($admin['role'], ['super_admin', 'mosque_admin'], true)) {
    http_response_code(403);
    echo json_encode(['success' => false, 'error' => 'Forbidden']);
    exit;
}

// ── Parse ID and sub-action ───────────────────────────────────────────────────
$uri       = strtok($_SERVER['REQUEST_URI'], '?');
$parts     = explode('/users', $uri, 2);
$tail      = isset($parts[1]) ? trim($parts[1], '/') : '';
$segments  = $tail !== '' ? explode('/', $tail, 2) : [];
$userId    = isset($segments[0]) && ctype_digit($segments[0]) ? (int)$segments[0] : null;
$subAction = $segments[1] ?? null;
$method    = $_SERVER['REQUEST_METHOD'];

function respond(array $p, int $s = 200): never {
    http_response_code($s);
    echo json_encode($p, JSON_UNESCAPED_UNICODE);
    exit;
}
function jsonBody(): array { return json_decode(file_get_contents('php://input'), true) ?: []; }
function safeUser(array $u): array {
    unset($u['password_hash']);
    // Attach mosque assignments
    $stmt = db()->prepare('SELECT mosque_slug, can_approve FROM user_mosques WHERE user_id=?');
    $stmt->execute([$u['id']]);
    $u['mosques'] = $stmt->fetchAll();
    return $u;
}

// ── GET list ──────────────────────────────────────────────────────────────────
if ($method === 'GET' && !$userId) {
    if ($admin['role'] === 'super_admin') {
        $users = db()->query('SELECT id,username,email,role,is_active,created_at FROM users ORDER BY created_at DESC')->fetchAll();
    } else {
        // mosque_admin: show users assigned to their mosques
        $slugs = array_column($admin['mosques'], 'mosque_slug');
        if (empty($slugs)) respond(['success' => true, 'users' => []]);
        $in   = implode(',', array_fill(0, count($slugs), '?'));
        $stmt = db()->prepare(
            "SELECT DISTINCT u.id,u.username,u.email,u.role,u.is_active,u.created_at
               FROM users u
               JOIN user_mosques um ON um.user_id=u.id
              WHERE um.mosque_slug IN ({$in})
              ORDER BY u.created_at DESC"
        );
        $stmt->execute($slugs);
        $users = $stmt->fetchAll();
    }
    $users = array_map('safeUser', $users);
    respond(['success' => true, 'users' => $users]);
}

// ── GET single ────────────────────────────────────────────────────────────────
if ($method === 'GET' && $userId) {
    $stmt = db()->prepare('SELECT id,username,email,role,is_active,created_at FROM users WHERE id=?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    if (!$user) respond(['success' => false, 'error' => 'User not found'], 404);
    respond(['success' => true, 'user' => safeUser($user)]);
}

// ── POST /assign (assign user to mosque) ──────────────────────────────────────
if ($method === 'POST' && $userId && $subAction === 'assign') {
    $body       = jsonBody();
    $mosqueSlug = trim($body['mosqueSlug'] ?? '');
    $canApprove = !empty($body['canApprove']) ? 1 : 0;

    if (!$mosqueSlug) respond(['success' => false, 'error' => 'mosqueSlug is required'], 400);

    // mosque_admin can only assign to their own mosques
    if ($admin['role'] === 'mosque_admin' && !canManageMosque($admin, $mosqueSlug)) {
        respond(['success' => false, 'error' => 'Forbidden'], 403);
    }

    $stmt = db()->prepare('SELECT id FROM users WHERE id=?');
    $stmt->execute([$userId]);
    if (!$stmt->fetch()) respond(['success' => false, 'error' => 'User not found'], 404);

    $stmt = db()->prepare('SELECT 1 FROM mosques WHERE slug=?');
    $stmt->execute([$mosqueSlug]);
    if (!$stmt->fetch()) respond(['success' => false, 'error' => 'Mosque not found'], 404);

    // Upsert
    db()->prepare(
        'INSERT INTO user_mosques (user_id, mosque_slug, can_approve) VALUES (?,?,?)
         ON DUPLICATE KEY UPDATE can_approve=VALUES(can_approve)'
    )->execute([$userId, $mosqueSlug, $canApprove]);

    respond(['success' => true]);
}

// ── DELETE /assign (remove from mosque) ───────────────────────────────────────
if ($method === 'DELETE' && $userId && $subAction === 'assign') {
    $body       = jsonBody();
    $mosqueSlug = trim($body['mosqueSlug'] ?? '');
    if (!$mosqueSlug) respond(['success' => false, 'error' => 'mosqueSlug is required'], 400);
    if ($admin['role'] === 'mosque_admin' && !canManageMosque($admin, $mosqueSlug)) {
        respond(['success' => false, 'error' => 'Forbidden'], 403);
    }
    db()->prepare('DELETE FROM user_mosques WHERE user_id=? AND mosque_slug=?')->execute([$userId, $mosqueSlug]);
    respond(['success' => true]);
}

// ── POST create ───────────────────────────────────────────────────────────────
if ($method === 'POST' && !$userId) {
    if ($admin['role'] !== 'super_admin') respond(['success' => false, 'error' => 'Forbidden'], 403);
    $body     = jsonBody();
    $username = preg_replace('/[^a-z0-9_]/', '', strtolower(trim($body['username'] ?? '')));
    $email    = strtolower(trim($body['email'] ?? ''));
    $role     = $body['role'] ?? 'maintainer';
    $tempPass = bin2hex(random_bytes(8)); // 16-char random password

    if (strlen($username) < 3) respond(['success' => false, 'error' => 'Username must be at least 3 characters'], 400);
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) respond(['success' => false, 'error' => 'Invalid email'], 400);
    if (!in_array($role, ['super_admin', 'mosque_admin', 'maintainer'], true)) {
        respond(['success' => false, 'error' => 'Invalid role'], 400);
    }

    $check = db()->prepare('SELECT 1 FROM users WHERE username=? OR email=?');
    $check->execute([$username, $email]);
    if ($check->fetch()) respond(['success' => false, 'error' => 'Username or email already in use'], 400);

    $hash = password_hash($tempPass, PASSWORD_BCRYPT, ['cost' => 12]);
    db()->prepare('INSERT INTO users (username,email,password_hash,role) VALUES (?,?,?,?)')->execute([$username, $email, $hash, $role]);
    $newId = (int)db()->lastInsertId();

    // Send welcome email
    try { (new Mailer())->sendWelcome($email, $username, $tempPass); }
    catch (Throwable $e) { error_log('[mail] ' . $e->getMessage()); }

    $stmt = db()->prepare('SELECT id,username,email,role,is_active,created_at FROM users WHERE id=?');
    $stmt->execute([$newId]);
    respond(['success' => true, 'user' => safeUser($stmt->fetch())]);
}

// ── PUT update ────────────────────────────────────────────────────────────────
if ($method === 'PUT' && $userId) {
    $body = jsonBody();

    // Non-super-admins can only update users in their mosques
    if ($admin['role'] !== 'super_admin') {
        $adminMosques = array_column($admin['mosques'], 'mosque_slug');
        $in   = implode(',', array_fill(0, count($adminMosques), '?'));
        $stmt = db()->prepare("SELECT 1 FROM user_mosques WHERE user_id=? AND mosque_slug IN ({$in})");
        $stmt->execute(array_merge([$userId], $adminMosques));
        if (!$stmt->fetch()) respond(['success' => false, 'error' => 'Forbidden'], 403);
    }

    $fields = [];
    $params = [];

    if (isset($body['email'])) {
        $email = strtolower(trim($body['email']));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) respond(['success' => false, 'error' => 'Invalid email'], 400);
        $fields[] = 'email=?'; $params[] = $email;
    }
    if (isset($body['is_active'])) {
        $fields[] = 'is_active=?'; $params[] = $body['is_active'] ? 1 : 0;
    }
    // Only super_admin can change roles
    if (isset($body['role']) && $admin['role'] === 'super_admin') {
        if (!in_array($body['role'], ['super_admin', 'mosque_admin', 'maintainer'], true)) {
            respond(['success' => false, 'error' => 'Invalid role'], 400);
        }
        $fields[] = 'role=?'; $params[] = $body['role'];
    }
    if (isset($body['password'])) {
        if (strlen($body['password']) < 8) respond(['success' => false, 'error' => 'Password must be at least 8 characters'], 400);
        $fields[] = 'password_hash=?';
        $params[] = password_hash($body['password'], PASSWORD_BCRYPT, ['cost' => 12]);
    }

    if (empty($fields)) respond(['success' => false, 'error' => 'Nothing to update'], 400);

    $params[] = $userId;
    db()->prepare('UPDATE users SET ' . implode(',', $fields) . ' WHERE id=?')->execute($params);

    $stmt = db()->prepare('SELECT id,username,email,role,is_active,created_at FROM users WHERE id=?');
    $stmt->execute([$userId]);
    respond(['success' => true, 'user' => safeUser($stmt->fetch())]);
}

// ── DELETE ────────────────────────────────────────────────────────────────────
if ($method === 'DELETE' && $userId) {
    if ($admin['role'] !== 'super_admin') respond(['success' => false, 'error' => 'Forbidden'], 403);
    if ($userId === $admin['id']) respond(['success' => false, 'error' => 'Cannot delete your own account'], 400);
    db()->prepare('DELETE FROM users WHERE id=?')->execute([$userId]);
    respond(['success' => true]);
}

respond(['success' => false, 'error' => 'Method not allowed'], 405);
