# NCDF Money - Role-Based UX Testing Guide

## Test Scenarios by Role

### 📋 Overview
This document contains detailed test scenarios for all 6 primary roles in the new Alibaba-inspired global utility header. Each test scenario includes:
- Navigation flows
- Button functionality checks
- Expected outcomes
- Screenshots/verification steps

---

## 🧪 Test Setup

### Prerequisites
- ✅ App installed on itel A6611L (Android 15)
- ✅ User account: `ukwun97@gmail.com`
- ✅ Firestore rules deployed
- ✅ Firebase initialized

### Test Device Info
- Device: itel A6611L
- Android Version: 15 (API 35)
- Device ID: `159863759V002387`
- App Version: Debug build with header

### How to Test Different Roles
1. Sign out current user (or use different test accounts)
2. Sign in with role-specific account
3. Navigate to home screen
4. Verify header shows correct role
5. Test all 4 utility buttons for that role

---

## 👤 **Test Scenario 1: MEMBER ROLE**

### User Profile
- **Role:** Coop Member / Premium Member
- **Expected Header Color:** Gold (#C9A227 for Member, #FFD700 for Premium)
- **Test Account:** Use existing or create new with member role

### Utility Buttons to Test
```
1. KYC Status    → /profile
2. Wallet        → /payment-methods
3. Loyalty       → /member-loyalty
4. Savings       → /member-benefits
```

### Test Cases

#### TC-1.1: Header Display
- [ ] Open app and navigate to Home screen
- [ ] Verify AppHeaderUtility visible at top
- [ ] Verify profile avatar shows user initial
- [ ] Verify user name displayed
- [ ] Verify "Member" or "Premium Member" badge shows
- [ ] Verify gold color applied to role badge
- **Expected Result:** All elements visible, properly aligned

#### TC-1.2: Profile Access
- [ ] Click on profile avatar/name in header
- [ ] **Expected Result:** Navigate to `/profile` screen
- [ ] Verify user email displayed
- [ ] Verify user role shown
- [ ] Tap back to return to home

#### TC-1.3: KYC Status Button
- [ ] From home, verify KYC Status button visible in header utilities
- [ ] Tap "KYC Status" button
- [ ] **Expected Result:** Navigate to `/profile` screen
- [ ] Verify navigation smooth, no errors in logs
- [ ] Verify button is responsive (ripple effect)
- [ ] Tap back to return

#### TC-1.4: Wallet Button
- [ ] From home, tap "Wallet" button in utilities
- [ ] **Expected Result:** Navigate to `/payment-methods` screen
- [ ] Verify payment methods displayed (or empty state)
- [ ] Verify "Add Payment Method" button works
- [ ] Tap back to return

#### TC-1.5: Loyalty Button
- [ ] From home, tap "Loyalty" button
- [ ] **Expected Result:** Navigate to `/member-loyalty` screen
- [ ] Verify loyalty points displayed
- [ ] Verify rewards tier shown
- [ ] Verify tier progress visible
- [ ] Tap back to return

#### TC-1.6: Savings Button
- [ ] From home, tap "Savings" button
- [ ] **Expected Result:** Navigate to `/member-benefits` screen
- [ ] Verify member benefits listed
- [ ] Verify savings amount displayed
- [ ] Verify benefit details accessible
- [ ] Tap back to return

#### TC-1.7: Global Utilities
- [ ] Verify notifications bell icon visible
- [ ] Tap notifications bell → Should navigate to `/notifications`
- [ ] Verify settings gear icon visible
- [ ] Tap settings → Should navigate to `/settings`
- [ ] Verify help icon visible
- [ ] Tap help → Should navigate to `/help-support`

#### TC-1.8: Bottom Tabs Functionality
- [ ] Verify all 5 bottom tabs still visible
- [ ] Tap "Home" tab → Should remain on home
- [ ] Tap "Offers" tab → Should navigate to products
- [ ] Tap "Messages" tab → Should navigate to messages
- [ ] Tap "Cart" tab → Should navigate to cart
- [ ] Tap "My NCDFCOOP" tab → Should navigate to profile
- [ ] Verify header persists on all tabs
- **Critical Check:** Header should NOT disappear when switching tabs

#### TC-1.9: Header Persistence
- [ ] Navigate to Products (Offers tab)
- [ ] Verify header still visible at top
- [ ] Tap a product
- [ ] Verify header still visible
- [ ] Go to Cart
- [ ] Verify header visible
- [ ] Go to Checkout
- [ ] Verify header visible
- **Expected:** Header visible on ALL screens

#### TC-1.10: Role Indicator Click
- [ ] Tap on the "Member" or "Premium Member" role badge
- [ ] **Expected Result:** Open role switcher bottom sheet
- [ ] Verify message about multiple roles
- [ ] Tap "Close" button
- [ ] Verify sheet closes

### Pass Criteria
- ✅ All 4 utility buttons navigate correctly
- ✅ Global utilities (notifications, settings, help) functional
- ✅ Header persists on all screens
- ✅ No console errors
- ✅ Bottom tabs still work
- ✅ Colors display correctly

### Failure Criteria
- ❌ Header not visible on any screen
- ❌ Buttons don't navigate
- ❌ Navigation to wrong screen
- ❌ Console errors/exceptions
- ❌ App crashes

---

## 💼 **Test Scenario 2: SELLER ROLE**

### User Profile
- **Role:** Seller
- **Expected Header Color:** Dark Green (#0B6B3A)
- **Test Account:** Create seller account or use existing

### Utility Buttons to Test
```
1. Leads         → /messages
2. Sales         → /orders
3. Commission    → /payment-methods
4. Products      → /products
```

### Test Cases

#### TC-2.1: Header Display
- [ ] Sign in as Seller
- [ ] Navigate to Home
- [ ] Verify header displays "Seller" role badge in dark green
- [ ] Verify 4 seller-specific buttons in utilities row
- [ ] Verify buttons are: Leads, Sales, Commission, Products

#### TC-2.2: Leads Button
- [ ] From home, tap "Leads" button
- [ ] **Expected Result:** Navigate to `/messages` screen
- [ ] Verify buyer inquiries/messages displayed
- [ ] Verify seller can respond to messages
- [ ] Tap back to return

#### TC-2.3: Sales Button
- [ ] From home, tap "Sales" button
- [ ] **Expected Result:** Navigate to `/orders` screen
- [ ] Verify seller's orders listed
- [ ] Verify order status visible
- [ ] Verify order details accessible
- [ ] Tap back to return

#### TC-2.4: Commission Button
- [ ] From home, tap "Commission" button
- [ ] **Expected Result:** Navigate to `/payment-methods` screen
- [ ] Verify commission earnings displayed
- [ ] Verify payment method options shown
- [ ] Tap back to return

#### TC-2.5: Products Button
- [ ] From home, tap "Products" button
- [ ] **Expected Result:** Navigate to `/products` screen
- [ ] Verify seller's products listed
- [ ] Verify can add new product
- [ ] Verify can edit existing product
- [ ] Verify stock levels shown
- [ ] Tap back to return

#### TC-2.6: Multi-Tab Navigation
- [ ] From home, navigate to different tabs
- [ ] Tap Offers → Verify seller sees his products
- [ ] Tap Cart → Verify header persists
- [ ] Tap Messages → Verify header persists with seller utilities
- [ ] Tap My NCDFCOOP → Navigate to seller profile
- [ ] Verify header visible on all screens

### Pass Criteria
- ✅ All 4 seller utilities navigate to correct screens
- ✅ Seller can access sales, leads, commission, products
- ✅ Header shows correct seller color
- ✅ No errors in logs

### Failure Criteria
- ❌ Wrong buttons displayed
- ❌ Navigation to consumer screens instead of seller screens
- ❌ Commission/earnings not visible
- ❌ Can't manage products

---

## 🏢 **Test Scenario 3: INSTITUTIONAL BUYER ROLE**

### User Profile
- **Role:** Institutional Buyer / Institutional Approver
- **Expected Header Color:** Purple (#8B5CF6)
- **Test Account:** Create institutional account

### Utility Buttons to Test
```
1. Compliance    → /help-support
2. Alerts        → /notifications
3. Team          → /messages
4. Invoices      → /orders
```

### Test Cases

#### TC-3.1: Header Display
- [ ] Sign in as Institutional Buyer
- [ ] Navigate to Home
- [ ] Verify header displays "Institutional Buyer" in purple
- [ ] Verify 4 institutional-specific buttons visible
- [ ] Verify buttons are: Compliance, Alerts, Team, Invoices

#### TC-3.2: Compliance Button
- [ ] From home, tap "Compliance" button
- [ ] **Expected Result:** Navigate to `/help-support`
- [ ] Verify compliance documentation/reports available
- [ ] Verify can download compliance docs
- [ ] Tap back to return

#### TC-3.3: Alerts Button
- [ ] From home, tap "Alerts" button
- [ ] **Expected Result:** Navigate to `/notifications`
- [ ] Verify institutional-specific alerts displayed
- [ ] Verify alerts are about compliance, deliveries, approvals
- [ ] Verify can mark alerts as read
- [ ] Tap back to return

#### TC-3.4: Team Button
- [ ] From home, tap "Team" button
- [ ] **Expected Result:** Navigate to `/messages`
- [ ] Verify team members/approvers listed
- [ ] Verify can communicate with team
- [ ] Verify approval workflow visible
- [ ] Tap back to return

#### TC-3.5: Invoices Button
- [ ] From home, tap "Invoices" button
- [ ] **Expected Result:** Navigate to `/orders`
- [ ] Verify institutional invoices/POs listed
- [ ] Verify can view invoice details
- [ ] Verify can download invoices
- [ ] Verify payment status shown
- [ ] Tap back to return

#### TC-3.6: Approval Workflow
- [ ] Verify Institutional Approver variant has same utilities
- [ ] Verify approver has access to pending approvals in Team section
- [ ] Verify can approve/reject requests

### Pass Criteria
- ✅ All 4 institutional utilities accessible
- ✅ Compliance documentation available
- ✅ Alerts properly categorized
- ✅ Team/approver workflow functional
- ✅ Invoices visible and downloadable

### Failure Criteria
- ❌ Consumer utilities showing instead
- ❌ Can't access compliance documents
- ❌ Invoices not visible
- ❌ Team collaboration broken

---

## 🏪 **Test Scenario 4: FRANCHISE OWNER ROLE**

### User Profile
- **Role:** Franchise Owner
- **Expected Header Color:** Orange (#F3951A)
- **Test Account:** Create franchise account

### Utility Buttons to Test
```
1. Dashboard     → /franchise-dashboard
2. Stock         → /products
3. Sales         → /orders
4. Store         → /help-support
```

### Test Cases

#### TC-4.1: Header Display
- [ ] Sign in as Franchise Owner
- [ ] Navigate to Home
- [ ] Verify header displays "Franchise Owner" in orange
- [ ] Verify 4 franchise-specific buttons visible
- [ ] Verify buttons are: Dashboard, Stock, Sales, Store

#### TC-4.2: Dashboard Button
- [ ] From home, tap "Dashboard" button
- [ ] **Expected Result:** Navigate to `/franchise-dashboard`
- [ ] Verify analytics/KPIs displayed
- [ ] Verify sales metrics shown
- [ ] Verify inventory overview visible
- [ ] Verify can access detailed analytics
- [ ] Tap back to return

#### TC-4.3: Stock Button
- [ ] From home, tap "Stock" button
- [ ] **Expected Result:** Navigate to `/products`
- [ ] Verify franchise inventory displayed
- [ ] Verify stock levels shown
- [ ] Verify low stock alerts visible
- [ ] Verify can place reorder
- [ ] Tap back to return

#### TC-4.4: Sales Button
- [ ] From home, tap "Sales" button
- [ ] **Expected Result:** Navigate to `/orders`
- [ ] Verify franchise orders/sales listed
- [ ] Verify sales metrics accessible
- [ ] Verify performance dashboard available
- [ ] Tap back to return

#### TC-4.5: Store Button
- [ ] From home, tap "Store" button
- [ ] **Expected Result:** Navigate to `/help-support`
- [ ] Verify store settings/management options
- [ ] Verify store info editable
- [ ] Verify store configuration accessible
- [ ] Tap back to return

#### TC-4.6: Staff Management
- [ ] Verify franchise can access staff management from settings
- [ ] Verify can add/remove staff members
- [ ] Verify can assign roles to staff

### Pass Criteria
- ✅ All franchise utilities functional
- ✅ Dashboard shows accurate analytics
- ✅ Inventory management operational
- ✅ Sales tracking working
- ✅ Store settings accessible

### Failure Criteria
- ❌ Dashboard analytics missing
- ❌ Inventory levels incorrect
- ❌ Can't manage store settings
- ❌ Sales data not updating

---

## 🛒 **Test Scenario 5: WHOLESALE BUYER ROLE**

### User Profile
- **Role:** Wholesale Buyer
- **Expected Header Color:** Forest Green (#1E7F4E)
- **Test Account:** Use existing or create wholesale account

### Utility Buttons to Test
```
1. Orders        → /orders
2. Bulk Rate     → /products
3. Account       → /payment-methods
4. Support       → /help-support
```

### Test Cases

#### TC-5.1: Header Display
- [ ] Sign in as Wholesale Buyer
- [ ] Navigate to Home
- [ ] Verify header displays "Wholesale Buyer" in forest green
- [ ] Verify 4 wholesale-specific buttons visible
- [ ] Verify buttons are: Orders, Bulk Rate, Account, Support

#### TC-5.2: Orders Button
- [ ] From home, tap "Orders" button
- [ ] **Expected Result:** Navigate to `/orders`
- [ ] Verify wholesale orders displayed
- [ ] Verify bulk quantities shown
- [ ] Verify shipment tracking available
- [ ] Verify delivery status visible
- [ ] Tap back to return

#### TC-5.3: Bulk Rate Button
- [ ] From home, tap "Bulk Rate" button
- [ ] **Expected Result:** Navigate to `/products`
- [ ] Verify wholesale pricing displayed
- [ ] Verify bulk discounts shown
- [ ] Verify minimum order quantities displayed
- [ ] Verify can get price quotes
- [ ] Tap back to return

#### TC-5.4: Account Button
- [ ] From home, tap "Account" button
- [ ] **Expected Result:** Navigate to `/payment-methods`
- [ ] Verify payment terms displayed
- [ ] Verify credit limit shown
- [ ] Verify payment history visible
- [ ] Verify can update payment methods
- [ ] Tap back to return

#### TC-5.5: Support Button
- [ ] From home, tap "Support" button
- [ ] **Expected Result:** Navigate to `/help-support`
- [ ] Verify wholesale support contact info
- [ ] Verify can submit support ticket
- [ ] Verify FAQs for wholesale available
- [ ] Tap back to return

#### TC-5.6: Bulk Purchase Flow
- [ ] Navigate to Products via Bulk Rate button
- [ ] Select product
- [ ] Increase quantity (test bulk ordering)
- [ ] Add to cart
- [ ] Proceed to checkout
- [ ] Verify bulk pricing applied
- [ ] Verify header persists during checkout

### Pass Criteria
- ✅ All wholesale utilities functional
- ✅ Bulk pricing correctly displayed
- ✅ Order tracking working
- ✅ Payment terms accessible
- ✅ Support system responsive

### Failure Criteria
- ❌ Bulk discounts not applied
- ❌ Can't track orders
- ❌ Minimum quantities not enforced
- ❌ Support not accessible

---

## 👨‍💼 **Test Scenario 6: ADMIN ROLE**

### User Profile
- **Role:** Admin / Super Admin
- **Expected Header Color:** Red (#EF4444) / Dark Red (#DC2626)
- **Test Account:** Admin account only

### Utility Buttons to Test
```
1. Control Tower  → /admin-dashboard
2. Users         → /admin-users
3. Analytics     → /notifications
4. Security      → /settings
```

### Test Cases

#### TC-6.1: Header Display
- [ ] Sign in as Admin
- [ ] Navigate to Home
- [ ] Verify header displays "Admin" in red
- [ ] Verify 4 admin-specific buttons visible
- [ ] Verify buttons are: Control Tower, Users, Analytics, Security

#### TC-6.2: Control Tower Button
- [ ] From home, tap "Control Tower" button
- [ ] **Expected Result:** Navigate to `/admin-dashboard`
- [ ] Verify admin control panel displayed
- [ ] Verify system metrics visible
- [ ] Verify can access all admin functions
- [ ] Tap back to return

#### TC-6.3: Users Button
- [ ] From home, tap "Users" button
- [ ] **Expected Result:** Navigate to `/admin-users`
- [ ] Verify user list displayed
- [ ] Verify can search users
- [ ] Verify can view user details
- [ ] Verify can manage user roles
- [ ] Verify can deactivate/activate users
- [ ] Tap back to return

#### TC-6.4: Analytics Button
- [ ] From home, tap "Analytics" button
- [ ] **Expected Result:** Navigate to `/notifications` (or admin analytics)
- [ ] Verify system-wide analytics displayed
- [ ] Verify can view metrics
- [ ] Verify can generate reports
- [ ] Verify data export functionality
- [ ] Tap back to return

#### TC-6.5: Security Button
- [ ] From home, tap "Security" button
- [ ] **Expected Result:** Navigate to `/settings`
- [ ] Verify security settings accessible
- [ ] Verify can manage API keys
- [ ] Verify can view audit logs
- [ ] Verify can configure security policies
- [ ] Tap back to return

#### TC-6.6: Super Admin Features
- [ ] If testing Super Admin role
- [ ] Verify can access all admin functions
- [ ] Verify can manage admins
- [ ] Verify can access system configuration
- [ ] Verify can access database functions

#### TC-6.7: Permission Enforcement
- [ ] Verify regular admin sees limited functions
- [ ] Verify super admin sees all functions
- [ ] Verify non-admin cannot access admin utilities
- [ ] Verify role-based access control enforced

### Pass Criteria
- ✅ All admin utilities accessible
- ✅ User management functional
- ✅ Analytics/metrics visible
- ✅ Security settings configurable
- ✅ Audit logs available
- ✅ Permission hierarchy enforced

### Failure Criteria
- ❌ Can't manage users
- ❌ Analytics not accessible
- ❌ Security settings locked
- ❌ Regular user can access admin functions
- ❌ Audit trails missing

---

## 🔍 **Runtime Issue Monitoring Checklist**

### Console Error Checks
- [ ] No "Undefined name" errors
- [ ] No "The named parameter is not defined" errors
- [ ] No "The getter '...' isn't defined" errors
- [ ] No Firebase permission errors (after rules deployed)
- [ ] No navigation/routing errors
- [ ] No provider state management errors

### Performance Checks
- [ ] Header renders without lag
- [ ] Button taps respond immediately
- [ ] Navigation is smooth (no janky transitions)
- [ ] No frame drops when switching roles
- [ ] Memory usage reasonable (<200MB)

### Functional Checks
- [ ] All buttons navigate to correct screens
- [ ] Header persists on ALL screens
- [ ] Color coding matches role
- [ ] Profile info displays correctly
- [ ] Bottom tabs still functional
- [ ] Back button works from all screens

### Visual Checks
- [ ] Header layout proper on different screen sizes
- [ ] Text not cut off or overlapping
- [ ] Icons render correctly
- [ ] Colors display properly
- [ ] Spacing and alignment correct
- [ ] No visual glitches/artifacts

### State Management Checks
- [ ] User role persists on reload
- [ ] Header updates when switching roles
- [ ] Profile info synchronized with auth state
- [ ] Notifications badge updates real-time
- [ ] No duplicate renders

### Network Checks
- [ ] Navigation doesn't require network calls
- [ ] Firebase operations work when offline
- [ ] No unnecessary API requests
- [ ] No slow network requests blocking UI

---

## 📊 **Test Results Template**

```
Role: [Member/Seller/Institutional/Franchise/Wholesale/Admin]
Test Date: [Date]
Device: itel A6611L
Test Duration: [Time]

Tests Passed: __ / __
Tests Failed: __ / __

Passed Tests:
- [ ] TC-X.X: [Description]
- [ ] TC-X.X: [Description]

Failed Tests:
- [ ] TC-X.X: [Description] → [Error Details]
- [ ] TC-X.X: [Description] → [Error Details]

Console Errors:
[None] / [List errors found]

Performance Issues:
[None] / [List issues found]

Screenshots:
[Attach screenshots of header for each role]

Notes:
[Additional observations]
```

---

## 🚀 **Quick Test Checklist (5-Minute Per Role)**

For rapid testing of all roles:

- [ ] **Step 1:** Sign in
- [ ] **Step 2:** Verify header displays correct role + color
- [ ] **Step 3:** Tap each of 4 utility buttons
- [ ] **Step 4:** Verify each navigates to correct screen
- [ ] **Step 5:** Verify header persists on target screen
- [ ] **Step 6:** Tap back button
- [ ] **Step 7:** Verify return to home
- [ ] **Step 8:** Test bottom navigation tabs
- [ ] **Step 9:** Check for console errors
- [ ] **Step 10:** Sign out and repeat for next role

---

## 📱 **Device Commands**

### Monitor Device Logs
```bash
# Real-time logs
adb logcat -v time flutter:D DartVM:D AndroidRuntime:E *:S

# Filter for errors only
adb logcat *:E | grep -E "(ERROR|Exception|FATAL)"

# Clear logs
adb logcat -c

# Dump current logs to file
adb logcat > logs.txt
```

### Check Device Info
```bash
# Device info
adb shell getprop ro.product.model

# Android version
adb shell getprop ro.build.version.release

# Running processes
adb shell pm list packages | grep coop
```

---

## ✅ **Deployment Checklist**

Before finalizing implementation:
- [ ] All 6 roles tested
- [ ] All buttons functional
- [ ] Header persists on all screens
- [ ] No console errors
- [ ] Performance acceptable
- [ ] Visual design correct
- [ ] Documentation complete
- [ ] Screenshots captured
- [ ] User feedback collected

---

**Last Updated:** May 10, 2026
**Status:** Ready for Testing
**Device:** itel A6611L (Android 15)
