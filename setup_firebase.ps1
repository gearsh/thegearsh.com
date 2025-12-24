# Firebase Setup Script for Gearsh App
# This script helps configure Firebase for the hybrid approach

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Gearsh App - Firebase Setup Helper" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if FlutterFire CLI is installed
Write-Host "Step 1: Checking FlutterFire CLI..." -ForegroundColor Yellow
$flutterfireInstalled = $null
try {
    $flutterfireInstalled = dart pub global list | Select-String "flutterfire_cli"
} catch {
    $flutterfireInstalled = $null
}

if (-not $flutterfireInstalled) {
    Write-Host "Installing FlutterFire CLI..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
    Write-Host "FlutterFire CLI installed!" -ForegroundColor Green
} else {
    Write-Host "FlutterFire CLI already installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2: Firebase Configuration" -ForegroundColor Yellow
Write-Host ""
Write-Host "You need to configure Firebase. Follow these steps:" -ForegroundColor White
Write-Host ""
Write-Host "1. Go to https://console.firebase.google.com/" -ForegroundColor Cyan
Write-Host "2. Create a new project or select existing 'gearsh-app'" -ForegroundColor Cyan
Write-Host "3. Enable Authentication:" -ForegroundColor Cyan
Write-Host "   - Go to Build > Authentication > Get Started" -ForegroundColor Cyan
Write-Host "   - Enable Email/Password" -ForegroundColor Cyan
Write-Host "   - Enable Google Sign-In" -ForegroundColor Cyan
Write-Host "   - Enable Apple Sign-In (optional)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 3: Run FlutterFire Configure" -ForegroundColor Yellow
Write-Host ""
Write-Host "After setting up Firebase in console, run:" -ForegroundColor White
Write-Host "  flutterfire configure" -ForegroundColor Green
Write-Host ""
Write-Host "This will:" -ForegroundColor White
Write-Host "  - Create google-services.json for Android" -ForegroundColor Cyan
Write-Host "  - Create GoogleService-Info.plist for iOS" -ForegroundColor Cyan
Write-Host "  - Update lib/config/firebase_options.dart" -ForegroundColor Cyan
Write-Host ""

$runConfigure = Read-Host "Do you want to run 'flutterfire configure' now? (y/n)"
if ($runConfigure -eq 'y') {
    Write-Host ""
    Write-Host "Running FlutterFire configure..." -ForegroundColor Yellow
    flutterfire configure --project=gearsh-app
}

Write-Host ""
Write-Host "Step 4: Get SHA-1 for Google Sign-In" -ForegroundColor Yellow
Write-Host ""
Write-Host "Run this command to get your debug SHA-1:" -ForegroundColor White
Write-Host '  keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android' -ForegroundColor Green
Write-Host ""
Write-Host "Add the SHA-1 to Firebase Console:" -ForegroundColor White
Write-Host "  Project Settings > Your apps > Android app > Add fingerprint" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 5: Database Migration" -ForegroundColor Yellow
Write-Host ""
Write-Host "Run this SQL on Cloudflare D1 to add Firebase support:" -ForegroundColor White
Write-Host "  wrangler d1 execute gearsh-db --file=database/add_firebase_support.sql" -ForegroundColor Green
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "After completing these steps, run:" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor Green
Write-Host ""

