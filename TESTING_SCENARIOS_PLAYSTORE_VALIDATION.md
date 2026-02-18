# Critical Testing Scenarios - PlayStore Launch
**Purpose:** Validate all core user journeys before submitting to Play Store  
**Estimated Time:** 4-6 hours (thorough testing)  
**Devices Needed:** Minimum 3 (API 21, 28, 33+)

---

## PRE-TEST SETUP

### Device Preparation
```bash
# For each test device:

# 1. Clear app data
adb shell pm clear com.cooperativenicorp.coopcommerce

# 2. Uninstall previous version
adb uninstall com.cooperativenicorp.coopcommerce

# 3. Install release APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 4. Verify installation
adb shell pm list packages | grep coopcommerce
```

### Test Accounts (Create in Firebase/backend)
```
Consumer Account:
  Email: consumer@test.com
  Password: Test@12345
  Role: consumer
  
Member Account:
  Email: member@test.com
  Password: Test@12345
  Role: coopMember
  
Franchise Account:
  Email: franchise@test.com
  Password: Test@12345
  Role: franchiseOwner
  
Admin Account:
  Email: admin@test.com
  Password: Test@12345
  Role: admin
```

### Test Credit Cards (Flutterwave/Paystack)
```
Flutterwave Test Cards:
  Visa: 4242 4242 4242 4242
  Expiry: 09/32
  CVV: 408
  OTP: 123456

Paystack Test Cards:
  Visa: 4084 0343 0343 0343
  Expiry: 12/25
  CVV: 123
```

---

## TEST SCENARIO 1: NEW USER SIGNUP

**Objective:** Verify complete onboarding flow for new consumer

**Steps:**

1. **App Launch**
   - [ ] App launches without crash
   - [ ] Splash screen displays (< 1 second)
   - [ ] Welcome screen shows
   - [ ] **Expected:** Smooth transition to sign-in screen

2. **Navigate to Sign Up**
   - [ ] Tap "Create Account" or sign-up link
   - [ ] Sign-up form loads
   - [ ] [ ] **Expected:** Form displays name, email, password fields

3. **Fill Sign-Up Form**
   - [ ] Enter first name: "Test"
   - [ ] Enter last name: "User"
   - [ ] Enter email: "newuser@test.com"
   - [ ] Enter password: "SecurePass123!"
   - [ ] Confirm password: "SecurePass123!"
   - [ ] **Expected:** All fields populate correctly

4. **Submit Sign-Up**
   - [ ] Tap "Sign Up" button
   - [ ] Loading indicator shows
   - [ ] Form validates fields
   - [ ] **Expected:** Account created, auto-login, redirected to home

5. **Role Assignment**
   - [ ] User assigned "consumer" role by default
   - [ ] Consumer home screen appears
   - [ ] **Expected:** Home screen displays products, navigation bar visible

**Pass Criteria:**
- ✅ Account created successfully
- ✅ User logged in automatically
- ✅ Correct role assigned
- ✅ No crashes detected
- ✅ Response time < 3 seconds

---

## TEST SCENARIO 2: EXISTING USER LOGIN

**Objective:** Verify login works for existing account

**Steps:**

1. **Open Sign In Screen**
   - [ ] App shows sign-in screen
   - [ ] Email and password fields visible
   - [ ] Remember me checkbox present
   - [ ] Forgot password link present

2. **Standard Email Login**
   - [ ] Enter email: "consumer@test.com"
   - [ ] Enter password: "Test@12345"
   - [ ] Tap "Sign In"
   - [ ] Loading indicator shows
   - [ ] **Expected:** Logged in, redirected to consumer home

3. **Remember Me Functionality**
   - [ ] Select "Remember me" checkbox
   - [ ] Login with account
   - [ ] Close app completely
   - [ ] Reopen app
   - [ ] **Expected:** App remembers login, skips sign-in screen

4. **OAuth Sign-In (Optional)**
   - [ ] Tap "Sign in with Google"
   - [ ] Google login flow initiates
   - [ ] **Expected:** Account linked, logged in

