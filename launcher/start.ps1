# MultiGames Launcher — запуск клиента и сервера (Windows)
# Запускать из корня проекта: .\launcher\start.ps1
# Или из папки launcher: .\start.ps1 (скрипт сам найдёт корень)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
if ((Split-Path -Leaf $ProjectRoot) -eq "launcher") {
    $ProjectRoot = Split-Path -Parent $ProjectRoot
}
Set-Location $ProjectRoot

Write-Host 'MultiGames Launcher' -ForegroundColor Cyan
Write-Host ('Koren proekta: ' + $ProjectRoot) -ForegroundColor Gray
Write-Host ""

# Запуск сервера в новом окне
Write-Host 'Zapusk servera (Go)...' -ForegroundColor Yellow
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Write-Host 'MultiGames Server' -ForegroundColor Green; go run ./cmd/server"
) -WorkingDirectory (Join-Path $ProjectRoot "server")

# Небольшая пауза, чтобы сервер успел подняться
Start-Sleep -Seconds 2

# Запуск клиента в новом окне (Web по умолчанию)
Write-Host 'Zapusk klienta (Flutter Web)...' -ForegroundColor Yellow
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "Write-Host 'MultiGames Client' -ForegroundColor Green; flutter run -d chrome"
) -WorkingDirectory (Join-Path $ProjectRoot "client")

Write-Host ""
Write-Host 'Done. Two windows opened: server and client.' -ForegroundColor Green
Write-Host 'Zakroyte okna ili Ctrl+C v kazhdom dlya ostanovki.' -ForegroundColor Gray
