@echo off
REM Firebase Deployment Script for Flutter Web App
REM This script automates the build and deploy process

echo.
echo ========================================
echo Flutter Web App - Firebase Deployment
echo ========================================
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Firebase CLI not found!
    echo Please install it with: npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found!
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Change to project directory
cd /d "%~dp0"

echo.
echo Step 1: Cleaning Flutter project...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Getting dependencies failed!
    pause
    exit /b 1
)

echo.
echo Step 3: Building Flutter web app (Release mode)...
call flutter build web --release --minify
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)

echo.
echo Step 4: Deploying to Firebase Hosting...
call firebase deploy --only hosting
if errorlevel 1 (
    echo ERROR: Firebase deployment failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deployment completed successfully!
echo ========================================
echo.
echo Your app is now live on Firebase Hosting.
echo Check the console output above for your live URL.
echo.
pause
