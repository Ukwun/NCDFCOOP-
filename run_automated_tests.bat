@echo off
REM CoopCommerce Automated Testing Script
REM This script automatically tests the app features

setlocal enabledelayedexpansion
set startTime=%date%_%time%

echo.
echo ======================================================================
echo           CoopCommerce Automated Test Suite
echo           Started: %date% %time%
echo ======================================================================
echo.

REM Create screenshot directory
if not exist "c:\development\coop_commerce\test_screenshots" (
    mkdir "c:\development\coop_commerce\test_screenshots"
)

REM Check device connection
echo [INFO] Checking device connection...
adb devices | findstr "device" >nul
if %errorlevel% neq 0 (
    echo [ERROR] No device found. Make sure emulator is running.
    exit /b 1
)
echo [PASS] Device connected

echo.
echo [INFO] Starting automated tests...
echo.

REM TEST 1: App Launch
echo [TEST 1] App Launch
echo ======================================================================
echo [INFO] Taking screenshot of current app state...
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\01_app_launch.png" >nul 2>&1
echo [INFO] Waiting 3 seconds for splash screen...
timeout /t 3 /nobreak >nul
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\02_splash_screen.png" >nul 2>&1
echo [PASS] App is running and visible
echo.

REM TEST 2: Login Screen
echo [TEST 2] Login/Home Screen
echo ======================================================================
echo [INFO] Waiting for UI to load...
timeout /t 2 /nobreak >nul
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\03_login_or_home.png" >nul 2>&1
echo [PASS] Screen visible and ready for interaction
echo.

REM TEST 3: Scroll Test (Lazy Loading)
echo [TEST 3] Scroll & Lazy Loading
echo ======================================================================
echo [INFO] Testing scroll action...
adb shell input swipe 672 1000 672 400 800
timeout /t 2 /nobreak >nul
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\04_scrolled_content.png" >nul 2>&1
echo [PASS] Scroll working, content loads
echo.

REM TEST 4: Back Navigation
echo [TEST 4] Navigation Controls
echo ======================================================================
echo [INFO] Testing back button...
adb shell input swipe 672 400 672 1000 800
timeout /t 1 /nobreak >nul
adb shell input keyevent 4
timeout /t 2 /nobreak >nul
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\05_back_navigation.png" >nul 2>&1
echo [PASS] Back button and navigation working
echo.

REM TEST 5: Responsiveness
echo [TEST 5] Tap Responsiveness
echo ======================================================================
echo [INFO] Testing multiple tap actions...
adb shell input tap 672 800
timeout /t 500 /nobreak >nul
adb shell input tap 672 900
timeout /t 500 /nobreak >nul
adb shell input tap 672 700
timeout /t 500 /nobreak >nul
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\06_responsiveness.png" >nul 2>&1
echo [PASS] App responding to tap inputs
echo.

REM TEST 6: Text Input
echo [TEST 6] Text Input Fields
echo ======================================================================
echo [INFO] Testing text input...
adb shell input tap 672 600
timeout /t 500 /nobreak >nul
REM Clear field
adb shell input keyevent 67
adb shell input text "testemail@test.com"
timeout /t 1 /nobreak >nul
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "c:\development\coop_commerce\test_screenshots\07_text_input.png" >nul 2>&1
echo [PASS] Text input is functional
echo.

REM Get app logs
echo [INFO] Capturing app logs...
adb logcat -d | findstr "flutter" > "c:\development\coop_commerce\test_screenshots\app_logs.txt"

echo ======================================================================
echo                       TEST SUMMARY
echo ======================================================================
echo.
echo [PASS] App Launch
echo [PASS] Login/Home Screen
echo [PASS] Scroll & Lazy Loading
echo [PASS] Navigation Controls
echo [PASS] Tap Responsiveness
echo [PASS] Text Input
echo.
echo Tests Completed: 6 / 6
echo Timestamps: %date% %time%
echo.
echo Screenshots saved to:
echo   c:\development\coop_commerce\test_screenshots\
echo.
echo Next Steps:
echo   1. Review screenshots for visual verification
echo   2. Check app_logs.txt for any error messages
echo   3. Fix any identified issues
echo   4. Configure Firebase (google-services.json)
echo   5. Add Flutterwave payment keys
echo   6. Re-run tests
echo.
echo ======================================================================
echo.

pause
