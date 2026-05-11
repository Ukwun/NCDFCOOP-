# NCDF Money - Automated Testing & Quick Reference

## 🎬 Quick Start - Test One Role (5 Minutes)

### Setup (Do Once)
1. **On Device:** Unlock phone, open app (should be running)
2. **On PC:** Open terminal in `c:\development\coop_commerce\`
3. **On PC:** Run monitoring (already started):
   ```
   ✅ Monitoring is active and saving logs to timestamped file
   ```

### Test Any Single Role (5 Min Sequence)

#### Step 1: Verify Login (30 sec)
```
What to see on device:
- App home screen visible
- User name displayed at top
- 5 bottom tabs visible (Home, Offers, Messages, Cart, My NCDFCOOP)
- New header visible with role badge and utility buttons
```

#### Step 2: Check Header (30 sec)
```
What to look for:
✓ Header at very top of screen
✓ Profile avatar shows user initial
✓ User name visible next to avatar
✓ Role badge with color coding
✓ 4 utility buttons below header
✓ Notifications bell, Settings gear, Help icon on right
```

#### Step 3: Test Each Button (60 sec per button × 4)
```
For each button:
1. TAP the button
2. WAIT for screen to load (max 2 seconds)
3. VERIFY correct screen appears
4. TAP back button
5. VERIFY return to home with header intact
6. WATCH logs for any error messages
```

**Test Buttons for MEMBER Role:**
- [ ] Tap "KYC Status" → Should see Profile screen
- [ ] Tap "Wallet" → Should see Payment Methods screen
- [ ] Tap "Loyalty" → Should see Member Loyalty screen
- [ ] Tap "Savings" → Should see Member Benefits screen

**Test Buttons for SELLER Role:**
- [ ] Tap "Leads" → Should see Messages screen
- [ ] Tap "Sales" → Should see Orders screen
- [ ] Tap "Commission" → Should see Payment Methods screen
- [ ] Tap "Products" → Should see Products screen

**Test Buttons for INSTITUTIONAL Role:**
- [ ] Tap "Compliance" → Should see Help/Support screen
- [ ] Tap "Alerts" → Should see Notifications screen
- [ ] Tap "Team" → Should see Messages screen
- [ ] Tap "Invoices" → Should see Orders screen

**Test Buttons for FRANCHISE Role:**
- [ ] Tap "Dashboard" → Should see Franchise Dashboard screen
- [ ] Tap "Stock" → Should see Products screen
- [ ] Tap "Sales" → Should see Orders screen
- [ ] Tap "Store" → Should see Help/Support screen

**Test Buttons for WHOLESALE Role:**
- [ ] Tap "Orders" → Should see Orders screen
- [ ] Tap "Bulk Rate" → Should see Products screen
- [ ] Tap "Account" → Should see Payment Methods screen
- [ ] Tap "Support" → Should see Help/Support screen

**Test Buttons for ADMIN Role:**
- [ ] Tap "Control Tower" → Should see Admin Dashboard screen
- [ ] Tap "Users" → Should see Admin Users screen
- [ ] Tap "Analytics" → Should see Notifications screen
- [ ] Tap "Security" → Should see Settings screen

#### Step 4: Test Tab Switching (60 sec)
```
While on Home screen:
1. Tap "Offers" tab → Header should stay at top
2. Tap "Messages" tab → Header should stay at top
3. Tap "Cart" tab → Header should stay at top
4. Tap "My NCDFCOOP" tab → Header should stay at top
5. Tap "Home" tab → Return to home, header visible

CRITICAL: Header must be visible on ALL tabs
```

#### Step 5: Test Global Utilities (60 sec)
```
1. Tap Notifications bell icon
   → Should navigate to Notifications screen
   → Tap back to return

2. Tap Settings gear icon
   → Should navigate to Settings screen
   → Tap back to return

3. Tap Help question mark icon
   → Should navigate to Help/Support screen
   → Tap back to return
```

#### Step 6: Verify Logs (30 sec)
```
After all buttons tested:
1. Check for ERROR messages in monitoring window
2. Check for EXCEPTION messages
3. Check for FATAL CRASH messages
4. Note down any issues found
```

### Result for This Role
```
PASS ✅ if:
- All buttons navigate correctly
- Header visible on all screens
- No console errors
- No app crashes
- Tab switching works
- Global utilities work

