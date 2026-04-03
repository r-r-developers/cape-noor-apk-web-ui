<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\DatabaseService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class MosqueController extends BaseController
{
    public function __construct(private readonly DatabaseService $db) {}

    // GET /v2/mosques
    public function index(Request $request, Response $response): Response
    {
        $mosques = $this->db->fetchAll(
            'SELECT slug, short_id, name, logo, address, phone, website, show_fasting,
                    show_sidebars, color_primary, color_gold, color_bg, is_default
             FROM mosques ORDER BY name ASC'
        );

        $mosques = array_map([$this, 'formatMosque'], $mosques);
        return $this->success($response, ['mosques' => $mosques]);
    }

    // GET /v2/mosques/default
    public function defaultMosque(Request $request, Response $response): Response
    {
        $mosque = $this->db->fetchOne('SELECT * FROM mosques WHERE is_default = 1 LIMIT 1');
        if (!$mosque) {
            $mosque = $this->db->fetchOne('SELECT * FROM mosques LIMIT 1');
        }

        if (!$mosque) {
            return $this->error($response, 'No mosque configured', 404);
        }

        return $this->success($response, ['mosque' => $this->formatMosque($mosque, full: true)]);
    }

    // GET /v2/mosques/{slug}
    public function show(Request $request, Response $response, array $args): Response
    {
        $identifier = $args['slug'] ?? '';

        // Accept slug or 3-digit short_id
        if (preg_match('/^\d{3}$/', $identifier)) {
            $mosque = $this->db->fetchOne('SELECT * FROM mosques WHERE short_id = ?', [$identifier]);
        } else {
            $mosque = $this->db->fetchOne('SELECT * FROM mosques WHERE slug = ?', [$identifier]);
        }

        if (!$mosque) {
            return $this->error($response, 'Mosque not found', 404);
        }

        return $this->success($response, ['mosque' => $this->formatMosque($mosque, full: true)]);
    }

    private function formatMosque(array $row, bool $full = false): array
    {
        $base = [
            'slug'         => $row['slug'],
            'shortId'      => $row['short_id'],
            'name'         => $row['name'],
            'logo'         => $row['logo'],
            'isDefault'    => (bool) ($row['is_default'] ?? false),
            'colors'       => [
                'primary' => $row['color_primary'] ?? '#22c55e',
                'gold'    => $row['color_gold'] ?? '#d4af37',
                'bg'      => $row['color_bg'] ?? '#0a0f1a',
            ],
        ];

        if (!$full) {
            return $base;
        }

        return array_merge($base, [
            'address'       => $row['address'],
            'phone'         => $row['phone'],
            'website'       => $row['website'],
            'showFasting'   => (bool) $row['show_fasting'],
            'showSidebars'  => (bool) $row['show_sidebars'],
            'announcements' => $row['announcements'] ? json_decode($row['announcements'], true) : [],
            'socialMedia'   => $row['social_media'] ? json_decode($row['social_media'], true) : [],
            'sponsors'      => $row['sponsors'] ? json_decode($row['sponsors'], true) : [],
            'adhanOffsets'  => $row['adhan_offsets'] ? json_decode($row['adhan_offsets'], true) : [],
            'facebookPageId'   => $row['facebook_page_id'],
            'facebookPageName' => $row['facebook_page_name'],
        ]);
    }
}
