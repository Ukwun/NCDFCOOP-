# CoopCommerce App Testing Script - Emulator

**Date**: February 16, 2026  
**Platform**: Android Emulator (Pixel 9 Pro XL)  
**Status**: ✅ App Running and Ready to Test

---

## Current App State

✅ **Build**: Successful (47.2 MB APK)  
✅ **Deployment**: Installed on emulator  
✅ **Running**: PID 6060  
✅ **UI Rendering**: Visible on emulator  
⚠️ **Firebase**: Fallback mode (no google-services.json)

---

## Testing Checklist

### 1️⃣ LAUNCH & SPLASH SCREEN (1-2 minutes)

**What to look for:**
- [ ] App splash screen appears (2-3 second animated fade)
- [ ] CoopCommerce green branding visible
- [ ] No crash or hang
- [ ] Smooth animation transition

**Expected**: Splash screen → Auto-navigate to login OR home screen

---

### 2️⃣ LOGIN/SIGNUP FLOW (5-10 minutes)

#### Test 2A: Signup (New User)
1. Look for "Sign Up" or "Create Account" button
2. Enter test credentials:
   ```
   Email: testuser1@coopcommerce.test
   Password: TestPass123!
   Name: Test User
   ```
3. Tap "Create Account"

**Expected Results** ✅
- [ ] Form validates email format
- [ ] Password field shows secure input (dots)
- [ ] "Create Account" button shows loading state
- [ ] No error messages for valid input
- [ ] After submission, automatically navigates to home OR profile setup

**What happens if Firebase fails:**
- App shows fallback behavior
- Mock login may proceed
- User should be able to continue to next screen

---

#### Test 2B: Login (Returning User)
1. If signup succeeded, logout first (if logout is available)
2. Enter credentials from signup test
3. Tap "Login"

**Expected Results** ✅
- [ ] Email field required validation works
- [ ] Password field required validation works
- [ ] Login button shows loading indicator
- [ ] Successful navigation to home screen
- [ ] User name/avatar appears in app if stored

---

### 3️⃣ HOME SCREEN & PRODUCT BROWSING (3-5 minutes)

**What to look for on home screen:**
- [ ] App bar displays "CoopCommerce" or home icon
- [ ] Products load and display in grid/list
- [ ] Product images visible (cached_network_image working)
- [ ] Product name, price visible
- [ ] Categories or filters visible (if implemented)
- [ ] Bottom navigation bar visible

**Test Interactions:**
1. **Scroll down** - Check if more products load (lazy loading test)
   - [ ] Smooth scrolling without jank
   - [ ] Products load from pagination provider
   - [ ] No freezing or crashes

2. **Search** (if search bar exists)
   - [ ] Type product name: "test"
   - [ ] Results update in real-time or on submit
   - [ ] Search clears, returns to full list

3. **Filter/Category** (if filter exists)
   - [ ] Select a category
   - [ ] Products filter correctly
   - [ ] Back/reset filter works

---

### 4️⃣ PRODUCT DETAILS (2-3 minutes)

1. **Click any product**
   - [ ] Product detail page opens smoothly
   - [ ] Product image displays clearly
   - [ ] Product name, description, price visible
   - [ ] Stock/availability shown
   - [ ] Rating and reviews visible (if integrated)

2. **Product images**
   - [ ] Images load via cached_network_image
   - [ ] Similar quality/speed to first visit if scrolling back
   - [ ] No placeholder flicker on return visit (caching working)

---

### 5️⃣ SHOPPING CART (5-7 minutes)

#### Test 5A: Add to Cart
1. On product detail, find "Add to Cart" button
2. Enter quantity: 2
3. Tap "Add to Cart"

**Expected Results** ✅
- [ ] Button shows loading state during action
- [ ] Cart count increases in navigation bar (if visible)
- [ ] Success message/toast appears
- [ ] Can continue shopping or go to cart

---

#### Test 5B: View Cart
1. Tap cart icon in navigation bar OR "View Cart" button
2. Cart page displays:
   - [ ] List of added items with images
   - [ ] Item names, prices, quantities
   - [ ] Remove item functionality works
   - [ ] Quantity +/- buttons work
   - [ ] Subtotal calculates correctly

**Calculations test:**
- Product 1: $10 × 2 = $20
- Product 2 (if added): $15 × 1 = $15
- Subtotal should show: $35

