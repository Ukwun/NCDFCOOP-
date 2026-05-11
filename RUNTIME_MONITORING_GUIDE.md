# NCDF Money - Runtime Error Monitoring Guide

## 📊 Real-Time Monitoring Setup

### Purpose
Detect and log runtime issues during testing of new Alibaba-inspired header feature in real-time.

---

## 🎯 What to Monitor

### Critical Issues (Stop Testing)
1. **App Crashes**
   - Signature: `FATAL EXCEPTION` or `Fatal error`
   - Action: Screenshot, note steps, restart app

2. **Navigation Errors**
   - Signature: `RouteException` or `Could not find Route`
   - Action: Check route name in AppHeaderUtility

3. **Firebase Permission Errors**
   - Signature: `PERMISSION_DENIED` in Firestore calls
   - Action: Redeploy Firestore rules

4. **Null Pointer Exceptions**
   - Signature: `NullPointerException` or `NoSuchMethodError`
   - Action: Check provider initialization

5. **State Management Failures**
   - Signature: `RiverpodError` or `ProviderException`
   - Action: Check provider dependencies

### Warning Issues (Note & Continue)
1. **Slow Navigation**
   - Symptom: Button tap takes >2 seconds to navigate
   - Possible Cause: Heavy widget rebuilds, async operations
   - Action: Check for expensive operations in build()

2. **Memory Leaks**
   - Symptom: App slows down over time
   - Monitor with: DevTools memory profiler
   - Action: Check for listener cleanup

3. **Frame Drops**
   - Symptom: Animation or transition feels janky
   - Detected in logs: "Skipped XX frames"
   - Action: Check rendering performance

4. **UI Glitches**
   - Symptom: Text cut off, overlapping widgets, layout issues
   - Action: Test on different screen sizes

5. **Timing Issues**
   - Symptom: Header flickers or updates late
   - Cause: Race conditions in state updates
   - Action: Add loading states

### Info Issues (Monitor Only)
1. **Facebook Graph Errors** (Expected)
   - Message: "Error validating application. Invalid application ID"
   - Status: Non-critical, Facebook SDK not fully configured
   - Action: Ignore

2. **Android Warnings**
   - Message: "OnBackInvokedCallback not enabled"
   - Status: Android 12+ compatibility warning
   - Action: Can be fixed in AndroidManifest.xml if needed

3. **Verification Timing Warnings**
   - Message: "Verification of ... took XXms"
   - Status: Performance info, not an error
   - Action: Monitor if >1000ms

---

## 🔧 Log Monitoring Commands

### Start Real-Time Monitoring (Main Device Logs)
```bash
adb logcat -v time flutter:D *:E | tee monitoring.log
```
This shows:
- All Flutter debug messages (flutter:D)
- All error-level messages across all tags (*:E)
- Timestamps for correlation
- Saves to monitoring.log file

### Filter for App Startup Issues
```bash
adb logcat -v time coop_commerce:* flutter:D | grep -E "(ERROR|Exception|Crash|FATAL)"
```

### Monitor Specific Subsystems

**Firebase Operations:**
```bash
adb logcat -v time Firebase:D
```

**Navigation/Routing:**
```bash
adb logcat -v time flutter:D | grep -i "route\|navigate\|push"
```

**State Management:**
```bash
adb logcat -v time flutter:D | grep -i "provider\|riverpod\|state"
```

**Memory Pressure:**
```bash
adb logcat -v time | grep -i "gc\|memory\|oom"
```

---

## 📋 Expected Log Signatures During Normal Operation

### App Launch (Normal)
```
I/flutter: 📱 App starting...
I/flutter: Initializing Firebase...
I/flutter: ✅ Firebase initialized successfully
I/flutter: ✅ FCM initialized
I/flutter: 🔧 Initializing service locator...
I/flutter: ✅ ServiceLocator initialized successfully
I/flutter: ✅ App initialization complete
I/flutter: ✅ User retrieved: [email]
I/flutter: ✅ AuthController initialized successfully
```

### Header Rendering (Normal)
```
I/flutter: [Header] Displaying utilities for role: member
I/flutter: [Header] Building 4 member utility buttons
I/flutter: [Navigation] Navigating to: /payment-methods
```

### Button Tap (Normal)
```
I/flutter: [Button Tap] KYC Status button tapped
I/flutter: [Navigation] Pushing route: /profile
```

### Role Switch (Normal)
```
I/flutter: [RoleSwitch] User role changed from: seller to: member
I/flutter: [Header] Rebuilding with new role: member
```

---

## ❌ Error Signature Reference