**Pass Criteria:**
- ✅ Login successful for valid credentials
- ✅ Error shown for invalid password
- ✅ Remember me works
- ✅ OAuth works (if enabled)
- ✅ Session persists across app restarts

---

## TEST SCENARIO 3: PRODUCT DISCOVERY & BROWSING

**Objective:** Verify product listing and search functionality

**Steps:**

1. **Home Screen Products**
   - [ ] Open consumer home
   - [ ] Scroll to "Featured for You" section
   - [ ] **Verify:** 8 product cards visible
   - [ ] Each card shows: image, name, price, rating
   - [ ] Product images load correctly
   - [ ] Prices display in Nigerian Naira (₦)

2. **Product Search**
   - [ ] Tap search icon
   - [ ] Search bar appears
   - [ ] Type "rice"
   - [ ] Results load (< 2 seconds)
   - [ ] **Verify:** Correct products displayed
   - [ ] Search filters show category options
   - [ ] Can select multiple filters

3. **Product Filtering**
   - [ ] Tap "Filter" button
   - [ ] Filter modal opens
   - [ ] Select category: "Grains"
   - [ ] Set price range: ₦10,000 - ₦30,000
   - [ ] Tap "Apply"
   - [ ] **Verify:** Products filtered correctly
   - [ ] Count updated
   - [ ] Can clear filters

4. **Category Browsing**
   - [ ] Tap on category (e.g., "Spices")
   - [ ] Category page loads
   - [ ] Products in category displayed
   - [ ] Can sort by: price, popularity, rating
   - [ ] **Verify:** Sorting works correctly

5. **Product Detail View**
   - [ ] Tap on any product card
   - [ ] Product detail page loads (< 1 second)
   - [ ] **Verify:**
     - [ ] Full product image displays
     - [ ] Product title, description visible
     - [ ] All prices shown: retail, wholesale (if applicable)
     - [ ] Stock status shown
     - [ ] Add to cart button visible
     - [ ] Similar products section at bottom

**Pass Criteria:**
- ✅ Products load without lag
- ✅ Search returns relevant results
- ✅ Filters work correctly
- ✅ Product detail loads quickly
- ✅ Images display properly
- ✅ No missing product data

---

## TEST SCENARIO 4: SHOPPING CART

**Objective:** Verify add-to-cart and cart management

**Steps:**

1. **Add to Cart**
   - [ ] Open product detail page
   - [ ] Tap "Add to Cart"
   - [ ] Quantity default should be 1
   - [ ] **Expected:** Toast notification "Added to cart"
   - [ ] Cart icon shows badge "1"

2. **View Cart**
   - [ ] Tap cart icon in nav bar
   - [ ] Cart screen opens
   - [ ] **Verify:**
     - [ ] Product listed with image, name, price
     - [ ] Quantity shown with +/- buttons
     - [ ] Item subtotal calculated correctly
     - [ ] Cart total displayed

3. **Modify Quantities**
   - [ ] Tap + button to increase quantity to 3
   - [ ] Subtotal updates: 3 × price
   - [ ] Cart total updates automatically
   - [ ] Tap - button to decrease to 1
   - [ ] **Verify:** Calculations correct

4. **Remove Item**
   - [ ] Tap trash/remove icon
   - [ ] Confirmation dialog appears
   - [ ] Tap confirm
   - [ ] Item removed from cart
   - [ ] Cart total updated
   - [ ] **Verify:** Cart reflects change

5. **Add Multiple Products**
   - [ ] Go back to home
   - [ ] Add 3 different products to cart
   - [ ] Open cart
   - [ ] **Verify:**
     - [ ] All 3 items listed
     - [ ] Total sum of all items correct
     - [ ] Can modify each item independently

6. **Cart Persistence**
   - [ ] Add items to cart
   - [ ] Close app completely
   - [ ] Reopen app
   - [ ] **Verify:** Cart items still there

