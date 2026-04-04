<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\DatabaseService;
use App\Services\FcmService;
use App\Services\MailService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class AdminController extends BaseController
{
    private const ADMIN_ROLES = ['super_admin', 'mosque_admin', 'maintainer'];
    private const SUPER_ROLES = ['super_admin'];

    public function __construct(
        private readonly DatabaseService $db,
        private readonly FcmService $fcm,
        private readonly MailService $mail
    ) {}

    // ─────────────────────────────────────────────────────────────────────────
    // Mosques
    // ─────────────────────────────────────────────────────────────────────────

    // GET /v2/admin/mosques
    public function listMosques(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $role   = $this->userRole($request);

        if ($role === 'super_admin') {
            $mosques = $this->db->fetchAll('SELECT * FROM mosques ORDER BY name ASC');
        } else {
            $mosques = $this->db->fetchAll(
                'SELECT m.* FROM mosques m
                 JOIN user_mosques um ON um.mosque_slug = m.slug
                 WHERE um.user_id = ?
                 ORDER BY m.name ASC',
                [$userId]
            );
        }

        return $this->success($response, ['mosques' => array_map([$this, 'formatRow'], $mosques)]);
    }

    // POST /v2/admin/mosques
    public function createMosque(Request $request, Response $response): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $body = $this->body($request);
        $slug = strtolower(preg_replace('/[^a-z0-9-]/', '', $body['slug'] ?? ''));
        $name = trim($body['name'] ?? '');

        if (!$slug || !$name) {
            return $this->error($response, 'slug and name are required');
        }

        // Auto-assign short_id
        $lastShort = $this->db->fetchOne('SELECT MAX(CAST(short_id AS UNSIGNED)) AS max_id FROM mosques');
        $shortId   = str_pad((string) (((int) ($lastShort['max_id'] ?? -1)) + 1), 3, '0', STR_PAD_LEFT);

        try {
            $this->db->execute(
                'INSERT INTO mosques (slug, short_id, name, color_primary, color_gold, color_bg)
                 VALUES (?, ?, ?, ?, ?, ?)',
                [$slug, $shortId, $name,
                 $body['color_primary'] ?? '#22c55e',
                 $body['color_gold']    ?? '#d4af37',
                 $body['color_bg']      ?? '#0a0f1a',
                ]
            );
        } catch (\PDOException $e) {
            if ($e->getCode() === '23000') {
                return $this->error($response, 'A mosque with that slug already exists', 409);
            }
            throw $e;
        }

        $mosque = $this->db->fetchOne('SELECT * FROM mosques WHERE slug = ?', [$slug]);
        return $this->success($response, ['mosque' => $this->formatRow($mosque)], 201);
    }

    // GET /v2/admin/mosques/{slug}
    public function getMosque(Request $request, Response $response, array $args): Response
    {
        $slug   = $args['slug'];
        $userId = $this->userId($request);
        $role   = $this->userRole($request);

        $mosque = $this->db->fetchOne('SELECT * FROM mosques WHERE slug = ?', [$slug]);
        if (!$mosque) {
            return $this->error($response, 'Mosque not found', 404);
        }

        if ($role !== 'super_admin') {
            $assignment = $this->db->fetchOne(
                'SELECT id FROM user_mosques WHERE user_id = ? AND mosque_slug = ?',
                [$userId, $slug]
            );
            if (!$assignment) {
                return $this->error($response, 'Forbidden', 403);
            }
        }

        return $this->success($response, ['mosque' => $this->formatRow($mosque)]);
    }

    // PUT /v2/admin/mosques/{slug}
    public function updateMosque(Request $request, Response $response, array $args): Response
    {
        $slug   = $args['slug'];
        $userId = $this->userId($request);
        $role   = $this->userRole($request);

        $mosque = $this->db->fetchOne('SELECT * FROM mosques WHERE slug = ?', [$slug]);
        if (!$mosque) {
            return $this->error($response, 'Mosque not found', 404);
        }

        if ($role !== 'super_admin') {
            $assignment = $this->db->fetchOne(
                'SELECT can_approve FROM user_mosques WHERE user_id = ? AND mosque_slug = ?',
                [$userId, $slug]
            );
            if (!$assignment) {
                return $this->error($response, 'Forbidden', 403);
            }
        }

        $body    = $this->body($request);
        $changes = $this->sanitizeMosquePayload($body);

            // Super admin can toggle auto_approve
            if ($role === 'super_admin' && array_key_exists('auto_approve', $body)) {
                $changes['auto_approve'] = (int) (bool) $body['auto_approve'];
            }

            // Maintainers without auto-approve → pending change
        if ($role === 'maintainer' && !$mosque['auto_approve']) {
            $this->db->execute(
                'INSERT INTO pending_changes (mosque_slug, submitted_by, changes, status, created_at)
                 VALUES (?, ?, ?, "pending", NOW())',
                [$slug, $userId, json_encode($changes)]
            );
            return $this->success($response, ['message' => 'Changes submitted for approval']);
        }

        $this->applyMosqueChanges($slug, $changes);
        $updated = $this->db->fetchOne('SELECT * FROM mosques WHERE slug = ?', [$slug]);
        return $this->success($response, ['mosque' => $this->formatRow($updated)]);
    }

    // DELETE /v2/admin/mosques/{slug}
    public function deleteMosque(Request $request, Response $response, array $args): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $slug    = $args['slug'];
        $mosque  = $this->db->fetchOne('SELECT id, is_default FROM mosques WHERE slug = ?', [$slug]);
        if (!$mosque) {
            return $this->error($response, 'Mosque not found', 404);
        }

        if ((bool) ($mosque['is_default'] ?? false)) {
            return $this->error($response, 'Cannot delete the default mosque');
        }

        $this->db->execute('DELETE FROM mosques WHERE slug = ?', [$slug]);
        return $this->success($response, ['message' => "Mosque '{$slug}' deleted"]);
    }

    // POST /v2/admin/mosques/{slug}/set-default
    public function setDefault(Request $request, Response $response, array $args): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $slug   = $args['slug'];
        $mosque = $this->db->fetchOne('SELECT slug FROM mosques WHERE slug = ?', [$slug]);
        if (!$mosque) {
            return $this->error($response, 'Mosque not found', 404);
        }

        $this->db->beginTransaction();
        try {
            $this->db->execute('UPDATE mosques SET is_default = 0');
            $this->db->execute('UPDATE mosques SET is_default = 1 WHERE slug = ?', [$slug]);
            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }

        return $this->success($response, ['message' => "'{$slug}' is now the default mosque"]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Pending Changes
    // ─────────────────────────────────────────────────────────────────────────

    // GET /v2/admin/pending-changes
    public function listPending(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $role   = $this->userRole($request);

        if ($role === 'super_admin') {
            $rows = $this->db->fetchAll(
                'SELECT pc.*, u.username AS submitter_name FROM pending_changes pc
                 JOIN users u ON u.id = pc.submitted_by
                 WHERE pc.status = "pending" ORDER BY pc.created_at DESC'
            );
        } elseif ($role === 'mosque_admin') {
            $rows = $this->db->fetchAll(
                'SELECT pc.*, u.username AS submitter_name FROM pending_changes pc
                 JOIN users u ON u.id = pc.submitted_by
                 JOIN user_mosques um ON um.mosque_slug = pc.mosque_slug
                 WHERE pc.status = "pending" AND um.user_id = ? AND um.can_approve = 1
                 ORDER BY pc.created_at DESC',
                [$userId]
            );
        } else {
            $rows = $this->db->fetchAll(
                'SELECT * FROM pending_changes WHERE submitted_by = ? ORDER BY created_at DESC',
                [$userId]
            );
        }

        return $this->success($response, ['pending' => $rows]);
    }

    // POST /v2/admin/pending-changes/{id}/approve
    public function approveChange(Request $request, Response $response, array $args): Response
    {
        $id     = (int) $args['id'];
        $userId = $this->userId($request);

        $change = $this->db->fetchOne('SELECT * FROM pending_changes WHERE id = ? AND status = "pending"', [$id]);
        if (!$change) {
            return $this->error($response, 'Pending change not found', 404);
        }

        // Verify reviewer has can_approve for this mosque
        $role = $this->userRole($request);
        if ($role !== 'super_admin') {
            $perm = $this->db->fetchOne(
                'SELECT can_approve FROM user_mosques WHERE user_id = ? AND mosque_slug = ?',
                [$userId, $change['mosque_slug']]
            );
            if (!$perm || !$perm['can_approve']) {
                return $this->error($response, 'Forbidden', 403);
            }
        }

        $changes = json_decode($change['changes'], true);
        $this->applyMosqueChanges($change['mosque_slug'], $changes);

        $this->db->execute(
            'UPDATE pending_changes SET status = "approved", reviewed_by = ?, reviewed_at = NOW() WHERE id = ?',
            [$userId, $id]
        );

        return $this->success($response, ['message' => 'Change approved and applied']);
    }

    // POST /v2/admin/pending-changes/{id}/reject
    public function rejectChange(Request $request, Response $response, array $args): Response
    {
        $id     = (int) $args['id'];
        $userId = $this->userId($request);
        $note   = $this->param($request, 'note') ?? '';

        $change = $this->db->fetchOne('SELECT * FROM pending_changes WHERE id = ? AND status = "pending"', [$id]);
        if (!$change) {
            return $this->error($response, 'Pending change not found', 404);
        }

        // Verify reviewer has can_approve for this mosque
        $role = $this->userRole($request);
        if ($role !== 'super_admin') {
            $perm = $this->db->fetchOne(
                'SELECT can_approve FROM user_mosques WHERE user_id = ? AND mosque_slug = ?',
                [$userId, $change['mosque_slug']]
            );
            if (!$perm || !$perm['can_approve']) {
                return $this->error($response, 'Forbidden', 403);
            }
        }

        $this->db->execute(
            'UPDATE pending_changes SET status = "rejected", reviewed_by = ?, review_note = ?, reviewed_at = NOW() WHERE id = ?',
            [$userId, $note, $id]
        );

        return $this->success($response, ['message' => 'Change rejected']);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Notifications
    // ─────────────────────────────────────────────────────────────────────────

    // POST /v2/admin/notifications/broadcast
    public function broadcast(Request $request, Response $response): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $title      = $this->param($request, 'title') ?? '';
        $body       = $this->param($request, 'body') ?? '';
        $mosqueSlug = $this->param($request, 'mosque_slug'); // null = all

        if (!$title || !$body) {
            return $this->error($response, 'title and body are required');
        }

        $topic = $mosqueSlug ? "mosque_{$mosqueSlug}" : 'all_users';
        $sent  = $this->fcm->sendToTopic($topic, $title, $body, ['type' => 'announcement']);

        return $this->success($response, ['sent' => $sent, 'topic' => $topic]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin Users + Mosque Assignment Management
    // ─────────────────────────────────────────────────────────────────────────

    // GET /v2/admin/users
    public function listUsers(Request $request, Response $response): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $rows = $this->db->fetchAll(
            'SELECT id, username, email, role, is_active, created_at, updated_at
             FROM users
             ORDER BY created_at DESC'
        );

        $users = array_map(function (array $row): array {
            return $this->formatAdminUser($row);
        }, $rows);

        return $this->success($response, ['users' => $users]);
    }

    // GET /v2/admin/users/{id}
    public function getUser(Request $request, Response $response, array $args): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $id   = (int) ($args['id'] ?? 0);
        $user = $this->db->fetchOne(
            'SELECT id, username, email, role, is_active, created_at, updated_at FROM users WHERE id = ?',
            [$id]
        );

        if (!$user) {
            return $this->error($response, 'User not found', 404);
        }

        return $this->success($response, ['user' => $this->formatAdminUser($user)]);
    }

    // POST /v2/admin/users
    public function createUser(Request $request, Response $response): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $body     = $this->body($request);
        $username = trim((string) ($body['username'] ?? ''));
        $email    = strtolower(trim((string) ($body['email'] ?? '')));
        $password = (string) ($body['password'] ?? '');
        $role     = (string) ($body['role'] ?? 'maintainer');
        $isActive = isset($body['is_active']) ? (int) ((bool) $body['is_active']) : 1;

        if ($username === '' || $email === '' || $password === '') {
            return $this->error($response, 'username, email and password are required');
        }

        if (!in_array($role, self::ADMIN_ROLES, true)) {
            return $this->error($response, 'Invalid role');
        }

        if (strlen($password) < 8) {
            return $this->error($response, 'Password must be at least 8 characters');
        }

        $assignments = $this->normalizeAssignments($body);

        $this->db->beginTransaction();
        try {
            $id = (int) $this->db->insert(
                'INSERT INTO users (username, email, password_hash, role, is_active, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?, NOW(), NOW())',
                [$username, $email, password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]), $role, $isActive]
            );

            if ($role !== 'super_admin') {
                $this->replaceUserAssignments($id, $assignments);
            }

            $this->db->commit();
        } catch (\PDOException $e) {
            $this->db->rollback();
            if ($e->getCode() === '23000') {
                return $this->error($response, 'username or email already exists', 409);
            }
            throw $e;
        } catch (\RuntimeException $e) {
            $this->db->rollback();
            return $this->error($response, $e->getMessage(), (int) ($e->getCode() ?: 400));
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }

        $created = $this->db->fetchOne(
            'SELECT id, username, email, role, is_active, created_at, updated_at FROM users WHERE id = ?',
            [$id]
        );

        return $this->success($response, ['user' => $this->formatAdminUser($created)], 201);
    }

    // PUT /v2/admin/users/{id}
    public function updateUser(Request $request, Response $response, array $args): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $id   = (int) ($args['id'] ?? 0);
        $user = $this->db->fetchOne('SELECT * FROM users WHERE id = ?', [$id]);
        if (!$user) {
            return $this->error($response, 'User not found', 404);
        }

        $body   = $this->body($request);
        $fields = [];
        $params = [];

        if (array_key_exists('username', $body)) {
            $username = trim((string) $body['username']);
            if ($username === '') {
                return $this->error($response, 'username cannot be empty');
            }
            $fields[] = 'username = ?';
            $params[] = $username;
        }

        if (array_key_exists('email', $body)) {
            $email = strtolower(trim((string) $body['email']));
            if ($email === '') {
                return $this->error($response, 'email cannot be empty');
            }
            $fields[] = 'email = ?';
            $params[] = $email;
        }

        if (array_key_exists('password', $body)) {
            $password = (string) $body['password'];
            if (strlen($password) < 8) {
                return $this->error($response, 'Password must be at least 8 characters');
            }
            $fields[] = 'password_hash = ?';
            $params[] = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
        }

        $nextRole = $user['role'];
        if (array_key_exists('role', $body)) {
            $role = (string) $body['role'];
            if (!in_array($role, self::ADMIN_ROLES, true)) {
                return $this->error($response, 'Invalid role');
            }
            $nextRole = $role;
            if ($user['role'] === 'super_admin' && $role !== 'super_admin' && $this->countSuperAdmins() <= 1) {
                return $this->error($response, 'Cannot demote the last super_admin', 409);
            }
            $fields[] = 'role = ?';
            $params[] = $role;
        }

        if (array_key_exists('is_active', $body)) {
            $fields[] = 'is_active = ?';
            $params[] = (int) ((bool) $body['is_active']);
        }

        $assignmentsProvided = array_key_exists('assignments', $body) || array_key_exists('mosque_slugs', $body);
        $assignments         = $assignmentsProvided ? $this->normalizeAssignments($body) : [];

        $this->db->beginTransaction();
        try {
            if ($fields) {
                $params[] = $id;
                $this->db->execute(
                    'UPDATE users SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE id = ?',
                    $params
                );
            }

            if ($nextRole === 'super_admin') {
                // Super admins don't need explicit mosque assignment rows.
                $this->db->execute('DELETE FROM user_mosques WHERE user_id = ?', [$id]);
            } elseif ($assignmentsProvided) {
                $this->replaceUserAssignments($id, $assignments);
            }

            $this->db->commit();
        } catch (\PDOException $e) {
            $this->db->rollback();
            if ($e->getCode() === '23000') {
                return $this->error($response, 'username or email already exists', 409);
            }
            throw $e;
        } catch (\RuntimeException $e) {
            $this->db->rollback();
            return $this->error($response, $e->getMessage(), (int) ($e->getCode() ?: 400));
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }

        $updated = $this->db->fetchOne(
            'SELECT id, username, email, role, is_active, created_at, updated_at FROM users WHERE id = ?',
            [$id]
        );

        return $this->success($response, ['user' => $this->formatAdminUser($updated)]);
    }

    // DELETE /v2/admin/users/{id}
    public function deleteUser(Request $request, Response $response, array $args): Response
    {
        if ($err = $this->requireRole($request, $response, self::SUPER_ROLES)) {
            return $err;
        }

        $id       = (int) ($args['id'] ?? 0);
        $actorId  = $this->userId($request);
        $toDelete = $this->db->fetchOne('SELECT id, role FROM users WHERE id = ?', [$id]);

        if (!$toDelete) {
            return $this->error($response, 'User not found', 404);
        }

        if ($id === $actorId) {
            return $this->error($response, 'You cannot delete your own account', 409);
        }

        if ($toDelete['role'] === 'super_admin' && $this->countSuperAdmins() <= 1) {
            return $this->error($response, 'Cannot delete the last super_admin', 409);
        }

        $this->db->execute('DELETE FROM users WHERE id = ?', [$id]);
        return $this->success($response, ['message' => 'User deleted']);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    private function formatRow(array $row): array
    {
        return [
            'slug'          => $row['slug'],
            'shortId'       => $row['short_id'],
            'name'          => $row['name'],
            'logo'          => $row['logo'],
            'address'       => $row['address'],
            'phone'         => $row['phone'],
            'website'       => $row['website'],
            'showFasting'   => (bool) $row['show_fasting'],
            'showSidebars'  => (bool) ($row['show_sidebars'] ?? 1),
            'colors'        => [
                'primary' => $row['color_primary'] ?? '#22c55e',
                'gold'    => $row['color_gold'] ?? '#d4af37',
                'bg'      => $row['color_bg'] ?? '#0a0f1a',
            ],
            'announcements' => $row['announcements'] ? json_decode($row['announcements'], true) : [],
            'socialMedia'   => $row['social_media'] ? json_decode($row['social_media'], true) : [],
            'sponsors'      => $row['sponsors'] ? json_decode($row['sponsors'], true) : [],
            'adhanOffsets'  => $row['adhan_offsets'] ? json_decode($row['adhan_offsets'], true) : [],
            'autoApprove'   => (bool) $row['auto_approve'],
            'isDefault'     => (bool) $row['is_default'],
        ];
    }

    private function sanitizeMosquePayload(array $body): array
    {
        $allowed = [
            'name', 'logo', 'address', 'phone', 'website',
            'show_fasting', 'show_sidebars', 'color_primary', 'color_gold', 'color_bg',
            'announcements', 'social_media', 'sponsors', 'adhan_offsets',
        ];
            // auto_approve set only via admin route guards in updateMosque
        return array_intersect_key($body, array_flip($allowed));
    }

    private function applyMosqueChanges(string $slug, array $data): void
    {
        $fields = [];
        $params = [];

        $jsonFields = ['announcements', 'social_media', 'sponsors', 'adhan_offsets'];

        foreach ($data as $k => $v) {
            $fields[] = "`{$k}` = ?";
            $params[] = in_array($k, $jsonFields, true) ? json_encode($v) : $v;
        }

        if (!$fields) {
            return;
        }

        $params[] = $slug;
        $this->db->execute(
            'UPDATE mosques SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE slug = ?',
            $params
        );
    }

    private function formatAdminUser(array $row): array
    {
        return [
            'id'          => (int) $row['id'],
            'username'    => $row['username'],
            'email'       => $row['email'],
            'role'        => $row['role'],
            'isActive'    => (bool) $row['is_active'],
            'createdAt'   => $row['created_at'] ?? null,
            'updatedAt'   => $row['updated_at'] ?? null,
            'assignments' => $this->fetchUserAssignments((int) $row['id']),
        ];
    }

    private function fetchUserAssignments(int $userId): array
    {
        $rows = $this->db->fetchAll(
            'SELECT um.mosque_slug, um.can_approve, m.name
             FROM user_mosques um
             LEFT JOIN mosques m ON m.slug = um.mosque_slug
             WHERE um.user_id = ?
             ORDER BY m.name ASC',
            [$userId]
        );

        return array_map(static fn (array $r): array => [
            'mosqueSlug'  => $r['mosque_slug'],
            'mosqueName'  => $r['name'] ?? null,
            'canApprove'  => (bool) $r['can_approve'],
        ], $rows);
    }

    private function normalizeAssignments(array $body): array
    {
        $assignments = $body['assignments'] ?? null;

        if (!is_array($assignments)) {
            $slugs = $body['mosque_slugs'] ?? [];
            if (!is_array($slugs)) {
                return [];
            }
            $assignments = array_map(static fn ($slug): array => [
                'mosqueSlug' => (string) $slug,
                'canApprove' => false,
            ], $slugs);
        }

        $normalized = [];
        foreach ($assignments as $item) {
            if (!is_array($item)) {
                continue;
            }

            $slug = trim((string) ($item['mosqueSlug'] ?? $item['mosque_slug'] ?? ''));
            if ($slug === '') {
                continue;
            }

            $normalized[$slug] = [
                'mosqueSlug' => $slug,
                'canApprove' => (bool) ($item['canApprove'] ?? $item['can_approve'] ?? false),
            ];
        }

        return array_values($normalized);
    }

    private function replaceUserAssignments(int $userId, array $assignments): void
    {
        $this->db->execute('DELETE FROM user_mosques WHERE user_id = ?', [$userId]);

        if (!$assignments) {
            return;
        }

        $slugs = array_map(static fn (array $a): string => $a['mosqueSlug'], $assignments);
        $in    = implode(',', array_fill(0, count($slugs), '?'));
        $rows  = $this->db->fetchAll("SELECT slug FROM mosques WHERE slug IN ({$in})", $slugs);

        $existing = array_flip(array_map(static fn (array $r): string => $r['slug'], $rows));
        $missing  = array_values(array_filter($slugs, static fn (string $slug): bool => !isset($existing[$slug])));

        if ($missing) {
            throw new \RuntimeException('Unknown mosque slug(s): ' . implode(', ', $missing), 400);
        }

        foreach ($assignments as $assignment) {
            $this->db->execute(
                'INSERT INTO user_mosques (user_id, mosque_slug, can_approve) VALUES (?, ?, ?)',
                [$userId, $assignment['mosqueSlug'], (int) $assignment['canApprove']]
            );
        }
    }

    private function countSuperAdmins(): int
    {
        $row = $this->db->fetchOne('SELECT COUNT(*) AS c FROM users WHERE role = "super_admin"');
        return (int) ($row['c'] ?? 0);
    }
}
