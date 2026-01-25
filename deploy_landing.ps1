# Gearsh - Cloudflare Pages Deployment Script
# Run this script to deploy the landing page and web assets to Cloudflare

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gearsh - Cloudflare Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if wrangler is installed
$wranglerInstalled = Get-Command wrangler -ErrorAction SilentlyContinue
if (-not $wranglerInstalled) {
    Write-Host "Installing Wrangler CLI..." -ForegroundColor Yellow
    npm install -g wrangler
}

# Navigate to web directory
Set-Location -Path $PSScriptRoot\web

Write-Host ""
Write-Host "[1/4] Checking Cloudflare login status..." -ForegroundColor Yellow
wrangler whoami

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Please login to Cloudflare:" -ForegroundColor Yellow
    wrangler login
}

Write-Host ""
Write-Host "[2/4] Verifying landing page files..." -ForegroundColor Yellow

$landingFiles = @(
    "landing/index.html",
    "landing/privacy-policy.html",
    "landing/terms-and-conditions.html",
    "landing/account-deletion.html"
)

$allFilesExist = $true
foreach ($file in $landingFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (MISSING)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "ERROR: Some landing page files are missing!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/4] Deploying to Cloudflare Pages..." -ForegroundColor Yellow
Write-Host ""

# Deploy using wrangler pages
wrangler pages deploy . --project-name=thegearsh-com

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your site is now live at:" -ForegroundColor White
    Write-Host "  https://thegearsh-com.pages.dev" -ForegroundColor Cyan
    Write-Host "  https://www.thegearsh.com (custom domain)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Landing Pages:" -ForegroundColor White
    Write-Host "  / - Main landing page" -ForegroundColor Gray
    Write-Host "  /privacy-policy - Privacy Policy" -ForegroundColor Gray
    Write-Host "  /terms-and-conditions - Terms & Conditions" -ForegroundColor Gray
    Write-Host "  /account-deletion - Account Deletion" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Deployment failed. Please check the errors above." -ForegroundColor Red
    exit 1
}

Write-Host "[4/4] Verifying deployment..." -ForegroundColor Yellow
Write-Host ""

# Test the deployment
$urls = @(
    "https://thegearsh-com.pages.dev/",
    "https://thegearsh-com.pages.dev/privacy-policy",
    "https://thegearsh-com.pages.dev/terms-and-conditions",
    "https://thegearsh-com.pages.dev/account-deletion"
)

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✓ $url" -ForegroundColor Green
        } else {
            Write-Host "  ? $url (Status: $($response.StatusCode))" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ $url (Not accessible yet - may take a moment)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done! Your Gearsh landing page is live." -ForegroundColor Green