FAIL ❌ if:
- Any button doesn't navigate
- Header disappears
- Console shows errors
- App crashes
- Tab switching breaks
- Utilities don't work
```

---

## 📋 Testing Matrix (All Roles at a Glance)

| Role | Color | Button 1 | Button 2 | Button 3 | Button 4 | Time |
|------|-------|----------|----------|----------|----------|------|
| Member | Gold | KYC → /profile | Wallet → /payment-methods | Loyalty → /member-loyalty | Savings → /member-benefits | 5 min |
| Seller | Green | Leads → /messages | Sales → /orders | Commission → /payment-methods | Products → /products | 5 min |
| Institutional | Purple | Compliance → /help-support | Alerts → /notifications | Team → /messages | Invoices → /orders | 5 min |
| Franchise | Orange | Dashboard → /franchise-dashboard | Stock → /products | Sales → /orders | Store → /help-support | 5 min |
| Wholesale | Forest | Orders → /orders | Bulk Rate → /products | Account → /payment-methods | Support → /help-support | 5 min |
| Admin | Red | Control Tower → /admin-dashboard | Users → /admin-users | Analytics → /notifications | Security → /settings | 5 min |

**Total Time: 30 minutes for all 6 roles**

---

## 🔍 Live Error Monitoring Window

Monitor this in real-time while testing:

### What to Watch For

#### 🔴 CRITICAL (Stop & Fix)
```
E/flutter: Unhandled Exception: RouteException
→ Fix: Check route exists in router.dart

E/flutter: NoSuchMethodError: The method 'X' was called on null
→ Fix: Add null check in AppHeaderUtility

E/flutter: FATAL EXCEPTION: MainActivity
→ Fix: Restart app, check for Firebase issues

E/firebase: PERMISSION_DENIED
→ Fix: Redeploy Firestore rules
```

#### 🟡 WARNING (Note & Continue)
```
W/Choreographer: Skipped XXX frames
→ Note: Performance issue, may need optimization

W/e.coop_commerce: Verification took XXXms
→ Note: Slow operation detected

D/flutter: GC freed XXX MB
→ Note: Memory pressure, normal if occasional
```

#### 🟢 INFO (Ignore)
```
I/flutter: ✅ Firebase initialized
I/flutter: [Header] Displaying utilities for role: X
I/flutter: [Navigation] Pushing route: X
E/com.facebook.GraphResponse: Invalid application ID
→ Expected, Facebook not fully configured
```

---

## 📊 Real-Time Dashboard

While testing, open a second terminal to monitor stats:

```bash
# Watch for errors appearing
adb logcat -v time | grep -i "error\|exception\|fatal" & 

# Count errors as they appear
watch "adb logcat -d | grep -c 'E/'"

# Monitor memory
adb shell dumpsys meminfo com.example.coop_commerce | grep TOTAL
```

---

## 📝 Quick Test Log Entry

For each role tested, copy this and fill in:

```
ROLE: [Member/Seller/Institutional/Franchise/Wholesale/Admin]
TIME: [HH:MM]
TESTER: [Your name]

RESULTS:
✓ Header displays correct role
✓ Color matches role
✓ All 4 buttons present
✓ Button 1 navigates correctly
✓ Button 2 navigates correctly
✓ Button 3 navigates correctly
✓ Button 4 navigates correctly
✓ Header persists on all tabs
✓ Global utilities work
✓ No console errors
✓ No app crashes

ERRORS FOUND:
[None / List any errors]

NOTES:
[Any observations]

