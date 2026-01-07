@echo off
REM Artist Images Batch Download Script
REM This script uses curl to download images from available sources

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ======================================
echo GEARSH Artist Image Batch Downloader
echo ======================================
echo.
echo Downloading images to: assets\images\artists\
echo.

REM Create artists directory if it doesn't exist
if not exist "assets\images\artists" mkdir "assets\images\artists"

REM Wikipedia images (reliable sources)
echo [1/5] Downloading from Wikipedia...

REM Tyla
curl -s -L "https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Tyla_%%28singer%%29.png/220px-Tyla_%%28singer%%29.png" -o "assets\images\artists\tyla_wiki.jpg" 2>nul

REM Master KG
curl -s -L "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Master_KG_by_Albert_Gonzalez.jpg/220px-Master_KG_by_Albert_Gonzalez.jpg" -o "assets\images\artists\masterkg_wiki.jpg" 2>nul

REM Nasty C
curl -s -L "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Nasty_C_at_MOBO_Awards_2019.png/220px-Nasty_C_at_MOBO_Awards_2019.png" -o "assets\images\artists\nastyc_wiki.jpg" 2>nul

REM Kelly Khumalo
curl -s -L "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Kelly_Khumalo_%%282019%%29.jpg/220px-Kelly_Khumalo_%%282019%%29.jpg" -o "assets\images\artists\kellykhumalo_wiki.jpg" 2>nul

REM DJ Zinhle
curl -s -L "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/DJ_Zinhle_%%28cropped%%29.jpg/220px-DJ_Zinhle_%%28cropped%%29.jpg" -o "assets\images\artists\djzinhle_wiki.jpg" 2>nul

REM Elaine
curl -s -L "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Elaine_Akinsooto.jpg/220px-Elaine_Akinsooto.jpg" -o "assets\images\artists\elaine_wiki.jpg" 2>nul

echo Done! Downloaded Wikipedia sources.
echo.
echo ======================================
echo IMPORTANT: MANUAL DOWNLOADS REQUIRED
echo ======================================
echo.
echo For remaining images, please:
echo 1. Run: search_artist_images.bat
echo 2. Download good quality images for each artist
echo 3. Resize to 400x400 pixels
echo 4. Save with correct filename to: assets\images\artists\
echo.
echo See ARTIST_IMAGES_STATUS.md for required filenames.
echo.
pause

