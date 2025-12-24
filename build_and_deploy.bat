@echo off
setlocal enabledelayedexpansion
echo.
echo ========================================
echo    GEARSH WEB BUILD AND DEPLOY
echo    Mobile-Optimized Progressive Web App
echo ========================================
echo.

cd /d C:\Users\admin\StudioProjects\thegearsh.com

echo [1/6] Cleaning project...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)
echo      Done!
echo.

echo [2/6] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)
echo      Done!
echo.

echo [3/6] Building web app (release mode)...
call flutter build web --release --web-renderer canvaskit --pwa-strategy offline-first
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)
echo      Done!
echo.

if not exist "build\web\main.dart.js" (
    echo ERROR: Build output not found!
    pause
    exit /b 1
)

echo [4/6] Copying build files to web folder...
:: Copy main files
copy /Y "build\web\flutter.js" "web\" >nul 2>&1
copy /Y "build\web\flutter_bootstrap.js" "web\" >nul 2>&1
copy /Y "build\web\flutter_service_worker.js" "web\" >nul 2>&1
copy /Y "build\web\main.dart.js" "web\" >nul 2>&1
copy /Y "build\web\version.json" "web\" >nul 2>&1

:: Copy directories
xcopy /E /Y /I /Q "build\web\assets" "web\assets" >nul 2>&1
xcopy /E /Y /I /Q "build\web\canvaskit" "web\canvaskit" >nul 2>&1
xcopy /E /Y /I /Q "build\web\icons" "web\icons" >nul 2>&1

echo      Done!
echo.

echo [5/6] Deploying to Cloudflare Pages...
cd web
call npx wrangler pages deploy . --project-name=thegearsh-com
if errorlevel 1 (
    echo ERROR: Deployment failed!
    cd ..
    pause
    exit /b 1
)
cd ..
echo      Done!
echo.

echo ========================================
echo    DEPLOYMENT SUCCESSFUL!
echo ========================================
echo.
echo Your app is now live at:
echo   https://thegearsh-com.pages.dev
echo.
echo The web app now mirrors the Android app
echo and is optimized for all mobile devices.
echo.
pause

