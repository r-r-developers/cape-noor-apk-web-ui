<?php

declare(strict_types=1);

namespace App\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class AuthService
{
    public function __construct(
        private readonly DatabaseService $db,
        private readonly array $settings
    ) {}

    // ─────────────────────────────────────────────────────────────────────────
    // App-user auth (JWT-based)
    // ─────────────────────────────────────────────────────────────────────────

    public function register(string $name, string $email, string $password): array
    {
        $existing = $this->db->fetchOne('SELECT id FROM app_users WHERE email = ?', [$email]);
        if ($existing) {
            throw new \RuntimeException('Email already registered', 409);
        }

        $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
        $id   = $this->db->insert(
            'INSERT INTO app_users (name, email, password_hash, created_at) VALUES (?, ?, ?, NOW())',
            [$name, $email, $hash]
        );

        return $this->db->fetchOne('SELECT id, name, email, created_at FROM app_users WHERE id = ?', [$id]);
    }

    public function login(string $email, string $password): array
    {
        $user = $this->db->fetchOne(
            'SELECT id, name, email, password_hash, is_active FROM app_users WHERE email = ?',
            [$email]
        );

        if (!$user || !password_verify($password, $user['password_hash'])) {
            throw new \RuntimeException('Invalid credentials', 401);
        }

        if (!$user['is_active']) {
            throw new \RuntimeException('Account is inactive', 403);
        }

        return $user;
    }

    public function generateTokenPair(array $user): array
    {
        $jwt = $this->settings['jwt'];
        $now = time();

        $accessPayload = [
            'iss'  => $jwt['issuer'],
            'sub'  => $user['id'],
            'iat'  => $now,
            'exp'  => $now + $jwt['access_ttl'],
            'typ'  => 'access',
            'role' => $user['role'] ?? 'app_user',
            'email'=> $user['email'],
        ];

        $accessToken  = JWT::encode($accessPayload, $jwt['secret'], $jwt['algorithm']);
        $refreshToken = bin2hex(random_bytes(64));
        $refreshHash  = hash('sha256', $refreshToken);

        $this->db->execute(
            'INSERT INTO refresh_tokens (user_id, user_type, token_hash, expires_at)
             VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))',
            [$user['id'], $user['role'] ?? 'app_user', $refreshHash, $jwt['refresh_ttl']]
        );

        return [
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in'    => $jwt['access_ttl'],
            'token_type'    => 'Bearer',
        ];
    }

    public function refresh(string $refreshToken): array
    {
        $hash = hash('sha256', $refreshToken);
        $row  = $this->db->fetchOne(
            'SELECT * FROM refresh_tokens WHERE token_hash = ? AND revoked = 0 AND expires_at > NOW()',
            [$hash]
        );

        if (!$row) {
            throw new \RuntimeException('Invalid or expired refresh token', 401);
        }

        // Revoke old token (rotation)
        $this->db->execute('UPDATE refresh_tokens SET revoked = 1 WHERE id = ?', [$row['id']]);

        // Fetch user based on user_type
        if ($row['user_type'] === 'app_user') {
            $user = $this->db->fetchOne(
                'SELECT id, name, email, is_active FROM app_users WHERE id = ?',
                [$row['user_id']]
            );
            $user['role'] = 'app_user';
        } else {
            // Admin user
            $user = $this->db->fetchOne(
                'SELECT id, username AS name, email, role, is_active FROM users WHERE id = ?',
                [$row['user_id']]
            );
        }

        if (!$user || !$user['is_active']) {
            throw new \RuntimeException('User not found or inactive', 401);
        }

        return $this->generateTokenPair($user);
    }

    public function revokeRefreshToken(string $refreshToken): void
    {
        $hash = hash('sha256', $refreshToken);
        $this->db->execute('UPDATE refresh_tokens SET revoked = 1 WHERE token_hash = ?', [$hash]);
    }

    public function forgotPassword(string $email): void
    {
        $user = $this->db->fetchOne('SELECT id FROM app_users WHERE email = ?', [$email]);
        if (!$user) {
            return; // Silent — no enumeration
        }

        $token     = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);

        $this->db->execute(
            'INSERT INTO app_password_resets (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 1 HOUR))',
            [$user['id'], $tokenHash]
        );
    }

    public function resetPassword(string $token, string $newPassword): void
    {
        $hash = hash('sha256', $token);
        $row  = $this->db->fetchOne(
            'SELECT * FROM app_password_resets WHERE token_hash = ? AND used = 0 AND expires_at > NOW()',
            [$hash]
        );

        if (!$row) {
            throw new \RuntimeException('Invalid or expired reset token', 400);
        }

        $newHash = password_hash($newPassword, PASSWORD_BCRYPT, ['cost' => 12]);
        $this->db->execute('UPDATE app_users SET password_hash = ? WHERE id = ?', [$newHash, $row['user_id']]);
        $this->db->execute('UPDATE app_password_resets SET used = 1 WHERE id = ?', [$row['id']]);
    }

    public function getAppUser(int $userId): ?array
    {
        return $this->db->fetchOne(
            'SELECT id, name, email, is_active, created_at FROM app_users WHERE id = ?',
            [$userId]
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin (existing users table) auth via JWT
    // ─────────────────────────────────────────────────────────────────────────

    public function adminLogin(string $usernameOrEmail, string $password): array
    {
        $user = $this->db->fetchOne(
            'SELECT id, username, email, password_hash, role, is_active 
             FROM users 
             WHERE (username = ? OR email = ?)',
            [$usernameOrEmail, $usernameOrEmail]
        );

        if (!$user || !password_verify($password, $user['password_hash'])) {
            throw new \RuntimeException('Invalid credentials', 401);
        }

        if (!$user['is_active']) {
            throw new \RuntimeException('Account is inactive', 403);
        }

        $user['name'] = $user['username'];
        return $user;
    }
}
