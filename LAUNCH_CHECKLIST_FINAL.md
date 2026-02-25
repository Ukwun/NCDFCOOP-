# 🚀 COOP COMMERCE - FINAL LAUNCH CHECKLIST
**Date:** February 18, 2026 | **Target Launch:** February 25-28, 2026 | **Status:** 🟡 Ready for Testing

---

## 📋 PHASE 1: PRE-LAUNCH SETUP (Days 1-2) - CRITICAL PATH

### Day 1 Morning: Payment Gateway Credentials
- [ ] **Flutterwave Setup** (1 hour)
  - [ ] Create merchant account at flutterwave.com
  - [ ] Verify email and complete KYC
  - [ ] Get public and secret keys
  - [ ] Note down Merchant ID
  - [ ] Setup webhook: `https://yourdomain.com/api/flutterwave-webhook`
  - [ ] Test with test card: 4532 0151 4532 3010

- [ ] **Paystack Setup** (1 hour)
  - [ ] Create merchant account at paystack.com
  - [ ] Complete registration and verification
  - [ ] Get public and secret keys
  - [ ] Setup webhook: `https://yourdomain.com/api/paystack-webhook`
  - [ ] Test with test card: 4084 0343 5753 3310

- [ ] **Update Code** (30 min)
  - [ ] Add keys to `lib/core/payments/payment_gateway_service.dart`
  - [ ] Or store in Firebase Remote Config
  - [ ] Test payment flow doesn't crash

### Day 1 Afternoon: Bundle ID & Code Signing
- [ ] **Change Bundle ID** (30 min)
  - [ ] Update `android/app/build.gradle.kts`
    - namespace = "com.coopcommerce.app"
    - applicationId = "com.coopcommerce.app"
  - [ ] Update `ios/Runner.xcodeproj` bundle ID
  - [ ] Verify in `pubspec.yaml` name matches

- [ ] **Generate Release Keystore** (45 min)
  - [ ] Create keystore: `keytool -genkey -v -keystore ~/coop_release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias coop_key`
  - [ ] Store password securely in password manager
  - [ ] Backup keystore to encrypted location
  - [ ] Document location and password for team

- [ ] **Configure Code Signing** (30 min)
  - [ ] Update `android/app/build.gradle.kts` with signing config
  - [ ] Test release build: `flutter build apk --release`
  - [ ] Verify APK signed: `jarsigner -verify build/app/outputs/flutter-apk/app-release.apk`

### Day 1: Firebase Production Setup
- [ ] **Create Production Firebase Project** (1 hour)
  - [ ] Go to firebase.google.com/console
  - [ ] Create new project: "coop_commerce_prod"
  - [ ] Enable Firestore Database
  - [ ] Enable Cloud Storage
  - [ ] Enable Authentication
  - [ ] Enable Cloud Messaging
  - [ ] Enable Crashlytics

- [ ] **Download Config Files** (15 min)
  - [ ] Download `google-services.json` (Android)
  - [ ] Copy to `android/app/google-services.json`
  - [ ] Download `GoogleService-Info.plist` (iOS)
  - [ ] Copy to `ios/Runner/GoogleService-Info.plist`

- [ ] **Configure Auth Providers** (1 hour)
  - [ ] **Google OAuth:**
    - [ ] Get OAuth 2.0 Client ID from Google Cloud Console
    - [ ] Add to Firebase Authentication
    - [ ] Test Google login on device
  - [ ] **Facebook OAuth:**
    - [ ] Create Facebook App
    - [ ] Get App ID and Secret
    - [ ] Add to Firebase Authentication
    - [ ] Test Facebook login
  - [ ] **Apple Sign-In:**
    - [ ] Register Apple ID capability in Xcode
    - [ ] Add to Firebase Authentication
    - [ ] Test on device (iOS)

