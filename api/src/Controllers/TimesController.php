<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\DatabaseService;
use App\Services\PrayerService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class TimesController extends BaseController
{
    public function __construct(
        private readonly PrayerService $prayer,
        private readonly DatabaseService $db
    ) {}

    // GET /v2/times?month=YYYY-MM
    public function byMonth(Request $request, Response $response): Response
    {
        $month = $this->query($request, 'month') ?? date('Y-m');

        try {
            $times = $this->prayer->getTimesForMonth($month);
            return $this->success($response, ['month' => $month, 'times' => $times]);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage());
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }

    // GET /v2/times/today
    public function today(Request $request, Response $response): Response
    {
        try {
            $times = $this->prayer->getTimesForToday();
            return $this->success($response, ['today' => $times]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }

    // GET /v2/mosques/{slug}/times?month=YYYY-MM
    public function byMosque(Request $request, Response $response, array $args): Response
    {
        $slug  = $args['slug'] ?? '';
        $month = $this->query($request, 'month') ?? date('Y-m');

        $mosque = $this->db->fetchOne('SELECT adhan_offsets FROM mosques WHERE slug = ?', [$slug]);
        if (!$mosque) {
            return $this->error($response, 'Mosque not found', 404);
        }

        $offsets = $mosque['adhan_offsets'] ? json_decode($mosque['adhan_offsets'], true) : [];

        try {
            $times = $this->prayer->getTimesForMonth($month);

            if ($offsets) {
                $times = array_map(fn($row) => $this->prayer->applyOffsets($row, $offsets), $times);
            }

            return $this->success($response, ['month' => $month, 'mosque' => $slug, 'times' => $times]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }
}
