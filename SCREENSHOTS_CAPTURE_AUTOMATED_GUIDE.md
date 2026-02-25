# 📱 AUTOMATED SCREENSHOT CAPTURE GUIDE

**Status:** Ready to capture  
**Required:** Android emulator or physical device  
**Time:** 30-45 minutes  
**Output:** 8 professional screenshots (1080x1920px)

---

## 🎯 QUICK START (5 minutes)

### Option A: Physical Android Device (RECOMMENDED)
```powershell
# 1. Connect phone via USB
# 2. Enable USB debugging (Settings > Developer Options)

# 3. Start the app
flutter run --release

# 4. Take screenshots using device hardware buttons
# Hold: Power button + Volume Down (3 seconds)
# Saves to: Gallery > Screenshots

# 5. Transfer to computer
adb pull /sdcard/DCIM/Screenshots/ ./screenshots/
```

### Option B: Android Emulator (EASIEST)
```powershell
# 1. Ensure emulator is running
# 2. Start the app
flutter run --release

# 3. Screenshot button in emulator UI (keyboard shortcut)
# Windows/Mac: Ctrl+S (emulator takes screenshot)
# Saves to: User/AppData/Local/Temp/

# 4. Or use adb
adb shell screencap -p /sdcard/screenshot1.png
adb pull /sdcard/screenshot1.png ./screenshots/
```

### Option C: VSCode DevTools (EASIEST)
```powershell
# 1. Start app with: flutter run --release
# 2. In VS Code terminal, click "open DevTools"
# 3. Click "Screenshot" button in top right
# 4. File saves automatically to: project/test_reports/
```

---

## 📋 SCREENSHOTS TO CAPTURE (In This Order)

### Screenshot 1: Welcome/Login Screen
**Purpose:** First impression  
**Show:** App name, logo, login options

**Steps:**
1. Kill app completely (force stop)
2. Open app fresh
3. Take screenshot of login screen
4. **Important:** Make sure email/password fields are visible

**File:** `1_welcome_login.jpg`

---

### Screenshot 2: Home Page (Product Grid)
**Purpose:** Show main feature  
**Show:** Product list, featured items, search bar

**Steps:**
1. Login with test account
2. Navigate to home page
3. Make sure products are loaded (not blank)
4. Scroll to show variety of products
5. Take screenshot of grid layout

**File:** `2_home_products.jpg`

---

### Screenshot 3: Product Search/Browse
**Purpose:** Show discovery feature  
**Show:** Search bar, category filters, sorting

**Steps:**
1. Tap on search/browse section
2. Type a product name (e.g., "electronics")
3. Show filter options
4. Take screenshot with results visible

**File:** `3_product_search.jpg`

---

### Screenshot 4: Product Details Page
**Purpose:** Show product info  
**Show:** Product image, price, description, reviews, "Add to Cart"

**Steps:**
1. Tap on any product
2. Expand description
3. Scroll to see reviews
4. Make sure "Add to Cart" button is visible
5. Take screenshot

**File:** `4_product_details.jpg`

---

### Screenshot 5: Shopping Cart
**Purpose:** Show checkout flow  
**Show:** Items in cart, quantities, total price, checkout button

**Steps:**
1. Add 2-3 products to cart
2. Open shopping cart
3. Verify items, quantities, subtotal visible
4. Show "Proceed to Checkout" button
5. Take screenshot

**File:** `5_shopping_cart.jpg`

---

### Screenshot 6: Dark Mode (Settings)
**Purpose:** Highlight dark mode feature  
**Show:** Settings screen with dark mode toggle ON, app in dark theme

**Steps:**
1. Navigate to Settings
2. Find "Dark Mode" toggle
3. Turn it ON
4. Wait for app to refresh
5. Go back to home page (should be dark)
6. Take screenshot showing dark theme

**File:** `6_dark_mode_enabled.jpg`

---

### Screenshot 7: Order Confirmation
**Purpose:** Show successful purchase  
**Show:** Order confirmation, order number, delivery info

**Steps:**
1. From cart, proceed to checkout
2. Enter test payment info (use Flutterwave test card)
3. Test card: 4111111111111111 (expiry: any future date, CVV: any 3 digits)
4. Place order
5. Take screenshot of confirmation page

**File:** `7_order_confirmation.jpg`