### Day 2 Morning: Branding Assets
- [ ] **Create App Icons** (1.5 hours)
  - [ ] Design launcher icon (512×512 PNG)
    - [ ] CoopCommerce logo or stylized "CC"
    - [ ] Green background (#1A472A)
    - [ ] Transparent padding
  - [ ] Create adaptive icons (Android 8+)
    - [ ] Background layer (512×512)
    - [ ] Foreground layer (512×512)
  - [ ] Copy to correct locations:
    - [ ] `android/app/src/main/res/mipmap-*/ic_launcher.png`
    - [ ] `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

- [ ] **Create Custom Splash Screen** (1 hour)
  - [ ] Design splash in Figma or Adobe
  - [ ] Export as PNG (1080×1920)
  - [ ] Add CoopCommerce logo
  - [ ] Add "CoopCommerce" text
  - [ ] Add tagline: "Quality Products, Fair Prices"
  - [ ] Update `splash_screen.dart` to display custom image

- [ ] **Verify Design Quality** (30 min)
  - [ ] Test icon on device (Settings → Apps)
  - [ ] Test splash screen appears on cold start
  - [ ] Verify colors match brand guidelines

### Day 2 Afternoon: PlayStore Content
- [ ] **Write App Description** (45 min)
  - [ ] Short description (80 chars): "Shop quality products with loyalty rewards, real-time tracking, and same-day delivery"
  - [ ] Full description (4000 chars max):
    - Features for each role
    - Key benefits
    - Security/privacy mentions
    - Call to action

- [ ] **Create Screenshots** (1.5 hours)
  - [ ] 6-8 screenshots per device type (phone, tablet)
  - [ ] Annotate with text overlays
    - Shot 1: Login screen
    - Shot 2: Product browsing
    - Shot 3: Member benefits
    - Shot 4: Shopping cart
    - Shot 5: Checkout
    - Shot 6: Order tracking
    - Shot 7: Real-time notifications
    - Shot 8: Real-time delivery map
  - [ ] Use design tool (Figma, Canva, or Adobe)
  - [ ] Upload to Play Store console

- [ ] **Create Privacy Policy & Terms** (1 hour)
  - [ ] Use template from Termly or iubenda
  - [ ] Customize for CoopCommerce
  - [ ] Address data collection and privacy
  - [ ] Include refund policy
  - [ ] Deploy to website or in-app
  - [ ] Add URLs to app settings screen

---

## 🧪 PHASE 2: COMPREHENSIVE TESTING (Days 3-5)

### Day 3: Core Functionality Testing
- [ ] **Consumer Flow - Emulator** (2 hours)
  - [ ] Launch app (Splash → Welcome → Login)
  - [ ] Login with email/password
  - [ ] Browse products
  - [ ] Search for "electronics"
  - [ ] Filter by price: ₦50,000 - ₦100,000
  - [ ] Tap product → see detail
  - [ ] Add to cart
  - [ ] Go to checkout
  - [ ] Proceed through all 5 steps
  - [ ] Complete payment (test card)
  - [ ] See order confirmation
  - [ ] Track order (see real-time status)

- [ ] **Social Login - Emulator** (1 hour)
  - [ ] Test Google Sign-In
  - [ ] Test Facebook Login
  - [ ] Test Remember Me on login screen
  - [ ] Close and reopen app (should auto-login)

- [ ] **Real Device Testing** (2 hours)
  - [ ] Install signed APK: `adb install build/app/outputs/flutter-apk/app-release.apk`
  - [ ] Run through consumer flow above
  - [ ] Check UI responsiveness on real screen
  - [ ] Test back button navigation
  - [ ] Test notification permission popup

### Day 4: Edge Cases & Network
- [ ] **Network Condition Testing** (2 hours)
  - [ ] Emulator EDGE simulation:
    - [ ] Test product loading (EDGE)
    - [ ] Test payment on slow network (retry mechanism)
    - [ ] Verify error messages appear
  - [ ] Offline Mode: Put device in airplane mode
    - [ ] Verify app shows cached/mock data
    - [ ] Show offline indicator
  - [ ] Connection Interruption:
    - [ ] Start payment → interrupt → restart
    - [ ] Verify payment state is correct

- [ ] **Role-Specific Features** (2 hours)
  - [ ] **Member Login:** Check loyalty points, tier, exclusive deals
  - [ ] **Franchise Login:** Check store dashboard, analytics
  - [ ] **Institutional Login:** Check PO creation, approval
  - [ ] **Admin Login:** Check user management, price overrides
  - [ ] **Driver Login:** Check deliveries, routing, POD

- [ ] **Performance Testing** (1 hour)
  - [ ] Android Studio Profiler:
    - [ ] Memory usage at startup (should be < 150MB)
    - [ ] Memory when browsing products (should stay < 150MB)
    - [ ] No memory leaks on navigation
  - [ ] APK size check: `flutter build appbundle --release --analyze-size`
    - [ ] Target: < 100MB

### Day 5: Security & Stability
- [ ] **Security Testing** (2 hours)
  - [ ] RBAC enforcement:
    - [ ] Consumer cannot access franchise features
    - [ ] Franchise owner cannot access admin panel
    - [ ] Test role-based deep links
  - [ ] Auth token expiration:
    - [ ] Wait for token to expire
    - [ ] Try to make API call
    - [ ] Verify redirect to login
  - [ ] Payment security:
    - [ ] Verify HTTPS on all payment calls
    - [ ] Verify card data not logged
    - [ ] Verify no sensitive data in app logs

- [ ] **Crash Testing** (2 hours)
  - [ ] Back navigation on all screens
  - [ ] Rapid screen changes
  - [ ] Test error scenarios (network error, payment failure)
  - [ ] Verify Crashlytics receives errors
  - [ ] Check error dashboard

- [ ] **Final Stability** (1 hour)
  - [ ] Run `flutter analyze` - should be 0 errors
  - [ ] Run `dart format --set-exit-if-changed lib/`
  - [ ] Test on 2+ different Android versions
  - [ ] Use app for 30+ minutes, navigate thoroughly
  - [ ] No crashes or freezes

---

## 🔨 PHASE 3: BUILD & SIGN (Days 6-7)

### Day 6: Create Release Build
- [ ] **Clean & Prepare** (30 min)
  - [ ] `flutter clean`
  - [ ] `flutter pub get`
  - [ ] Verify no errors: `flutter analyze`

- [ ] **Create Release APK** (30 min)
  - [ ] `flutter build apk --release`
  - [ ] Output: `build/app/outputs/flutter-apk/app-release.apk`
  - [ ] Verify signature: `jarsigner -verify -certs build/app/outputs/flutter-apk/app-release.apk`
  - [ ] Expected output: "verified, signed"

- [ ] **Create Release AAB (Preferred)** (30 min)
  - [ ] `flutter build appbundle --release`
  - [ ] Output: `build/app/outputs/bundle/release/app-release.aab`
  - [ ] Check size: `flutter build appbundle --release --analyze-size`
  - [ ] Should be < 100MB

- [ ] **Test on Real Device** (1 hour)
  - [ ] `adb install build/app/outputs/flutter-apk/app-release.apk`
  - [ ] Run through key flows:
    - [ ] Login
    - [ ] Browse products
    - [ ] Checkout
    - [ ] Payment
    - [ ] Order tracking
  - [ ] Verify performance (should be faster than debug build)
  - [ ] Check Firebase connection works

### Day 7: Final Verification
- [ ] **Security & Code Quality** (1.5 hours)
  - [ ] Run `flutter analyze` - 0 errors/warnings
  - [ ] Verify no hardcoded secrets in code
  - [ ] Check payment keys are in Firebase Remote Config
  - [ ] Verify all credentials stored securely

- [ ] **Version Management** (30 min)
  - [ ] Version in `pubspec.yaml`: 1.0.0+1
  - [ ] Update version code for next build: 1.0.0+2 (or 1.0.1+1)
  - [ ] Document version numbering scheme

- [ ] **Documentation** (30 min)
  - [ ] Document build instructions
  - [ ] Document deployment process
  - [ ] Document rollback procedure if issues
  - [ ] Keep master keystore backup file

- [ ] **Stakeholder Review** (1 hour)
  - [ ] Demo to stakeholders (10-15 min)
    - [ ] Login flows
    - [ ] Product browsing
    - [ ] Real-time order tracking
    - [ ] Role-specific features
  - [ ] Get final approval to proceed

---

## 📤 PHASE 4: PLAYSTORE SUBMISSION (Days 8-9)

### Day 8 Morning: Setup Play Store
- [ ] **Create Developer Account (if needed)** (30 min)
  - [ ] Go to play.google.com/console
  - [ ] Pay $25 registration fee
  - [ ] Complete merchant tax form
  - [ ] Setup payment method

- [ ] **Create App Listing** (1 hour)
  - [ ] Click "Create App"
  - [ ] Fill in:
    - [ ] App name: "Coop Commerce"
    - [ ] Category: Shopping
    - [ ] Content rating: Complete questionnaire
    - [ ] Privacy policy URL: https://yoursite.com/privacy
    - [ ] Contact email: support@coopcommerce.com

- [ ] **Upload Branding** (1 hour)
  - [ ] Upload icon (512×512)
  - [ ] Upload 6-8 screenshots per device type
  - [ ] Upload feature graphic (1024×500)
  - [ ] Write description (from Day 2 prep)
  - [ ] Write tagline
  - [ ] Review and verify all images display correctly

### Day 8 Afternoon: Complete Metadata
- [ ] **PlayStore Metadata** (1.5 hours)
  - [ ] App name: "Coop Commerce"
  - [ ] Short description: "Shop quality products with loyalty rewards"
  - [ ] Full description: (prepared on Day 2)
  - [ ] Category: Shopping
  - [ ] Content rating: Appropriate (complete questionnaire)
  - [ ] Privacy policy: https://yoursite.com/privacy
  - [ ] Terms of service: https://yoursite.com/terms
  - [ ] Website: https://yoursite.com
  - [ ] Support email: support@coopcommerce.com

- [ ] **Pricing & Distribution** (30 min)
  - [ ] Set to Free
  - [ ] Select countries (at minimum: Nigeria)
  - [ ] Content rating: Unrated or appropriate category
  - [ ] Accept Play Store policies

- [ ] **Permissions Review** (30 min)
  - [ ] Location (for driver)
  - [ ] Camera (for POD/profile)
  - [ ] Contacts (optional)
  - [ ] Photos (for uploads)
  - [ ] Ensure all permissions explained to users

### Day 9 Morning: Upload & Submit
- [ ] **Final Content Review** (1 hour)
  - [ ] Review privacy policy one more time
  - [ ] Verify all links work
  - [ ] Verify all screenshots display correctly
  - [ ] Check spelling and grammar
  - [ ] Confirm release notes: "Initial launch with full shopping, member benefits, real-time order tracking, and same-day delivery features"

- [ ] **Upload Release AAB** (30 min)
  - [ ] Go to App Releases → Create new release
  - [ ] Select "Production" track
  - [ ] Upload AAB file: `build/app/outputs/bundle/release/app-release.aab`
  - [ ] Verify file size: should be ~50-80MB
  - [ ] Add release notes

- [ ] **Final Checklist** (1 hour)
  - [ ] Version code: 1 (for first release)
  - [ ] All metadata filled
  - [ ] Screenshots uploaded
  - [ ] Icon uploaded
  - [ ] Privacy policy linked
  - [ ] No violated policies
  - [ ] Content rating completed
  - [ ] All fields green (no warnings)

### Day 9 Afternoon: SUBMIT! 🚀
- [ ] **SUBMIT FOR REVIEW** (5 min)
  - [ ] Final review of all information
  - [ ] Click "Review and roll out to production"
  - [ ] Expected review time: **2-4 hours**
  - [ ] May require 1-2 rounds of revisions
  - [ ] Once approved, app goes live immediately

- [ ] **Post-Submission Monitoring** (ongoing)
  - [ ] Monitor email for Google Play feedback
  - [ ] Watch Crashlytics dashboard
  - [ ] Monitor app store reviews
  - [ ] Be ready for immediate response if critical issues
  - [ ] Have rollback plan ready

---

## 📊 PHASE 5: POST-LAUNCH (Ongoing)

### Hour 1-24 After Launch
- [ ] Monitor Crashlytics for errors
- [ ] Monitor Firebase Analytics
- [ ] Answer Play Store reviews
- [ ] Monitor payment processing
- [ ] Monitor user signup completion rate
- [ ] Check notification delivery
- [ ] Have support team on standby

### Days 1-7 Post-Launch
- [ ] Daily review of crash logs
- [ ] Monitor user feedback and reviews
- [ ] Track conversion funnel (signup → purchase)
- [ ] Monitor payment success rate (target: > 95%)
- [ ] Plan v1.0.1 patch if critical bugs found
- [ ] Start v1.1 feature development

### Weeks 1-4 Post-Launch
- [ ] Analyze retention metrics
- [ ] Identify drop-off points in user journey
- [ ] Gather feature requests from reviews
- [ ] Monitor server performance and optimize
- [ ] Plan marketing push based on initial traction

---

## ✅ FINAL VERIFICATION CHECKLIST

### Code & Build
- [ ] `flutter analyze` = 0 errors
- [ ] `flutter build apk --release` succeeds
- [ ] `flutter build appbundle --release` succeeds
- [ ] Release APK/AAB is signed correctly
- [ ] No hardcoded secrets in code

### Features
- [ ] All 11 roles have home screens
- [ ] 40+ screens implemented
- [ ] Real-time features working (orders, notifications, maps)
- [ ] Payment flow works (with test keys)
- [ ] All authentication methods functional

### Deployment
- [ ] Official bundle ID configured
- [ ] Release keystore generated and backed up
- [ ] Firebase production project setup
- [ ] Google/Facebook/Apple OAuth configured
- [ ] Flutterwave and Paystack credentials ready

### PlayStore Requirements
- [ ] App icon created and tested
- [ ] Screenshots prepared (6-8 each)
- [ ] Privacy policy available
- [ ] Terms of service available
- [ ] Description and metadata complete
- [ ] Permission requirements justified

### Testing
- [ ] Emulator testing (API 21, 26, 29, 33, 34)
- [ ] Real device testing (at least 2 devices)
- [ ] All auth methods tested
- [ ] Product browsing tested
- [ ] Checkout flow tested
- [ ] Payment tested (test cards)
- [ ] Order tracking tested
- [ ] Real-time notifications tested
- [ ] Network condition testing done

---

## 🎯 SUCCESS CRITERIA

Your launch is successful when:
1. ✅ App appears on Google Play Store
2. ✅ Users can signup and login
3. ✅ Users can browse products and add to cart
4. ✅ Users can complete checkout without errors
5. ✅ Payments process and users receive confirmation
6. ✅ Orders appear in real-time tracking
7. ✅ Notifications arrive when order status changes
8. ✅ App crash rate < 0.1%
9. ✅ Payment success rate > 95%
10. ✅ Signup completion rate > 50%

---

## 📞 ESCALATION CONTACTS

| Issue | Contact | Time |
|-------|---------|------|
| Build Issues | DevOps Lead | ASAP |
| Firebase Issues | Firebase Specialist | ASAP |
| Play Store Submission | Google Play Support | During review |
| Payment Gateway Down | Flutterwave/Paystack | Business hours |
| Critical Bugs Post-Launch | Dev Team | On-call 24/7 |

---

## 📅 TIMELINE

```
📆 Feb 18 (Today): Comprehensive analysis & roadmap
📆 Feb 19-20: Pre-launch setup + branding
📆 Feb 21-23: Comprehensive testing
📆 Feb 24: Build & sign release
📆 Feb 25: Play Store submission
📆 Feb 25-26: Review (2-4 hours typically)
📆 Feb 26: ✅ LAUNCH!
```

**Total Duration:** 7 days from today to live app

---

**Status:** 🟢 Ready to execute  
**Blockers:** Finance team needs to get payment gateway credentials TODAY  
**Next Action:** Start Day 1 pre-launch setup immediately
