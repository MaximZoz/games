# Создаёт внешний Upstash Redis (через Fly) и прописывает REDIS_URL в секреты app.
# Зачем: локальный Redis в контейнере эфемерный — после deploy лобби сбрасываются.
#
# Примеры:
#   .\launcher\setup_fly_redis.ps1 deploy.dev.env
#   .\launcher\setup_fly_redis.ps1 deploy.cursor.env
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$EnvFile = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { $null }

if ($EnvFile) {
    if (-not (Test-Path $EnvFile)) {
        $alt = Join-Path $RootDir $EnvFile
        if (Test-Path $alt) { $EnvFile = $alt }
        else { Write-Error "Файл конфигурации не найден: $EnvFile" }
    }
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) { return }
        $name, $value = $line -split "=", 2
        if ($name -and $null -ne $value) {
            # Убрать окружающие кавычки
            $v = $value.Trim()
            if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
                $v = $v.Substring(1, $v.Length - 2)
            }
            Set-Item -Path "Env:$name" -Value $v
        }
    }
}

foreach ($varName in @("FLY_API_TOKEN", "FLY_APP_NAME")) {
    $val = [Environment]::GetEnvironmentVariable($varName)
    if ([string]::IsNullOrWhiteSpace($val)) {
        Write-Error "Не задана обязательная переменная: $varName`nПример: .\launcher\setup_fly_redis.ps1 deploy.dev.env"
    }
}

if ([string]::IsNullOrWhiteSpace($env:FLY_REGION)) { $env:FLY_REGION = "ams" }
if ([string]::IsNullOrWhiteSpace($env:FLY_REDIS_NAME)) { $env:FLY_REDIS_NAME = "$($env:FLY_APP_NAME)-redis" }
if ([string]::IsNullOrWhiteSpace($env:FLY_REDIS_PLAN)) { $env:FLY_REDIS_PLAN = "pay-as-you-go" }

$flyBin = $null
if (Get-Command fly -ErrorAction SilentlyContinue) { $flyBin = "fly" }
elseif (Get-Command flyctl -ErrorAction SilentlyContinue) { $flyBin = "flyctl" }
elseif (Test-Path "$env:USERPROFILE\.fly\bin\flyctl.exe") { $flyBin = "$env:USERPROFILE\.fly\bin\flyctl.exe" }
elseif (Test-Path "$HOME/.fly/bin/flyctl") { $flyBin = "$HOME/.fly/bin/flyctl" }
else { Write-Error "Не найден fly/flyctl" }

Write-Host "==> App:        $($env:FLY_APP_NAME)"
Write-Host "==> Redis name: $($env:FLY_REDIS_NAME)"
Write-Host "==> Region:     $($env:FLY_REGION)"
Write-Host "==> Plan:       $($env:FLY_REDIS_PLAN)"

& $flyBin status --app $env:FLY_APP_NAME 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Приложение $($env:FLY_APP_NAME) не найдено или токен не имеет к нему доступа."
    Write-Host "Список app:"
    & $flyBin apps list
    Write-Host ""
    Write-Host "1) ./launcher/setup_fly_dev.sh  если DEV ещё не создан"
    Write-Host "2) Обнови FLY_API_TOKEN: fly tokens create deploy -a $($env:FLY_APP_NAME) -x 72h"
    Write-Error "App $($env:FLY_APP_NAME) unavailable"
}

$redisExists = $true
& $flyBin redis status $env:FLY_REDIS_NAME 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { $redisExists = $false }

if (-not $redisExists) {
    Write-Host "Создаю Upstash Redis: $($env:FLY_REDIS_NAME) ..."
    $createArgs = @(
        "redis", "create",
        "--name", $env:FLY_REDIS_NAME,
        "--region", $env:FLY_REGION,
        "--plan", $env:FLY_REDIS_PLAN,
        "--no-replicas",
        "--enable-eviction"
    )
    if (-not [string]::IsNullOrWhiteSpace($env:FLY_ORG)) {
        $createArgs += @("--org", $env:FLY_ORG)
    }
    & $flyBin @createArgs
    if ($LASTEXITCODE -ne 0) { Write-Error "fly redis create failed" }
} else {
    Write-Host "Redis $($env:FLY_REDIS_NAME) уже есть — пропускаю create."
}

Write-Host "Читаю Private URL..."
$statusOut = & $flyBin redis status $env:FLY_REDIS_NAME 2>&1 | Out-String
Write-Host $statusOut

$match = [regex]::Match($statusOut, 'rediss?://[^\s]+')
if (-not $match.Success) {
    Write-Error "Не удалось вытащить REDIS_URL. Скопируй Private URL вручную и: fly secrets set REDIS_URL='...' --app $($env:FLY_APP_NAME)"
}
$redisUrl = $match.Value

& $flyBin secrets set "REDIS_URL=$redisUrl" --app $env:FLY_APP_NAME
if ($LASTEXITCODE -ne 0) { Write-Error "Не удалось поставить REDIS_URL" }

Write-Host ""
Write-Host "Готово. Локальный redis в контейнере больше не поднимется; лобби переживают deploy."
Write-Host "Проверка: fly secrets list --app $($env:FLY_APP_NAME)"
