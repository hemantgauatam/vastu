<?php
// Local preview fixtures only. Never run against the production database.
if (PHP_SAPI !== 'cli' || getenv('DB_NAME') !== 'kubar_vastu_review_local' || getenv('APP_ENV') !== 'development') {
    fwrite(STDERR, "This script requires the isolated local preview database.\n"); exit(1);
}
$db = new PDO('mysql:host=127.0.0.1;port=3307;dbname=kubar_vastu_review_local;charset=utf8mb4', 'root', '', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$db->beginTransaction();
try {
    $names = ['reviewdemo' => 'Review Demo', 'sampleauthor' => 'Demo Contributor A', 'sampleauthorb' => 'Demo Contributor B'];
    foreach ($names as $username => $name) {
        $query = $db->prepare('INSERT INTO users(name,gender,email,phone,place,user_type,username,password_hash) VALUES(?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash)');
        $query->execute([$name, 'Other', $username.'@example.com', '9999999999', 'Local preview', 'Customer', $username, password_hash('LocalReview2026!', PASSWORD_DEFAULT)]);
    }
    $query = $db->prepare('SELECT id,name FROM users WHERE username=?');
    foreach (['sampleauthor', 'sampleauthorb'] as $username) {
        $query->execute([$username]); $user = $query->fetch(PDO::FETCH_ASSOC);
        $existing = $db->prepare('SELECT COUNT(*) FROM testimonials WHERE user_id=?'); $existing->execute([$user['id']]);
        if ((int)$existing->fetchColumn() === 0) {
            $insert = $db->prepare("INSERT INTO testimonials(name,rating,review,status,user_id) VALUES(?,5,?,'approved',?)");
            $insert->execute([$user['name'], 'LOCAL DEMO: Use the review options to test reporting and blocking.', $user['id']]);
            if ($username === 'sampleauthor') $insert->execute([$user['name'], 'LOCAL DEMO: Blocking Contributor A should also hide this second review.', $user['id']]);
        }
    }
    $db->commit(); echo "Local review demo accounts and sample reviews are ready.\n";
} catch (Throwable $e) { $db->rollBack(); throw $e; }
