<?php

declare(strict_types=1);

use App\Services\AuthService;
use App\Services\DatabaseService;
use App\Services\FcmService;
use App\Services\MailService;
use App\Services\PrayerService;
use App\Services\QuranService;
use DI\ContainerBuilder;
use Monolog\Handler\StreamHandler;
use Monolog\Logger;
use Psr\Container\ContainerInterface;
use Psr\Log\LoggerInterface;

return function (ContainerBuilder $builder): void {
    $builder->addDefinitions([

        'settings' => [
            'db' => [
                'host'    => $_ENV['DB_HOST'] ?? 'localhost',
                'port'    => (int) ($_ENV['DB_PORT'] ?? 3306),
                'name'    => $_ENV['DB_NAME'] ?? 'salaah_db',
                'user'    => $_ENV['DB_USER'] ?? '',
                'pass'    => $_ENV['DB_PASS'] ?? '',
                'charset' => 'utf8mb4',
            ],
            'jwt' => [
                'secret'     => $_ENV['JWT_SECRET'] ?? '',
                'access_ttl' => (int) ($_ENV['JWT_ACCESS_TTL'] ?? 900),
                'refresh_ttl'=> (int) ($_ENV['JWT_REFRESH_TTL'] ?? 2592000),
                'algorithm'  => 'HS256',
                'issuer'     => $_ENV['APP_URL'] ?? 'https://localhost',
            ],
            'app' => [
                'url'  => $_ENV['APP_URL'] ?? 'https://localhost',
                'name' => $_ENV['APP_NAME'] ?? 'Salaah Times',
                'env'  => $_ENV['APP_ENV'] ?? 'production',
            ],
            'smtp' => [
                'host'       => $_ENV['SMTP_HOST'] ?? '',
                'port'       => (int) ($_ENV['SMTP_PORT'] ?? 587),
                'username'   => $_ENV['SMTP_USERNAME'] ?? '',
                'password'   => $_ENV['SMTP_PASSWORD'] ?? '',
                'secure'     => $_ENV['SMTP_SECURE'] ?? 'tls',
                'from_email' => $_ENV['SMTP_FROM_EMAIL'] ?? '',
                'from_name'  => $_ENV['SMTP_FROM_NAME'] ?? 'Salaah Times',
            ],
            'firebase' => [
                'project_id'    => $_ENV['FIREBASE_PROJECT_ID'] ?? '',
                'service_account' => $_ENV['FIREBASE_SERVICE_ACCOUNT_JSON'] ?? '',
            ],
            'facebook' => [
                'app_id'       => $_ENV['FACEBOOK_APP_ID'] ?? '',
                'app_secret'   => $_ENV['FACEBOOK_APP_SECRET'] ?? '',
                'redirect_uri' => $_ENV['FACEBOOK_REDIRECT_URI'] ?? '',
            ],
            'cors' => [
                'allowed_origins' => array_filter(
                    explode(',', $_ENV['CORS_ALLOWED_ORIGINS'] ?? '*')
                ),
            ],
            'cache_dir'  => __DIR__ . '/../cache',
            'upload_dir' => __DIR__ . '/../uploads',
        ],

        LoggerInterface::class => function (): Logger {
            $logger = new Logger('salaah-api');
            $logger->pushHandler(new StreamHandler('php://stderr', Logger::WARNING));
            return $logger;
        },

        PDO::class => function (ContainerInterface $c): PDO {
            $db = $c->get('settings')['db'];
            $dsn = sprintf(
                'mysql:host=%s;port=%d;dbname=%s;charset=%s',
                $db['host'], $db['port'], $db['name'], $db['charset']
            );
            $pdo = new PDO($dsn, $db['user'], $db['pass'], [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
            return $pdo;
        },

        DatabaseService::class => DI\autowire(),
        AuthService::class     => DI\autowire()->constructorParameter('settings', DI\get('settings')),
        PrayerService::class   => DI\autowire()->constructorParameter('settings', DI\get('settings')),
        QuranService::class    => DI\autowire()->constructorParameter('settings', DI\get('settings')),
        FcmService::class      => DI\autowire()->constructorParameter('settings', DI\get('settings')),
        MailService::class     => DI\autowire()->constructorParameter('settings', DI\get('settings')),

        \App\Controllers\AuthController::class => DI\autowire()->constructorParameter('settings', DI\get('settings')),
    ]);
};
