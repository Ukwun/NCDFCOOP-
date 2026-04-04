═════════════════════════════════════════════════════════════════════════════
  CLIENT TESTING GUIDE - COOPCOMMERCE APP v1.0
═════════════════════════════════════════════════════════════════════════════

APK FILE INFORMATION:
├─ Filename: app-release.apk
├─ Size: 48.4 MB
├─ Location: C:\development\coop_commerce\build\app\outputs\flutter-apk\app-release.apk
├─ Version: 1.0 (Release Build)
└─ Platform: Android (ARM64)

BUILD DATE: April 4, 2026
STATUS: ✅ Production-Ready for Testing

═════════════════════════════════════════════════════════════════════════════
INSTALLATION INSTRUCTIONS
═════════════════════════════════════════════════════════════════════════════

STEP 1: ENABLE UNKNOWN SOURCES (One-time setup)
──────────────────────────────────────────────

On your Android device:
1. Open Settings
2. Go to: Security (or Privacy & Security)
3. Find: "Unknown Sources" or "Install Unknown Apps"
4. Enable it (Allow installation from files)

Note: This is required because the APK is not from Google Play Store.

STEP 2: TRANSFER APK TO YOUR DEVICE
──────────────────────────────────

Option A: Using USB Cable
├─ Connect device to computer via USB
├─ Copy app-release.apk to your device's Download folder
└─ Safely eject device

Option B: Email/Cloud
├─ Send the APK via email
├─ Download on your device
└─ Open from Downloads app

Option C: QR Code (if available)
├─ Create a QR code linking to the APK
├─ Scan with device camera
└─ Download and open

STEP 3: INSTALL THE APP
───────────────────────

1. Open Files app or Downloads folder on your device
2. Find "app-release.apk"
3. Tap to install
4. When prompted, tap "Install"
5. Wait for installation to complete
6. Tap "Open" OR find "CoopCommerce" in your app drawer

═════════════════════════════════════════════════════════════════════════════
CRITICAL TESTING CHECKLIST
═════════════════════════════════════════════════════════════════════════════

🔐 1. USER AUTHENTICATION
   □ Launch app
   □ Sign up with new account (email + password)
   □ Log out
   □ Log in with created account
   □ Verify user profile data saves
   Expected: Account created and login works ✅

🏪 2. BROWSING & PRODUCTS
   □ Browse different categories
   □ Search for products
   □ View product details (images, descriptions, prices)
   □ Check product availability
   Expected: All products display correctly ✅

🛒 3. SHOPPING CART
   □ Add items to cart
   □ Increase/decrease quantities
   □ Remove items from cart
   □ View cart total (includes tax)
   □ Cart persists after app restart
   Expected: Cart works and saves ✅

📍 4. DELIVERY ADDRESS
   □ Add delivery address
   □ Verify address fields
   □ Edit address
   □ Delete address
   □ Select address during checkout
   Expected: Address management works ✅

💳 5. PAYMENT SYSTEM (Flutterwave Integration)
   
   TEST A: CARD PAYMENT
   ────────────────────
   □ Go to Checkout
   □ Select "Card Payment"
   □ Click "Pay ₦X.XX"
   □ Use test card: 4242 4242 4242 4242
   □ Expiry: Any future date (e.g., 12/25)
   □ CVV: Any 3 digits (e.g., 123)
   □ Complete payment
   □ Verify order shows "confirmed" status
   Expected: Card payment works, order immediately confirmed ✅

   TEST B: BANK TRANSFER
   ─────────────────────
   □ Go to Checkout (NEW order)
   □ Select "Bank Transfer"
   □ Review account details dialog
   □ Verify displayed:
     ├─ Bank name
     ├─ Account number (with copy button - test it!)
     ├─ Reference code
     └─ Transfer instructions
   □ Click "I've Transferred the Money"
   □ Verify order shows "pending verification" status
   Expected: Order awaits manual verification ✅

✅ 6. ORDER HISTORY
   □ Go to My Orders section
   □ View completed orders
   □ View order details (items, address, total)
   □ Check order status
   Expected: Order history displays correctly ✅