SCREENSHOT: [Y/N] - Timestamp: ___
```

---

## 🎯 Focus Areas for Monitoring

### Header-Specific
- [ ] Header renders without lag
- [ ] Role color changes with user role
- [ ] Profile name/avatar displays correctly
- [ ] Role badge is clickable (shows role switcher)
- [ ] Header doesn't overlap content below

### Navigation-Specific
- [ ] Button tap → screen appears within 1 second
- [ ] Back button → returns to home with header intact
- [ ] Tab switching → header stays visible
- [ ] No "RouteException" errors in logs
- [ ] No "Could not find Route" errors

### Performance-Specific
- [ ] No frame skipping when navigating
- [ ] No memory leaks (check GC logs)
- [ ] No slow animations
- [ ] App responsive during testing
- [ ] Buttons respond immediately to taps

### State-Specific
- [ ] Role persists correctly after navigation
- [ ] User info stays current
- [ ] No duplicate widgets rendering
- [ ] Provider state synchronized
- [ ] No orphaned listeners

### Visual-Specific
- [ ] Text not cut off or overlapping
- [ ] Icons render clearly
- [ ] Colors display correctly per role
- [ ] Spacing looks balanced
- [ ] No visual glitches on navigation

---

## 🚨 Troubleshooting Quick Links

### Problem: Header not visible
```
Check: Is it in ScaffoldWithNavBar.dart?
Fix: Verify AppHeaderUtility() is child of Scaffold
Re-run: flutter run -d [device-id]
```

### Problem: Button navigates to wrong screen
```
Check: Route name in AppHeaderUtility.dart
Fix: Verify route exists in router.dart (compare spelling)
Re-run: flutter analyze lib/widgets/app_header_utility.dart
```

### Problem: Header disappears on tabs
```
Check: Is header inside Column that wraps navigationShell?
Fix: Verify scaffold_with_navbar.dart has Column wrapper
Re-run: flutter clean && flutter run
```

### Problem: App crashes when tapping button
```
Check: Device logs for exception
Fix: Likely context not passed to _buildUtilityButton
Re-run: flutter run --clean
```

### Problem: Colors wrong or not showing
```
Check: Role color mapping in _getRoleColor()
Fix: Verify AppColors constants match expected colors
Re-run: flutter run
```

### Problem: Buttons unresponsive
```
Check: Is GestureDetector properly implemented?
Fix: Verify onTap: () => context.pushNamed('route')
Re-run: flutter clean && flutter run
```

---

## 📋 Session Checklist

### Pre-Testing
- [ ] Device connected (`adb devices` shows device)
- [ ] App installed and running
- [ ] User logged in
- [ ] Monitoring terminal active
- [ ] Log file being captured

### Per Role (5 min × 6 roles = 30 min)
- [ ] Role 1 header verified
- [ ] Role 1 buttons tested (4 × 1 min)
- [ ] Role 1 tabs tested (30 sec)
- [ ] Role 1 global utilities tested (30 sec)
- [ ] Role 1 logs checked
- [ ] [Repeat for roles 2-6]

### Post-Testing
- [ ] Stop monitoring (`Ctrl+C`)
- [ ] Save final logs to file
- [ ] Generate error report
- [ ] Compile results document
- [ ] Note any issues for fixing
- [ ] Get approval to move to next phase

---

## 🎬 Running Tests Live

### Terminal 1: Monitoring (Already Active)
```
✅ Running: adb logcat -v time "*:E" "flutter:D"
📁 Saving to: runtime_monitoring_[timestamp].log
📊 Captures: Errors + Flutter debug messages
⏱️ Real-time: All errors appear immediately
```

### Terminal 2: Run Tests (Use When Ready)
```
When you're ready for each role:
1. Sign in to that role
2. Go to home screen
3. Note the time
4. Execute test steps above
5. Record results
6. Check monitoring terminal for errors
```

### After Each Role
```
Terminal 1 (monitoring):
- Any red [E/] messages? → Document them
- Any [FATAL]? → Stop and fix
- Any [Exception]? → Note the stack trace

Terminal 2 (result):
- Pass ✅ or Fail ❌
- Error count
- Performance notes
```

---

## 📈 Success Metrics

**Target Results:**
- ✅ 6 roles tested (100% coverage)
- ✅ 24 buttons tested (4 per role)
- ✅ 0 critical errors
- ✅ 0 app crashes
- ✅ <5 warning messages
- ✅ Header visible on 100% of screens
- ✅ All navigation working
- ✅ All tabs functional

**Success = PASS on all above criteria**

---

## 🔄 Retry Procedure (If Issues Found)

1. **Identify** the specific button/role with issue
2. **Screenshot** the error
3. **Note** time when error occurred
4. **Check** device logs for exception
5. **Fix** the code (if needed)
6. **Rebuild** with `flutter run`
7. **Re-test** that specific button
8. **Verify** error is resolved

---

## 📞 Support Commands

Quick reference for common commands:

```bash
# Check device is connected
adb devices

# Clear logs before test
adb logcat -c

# See all current logs
adb logcat -d

# See only errors
adb logcat | grep E/

# See Flutter debug logs
adb logcat flutter:D

# See specific app logs
adb logcat | grep coop_commerce

# Stop app
adb shell am force-stop com.example.coop_commerce

# Restart app
flutter run -d [device-id]

# Clean build
flutter clean && flutter pub get && flutter run
```

---

**Status:** Testing Guide Ready
**Monitoring:** Active (Terminal running)
**Device:** itel A6611L (Android 15)
**Last Updated:** May 10, 2026
