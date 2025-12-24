@echo off
echo ==========================================
echo Getting SHA-1 Fingerprint for Google Sign-In
echo ==========================================
echo.

echo Method 1: Using Gradle
cd /d C:\Users\admin\StudioProjects\thegearsh.com\android
call gradlew.bat signingReport

echo.
echo ==========================================
echo.
echo Method 2: Using keytool (debug keystore)
echo.
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>nul

echo.
echo ==========================================
echo Copy the SHA1 fingerprint above and add it to:
echo Google Cloud Console -> APIs & Services -> Credentials
echo ==========================================
echo.
pause