---

### Screenshot 8: User Profile
**Purpose:** Show account features  
**Show:** Profile info, order history, account settings, logout

**Steps:**
1. Tap on profile/account section
2. Scroll to show multiple features:
   - User name/email
   - Order history
   - Saved addresses
   - Preferences
3. Take screenshot

**File:** `8_user_profile.jpg`

---

## 🔧 AUTOMATED BATCH CAPTURE (Using ADB Script)

Create file: `capture_screenshots.ps1`

```powershell
# Automated screenshot capture script
# Usage: .\capture_screenshots.ps1

param(
    [string]$DeviceId = "",
    [int]$Count = 8
)

# Create output directory
if (!(Test-Path "screenshots")) {
    New-Item -ItemType Directory -Name "screenshots" | Out-Null
}

Write-Host "📱 Starting screenshot capture..."
Write-Host "Device ID: $DeviceId"
Write-Host "Screenshots: $Count"
Write-Host ""

# Get list of connected devices if not specified
if ([string]::IsNullOrEmpty($DeviceId)) {
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
    if ($devices.Count -eq 0) {
        Write-Host "❌ No devices found! Connect a device and try again."
        exit 1
    }
    $DeviceId = ($devices[0] -split "`t")[0]
    Write-Host "Using device: $DeviceId"
}

