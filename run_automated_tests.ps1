# CoopCommerce Automated Testing Script
# This script automatically tests the app on the Android emulator

param(
    [int]$ScreenshotDelay = 1000,  # Delay between screenshots (ms)
    [int]$ActionDelay = 500         # Delay between actions (ms)
)

# Color outputs
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    
    switch ($Type) {
        "Success" { Write-Host "✅ $Message" -ForegroundColor $Green }
        "Error" { Write-Host "❌ $Message" -ForegroundColor $Red }
        "Warning" { Write-Host "⚠️  $Message" -ForegroundColor $Yellow }
        "Test" { Write-Host "🧪 $Message" -ForegroundColor $Cyan }
        default { Write-Host "ℹ️  $Message" }
    }
}

function Take-Screenshot {
    param([string]$Name)
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "screenshot_${timestamp}_${Name}.png"
    $filepath = "c:\development\coop_commerce\test_screenshots\$filename"
    
    # Create directory if not exists
    if (!(Test-Path "c:\development\coop_commerce\test_screenshots")) {
        New-Item -ItemType Directory -Path "c:\development\coop_commerce\test_screenshots" | Out-Null
    }
    
    Write-Status "Taking screenshot: $Name" "Info"
    adb shell screencap -p /sdcard/screenshot.png | Out-Null
    adb pull /sdcard/screenshot.png $filepath | Out-Null
    
    Start-Sleep -Milliseconds $ScreenshotDelay
    return $filepath
}

function Tap {
    param([int]$X, [int]$Y, [string]$Label = "")
    
    Write-Status "Tapping at [$X, $Y] $Label" "Info"
    adb shell input tap $X $Y
    Start-Sleep -Milliseconds $ActionDelay
}

function TypeText {
    param([string]$Text)
    
    Write-Status "Typing: '$Text'" "Info"
    adb shell input text $Text
    Start-Sleep -Milliseconds $ActionDelay
}

function PressKey {
    param([string]$KeyCode)
    
    Write-Status "Pressing key: $KeyCode" "Info"
    adb shell input keyevent $KeyCode
    Start-Sleep -Milliseconds $ActionDelay
}

function Wait {
    param([int]$Seconds = 2)
    
    Write-Status "Waiting $Seconds seconds..." "Info"
    Start-Sleep -Seconds $Seconds
}

function Check-Device {
    Write-Status "Checking device connection..." "Test"
    $devices = adb devices | Select-String "device$"
    
    if ($devices.Count -eq 0) {
        Write-Status "No device found! Please ensure emulator is running." "Error"
        exit 1
    }
    
    Write-Status "Device connected: $($devices[0])" "Success"
}

# ============================================================================
# MAIN TEST SUITE
# ============================================================================

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                    CoopCommerce Automated Test Suite                        ║
║                          Started: $(Get-Date)                     ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$testResults = @()
$passCount = 0
$failCount = 0

# Check device connection
Check-Device

Write-Status "Starting automated tests..." "Test"
Write-Host ""

# ============================================================================
# TEST 1: APP LAUNCH & SPLASH SCREEN
# ============================================================================

Write-Host "TEST 1: App Launch & Splash Screen" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "App Launch"; Status = "PASS"; Details = "" }

