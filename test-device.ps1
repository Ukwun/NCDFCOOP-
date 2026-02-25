#!/usr/bin/env pwsh
# CoopCommerce Automated Device Testing Script

param([string]$DeviceId, [switch]$SkipInstall)

$APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"
$APP_ID = "com.cooperativenicorp.coopcommerce"

# Functions
function Write-Header([string]$Text) { Write-Host ""; Write-Host "=== $Text ===" -ForegroundColor Cyan }
function Write-Section([string]$Text) { Write-Host ""; Write-Host "> $Text" -ForegroundColor Cyan }
function Write-Success([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Error([string]$Text) { Write-Host "  [ERROR] $Text" -ForegroundColor Red }
function Write-Warning([string]$Text) { Write-Host "  [WARN] $Text" -ForegroundColor Yellow }
function Write-Info([string]$Text) { Write-Host "  [INFO] $Text" }

Write-Header "COOP COMMERCE - DEVICE TESTING"

# Step 1: Check device
Write-Section "Step 1: Checking Android Device"
$devices = adb devices | Select-Object -Skip 1 | Where-Object { $_.Trim() -and -not $_.Contains("offline") }

if ($devices.Count -eq 0) {
    Write-Error "No Android devices found!"
    Write-Info "Please connect your device via USB and enable USB debugging"
    exit 1
}

$Device = if ($DeviceId) { 
    ($devices | Where-Object { $_ -match $DeviceId }).Split()[0] 
} else { 
    $devices[0].Split()[0] 
}

Write-Success "Device found: $Device"

# Get device info
$osVersion = adb -s $Device shell getprop ro.build.version.release
$model = adb -s $Device shell getprop ro.product.model
Write-Info "Model: $model, Android: $osVersion"

# Step 2: Verify APK
Write-Section "Step 2: Checking APK File"
if (-not (Test-Path $APK_PATH)) {
    Write-Error "APK not found at: $APK_PATH"
    exit 1
}
$apkSize = [math]::Round((Get-Item $APK_PATH).Length / 1MB, 2)
Write-Success "APK found: $apkSize MB"

# Step 3: Install APK
if (-not $SkipInstall) {
    Write-Section "Step 3: Installing APK"
    
    # Uninstall old version
    $existing = adb -s $Device shell pm list packages | Select-String $APP_ID
    if ($existing) {
        Write-Info "Removing old version..."
        adb -s $Device uninstall $APP_ID | Out-Null
    }
    
    # Install new version
    Write-Info "Installing app..."
    $result = adb -s $Device install -r $APK_PATH
    
    if ($result -match "Success") {
        Write-Success "Installation successful"
        
        # Clear data for fresh start
        Write-Info "Clearing app data..."
        adb -s $Device shell pm clear $APP_ID 2>$null
    } else {
        Write-Error "Installation failed: $result"
        exit 1
    }
}

# Step 4: Launch app
Write-Section "Step 4: Launching Application"
Write-Info "Starting app..."
adb -s $Device shell am start -n "$APP_ID/.MainActivity" | Out-Null
Start-Sleep -Seconds 2

Write-Success "App should now be running on your device!"

# Step 5: Capture logs
Write-Section "Step 5: Collecting Logs"
$logFile = "test-logs-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

Write-Info "Gathering device logs (this may take a moment)..."
$logs = adb -s $Device logcat -d | Select-String -Pattern "flutter|coopcommerce|error|exception|crash" | Select-Object -First 100

if ($logs) {
    Write-Warning "Found potential issues in logs:"
    $logs | Out-File $logFile
    Write-Success "Logs saved to: $logFile"
} else {
    Write-Success "No errors found in logs"
}

# Step 6: Interactive testing menu
Write-Header "DEVICE TESTING MENU"

while ($true) {
    Write-Host ""
    Write-Host "What would you like to do?"
    Write-Host "  1) Watch live logs (Ctrl+C to exit)"
    Write-Host "  2) Take screenshot"
    Write-Host "  3) Restart app"
    Write-Host "  4) View device info"
    Write-Host "  5) Exit and move to next phase"
    Write-Host ""
    
    $choice = Read-Host "Select (1-5)"
    
    switch ($choice) {
        "1" {
            Write-Section "Live Logs (Press Ctrl+C to stop)"
            adb -s $Device logcat -s "flutter" "*:V" 2>$null
        }
        "2" {
            Write-Info "Taking screenshot..."
            $screenshot = "screenshot-$(Get-Date -Format 'yyyyMMdd-HHmmss').png"
            adb -s $Device shell screencap -p "/sdcard/$screenshot" 2>$null
            adb -s $Device pull "/sdcard/$screenshot" . 2>$null
            if (Test-Path $screenshot) {
                Write-Success "Screenshot saved: $screenshot"
            } else {
                Write-Warning "Screenshot may have failed"
            }
        }
        "3" {
            Write-Info "Restarting app..."
            adb -s $Device shell am force-stop $APP_ID
            adb -s $Device shell am start -n "$APP_ID/.MainActivity" | Out-Null
            Write-Success "App restarted"
        }
        "4" {
            Write-Section "Device Information"
            Write-Host ""
            $info = adb -s $Device shell "getprop" | Select-String -Pattern "version|model|device" | Select-Object -First 10
            $info | ForEach-Object { Write-Info $_ }
        }
        "5" {
            Write-Success "Exiting test menu..."
            break
        }
        default {
            Write-Warning "Invalid selection"
        }
    }
}

# Final summary
Write-Header "TEST SUMMARY"
Write-Success "APK: $apkSize MB"
Write-Success "Device: $Device"
Write-Success "App ID: $APP_ID"
Write-Success "Installed and launched successfully!"
Write-Host ""
Write-Host "NEXT: Manually test these flows on your device:"
Write-Host "  1. Sign In / Sign Up"
Write-Host "  2. Browse Products"
Write-Host "  3. Add to Cart"
Write-Host "  4. Navigation"
Write-Host ""
Write-Host "Check DEVICE_TESTING_GUIDE.txt for detailed test procedures."
Write-Host ""
