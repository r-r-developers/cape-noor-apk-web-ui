<?php

declare(strict_types=1);

namespace App\Services;

/**
 * Firebase Cloud Messaging via HTTP v1 API.
 * Requires a service account JSON for OAuth2 Bearer token generation.
 */
class FcmService
{
    private const FCM_ENDPOINT = 'https://fcm.googleapis.com/v1/projects/%s/messages:send';

    private string $projectId;
    private string $serviceAccountJson;

    public function __construct(array $settings)
    {
        $this->projectId         = $settings['firebase']['project_id'] ?? '';
        $this->serviceAccountJson = $settings['firebase']['service_account'] ?? '';
    }

    /**
     * Send a notification to a single device token.
     */
    public function sendToDevice(string $deviceToken, string $title, string $body, array $data = []): bool
    {
        if (empty($this->projectId)) {
            return false;
        }

        $message = [
            'message' => [
                'token'        => $deviceToken,
                'notification' => ['title' => $title, 'body' => $body],
                'data'         => array_map('strval', $data),
                'android'      => [
                    'notification' => [
                        'sound'        => 'adhan',
                        'channel_id'   => 'prayer_alerts',
                    ],
                ],
                'apns' => [
                    'payload' => ['aps' => ['sound' => 'adhan.caf']],
                ],
            ],
        ];

        return $this->post($message);
    }

    /**
     * Send to a topic (e.g. mosque-slug).
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = []): bool
    {
        if (empty($this->projectId)) {
            return false;
        }

        $message = [
            'message' => [
                'topic'        => $topic,
                'notification' => ['title' => $title, 'body' => $body],
                'data'         => array_map('strval', $data),
            ],
        ];

        return $this->post($message);
    }

    private function post(array $payload): bool
    {
        $url         = sprintf(self::FCM_ENDPOINT, $this->projectId);
        $accessToken = $this->getAccessToken();

        if (!$accessToken) {
            return false;
        }

        $ctx = stream_context_create([
            'http' => [
                'method'  => 'POST',
                'timeout' => 10,
                'header'  => implode("\r\n", [
                    'Content-Type: application/json',
                    "Authorization: Bearer {$accessToken}",
                ]),
                'content' => json_encode($payload),
            ],
        ]);

        $response = @file_get_contents($url, false, $ctx);
        return $response !== false;
    }

    /**
     * Generate an OAuth2 Bearer token from the service account JSON.
     * For production, use a proper OAuth2 library. This is a self-contained minimal version.
     */
    private function getAccessToken(): ?string
    {
        if (empty($this->serviceAccountJson)) {
            return null;
        }

        $sa = json_decode($this->serviceAccountJson, true);
        if (!$sa) {
            return null;
        }

        $now   = time();
        $scope = 'https://www.googleapis.com/auth/firebase.messaging';

        $header  = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $claims  = base64_encode(json_encode([
            'iss'   => $sa['client_email'],
            'scope' => $scope,
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
        ]));

        $unsigned = $header . '.' . $claims;
        openssl_sign($unsigned, $signature, $sa['private_key'], OPENSSL_ALGO_SHA256);
        $jwt = $unsigned . '.' . base64_encode($signature);

        $ctx = stream_context_create([
            'http' => [
                'method'  => 'POST',
                'header'  => 'Content-Type: application/x-www-form-urlencoded',
                'content' => http_build_query([
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion'  => $jwt,
                ]),
                'timeout' => 10,
            ],
        ]);

        $response = @file_get_contents('https://oauth2.googleapis.com/token', false, $ctx);
        if (!$response) {
            return null;
        }

        $data = json_decode($response, true);
        return $data['access_token'] ?? null;
    }
}
