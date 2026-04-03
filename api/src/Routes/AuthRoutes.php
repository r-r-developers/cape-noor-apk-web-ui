<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\AuthController;
use App\Middleware\JwtMiddleware;
use Slim\App;

class AuthRoutes
{
    public static function register(App $app): void
    {
        $jwt = $app->getContainer()->get('settings')['jwt'];

        $app->post('/auth/register',        [AuthController::class, 'register']);
        $app->post('/auth/login',           [AuthController::class, 'login']);
        $app->post('/auth/refresh',         [AuthController::class, 'refresh']);
        $app->post('/auth/logout',          [AuthController::class, 'logout']);
        $app->post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
        $app->post('/auth/reset-password',  [AuthController::class, 'resetPassword']);
        $app->post('/auth/admin/login',     [AuthController::class, 'adminLogin']);
        $app->get('/auth/me',               [AuthController::class, 'me'])
            ->add(new JwtMiddleware($jwt));
    }
}
