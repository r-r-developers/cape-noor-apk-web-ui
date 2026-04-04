<?php
/**
 * Session-based authentication helpers.
 *
 * Roles:
 *   super_admin  — owns the application; can do everything
 *   mosque_admin — manages one or more mosques; approves changes
 *   maintainer   — proposes changes (goes through approval unless auto-approve is on)
 */

function _bootAuth(): void {
    if (!defined('DB_HOST')) {
        require_once __DIR__ . '/../config.php';
    }
    require_once __DIR__ . '/Db.php';

    if (session_status() === PHP_SESSION_NONE) {
        ini_set('session.cookie_httponly', '1');
        ini_set('session.cookie_samesite', 'Strict');
        if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
            ini_set('session.cookie_secure', '1');
        }
        session_set_cookie_params(['lifetime' => SESSION_LIFETIME]);
        session_start();
    }
}

/**
 * Returns the current authenticated user array or null.
 * Attaches `mosques` array: [{ mosque_slug, can_approve }, ...]
 */
function getCurrentUser(): ?array {
    _bootAuth();

    if (empty($_SESSION['user_id'])) return null;

    $stmt = db()->prepare(
        'SELECT id, username, email, role, is_active
           FROM users
          WHERE id = ? AND is_active = 1'
    );
    $stmt->execute([$_SESSION['user_id']]);
    $user = $stmt->fetch();

    if (!$user) {
        session_destroy();
        return null;
    }

    $stmt = db()->prepare(
        'SELECT mosque_slug, can_approve
           FROM user_mosques
          WHERE user_id = ?'
    );
    $stmt->execute([$user['id']]);
    $user['mosques'] = $stmt->fetchAll();

    return $user;
}

/**
 * Requires authentication. Returns current user or sends 401 and exits.
 */
function requireAuth(): array {
    $user = getCurrentUser();
    if (!$user) {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'error' => 'Not authenticated']);
        exit;
    }
    return $user;
}

/**
 * Requires one of the given roles. Returns current user or sends 401/403 and exits.
 */
function requireRole(string ...$roles): array {
    $user = requireAuth();
    if (!in_array($user['role'], $roles, true)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'error' => 'Insufficient permissions']);
        exit;
    }
    return $user;
}

/**
 * Returns true if the user may read/write the given mosque
 * (super_admin can manage all; others only their assigned ones).
 */
function canManageMosque(array $user, string $mosqueSlug): bool {
    if ($user['role'] === 'super_admin') return true;
    foreach ($user['mosques'] as $m) {
        if ($m['mosque_slug'] === $mosqueSlug) return true;
    }
    return false;
}

/**
 * Returns true if the user may directly approve / apply changes
 * (super_admin always can; mosque_admin only for their assigned mosque with can_approve=1).
 */
function canApproveMosque(array $user, string $mosqueSlug): bool {
    if ($user['role'] === 'super_admin') return true;
    if ($user['role'] !== 'mosque_admin') return false;
    foreach ($user['mosques'] as $m) {
        if ($m['mosque_slug'] === $mosqueSlug && $m['can_approve']) return true;
    }
    return false;
}
