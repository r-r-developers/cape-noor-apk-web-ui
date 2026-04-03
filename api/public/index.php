<?php

declare(strict_types=1);

use App\Middleware\CorsMiddleware;
use App\Middleware\JwtMiddleware;
use App\Routes\AdminRoutes;
use App\Routes\AuthRoutes;
use App\Routes\DuasRoutes;
use App\Routes\MosqueRoutes;
use App\Routes\QuranRoutes;
use App\Routes\TimesRoutes;
use App\Routes\UserRoutes;
use App\Routes\UtilityRoutes;
use DI\ContainerBuilder;
use Slim\Factory\AppFactory;
use Slim\Middleware\ErrorMiddleware;

// ── Bootstrap ─────────────────────────────────────────────────────────────────
require_once __DIR__ . '/../vendor/autoload.php';

// Load .env
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->safeLoad();

// Container
$containerBuilder = new ContainerBuilder();
if (($_ENV['APP_ENV'] ?? 'production') === 'production') {
    $containerBuilder->enableCompilation(__DIR__ . '/../cache/di');
}
(require __DIR__ . '/../config/container.php')($containerBuilder);
$container = $containerBuilder->build();

// App
AppFactory::setContainer($container);
$app = AppFactory::create();
$app->setBasePath('/v2');

// ── Global Middleware ─────────────────────────────────────────────────────────
$app->addBodyParsingMiddleware();
$app->add(new CorsMiddleware($container->get('settings')['cors']));
$app->addRoutingMiddleware();

// Error Middleware
$settings    = $container->get('settings');
$isDebug     = ($settings['app']['env'] ?? 'production') !== 'production';
$errorMiddleware = $app->addErrorMiddleware($isDebug, true, true);
$errorMiddleware->getDefaultErrorHandler()->forceContentType('application/json');

// ── Routes ────────────────────────────────────────────────────────────────────
AuthRoutes::register($app);
TimesRoutes::register($app);
MosqueRoutes::register($app);
QuranRoutes::register($app);
DuasRoutes::register($app);
UtilityRoutes::register($app);
UserRoutes::register($app);
AdminRoutes::register($app);

$app->run();
