<?php
/**
 * This file is no longer used.
 * Auth is now handled via PHP sessions in lib/Auth.php.
 * All admin API endpoints call requireAuth() or requireRole() from lib/Auth.php.
 */
http_response_code(410);
header('Content-Type: application/json');
echo json_encode(['error' => 'This endpoint is gone. Use /api/auth/login instead.']);
