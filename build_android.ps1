# Gearsh Android Build Script

param(
    [switch]$Debug,
    [switch]$Release,
    [switch]$Appbundle,
    [switch]$Install,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Gearsh Android Build ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectRoot" -ForegroundColor Gray

Set-Location $ProjectRoot

# Clean build
if ($Clean) {
    Write-Host "`nCleaning project..." -ForegroundColor Yellow
    flutter clean
    flutter pub get
    Write-Host "Clean complete!" -ForegroundColor Green
}

# Get dependencies
Write-Host "`nGetting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build Debug APK
if ($Debug) {
    Write-Host "`n=== Building Debug APK ===" -ForegroundColor Yellow
    flutter build apk --debug

    $apkPath = "$ProjectRoot\build\app\outputs\flutter-apk\app-debug.apk"
    if (Test-Path $apkPath) {
        $size = (Get-Item $apkPath).Length / 1MB
        Write-Host "Debug APK built successfully!" -ForegroundColor Green
        Write-Host "Location: $apkPath" -ForegroundColor Cyan
        Write-Host "Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
    }
}

# Build Release APK
if ($Release) {
    Write-Host "`n=== Building Release APK ===" -ForegroundColor Yellow
    flutter build apk --release

    $apkPath = "$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $size = (Get-Item $apkPath).Length / 1MB
        Write-Host "Release APK built successfully!" -ForegroundColor Green
        Write-Host "Location: $apkPath" -ForegroundColor Cyan
        Write-Host "Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
    }
}

# Build App Bundle for Play Store
if ($Appbundle) {
    Write-Host "`n=== Building App Bundle ===" -ForegroundColor Yellow
    flutter build appbundle --release

    $aabPath = "$ProjectRoot\build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $aabPath) {
        $size = (Get-Item $aabPath).Length / 1MB
        Write-Host "App Bundle built successfully!" -ForegroundColor Green
        Write-Host "Location: $aabPath" -ForegroundColor Cyan
        Write-Host "Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
        Write-Host "`nReady for Google Play Store upload!" -ForegroundColor Magenta
    }
}

# Install on connected device
if ($Install) {
    Write-Host "`n=== Installing on Device ===" -ForegroundColor Yellow
    flutter install
    Write-Host "Installation complete!" -ForegroundColor Green
}

# Show usage if no options provided
if (-not ($Debug -or $Release -or $Appbundle -or $Install -or $Clean)) {
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\build_android.ps1 -Debug       # Build debug APK"
    Write-Host "  .\build_android.ps1 -Release     # Build release APK"
    Write-Host "  .\build_android.ps1 -Appbundle   # Build AAB for Play Store"
    Write-Host "  .\build_android.ps1 -Install     # Install on connected device"
    Write-Host "  .\build_android.ps1 -Clean       # Clean and rebuild"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\build_android.ps1 -Clean -Release        # Clean build release"
    Write-Host "  .\build_android.ps1 -Release -Install      # Build and install"
}

Write-Host "`nDone!" -ForegroundColor Green

