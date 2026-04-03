<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Services\DatabaseService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class DuasController extends BaseController
{
    public function __construct(private readonly DatabaseService $db) {}

    // GET /v2/duas/categories
    public function categories(Request $request, Response $response): Response
    {
        $cats = $this->db->fetchAll(
            'SELECT id, name_ar, name_en, icon FROM duas_categories ORDER BY id ASC'
        );
        return $this->success($response, ['categories' => $cats]);
    }

    // GET /v2/duas/categories/{id}
    public function categoryWithDuas(Request $request, Response $response, array $args): Response
    {
        $id  = (int) $args['id'];
        $cat = $this->db->fetchOne('SELECT * FROM duas_categories WHERE id = ?', [$id]);

        if (!$cat) {
            return $this->error($response, 'Category not found', 404);
        }

        $duas = $this->db->fetchAll(
            'SELECT id, title_ar, title_en, arabic, transliteration, translation, reference, audio_url
             FROM duas WHERE category_id = ? ORDER BY id ASC',
            [$id]
        );

        return $this->success($response, ['category' => $cat, 'duas' => $duas]);
    }

    // GET /v2/duas/{id}
    public function show(Request $request, Response $response, array $args): Response
    {
        $id  = (int) $args['id'];
        $dua = $this->db->fetchOne(
            'SELECT d.*, c.name_en AS category_name
             FROM duas d
             JOIN duas_categories c ON c.id = d.category_id
             WHERE d.id = ?',
            [$id]
        );

        if (!$dua) {
            return $this->error($response, 'Dua not found', 404);
        }

        return $this->success($response, ['dua' => $dua]);
    }
}
