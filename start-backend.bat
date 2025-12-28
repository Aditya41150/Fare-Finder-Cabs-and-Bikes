@echo off
echo ========================================
echo   Fare Finder Backend Server
echo ========================================
echo.

cd backend

echo Checking if node_modules exists...
if not exist "node_modules\" (
    echo Installing dependencies...
    call npm install
) else (
    echo Dependencies already installed.
)

echo.
echo Starting server...
echo Server will run on http://localhost:3000
echo.
echo Press Ctrl+C to stop the server
echo.

call npm start
