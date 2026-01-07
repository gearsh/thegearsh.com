# PowerShell script to download artist images
# Run this script to download missing artist images

$artistsDir = ".\assets\images\artists"

# Create directory if it doesn't exist
if (!(Test-Path $artistsDir)) {
    New-Item -ItemType Directory -Path $artistsDir -Force
}

# List of artists that need images (name => filename)
# These are placeholder URLs - you'll need to manually source proper licensed images
$artists = @{
    # Already have: tyla.jpg, lastkrm.png, maphorisa.png, kabza.png, nastyc.png, cassper.png, kelvin-momo.png, waffles.png, coffee.png

    # Need images for these artists:
    "Seether" = "seether.jpg"
    "The Kiffness" = "thekiffness.jpg"
    "Scotts Maphuma" = "scottsmaphuma.jpg"
    "Die Antwoord" = "dieantwoord.jpg"
    "Joyous Celebration" = "joyouscelebration.jpg"
    "Zee Nxumalo" = "zeenxumalo.jpg"
    "Makhadzi" = "makhadzi.jpg"
    "Tyler ICU" = "tylericu.jpg"
    "MaWhoo" = "mawhoo.jpg"
    "Focalistic" = "focalistic.jpg"
    "Lucky Dube" = "luckydube.jpg"
    "Sjava" = "sjava.jpg"
    "Mr JazziQ" = "mrjazziq.jpg"
    "Major League DJz" = "majorleaguedjz.jpg"
    "Deborah Lukalu" = "deborahlukalu.jpg"
    "Master KG" = "masterkg.jpg"
    "Kwesta" = "kwesta.jpg"
    "LLOYISO" = "lloyiso.jpg"
    "Aymos" = "aymos.jpg"
    "Big Zulu" = "bigzulu.jpg"
    "Ghost Hlubi" = "ghosthlubi.jpg"
    "Vigro Deep" = "vigrodeep.jpg"
    "Oscar Mbo" = "oscarmbo.jpg"
    "Pabi Cooper" = "pabicooper.jpg"
    "Blaq Diamond" = "blaqdiamond.jpg"
    "DJ Stokie" = "djstokie.jpg"
    "AKA" = "aka.jpg"
    "Usimamane" = "usimamane.jpg"
    "Kharishma" = "kharishma.jpg"
    "Babalwa M" = "babalwam.jpg"
    "DJ Zinhle" = "djzinhle.jpg"
    "Mellow & Sleazy" = "mellowandsleazy.jpg"
    "Mthandeni SK" = "mthandenisk.jpg"
    "Nontokozo Mkhize" = "nontokozomkhize.jpg"
    "Nkosazana Daughter" = "nkosazanadaughter.jpg"
    "LeeMcKrazy" = "leemckrazy.jpg"
    "Felo le Tee" = "feloletee.jpg"
    "Kamo Mphela" = "kamomphela.jpg"
    "Dumi Mkokstad" = "dumimkokstad.jpg"
    "Nomcebo Zikode" = "nomcebozikode.jpg"
    "Bassie" = "bassie.jpg"
    "Sam Deep" = "samdeep.jpg"
    "TitoM" = "titom.jpg"
    "Emtee" = "emtee.jpg"
    "Mlindo The Vocalist" = "mlindothevocalist.jpg"
    "Sho Madjozi" = "shomadjozi.jpg"
    "Young Stunna" = "youngstunna.jpg"
    "Sha Sha" = "shasha.jpg"
    "Prince Kaybee" = "princekaybee.jpg"
    "Mafikizolo" = "mafikizolo.jpg"
    "The Soil" = "thesoil.jpg"
    "K.O" = "ko.jpg"
    "Busta 929" = "busta929.jpg"
    "Dlala Thukzin" = "dlalathukzin.jpg"
    "DBN GOGO" = "dbngogo.jpg"
    "A-Reece" = "areece.jpg"
    "De Mthuda" = "demthuda.jpg"
    "DJ Tira" = "djtira.jpg"
    "Azana" = "azana.jpg"
    "King Monada" = "kingmonada.jpg"
    "Daliwonga" = "daliwonga.jpg"
    "Sun-EL Musician" = "sunelmusician.jpg"
    "Shekhinah" = "shekhinah.jpg"
    "Elaine" = "elaine.jpg"
    "Simmy" = "simmy.jpg"
    "Blxckie" = "blxckie.jpg"
    "Nadia Nakai" = "nadianakai.jpg"
    "Shimza" = "shimza.jpg"
    "Sir Trill" = "sirtrill.jpg"
    "Kelly Khumalo" = "kellykhumalo.jpg"
    "Boohle" = "boohle.jpg"
    "Mas Musiq" = "masmusiq.jpg"
    "Riky Rick" = "rikyrick.jpg"
    "Benjamin Dube" = "benjamindube.jpg"
    "Sbi Techn" = "sbitechn.jpg"
    "Megan Woods" = "meganwoods.jpg"
    "TXC" = "txc.jpg"
    "Lwah Ndlunkulu" = "lwahndlunkulu.jpg"
    "Alice Phoebe Lou" = "alicephoebelou.jpg"
    "Nomfundo Moh" = "nomfundomoh.jpg"
    "Caiiro" = "caiiro.jpg"
    "TOSS" = "toss.jpg"
    "Lebo Sekgobela" = "lebosekgobela.jpg"
    "Mduduzi Ncube" = "mduduzincube.jpg"
    "2Point1" = "2point1.jpg"
    "Q Twins" = "qtwins.jpg"
    "Malome Vector" = "malomevector.jpg"
    "Pistole Gwijo" = "pistolegwijo.jpg"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Artist Images Download Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check which images already exist
$existing = @()
$missing = @()

foreach ($artist in $artists.Keys) {
    $filename = $artists[$artist]
    $filepath = Join-Path $artistsDir $filename

    # Also check for .png and .webp variants
    $pngPath = $filepath -replace '\.jpg$', '.png'
    $webpPath = $filepath -replace '\.jpg$', '.webp'

    if ((Test-Path $filepath) -or (Test-Path $pngPath) -or (Test-Path $webpPath)) {
        $existing += $artist
    } else {
        $missing += $artist
    }
}

Write-Host "Images already exist for $($existing.Count) artists:" -ForegroundColor Green
$existing | ForEach-Object { Write-Host "  [OK] $_" -ForegroundColor DarkGreen }

Write-Host ""
Write-Host "Missing images for $($missing.Count) artists:" -ForegroundColor Yellow
$missing | ForEach-Object { Write-Host "  [MISSING] $_" -ForegroundColor Red }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Manual Download Instructions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To download images, search for each artist on:" -ForegroundColor White
Write-Host "  - Google Images (filter by 'Labeled for reuse')" -ForegroundColor Gray
Write-Host "  - Unsplash (https://unsplash.com)" -ForegroundColor Gray
Write-Host "  - Official artist websites/social media" -ForegroundColor Gray
Write-Host ""
Write-Host "Save images to: $artistsDir" -ForegroundColor White
Write-Host ""
Write-Host "Recommended image specs:" -ForegroundColor White
Write-Host "  - Size: 400x400 or 500x500 pixels" -ForegroundColor Gray
Write-Host "  - Format: JPG or PNG" -ForegroundColor Gray
Write-Host "  - Square aspect ratio preferred" -ForegroundColor Gray
Write-Host ""

# Generate search URLs
Write-Host "Opening browser tabs to search for missing artist images..." -ForegroundColor Cyan
Write-Host "(Press any key to open searches, or Ctrl+C to cancel)" -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

foreach ($artist in $missing) {
    $searchQuery = [System.Web.HttpUtility]::UrlEncode("$artist south african artist photo")
    $url = "https://www.google.com/search?q=$searchQuery&tbm=isch"
    Start-Process $url
    Start-Sleep -Milliseconds 500  # Small delay between tabs
}

Write-Host ""
Write-Host "Done! Please download and save images with the correct filenames." -ForegroundColor Green

