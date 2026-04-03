<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\DuasController;
use Slim\App;

class DuasRoutes
{
    public static function register(App $app): void
    {
        $app->get('/duas/categories',        [DuasController::class, 'categories']);
        $app->get('/duas/categories/{id}',   [DuasController::class, 'categoryWithDuas']);
        $app->get('/duas/{id}',              [DuasController::class, 'show']);
    }
}
