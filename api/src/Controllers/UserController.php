<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\DatabaseService;
use App\Services\FcmService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class UserController extends BaseController
{
    public function __construct(
        private readonly DatabaseService $db,
        private readonly FcmService $fcm
    ) {}

    // GET /v2/user/settings
    public function getSettings(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $rows   = $this->db->fetchAll(
            'SELECT `key`, `value` FROM user_settings WHERE app_user_id = ?',
            [$userId]
        );

        $settings = [];
        foreach ($rows as $row) {
            $settings[$row['key']] = json_decode($row['value'], true) ?? $row['value'];
        }

        return $this->success($response, ['settings' => $settings]);
    }

    // PUT /v2/user/settings
    public function updateSettings(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $body   = $this->body($request);

        $allowed = [
            'notification_enabled', 'prayer_notifications', 'adhan_audio',
            'madhab', 'theme', 'followed_mosque_slug', 'notification_offsets',
        ];

        foreach ($body as $key => $value) {
            if (!in_array($key, $allowed, true)) {
                continue;
            }
            $encoded = json_encode($value);
            $this->db->execute(
                'INSERT INTO user_settings (app_user_id, `key`, `value`, updated_at)
                 VALUES (?, ?, ?, NOW())
                 ON DUPLICATE KEY UPDATE `value` = VALUES(`value`), updated_at = NOW()',
                [$userId, $key, $encoded]
            );
        }

        return $this->success($response, ['message' => 'Settings updated']);
    }

    // POST /v2/user/device-token
    public function registerDeviceToken(Request $request, Response $response): Response
    {
        $userId   = $this->userId($request);
        $token    = $this->param($request, 'token') ?? '';
        $platform = $this->param($request, 'platform') ?? 'android';
        $mosqueSlug = $this->param($request, 'mosque_slug');

        if (!$token) {
            return $this->error($response, 'token is required');
        }

        if (!in_array($platform, ['android', 'ios', 'web'], true)) {
            return $this->error($response, 'platform must be android, ios, or web');
        }

        $this->db->execute(
            'INSERT INTO device_tokens (app_user_id, token, platform, mosque_slug, created_at)
             VALUES (?, ?, ?, ?, NOW())
             ON DUPLICATE KEY UPDATE app_user_id = VALUES(app_user_id), platform = VALUES(platform), mosque_slug = VALUES(mosque_slug)',
            [$userId, $token, $platform, $mosqueSlug]
        );

        return $this->success($response, ['message' => 'Device token registered'], 201);
    }

    // DELETE /v2/user/device-token
    public function removeDeviceToken(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $token  = $this->param($request, 'token') ?? '';

        $this->db->execute(
            'DELETE FROM device_tokens WHERE token = ? AND app_user_id = ?',
            [$token, $userId]
        );

        return $this->success($response, ['message' => 'Device token removed']);
    }

    // GET /v2/user/prayer-log?month=YYYY-MM
    public function getPrayerLog(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $month  = $this->query($request, 'month') ?? date('Y-m');

        if (!preg_match('/^\d{4}-\d{2}$/', $month)) {
            return $this->error($response, 'Invalid month format. Use YYYY-MM.');
        }

        $logs = $this->db->fetchAll(
            'SELECT date, prayer, status FROM prayer_logs
             WHERE app_user_id = ? AND date LIKE ?
             ORDER BY date ASC, FIELD(prayer, "fajr","thuhr","asr","maghrib","isha")',
            [$userId, $month . '%']
        );

        // Group by date
        $grouped = [];
        foreach ($logs as $log) {
            $grouped[$log['date']][$log['prayer']] = $log['status'];
        }

        return $this->success($response, ['month' => $month, 'log' => $grouped]);
    }

    // POST /v2/user/prayer-log
    public function logPrayer(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $prayer = strtolower($this->param($request, 'prayer') ?? '');
        $date   = $this->param($request, 'date') ?? date('Y-m-d');
        $status = $this->param($request, 'status') ?? 'prayed';

        $validPrayers = ['fajr', 'thuhr', 'asr', 'maghrib', 'isha'];
        $validStatuses = ['prayed', 'missed', 'qadha'];

        if (!in_array($prayer, $validPrayers, true)) {
            return $this->error($response, 'Invalid prayer name');
        }
        if (!in_array($status, $validStatuses, true)) {
            return $this->error($response, 'Status must be: prayed, missed, or qadha');
        }
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return $this->error($response, 'Invalid date format. Use YYYY-MM-DD.');
        }

        $this->db->execute(
            'INSERT INTO prayer_logs (app_user_id, date, prayer, status, logged_at)
             VALUES (?, ?, ?, ?, NOW())
             ON DUPLICATE KEY UPDATE status = VALUES(status), logged_at = NOW()',
            [$userId, $date, $prayer, $status]
        );

        return $this->success($response, ['message' => 'Prayer logged'], 201);
    }

    // GET /v2/user/bookmarks/quran
    public function getBookmarks(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $bookmarks = $this->db->fetchAll(
            'SELECT id, surah, ayah, note, created_at FROM quran_bookmarks
             WHERE app_user_id = ? ORDER BY created_at DESC',
            [$userId]
        );
        return $this->success($response, ['bookmarks' => $bookmarks]);
    }

    // POST /v2/user/bookmarks/quran
    public function addBookmark(Request $request, Response $response): Response
    {
        $userId = $this->userId($request);
        $surah  = (int) $this->param($request, 'surah');
        $ayah   = (int) $this->param($request, 'ayah');
        $note   = $this->param($request, 'note') ?? '';

        if ($surah < 1 || $surah > 114 || $ayah < 1) {
            return $this->error($response, 'Valid surah (1-114) and ayah are required');
        }

        // Check for duplicate
        $existing = $this->db->fetchOne(
            'SELECT id FROM quran_bookmarks WHERE app_user_id = ? AND surah = ? AND ayah = ?',
            [$userId, $surah, $ayah]
        );

        if ($existing) {
            return $this->error($response, 'Ayah already bookmarked', 409);
        }

        $id = $this->db->insert(
            'INSERT INTO quran_bookmarks (app_user_id, surah, ayah, note, created_at) VALUES (?, ?, ?, ?, NOW())',
            [$userId, $surah, $ayah, $note]
        );

        return $this->success($response, ['id' => (int) $id, 'surah' => $surah, 'ayah' => $ayah], 201);
    }

    // DELETE /v2/user/bookmarks/quran/{id}
    public function removeBookmark(Request $request, Response $response, array $args): Response
    {
        $userId = $this->userId($request);
        $id     = (int) ($args['id'] ?? 0);

        $affected = $this->db->execute(
            'DELETE FROM quran_bookmarks WHERE id = ? AND app_user_id = ?',
            [$id, $userId]
        );

        if ($affected === 0) {
            return $this->error($response, 'Bookmark not found', 404);
        }

        return $this->success($response, ['message' => 'Bookmark removed']);
    }
}
