# Deploy Gearsh to Cloudflare Pages with Functions
# This script deploys both the web app and API functions

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         GEARSH - CLOUDFLARE DEPLOYMENT                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Flutter Web
Write-Host "Step 1: Building Flutter Web..." -ForegroundColor Yellow
Set-Location $ProjectRoot
flutter clean
flutter pub get
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Flutter build complete!" -ForegroundColor Green

# Step 2: Copy build to web directory
Write-Host ""
Write-Host "Step 2: Preparing deployment files..." -ForegroundColor Yellow

$webDir = "$ProjectRoot\web"
$buildDir = "$ProjectRoot\build\web"

# Copy Flutter build files (but keep existing functions, wrangler.toml, etc.)
$excludeFiles = @("wrangler.toml", "_redirects", "manifest.json", "functions")

Get-ChildItem $buildDir -File | ForEach-Object {
    Copy-Item $_.FullName -Destination $webDir -Force
}

# Copy subdirectories except functions
Get-ChildItem $buildDir -Directory | Where-Object { $_.Name -ne "functions" } | ForEach-Object {
    Copy-Item $_.FullName -Destination $webDir -Recurse -Force
}

Write-Host "Files prepared!" -ForegroundColor Green

# Step 3: Deploy database schema
Write-Host ""
Write-Host "Step 3: Checking database..." -ForegroundColor Yellow
Set-Location $webDir

$applySchema = Read-Host "Apply database schema? (y/N)"
if ($applySchema -eq "y" -or $applySchema -eq "Y") {
    Write-Host "Applying schema..." -ForegroundColor Cyan
    wrangler d1 execute gearsh_db --file="../database/schema.sql" --remote

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Schema applied!" -ForegroundColor Green
    } else {
        Write-Host "Schema application failed - continuing anyway..." -ForegroundColor Yellow
    }
}

# Step 4: Deploy to Cloudflare Pages
Write-Host ""
Write-Host "Step 4: Deploying to Cloudflare Pages..." -ForegroundColor Yellow

wrangler pages deploy . --project-name=thegearsh-com

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         DEPLOYMENT SUCCESSFUL!                               ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your app is live at: https://www.thegearsh.com" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "API Endpoints:" -ForegroundColor Yellow
    Write-Host "  - Health: https://www.thegearsh.com/api/health" -ForegroundColor Gray
    Write-Host "  - Register: https://www.thegearsh.com/api/auth/register" -ForegroundColor Gray
    Write-Host "  - Login: https://www.thegearsh.com/api/auth/login" -ForegroundColor Gray
    Write-Host "  - Artists: https://www.thegearsh.com/api/artists" -ForegroundColor Gray
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
}

Set-Location $ProjectRoot
Write-Host ""
Write-Host "Done!" -ForegroundColor Green

