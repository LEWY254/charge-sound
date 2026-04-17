Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $repoRoot "charge_sound"
$binDir = Join-Path $repoRoot "bin"

if (!(Test-Path $appDir)) {
    throw "Expected Flutter app directory not found: $appDir"
}

if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

# Runtime config (can be overridden by environment variables)
$sentryDsn = if ($env:SENTRY_DSN) { $env:SENTRY_DSN } else { "https://14b986156d405bc541e6b8568c5ddcfc@o4509650662916096.ingest.de.sentry.io/4511223207559248" }
$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://kiqpuvxiooknnwgmwlio.supabase.co" }
$supabaseAnonKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpcXB1dnhpb29rbm53Z213bGlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTQ3NTAsImV4cCI6MjA5MTc5MDc1MH0.XKvFKwpFpBqT-GV7PIli89y-d9ujP9vnX8bdrBfLiTg" }

Write-Host "Building release APK..." -ForegroundColor Cyan
Push-Location $appDir
try {
    flutter build apk --release `
        --dart-define "SENTRY_DSN=$sentryDsn" `
        --dart-define "SUPABASE_URL=$supabaseUrl" `
        --dart-define "SUPABASE_ANON_KEY=$supabaseAnonKey"

    if ($LASTEXITCODE -ne 0) {
        throw "Release APK build failed."
    }

    $sourceApk = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
    if (!(Test-Path $sourceApk)) {
        throw "Built APK not found: $sourceApk"
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $versionedApk = Join-Path $binDir "charge-sound-release-$timestamp.apk"
    $latestApk = Join-Path $binDir "charge-sound-release-latest.apk"

    Copy-Item -LiteralPath $sourceApk -Destination $versionedApk -Force
    Copy-Item -LiteralPath $sourceApk -Destination $latestApk -Force

    Write-Host "Release APK copied to:" -ForegroundColor Green
    Write-Host " - $versionedApk" -ForegroundColor Green
    Write-Host " - $latestApk" -ForegroundColor Green
}
finally {
    Pop-Location
}
