<?php

declare(strict_types=1);

namespace App\Services;

/**
 * Server-side proxy + disk-cache for AlQuran.cloud API.
 * All responses are cached to disk indefinitely (Quran text never changes).
 */
class QuranService
{
    private const API_BASE    = 'https://api.alquran.cloud/v1';
    private const AUDIO_CDN   = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy';
    private const TEXT_EDITION = 'quran-simple';
    private const EN_EDITION   = 'en.asad';
    private const AUDIO_EDITION = 'ar.alafasy';

    private string $cacheDir;

    public function __construct(array $settings)
    {
        $this->cacheDir = $settings['cache_dir'] . '/quran';
        if (!is_dir($this->cacheDir)) {
            mkdir($this->cacheDir, 0755, true);
        }
    }

    /** Returns surah metadata list (114 surahs). */
    public function getSurahList(): array
    {
        $cacheFile = $this->cacheDir . '/surah-list.json';

        if (file_exists($cacheFile)) {
            return json_decode(file_get_contents($cacheFile), true);
        }

        try {
            $data = $this->apiGet('/meta');
            $surahs = $data['data']['surahs']['references'] ?? [];
        } catch (\RuntimeException) {
            // Fallback: some hosts intermittently fail on /meta, but /surah still works.
            $data = $this->apiGet('/surah');
            $surahs = $data['data'] ?? [];
        }

        file_put_contents($cacheFile, json_encode($surahs, JSON_UNESCAPED_UNICODE));
        return $surahs;
    }

    /** Returns a full surah with Arabic text + English translation + audio URLs. */
    public function getSurah(int $number): array
    {
        if ($number < 1 || $number > 114) {
            throw new \InvalidArgumentException('Surah number must be between 1 and 114');
        }

        $cacheFile = $this->cacheDir . "/surah-{$number}.json";

        if (file_exists($cacheFile)) {
            return json_decode(file_get_contents($cacheFile), true);
        }

        // Fetch Arabic + English in one call
        $editions = implode(',', [self::TEXT_EDITION, self::EN_EDITION, self::AUDIO_EDITION]);
        $data = $this->apiGet("/surah/{$number}/editions/{$editions}");

        $result = $this->formatSurah($data['data'] ?? []);

        file_put_contents($cacheFile, json_encode($result, JSON_UNESCAPED_UNICODE));
        return $result;
    }

    /** Returns a full Juz with Arabic + English. */
    public function getJuz(int $number): array
    {
        if ($number < 1 || $number > 30) {
            throw new \InvalidArgumentException('Juz number must be between 1 and 30');
        }

        $cacheFile = $this->cacheDir . "/juz-{$number}.json";

        if (file_exists($cacheFile)) {
            return json_decode(file_get_contents($cacheFile), true);
        }

        $editions = implode(',', [self::TEXT_EDITION, self::EN_EDITION]);
        $data     = $this->apiGet("/juz/{$number}/editions/{$editions}");

        // Structure the result
        $result = ['juz' => $number, 'ayahs' => []];
        $arabicAyahs = $data['data'][0]['ayahs'] ?? [];
        $englishAyahs = $data['data'][1]['ayahs'] ?? [];

        foreach ($arabicAyahs as $i => $ayah) {
            $result['ayahs'][] = [
                'number'      => $ayah['number'],
                'numberInSurah' => $ayah['numberInSurah'],
                'surah'       => $ayah['surah']['number'] ?? null,
                'text'        => $ayah['text'],
                'translation' => $englishAyahs[$i]['text'] ?? '',
                'audio'       => self::AUDIO_CDN . '/' . $ayah['number'] . '.mp3',
                'page'        => $ayah['page'] ?? null,
            ];
        }

        file_put_contents($cacheFile, json_encode($result, JSON_UNESCAPED_UNICODE));
        return $result;
    }

    /** Full-text search across the Quran. */
    public function search(string $query, string $language = 'en'): array
    {
        $encoded = urlencode($query);
        $data    = $this->apiGet("/search/{$encoded}/all/{$language}");
        return $data['data']['matches'] ?? [];
    }

