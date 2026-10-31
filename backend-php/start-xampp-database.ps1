$ErrorActionPreference = 'Stop'
$mysqlExecutable = 'C:\xampp\mysql\bin\mysqld.exe'
$mysqlConfig = 'C:\xampp\mysql\bin\my.ini'
if (-not (Test-Path -LiteralPath $mysqlExecutable)) { throw 'XAMPP MariaDB was not found.' }
$listener = Get-NetTCPConnection -LocalPort 3307 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
  Write-Host 'Kubar Vastu database is already running on port 3307.'
  exit 0
}
Start-Process -FilePath $mysqlExecutable -ArgumentList "--defaults-file=$mysqlConfig", '--port=3307', '--console' -WindowStyle Hidden
Start-Sleep -Seconds 2
$listener = Get-NetTCPConnection -LocalPort 3307 -State Listen -ErrorAction SilentlyContinue
if (-not $listener) { throw 'MariaDB did not start. Check C:\xampp\mysql\data\mysql_error.log.' }
Write-Host 'Kubar Vastu database started on port 3307.'