**Pass Criteria:**
- ✅ Items add/remove successfully
- ✅ Quantities update correctly
- ✅ Cart total accurate
- ✅ Cart persists across sessions
- ✅ UI updates instantly

---

## TEST SCENARIO 5: CHECKOUT & PAYMENT

**Objective:** Complete end-to-end purchase flow

**Steps:**

1. **Proceed to Checkout**
   - [ ] In cart screen, tap "Checkout"
   - [ ] Checkout flow initiates
   - [ ] Page 1: Order review opens
   - [ ] **Verify:**
     - [ ] All items listed
     - [ ] Subtotal, tax, shipping shown
     - [ ] Grand total calculated

2. **Enter Delivery Address**
   - [ ] Tap "Add Address" or select existing
   - [ ] Address form opens:
     - [ ] Street address
     - [ ] City/LGA
     - [ ] Postal code
     - [ ] Phone number
   - [ ] Fill all fields with valid data
   - [ ] Tap "Save Address"
   - [ ] **Verify:** Address saved and selected

3. **Confirm Delivery Address**
   - [ ] Selected address shown
   - [ ] Can edit or add another address
   - [ ] Tap "Continue to Payment"
   - [ ] Payment screen loads

4. **Payment Method Selection**
   - [ ] **Option 1: Credit/Debit Card**
     - [ ] Tap "Card Payment"
     - [ ] Card form opens
     - [ ] Enter test card: 4242 4242 4242 4242
     - [ ] Enter expiry: 09/32
     - [ ] Enter CVV: 408
     - [ ] Tap "Pay Now"
     - [ ] Flutterwave modal appears
     - [ ] Enter OTP: 123456
     - [ ] **Verify:** Payment successful

   - [ ] **Option 2: Paystack (if integrated)**
     - [ ] Tap "Complete Payment"
     - [ ] Paystack modal opens
     - [ ] Enter test card details
     - [ ] Enter OTP
     - [ ] **Verify:** Payment successful

5. **Order Confirmation**
   - [ ] Payment processes (show loading)
   - [ ] Order confirmation page appears
   - [ ] **Verify:**
     - [ ] Order number displayed
     - [ ] Order date/time shown
     - [ ] Items and total shown
     - [ ] "Track Order" button visible
   - [ ] Tap "Back to Home"
   - [ ] Returned to home, cart empty

6. **Payment Failure Handling**
   - [ ] Repeat checkout with invalid card
   - [ ] **Verify:** Clear error message shown
   - [ ] Can retry with different card
   - [ ] Cart items still there after failure

**Pass Criteria:**
- ✅ Checkout form validates all fields
- ✅ Address saved correctly
- ✅ Payment gateway loads properly
- ✅ Successful payment processes
- ✅ Order confirmation shows correct data
- ✅ Cart clears after successful payment
- ✅ Errors handled gracefully

---

## TEST SCENARIO 6: ORDER TRACKING

**Objective:** Verify order history and tracking

**Steps:**

1. **View Order History**
   - [ ] Go to Profile → Order History
   - [ ] Orders screen opens
   - [ ] **Verify:**
     - [ ] Recently created order visible
     - [ ] Order number displayed
     - [ ] Order date shown
     - [ ] Order status shown
     - [ ] Order total shown

2. **Order Detail View**
   - [ ] Tap on order
   - [ ] Order detail screen opens
   - [ ] **Verify:**
     - [ ] All items listed with quantities
     - [ ] Delivery address shown
     - [ ] Order total breakdown (subtotal, tax, shipping)
     - [ ] Estimated delivery date

3. **Order Tracking (if available)**
   - [ ] Tap "Track Order"
   - [ ] Map screen opens (if delivery)
   - [ ] Real-time status updates work
   - [ ] Estimated time of arrival shown
   - [ ] **Verify:** Map loads correctly

4. **Order Actions**
   - [ ] If status allows, can "Cancel Order"
   - [ ] If status allows, can "Contact Support"
   - [ ] View invoice option available
   - [ ] Reorder button available

