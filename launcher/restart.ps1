# MultiGames Restart — перезапуск сервера и клиента (применяет изменения в коде)
# Запускать из корня: .\launcher\restart.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
if ((Split-Path -Leaf $ProjectRoot) -eq "launcher") {
    $ProjectRoot = Split-Path -Parent $ProjectRoot
}

Write-Host 'MultiGames Restart' -ForegroundColor Cyan
Write-Host ""

# Завершить процесс, слушающий порт 8080 (Go-сервер)
$conn = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($conn) {
    $serverPid = $conn.OwningProcess
    Write-Host "Stopping server (PID $serverPid) on port 8080..." -ForegroundColor Yellow
    Stop-Process -Id $serverPid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
} else {
    Write-Host 'No server on port 8080.' -ForegroundColor Gray
}

Write-Host 'Starting server and client...' -ForegroundColor Yellow
& (Join-Path $PSScriptRoot "start.ps1")
