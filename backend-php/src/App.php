<?php
declare(strict_types=1);

namespace KubarVastu;

use PDO;
use PDOException;
use Throwable;

final class App
{
    private PDO $db;
    private array $env = [];
    private array $body = [];
    private string $method;
    private string $path;
    private string $root;

    public function __construct(string $root)
    {
        $this->root = $root;
        $this->loadEnv($root . '/.env');
        $this->method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $requestPath = (string)parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
        $scriptDirectory = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
        if ($scriptDirectory !== '' && $scriptDirectory !== '.' && str_starts_with($requestPath, $scriptDirectory)) $requestPath = substr($requestPath, strlen($scriptDirectory)) ?: '/';
        $this->path = '/' . trim($requestPath, '/');
        if ($this->path === '//') $this->path = '/';
        $raw = file_get_contents('php://input') ?: '';
        $decoded = json_decode($raw, true);
        $this->body = is_array($decoded) ? $decoded : [];
        $this->connectDatabase();
        if (filter_var($this->env('AUTO_MIGRATE', 'true'), FILTER_VALIDATE_BOOL)) $this->migrate();
    }

    public function run(): void
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        if ($this->method === 'OPTIONS') { http_response_code(204); return; }
        try {
            $this->route();
        } catch (PDOException $e) {
            $code = (int)($e->errorInfo[1] ?? 0);
            $this->json(['error' => $code === 1062 ? 'A record with these details already exists' : 'Database request failed'], $code === 1062 ? 409 : 500);
        } catch (Throwable $e) {
            $this->json(['error' => $this->env('APP_ENV', 'production') === 'development' ? $e->getMessage() : 'Internal server error'], 500);
        }
    }

    private function route(): void
    {
        if ($this->method === 'GET' && ($this->path === '/admin' || $this->path === '/admin/')) { $this->adminPage(); return; }
        if ($this->method === 'GET' && $this->path === '/health') { $this->json(['ok'=>true,'service'=>'kubar-vastu-php','database'=>'mysql','razorpayConfigured'=>$this->razorpayConfigured()]); return; }
        if ($this->method === 'GET' && $this->match('/api/media/([A-Za-z0-9._-]+)', $filename)) { $this->serveMedia($filename); return; }
        if ($this->method === 'POST' && $this->path === '/api/admin/login') { $this->adminLogin(); return; }
        if (str_starts_with($this->path, '/api/admin/')) $this->requireAdmin();

        if ($this->method === 'GET' && $this->path === '/api/admin/session') { $this->json(['authenticated'=>true,'email'=>$this->env('ADMIN_EMAIL','admin@gmail.com')]); return; }
        if ($this->method === 'POST' && $this->path === '/api/admin/logout') { $this->adminLogout(); return; }
        if ($this->method === 'POST' && $this->path === '/api/admin/uploads') { $this->upload(); return; }
        if ($this->method === 'GET' && $this->path === '/api/content/videos') { $this->contentVideos(); return; }
        if ($this->match('/api/admin/videos/(\\d+)', $id)) { $this->videoItem((int)$id); return; }
        if ($this->method === 'POST' && $this->path === '/api/admin/videos') { $this->videoCreate(); return; }
        if ($this->method === 'GET' && $this->path === '/api/blogs') { $this->blogs(); return; }
        if ($this->match('/api/admin/blogs/(\\d+)', $id)) { $this->blogItem((int)$id); return; }
        if ($this->method === 'POST' && $this->path === '/api/admin/blogs') { $this->blogCreate(); return; }
        if ($this->method === 'GET' && $this->path === '/api/testimonials') { $this->testimonials(); return; }
        if ($this->method === 'POST' && $this->path === '/api/testimonials') { $this->testimonialCreate(); return; }
        if ($this->method === 'PUT' && $this->match('/api/admin/testimonials/(\\d+)/status', $id)) { $this->testimonialStatus((int)$id); return; }
        if ($this->method === 'POST' && $this->path === '/api/auth/register') { $this->register(); return; }
        if ($this->method === 'POST' && $this->path === '/api/auth/login') { $this->login(); return; }
        if ($this->method === 'POST' && $this->path === '/api/auth/logout') { [$user,$session]=$this->auth(); $this->logout($user,$session); return; }
        if ($this->method === 'DELETE' && $this->path === '/api/me') { [$user]=$this->auth(); $this->deleteAccount($user); return; }
        if ($this->method === 'POST' && $this->match('/api/testimonials/(\\d+)/report', $id)) { [$user]=$this->auth(); $this->reportTestimonial((int)$id, $user); return; }
        if ($this->method === 'GET' && $this->path === '/api/me') { [$user]=$this->auth(); $this->me($user); return; }
        if ($this->method === 'GET' && $this->path === '/api/remedies') { $this->remedies(); return; }
        if ($this->method === 'GET' && $this->path === '/api/app-update') { $this->json(['update'=>$this->appUpdate()]); return; }
        if ($this->method === 'GET' && $this->path === '/api/admin/overview') { $this->overview(); return; }
        if ($this->method === 'GET' && $this->path === '/api/admin/app-update') { $this->json(['update'=>$this->appUpdate()]); return; }
        if ($this->method === 'PUT' && $this->path === '/api/admin/app-update') { $this->saveAppUpdate(); return; }
        if ($this->match('/api/admin/remedies/([^/]+)', $id)) { $this->remedyItem(urldecode($id)); return; }
        if ($this->method === 'POST' && $this->path === '/api/admin/remedies') { $this->remedyCreate(); return; }
        if ($this->method === 'POST' && $this->path === '/api/payments/create') { [$user]=$this->auth(); $this->paymentCreate($user); return; }
        if ($this->method === 'GET' && $this->match('/api/payments/(\\d+)/status', $id)) { [$user]=$this->auth(); $this->paymentStatus((int)$id,$user); return; }
        if ($this->method === 'GET' && $this->match('/payment/([a-f0-9]+)', $token)) { $this->paymentPage($token); return; }
        if ($this->method === 'POST' && $this->match('/api/payments/verify/([a-f0-9]+)', $token)) { $this->paymentVerify($token); return; }
        if ($this->method === 'POST' && $this->path === '/api/users') { $this->userSave(); return; }
        if ($this->method === 'GET' && $this->path === '/api/users') { $this->userGet(); return; }
        if ($this->method === 'POST' && $this->path === '/api/orders/checkout') { $this->json(['error'=>'Use the verified Razorpay payment flow'],410); return; }
        if ($this->method === 'POST' && $this->path === '/api/orders') { $this->orderCreate(); return; }
        if ($this->method === 'GET' && $this->path === '/api/orders') { $this->ordersGet(); return; }
        $this->json(['error'=>'Route not found'],404);
    }

    private function loadEnv(string $file): void { if (!is_file($file)) return; foreach (file($file, FILE_IGNORE_NEW_LINES|FILE_SKIP_EMPTY_LINES) ?: [] as $line) { $line=trim($line); if ($line==='' || $line[0]==='#' || !str_contains($line,'=')) continue; [$k,$v]=explode('=',$line,2); $this->env[trim($k)]=trim(trim($v), "\"'"); } }
    private function env(string $key,string $default=''): string { if(array_key_exists($key,$_ENV))return (string)$_ENV[$key];$system=getenv($key);if($system!==false)return (string)$system;return (string)($this->env[$key]??$default); }
    private function connectDatabase(): void { $host=$this->env('DB_HOST','127.0.0.1');$port=$this->env('DB_PORT','3306');$name=$this->env('DB_NAME','kubar_vastu');if(!preg_match('/^[A-Za-z0-9_]+$/',$name))throw new \RuntimeException('DB_NAME may contain only letters, numbers, and underscores');$options=[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false];$this->db=new PDO("mysql:host={$host};port={$port};charset=utf8mb4",$this->env('DB_USER','root'),$this->env('DB_PASSWORD',''),$options);try{$this->db->exec("CREATE DATABASE IF NOT EXISTS `{$name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");}catch(PDOException){}$this->db->exec("USE `{$name}`"); }
    private function migrate(): void { $this->db->exec('CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(100) PRIMARY KEY, applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB');if(!$this->q('SELECT version FROM schema_migrations WHERE version=?',['001_initial'])->fetch()){$schema=file_get_contents($this->root.'/database/schema.sql');if($schema===false)throw new \RuntimeException('Database schema file is missing');foreach(array_filter(array_map('trim',explode(';',$schema))) as $statement){if(preg_match('/^(CREATE DATABASE|USE)\b/i',$statement))continue;$this->db->exec($statement);}$this->q('INSERT IGNORE INTO schema_migrations(version) VALUES(?)',['001_initial']);}if(!$this->q('SELECT version FROM schema_migrations WHERE version=?',['002_shipping'])->fetch()){foreach(['purchases','orders'] as $table){$column=$this->q('SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=? AND COLUMN_NAME=?',[$table,'shipping'])->fetch();if(!$column)$this->db->exec('ALTER TABLE '.$table.' ADD COLUMN shipping JSON NULL');}$this->q('INSERT INTO schema_migrations(version) VALUES(?)',['002_shipping']);} if(!$this->q('SELECT version FROM schema_migrations WHERE version=?',['003_review_safety'])->fetch()) {
            $column=$this->q('SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=? AND COLUMN_NAME=?',['testimonials','user_id'])->fetch();
            if(!$column) $this->db->exec('ALTER TABLE testimonials ADD COLUMN user_id BIGINT UNSIGNED NULL, ADD INDEX idx_testimonial_user(user_id)');
            $this->db->exec("CREATE TABLE IF NOT EXISTS content_reports (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, testimonial_id BIGINT UNSIGNED NOT NULL, reporter_id BIGINT UNSIGNED NOT NULL, reason VARCHAR(500) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY reporter_review(reporter_id,testimonial_id)) ENGINE=InnoDB");
            $this->q('INSERT INTO schema_migrations(version) VALUES(?)',['003_review_safety']);
        } }
    private function json(array $data,int $status=200): never { http_response_code($status); header('Content-Type: application/json; charset=utf-8'); echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE); exit; }
    private function match(string $pattern,?string &$value): bool { if (preg_match('#^'.$pattern.'/?$#',$this->path,$m)) { $value=$m[1]; return true; } return false; }
    private function q(string $sql,array $params=[]): \PDOStatement { $s=$this->db->prepare($sql); $s->execute($params); return $s; }
    private function required(array $fields): void { $missing=[]; foreach($fields as $f) if(trim((string)($this->body[$f]??''))==='') $missing[]=$f; if($missing) $this->json(['error'=>'Missing required field(s): '.implode(', ',$missing)],400); }
    private function now(): string { return gmdate('Y-m-d H:i:s'); }
    private function iso(?string $v): ?string { return $v ? gmdate('c',strtotime($v)) : null; }
    private function boolValue(mixed $v,bool $default=true): int { return $v===null ? ($default?1:0) : (filter_var($v,FILTER_VALIDATE_BOOL)?1:0); }
    private function bearer(): string { $h=$_SERVER['HTTP_AUTHORIZATION'] ?? ''; return preg_match('/^Bearer\s+(.+)$/i',$h,$m) ? trim($m[1]) : ''; }
    private function auth(): array { $token=$this->bearer(); if(!$token) $this->json(['error'=>'Login required'],401); $s=$this->q('SELECT * FROM sessions WHERE token_hash=? AND revoked_at IS NULL AND expires_at>UTC_TIMESTAMP()',[hash('sha256',$token)])->fetch(); if(!$s) $this->json(['error'=>'Session expired'],401); $u=$this->q('SELECT * FROM users WHERE id=?',[$s['user_id']])->fetch(); if(!$u) $this->json(['error'=>'User not found'],401); return [$u,$s]; }
    private function optionalUser(): ?array { try { return $this->bearer() ? $this->auth()[0] : null; } catch(Throwable) { return null; } }
    private function issueSession(int $userId): array { $token=bin2hex(random_bytes(32)); $days=max(1,(int)$this->env('SESSION_DAYS','30')); $expires=gmdate('Y-m-d H:i:s',time()+$days*86400); $this->q('INSERT INTO sessions(user_id,token_hash,expires_at) VALUES(?,?,?)',[$userId,hash('sha256',$token),$expires]); return ['token'=>$token,'expiresAt'=>$this->iso($expires)]; }

    private function publicUser(array $u): array { return ['id'=>(string)$u['id'],'name'=>$u['name'],'gender'=>$u['gender']??'','email'=>$u['email'],'phone'=>$u['phone']??'','place'=>$u['place']??'','userType'=>$u['user_type']??'','username'=>$u['username']??'','createdAt'=>$this->iso($u['created_at']??null),'updatedAt'=>$this->iso($u['updated_at']??null),'lastLoginAt'=>$this->iso($u['last_login_at']??null),'lastLogoutAt'=>$this->iso($u['last_logout_at']??null)]; }
    private function publicRemedy(array $r): array { $list=fn($k,$limit=10)=>array_slice(json_decode($r[$k]?:'[]',true)?:[],0,$limit);$media=fn($k,$limit=10)=>array_values(array_filter(array_map(fn($url)=>$this->publicMediaUrl((string)$url),$list($k,$limit))));return ['id'=>$r['id'],'title'=>$r['title'],'subtitle'=>$r['subtitle']??'','direction'=>$r['direction'],'purpose'=>$r['purpose'],'category'=>$r['category']??'General Remedies','price'=>(float)$r['price'],'whyYouNeed'=>$r['why_you_need']??'','howItWorks'=>$r['how_it_works']??'','whatYouGet'=>$r['what_you_get']??'','placement'=>$r['placement']??'','offers'=>$list('offers',8),'imageUrls'=>$media('image_urls',10),'videoUrls'=>$media('video_urls',6),'installationImageUrls'=>$media('installation_image_urls',10),'installationVideoUrls'=>$media('installation_video_urls',6),'createdAt'=>$this->iso($r['created_at']??null),'updatedAt'=>$this->iso($r['updated_at']??null)]; }
    private function publicMediaUrl(string $url): string { $url=html_entity_decode(trim($url),ENT_QUOTES|ENT_HTML5,'UTF-8');if(preg_match('/^\\[[^\\]]*\\]\\((https?:\\/\\/[^\\s)]+)\\)$/i',$url,$match))$url=$match[1];if($url==='')return '';$parts=parse_url($url);$path=(string)($parts['path']??'');if(preg_match('#/uploads/([A-Za-z0-9._-]+)$#',$path,$upload))return rtrim($this->origin(),'/').'/api/media/'.rawurlencode($upload[1]);if(isset($parts['scheme'])&&in_array(strtolower((string)$parts['scheme']),['http','https'],true)){if(!in_array(strtolower((string)($parts['host']??'')),['localhost','127.0.0.1','10.0.2.2'],true))return $url;$url=$path;}return rtrim($this->origin(),'/').'/'.ltrim($url,'/'); }
    private function publicOrder(array $o): array { return ['id'=>(string)$o['id'],'userId'=>(string)$o['user_id'],'remedyId'=>$o['remedy_id'],'remedyName'=>$o['remedy_name'],'quantity'=>(int)$o['quantity'],'unitPrice'=>(float)$o['unit_price'],'price'=>(float)$o['price'],'status'=>$o['status'],'purchasedAt'=>$this->iso($o['purchased_at']),'validityStartsAt'=>$this->iso($o['validity_starts_at']?:$o['purchased_at']),'validityEndsAt'=>$this->iso($o['validity_ends_at']),'paymentId'=>$o['payment_id']??'','shipping'=>json_decode((string)($o['shipping']??''),true)?:null]; }
    private function publicBlog(array $b): array { return ['id'=>(string)$b['id'],'title'=>$b['title'],'description'=>$b['description'],'content'=>$b['content'],'imageUrl'=>$b['image_url']??'','category'=>$b['category'],'published'=>(bool)$b['published'],'publishedAt'=>$this->iso($b['published_at'])]; }
    private function publicTestimonial(array $t): array { return ['authorId'=>empty($t['user_id']) ? '' : hash_hmac('sha256',(string)$t['user_id'],$this->env('APP_KEY','kuber-vastu-author')),'id'=>(string)$t['id'],'name'=>$t['name'],'profileImageUrl'=>$t['profile_image_url']??'','rating'=>(int)$t['rating'],'review'=>$t['review'],'status'=>$t['status'],'createdAt'=>$this->iso($t['created_at'])]; }
    private function publicVideo(array $v): array { return ['id'=>$v['video_id'],'recordId'=>(string)$v['id'],'title'=>$v['title'],'thumbnailUrl'=>$v['thumbnail_url']?:'https://img.youtube.com/vi/'.$v['video_id'].'/hqdefault.jpg','published'=>(bool)$v['published'],'publishedAt'=>$this->iso($v['published_at'])]; }

    private function adminPage(): never { $file=$this->root.'/public/admin/index.php'; if(!is_file($file)) { http_response_code(404); exit('Admin portal not found'); } require $file; exit; }
    private function adminLogin(): void { $email=strtolower(trim((string)($this->body['email']??''))); $password=(string)($this->body['password']??''); if($this->env('ADMIN_PASSWORD')===''||!hash_equals(strtolower($this->env('ADMIN_EMAIL','admin@gmail.com')),$email)||!hash_equals($this->env('ADMIN_PASSWORD',''),$password)) $this->json(['error'=>'Invalid admin email or password'],401); $token=bin2hex(random_bytes(32)); $seconds=max(1,(int)$this->env('ADMIN_SESSION_HOURS','12'))*3600; $this->q('DELETE FROM admin_sessions WHERE expires_at<=UTC_TIMESTAMP()'); $this->q('INSERT INTO admin_sessions(token_hash,expires_at) VALUES(?,?)',[hash('sha256',$token),gmdate('Y-m-d H:i:s',time()+$seconds)]); setcookie('kubar_admin_session',$token,['expires'=>time()+$seconds,'path'=>'/','httponly'=>true,'samesite'=>'Lax','secure'=>(!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off')]); $this->json(['ok'=>true,'email'=>$email]); }
    private function requireAdmin(): void { $token=(string)($_COOKIE['kubar_admin_session']??''); $row=$token ? $this->q('SELECT id FROM admin_sessions WHERE token_hash=? AND expires_at>UTC_TIMESTAMP()',[hash('sha256',$token)])->fetch() : false; if(!$row) $this->json(['error'=>'Admin login required'],401); }
    private function adminLogout(): void { $token=(string)($_COOKIE['kubar_admin_session']??''); if($token) $this->q('DELETE FROM admin_sessions WHERE token_hash=?',[hash('sha256',$token)]); setcookie('kubar_admin_session','',['expires'=>1,'path'=>'/','httponly'=>true,'samesite'=>'Lax']); $this->json(['ok'=>true]); }
    private function upload(): void { $data=(string)($this->body['data']??''); if(!preg_match('#^data:(image/(?:png|jpeg|webp)|video/(?:mp4|webm));base64,([A-Za-z0-9+/=]+)$#',$data,$m)) $this->json(['error'=>'Unsupported image or video file'],400); $bytes=base64_decode($m[2],true); if($bytes===false) $this->json(['error'=>'Invalid file data'],400); if(strlen($bytes)>8*1024*1024) $this->json(['error'=>'File must be 8 MB or smaller'],413); $ext=['image/png'=>'png','image/jpeg'=>'jpg','image/webp'=>'webp','video/mp4'=>'mp4','video/webm'=>'webm'][$m[1]]; $dir=$this->root.'/public/uploads'; if(!is_dir($dir)) mkdir($dir,0775,true); $name=(string)round(microtime(true)*1000).'-'.bin2hex(random_bytes(12)).'.'.$ext; if(file_put_contents($dir.'/'.$name,$bytes)===false) $this->json(['error'=>'Could not save upload'],500); $this->json(['url'=>rtrim($this->origin(),'/').'/api/media/'.$name],201); }
    private function serveMedia(string $filename): never { if(!preg_match('/^[A-Za-z0-9._-]+\.(?:jpe?g|png|webp|mp4|webm)$/i',$filename))$this->json(['error'=>'Media not found'],404);$file=$this->root.'/public/uploads/'.$filename;if(!is_file($file))$this->json(['error'=>'Media not found'],404);$extension=strtolower(pathinfo($filename,PATHINFO_EXTENSION));$types=['jpg'=>'image/jpeg','jpeg'=>'image/jpeg','png'=>'image/png','webp'=>'image/webp','mp4'=>'video/mp4','webm'=>'video/webm'];header('Content-Type: '.$types[$extension]);header('Content-Length: '.filesize($file));header('Cache-Control: public, max-age=86400');header('Cross-Origin-Resource-Policy: cross-origin');readfile($file);exit; }
    private function origin(): string { $configured=rtrim($this->env('APP_URL',''),'/'); if($configured) return $configured; $scheme=(!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off')?'https':'http'; return $scheme.'://'.($_SERVER['HTTP_HOST']??'localhost'); }

    private function register(): void { $this->required(['name','gender','phone','email','place','userType','username','password']); $email=strtolower(trim((string)$this->body['email'])); $username=strtolower(trim((string)$this->body['username'])); $password=(string)$this->body['password']; if(strlen($password)<6) $this->json(['error'=>'Password must be at least 6 characters'],400); if(strlen($username)<3||preg_match('/\s/',$username)) $this->json(['error'=>'Username must be at least 3 characters and cannot contain spaces'],400); if(!filter_var($email,FILTER_VALIDATE_EMAIL)) $this->json(['error'=>'Enter a valid email address'],400); $phone=preg_replace('/[\s-]/','',(string)$this->body['phone']); if(!preg_match('/^\+?[0-9]{10,15}$/',$phone)) $this->json(['error'=>'Enter a valid mobile number'],400); $old=$this->q('SELECT email,username FROM users WHERE email=? OR username=?',[$email,$username])->fetch(); if($old) $this->json(['error'=>$old['email']===$email?'Email already registered':'Username already registered'],409); $now=$this->now(); $this->q('INSERT INTO users(name,gender,email,phone,place,user_type,username,password_hash,last_login_at) VALUES(?,?,?,?,?,?,?,?,?)',[trim((string)$this->body['name']),trim((string)$this->body['gender']),$email,trim((string)$this->body['phone']),trim((string)$this->body['place']),trim((string)$this->body['userType']),$username,password_hash($password,PASSWORD_DEFAULT),$now]); $u=$this->q('SELECT * FROM users WHERE id=?',[(int)$this->db->lastInsertId()])->fetch(); $this->json(['user'=>$this->publicUser($u)]+$this->issueSession((int)$u['id']),201); }
    private function login(): void { $this->required(['username','password']); $name=strtolower(trim((string)$this->body['username'])); $u=$this->q('SELECT * FROM users WHERE username=? OR email=? LIMIT 1',[$name,$name])->fetch(); if(!$u||!password_verify((string)$this->body['password'],$u['password_hash'])) $this->json(['error'=>'Invalid username or password'],401); $this->q('UPDATE users SET last_login_at=UTC_TIMESTAMP() WHERE id=?',[$u['id']]); $u=$this->q('SELECT * FROM users WHERE id=?',[$u['id']])->fetch(); $this->json(['user'=>$this->publicUser($u)]+$this->issueSession((int)$u['id'])); }
    private function logout(array $u,array $s): void { $this->q('UPDATE sessions SET revoked_at=UTC_TIMESTAMP() WHERE id=?',[$s['id']]); $this->q('UPDATE users SET last_logout_at=UTC_TIMESTAMP() WHERE id=?',[$u['id']]); $this->json(['ok'=>true]); }
    private function me(array $u): void { $rows=$this->q('SELECT * FROM orders WHERE user_id=? ORDER BY purchased_at DESC',[$u['id']])->fetchAll(); $this->json(['user'=>$this->publicUser($u),'orders'=>array_map(fn($r)=>$this->publicOrder($r),$rows)]); }

    private function remedies(): void { $this->seedRemedies(); $rows=$this->q('SELECT * FROM remedies ORDER BY created_at,id')->fetchAll(); $this->json(['remedies'=>array_map(fn($r)=>$this->publicRemedy($r),$rows)]); }
    private function seedRemedies(): void { if((int)$this->q('SELECT COUNT(*) FROM remedies')->fetchColumn()>0) return; $file=$this->root.'/database/remedies-catalog.json';if(!is_file($file))$file=dirname($this->root).'/backend/data/remedies-catalog.json'; $items=is_file($file)?json_decode(file_get_contents($file)?:'[]',true):[]; $items=array_merge([['id'=>'wealth-kalash','title'=>'Wealth Kalash','subtitle'=>'North prosperity balancing kit','direction'=>'North','purpose'=>'Prosperity and steady opportunities','category'=>'Wealth & Prosperity','price'=>799],['id'=>'agni-copper','title'=>'Agni Copper Set','subtitle'=>'Southeast fire element support','direction'=>'Southeast','purpose'=>'Energy, kitchen harmony, and transformation','category'=>'Health & Energy','price'=>1199],['id'=>'ishanya-crystal','title'=>'Ishanya Crystal','subtitle'=>'Northeast clarity and prayer corner remedy','direction'=>'Northeast','purpose'=>'Clarity, devotion, and peaceful study','category'=>'Clarity & Spiritual Growth','price'=>999],['id'=>'vayu-bells','title'=>'Vayu Bells','subtitle'=>'Northwest movement and relationship remedy','direction'=>'Northwest','purpose'=>'Supportive relationships and better flow','category'=>'Relationships & Harmony','price'=>699]],is_array($items)?$items:[]); foreach($items as $r) { try{$this->saveRemedy($r,null);}catch(Throwable){} } }
    private function cleanRemedy(array $b,?string $existing=null): array { $title=trim((string)($b['title']??'')); $id=$existing?:trim((string)($b['id']??preg_replace('/[^a-z0-9]+/','-',strtolower($title))),'-'); return [$id,$title,trim((string)($b['subtitle']??'')),trim((string)($b['direction']??'')),trim((string)($b['purpose']??'')),trim((string)($b['category']??'General Remedies')),(float)($b['price']??0),trim((string)($b['whyYouNeed']??'')),trim((string)($b['howItWorks']??'')),trim((string)($b['whatYouGet']??'')),trim((string)($b['placement']??'')),json_encode(array_values((array)($b['offers']??[]))),json_encode(array_values((array)($b['imageUrls']??[]))),json_encode(array_values((array)($b['videoUrls']??[]))),json_encode(array_values((array)($b['installationImageUrls']??[]))),json_encode(array_values((array)($b['installationVideoUrls']??[])))]; }
    private function saveRemedy(array $b,?string $existing): array { $v=$this->cleanRemedy($b,$existing); if($existing){$this->q('UPDATE remedies SET title=?,subtitle=?,direction=?,purpose=?,category=?,price=?,why_you_need=?,how_it_works=?,what_you_get=?,placement=?,offers=?,image_urls=?,video_urls=?,installation_image_urls=?,installation_video_urls=? WHERE id=?',array_merge(array_slice($v,1),[$existing]));}else{$this->q('INSERT INTO remedies(id,title,subtitle,direction,purpose,category,price,why_you_need,how_it_works,what_you_get,placement,offers,image_urls,video_urls,installation_image_urls,installation_video_urls) VALUES('.implode(',',array_fill(0,16,'?')).')',$v);} return $this->q('SELECT * FROM remedies WHERE id=?',[$v[0]])->fetch(); }
    private function remedyCreate(): void { $this->required(['title','direction','purpose']); $this->json(['remedy'=>$this->publicRemedy($this->saveRemedy($this->body,null))],201); }
    private function remedyItem(string $id): void { if($this->method==='DELETE'){ if(!$this->q('DELETE FROM remedies WHERE id=?',[$id])->rowCount()) $this->json(['error'=>'Remedy not found'],404); $this->json(['ok'=>true]); } if($this->method==='PUT'){ $this->required(['title','direction','purpose']); if(!$this->q('SELECT id FROM remedies WHERE id=?',[$id])->fetch()) $this->json(['error'=>'Remedy not found'],404); $this->json(['remedy'=>$this->publicRemedy($this->saveRemedy($this->body,$id))]); } $this->json(['error'=>'Route not found'],404); }

    private function appUpdate(): array { $r=$this->q('SELECT * FROM app_updates WHERE id=1')->fetch(); if(!$r){$this->q("INSERT INTO app_updates(id,release_notes) VALUES(1,'A new Kubar Vastu app update is available.')");$r=$this->q('SELECT * FROM app_updates WHERE id=1')->fetch();} return ['enabled'=>(bool)$r['enabled'],'latestVersion'=>$r['latest_version'],'latestBuildNumber'=>(int)$r['latest_build_number'],'downloadUrl'=>$r['download_url']??'','releaseNotes'=>$r['release_notes']??'','forceUpdate'=>(bool)$r['force_update'],'updatedAt'=>$this->iso($r['updated_at'])]; }
    private function saveAppUpdate(): void { $version=trim((string)($this->body['latestVersion']??'')); $build=(int)($this->body['latestBuildNumber']??0); if(!$version)$this->json(['error'=>'Latest version is required'],400); if($build<1)$this->json(['error'=>'Latest build number must be at least 1'],400); $this->q('INSERT INTO app_updates(id,enabled,latest_version,latest_build_number,download_url,release_notes,force_update) VALUES(1,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE enabled=VALUES(enabled),latest_version=VALUES(latest_version),latest_build_number=VALUES(latest_build_number),download_url=VALUES(download_url),release_notes=VALUES(release_notes),force_update=VALUES(force_update)',[$this->boolValue($this->body['enabled']??null),$version,$build,trim((string)($this->body['downloadUrl']??'')),trim((string)($this->body['releaseNotes']??'')),$this->boolValue($this->body['forceUpdate']??false,false)]); $this->json(['update'=>$this->appUpdate()]); }

    private function blogs(): void { $page=max(1,(int)($_GET['page']??1));$limit=min(20,max(1,(int)($_GET['limit']??8)));$search=trim((string)($_GET['q']??''));$where='published=1';$p=[];if($search!==''){$where.=' AND (title LIKE ? OR description LIKE ? OR content LIKE ? OR category LIKE ?)';$p=array_fill(0,4,'%'.$search.'%');}$total=(int)$this->q('SELECT COUNT(*) FROM blogs WHERE '.$where,$p)->fetchColumn();$sql='SELECT * FROM blogs WHERE '.$where.' ORDER BY published_at DESC LIMIT '.$limit.' OFFSET '.(($page-1)*$limit);$rows=$this->q($sql,$p)->fetchAll();$this->json(['blogs'=>array_map(fn($r)=>$this->publicBlog($r),$rows),'page'=>$page,'hasMore'=>$page*$limit<$total,'total'=>$total]); }
    private function blogCreate(): void { $this->required(['title','description','content']);$this->q('INSERT INTO blogs(title,description,content,image_url,category,published,published_at) VALUES(?,?,?,?,?,?,?)',[trim((string)$this->body['title']),trim((string)$this->body['description']),trim((string)$this->body['content']),trim((string)($this->body['imageUrl']??'')),trim((string)($this->body['category']??'Vastu')),$this->boolValue($this->body['published']??null),$this->dateInput($this->body['publishedAt']??null)]);$r=$this->q('SELECT * FROM blogs WHERE id=?',[(int)$this->db->lastInsertId()])->fetch();$this->json(['blog'=>$this->publicBlog($r)],201); }
    private function blogItem(int $id): void { if($this->method==='DELETE'){if(!$this->q('DELETE FROM blogs WHERE id=?',[$id])->rowCount())$this->json(['error'=>'Blog not found'],404);$this->json(['ok'=>true]);} if($this->method==='PUT'){$this->required(['title','description','content']);$n=$this->q('UPDATE blogs SET title=?,description=?,content=?,image_url=?,category=?,published=?,published_at=? WHERE id=?',[trim((string)$this->body['title']),trim((string)$this->body['description']),trim((string)$this->body['content']),trim((string)($this->body['imageUrl']??'')),trim((string)($this->body['category']??'Vastu')),$this->boolValue($this->body['published']??null),$this->dateInput($this->body['publishedAt']??null),$id])->rowCount();$r=$this->q('SELECT * FROM blogs WHERE id=?',[$id])->fetch();if(!$r)$this->json(['error'=>'Blog not found'],404);$this->json(['blog'=>$this->publicBlog($r)]);} $this->json(['error'=>'Route not found'],404); }
    private function dateInput(mixed $v): string { return $v ? gmdate('Y-m-d H:i:s',strtotime((string)$v)) : $this->now(); }

    private function deleteAccount(array $user): void {
        if(!password_verify((string)($this->body['password']??''),$user['password_hash'])) $this->json(['error'=>'Incorrect password'],403);
        $this->db->beginTransaction();
        try {
            $this->q('DELETE FROM content_reports WHERE reporter_id=? OR testimonial_id IN (SELECT id FROM testimonials WHERE user_id=?)',[$user['id'],$user['id']]);
            $this->q('DELETE FROM testimonials WHERE user_id=?',[$user['id']]);
            // Sessions, purchases and orders cascade through their user foreign keys.
            $this->q('DELETE FROM users WHERE id=?',[$user['id']]);
            $this->db->commit();
        } catch(Throwable $error) { $this->db->rollBack(); throw $error; }
        $this->json(['deleted'=>true]);
    }

    private function reportTestimonial(int $id, array $user): void {
        $reason=trim((string)($this->body['reason']??''));
        if(strlen($reason)<3 || strlen($reason)>500) $this->json(['error'=>'Provide a reason between 3 and 500 characters'],400);
        if(!$this->q('SELECT id FROM testimonials WHERE id=?',[$id])->fetch()) $this->json(['error'=>'Review not found'],404);
        $this->db->beginTransaction();
        try {
            $this->q('INSERT INTO content_reports(testimonial_id,reporter_id,reason) VALUES(?,?,?) ON DUPLICATE KEY UPDATE reason=VALUES(reason)',[$id,$user['id'],$reason]);
            $this->q("UPDATE testimonials SET status='pending' WHERE id=?",[$id]);
            $this->db->commit();
        } catch(Throwable $error) { $this->db->rollBack(); throw $error; }
        $this->json(['reported'=>true]);
    }

    private function testimonials(): void { $rows=$this->q("SELECT * FROM testimonials WHERE status='approved' ORDER BY created_at DESC LIMIT 30")->fetchAll();$this->json(['testimonials'=>array_map(fn($r)=>$this->publicTestimonial($r),$rows)]); }
    private function testimonialCreate(): void { [$user]=$this->auth(); $this->required(['name','review']);$review=trim((string)$this->body['review']);if(strlen($review)<10||strlen($review)>1200)$this->json(['error'=>'Review must be 10-1200 characters'],400);$rating=max(1,min(5,(int)($this->body['rating']??5)));$this->q('INSERT INTO testimonials(name,profile_image_url,rating,review,user_id) VALUES(?,?,?,?,?)',[trim((string)$this->body['name']),trim((string)($this->body['profileImageUrl']??'')),$rating,$review,$user['id']]);$this->json(['id'=>(string)$this->db->lastInsertId(),'status'=>'pending'],201); }
    private function testimonialStatus(int $id): void { $status=(string)($this->body['status']??'');if(!in_array($status,['pending','approved','rejected'],true))$this->json(['error'=>'Invalid testimonial status'],400);$this->q('UPDATE testimonials SET status=? WHERE id=?',[$status,$id]);$r=$this->q('SELECT * FROM testimonials WHERE id=?',[$id])->fetch();if(!$r)$this->json(['error'=>'Testimonial not found'],404);$this->json(['testimonial'=>$this->publicTestimonial($r),'status'=>$status]); }

    private function youtubeId(mixed $value): string { $s=trim((string)$value); if(preg_match('/^[A-Za-z0-9_-]{11}$/',$s))return $s; $parts=parse_url($s); if(!$parts)return ''; if(str_contains($parts['host']??'','youtu.be'))$candidate=trim($parts['path']??'','/');else{parse_str($parts['query']??'',$q);$candidate=(string)($q['v']??basename($parts['path']??''));} return preg_match('/^[A-Za-z0-9_-]{11}$/',$candidate)?$candidate:''; }
    private function contentVideos(): void { $rows=$this->q('SELECT * FROM videos WHERE published=1 ORDER BY published_at DESC LIMIT 20')->fetchAll(); if($rows){$this->json(['videos'=>array_map(fn($r)=>$this->publicVideo($r),$rows)]);} $key=$this->env('YOUTUBE_API_KEY');$channel=$this->env('YOUTUBE_CHANNEL_ID');if(!$key||!$channel){$ids=array_slice(array_filter(array_map('trim',explode(',',$this->env('YOUTUBE_VIDEO_IDS','ccJZyHd_6EA,dEpKvAtxqEU')))),0,12);$out=[];foreach($ids as $i=>$id)$out[]=['id'=>$id,'title'=>$i===0?'Kubar Vastu Video':'Featured Vastu Video','publishedAt'=>null,'thumbnailUrl'=>'https://img.youtube.com/vi/'.$id.'/hqdefault.jpg'];$this->json(['videos'=>$out]);} $url='https://www.googleapis.com/youtube/v3/search?'.http_build_query(['part'=>'snippet','channelId'=>$channel,'order'=>'date','type'=>'video','maxResults'=>12,'key'=>$key]);$ctx=stream_context_create(['http'=>['timeout'=>8,'header'=>"Accept: application/json\r\n"]]);$raw=@file_get_contents($url,false,$ctx);if($raw===false)$this->json(['error'=>'YouTube service is unavailable'],502);$payload=json_decode($raw,true)?:[];$out=[];foreach($payload['items']??[] as $item){$id=$item['id']['videoId']??'';if(!$id)continue;$sn=$item['snippet']??[];$out[]=['id'=>$id,'title'=>$sn['title']??'Kubar Vastu video','publishedAt'=>$sn['publishedAt']??null,'thumbnailUrl'=>$sn['thumbnails']['high']['url']??$sn['thumbnails']['medium']['url']??$sn['thumbnails']['default']['url']??''];}header('Cache-Control: public, max-age=300, stale-while-revalidate=1800');$this->json(['videos'=>$out]); }
    private function videoCreate(): void { $id=$this->youtubeId($this->body['youtubeUrl']??$this->body['videoId']??'');$title=trim((string)($this->body['title']??''));if(!$id)$this->json(['error'=>'Valid YouTube URL is required'],400);if(!$title)$this->json(['error'=>'Video title is required'],400);$this->q('INSERT INTO videos(video_id,title,thumbnail_url,published) VALUES(?,?,?,?)',[$id,$title,trim((string)($this->body['thumbnailUrl']??'')),$this->boolValue($this->body['published']??null)]);$r=$this->q('SELECT * FROM videos WHERE id=?',[(int)$this->db->lastInsertId()])->fetch();$this->json(['video'=>$this->publicVideo($r)],201); }
    private function videoItem(int $recordId): void { if($this->method==='DELETE'){if(!$this->q('DELETE FROM videos WHERE id=?',[$recordId])->rowCount())$this->json(['error'=>'Video not found'],404);$this->json(['ok'=>true]);}if($this->method==='PUT'){$id=$this->youtubeId($this->body['youtubeUrl']??$this->body['videoId']??'');$title=trim((string)($this->body['title']??''));if(!$id)$this->json(['error'=>'Valid YouTube URL is required'],400);if(!$title)$this->json(['error'=>'Video title is required'],400);$this->q('UPDATE videos SET video_id=?,title=?,thumbnail_url=?,published=? WHERE id=?',[$id,$title,trim((string)($this->body['thumbnailUrl']??'')),$this->boolValue($this->body['published']??null),$recordId]);$r=$this->q('SELECT * FROM videos WHERE id=?',[$recordId])->fetch();if(!$r)$this->json(['error'=>'Video not found'],404);$this->json(['video'=>$this->publicVideo($r)]);} $this->json(['error'=>'Route not found'],404); }

    private function userSave(): void { $this->required(['name','email']);$email=strtolower(trim((string)$this->body['email']));if(!filter_var($email,FILTER_VALIDATE_EMAIL))$this->json(['error'=>'Enter a valid email address'],400);$username=strtolower(trim((string)($this->body['username']??'')));if($username){$taken=$this->q('SELECT id FROM users WHERE username=? AND email<>?',[$username,$email])->fetch();if($taken)$this->json(['error'=>'Username already registered'],409);} $old=$this->q('SELECT * FROM users WHERE email=?',[$email])->fetch();if($old){$this->q('UPDATE users SET name=?,gender=?,phone=?,place=?,user_type=?,username=? WHERE id=?',[trim((string)$this->body['name']),trim((string)($this->body['gender']??'')),trim((string)($this->body['phone']??'')),trim((string)($this->body['place']??'')),trim((string)($this->body['userType']??'')),$username?:null,$old['id']]);$id=$old['id'];}else{$password=(string)($this->body['password']??bin2hex(random_bytes(12)));$this->q('INSERT INTO users(name,email,gender,phone,place,user_type,username,password_hash) VALUES(?,?,?,?,?,?,?,?)',[trim((string)$this->body['name']),$email,trim((string)($this->body['gender']??'')),trim((string)($this->body['phone']??'')),trim((string)($this->body['place']??'')),trim((string)($this->body['userType']??'')),$username?:null,password_hash($password,PASSWORD_DEFAULT)]);$id=$this->db->lastInsertId();}$u=$this->q('SELECT * FROM users WHERE id=?',[$id])->fetch();$this->json(['user'=>$this->publicUser($u)],201); }
    private function userGet(): void { $email=strtolower(trim((string)($_GET['email']??'')));$u=$this->q('SELECT * FROM users WHERE email=?',[$email])->fetch();if(!$u)$this->json(['error'=>'User not found'],404);$this->json(['user'=>$this->publicUser($u)]); }
    private function findOrderUser(): ?array { $u=$this->optionalUser();if($u)return $u;$email=strtolower(trim((string)($this->body['email']??$_GET['email']??'')));return $email?$this->q('SELECT * FROM users WHERE email=?',[$email])->fetch()?:null:null; }
    private function orderCreate(): void { $this->required(['remedyId']);$u=$this->findOrderUser();if(!$u)$this->json(['error'=>'Login before purchasing remedies'],401);$r=$this->q('SELECT * FROM remedies WHERE id=?',[(string)$this->body['remedyId']])->fetch();if(!$r)$this->json(['error'=>'Remedy not found'],404);$this->q("INSERT INTO orders(user_id,remedy_id,remedy_name,quantity,unit_price,price,status) VALUES(?,?,?,?,?,?,'created')",[$u['id'],$r['id'],$r['title'],1,$r['price'],$r['price']]);$o=$this->q('SELECT * FROM orders WHERE id=?',[(int)$this->db->lastInsertId()])->fetch();$this->json(['order'=>$this->publicOrder($o)],201); }
    private function ordersGet(): void { $email=strtolower(trim((string)($_GET['email']??'')));$u=$this->q('SELECT * FROM users WHERE email=?',[$email])->fetch();if(!$u)$this->json(['error'=>'User not found'],404);$rows=$this->q('SELECT * FROM orders WHERE user_id=? ORDER BY purchased_at DESC',[$u['id']])->fetchAll();$this->json(['orders'=>array_map(fn($r)=>$this->publicOrder($r),$rows)]); }

    private function razorpayConfigured(): bool { return $this->env('RAZORPAY_KEY_ID')!==''&&$this->env('RAZORPAY_KEY_SECRET')!==''; }
    private function paymentCreate(array $u): void {
        if(!$this->razorpayConfigured())$this->json(['error'=>'Razorpay test keys are not configured'],503);
        $shipping=[];
        $inputShipping=is_array($this->body['shipping']??null)?$this->body['shipping']:[];
        foreach(['name','phone','address','city','state','pincode'] as $key)$shipping[$key]=trim((string)($inputShipping[$key]??''));
        if(in_array('', $shipping, true)||array_filter($shipping,fn($v)=>strlen($v)>250)||!preg_match('/^[0-9+() -]{10,16}$/',$shipping['phone'])||!preg_match('/^\d{6}$/',$shipping['pincode']))$this->json(['error'=>'Valid shipping details are required'],400);
        $items=$this->body['items']??[];
        if(!is_array($items)||!$items)$this->json(['error'=>'Cart is empty'],400);
        $purchaseItems=[];$total=0;
        foreach($items as $item){$r=$this->q('SELECT * FROM remedies WHERE id=?',[trim((string)($item['remedyId']??''))])->fetch();if(!$r)$this->json(['error'=>'A cart remedy is unavailable'],404);$quantity=max(1,min(20,(int)($item['quantity']??1)));$purchaseItems[]=['remedyId'=>$r['id'],'remedyName'=>$r['title'],'quantity'=>$quantity,'unitPrice'=>(float)$r['price']];$total+=(float)$r['price']*$quantity;}
        if($total<1)$this->json(['error'=>'Payment total is invalid'],400);
        $receipt='kv_'.round(microtime(true)*1000).'_'.bin2hex(random_bytes(3));
        $payload=json_encode(['amount'=>(int)round($total*100),'currency'=>'INR','receipt'=>$receipt,'notes'=>['userId'=>(string)$u['id']]]);
        $ch=curl_init('https://api.razorpay.com/v1/orders');curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>$payload,CURLOPT_HTTPHEADER=>['Content-Type: application/json'],CURLOPT_USERPWD=>$this->env('RAZORPAY_KEY_ID').':'.$this->env('RAZORPAY_KEY_SECRET'),CURLOPT_TIMEOUT=>10]);
        $raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);curl_close($ch);$rp=json_decode((string)$raw,true)?:[];
        if($status<200||$status>=300||empty($rp['id']))$this->json(['error'=>'Unable to start Razorpay payment'],502);
        $token=bin2hex(random_bytes(32));
        $this->q('INSERT INTO purchases(user_id,items,total,checkout_token_hash,razorpay_order_id,shipping) VALUES(?,?,?,?,?,?)',[$u['id'],json_encode($purchaseItems),$total,hash('sha256',$token),$rp['id'],json_encode($shipping)]);
        $purchaseId=(string)$this->db->lastInsertId();$return='';$candidate=trim((string)($this->body['returnUrl']??''));
        if(filter_var($candidate,FILTER_VALIDATE_URL)&&in_array(parse_url($candidate,PHP_URL_SCHEME),['http','https'],true))$return='?returnUrl='.rawurlencode($candidate);
        $this->json(['purchaseId'=>$purchaseId,'checkoutUrl'=>$this->origin().'/payment/'.$token.$return,'amount'=>$total,'currency'=>'INR','status'=>'pending'],201);
    }
    private function paymentStatus(int $id,array $u): void { $p=$this->q('SELECT * FROM purchases WHERE id=? AND user_id=?',[$id,$u['id']])->fetch();if(!$p)$this->json(['error'=>'Purchase not found'],404);$orders=$p['status']==='paid'?$this->q('SELECT * FROM orders WHERE user_id=? AND payment_id=?',[$u['id'],$p['razorpay_payment_id']])->fetchAll():[];$this->json(['status'=>$p['status'],'total'=>(float)$p['total'],'validityEndsAt'=>$this->iso($p['validity_ends_at']),'orders'=>array_map(fn($r)=>$this->publicOrder($r),$orders)]); }
    private function paymentPage(string $token): never
    {
        $p = $this->q(
            'SELECT p.*,u.name,u.email,u.phone FROM purchases p JOIN users u ON u.id=p.user_id WHERE p.checkout_token_hash=?',
            [hash('sha256', $token)],
        )->fetch();
        if (!$p) {
            http_response_code(404);
            exit('Payment link is invalid.');
        }

        $return = trim((string)($_GET['returnUrl'] ?? ''));
        if (!(filter_var($return, FILTER_VALIDATE_URL)
            && in_array(parse_url($return, PHP_URL_SCHEME), ['http', 'https'], true))) {
            $return = $this->env(
                'PAYMENT_RETURN_URL',
                'https://kubervastu.com/?payment=success',
            );
        }
        if ($p['status'] === 'paid') {
            header('Location: ' . $return, true, 303);
            exit;
        }

        $options = [
            'key' => $this->env('RAZORPAY_KEY_ID'),
            'amount' => (int)round((float)$p['total'] * 100),
            'currency' => 'INR',
            'name' => 'Kubar Vastu',
            'description' => 'One-year remedy purchase',
            'order_id' => $p['razorpay_order_id'],
            'prefill' => [
                'name' => $p['name'],
                'email' => $p['email'],
                'contact' => $p['phone'] ?? '',
            ],
            'theme' => ['color' => '#9b7428'],
            'modal' => ['confirm_close' => true],
        ];

        header('Content-Type: text/html; charset=utf-8');
        $o = json_encode($options, JSON_UNESCAPED_SLASHES);
        $ret = json_encode($return, JSON_UNESCAPED_SLASHES);
        $tok = json_encode($token);
        $amount = htmlspecialchars((string)$p['total']);
        echo '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>Kubar Vastu Payment</title><script src="https://checkout.razorpay.com/v1/checkout.js"></script><style>body{font-family:system-ui;background:#f5eedd;margin:0;display:grid;place-items:center;min-height:100vh;color:#2a2117}.card{width:min(420px,calc(100% - 32px));background:#fffaf0;border:1px solid #d8bd82;border-radius:18px;padding:26px;text-align:center}button{width:100%;padding:14px;border:0;border-radius:10px;background:#9b7428;color:white;font-weight:800}button:disabled{opacity:.6}.error{color:#b42318}</style></head><body><main class="card"><h1>Kubar Vastu</h1><p>One-year remedy validity</p><h2>₹'.$amount.'</h2><p id="status"></p><button id="pay">Pay Now</button></main><script>const options='.$o.',returnUrl='.$ret.',token='.$tok.',statusElement=document.querySelector("#status"),payButton=document.querySelector("#pay");const verifyPath=location.pathname.replace(/\/payment\/[^/]+\/?$/,"/api/payments/verify/"+encodeURIComponent(token));const verifyUrl=location.origin+verifyPath;options.handler=async result=>{statusElement.className="";statusElement.textContent="Verifying payment...";payButton.disabled=true;try{const response=await fetch(verifyUrl,{method:"POST",headers:{"Content-Type":"application/json","Accept":"application/json"},body:JSON.stringify(result)});const raw=await response.text();let data={};try{data=raw?JSON.parse(raw):{}}catch(_){throw new Error("Payment server returned an invalid response.")}if(!response.ok)throw new Error(data.error||"Payment verification failed.");statusElement.textContent="Payment successful. Redirecting...";payButton.style.display="none";window.location.replace(returnUrl);}catch(error){statusElement.className="error";statusElement.textContent=error.message||"Payment verification failed. Please try again.";payButton.disabled=false;}};payButton.onclick=()=>new Razorpay(options).open();</script></body></html>';
        exit;
    }
    private function sendPurchaseNotification(array $purchase,string $paymentId,string $paidAt): bool
    {
        $to=trim($this->env('PURCHASE_MAIL_TO',$this->env('ADMIN_EMAIL','kubervastu153@gmail.com')));
        $from=trim($this->env('MAIL_FROM',$this->env('SMTP_USER','orders@kubervastu.com')));
        if(!filter_var($to,FILTER_VALIDATE_EMAIL)||!filter_var($from,FILTER_VALIDATE_EMAIL)){
            error_log('Purchase email skipped: PURCHASE_MAIL_TO or MAIL_FROM is invalid.');
            return false;
        }
        $customer=$this->q('SELECT name,email,phone,place FROM users WHERE id=?',[$purchase['user_id']])->fetch()?:[];
        $items=json_decode((string)$purchase['items'],true)?:[];
        $shipping=json_decode((string)($purchase['shipping']??''),true)?:null;
        $lines=[
            'A new Kuber Vastu remedy order has been paid.',
            '',
            'Purchase ID: '.(string)$purchase['id'],
            'Payment ID: '.$paymentId,
            'Customer: '.($customer['name']??'Unknown'),
            'Email: '.($customer['email']??'Not provided'),
            'Phone: '.($customer['phone']??'Not provided'),
            'Place: '.($customer['place']??'Not provided'),
            ...($shipping ? [
                'Ship to: '.($shipping['name']??''),
                'Shipping phone: '.($shipping['phone']??''),
                'Shipping address: '.($shipping['address']??'').', '.($shipping['city']??'').', '.($shipping['state']??'').' - '.($shipping['pincode']??''),
            ] : []),
            '',
            'Order details:',
        ];
        foreach($items as $index=>$item){
            $quantity=max(1,(int)($item['quantity']??1));
            $unitPrice=(float)($item['unitPrice']??0);
            $lines[]=($index+1).'. '.($item['remedyName']??'Remedy').' x '.$quantity.' - INR '.number_format($unitPrice*$quantity,2,'.','');
        }
        $lines[]='';
        $lines[]='Total: INR '.number_format((float)$purchase['total'],2,'.','');
        $lines[]='Paid at: '.gmdate('d M Y, h:i A',strtotime($paidAt)).' UTC';
        $subject='New Kuber Vastu order - INR '.number_format((float)$purchase['total'],2,'.','');
        $headers=[
            'From: Kuber Vastu Orders <'.$from.'>',
            'Reply-To: '.(filter_var($customer['email']??'',FILTER_VALIDATE_EMAIL)?$customer['email']:$from),
            'Content-Type: text/plain; charset=UTF-8',
            'X-Mailer: PHP/'.PHP_VERSION,
        ];
        $message=implode("\r\n",$lines);
        $sent=false;
        if($this->env('SMTP_HOST')!==''&&$this->env('SMTP_USER')!==''&&$this->env('SMTP_PASSWORD')!==''){
            try{
                $sent=$this->sendSmtpMail($to,$from,$subject,$message,$headers);
            }catch(Throwable $e){
                error_log('Purchase SMTP email error: '.$e->getMessage());
            }
        }
        if(!$sent){
            $sent=mail($to,$subject,$message,implode("\r\n",$headers));
        }
        if(!$sent)error_log('Purchase email failed for purchase '.$purchase['id'].' and payment '.$paymentId.'.');
        return $sent;
    }

    private function sendSmtpMail(string $to,string $from,string $subject,string $message,array $headers): bool
    {
        $host=trim($this->env('SMTP_HOST'));
        $port=max(1,(int)$this->env('SMTP_PORT','465'));
        $encryption=strtolower(trim($this->env('SMTP_ENCRYPTION','ssl')));
        $remote=($encryption==='ssl'?'ssl://':'').$host.':'.$port;
        $socket=@stream_socket_client($remote,$errorNumber,$errorMessage,15,STREAM_CLIENT_CONNECT);
        if(!is_resource($socket))throw new \RuntimeException('SMTP connection failed: '.$errorMessage.' ('.$errorNumber.')');
        stream_set_timeout($socket,15);
        try{
            $this->expectSmtp($socket,[220]);
            $hostname=preg_replace('/[^A-Za-z0-9.-]/','',gethostname()?:'kubervastu.com')?:'kubervastu.com';
            $this->writeSmtp($socket,'EHLO '.$hostname,[250]);
            if($encryption==='tls'){
                $this->writeSmtp($socket,'STARTTLS',[220]);
                if(!stream_socket_enable_crypto($socket,true,STREAM_CRYPTO_METHOD_TLS_CLIENT))throw new \RuntimeException('SMTP TLS negotiation failed');
                $this->writeSmtp($socket,'EHLO '.$hostname,[250]);
            }
            $this->writeSmtp($socket,'AUTH LOGIN',[334]);
            $this->writeSmtp($socket,base64_encode($this->env('SMTP_USER')),[334]);
            $this->writeSmtp($socket,base64_encode($this->env('SMTP_PASSWORD')),[235]);
            $this->writeSmtp($socket,'MAIL FROM:<'.$from.'>',[250]);
            $this->writeSmtp($socket,'RCPT TO:<'.$to.'>',[250,251]);
            $this->writeSmtp($socket,'DATA',[354]);
            $encodedSubject='=?UTF-8?B?'.base64_encode($subject).'?=';
            $payload='To: '.$to."\r\n".'Subject: '.$encodedSubject."\r\n".implode("\r\n",$headers)."\r\n\r\n".$message;
            $payload=preg_replace('/(?m)^\./','..',$payload)??$payload;
            fwrite($socket,$payload."\r\n.\r\n");
            $this->expectSmtp($socket,[250]);
            $this->writeSmtp($socket,'QUIT',[221]);
            return true;
        }finally{
            fclose($socket);
        }
    }

    /** @param resource $socket */
    private function writeSmtp($socket,string $command,array $expected): void
    {
        if(fwrite($socket,$command."\r\n")===false)throw new \RuntimeException('Could not write to SMTP server');
        $this->expectSmtp($socket,$expected);
    }

    /** @param resource $socket */
    private function expectSmtp($socket,array $expected): void
    {
        $response='';
        do{
            $line=fgets($socket,1024);
            if($line===false)throw new \RuntimeException('SMTP server closed the connection');
            $response.=$line;
        }while(strlen($line)>=4&&$line[3]==='-');
        $code=(int)substr($response,0,3);
        if(!in_array($code,$expected,true))throw new \RuntimeException('SMTP rejected the message: '.trim($response));
    }

    private function paymentVerify(string $token): void {
        $p=$this->q('SELECT * FROM purchases WHERE checkout_token_hash=?',[hash('sha256',$token)])->fetch();
        if(!$p)$this->json(['error'=>'Purchase not found'],404);
        if($p['status']==='paid')$this->json(['ok'=>true,'status'=>'paid']);
        $paymentId=(string)($this->body['razorpay_payment_id']??'');$signature=(string)($this->body['razorpay_signature']??'');
        if(!$paymentId||!$signature)$this->json(['error'=>'Missing payment verification data'],400);
        $expected=hash_hmac('sha256',$p['razorpay_order_id'].'|'.$paymentId,$this->env('RAZORPAY_KEY_SECRET'));
        if(!hash_equals($expected,$signature))$this->json(['error'=>'Payment signature is invalid'],400);
        $paid=$this->now();$valid=gmdate('Y-m-d H:i:s',strtotime('+1 year'));
        $this->db->beginTransaction();
        try{
            if(!(int)$this->q('SELECT COUNT(*) FROM orders WHERE payment_id=?',[$paymentId])->fetchColumn()){
                foreach(json_decode($p['items'],true)?:[] as $i){
                    $this->q("INSERT INTO orders(user_id,remedy_id,remedy_name,quantity,unit_price,price,status,purchased_at,validity_starts_at,validity_ends_at,payment_id,shipping) VALUES(?,?,?,?,?,?,'paid',?,?,?,?,?)",[$p['user_id'],$i['remedyId'],$i['remedyName'],$i['quantity'],$i['unitPrice'],$i['unitPrice']*$i['quantity'],$paid,$paid,$valid,$paymentId,$p['shipping']]);
                }
            }
            $this->q("UPDATE purchases SET status='paid',razorpay_payment_id=?,paid_at=?,validity_ends_at=? WHERE id=?",[$paymentId,$paid,$valid,$p['id']]);
            $this->db->commit();
        }catch(Throwable $e){$this->db->rollBack();throw $e;}
        try{$this->sendPurchaseNotification($p,$paymentId,$paid);}catch(Throwable $e){error_log('Purchase email error: '.$e->getMessage());}
        $this->json(['ok'=>true,'status'=>'paid','validityEndsAt'=>$this->iso($valid)]);
    }

    private function overview(): void { $this->seedRemedies();$users=$this->q('SELECT * FROM users ORDER BY created_at DESC')->fetchAll();$remedies=$this->q('SELECT * FROM remedies ORDER BY created_at DESC')->fetchAll();$orders=$this->q('SELECT * FROM orders ORDER BY purchased_at DESC')->fetchAll();$blogs=$this->q('SELECT * FROM blogs ORDER BY published_at DESC')->fetchAll();$testimonials=$this->q('SELECT * FROM testimonials ORDER BY created_at DESC')->fetchAll();$reports=$this->q('SELECT testimonial_id,reason,created_at FROM content_reports ORDER BY created_at ASC')->fetchAll();$reportMap=[];foreach($reports as $report)$reportMap[(string)$report['testimonial_id']][]=['reason'=>$report['reason'],'createdAt'=>$this->iso($report['created_at'])];$videos=$this->q('SELECT * FROM videos ORDER BY published_at DESC')->fetchAll();$publicOrders=array_map(fn($r)=>$this->publicOrder($r),$orders);$this->json(['users'=>array_map(fn($r)=>$this->publicUser($r),$users),'remedies'=>array_map(fn($r)=>$this->publicRemedy($r),$remedies),'orders'=>$publicOrders,'payments'=>$publicOrders,'appUpdate'=>$this->appUpdate(),'blogs'=>array_map(fn($r)=>$this->publicBlog($r),$blogs),'testimonials'=>array_map(fn($r)=>$this->publicTestimonial($r)+['reports'=>$reportMap[(string)$r['id']]??[]],$testimonials),'videos'=>array_map(fn($r)=>$this->publicVideo($r),$videos),'stats'=>['users'=>count($users),'remedies'=>count($remedies),'orders'=>count($orders),'paymentsTotal'=>array_sum(array_map(fn($r)=>(float)$r['price'],$orders)),'blogs'=>count($blogs),'pendingReviews'=>count(array_filter($testimonials,fn($r)=>$r['status']==='pending')),'videos'=>count($videos)]]); }
}