    /** Get the audio CDN URL for a given global ayah number (1–6236). */
    public static function getAudioUrl(int $ayahNumber): string
    {
        return self::AUDIO_CDN . '/' . $ayahNumber . '.mp3';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private
    // ─────────────────────────────────────────────────────────────────────────

    private function apiGet(string $path): array
    {
        $url = self::API_BASE . $path;

        // Prefer cURL for better compatibility on shared hosts.
        $raw = $this->httpGet($url);
        if ($raw === null) {
            throw new \RuntimeException("Failed to fetch Quran data from AlQuran.cloud: {$path}");
        }

        $data = json_decode($raw, true);
        if (!$data || ($data['code'] ?? 0) !== 200) {
            throw new \RuntimeException("AlQuran.cloud returned an error for {$path}");
        }

        return $data;
    }

    private function httpGet(string $url): ?string
    {
        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_MAXREDIRS => 3,
                CURLOPT_CONNECTTIMEOUT => 10,
                CURLOPT_TIMEOUT => 25,
                CURLOPT_ENCODING => '',
                CURLOPT_HTTPHEADER => [
                    'Accept: application/json',
                    'User-Agent: SalaahTimesAPI/1.0 (+https://mosque-admin.randrdevelopers.co.za)',
                ],
            ]);

            $body = curl_exec($ch);
            $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $ok   = $body !== false && $http >= 200 && $http < 300;

            // Last-resort compatibility retry for hosts with broken CA bundles.
            if (!$ok && curl_errno($ch) === 60) {
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
                $body = curl_exec($ch);
                $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $ok   = $body !== false && $http >= 200 && $http < 300;
            }

            curl_close($ch);
            if ($ok) {
                return (string) $body;
            }
        }

        // Fallback for environments without cURL.
        $ctx = stream_context_create([
            'http' => [
                'timeout' => 25,
                'header'  => "Accept: application/json\r\nUser-Agent: SalaahTimesAPI/1.0",
            ],
        ]);

        $raw = @file_get_contents($url, false, $ctx);
        return $raw === false ? null : $raw;
    }

    private function formatSurah(array $editions): array
    {
        if (empty($editions)) {
            return [];
        }

        $arabicEdition  = null;
        $englishEdition = null;
        $audioEdition   = null;

        foreach ($editions as $edition) {
            $identifier = $edition['edition']['identifier'] ?? '';
            if ($identifier === self::TEXT_EDITION) {
                $arabicEdition = $edition;
            } elseif ($identifier === self::EN_EDITION) {
                $englishEdition = $edition;
            } elseif ($identifier === self::AUDIO_EDITION) {
                $audioEdition = $edition;
            }
        }

        if (!$arabicEdition) {
            return [];
        }

        $surahMeta = [
            'number'          => $arabicEdition['number'],
            'name'            => $arabicEdition['name'],
            'englishName'     => $arabicEdition['englishName'],
            'englishNameTranslation' => $arabicEdition['englishNameTranslation'],
            'numberOfAyahs'   => $arabicEdition['numberOfAyahs'],
            'revelationType'  => $arabicEdition['revelationType'],
        ];

        $arabicAyahs  = $arabicEdition['ayahs'] ?? [];
        $englishAyahs = $englishEdition['ayahs'] ?? [];
        $audioAyahs   = $audioEdition['ayahs'] ?? [];

        $ayahs = [];
        foreach ($arabicAyahs as $i => $ayah) {
            $ayahs[] = [
                'number'        => $ayah['number'],
                'numberInSurah' => $ayah['numberInSurah'],
                'text'          => $ayah['text'],
                'translation'   => $englishAyahs[$i]['text'] ?? '',
                'audio'         => $audioAyahs[$i]['audio'] ?? self::AUDIO_CDN . '/' . $ayah['number'] . '.mp3',
                'page'          => $ayah['page'] ?? null,
                'juz'           => $ayah['juz'] ?? null,
            ];
        }

        return ['surah' => $surahMeta, 'ayahs' => $ayahs];
    }
}
