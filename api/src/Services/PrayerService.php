<?php

declare(strict_types=1);

namespace App\Services;

class PrayerService
{
    private string $cacheDir;

    public function __construct(private readonly DatabaseService $db, array $settings)
    {
        $this->cacheDir = $settings['cache_dir'] . '/prayer-times';
        if (!is_dir($this->cacheDir)) {
            mkdir($this->cacheDir, 0755, true);
        }
    }

    /** Returns prayer times for a given YYYY-MM, from cache or scraped. */
    public function getTimesForMonth(string $month): array
    {
        if (!preg_match('/^\d{4}-\d{2}$/', $month)) {
            throw new \InvalidArgumentException('Invalid month format. Use YYYY-MM.');
        }

        $cacheFile = $this->cacheDir . '/' . $month . '.json';

        if (file_exists($cacheFile)) {
            $data = json_decode(file_get_contents($cacheFile), true);
            if ($data) {
                return $data;
            }
        }

        $times = $this->scrapeFromMasjids($month);

        file_put_contents($cacheFile, json_encode($times, JSON_UNESCAPED_UNICODE));

        return $times;
    }

    /** Returns today's prayer times with optional adhan offsets applied. */
    public function getTimesForToday(?array $adhanOffsets = null): array
    {
        $today  = date('Y-m-d');
        $month  = date('Y-m');
        $day    = (int) date('j');
        $all    = $this->getTimesForMonth($month);

        $todayRow = null;
        foreach ($all as $row) {
            if ((int) explode('-', $row['date'])[2] === $day) {
                $todayRow = $row;
                break;
            }
        }

        if (!$todayRow) {
            throw new \RuntimeException('Could not find today\'s prayer times.');
        }

        if ($adhanOffsets) {
            $todayRow = $this->applyOffsets($todayRow, $adhanOffsets);
        }

        return $todayRow;
    }

    /**
     * Apply per-prayer adhan offsets (minutes) to a prayer-times row.
     * Offsets format: {"fajr": 0, "thuhr": 5, ...}
     */
    public function applyOffsets(array $row, array $offsets): array
    {
        $prayers = ['fajr', 'thuhr', 'asr', 'maghrib', 'isha'];
        foreach ($prayers as $prayer) {
            $offset = (int) ($offsets[$prayer] ?? 0);
            if ($offset !== 0 && isset($row[$prayer])) {
                $row[$prayer] = $this->addMinutes($row[$prayer], $offset);
            }
        }
        return $row;
    }

    private function addMinutes(string $time, int $minutes): string
    {
        $dt = \DateTime::createFromFormat('H:i', $time);
        if (!$dt) {
            return $time;
        }
        $dt->modify("{$minutes} minutes");
        return $dt->format('H:i');
    }

    private function scrapeFromMasjids(string $month): array
    {
        $url = "https://www.masjids.co.za/salaahtimes/capetown/{$month}";

        $ctx = stream_context_create([
            'http' => [
                'timeout' => 15,
                'header'  => 'User-Agent: SalaahApp/2.0',
            ],
        ]);

        $html = @file_get_contents($url, false, $ctx);
        if (!$html) {
            throw new \RuntimeException("Failed to fetch prayer times from masjids.co.za for {$month}");
        }

        $dom = new \DOMDocument();
        libxml_use_internal_errors(true);
        $dom->loadHTML($html);
        libxml_clear_errors();

        $xpath = new \DOMXPath($dom);
        // Table rows — first row is header
        $rows  = $xpath->query('//table//tr');

        $times = [];
        $year  = (int) substr($month, 0, 4);
        $mon   = (int) substr($month, 5, 2);

        foreach ($rows as $i => $row) {
            if ($i === 0) {
                continue; // Skip header
            }
            $cells = $row->getElementsByTagName('td');
            if ($cells->length < 8) {
                continue;
            }

            $dateStr  = trim($cells->item(0)->textContent);
            $dayName  = trim($cells->item(1)->textContent);
            $fajr     = $this->normalizeTime(trim($cells->item(2)->textContent));
            $thuhr    = $this->normalizeTime(trim($cells->item(3)->textContent));
            $asrShafi = $this->normalizeTime(trim($cells->item(4)->textContent)); // Shafi'i
            $maghrib  = $this->normalizeTime(trim($cells->item(6)->textContent));
            $isha     = $this->normalizeTime(trim($cells->item(7)->textContent));

            if (!$fajr || !$thuhr || !$asrShafi || !$maghrib || !$isha) {
                continue;
            }

            $dayNum = (int) $dateStr;
            $date   = sprintf('%04d-%02d-%02d', $year, $mon, $dayNum);

            $times[] = [
                'date'    => $date,
                'day'     => $dayName,
                'fajr'    => $fajr,
                'thuhr'   => $thuhr,
                'asr'     => $asrShafi,
                'maghrib' => $maghrib,
                'isha'    => $isha,
            ];
        }

        if (empty($times)) {
            throw new \RuntimeException("No prayer times parsed for {$month}");
        }

        return $times;
    }

    private function normalizeTime(string $raw): ?string
    {
        $clean = preg_replace('/[^\d:]/', '', $raw);
        if (preg_match('/^\d{1,2}:\d{2}$/', $clean)) {
            return $clean;
        }
        return null;
    }
}
