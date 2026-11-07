$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$env:APP_ENV = 'development'
$env:APP_URL = 'http://127.0.0.1:4001'
$env:DB_HOST = '127.0.0.1'
$env:DB_PORT = '3307'
$env:DB_NAME = 'kubar_vastu_review_local'
$env:DB_USER = 'root'
$env:DB_PASSWORD = ''
$env:AUTO_MIGRATE = 'true'
$env:APP_KEY = 'local-review-preview-only'
$env:ADMIN_EMAIL = 'review-admin@example.com'
$env:ADMIN_PASSWORD = 'LocalReviewAdmin2026!'
# Preview never uses payment, email or YouTube API credentials from .env.
$env:RAZORPAY_KEY_ID = ''
$env:RAZORPAY_KEY_SECRET = ''
$env:SMTP_HOST = ''
$env:SMTP_USER = ''
$env:SMTP_PASSWORD = ''
$env:YOUTUBE_API_KEY = ''
$env:YOUTUBE_CHANNEL_ID = ''
$env:YOUTUBE_VIDEO_IDS = ''
$phpExecutable = 'C:\xampp\php\php.exe'
if (-not (Test-Path -LiteralPath $phpExecutable)) { throw 'Install XAMPP PHP first.' }
$runtimeRoot = Join-Path $projectRoot '.review-preview'
$dbDirectory = Join-Path $runtimeRoot 'mysql'
New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $dbDirectory 'mysql'))) {
    & 'C:\xampp\mysql\bin\mysql_install_db.exe' "--datadir=$dbDirectory" --port=3307
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the isolated preview database.' }
}
$databaseReady = $false
try { $connection = New-Object System.Net.Sockets.TcpClient('127.0.0.1',3307); $connection.Dispose(); $databaseReady = $true } catch {}
if (-not $databaseReady) {
    Start-Process -FilePath 'C:\xampp\mysql\bin\mysqld.exe' -ArgumentList '--no-defaults', '--basedir=C:\xampp\mysql', ('--datadir="' + $dbDirectory + '"'), '--port=3307', '--bind-address=127.0.0.1', '--console' -WindowStyle Hidden -RedirectStandardOutput (Join-Path $runtimeRoot 'mysql.out.log') -RedirectStandardError (Join-Path $runtimeRoot 'mysql.err.log') | Out-Null
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try { $connection = New-Object System.Net.Sockets.TcpClient('127.0.0.1',3307); $connection.Dispose(); $databaseReady = $true; break } catch { Start-Sleep -Milliseconds 500 }
    }
}
if (-not $databaseReady) { throw 'Preview database did not start. Check .review-preview/mysql.err.log.' }
if ($args -contains '-BackendOnly') {
    & $phpExecutable -S 127.0.0.1:4001 -t backend-php/public backend-php/router.php
    exit $LASTEXITCODE
}
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) { throw 'Flutter is not available on PATH.' }
$backendProcess = Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'), '-BackendOnly' -WindowStyle Hidden -PassThru
try {
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try { $health = Invoke-RestMethod 'http://127.0.0.1:4001/health'; $ready = $health.ok; if ($ready) { break } } catch { Start-Sleep -Milliseconds 500 }
    }
    if (-not $ready) { throw 'The local backend could not start.' }
    & $phpExecutable backend-php/seed-review-preview.php
    if ($LASTEXITCODE -ne 0) { throw 'Could not prepare review demo accounts.' }
    Write-Host 'Preview: http://localhost:8081'
    Write-Host 'Profile login: reviewdemo / LocalReview2026!'
    Write-Host 'Local admin: http://127.0.0.1:4001/admin/'
    Write-Host 'Admin login: review-admin@example.com / LocalReviewAdmin2026!'
    & $flutterCommand.Source run -d web-server --web-hostname localhost --web-port 8081 --dart-define=BACKEND_URL=http://127.0.0.1:4001
} finally {
    if (-not $backendProcess.HasExited) { Stop-Process -Id $backendProcess.Id }
}
