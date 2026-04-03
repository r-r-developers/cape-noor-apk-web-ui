<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\AuthService;
use App\Services\MailService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class AuthController extends BaseController
{
    public function __construct(
        private readonly AuthService $auth,
        private readonly MailService $mail,
        private readonly array $settings
    ) {}

    // POST /v2/auth/register
    public function register(Request $request, Response $response): Response
    {
        $body     = $this->body($request);
        $name     = trim($body['name'] ?? '');
        $email    = trim(strtolower($body['email'] ?? ''));
        $password = $body['password'] ?? '';

        if (!$name || !$email || !$password) {
            return $this->error($response, 'name, email, and password are required');
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->error($response, 'Invalid email address');
        }

        if (strlen($password) < 8) {
            return $this->error($response, 'Password must be at least 8 characters');
        }

        try {
            $user   = $this->auth->register($name, $email, $password);
            $tokens = $this->auth->generateTokenPair($user + ['role' => 'app_user']);
            return $this->success($response, ['user' => $this->sanitizeUser($user), 'tokens' => $tokens], 201);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), (int) $e->getCode() ?: 400);
        }
    }

    // POST /v2/auth/login
    public function login(Request $request, Response $response): Response
    {
        $body     = $this->body($request);
        $email    = trim(strtolower($body['email'] ?? ''));
        $password = $body['password'] ?? '';

        if (!$email || !$password) {
            return $this->error($response, 'email and password are required');
        }

        try {
            $user   = $this->auth->login($email, $password);
            $user['role'] = 'app_user';
            $tokens = $this->auth->generateTokenPair($user);
            return $this->success($response, ['user' => $this->sanitizeUser($user), 'tokens' => $tokens]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), (int) $e->getCode() ?: 401);
        }
    }

    // POST /v2/auth/refresh
    public function refresh(Request $request, Response $response): Response
    {
        $token = $this->param($request, 'refresh_token') ??
                 $this->extractBearerToken($request);

        if (!$token) {
            return $this->error($response, 'refresh_token is required', 401);
        }

        try {
            $tokens = $this->auth->refresh($token);
            return $this->success($response, ['tokens' => $tokens]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 401);
        }
    }

    // POST /v2/auth/logout
    public function logout(Request $request, Response $response): Response
    {
        $token = $this->param($request, 'refresh_token');
        if ($token) {
            $this->auth->revokeRefreshToken($token);
        }
        return $this->success($response, ['message' => 'Logged out successfully']);
    }

    // POST /v2/auth/forgot-password
    public function forgotPassword(Request $request, Response $response): Response
    {
        $email = trim(strtolower($this->param($request, 'email') ?? ''));

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->error($response, 'Invalid email address');
        }

        $this->auth->forgotPassword($email);
        // Always 200 — no enumeration
        return $this->success($response, ['message' => 'If that email exists, a reset link has been sent.']);
    }

    // POST /v2/auth/reset-password
    public function resetPassword(Request $request, Response $response): Response
    {
        $token    = $this->param($request, 'token') ?? '';
        $password = $this->param($request, 'password') ?? '';

        if (!$token || strlen($password) < 8) {
            return $this->error($response, 'Valid token and password (min 8 chars) required');
        }

        try {
            $this->auth->resetPassword($token, $password);
            return $this->success($response, ['message' => 'Password reset successfully']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 400);
        }
    }

    // GET /v2/auth/me  [JWT required]
    public function me(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $user   = $this->auth->getAppUser($userId);

        if (!$user) {
            return $this->error($response, 'User not found', 404);
        }

        return $this->success($response, ['user' => $this->sanitizeUser($user)]);
    }

    // POST /v2/auth/admin/login
    public function adminLogin(Request $request, Response $response): Response
    {
        $body     = $this->body($request);
        $username = trim($body['username'] ?? '');
        $password = $body['password'] ?? '';

        if (!$username || !$password) {
            return $this->error($response, 'username and password are required');
        }

        try {
            $user   = $this->auth->adminLogin($username, $password);
            $tokens = $this->auth->generateTokenPair($user);
            return $this->success($response, ['user' => $this->sanitizeUser($user), 'tokens' => $tokens]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), (int) $e->getCode() ?: 401);
        }
    }

    private function sanitizeUser(array $user): array
    {
        unset($user['password_hash'], $user['is_active']);
        return $user;
    }

    private function extractBearerToken(Request $request): ?string
    {
        $header = $request->getHeaderLine('Authorization');
        if (str_starts_with($header, 'Bearer ')) {
            return substr($header, 7);
        }
        return null;
    }
}
