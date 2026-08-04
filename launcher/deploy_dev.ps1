# Деплой текущего кода в Fly DEV.
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$EnvFile = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { Join-Path $RootDir "deploy.dev.env" }
$FlyConfig = Join-Path $RootDir "fly.dev.toml"

if (-not (Test-Path $EnvFile)) {
    Write-Error "Файл конфигурации не найден: $EnvFile`nСоздай его из шаблона: cp deploy.dev.env.example deploy.dev.env"
}
if (-not (Test-Path $FlyConfig)) {
    Write-Error "Не найден $FlyConfig"
}

Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    $name, $value = $line -split "=", 2
    if ($name -and $null -ne $value) {
        Set-Item -Path "Env:$name" -Value $value
    }
}

$requiredVars = @("FLY_API_TOKEN", "FLY_APP_NAME", "JWT_SECRET", "ADMIN_INIT_SECRET")
foreach ($varName in $requiredVars) {
    $val = [Environment]::GetEnvironmentVariable($varName)
    if ([string]::IsNullOrWhiteSpace($val)) {
        Write-Error "Не задана обязательная переменная: $varName"
    }
}

if ($env:FLY_APP_NAME -eq "multigameszozu") {
    Write-Error "Отказ: FLY_APP_NAME указывает на прод. Для DEV используй multigameszozu-dev."
}

$flyBin = $null
if (Get-Command fly -ErrorAction SilentlyContinue) { $flyBin = "fly" }
elseif (Get-Command flyctl -ErrorAction SilentlyContinue) { $flyBin = "flyctl" }
elseif (Test-Path "$env:USERPROFILE\.fly\bin\flyctl.exe") { $flyBin = "$env:USERPROFILE\.fly\bin\flyctl.exe" }
elseif (Test-Path "$HOME/.fly/bin/flyctl") { $flyBin = "$HOME/.fly/bin/flyctl" }
else {
    Write-Error "Не найден fly/flyctl. Установи Fly CLI: https://fly.io/docs/hands-on/install-flyctl/"
}

if ([string]::IsNullOrWhiteSpace($env:PUBLIC_BASE_URL)) {
    $env:PUBLIC_BASE_URL = "https://$($env:FLY_APP_NAME).fly.dev"
}
if ([string]::IsNullOrWhiteSpace($env:FRONTEND_URL)) {
    $env:FRONTEND_URL = $env:PUBLIC_BASE_URL
}

Write-Host "Используется DEV-приложение Fly: $($env:FLY_APP_NAME)"
Write-Host "Конфиг: fly.dev.toml"
Write-Host "Обновляю секреты..."

$secretArgs = @(
    "JWT_SECRET=$($env:JWT_SECRET)",
    "ADMIN_INIT_SECRET=$($env:ADMIN_INIT_SECRET)",
    "PUBLIC_BASE_URL=$($env:PUBLIC_BASE_URL)",
    "FRONTEND_URL=$($env:FRONTEND_URL)"
)

$optionalVars = @(
    "REDIS_URL",
    "RESEND_API_KEY",
    "MAIL_FROM",
    "APP_LOG_ENABLED",
    "APP_LOG_FILE",
    "APP_LOG_STATE_FILE",
    "APP_LOG_SYNC_INTERVAL_SECONDS",
    "APP_LOG_RETENTION_DAYS",
    "APP_LOG_CLEANUP_INTERVAL_SECONDS"
)
foreach ($varName in $optionalVars) {
    $value = [Environment]::GetEnvironmentVariable($varName)
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $secretArgs += "$varName=$value"
    }
}

& $flyBin secrets set @secretArgs --app $env:FLY_APP_NAME

Write-Host "Запускаю деплой DEV..."
Push-Location $RootDir
try {
    # --depot=false: обход частых deadline_exceeded у Depot builder.
    & $flyBin deploy --config $FlyConfig --app $env:FLY_APP_NAME --remote-only --depot=false --yes
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Повтор деплоя без --depot=false..."
        & $flyBin deploy --config $FlyConfig --app $env:FLY_APP_NAME --remote-only --yes
    }
} finally {
    Pop-Location
}

Write-Host "DEV деплой завершен: https://$($env:FLY_APP_NAME).fly.dev"
Write-Host "Проверка: curl -sS https://$($env:FLY_APP_NAME).fly.dev/api/start"
