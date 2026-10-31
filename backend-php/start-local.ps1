$ErrorActionPreference = 'Stop'
$backendRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $backendRoot '.env'))) {
  Copy-Item -LiteralPath (Join-Path $backendRoot '.env.example') -Destination (Join-Path $backendRoot '.env')
  Write-Host 'Created backend-php/.env. Update the MySQL credentials if needed.'
}
$phpCommand = Get-Command php -ErrorAction SilentlyContinue
$phpExecutable = if ($phpCommand) { $phpCommand.Source } elseif (Test-Path 'C:\xampp\php\php.exe') { 'C:\xampp\php\php.exe' } else { throw 'PHP 8.0+ was not found. Install PHP or XAMPP first.' }
& $phpExecutable -S 0.0.0.0:4000 -t (Join-Path $backendRoot 'public') (Join-Path $backendRoot 'router.php')
