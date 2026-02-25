@echo off
REM Setup script for real-time sync components (Windows)
REM Run: scripts\setup_realtime.bat

setlocal enabledelayedexpansion

echo.
echo 🚀 Setting up Real-Time Sync Components
echo ========================================

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ⚠️  Firebase CLI not found. Installing...
    npm install -g firebase-tools
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ❌ ERROR: Flutter not found. Please install Flutter first.
    pause
    exit /b 1
)

REM Step 1: Install dependencies
echo.
echo Step 1: Installing Node dependencies...
call npm install
if errorlevel 1 (
    echo ❌ npm install failed
    pause
    exit /b 1
)

REM Step 2: Ask about function deployment
echo.
echo Step 2: Deploying Cloud Functions
set /p deploy_functions="Deploy functions to Firebase? (y/n): "
if /i "%deploy_functions%"=="y" (
    cd functions
    call npm install
    call firebase deploy --only functions
    cd ..
    echo ✓ Functions deployed
) else (
    echo ⊘ Skipped function deployment
)

REM Step 3: Verify Flutter dependencies
echo.
echo Step 3: Verifying Flutter dependencies...
call flutter pub get
echo ✓ Flutter dependencies installed

REM Step 4: Ask about test data
echo.
echo Step 4: Setup test data
set /p create_test="Create load test data in Firestore? (y/n): "
if /i "%create_test%"=="y" (
    call node scripts\setup_test_data.js
    echo ✓ Test data created
) else (
    echo ⊘ Skipped test data creation
)

REM Step 5: Configuration
echo.
echo Step 5: Configuration
REM Get first Firebase project
for /f "tokens=1" %%i in ('firebase projects:list 2^>nul') do (
    set "PROJECT_ID=%%i"
    goto :found_project
)
:found_project

(
echo # Real-Time Sync Configuration
echo FIREBASE_PROJECT_ID=%PROJECT_ID%
echo LOAD_TEST_CONCURRENT_USERS=100
echo LOAD_TEST_DURATION_MINUTES=5
echo LOAD_TEST_UPDATE_INTERVAL_MS=2000
) > .env.local

echo ✓ Configuration created (.env.local^)

REM Final summary
echo.
echo ✅ Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Run the app:        flutter run
echo 2. Test load testing:  npm run load-test
echo 3. View functions log: firebase functions:log
echo 4. Read guide:         LOAD_TESTING_GUIDE.md
echo.
echo For more info, see: REALTIME_SYNC_COMPLETE.md
echo.

pause
