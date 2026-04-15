Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Runtime config (can be overridden by environment variables)
$sentryDsn = if ($env:SENTRY_DSN) { $env:SENTRY_DSN } else { "https://14b986156d405bc541e6b8568c5ddcfc@o4509650662916096.ingest.de.sentry.io/4511223207559248" }
$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://kiqpuvxiooknnwgmwlio.supabase.co" }
$supabaseAnonKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpcXB1dnhpb29rbm53Z213bGlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTQ3NTAsImV4cCI6MjA5MTc5MDc1MH0.XKvFKwpFpBqT-GV7PIli89y-d9ujP9vnX8bdrBfLiTg" }

Write-Host "Building release APK..." -ForegroundColor Cyan
flutter build apk --release `
    --dart-define "SENTRY_DSN=$sentryDsn" `
    --dart-define "SUPABASE_URL=$supabaseUrl" `
    --dart-define "SUPABASE_ANON_KEY=$supabaseAnonKey"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Release APK build failed." -ForegroundColor Red
    exit 1
}

Write-Host "Release APK ready at build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
