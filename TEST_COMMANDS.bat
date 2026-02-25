@echo off
REM CoopCommerce Device Testing Commands
REM Run these commands to test your app

echo.
echo ========================================
echo COOP COMMERCE - DEVICE TEST COMMANDS
echo ========================================
echo.
echo Your device: 159863759V002387
echo App: CoopCommerce (com.cooperativenicorp.coopcommerce)
echo.
echo Choose an option:
echo.
echo 1. View Live Logs:
echo    adb logcat -s "flutter"
echo.
echo 2. View App-Specific Logs:
echo    adb logcat | find "coopcommerce"
echo.
echo 3. Take Screenshot:
echo    adb shell screencap -p /sdcard/screenshot.png
echo    adb pull /sdcard/screenshot.png
echo.
echo 4. View Device Info:
echo    adb shell getprop | find "model"
echo    adb shell getprop | find "version"
echo.
echo 5. Restart App:
echo    adb shell am force-stop com.cooperativenicorp.coopcommerce
echo    adb shell am start -n com.cooperativenicorp.coopcommerce/.MainActivity
echo.
echo 6. Clear App Data:
echo    adb shell pm clear com.cooperativenicorp.coopcommerce
echo.
echo 7. View Installed Packages:
echo    adb shell pm list packages | find "coop"
echo.
echo ========================================
echo TEST CHECKLIST:
echo ========================================
echo.
echo On your device, perform these tests:
echo [  ] 1. App launches without crashing
echo [  ] 2. Welcome/Login screen appears
echo [  ] 3. Can see buttons (can tap them)
echo [  ] 4. No white blank screens
echo [  ] 5. No red error dialogs
echo [  ] 6. Can navigate between screens
echo [  ] 7. Search/browse functions work
echo [  ] 8. No crashes in 5+ minutes of use
echo.
echo ========================================
echo NEXT STEPS:
echo ========================================
echo.
echo If app works:
echo   - Report back with results
echo   - We'll configure Flutterwave payment keys
echo   - Test payment processing
echo   - Prepare for PlayStore
echo.
echo If app crashes:
echo   - Run: adb logcat -s "flutter"   (to see errors)
echo   - Take screenshot of error
echo   - Report back
echo.
