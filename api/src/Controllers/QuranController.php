<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\QuranService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class QuranController extends BaseController
{
    public function __construct(private readonly QuranService $quran) {}

    // GET /v2/quran/surahs
    public function surahs(Request $request, Response $response): Response
    {
        try {
            $list = $this->quran->getSurahList();
            return $this->success($response, ['surahs' => $list]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }

    // GET /v2/quran/surahs/{number}
    public function surah(Request $request, Response $response, array $args): Response
    {
        $number = (int) ($args['number'] ?? 0);

        try {
            $data = $this->quran->getSurah($number);
            return $this->success($response, $data);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage());
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }

    // GET /v2/quran/juz/{number}
    public function juz(Request $request, Response $response, array $args): Response
    {
        $number = (int) ($args['number'] ?? 0);

        try {
            $data = $this->quran->getJuz($number);
            return $this->success($response, $data);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage());
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }

    // GET /v2/quran/search?q=&lang=en
    public function search(Request $request, Response $response): Response
    {
        $q    = trim($this->query($request, 'q') ?? '');
        $lang = $this->query($request, 'lang') ?? 'en';

        if (strlen($q) < 2) {
            return $this->error($response, 'Search query must be at least 2 characters');
        }

        try {
            $matches = $this->quran->search($q, $lang);
            return $this->success($response, ['query' => $q, 'matches' => $matches]);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), 502);
        }
    }

    // GET /v2/quran/audio/{ayah}   — returns CDN URL for a single ayah
    public function audioUrl(Request $request, Response $response, array $args): Response
    {
        $ayah = (int) ($args['ayah'] ?? 0);
        if ($ayah < 1 || $ayah > 6236) {
            return $this->error($response, 'Ayah number must be between 1 and 6236');
        }

        return $this->success($response, ['url' => QuranService::getAudioUrl($ayah)]);
    }
}