📦 7. NOTIFICATIONS
   □ Allow notifications when prompted
   □ Complete a purchase
   □ Check if notification is received
   Expected: Notifications work for order updates ✅

⚙️ 8. APP PERFORMANCE
   □ Scroll through product lists (check smoothness)
   □ Switch between screens quickly
   □ Load images in product view
   □ Check app stability during checkout
   Expected: App is smooth and responsive ✅

🌐 9. NETWORK CONNECTIVITY
   □ Use over WiFi and mobile data
   □ Go offline during load and come back online
   □ Verify app handles network changes gracefully
   Expected: App works on both network types ✅

🔄 10. APP RESTART & DATA PERSISTENCE
    □ Log in > Add to cart > Exit app
    □ Restart app
    □ Verify you're still logged in
    □ Verify cart items are still there
    Expected: Session and cart data persist ✅

═════════════════════════════════════════════════════════════════════════════
KNOWN TEST CREDENTIALS
═════════════════════════════════════════════════════════════════════════════

CARD PAYMENT (Test Mode):
├─ Card: 4242 4242 4242 4242
├─ Expiry: 12/25 (any future date)
├─ CVV: 123 (any 3 digits)
└─ Name: Any name

BANK TRANSFER (Test Mode):
├─ Account Details: Displayed in app during checkout
├─ Amount: Use exact amount shown
└─ Reference: Will be provided in dialog

═════════════════════════════════════════════════════════════════════════════
REPORTING ISSUES
═════════════════════════════════════════════════════════════════════════════

When reporting bugs, please include:

1. DEVICE INFORMATION
   ├─ Device model (e.g., Samsung Galaxy A12)
   ├─ Android version (e.g., Android 11)
   ├─ RAM (e.g., 4GB)
   └─ Internet connection (WiFi/4G/5G)

2. ISSUE DESCRIPTION
   ├─ What were you doing when the issue occurred?
   ├─ What did you expect to happen?
   ├─ What actually happened?
   └─ Can you reproduce it? (Always/Sometimes/Once)

3. SCREENSHOTS/VIDEO
   ├─ Screenshot of the problem (if visual)
   ├─ Screen recording (if behavior-related)
   └─ Error messages (copy exact text)

4. SPECIFIC AREAS TO TEST
   ├─ Card payment workflow
   ├─ Bank transfer workflow
   ├─ Order creation and tracking
   ├─ Navigation and UI responsiveness
   └─ Login/authentication flows

═════════════════════════════════════════════════════════════════════════════
STATES TESTING ASSIGNMENTS (5 Clients, 5 States)
═════════════════════════════════════════════════════════════════════════════

CLIENT 1 - [STATE 1]
├─ Focus: Card Payment Testing
├─ Test: Multiple card transactions
├─ Verify: Instant order confirmation
└─ Report: Payment success rate & timing

CLIENT 2 - [STATE 2]
├─ Focus: Bank Transfer Testing
├─ Test: Bank transfer account details display
├─ Verify: Manual verification process
└─ Report: Account info clarity & instructions

CLIENT 3 - [STATE 3]
├─ Focus: Cart & Checkout Flow
├─ Test: Adding/removing items
├─ Verify: Address selection & totals
└─ Report: Checkout speed & accuracy

CLIENT 4 - [STATE 4]
├─ Focus: User Authentication & Profile
├─ Test: Sign up, login, logout
├─ Verify: Profile data persistence
└─ Report: Auth reliability & performance

CLIENT 5 - [STATE 5]
├─ Focus: Overall UX & Performance
├─ Test: General app navigation
├─ Verify: Speed, responsiveness, crashes
└─ Report: General impressions & stability

═════════════════════════════════════════════════════════════════════════════
FEEDBACK FORM TEMPLATE
═════════════════════════════════════════════════════════════════════════════

Please complete this form after testing:

---CLIENT FEEDBACK---