### Navigation Errors
```
E/flutter: [ERROR:flutter/runtime/dart_vm_initializer.cc(41)]
Unhandled Exception: RouteException: Could not find Route named '/unknown-route'
```
**Fix:** Verify route exists in router.dart, check spelling

### Provider Errors
```
E/flutter: Unhandled Exception: A ProviderContainer was used after being disposed.
```
**Fix:** Check provider initialization, ensure ref is valid in scope

### Build Errors (Already Resolved)
```
E/flutter: No such method
```
**Fix:** Clean build with `flutter clean && flutter pub get`

### Firebase Permission Errors (Already Resolved)
```
E/firebase: PERMISSION_DENIED: Missing or insufficient permissions
```
**Fix:** Update Firestore rules, redeploy with `firebase deploy --only firestore:rules`

### Null Reference Errors
```
E/flutter: Unhandled Exception: NoSuchMethodError: The method 'foo' was called on null.
```
**Fix:** Add null checks, use optional chaining (?.), default values

---

## 🎯 Testing Checklist for Each Role

### Before Starting
- [ ] Clear app logs: `adb logcat -c`
- [ ] Ensure app is running on device
- [ ] Open monitoring terminal showing real-time logs
- [ ] Have screenshot tool ready

### During Testing Each Role
1. **Launch Phase**
   - [ ] Watch for initialization logs
   - [ ] Verify "App initialization complete" appears
   - [ ] Check for any ERROR messages

2. **Navigation Phase**
   - [ ] Tap each utility button
   - [ ] Watch logs for navigation messages
   - [ ] Check for RouteException errors
   - [ ] Verify no "Unhandled Exception" messages

3. **UI Phase**
   - [ ] Watch for widget rebuild messages
   - [ ] Check for "Skipped XX frames" (normal if <100)
   - [ ] Look for layout/rendering warnings

4. **Cleanup Phase**
   - [ ] Return to home screen
   - [ ] Check for state cleanup messages
   - [ ] Verify no resource leaks

### After Testing Each Role
- [ ] Save logs to timestamped file: `role_member_logs_2026-05-10_14-30.txt`
- [ ] Scan logs for errors/warnings
- [ ] Document any issues found
- [ ] Clear logs before next role

---

## 📊 Log Analysis Workflow

### Step 1: Collect Logs During Test
```bash
# Terminal 1: Start monitoring
adb logcat -v time > test_run_logs.txt

# Terminal 2: Run test steps
# ... perform test steps while Terminal 1 captures logs
```

### Step 2: Stop Monitoring & Analyze
```bash
# Stop logcat (Ctrl+C in Terminal 1)

# Search for errors
grep -i "error\|exception\|fatal\|crash" test_run_logs.txt

# Count errors
grep -c "E/" test_run_logs.txt

# Show only Flutter logs
grep "I/flutter" test_run_logs.txt

# Show logs around specific time
grep -A5 -B5 "14:32:15" test_run_logs.txt
```

### Step 3: Generate Report
```bash
echo "=== ERROR SUMMARY ===" > report.txt
grep -i "error" test_run_logs.txt >> report.txt
echo "" >> report.txt
echo "=== WARNINGS ===" >> report.txt
grep -i "warning" test_run_logs.txt >> report.txt
echo "" >> report.txt
echo "=== STATISTICS ===" >> report.txt
echo "Total logs: $(wc -l < test_run_logs.txt)" >> report.txt
echo "Errors: $(grep -c E/ test_run_logs.txt)" >> report.txt
echo "Warnings: $(grep -c W/ test_run_logs.txt)" >> report.txt
```

---

## 🎬 Real-Time Monitoring Session Examples

### Example 1: Normal Member Role Test
```
12:00:00 I/flutter: 📱 App starting...
12:00:02 I/flutter: ✅ Firebase initialized successfully
12:00:03 I/flutter: ✅ App initialization complete
12:00:05 I/flutter: [Header] Displaying utilities for role: member
12:00:06 I/flutter: Member utilities: KYC Status, Wallet, Loyalty, Savings
12:00:08 I/flutter: [Button Tap] Wallet button tapped
12:00:08 I/flutter: [Navigation] Pushing route: /payment-methods
12:00:09 D/flutter: [Screen] PaymentMethods screen loaded
12:00:11 I/flutter: [Navigation] Navigating back to: /home
12:00:12 I/flutter: [Header] Header re-rendered, utilities still member
[✓] Test PASSED - No errors, smooth navigation
```