**Pass Criteria:**
- ✅ Order history loads instantly
- ✅ Order details complete and accurate
- ✅ Tracking maps load (if applicable)
- ✅ Status updates reflect correctly
- ✅ Actions available for valid states

---

## TEST SCENARIO 7: MEMBER FEATURES (Member Account)

**Objective:** Verify member-specific functionality

**Steps:**

1. **Login as Member**
   - [ ] Sign in with member@test.com
   - [ ] Redirected to member home screen
   - [ ] **Verify:** Member-specific UI shows:
     - [ ] Greeting "Welcome, [Name]!"
     - [ ] Member tier badge visible
     - [ ] Loyalty points display
     - [ ] "Save 20% on all items this week" callout

2. **Loyalty Card**
   - [ ] Loyalty card visible with:
     - [ ] Current points balance
     - [ ] Progress bar to next tier
     - [ ] Points needed for next tier
     - [ ] Gradient background

3. **Member Benefits**
   - [ ] "Your Benefits" section shows benefits
   - [ ] Can scroll through benefit cards
   - [ ] Tap benefit to see details
   - [ ] "View All Benefits" navigates to benefits page

4. **Member-Only Deals**
   - [ ] "Member-Only Deals" section visible
   - [ ] Shows exclusive offer with:
     - [ ] Discount percentage (e.g., 20%)
     - [ ] Offer description
     - [ ] Confidence badge (member exclusive)

5. **Recommended Products**
   - [ ] "Recommended for You" shows products
   - [ ] Products have "Member Deal" badge
   - [ ] Price shows member price
   - [ ] Can add to cart directly

6. **Member Pricing**
   - [ ] Browse any product as member
   - [ ] Compare consumer vs member price
   - [ ] Member price should be lower
   - [ ] Discount percentage shown
   - [ ] Savings amount highlighted

**Pass Criteria:**
- ✅ Member home loads correctly
- ✅ Loyalty card displays accurate data
- ✅ Member benefits properly formatted
- ✅ Member-only deals visible
- ✅ Member pricing applied
- ✅ Badges/indicators clear

---

## TEST SCENARIO 8: NOTIFICATIONS

**Objective:** Verify push and in-app notifications

**Steps:**

1. **Notification Permission**
   - [ ] App requests notification permission
   - [ ] User grants permission
   - [ ] **Verify:** Permission granted in system settings

2. **Order Status Notifications**
   - [ ] Place an order (Test Scenario 5)
   - [ ] Trigger order status update from admin panel
   - [ ] **Verify:** Push notification appears
   - [ ] Notification text mentions order status
   - [ ] Tap notification opens order tracking

3. **In-App Banner Notification**
   - [ ] While app open, trigger order update
   - [ ] **Verify:** In-app banner appears at top
   - [ ] Shows update message
   - [ ] Banner auto-dismisses after 5 seconds
   - [ ] Can tap to navigate to order

4. **Notification Center**
   - [ ] Open notification center from profile
   - [ ] Historical notifications visible
   - [ ] Can mark as read
   - [ ] Can clear individual notifications
   - [ ] Search/filter notifications work

5. **Promotional Notifications**
   - [ ] Trigger promo notification from admin
   - [ ] **Verify:** Received and displayed
   - [ ] Tap opens promo/product details
   - [ ] Can dismiss without action

**Pass Criteria:**
- ✅ FCM integration working
- ✅ Notifications deliver reliably
- ✅ Notification content accurate
- ✅ Tap actions navigate correctly
- ✅ Notification center works
- ✅ No crashes from notifications

---

## TEST SCENARIO 9: SETTINGS & PROFILE

**Objective:** Verify user profile and settings management

**Steps:**

1. **View Profile**
   - [ ] Go to Profile tab
   - [ ] User info displayed:
     - [ ] Name
     - [ ] Email
     - [ ] Phone
     - [ ] Account creation date
     - [ ] Membership tier (if applicable)

