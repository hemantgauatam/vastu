<?php
declare(strict_types=1);

$requestPath = (string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
if ($requestPath === '/' || preg_match('#/public/?$#', $requestPath)) {
    $adminPath = rtrim($requestPath, '/') . '/admin/';
    if ($adminPath === '/admin/') $adminPath = './admin/';
    header('Location: ' . $adminPath, true, 302);
    exit;
}

require dirname(__DIR__) . '/src/App.php';
try {
    (new KubarVastu\App(dirname(__DIR__)))->run();
} catch (Throwable $error) {
    error_log('[Kubar Vastu startup] ' . $error->getMessage());
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    $development = getenv('APP_ENV') === 'development';
    echo json_encode([
        'error' => 'Backend startup failed',
        'detail' => $development ? $error->getMessage() : 'Check the server PHP error log',
    ], JSON_UNESCAPED_SLASHES);
}