### Example 2: Error Detected - Navigation Failure
```
12:05:00 I/flutter: [Button Tap] Sales button tapped
12:05:00 I/flutter: [Navigation] Attempting to push: /orders
12:05:01 E/flutter: [ERROR] RouteException: Could not find Route named '/orders'
12:05:01 E/flutter: Unhandled Exception: RouteException...
12:05:02 D/flutter: Navigation failed, staying on home screen
[✗] Test FAILED - RouteException, check router.dart for '/orders' definition
```

### Example 3: Performance Issue Detected
```
12:10:00 I/flutter: [Button Tap] Dashboard button tapped
12:10:00 I/flutter: [Navigation] Pushing route: /franchise-dashboard
12:10:02 W/Choreographer: Skipped 234 frames! The application may be doing too much work on its main thread.
12:10:03 D/flutter: FranchiseDashboard screen loading...
12:10:05 D/flutter: Dashboard data loaded, rendering 150 widgets
12:10:06 W/Choreographer: Skipped 89 frames!
[⚠] Test WARNED - Dashboard loads slowly, consider optimizing widget tree
```

---

## 🛠️ Quick Troubleshooting Guide

### "App crashes after header appears"
**Likely Cause:** Null reference in role-specific button builder
**Debug Steps:**
1. Check logs for "NoSuchMethodError"
2. Look for `_buildMemberUtilities()` error
3. Verify `context` parameter passed correctly
4. Run `flutter analyze`

**Fix:**
```dart
// Before (buggy)
_buildUtilityButton(icon: ...) // context not passed

// After (fixed)
_buildUtilityButton(context: context, icon: ...) // context passed
```

### "Header doesn't show on all screens"
**Likely Cause:** Header only integrated into home screen
**Debug Steps:**
1. Check ScaffoldWithNavBar integration
2. Verify `Column(children: [AppHeaderUtility(), ...])` wraps all screens
3. Check bottom nav structure

**Fix:**
- AppHeaderUtility must be at top of Scaffold, above navigationShell

### "Buttons navigate to wrong screens"
**Likely Cause:** Route names mismatch in AppHeaderUtility
**Debug Steps:**
1. Compare button route in `_buildUtilityButton()`
2. Verify route exists in `router.dart`
3. Check for typos in route names

**Fix:**
```dart
// Check that these match router.dart definitions
context.pushNamed('payment-methods')  // must exist in router
context.pushNamed('profile')           // must exist in router
```

### "Memory usage increases during testing"
**Likely Cause:** Listeners not cleaned up
**Debug Steps:**
1. Monitor with `adb logcat | grep -i "gc"`
2. Check for repeated GC triggers
3. Use DevTools Memory tab

**Fix:**
- Add dispose() methods to ConsumerWidgets
- Clean up StreamSubscriptions
- Clear cached images

### "Colors not displaying correctly"
**Likely Cause:** Theme not applied or color constant wrong
**Debug Steps:**
1. Check `AppColors` enum
2. Verify color code for role
3. Check theme application

**Fix:**
- Verify role color mapping in `_getRoleColor()`
- Check theme is applied to app wrapper

---

## 📈 Monitoring Metrics

### Performance Targets
| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Button response time | <200ms | >300ms | >500ms |
| Screen navigation | <300ms | >500ms | >1000ms |
| Header render time | <100ms | >150ms | >300ms |
| Memory usage | <100MB | >150MB | >200MB |
| Frame rate | 60 FPS | >10 frames dropped | App crashes |
| Startup time | <3s | >5s | >10s |

### Data Collection Template
```
Test Date: 2026-05-10
Device: itel A6611L
Role: [Role]

Performance Metrics:
- Button response time: ___ms
- Navigation speed: ___ms
- Memory at start: ___MB
- Memory at end: ___MB
- Frames dropped: ___
- Errors found: ___

Issues:
[List any issues found]

Recommendations:
[List optimizations needed]
```

---

## 🎯 Session Checklist

- [ ] Monitor setup complete (logcat running)
- [ ] Test role 1: Member (collect logs)
- [ ] Analyze member logs (check errors)
- [ ] Test role 2: Seller (collect logs)
- [ ] Analyze seller logs (check errors)
- [ ] Test role 3: Institutional (collect logs)
- [ ] Analyze institutional logs (check errors)
- [ ] Test role 4: Franchise (collect logs)
- [ ] Analyze franchise logs (check errors)
- [ ] Test role 5: Wholesale (collect logs)
- [ ] Analyze wholesale logs (check errors)
- [ ] Test role 6: Admin (collect logs)
- [ ] Analyze admin logs (check errors)
- [ ] Generate final report
- [ ] Fix any critical issues
- [ ] Re-test fixed issues

---

**Status:** Ready for Monitoring
**Last Updated:** May 10, 2026
**Device:** itel A6611L (Android 15)
