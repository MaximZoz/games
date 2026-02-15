# MultiGames Launcher — запуск тестов (Go + Flutter)
# Запускать из корня: .\launcher\test.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
if ((Split-Path -Leaf $ProjectRoot) -eq "launcher") {
    $ProjectRoot = Split-Path -Parent $ProjectRoot
}
Set-Location $ProjectRoot

Write-Host 'MultiGames Tests' -ForegroundColor Cyan
Write-Host ""

$failed = $false

Write-Host 'Go tests...' -ForegroundColor Yellow
Push-Location (Join-Path $ProjectRoot "server")
try {
    go test ./...
    if ($LASTEXITCODE -ne 0) { $failed = $true }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host 'Flutter tests...' -ForegroundColor Yellow
Push-Location (Join-Path $ProjectRoot "client")
try {
    if (Test-Path "test") {
        flutter test --no-pub
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    } else {
        Write-Host 'No test directory, skipping Flutter tests.' -ForegroundColor Gray
    }
} finally {
    Pop-Location
}

Write-Host ""
if ($failed) {
    Write-Host 'Some tests failed.' -ForegroundColor Red
    exit 1
}
Write-Host 'All tests passed.' -ForegroundColor Green
exit 0
