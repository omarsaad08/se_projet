#!/usr/bin/env powershell
# Firebase Deployment Script for Flutter Web App
# This script automates the build and deploy process

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Web App - Firebase Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
try {
    firebase --version | Out-Null
} catch {
    Write-Host "ERROR: Firebase CLI not found!" -ForegroundColor Red
    Write-Host "Please install it with: npm install -g firebase-tools" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Flutter is installed
try {
    flutter --version | Out-Null
} catch {
    Write-Host "ERROR: Flutter not found!" -ForegroundColor Red
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Change to project directory
Set-Location -Path $PSScriptRoot

Write-Host "Step 1: Cleaning Flutter project..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Getting dependencies failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 3: Building Flutter web app (Release mode)..." -ForegroundColor Cyan
flutter build web --release --minify
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter build failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 4: Deploying to Firebase Hosting..." -ForegroundColor Cyan
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Firebase deployment failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your app is now live on Firebase Hosting." -ForegroundColor Green
Write-Host "Check the console output above for your live URL." -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
