<?php

declare(strict_types=1);

namespace App\Routes;

use App\Controllers\QuranController;
use Slim\App;

class QuranRoutes
{
    public static function register(App $app): void
    {
        $app->get('/quran/surahs',           [QuranController::class, 'surahs']);
        $app->get('/quran/surahs/{number}',  [QuranController::class, 'surah']);
        $app->get('/quran/juz/{number}',     [QuranController::class, 'juz']);
        $app->get('/quran/search',           [QuranController::class, 'search']);
        $app->get('/quran/audio/{ayah}',     [QuranController::class, 'audioUrl']);
    }
}
