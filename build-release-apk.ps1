Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$newScript = Join-Path $repoRoot "release-android-apk.ps1"

Write-Host "build-release-apk.ps1 is deprecated. Running release-android-apk.ps1 instead." -ForegroundColor Yellow
& $newScript