# Capture screenshots
for ($i = 1; $i -le $Count; $i++) {
    Write-Host ""
    Write-Host "📸 Screenshot $i/$Count"
    Write-Host "Press ENTER when ready to capture..." -ForegroundColor Yellow
    Read-Host
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "screenshot_${i}_${timestamp}.png"
    
    # Capture screenshot
    adb -s $DeviceId shell screencap -p /sdcard/$filename
    
    # Pull from device
    adb -s $DeviceId pull /sdcard/$filename "./screenshots/$filename"
    
    # Clean up device
    adb -s $DeviceId shell rm /sdcard/$filename
    
    Write-Host "✅ Saved: ./screenshots/$filename" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ All screenshots captured!" -ForegroundColor Green
Write-Host "Location: ./screenshots/"
```

**Run it:**
```powershell
.\capture_screenshots.ps1
```

---

## 📐 OPTIMIZE SCREENSHOTS FOR PLAY STORE

### Resize Images to Exact 1080x1920px
```powershell
# Using ImageMagick (install if needed)
choco install imagemagick

# Batch resize all screenshots
Get-ChildItem screenshots/*.png | ForEach-Object {
    magick $_.FullName -resize 1080x1920 -gravity center -background white -extent 1080x1920 $_.DirectoryName/$_.BaseName"_optimized.jpg"
}

# Or use this PowerShell script
$screenshots = Get-ChildItem "screenshots" -Filter "*.png"
foreach ($file in $screenshots) {
    # Convert to JPG and optimize
    magick $file.FullName -quality 85 -resize 1080x1920 -background white -gravity center -extent 1080x1920 ("screenshots\optimized_" + $file.BaseName + ".jpg")
}
```

### Check File Sizes
```powershell
# Verify all images are under 2MB each
Get-ChildItem "screenshots" -Filter "*.jpg" | ForEach-Object {
    $sizeMB = $_.Length / 1MB
    Write-Host "$($_.Name): $($sizeMB.ToString('F2')) MB"
}

# Total size
$total = (Get-ChildItem "screenshots" -Filter "*.jpg" | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host ""
Write-Host "Total size: $($total.ToString('F2')) MB (max 16MB for 8 images)"
```

---

## 🎨 SCREENSHOT BEST PRACTICES

### ✅ DO
- ✅ Show real app data (actual products, prices)
- ✅ Highlight unique features (dark mode, personalization)
- ✅ Make text clearly readable
- ✅ Use consistent branding (app colors, logo)
- ✅ Show completed flows (cart → checkout → confirmation)
- ✅ Include calls-to-action (buttons, next steps)

### ❌ DON'T
- ❌ Include personal information (real names, addresses)
- ❌ Show test data (dummy accounts, fake prices)
- ❌ Use placeholder images
- ❌ Include device notifications or status bar content
- ❌ Show error messages or crashes
- ❌ Mix different devices (consistency matters)

---

## 🖼️ ORGANIZE OUTPUT FOLDER

**Final structure:**
```
Screenshots_PlayStore/
├── 1_welcome_login.jpg ..................... Login screen
├── 2_home_products.jpg .................... Home page with product grid
├── 3_product_search.jpg ................... Product search with filters
├── 4_product_details.jpg .................. Product info page
├── 5_shopping_cart.jpg .................... Cart ready for checkout
├── 6_dark_mode_enabled.jpg ................ Settings in dark mode
├── 7_order_confirmation.jpg ............... Order success screen
└── 8_user_profile.jpg ..................... Profile & account page
```

**Verify:**
```powershell
# List screenshots
Get-ChildItem "Screenshots_PlayStore" | Format-Table Name, Length

# Check all 8 exist
$count = (Get-ChildItem "Screenshots_PlayStore" -Filter "*.jpg" | Measure-Object).Count
Write-Host "✅ Found $count screenshots" -ForegroundColor Green
```

---

## 📹 EMULATOR TIPS

If using Android emulator:

### Launch Emulator
```powershell
# Start emulator
emulator -avd YourAVDName

# Or list available AVDs
emulator -list-avds

# Then start specific AVD
emulator -avd Pixel_4_API_31
```

### Screenshot in Emulator
```powershell
# Keyboard shortcut
# Ctrl+S (Windows)
# Cmd+S (Mac)

# Or via adb
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png
```

### Speed Up Emulator (Optional)
```powershell
# Use GPU acceleration
emulator -avd YourAVDName -gpu on

# Enable snapshot (speeds up boot)
# In AVD Manager: Edit > Boot option > Cold boot from snapshot
```

---

## ✨ AUTOMATION TEMPLATE

Save as: `screenshot_workflow.ps1`

```powershell
# Complete screenshot workflow automation

Write-Host "🎬 SCREENSHOT CAPTURE WORKFLOW" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean up
Write-Host "1️⃣  Cleaning previous screenshots..."
Remove-Item "Screenshots_PlayStore" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Name "Screenshots_PlayStore" | Out-Null
Write-Host "✅ Done" -ForegroundColor Green

# Step 2: Start app
Write-Host ""
Write-Host "2️⃣  Starting app in release mode..."
Write-Host "⏠ Waiting 10 seconds for app to boot..." -ForegroundColor Yellow
Start-Process -FilePath "flutter" -ArgumentList "run --release" -WindowStyle Normal
Start-Sleep -Seconds 10

# Step 3: Capture
Write-Host "✅ App started" -ForegroundColor Green
Write-Host ""
Write-Host "3️⃣  Ready to capture 8 screenshots"
Write-Host "Press ENTER when ready for each screenshot..." -ForegroundColor Yellow
Write-Host ""

$screenshots = @(
    "1. Welcome/Login",
    "2. Home page",
    "3. Product search",
    "4. Product details",
    "5. Shopping cart",
    "6. Dark mode",
    "7. Order confirmation",
    "8. User profile"
)

for ($i = 0; $i -lt $screenshots.Count; $i++) {
    Write-Host "[$($i+1)/8] $($screenshots[$i]) - Press ENTER" -ForegroundColor Yellow
    Read-Host
    
    $num = $i + 1
    adb shell screencap -p "/sdcard/screenshot_$num.png"
    adb pull "/sdcard/screenshot_$num.png" "./Screenshots_PlayStore/screenshot_$num.png"
    adb shell rm "/sdcard/screenshot_$num.png"
    
    Write-Host "✅ Captured: screenshot_$num.png" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ ALL SCREENSHOTS CAPTURED!" -ForegroundColor Green
Write-Host "Location: ./Screenshots_PlayStore/" -ForegroundColor Green
Write-Host ""
Write-Host "⏭️  Next step: Run screenshot optimization"
```

---

## 🎬 READY TO GO

Once you have the 8 screenshots:

```powershell
# Verify all present
Get-ChildItem "Screenshots_PlayStore" -Filter "*.jpg"

# Quick check
$total = (Get-ChildItem "Screenshots_PlayStore" | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Total: $($total.ToString('F2')) MB"
Write-Host "✅ Ready for Play Store upload!"
```

---

**Status:** Ready to capture ✅  
**Timeline:** 30-45 minutes hands-on  
**Next:** Follow the quick start above, then proceed to Play Store listing creation
