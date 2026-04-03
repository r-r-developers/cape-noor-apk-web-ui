<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\UtilityController;
use Slim\App;

class UtilityRoutes
{
    public static function register(App $app): void
    {
        $app->get('/qibla',           [UtilityController::class, 'qibla']);
        $app->get('/calendar/hijri',  [UtilityController::class, 'hijri']);
        $app->get('/calendar/events', [UtilityController::class, 'islamicEvents']);
    }
}