2. **Edit Profile**
   - [ ] Tap "Edit" button
   - [ ] Form becomes editable
   - [ ] Update name: "Updated Test"
   - [ ] Update phone: "08123456789"
   - [ ] Tap "Save"
   - [ ] **Verify:** Changes saved (refresh confirms)

3. **Change Password**
   - [ ] Go to Settings
   - [ ] Tap "Change Password"
   - [ ] Form opens:
     - [ ] Current password field
     - [ ] New password field
     - [ ] Confirm password field
   - [ ] Enter valid data
   - [ ] Tap "Save"
   - [ ] **Verify:** Success message, logout and login with new password

4. **Notification Settings**
   - [ ] Go to Settings → Notifications
   - [ ] Toggle options:
     - [ ] Push notifications
     - [ ] Order updates
     - [ ] Promotions
   - [ ] Save changes
   - [ ] **Verify:** Changes persist

5. **Address Management**
   - [ ] Go to Profile → Addresses
   - [ ] List of saved addresses shows
   - [ ] Can add new address
   - [ ] Can edit existing address
   - [ ] Can delete address
   - [ ] Can set as default
   - [ ] **Verify:** All operations work

6. **Payment Methods**
   - [ ] Go to Profile → Payment Methods
   - [ ] Saved cards list shows
   - [ ] Can add new card
   - [ ] Can delete card
   - [ ] Can set as default
   - [ ] **Verify:** Changes reflected in checkout

7. **Logout**
   - [ ] Tap "Logout" button
   - [ ] Confirmation dialog appears
   - [ ] Tap confirm
   - [ ] **Verify:** Logged out, sign-in screen shows
   - [ ] Previous session data cleared

**Pass Criteria:**
- ✅ Profile info displays correctly
- ✅ Profile edits save
- ✅ Password change works (old → new)
- ✅ Settings persist across sessions
- ✅ Address management complete
- ✅ Logout clears session

---

## TEST SCENARIO 10: ADMIN FEATURES (Admin Account)

**Objective:** Verify admin dashboard functionality

**Steps:**

1. **Admin Home**
   - [ ] Login with admin@test.com
   - [ ] Admin home screen loads
   - [ ] **Verify:**
     - [ ] Key metrics visible (orders, revenue, etc.)
     - [ ] Charts/graphs display correctly
     - [ ] Navigation to admin features available

2. **User Management**
   - [ ] Navigate to User Management
   - [ ] List of users shown with:
     - [ ] Username
     - [ ] Email
     - [ ] Role
     - [ ] Status (active/inactive)
   - [ ] Can search for user
   - [ ] Can edit user details
   - [ ] Can change user role
   - [ ] **Verify:** Changes saved

3. **View Analytics**
   - [ ] Navigate to Analytics/Dashboard
   - [ ] Charts show:
     - [ ] Daily orders
     - [ ] Revenue trends
     - [ ] Top products
     - [ ] Member growth
   - [ ] Can filter by date range
   - [ ] **Verify:** Data loads and displays

4. **Price Override**
   - [ ] Navigate to Pricing Management
   - [ ] Select a product
   - [ ] Tap "Override Price"
   - [ ] Enter new price
   - [ ] Tap "Save"
   - [ ] **Verify:**
     - [ ] Change saved in system
     - [ ] Consumer sees new price
     - [ ] Old price shown as "was"

**Pass Criteria:**
- ✅ Admin dashboard loads quickly
- ✅ User management works
- ✅ Analytics display correctly
- ✅ Price overrides apply system-wide
- ✅ All admin actions logged

---

## TEST SCENARIO 11: OFFLINE FUNCTIONALITY

**Objective:** Verify app works with no internet

**Steps:**

1. **Enable Airplane Mode**
   - [ ] App running and logged in
   - [ ] Device Settings → Toggle Flight Mode ON
   - [ ] Verify WiFi and data are off
   - [ ] Return to app

