# Gearsh - Google Play Store Build Script
# Run this script to build the app bundle for Play Store submission

param(
    [switch]$GenerateKeystore,
    [switch]$BuildBundle,
    [switch]$BuildApk,
    [switch]$Analyze,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           GEARSH - PLAY STORE BUILD SCRIPT                   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location $ProjectRoot

# Generate Keystore
function Generate-Keystore {
    Write-Host "═══ GENERATING RELEASE KEYSTORE ═══" -ForegroundColor Yellow

    $keystoreDir = "$ProjectRoot\android\keystore"
    $keystorePath = "$keystoreDir\gearsh-release-key.jks"

    if (-not (Test-Path $keystoreDir)) {
        New-Item -ItemType Directory -Path $keystoreDir -Force | Out-Null
    }

    if (Test-Path $keystorePath) {
        Write-Host "Keystore already exists at: $keystorePath" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite? (y/N)"
        if ($overwrite -ne "y") {
            Write-Host "Skipping keystore generation." -ForegroundColor Gray
            return
        }
    }

    Write-Host "Generating keystore..." -ForegroundColor Cyan
    Write-Host "You will be prompted for passwords and information." -ForegroundColor Gray
    Write-Host ""

    keytool -genkey -v `
        -keystore $keystorePath `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias gearsh

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Keystore generated successfully!" -ForegroundColor Green
        Write-Host "Location: $keystorePath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "IMPORTANT: Now create android/key.properties with:" -ForegroundColor Yellow
        Write-Host "  storePassword=YOUR_STORE_PASSWORD" -ForegroundColor Gray
        Write-Host "  keyPassword=YOUR_KEY_PASSWORD" -ForegroundColor Gray
        Write-Host "  keyAlias=gearsh" -ForegroundColor Gray
        Write-Host "  storeFile=../keystore/gearsh-release-key.jks" -ForegroundColor Gray
        Write-Host ""
        Write-Host "NEVER commit key.properties or the .jks file to git!" -ForegroundColor Red
    }
}

# Build App Bundle
function Build-AppBundle {
    Write-Host ""
    Write-Host "═══ BUILDING APP BUNDLE FOR PLAY STORE ═══" -ForegroundColor Yellow

    # Check for key.properties
    $keyPropsPath = "$ProjectRoot\android\key.properties"
    if (-not (Test-Path $keyPropsPath)) {
        Write-Host "WARNING: android/key.properties not found!" -ForegroundColor Red
        Write-Host "Building with debug signing (not for production)" -ForegroundColor Yellow
    } else {
        Write-Host "Using release signing configuration" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Cleaning previous builds..." -ForegroundColor Cyan
    flutter clean

    Write-Host "Getting dependencies..." -ForegroundColor Cyan
    flutter pub get

    Write-Host "Building app bundle..." -ForegroundColor Cyan
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

    $aabPath = "$ProjectRoot\build\app\outputs\bundle\release\app-release.aab"

    if (Test-Path $aabPath) {
        $size = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  BUILD SUCCESSFUL!                                            ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "App Bundle: $aabPath" -ForegroundColor Cyan
        Write-Host "Size: $size MB" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Debug symbols: $ProjectRoot\build\debug-info" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Go to Google Play Console" -ForegroundColor Gray
        Write-Host "  2. Create or select your app" -ForegroundColor Gray
        Write-Host "  3. Upload the .aab file to Internal Testing first" -ForegroundColor Gray
        Write-Host "  4. Test thoroughly before promoting to Production" -ForegroundColor Gray
    } else {
        Write-Host "Build failed! Check the error messages above." -ForegroundColor Red
    }
}

# Build APK
function Build-Apk {
    Write-Host ""
    Write-Host "═══ BUILDING RELEASE APK ═══" -ForegroundColor Yellow

    Write-Host "Getting dependencies..." -ForegroundColor Cyan
    flutter pub get

    Write-Host "Building APK..." -ForegroundColor Cyan
    flutter build apk --release --obfuscate --split-debug-info=build/debug-info

    $apkPath = "$ProjectRoot\build\app\outputs\flutter-apk\app-release.apk"

    if (Test-Path $apkPath) {
        $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
        Write-Host ""
        Write-Host "APK built successfully!" -ForegroundColor Green
        Write-Host "Location: $apkPath" -ForegroundColor Cyan
        Write-Host "Size: $size MB" -ForegroundColor Cyan
    }
}

# Analyze Build
function Analyze-Build {
    Write-Host ""
    Write-Host "═══ ANALYZING BUILD SIZE ═══" -ForegroundColor Yellow

    flutter build apk --analyze-size --target-platform android-arm64
}

# Show usage
function Show-Usage {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\play_store_build.ps1 -GenerateKeystore  # Generate signing keystore"
    Write-Host "  .\play_store_build.ps1 -BuildBundle       # Build AAB for Play Store"
    Write-Host "  .\play_store_build.ps1 -BuildApk          # Build release APK"
    Write-Host "  .\play_store_build.ps1 -Analyze           # Analyze build size"
    Write-Host "  .\play_store_build.ps1 -All               # Generate keystore and build bundle"
    Write-Host ""
    Write-Host "Example workflow:" -ForegroundColor Cyan
    Write-Host "  1. .\play_store_build.ps1 -GenerateKeystore"
    Write-Host "  2. Create android/key.properties with your passwords"
    Write-Host "  3. .\play_store_build.ps1 -BuildBundle"
    Write-Host "  4. Upload to Play Console"
}

# Main execution
if ($All) {
    Generate-Keystore
    Build-AppBundle
} elseif ($GenerateKeystore) {
    Generate-Keystore
} elseif ($BuildBundle) {
    Build-AppBundle
} elseif ($BuildApk) {
    Build-Apk
} elseif ($Analyze) {
    Analyze-Build
} else {
    Show-Usage
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

