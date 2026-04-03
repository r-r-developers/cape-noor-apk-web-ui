<?php

declare(strict_types=1);

namespace App\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class UtilityController extends BaseController
{
    private const KAABA_LAT = 21.3891;
    private const KAABA_LNG = 39.8579;

    // GET /v2/qibla?lat=&lng=
    public function qibla(Request $request, Response $response): Response
    {
        $lat = (float) ($this->query($request, 'lat') ?? 0);
        $lng = (float) ($this->query($request, 'lng') ?? 0);

        if ($lat === 0.0 && $lng === 0.0) {
            return $this->error($response, 'lat and lng query parameters are required');
        }

        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            return $this->error($response, 'Invalid latitude or longitude values');
        }

        $bearing = $this->calculateQibla($lat, $lng);

        return $this->success($response, [
            'qibla' => [
                'bearing'  => round($bearing, 4),
                'cardinal' => $this->bearingToCardinal($bearing),
            ],
        ]);
    }

    // GET /v2/calendar/hijri?date=YYYY-MM-DD
    public function hijri(Request $request, Response $response): Response
    {
        $dateStr = $this->query($request, 'date') ?? date('Y-m-d');

        try {
            $gregorian = new \DateTime($dateStr);
        } catch (\Exception) {
            return $this->error($response, 'Invalid date. Use YYYY-MM-DD format.');
        }

        $hijri = $this->gregorianToHijri(
            (int) $gregorian->format('Y'),
            (int) $gregorian->format('n'),
            (int) $gregorian->format('j')
        );

        return $this->success($response, ['gregorian' => $dateStr, 'hijri' => $hijri]);
    }

    // GET /v2/calendar/events?year=
    public function islamicEvents(Request $request, Response $response): Response
    {
        $year = (int) ($this->query($request, 'year') ?? date('Y'));

        // Static Islamic event data (approximate Gregorian dates for 2026/2027)
        $events = $this->getIslamicEvents($year);

        return $this->success($response, ['year' => $year, 'events' => $events]);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private — Qibla calculation
    // ─────────────────────────────────────────────────────────────────────────

    private function calculateQibla(float $lat, float $lng): float
    {
        $lat1   = deg2rad($lat);
        $lng1   = deg2rad($lng);
        $lat2   = deg2rad(self::KAABA_LAT);
        $lng2   = deg2rad(self::KAABA_LNG);
        $dLng   = $lng2 - $lng1;

        $y       = sin($dLng) * cos($lat2);
        $x       = cos($lat1) * sin($lat2) - sin($lat1) * cos($lat2) * cos($dLng);
        $bearing = rad2deg(atan2($y, $x));

        return ($bearing + 360) % 360;
    }

    private function bearingToCardinal(float $bearing): string
    {
        $directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
        $index = (int) round($bearing / 22.5) % 16;
        return $directions[$index];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private — Hijri conversion (Umm al-Qura algorithm approximation)
    // ─────────────────────────────────────────────────────────────────────────

    private function gregorianToHijri(int $y, int $m, int $d): array
    {
        // Julian Day Number
        if ($m <= 2) {
            $y--;
            $m += 12;
        }
        $a  = (int) ($y / 100);
        $b  = 2 - $a + (int) ($a / 4);
        $jd = (int) (365.25 * ($y + 4716)) + (int) (30.6001 * ($m + 1)) + $d + $b - 1524.5;

        // JD → Hijri
        $jd  = $jd - 1948438.5 + 0.5;
        $z   = floor($jd);
        $a   = floor(($z - 1867216.25) / 36524.25);
        $n   = $z + 1 + $a - floor($a / 4) + 38;
        $hYear = (int) floor(($n - 0.5) / 354.3666);
        $n2   = $n - floor(29.5001 * $hYear + 29.5);
        $hMonth = (int) floor($n2 / 29.5) + 1;
        if ($hMonth > 12) {
            $hMonth = 12;
        }
        $hDay = (int) $n2 - (int) floor(29.5001 * ($hMonth - 1)) + 1;

        $monthNames = [
            1  => 'Muharram',    2  => 'Safar',       3  => "Rabi' al-Awwal",
            4  => "Rabi' al-Thani", 5 => "Jumada al-Awwal", 6 => "Jumada al-Thani",
            7  => 'Rajab',       8  => "Sha'ban",      9  => 'Ramadan',
            10 => 'Shawwal',     11 => "Dhu al-Qi'dah", 12 => 'Dhu al-Hijjah',
        ];

        return [
            'year'       => $hYear,
            'month'      => $hMonth,
            'day'        => $hDay,
            'monthName'  => $monthNames[$hMonth] ?? '',
            'formatted'  => "{$hDay} {$monthNames[$hMonth]} {$hYear} AH",
        ];
    }

    private function getIslamicEvents(int $gregorianYear): array
    {
        // Approximate event data — in production these should come from a curated DB or API
        return [
            ['name' => 'Islamic New Year (1 Muharram)', 'hijri' => '1 Muharram', 'note' => 'Approximate Gregorian dates vary yearly'],
            ['name' => "Ashura (10 Muharram)",         'hijri' => '10 Muharram', 'note' => ''],
            ['name' => "Mawlid al-Nabi",               'hijri' => '12 Rabi al-Awwal', 'note' => 'Prophet\'s Birthday'],
            ['name' => 'Laylat al-Miraj',              'hijri' => '27 Rajab', 'note' => 'Night Journey'],
            ['name' => "Laylat al-Bara'ah",            'hijri' => "15 Sha'ban", 'note' => 'Night of Forgiveness'],
            ['name' => 'Ramadan begins',               'hijri' => '1 Ramadan', 'note' => ''],
            ['name' => 'Laylat al-Qadr',               'hijri' => '27 Ramadan', 'note' => 'Night of Power (approximate)'],
            ['name' => 'Eid al-Fitr',                  'hijri' => '1 Shawwal', 'note' => 'End of Ramadan'],
            ['name' => 'Day of Arafah',                'hijri' => '9 Dhu al-Hijjah', 'note' => 'Fast recommended'],
            ['name' => 'Eid al-Adha',                  'hijri' => '10 Dhu al-Hijjah', 'note' => 'Festival of Sacrifice'],
        ];
    }
}
