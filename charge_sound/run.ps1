# Charge Sound - Build & Run Script
# Launches the app on the Medium Phone API 36 emulator

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sdkPath = "C:\Users\lewy\AppData\Local\Android\sdk"
$avdName = "Medium_Phone_API_36.1"
$emulatorExe = "$sdkPath\emulator\emulator.exe"
$adb = "$sdkPath\platform-tools\adb.exe"

$env:ANDROID_HOME = $sdkPath

# Runtime config (can be overridden by environment variables)
$sentryDsn = if ($env:SENTRY_DSN) { $env:SENTRY_DSN } else { "https://14b986156d405bc541e6b8568c5ddcfc@o4509650662916096.ingest.de.sentry.io/4511223207559248" }
$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://kiqpuvxiooknnwgmwlio.supabase.co" }
$supabaseAnonKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpcXB1dnhpb29rbm53Z213bGlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTQ3NTAsImV4cCI6MjA5MTc5MDc1MH0.XKvFKwpFpBqT-GV7PIli89y-d9ujP9vnX8bdrBfLiTg" }

Write-Host "=== Charge Sound ===" -ForegroundColor Green
Write-Host ""

# Step 1: Install dependencies
Write-Host "[1/3] Installing dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to get dependencies." -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies installed." -ForegroundColor Green
Write-Host ""

# Step 2: Launch emulator if not already running
Write-Host "[2/3] Checking for Android emulator..." -ForegroundColor Cyan

$adbOutput = & $adb devices 2>&1 | Out-String
if ($adbOutput -match "(emulator-\d+)\s+device") {
    $deviceId = $Matches[1]
    Write-Host "Emulator already running: $deviceId" -ForegroundColor Green
} else {
    Write-Host "Launching $avdName..." -ForegroundColor Yellow
    Start-Process -FilePath $emulatorExe -ArgumentList "-avd", $avdName -WindowStyle Hidden
    Write-Host "Waiting for emulator to boot..." -ForegroundColor Yellow

    $timeout = 120
    $elapsed = 0
    $deviceId = $null
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 3
        $elapsed += 3
        $check = & $adb devices 2>&1 | Out-String
        if ($check -match "(emulator-\d+)\s+device") {
            $deviceId = $Matches[1]
            $bootCheck = & $adb -s $deviceId shell getprop sys.boot_completed 2>&1 | Out-String
            if ($bootCheck.Trim() -eq "1") {
                Write-Host "Emulator booted after ~${elapsed}s: $deviceId" -ForegroundColor Green
                break
            }
        }
        Write-Host "  Still booting... (${elapsed}s)" -ForegroundColor DarkGray
    }
    if (-not $deviceId) {
        Write-Host "Emulator failed to start after ${timeout}s." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 3: Run the app
Write-Host "[3/3] Running Charge Sound on $deviceId..." -ForegroundColor Cyan
flutter run -d $deviceId `
    --dart-define "SENTRY_DSN=$sentryDsn" `
    --dart-define "SUPABASE_URL=$supabaseUrl" `
    --dart-define "SUPABASE_ANON_KEY=$supabaseAnonKey"
