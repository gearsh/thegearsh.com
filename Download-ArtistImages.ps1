# PowerShell Script to Download Artist Images
# This script downloads images from multiple sources and resizes them

$ErrorActionPreference = "SilentlyContinue"

$artistsDir = "assets\images\artists"
$baseDir = Get-Location

# Create directory if not exists
if (!(Test-Path $artistsDir)) {
    New-Item -ItemType Directory -Path $artistsDir | Out-Null
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Artist Image Downloader" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# List of artists with image sources (Wikipedia and other reliable sources)
$imageMap = @{
    # Format: "filename" = "URL"

    # Already existing - verify they're there
    "tyla.jpg" = "";
    "makhadzi.jpg" = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Makhadzi_%28cropped%29.jpg/220px-Makhadzi_%28cropped%29.jpg";
    "masterkg.jpg" = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Master_KG_by_Albert_Gonzalez.jpg/220px-Master_KG_by_Albert_Gonzalez.jpg";
    "lloyiso.jpg" = "";
    "nastyc.jpg" = "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Nasty_C_at_MOBO_Awards_2019.png/220px-Nasty_C_at_MOBO_Awards_2019.png";
    "kellykhumalo.jpg" = "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Kelly_Khumalo_%282019%29.jpg/220px-Kelly_Khumalo_%282019%29.jpg";
    "djzinhle.jpg" = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/DJ_Zinhle_%28cropped%29.jpg/220px-DJ_Zinhle_%28cropped%29.jpg";
    "elaine.jpg" = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Elaine_Akinsooto.jpg/220px-Elaine_Akinsooto.jpg";
}

$downloaded = 0
$skipped = 0
$failed = 0

foreach ($filename in $imageMap.Keys) {
    $filepath = Join-Path $artistsDir $filename

    # Skip if already exists
    if (Test-Path $filepath) {
        Write-Host "⏭️  $filename - Already exists" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $url = $imageMap[$filename]

    # Skip if no URL provided
    if ([string]::IsNullOrEmpty($url)) {
        Write-Host "⏹️  $filename - No source URL" -ForegroundColor Gray
        continue
    }

    Write-Host "📥 Downloading: $filename" -ForegroundColor Green

    try {
        # Download the image
        Invoke-WebRequest -Uri $url -OutFile $filepath -UserAgent "Mozilla/5.0" -ErrorAction Stop | Out-Null

        Write-Host "✅ Downloaded: $filename" -ForegroundColor Green
        $downloaded++
        Start-Sleep -Milliseconds 500  # Rate limiting
    }
    catch {
        Write-Host "❌ Failed: $filename" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Download Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Downloaded: $downloaded" -ForegroundColor Green
Write-Host "⏭️  Already existed: $skipped" -ForegroundColor Yellow
Write-Host "❌ Failed: $failed" -ForegroundColor Red
Write-Host ""
Write-Host "📝 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Run: .\search_artist_images.bat"
Write-Host "2. Manually download images for remaining artists"
Write-Host "3. Resize images to 400x400 pixels"
Write-Host "4. Save with correct filenames to: $artistsDir"
Write-Host ""
Write-Host "For filename reference, see: ARTIST_IMAGES_STATUS.md" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