---

#### Test 5C: Cart Updates
1. Change quantity of item to 5
2. Remove one item completely
3. Add item back to cart

**Expected:**
- [ ] Subtotal updates in real-time
- [ ] No crashes when updating
- [ ] Smooth quantity animations

---

### 6️⃣ CHECKOUT FLOW (8-10 minutes)

#### Test 6A: Proceed to Checkout
1. Cart page: Tap "Checkout" or "Proceed to Checkout"
2. You should be taken to checkout/order screen

**Expected:**
- [ ] Billing/shipping form appears smoothly
- [ ] Loading states visible
- [ ] No layout overflow or UI issues on 6.1" screen (Pixel 9 Pro XL)

---

#### Test 6B: Shipping Address
1. Enter/verify shipping address:
   ```
   Name: Test User
   Address: 123 Main St
   City: Lagos
   State: Lagos
   ZIP: 100001
   Phone: +2348012345678
   ```

**Expected:**
- [ ] All fields accept input
- [ ] Form validates correctly
- [ ] No keyboard overlaps critical content

---

#### Test 6C: Shipping Method
1. Select shipping method (if options available):
   - [ ] Standard (5-7 days)
   - [ ] Express (2-3 days)
   - [ ] Pickup

**Expected:**
- [ ] Shipping cost updates based on selection
- [ ] Total price recalculates
- [ ] Option stays selected after scrolling

---

#### Test 6D: Payment Method
1. Look for payment option selection
   - You should see **Flutterwave** or other payment options
   
2. **Without Flutterwave keys configured:**
   - [ ] Payment button may be disabled or shows "Not Available"
   - [ ] Fallback message appears
   - [ ] App doesn't crash

3. **If Flutterwave is integrated:**
   - [ ] Select payment method
   - [ ] Tap "Pay" button
   - [ ] Flutterwave dialog should appear

---

#### Test 6E: Order Summary Before Payment
1. Review screen should show:
   - [ ] Product list with items
   - [ ] Subtotal: $XX.XX
   - [ ] Shipping: $X.XX
   - [ ] Tax: $X.XX (if applicable)
   - [ ] **Total: $XX.XX**
   
2. **Math check:**
   - Subtotal + Shipping + Tax = Total

**Expected:**
- [ ] All amounts correct
- [ ] No visual glitches
- [ ] Proceed button clearly visible

---

### 7️⃣ PAYMENT SIMULATION (3-5 minutes)

**Note**: Since Flutterwave keys aren't configured yet:

**Option A: Mock Payment (Fallback)**
1. If payment form appears with mock data:
   - Card Number: 4111111111111111
   - Expiry: 12/25
   - CVV: 123

2. **Expected Result:**
   - [ ] Either shows success screen OR
   - [ ] Shows "Payment configuration needed" message
   - [ ] App doesn't crash
   - [ ] Doesn't make real charges

**Option B: Error Handling**
- [ ] If payment fails, error message shows clearly
- [ ] Can retry or go back to cart
- [ ] Error doesn't freeze app

---

### 8️⃣ ORDER CONFIRMATION (2-3 minutes)

**If payment succeeds:**
1. Confirmation screen should display:
   - [ ] Order number (e.g., "ORD-12345")
   - [ ] Confirmation message
   - [ ] Order date and time
   - [ ] Estimated delivery date

2. Buttons available:
   - [ ] "View Order Details" - takes to order page
   - [ ] "Continue Shopping" - back to home
   - [ ] "Track Order" (if implemented)

---

### 9️⃣ PERFORMANCE & STABILITY (Throughout Testing)

Track these metrics:
- [ ] **App Startup**: <5 seconds total
- [ ] **Screen Transitions**: Smooth, <500ms
- [ ] **Image Loading**: <2 seconds per image
- [ ] **Scroll Performance**: No jank/frame drops
- [ ] **Memory**: Check logs for excessive allocation
- [ ] **Battery**: Normal usage (emulator shows in logs)

**Commands to check performance:**
```bash
# View memory usage
adb shell dumpsys meminfo com.example.coop_commerce | grep TOTAL

# View frame timing
adb shell dumpsys SurfaceFlinger --dump-all | grep "Frame"
```

---

### 🔟 NOTIFICATIONS (2-3 minutes, if Firebase configured)

