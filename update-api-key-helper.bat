@echo off
echo ========================================
echo   API Key Update Helper
echo ========================================
echo.
echo This script will help you update your API key
echo.
set /p APIKEY="Enter your new Google Maps API key: "
echo.
echo Updating files...
echo.

REM Note: This is a helper script
REM You still need to manually update these 3 files:
echo.
echo 1. backend\.env
echo    GOOGLE_MAPS_API_KEY=%APIKEY%
echo.
echo 2. web\index.html (line 36)
echo    ^<script src="https://maps.googleapis.com/maps/api/js?key=%APIKEY%"^>^</script^>
echo.
echo 3. android\app\src\main\AndroidManifest.xml (line 13)
echo    android:value="%APIKEY%"/^>
echo.
echo ========================================
echo After updating all 3 files:
echo 1. Restart backend: Ctrl+C, then npm start
echo 2. Restart Flutter: Ctrl+C, then flutter run
echo ========================================
echo.
pause
