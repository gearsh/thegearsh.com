# Deploy Gearsh Database Schema to Cloudflare D1
# Run this script to set up the database tables

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "=== GEARSH DATABASE SETUP ===" -ForegroundColor Cyan
Write-Host ""

Set-Location "$ProjectRoot\web"

# Check if wrangler is installed
try {
    wrangler --version | Out-Null
} catch {
    Write-Host "Wrangler not found. Installing..." -ForegroundColor Yellow
    npm install -g wrangler
}

Write-Host "Applying database schema..." -ForegroundColor Yellow
Write-Host ""

# Apply schema
wrangler d1 execute gearsh_db --file="../database/schema.sql" --remote

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Schema applied successfully!" -ForegroundColor Green
    Write-Host ""

    $seedData = Read-Host "Do you want to seed sample data? (y/N)"
    if ($seedData -eq "y" -or $seedData -eq "Y") {
        Write-Host "Seeding database..." -ForegroundColor Yellow
        wrangler d1 execute gearsh_db --file="../database/seed.sql" --remote

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Database seeded successfully!" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Failed to apply schema. Check the error above." -ForegroundColor Red
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