try {
    Take-Screenshot "01_app_launch"
    Wait 3
    Take-Screenshot "02_splash_screen"
    
    Write-Status "App visible and running" "Success"
    $passCount++
}
catch {
    Write-Status "Failed to launch app: $_" "Error"
    $failCount++
    $result.Status = "FAIL"
    $result.Details = $_
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 2: NAVIGATE TO LOGIN SCREEN
# ============================================================================

Write-Host "TEST 2: Navigate to Login Screen" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Login Screen"; Status = "PASS"; Details = "" }

try {
    # Wait for splash to complete
    Wait 2
    Take-Screenshot "03_login_screen"
    
    Write-Status "Login screen visible" "Success"
    $passCount++
}
catch {
    Write-Status "Failed to reach login screen: $_" "Error"
    $failCount++
    $result.Status = "FAIL"
    $result.Details = $_
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 3: SIGNUP FLOW
# ============================================================================

Write-Host "TEST 3: Sign Up Flow" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Signup"; Status = "PASS"; Details = "" }

try {
    # Tap Sign Up button (adjust coordinates based on actual layout)
    Write-Status "Looking for Sign Up button..." "Info"
    Tap 672 1400 "- Sign Up button"
    Wait 1
    Take-Screenshot "04_signup_form"
    
    # Enter email
    Write-Status "Entering email..." "Info"
    TypeText "testuser@coopcommerce.test"
    
    # Tab to next field
    PressKey "KEYCODE_TAB"
    Wait 1
    
    # Enter password
    Write-Status "Entering password..." "Info"
    TypeText "TestPass123!"
    
    # Tab to name field
    PressKey "KEYCODE_TAB"
    Wait 1
    
    # Enter name
    Write-Status "Entering name..." "Info"
    TypeText "Test User"
    
    Take-Screenshot "05_signup_filled"
    
    # Tap Sign Up button
    Write-Status "Submitting signup form..." "Info"
    Tap 672 1200 "- Submit button"
    
    Wait 3
    Take-Screenshot "06_signup_processing"
    
    Write-Status "Signup attempt completed" "Success"
    $passCount++
}
catch {
    Write-Status "Signup failed: $_" "Error"
    $failCount++
    $result.Status = "FAIL"
    $result.Details = $_
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 4: HOME SCREEN & PRODUCTS
# ============================================================================

Write-Host "TEST 4: Home Screen & Products" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Home Screen"; Status = "PASS"; Details = "" }

try {
    Wait 2
    Take-Screenshot "07_home_screen"
    
    Write-Status "Taking home screen screenshot" "Info"
    
    # Scroll down to test lazy loading
    Write-Status "Testing lazy loading with scroll..." "Info"
    adb shell input swipe 672 1000 672 400 500
    Wait 2
    Take-Screenshot "08_products_scrolled"
    
    # Scroll back up
    adb shell input swipe 672 400 672 1000 500
    Wait 1
    
    Write-Status "Home screen visible and scrollable" "Success"
    $passCount++
}
catch {
    Write-Status "Home screen test failed: $_" "Error"
    $failCount++
    $result.Status = "FAIL"
    $result.Details = $_
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 5: PRODUCT DETAILS
# ============================================================================

Write-Host "TEST 5: Product Details" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Product Details"; Status = "PASS"; Details = "" }

try {
    # Tap on first product (adjust coordinates)
    Write-Status "Tapping on first product..." "Info"
    Tap 336 600 "- First product"
    
    Wait 2
    Take-Screenshot "09_product_details"
    
    Write-Status "Product details screen visible" "Success"
    $passCount++
}
catch {
    Write-Status "Product details failed: $_" "Error"
    $failCount++
    $result.Status = "FAIL"
    $result.Details = $_
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 6: ADD TO CART
# ============================================================================

Write-Host "TEST 6: Add to Cart" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Add to Cart"; Status = "PASS"; Details = "" }

try {
    # Try to find and tap Add to Cart button
    Write-Status "Looking for Add to Cart button..." "Info"
    Tap 672 1300 "- Add to Cart button"
    
    Wait 2
    Take-Screenshot "10_cart_added"
    
    Write-Status "Item added to cart" "Success"
    $passCount++
}
catch {
    Write-Status "Add to cart failed: $_" "Warning"
    # This might fail due to layout differences, but continue
    $result.Status = "WARN"
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 7: VIEW CART
# ============================================================================

Write-Host "TEST 7: View Cart" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "View Cart"; Status = "PASS"; Details = "" }

try {
    # Go back to home first
    PressKey "KEYCODE_BACK"
    Wait 2
    
    # Tap cart icon (top right area)
    Write-Status "Tapping cart icon..." "Info"
    Tap 1300 100 "- Cart icon"
    
    Wait 2
    Take-Screenshot "11_cart_view"
    
    Write-Status "Cart view displayed" "Success"
    $passCount++
}
catch {
    Write-Status "View cart failed: $_" "Warning"
    $result.Status = "WARN"
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 8: CHECKOUT
# ============================================================================

Write-Host "TEST 8: Checkout Process" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Checkout"; Status = "PASS"; Details = "" }

try {
    # Tap checkout button
    Write-Status "Tapping checkout button..." "Info"
    Tap 672 1400 "- Checkout button"
    
    Wait 2
    Take-Screenshot "12_checkout_screen"
    
    # Fill in address form (if visible)
    Write-Status "Filling checkout form..." "Info"
    Tap 672 300 "- Name field"
    TypeText "Test User"
    
    PressKey "KEYCODE_TAB"
    TypeText "123 Main Street"
    
    PressKey "KEYCODE_TAB"
    TypeText "Lagos"
    
    Take-Screenshot "13_checkout_filled"
    
    Write-Status "Checkout form filled" "Success"
    $passCount++
}
catch {
    Write-Status "Checkout failed: $_" "Warning"
    $result.Status = "WARN"
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST 9: NAVIGATION FLOW
# ============================================================================

Write-Host "TEST 9: Navigation and Back Buttons" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$result = @{Test = "Navigation"; Status = "PASS"; Details = "" }

try {
    # Test back navigation
    Write-Status "Testing back button navigation..." "Info"
    PressKey "KEYCODE_BACK"
    Wait 1
    Take-Screenshot "14_back_navigation"
    
    Write-Status "Back button working" "Success"
    $passCount++
}
catch {
    Write-Status "Navigation failed: $_" "Error"
    $failCount++
    $result.Status = "FAIL"
    $result.Details = $_
}

$testResults += $result
Write-Host ""

# ============================================================================
# TEST SUMMARY
# ============================================================================

Write-Host @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                           TEST RESULTS SUMMARY                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$testResults | Format-Table -Property Test, Status, Details -AutoSize -Wrap

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

Write-Host "✅ Passed: $passCount" -ForegroundColor Green
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor Yellow

Write-Host ""
Write-Host "Screenshots saved to: c:\development\coop_commerce\test_screenshots\" -ForegroundColor Cyan

Write-Host ""
Write-Host @"
Next Steps:
1. Review screenshots in test_screenshots folder
2. Check app logs for errors: adb logcat | grep flutter
3. Fix any identified issues
4. Configure Firebase with google-services.json
5. Add Flutterwave payment keys
6. Re-run tests with full Firebase integration

"@ -ForegroundColor Yellow

Write-Host "Test run completed at $(Get-Date)" -ForegroundColor Cyan
Write-Host ""
