<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\MosqueController;
use App\Controllers\TimesController;
use Slim\App;

class MosqueRoutes
{
    public static function register(App $app): void
    {
        $app->get('/mosques',            [MosqueController::class, 'index']);
        $app->get('/mosques/default',    [MosqueController::class, 'defaultMosque']);
        $app->get('/mosques/{slug}',     [MosqueController::class, 'show']);
        $app->get('/mosques/{slug}/times', [TimesController::class, 'byMosque']);
    }
}