1. Go back to home screen
2. Wait for a test notification OR manually trigger via Firebase Console
3. **Expected:**
   - [ ] Notification appears in system tray
   - [ ] Notification shows title and message
   - [ ] Tap notification → opens app to relevant screen
   - [ ] App handles new intent smoothly

---

## Navigation Flow Test Map

```
Splash Screen
      ↓
Login/Signup ←→ Home Screen
                    ↓
                Browse Products
                    ↓
            Product Details
                    ↓
            Add to Cart
                    ↓
            View Cart
                    ↓
            Checkout
                    ↓
            Enter Address
                    ↓
            Select Shipping
                    ↓
            Select Payment ← Flutterwave Integration Point
                    ↓
            Review Order
                    ↓
            Payment Confirmation
                    ↓
            Order Details/Tracking
```

---

## Issues to Watch For

### 🔴 Critical (Blocks Testing)
- [ ] App crashes during startup
- [ ] Complete UI freeze
- [ ] Can't navigate between screens
- [ ] Can't add items to cart

### 🟠 Important (Limits Testing)
- [ ] Navigation too slow (>3 seconds per screen)
- [ ] Images don't load
- [ ] Form validation fails
- [ ] Can't complete checkout

### 🟡 Minor (Polish)
- [ ] Animation jank on scroll
- [ ] Text overflow in certain screens
- [ ] Color contrast issues
- [ ] Button states unclear

---

## Test Results Template

```
═══════════════════════════════════════
TESTING SESSION REPORT
═══════════════════════════════════════
Date: 2026-02-16
Build: app-debug.apk (47.2 MB)
Device: Pixel 9 Pro XL Emulator
Duration: ___ minutes

TEST RESULTS:
─────────────────────────────────────
✅ Splash Screen: PASS / FAIL
✅ Signup: PASS / FAIL
✅ Login: PASS / FAIL
✅ Home/Products: PASS / FAIL
✅ Search: PASS / FAIL (N/A)
✅ Product Details: PASS / FAIL
✅ Add to Cart: PASS / FAIL
✅ View Cart: PASS / FAIL
✅ Shipping Address: PASS / FAIL
✅ Shipping Method: PASS / FAIL
✅ Payment Selection: PASS / FAIL
✅ Order Confirmation: PASS / FAIL
✅ Navigation Flow: PASS / FAIL
✅ Performance: PASS / FAIL

BLOCKERS FOUND:
─────────────────────────────────────
1. Firebase Configuration (Expected)
   - Impact: Services in fallback mode
   - Fix: Add google-services.json

2. [Other issues found]

NEXT STEPS:
─────────────────────────────────────
1. Configure Firebase
2. Add Flutterwave keys
3. Create test products in Firestore
4. Re-test checkout flow
```

---

## Firebase Configuration (Optional for Full Testing)

To enable real Firebase features:

1. **Download google-services.json**:
   - Go to Firebase Console → Project Settings → Download google-services.json
   - Place in: `android/app/google-services.json`

2. **Rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Test again** - All Firebase features should work

---

## Key Test Scenarios Summary

| Scenario | Expected | Critical? |
|----------|----------|-----------|
| App launches | Splash screen → Login | Yes |
| User can sign up | Creates account, auto-login | Yes |
| User can login | Existing user logs in | Yes |
| Products load | Grid shows items | Yes |
| Product details | Image and info display | Yes |
| Add to cart | Cart count increases | Yes |
| View cart | Items list with total | Yes |
| Checkout | Form appears | Yes |
| Order summary | All costs correct | Yes |
| Payment attempt | No crash if payment unavailable | Yes |
| Order confirmation | Shows order number | Important |

---

## Need Help?

If you encounter issues:

1. **App crashes:**
   ```bash
   adb logcat | grep "ERROR\|Exception"
   ```

2. **Check specific logs:**
   ```bash
   adb logcat | grep "flutter"
   ```

3. **Reset emulator:**
   ```bash
   flutter emulators --launch Pixel_9_Pro_XL
   ```

4. **Clear app data:**
   ```bash
   adb shell pm clear com.example.coop_commerce
   ```

---

## Document Your Findings

When testing, note:
- ✅ What works perfectly
- ⚠️ What works with minor issues
- ❌ What doesn't work
- 📸 Any UI layout issues
- ⏱️ Performance timings

This helps prioritize fixes before Play Store submission!