Client Name: ________________
State: ________________
Testing Date: ________________
Device: ________________ (model & Android version)
Internet: ☐ WiFi  ☐ 4G  ☐ 5G

PAYMENT TESTING:
├─ Card Payment: ☐ Works  ☐ Issue: __________
├─ Bank Transfer: ☐ Works  ☐ Issue: __________
└─ Overall Payment: Rating 1-5: ___

WORKFLOW TESTING:
├─ Sign up/Login: ☐ Works  ☐ Issue: __________
├─ Browsing: ☐ Works  ☐ Issue: __________
├─ Cart: ☐ Works  ☐ Issue: __________
├─ Checkout: ☐ Works  ☐ Issue: __________
└─ Overall Workflow: Rating 1-5: ___

PERFORMANCE:
├─ Speed: ☐ Fast  ☐ Normal  ☐ Slow
├─ Crashes: ☐ None  ☐ Occasional  ☐ Frequent
├─ Responsiveness: ☐ Good  ☐ Fair  ☐ Poor
└─ Overall Performance: Rating 1-5: ___

GENERAL FEEDBACK:
├─ What did you like most?
│  ________________________________________
│
├─ What needs improvement?
│  ________________________________________
│
├─ Any bugs or errors?
│  ________________________________________
│
└─ Additional comments?
   ________________________________________

Would you use this app? ☐ Yes  ☐ Maybe  ☐ No

─────────────────────

═════════════════════════════════════════════════════════════════════════════
UNINSTALL INSTRUCTIONS
═════════════════════════════════════════════════════════════════════════════

To uninstall the app:

1. long-press the CoopCommerce app icon
2. Tap "Uninstall" or "Remove"
3. Confirm removal
4. (Optional) Go back to Settings > Unknown Sources and disable it

═════════════════════════════════════════════════════════════════════════════
SUPPORT CONTACT
═════════════════════════════════════════════════════════════════════════════

For technical issues or questions:

Email: [Your Support Email]
Phone: [Your Support Phone]
Hours: [Your Support Hours]

Include:
- Issue description
- Device model & Android version
- Screenshots/error messages
- Steps to reproduce

═════════════════════════════════════════════════════════════════════════════
IMPORTANT NOTES
═════════════════════════════════════════════════════════════════════════════

🚨 CRITICAL INFO:
   • This is a TEST build for evaluation purposes
   • Test payments are NOT charged
   • Card: 4242 4242 4242 4242 (always succeeds in test mode)
   • Bank transfers: Use account details shown in app
   • Feedback is CRUCIAL for development

⏰ TESTING WINDOW:
   • Please test within [TIMELINE]
   • Available for support during [HOURS]
   • Expected feedback by: [DATE]

🔒 PRIVACY:
   • Your test data will not be shared
   • All test accounts will be deleted after testing
   • Your feedback is confidential

═════════════════════════════════════════════════════════════════════════════
TROUBLESHOOTING QUICK TIPS
═════════════════════════════════════════════════════════════════════════════

Issue: "Installation blocked - Unknown Sources not enabled"
→ Solution: Follow Step 1 in Installation Instructions

Issue: "App crashes on startup"
→ Solution: 
  1. Restart device
  2. Clear app cache (Settings > Apps > CoopCommerce > Clear Cache)
  3. Reinstall app
  4. Report if persists

Issue: "Payment page doesn't load"
→ Solution:
  1. Check internet connection
  2. Try on WiFi instead of mobile data (or vice versa)
  3. Close and reopen app
  4. Report if persists

Issue: "Can't see order confirmation"
→ Solution:
  1. Go to "My Orders" section
  2. Check order status there
  3. Wait 1-2 minutes for webhook to fire
  4. Refresh the page

Issue: "Bank transfer account details missing"
→ Solution:
  1. This is required data from our system
  2. Email support if not showing
  3. Do NOT proceed without seeing account details

═════════════════════════════════════════════════════════════════════════════

Thank you for testing CoopCommerce!
Your feedback is essential for our success.

═════════════════════════════════════════════════════════════════════════════
