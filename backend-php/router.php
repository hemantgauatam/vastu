<?php
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$file = __DIR__ . '/public' . $path;
if ($path !== '/' && (is_file($file) || (is_dir($file) && is_file(rtrim($file, '/\\') . '/index.php')))) return false;
require __DIR__ . '/public/index.php';
