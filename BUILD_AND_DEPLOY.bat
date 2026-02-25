@echo off
REM ============================================================================
REM Coop Commerce - Quick Build & Deploy Script
REM ============================================================================
REM This script automates the build and installation process
REM Make sure ADB is in your PATH and device is connected
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================================
echo  Coop Commerce v1.0.0 - MVP Build & Deploy
echo ============================================================================
echo.

REM Check if device is connected
echo [1/6] Checking device connection...
adb devices > nul 2>&1
if errorlevel 1 (
    echo ERROR: ADB not found or device not connected
    echo Please ensure:
    echo   1. Device is connected via USB
    echo   2. USB debugging is enabled
    echo   3. ADB is in your system PATH
    exit /b 1
)

REM Count connected devices
for /f %%A in ('adb devices ^| find /c /v ""') do set device_count=%%A
if !device_count! LEQ 1 (
    echo ERROR: No devices connected
    exit /b 1
)
echo ✓ Device detected

echo.
echo [2/6] Cleaning build cache...
call flutter clean > nul 2>&1
echo ✓ Build cache cleaned

echo.
echo [3/6] Getting dependencies...
call flutter pub get > nul 2>&1
echo ✓ Dependencies updated

echo.
echo [4/6] Building release APK...
echo    (This may take 3-5 minutes...)
call flutter build apk --release
if errorlevel 1 (
    echo ERROR: Build failed
    exit /b 1
)
echo ✓ APK built successfully

echo.
echo [5/6] Installing APK on device...
call adb uninstall com.cooperativenicorp.coopcommerce > nul 2>&1
call adb install -r build\app\outputs\flutter-apk\app-release.apk
if errorlevel 1 (
    echo ERROR: Installation failed
    exit /b 1
)
echo ✓ APK installed

echo.
echo [6/6] Launching app on device...
call adb shell am start -n "com.cooperativenicorp.coopcommerce/.MainActivity"
echo ✓ App launched

echo.
echo ============================================================================
echo  ✅ Build and deployment complete!
echo ============================================================================
echo.
echo The app should now be running on your device.
echo.
echo 🧪 TESTING INSTRUCTIONS:
echo.
echo 1. Tap the "Loyalty" card to test loyalty points screen
echo 2. Tap the "Delivery" card to test delivery tracking
echo 3. Tap the tier card to view full member tier information
echo 4. Check the timeline auto-progression (updates every 10 seconds)
echo 5. Verify animations and transitions are smooth
echo.
echo 📚 Full testing guide: MVP_FEATURE_TESTING_GUIDE.md
echo.
echo 💡 TROUBLESHOOTING:
echo.
echo If the app doesn't launch:
echo   - Check device is still connected: adb devices
echo   - Check USB debugging is enabled
echo   - Try manual uninstall: adb uninstall com.cooperativenicorp.coopcommerce
echo.
echo If build fails:
echo   - Make sure you're in the project root: c:\development\coop_commerce
echo   - Try manual clean: flutter clean
echo   - Check Android SDK is properly installed
echo.
echo Enjoy testing Coop Commerce MVP! 🎉
echo.
pause
