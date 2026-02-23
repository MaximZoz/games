param(
    [string]$EnvFile = (Join-Path (Join-Path $PSScriptRoot "..") "deploy.cursor.env")
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Join-Path $PSScriptRoot ".."
$DeployBranch = "develop"
$DeployRef = "origin/$DeployBranch"

if (-not (Test-Path $EnvFile)) {
    throw "Файл конфигурации не найден: $EnvFile`nСоздай его из шаблона: copy deploy.cursor.env.example deploy.cursor.env"
}

Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        return
    }

    $parts = $line -split "=", 2
    if ($parts.Count -lt 2) {
        return
    }

    $name = $parts[0].Trim()
    $value = $parts[1]
    Set-Item -Path "Env:$name" -Value $value
}

$requiredVars = @("FLY_API_TOKEN", "FLY_APP_NAME", "JWT_SECRET", "ADMIN_INIT_SECRET")
foreach ($varName in $requiredVars) {
    $value = [Environment]::GetEnvironmentVariable($varName, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Не задана обязательная переменная: $varName"
    }
}

$flyCmd = Get-Command fly -ErrorAction SilentlyContinue
if ($flyCmd) {
    $flyBin = $flyCmd.Source
} else {
    $flyctlCmd = Get-Command flyctl -ErrorAction SilentlyContinue
    if ($flyctlCmd) {
        $flyBin = $flyctlCmd.Source
    } else {
        throw "Не найден fly/flyctl. Установи Fly CLI: https://fly.io/docs/hands-on/install-flyctl/"
    }
}

Write-Host "Обновляю ссылку на $DeployRef..."
git -C $ProjectRoot fetch origin $DeployBranch

$tempWorktree = Join-Path ([System.IO.Path]::GetTempPath()) ("multigames-deploy-{0}-{1}" -f $DeployBranch, [Guid]::NewGuid().ToString("N"))
git -C $ProjectRoot worktree add --detach $tempWorktree $DeployRef | Out-Null
$deploySha = (git -C $tempWorktree rev-parse --short HEAD).Trim()

try {
    Write-Host "Используется приложение Fly: $env:FLY_APP_NAME"
    Write-Host "Деплой ветки $DeployRef (commit $deploySha)"
    Write-Host "Обновляю секреты..."

    $secretArgs = @(
        "JWT_SECRET=$env:JWT_SECRET"
        "ADMIN_INIT_SECRET=$env:ADMIN_INIT_SECRET"
    )

    $optionalVars = @(
        "REDIS_URL",
        "APP_LOG_ENABLED",
        "APP_LOG_FILE",
        "APP_LOG_STATE_FILE",
        "APP_LOG_SYNC_INTERVAL_SECONDS",
        "APP_LOG_RETENTION_DAYS",
        "APP_LOG_CLEANUP_INTERVAL_SECONDS"
    )
    foreach ($varName in $optionalVars) {
        $value = [Environment]::GetEnvironmentVariable($varName, "Process")
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $secretArgs += "$varName=$value"
        }
    }

    & $flyBin secrets set @secretArgs --app $env:FLY_APP_NAME

    Write-Host "Запускаю деплой..."
    Push-Location $tempWorktree
    try {
        & $flyBin deploy --app $env:FLY_APP_NAME --remote-only --yes
    }
    finally {
        Pop-Location
    }

    Write-Host "Деплой develop завершен: https://$($env:FLY_APP_NAME).fly.dev"
}
finally {
    git -C $ProjectRoot worktree remove --force $tempWorktree 2>$null
    if (Test-Path $tempWorktree) {
        Remove-Item -Recurse -Force $tempWorktree
    }
}
