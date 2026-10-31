$ErrorActionPreference = 'Stop'

$backendRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$databasePath = Join-Path $backendRoot 'data\mongodb'
$mongoLogPath = Join-Path $backendRoot 'data\mongodb.log'
$backendLogPath = Join-Path $backendRoot 'data\backend.log'
$backendErrorPath = Join-Path $backendRoot 'data\backend-error.log'
$mongoExecutable = 'C:\Program Files\MongoDB\Server\6.0\bin\mongod.exe'
$nodeExecutable = 'C:\Program Files\nodejs\node.exe'

New-Item -ItemType Directory -Force -Path $databasePath | Out-Null

$mongoListening = Get-NetTCPConnection `
  -LocalPort 27017 `
  -State Listen `
  -ErrorAction SilentlyContinue
if (-not $mongoListening) {
  Start-Process `
    -FilePath $mongoExecutable `
    -ArgumentList @(
      '--dbpath', $databasePath,
      '--bind_ip', '127.0.0.1',
      '--port', '27017',
      '--logpath', $mongoLogPath,
      '--logappend'
    ) `
    -WorkingDirectory $backendRoot `
    -WindowStyle Hidden
}

$databaseReady = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
  if (Get-NetTCPConnection -LocalPort 27017 -State Listen -ErrorAction SilentlyContinue) {
    $databaseReady = $true
    break
  }
  Start-Sleep -Milliseconds 500
}
if (-not $databaseReady) {
  throw 'MongoDB did not start on port 27017.'
}

$apiListening = Get-NetTCPConnection `
  -LocalPort 4000 `
  -State Listen `
  -ErrorAction SilentlyContinue
if (-not $apiListening) {
  $env:MONGODB_URI = 'mongodb://127.0.0.1:27017/divinewall'
  $env:PORT = '4000'
  Start-Process `
    -FilePath $nodeExecutable `
    -ArgumentList 'server.js' `
    -WorkingDirectory $backendRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $backendLogPath `
    -RedirectStandardError $backendErrorPath
}

$apiReady = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
  try {
    $health = Invoke-RestMethod -Uri 'http://localhost:4000/health' -TimeoutSec 2
    if ($health.ok) {
      $apiReady = $true
      break
    }
  } catch {
    Start-Sleep -Milliseconds 500
  }
}
if (-not $apiReady) {
  throw 'Kubar Vastu API did not start on port 4000.'
}

Write-Host 'Kubar Vastu database and API are ready.'
Write-Host 'API:   http://localhost:4000'
Write-Host 'Admin: http://localhost:4000/admin'