2. **Offline Navigation**
   - [ ] **Verify:** Can navigate between screens
   - [ ] Can view previously loaded pages
   - [ ] Mock products display (if configured)
   - [ ] No app crashes

3. **Offline Cart**
   - [ ] Add items to cart (while offline)
   - [ ] Cart updates reflect changes
   - [ ] Cart persists in local storage
   - [ ] **Verify:** Can modify quantities offline

4. **Offline Checkout**
   - [ ] Try to proceed to payment
   - [ ] **Expected:** Error message indicating no internet
   - [ ] Can dismiss error
   - [ ] App remains stable

5. **Reconnect to Internet**
   - [ ] Device Settings → Toggle Flight Mode OFF
   - [ ] App detects connectivity
   - [ ] Real data reloads
   - [ ] Cart items persist
   - [ ] Can now proceed with payment

**Pass Criteria:**
- ✅ App stable with no network
- ✅ UI navigation works offline
- ✅ Local data accessible
- ✅ Graceful error handling
- ✅ Seamless reconnection

---

## TEST SCENARIO 12: PERFORMANCE STRESS TEST

**Objective:** Verify stability under heavy load

**Steps:**

1. **Memory Usage**
   ```bash
   adb shell dumpsys meminfo com.cooperativenicorp.coopcommerce | grep TOTAL
   ```
   - [ ] Launch app
   - [ ] Check memory: should be < 100MB
   - [ ] Browse 50+ products
   - [ ] Check memory: should be < 200MB
   - [ ] No Out of Memory crashes

2. **Rapid Navigation**
   - [ ] Quickly tap between tabs 50 times
   - [ ] Rapidly open/close product details
   - [ ] **Verify:** No crashes, UI remains responsive

3. **Large List Rendering**
   - [ ] Load category with 100+ products
   - [ ] Scroll rapidly through list
   - [ ] **Verify:** Smooth scrolling (60 FPS)
   - [ ] Images load without stuttering
   - [ ] No memory leaks

4. **Network Throttling**
   - [ ] Enable Android Developer Options
   - [ ] Set network throttling: 3G (400kbps)
   - [ ] Perform key flows:
     - [ ] Browse products
     - [ ] Search
     - [ ] Checkout
   - [ ] **Verify:** Graceful handling, appropriate loading states

**Pass Criteria:**
- ✅ Memory stays < 250MB
- ✅ App never crashes under stress
- ✅ Frame rate remains > 30 FPS
- ✅ Responsive even on slow networks

---

## FINAL VALIDATION CHECKLIST

### Crashes
- [ ] 0 crashes across all 12 scenarios
- [ ] 0 ANR (Application Not Responding) errors
- [ ] Logs show no fatal exceptions

### Performance
- [ ] Average load time < 2 seconds
- [ ] Memory usage < 200MB
- [ ] Frame rate > 30 FPS during scrolling
- [ ] APK size < 100MB

### Functionality
- [ ] All features work on device
- [ ] All user roles function correctly
- [ ] Payment flows complete
- [ ] Notifications deliver
- [ ] Offline mode works

### User Experience
- [ ] UI responsive
- [ ] Loading states clear
- [ ] Error messages helpful
- [ ] Navigation intuitive
- [ ] No visual glitches

### Data Integrity
- [ ] Cart persists correctly
- [ ] Order data saved accurately
- [ ] Profile updates persist
- [ ] Payment records match orders

---

## SIGN-OFF TEMPLATE

**Device:** [Model] - Android [Version]  
**Tester:** [Name]  
**Date:** [Date]  
**Time Spent:** [Duration]  
**APK Version:** 1.0.0 (Build 1)  

**Overall Result:** ✅ PASS / ❌ FAIL

**Critical Issues Found:** (if any)
```
[Issue #1]
[Issue #2]
```

**Recommendations:**
```
[Recommendation 1]
[Recommendation 2]
```

**Signature:** ________________  **Date:** ________

---

**After passing all scenarios:**
✅ App is ready for PlayStore submission
✅ Document this testing session for compliance
✅ Archive signed APK with version info
