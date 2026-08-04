# Создаёт на Fly отдельное DEV-окружение (приложение + Postgres + секреты).
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

$requiredVars = @("FLY_API_TOKEN", "FLY_APP_NAME", "FLY_DEV_DB_NAME", "JWT_SECRET", "ADMIN_INIT_SECRET")
foreach ($varName in $requiredVars) {
    $val = [Environment]::GetEnvironmentVariable($varName)
    if ([string]::IsNullOrWhiteSpace($val)) {
        Write-Error "Не задана обязательная переменная: $varName"
    }
}

if ([string]::IsNullOrWhiteSpace($env:FLY_REGION)) { $env:FLY_REGION = "ams" }
if ([string]::IsNullOrWhiteSpace($env:PUBLIC_BASE_URL)) {
    $env:PUBLIC_BASE_URL = "https://$($env:FLY_APP_NAME).fly.dev"
}
if ([string]::IsNullOrWhiteSpace($env:FRONTEND_URL)) {
    $env:FRONTEND_URL = $env:PUBLIC_BASE_URL
}
if ([string]::IsNullOrWhiteSpace($env:APP_LOG_ENABLED)) { $env:APP_LOG_ENABLED = "false" }

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

Write-Host "==> DEV app: $($env:FLY_APP_NAME)"
Write-Host "==> DEV db:  $($env:FLY_DEV_DB_NAME)"
Write-Host "==> region:  $($env:FLY_REGION)"

$appExists = $true
try { & $flyBin status --app $env:FLY_APP_NAME | Out-Null } catch { $appExists = $false }

if (-not $appExists) {
    Write-Host "Создаю приложение $($env:FLY_APP_NAME)..."
    try {
        & $flyBin apps create $env:FLY_APP_NAME --org personal
    } catch {
        & $flyBin apps create $env:FLY_APP_NAME
    }
} else {
    Write-Host "Приложение $($env:FLY_APP_NAME) уже есть — пропускаю create."
}

$dbExists = $true
try { & $flyBin status --app $env:FLY_DEV_DB_NAME | Out-Null } catch { $dbExists = $false }

if (-not $dbExists) {
    Write-Host "Создаю Postgres $($env:FLY_DEV_DB_NAME) (это займёт несколько минут)..."
    & $flyBin postgres create `
        --name $env:FLY_DEV_DB_NAME `
        --region $env:FLY_REGION `
        --initial-cluster-size 1 `
        --vm-size shared-cpu-1x `
        --volume-size 1 `
        --yes
} else {
    Write-Host "Postgres $($env:FLY_DEV_DB_NAME) уже есть — пропускаю create."
}

Write-Host "Привязываю Postgres к приложению (DATABASE_URL)..."
try {
    & $flyBin postgres attach $env:FLY_DEV_DB_NAME --app $env:FLY_APP_NAME --yes
} catch {
    Write-Host "Attach пропущен/уже выполнен — проверь: fly secrets list --app $($env:FLY_APP_NAME)"
}

Write-Host "Ставлю секреты DEV..."
$secretArgs = @(
    "JWT_SECRET=$($env:JWT_SECRET)",
    "ADMIN_INIT_SECRET=$($env:ADMIN_INIT_SECRET)",
    "PUBLIC_BASE_URL=$($env:PUBLIC_BASE_URL)",
    "FRONTEND_URL=$($env:FRONTEND_URL)",
    "APP_LOG_ENABLED=$($env:APP_LOG_ENABLED)"
)

$optionalVars = @(
    "REDIS_URL",
    "RESEND_API_KEY",
    "MAIL_FROM",
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

Write-Host ""
Write-Host "DEV-окружение готово (ресурсы созданы, секреты выставлены)."
Write-Host "Дальше задеплой код:"
Write-Host "  .\launcher\deploy_dev.ps1"
Write-Host "URL: $($env:PUBLIC_BASE_URL)"
Write-Host ""
Write-Host "Важно: это чистая БД (миграции применятся при старте приложения)."
Write-Host "Данные прода НЕ копируются. Чтобы склонировать данные — см. docs/DEPLOY_FLY_DEV.md"
