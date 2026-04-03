<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\TimesController;
use App\Controllers\MosqueController;
use Slim\App;

class TimesRoutes
{
    public static function register(App $app): void
    {
        $app->get('/times',        [TimesController::class, 'byMonth']);
        $app->get('/times/today',  [TimesController::class, 'today']);
    }
}
