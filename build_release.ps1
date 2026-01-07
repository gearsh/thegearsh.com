# Gearsh App - Build Release Script
# Run this script to build release versions for Play Store and App Store

param(
    [switch]$Android,
    [switch]$iOS,
    [switch]$All,
    [string]$BuildName = "1.0.0",
    [int]$BuildNumber = 1
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gearsh App - Release Build Script    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to project directory
$projectDir = $PSScriptRoot
Set-Location $projectDir

# Function to build Android
function Build-Android {
    Write-Host "📱 Building Android App Bundle..." -ForegroundColor Green

    # Check for key.properties
    if (-not (Test-Path "android/key.properties")) {
        Write-Host "⚠️  Warning: android/key.properties not found!" -ForegroundColor Yellow
        Write-Host "   Creating template file..." -ForegroundColor Yellow

        @"
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gearsh-upload
storeFile=../keys/gearsh-upload.keystore
"@ | Out-File -FilePath "android/key.properties" -Encoding UTF8

        Write-Host "   Please update android/key.properties with your keystore details." -ForegroundColor Yellow
        return
    }

    # Clean previous builds
    Write-Host "   Cleaning previous builds..." -ForegroundColor Gray
    flutter clean

    # Get dependencies
    Write-Host "   Getting dependencies..." -ForegroundColor Gray
    flutter pub get

    # Build App Bundle
    Write-Host "   Building release App Bundle..." -ForegroundColor Gray
    flutter build appbundle --release --build-name=$BuildName --build-number=$BuildNumber

    $outputPath = "build/app/outputs/bundle/release/app-release.aab"
    if (Test-Path $outputPath) {
        $size = (Get-Item $outputPath).Length / 1MB
        Write-Host "✅ Android App Bundle built successfully!" -ForegroundColor Green
        Write-Host "   Output: $outputPath" -ForegroundColor Gray
        Write-Host "   Size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
    } else {
        Write-Host "❌ Build failed! Check the errors above." -ForegroundColor Red
    }
}

# Function to build iOS (requires macOS)
function Build-iOS {
    if ($IsWindows) {
        Write-Host "⚠️  iOS builds require macOS with Xcode installed." -ForegroundColor Yellow
        Write-Host "   Please run this script on a Mac to build for iOS." -ForegroundColor Yellow
        return
    }

    Write-Host "🍎 Building iOS IPA..." -ForegroundColor Green

    # Clean previous builds
    Write-Host "   Cleaning previous builds..." -ForegroundColor Gray
    flutter clean

    # Get dependencies
    Write-Host "   Getting dependencies..." -ForegroundColor Gray
    flutter pub get

    # Install CocoaPods
    Write-Host "   Installing CocoaPods..." -ForegroundColor Gray
    Push-Location ios
    pod install
    Pop-Location

    # Build IPA
    Write-Host "   Building release IPA..." -ForegroundColor Gray
    flutter build ipa --release --build-name=$BuildName --build-number=$BuildNumber

    Write-Host "✅ iOS IPA built successfully!" -ForegroundColor Green
    Write-Host "   Output: build/ios/ipa/Gearsh.ipa" -ForegroundColor Gray
}

# Main execution
Write-Host "Build Configuration:" -ForegroundColor White
Write-Host "  Version: $BuildName" -ForegroundColor Gray
Write-Host "  Build Number: $BuildNumber" -ForegroundColor Gray
Write-Host ""

if ($All) {
    Build-Android
    Write-Host ""
    Build-iOS
} elseif ($Android) {
    Build-Android
} elseif ($iOS) {
    Build-iOS
} else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\build_release.ps1 -Android       # Build Android only" -ForegroundColor Gray
    Write-Host "  .\build_release.ps1 -iOS           # Build iOS only (macOS required)" -ForegroundColor Gray
    Write-Host "  .\build_release.ps1 -All           # Build both platforms" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -BuildName '1.0.1'    # Set version name" -ForegroundColor Gray
    Write-Host "  -BuildNumber 2        # Set build number" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host "  .\build_release.ps1 -Android -BuildName '1.0.1' -BuildNumber 2" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

