<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\AdminController;
use App\Middleware\JwtMiddleware;
use Slim\App;
use Slim\Routing\RouteCollectorProxy;

class AdminRoutes
{
    public static function register(App $app): void
    {
        $jwt           = $app->getContainer()->get('settings')['jwt'];
        $jwtMiddleware = new JwtMiddleware($jwt);

        $app->group('/admin', function (RouteCollectorProxy $group) {
            // Mosques
            $group->get('/mosques',                        [AdminController::class, 'listMosques']);
            $group->post('/mosques',                       [AdminController::class, 'createMosque']);
            $group->get('/mosques/{slug}',                 [AdminController::class, 'getMosque']);
            $group->put('/mosques/{slug}',                 [AdminController::class, 'updateMosque']);
            $group->delete('/mosques/{slug}',              [AdminController::class, 'deleteMosque']);
            $group->post('/mosques/{slug}/set-default',    [AdminController::class, 'setDefault']);

            // Pending changes
            $group->get('/pending-changes',                [AdminController::class, 'listPending']);
            $group->post('/pending-changes/{id}/approve',  [AdminController::class, 'approveChange']);
            $group->post('/pending-changes/{id}/reject',   [AdminController::class, 'rejectChange']);

            // Admin users + assignments
            $group->get('/users',                          [AdminController::class, 'listUsers']);
            $group->get('/users/{id}',                     [AdminController::class, 'getUser']);
            $group->post('/users',                         [AdminController::class, 'createUser']);
            $group->put('/users/{id}',                     [AdminController::class, 'updateUser']);
            $group->delete('/users/{id}',                  [AdminController::class, 'deleteUser']);

            // Notifications
            $group->post('/notifications/broadcast',       [AdminController::class, 'broadcast']);
        })->add($jwtMiddleware);
    }
}
