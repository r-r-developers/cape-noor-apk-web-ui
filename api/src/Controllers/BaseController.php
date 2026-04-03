<?php

declare(strict_types=1);

namespace App\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Psr7\Response as SlimResponse;

abstract class BaseController
{
    protected function json(Response $response, mixed $data, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
        return $response
            ->withStatus($status)
            ->withHeader('Content-Type', 'application/json');
    }

    protected function success(Response $response, mixed $data = null, int $status = 200): Response
    {
        $body = ['success' => true];
        if ($data !== null) {
            $body = array_merge($body, is_array($data) ? $data : ['data' => $data]);
        }
        return $this->json($response, $body, $status);
    }

    protected function error(Response $response, string $message, int $status = 400): Response
    {
        return $this->json($response, ['success' => false, 'error' => $message], $status);
    }

    protected function userId(Request $request): ?int
    {
        $id = $request->getAttribute('user_id');
        return $id !== null ? (int) $id : null;
    }

    protected function userRole(Request $request): string
    {
        return $request->getAttribute('user_role', 'app_user');
    }

    protected function requireRole(Request $request, Response $response, array $roles): ?Response
    {
        if (!in_array($this->userRole($request), $roles, true)) {
            return $this->error($response, 'Forbidden', 403);
        }
        return null;
    }

    protected function body(Request $request): array
    {
        $body = $request->getParsedBody();
        return is_array($body) ? $body : [];
    }

    protected function param(Request $request, string $key, mixed $default = null): mixed
    {
        return $this->body($request)[$key] ?? $default;
    }

    protected function query(Request $request, string $key, mixed $default = null): mixed
    {
        return $request->getQueryParams()[$key] ?? $default;
    }
}
