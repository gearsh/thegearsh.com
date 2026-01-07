@echo off
REM Quick Reference Card - Artist Image Download
REM Display this when user runs the file

cls
color 0A
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║           GEARSH ARTIST IMAGE DOWNLOAD - QUICK START           ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 📊 STATUS:
echo    • Total Artists: 100
echo    • Already Have: 15 ✅
echo    • Still Need: 85 ⏳
echo.
echo 🚀 HOW TO DOWNLOAD (Pick ONE):
echo.
echo   OPTION 1 - EASIEST (Recommended)
echo   ─────────────────────────────────
echo   → Open file: artist_downloader.html
echo   → Use web interface to find and download
echo   → Takes: ~2-3 hours manually
echo.
echo   OPTION 2 - FASTER (Batch Mode)
echo   ──────────────────────────────
echo   → Run: search_artist_images.bat
echo   → Opens 80+ Google search tabs
echo   → Download in parallel
echo   → Takes: ~1-2 hours
echo.
echo   OPTION 3 - AUTOMATED (PowerShell)
echo   ─────────────────────────────────
echo   → Run: powershell -File Download-ArtistImages.ps1
echo   → Attempts auto-download from Wikipedia
echo   → Falls back to manual
echo   → Takes: ~30 min + manual for rest
echo.
echo   OPTION 4 - PYTHON (For developers)
echo   ───────────────────────────────────
echo   → Run: python download_images.py
echo   → Advanced downloading with PIL
echo   → Requires Python 3.x
echo.
echo 📝 REQUIREMENTS:
echo    • Image size: 400x400 pixels (square)
echo    • Format: JPG or PNG (WebP ok)
echo    • Save to: assets\images\artists\
echo    • Use EXACT filenames from guide
echo.
echo 📁 WHERE TO FIND THINGS:
echo.
echo    📖 Documentation:
echo       • SETUP_COMPLETE.md ........... Full overview
echo       • DOWNLOAD_GUIDE.md .......... Step-by-step
echo       • ARTIST_IMAGES_STATUS.md ... Complete list
echo.
echo    🛠️  Download Tools:
echo       • artist_downloader.html .... Web interface
echo       • search_artist_images.bat .. Batch opener
echo       • Download-ArtistImages.ps1  PowerShell
echo       • download_images.py ........ Python
echo.
echo    🔧 Utilities:
echo       • resize_images.py .......... Batch resizer
echo       • batch_download_images.bat  Alternative
echo.
echo ⚡ QUICK TIPS:
echo.
echo    ✓ Search: artist + "official photo" for best results
echo    ✓ Instagram: Check official artist accounts
echo    ✓ Wikipedia: High quality press photos
echo    ✓ YouTube: Video thumbnails work too
echo    ✓ Batch resize: python resize_images.py
echo.
echo 📌 NEXT STEPS:
echo.
echo    1. Choose download method above (Option 1 recommended)
echo    2. Download 85 remaining artist images
echo    3. Save with CORRECT filenames
echo    4. Verify all files in: assets\images\artists\
echo    5. Rebuild app: flutter run
echo.
echo ════════════════════════════════════════════════════════════════
echo.
echo 🌐 For web interface, open: artist_downloader.html
echo 📚 For full guide, read: SETUP_COMPLETE.md
echo.
pause

