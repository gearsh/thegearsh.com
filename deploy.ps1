# Gearsh MVP - Build and Deploy Script for Windows PowerShell

param(
    [switch]$BuildWeb,
    [switch]$DeployPages,
    [switch]$SetupDatabase,
    [switch]$SeedDatabase,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$WebBuildDir = "$ProjectRoot\build\web"
$DatabaseDir = "$ProjectRoot\database"

Write-Host "=== Gearsh MVP Build & Deploy ===" -ForegroundColor Cyan

# Function to check if a command exists
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites
function Check-Prerequisites {
    Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

    if (-not (Test-Command "flutter")) {
        Write-Error "Flutter is not installed or not in PATH"
        exit 1
    }

    if (-not (Test-Command "wrangler")) {
        Write-Host "Installing Wrangler CLI..." -ForegroundColor Yellow
        npm install -g wrangler
    }

    Write-Host "Prerequisites OK!" -ForegroundColor Green
}

# Build Flutter Web
function Build-FlutterWeb {
    Write-Host "`n=== Building Flutter Web ===" -ForegroundColor Yellow

    Set-Location $ProjectRoot

    # Clean previous build
    flutter clean

    # Get dependencies
    flutter pub get

    # Build for web with optimizations
    flutter build web --release --web-renderer canvaskit

    Write-Host "Flutter web build complete!" -ForegroundColor Green
}

# Setup D1 Database
function Setup-Database {
    Write-Host "`n=== Setting up D1 Database ===" -ForegroundColor Yellow

    Set-Location "$ProjectRoot\web"

    # Apply schema
    Write-Host "Applying database schema..." -ForegroundColor Cyan
    wrangler d1 execute gearsh_db --file="$DatabaseDir\schema.sql" --remote

    Write-Host "Database schema applied!" -ForegroundColor Green
}

# Seed Database
function Seed-Database {
    Write-Host "`n=== Seeding Database ===" -ForegroundColor Yellow

    Set-Location "$ProjectRoot\web"

    # Apply seed data
    Write-Host "Seeding database..." -ForegroundColor Cyan
    wrangler d1 execute gearsh_db --file="$DatabaseDir\seed.sql" --remote

    Write-Host "Database seeded!" -ForegroundColor Green
}

# Deploy to Cloudflare Pages
function Deploy-Pages {
    Write-Host "`n=== Deploying to Cloudflare Pages ===" -ForegroundColor Yellow

    # Copy build to web directory
    Write-Host "Copying build files..." -ForegroundColor Cyan

    # Remove old build files but keep config
    Get-ChildItem "$ProjectRoot\web" -Exclude "wrangler.toml", "functions", "_redirects", "manifest.json" |
        Where-Object { $_.Name -notlike ".*" } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Copy new build
    Copy-Item -Path "$WebBuildDir\*" -Destination "$ProjectRoot\web" -Recurse -Force

    # Deploy
    Set-Location "$ProjectRoot\web"
    Write-Host "Deploying to Cloudflare Pages..." -ForegroundColor Cyan
    wrangler pages deploy . --project-name=thegearsh-com

    Write-Host "Deployment complete!" -ForegroundColor Green
    Write-Host "Visit: https://www.thegearsh.com" -ForegroundColor Cyan
}

# Main execution
Check-Prerequisites

if ($All) {
    $BuildWeb = $true
    $SetupDatabase = $true
    $SeedDatabase = $true
    $DeployPages = $true
}

if ($BuildWeb) {
    Build-FlutterWeb
}

if ($SetupDatabase) {
    Setup-Database
}

if ($SeedDatabase) {
    Seed-Database
}

if ($DeployPages) {
    Deploy-Pages
}

if (-not ($BuildWeb -or $SetupDatabase -or $SeedDatabase -or $DeployPages)) {
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -BuildWeb       # Build Flutter web app"
    Write-Host "  .\deploy.ps1 -SetupDatabase  # Create database tables"
    Write-Host "  .\deploy.ps1 -SeedDatabase   # Seed sample data"
    Write-Host "  .\deploy.ps1 -DeployPages    # Deploy to Cloudflare Pages"
    Write-Host "  .\deploy.ps1 -All            # Do all of the above"
}

Write-Host "`nDone!" -ForegroundColor Green

