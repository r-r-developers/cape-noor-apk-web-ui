<?php

declare(strict_types=1);

namespace App\Middleware;

use App\Services\AuthService;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Slim\Psr7\Response;

class JwtMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly array $jwtSettings
    ) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $header = $request->getHeaderLine('Authorization');

        if (!$header || !str_starts_with($header, 'Bearer ')) {
            return $this->unauthorized('Missing or malformed Authorization header');
        }

        $token = substr($header, 7);

        try {
            $decoded = JWT::decode($token, new Key($this->jwtSettings['secret'], $this->jwtSettings['algorithm']));
        } catch (ExpiredException) {
            return $this->unauthorized('Token expired');
        } catch (\Exception) {
            return $this->unauthorized('Invalid token');
        }

        if (($decoded->iss ?? '') !== $this->jwtSettings['issuer']) {
            return $this->unauthorized('Invalid token issuer');
        }

        if (($decoded->typ ?? '') !== 'access') {
            return $this->unauthorized('Invalid token type');
        }

        // Attach user payload to request attributes
        $request = $request
            ->withAttribute('user_id', $decoded->sub)
            ->withAttribute('user_role', $decoded->role ?? 'app_user')
            ->withAttribute('user_email', $decoded->email ?? '')
            ->withAttribute('jwt_payload', $decoded);

        return $handler->handle($request);
    }

    private function unauthorized(string $message): ResponseInterface
    {
        $response = new Response();
        $response->getBody()->write(json_encode(['success' => false, 'error' => $message], JSON_UNESCAPED_UNICODE));
        return $response
            ->withStatus(401)
            ->withHeader('Content-Type', 'application/json');
    }
}
