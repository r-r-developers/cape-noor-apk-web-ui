<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\UserController;
use App\Middleware\JwtMiddleware;
use Slim\App;
use Slim\Routing\RouteCollectorProxy;

class UserRoutes
{
    public static function register(App $app): void
    {
        $jwt = $app->getContainer()->get('settings')['jwt'];
        $jwtMiddleware = new JwtMiddleware($jwt);

        $app->group('/user', function (RouteCollectorProxy $group) {
            $group->get('/settings',             [UserController::class, 'getSettings']);
            $group->put('/settings',             [UserController::class, 'updateSettings']);
            $group->post('/device-token',        [UserController::class, 'registerDeviceToken']);
            $group->delete('/device-token',      [UserController::class, 'removeDeviceToken']);
            $group->get('/prayer-log',           [UserController::class, 'getPrayerLog']);
            $group->post('/prayer-log',          [UserController::class, 'logPrayer']);
            $group->get('/bookmarks/quran',      [UserController::class, 'getBookmarks']);
            $group->post('/bookmarks/quran',     [UserController::class, 'addBookmark']);
            $group->delete('/bookmarks/quran/{id}', [UserController::class, 'removeBookmark']);
        })->add($jwtMiddleware);
    }
}
