# Сидирует DEV Postgres: admin + player1..player20. Только DEV.
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$EnvFile = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { Join-Path $RootDir "deploy.dev.env" }

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) { return }
        $name, $value = $line -split "=", 2
        if ($name -and $null -ne $value) {
            $value = $value.Trim('"')
            Set-Item -Path "Env:$name" -Value $value
        }
    }
}

if ([string]::IsNullOrWhiteSpace($env:FLY_APP_NAME)) { $env:FLY_APP_NAME = "multigameszozu-dev" }
if ([string]::IsNullOrWhiteSpace($env:FLY_DEV_DB_NAME)) { $env:FLY_DEV_DB_NAME = "multigameszozu-dev-db" }
if ([string]::IsNullOrWhiteSpace($env:FLY_DEV_DB_DATABASE)) { $env:FLY_DEV_DB_DATABASE = "multigameszozu_dev" }

if ($env:FLY_APP_NAME -eq "multigameszozu") {
    Write-Error "Отказ: скрипт только для DEV"
}

$flyBin = $null
if (Get-Command fly -ErrorAction SilentlyContinue) { $flyBin = "fly" }
elseif (Get-Command flyctl -ErrorAction SilentlyContinue) { $flyBin = "flyctl" }
elseif (Test-Path "$env:USERPROFILE\.fly\bin\flyctl.exe") { $flyBin = "$env:USERPROFILE\.fly\bin\flyctl.exe" }
else { Write-Error "Не найден fly/flyctl" }

$SqlFile = [System.IO.Path]::GetTempFileName()
try {
    Write-Host "Генерирую SQL (bcrypt)..."
    Push-Location (Join-Path $RootDir "server")
    try {
        go run ./cmd/seed_dev_users | Set-Content -Path $SqlFile -Encoding utf8
    } finally {
        Pop-Location
    }

    Write-Host "Применяю к Postgres DEV: $($env:FLY_DEV_DB_NAME)"
    Get-Content $SqlFile | & $flyBin postgres connect --app $env:FLY_DEV_DB_NAME --database $env:FLY_DEV_DB_DATABASE
} finally {
    Remove-Item $SqlFile -ErrorAction SilentlyContinue
}

Write-Host "Готово. Логин: https://$($env:FLY_APP_NAME).fly.dev/login"
Write-Host "player1@player.com / player1 ... player20@player.com / player20"
