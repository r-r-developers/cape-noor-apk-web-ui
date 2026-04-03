<?php

declare(strict_types=1);

namespace App\Middleware;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Slim\Psr7\Response;

/**
 * Simple fixed-window rate limiter backed by PHP APCu (falls back to no-op if APCu unavailable).
 */
class RateLimitMiddleware implements MiddlewareInterface
{
    public function __construct(
        private readonly int $maxRequests = 120,
        private readonly int $windowSeconds = 60
    ) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        if (!function_exists('apcu_fetch')) {
            return $handler->handle($request);
        }

        $ip  = $this->getClientIp($request);
        $key = 'rl:' . $ip . ':' . floor(time() / $this->windowSeconds);

        $count = apcu_fetch($key);
        if ($count === false) {
            apcu_store($key, 1, $this->windowSeconds);
            $count = 1;
        } else {
            $count = apcu_inc($key);
        }

        if ($count > $this->maxRequests) {
            $response = new Response();
            $response->getBody()->write(json_encode([
                'success' => false,
                'error'   => 'Too many requests. Try again shortly.',
            ]));
            return $response
                ->withStatus(429)
                ->withHeader('Content-Type', 'application/json')
                ->withHeader('Retry-After', (string) $this->windowSeconds);
        }

        $response = $handler->handle($request);
        return $response
            ->withHeader('X-RateLimit-Limit', (string) $this->maxRequests)
            ->withHeader('X-RateLimit-Remaining', (string) max(0, $this->maxRequests - $count));
    }

    private function getClientIp(ServerRequestInterface $request): string
    {
        $serverParams = $request->getServerParams();

        foreach (['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'] as $header) {
            if (!empty($serverParams[$header])) {
                // Take the first IP if forwarded list
                return explode(',', $serverParams[$header])[0];
            }
        }

        return 'unknown';
    }
}
