# PlayStore Launch Readiness CheckList
**Target Launch Date:** February 24-28, 2026 (7-10 days)  
**Status:** 85-90% Ready

---

## CRITICAL ITEMS (Complete by Feb 18)

### 1. Payment Gateway Setup
- [ ] **Flutterwave**
  - [ ] Create business account at https://dashboard.flutterwave.com
  - [ ] Complete KYC verification
  - [ ] Get Public Key (copy to config)
  - [ ] Get Secret Key (store securely in env/secrets)
  - [ ] Enable Test Mode for initial testing
  - [ ] Switch to Live Mode before launch
  
- [ ] **Paystack**
  - [ ] Create business account at https://dashboard.paystack.com
  - [ ] Complete verification
  - [ ] Get Public Key
  - [ ] Get Secret Key
  - [ ] Enable test transactions first

**Action:** Update these files with keys:
```
lib/config/payment_config.dart (create if not exists)
lib/core/services/payment_gateway_service.dart
```

### 2. App ID & Package Name Update
**Current:** `com.example.coop_commerce` ❌  
**New:** `com.cooperativenicorp.coopcommerce` (or approved name)

**Files to Update:**
- [ ] `android/app/build.gradle.kts` (line ~30)
  ```kotlin
  applicationId = "com.cooperativenicorp.coopcommerce"
  ```
- [ ] `android/app/src/main/AndroidManifest.xml` (verify package name)
- [ ] `pubspec.yaml` (update name)
- [ ] iOS: `ios/Runner.xcodeproj` (verify bundle ID)

**After changing:**
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 3. App Branding Assets
- [ ] **Launcher Icon** (512×512 PNG)
  - Save to: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
  - Also: xxxhdpi (640×640), xxhdpi (480×480), xhdpi (320×320), hdpi (240×240)
  
- [ ] **Adaptive Icon** (for Android 8+)
  - Background: `ic_launcher_background.xml`
  - Foreground: `mipmap-*/ic_launcher_foreground.png`
  
- [ ] **Splash Screen Image**
  - Replace in `assets/images/` (if using custom splash)
  
- [ ] **App Name Branding**
  - Update `android/app/src/main/AndroidManifest.xml` (android:label)

**Tool:** Use Flutter icon generator
```bash
flutter pub get
dart run flutter_launcher_icons:main
```

---

## CONFIGURATION (Complete by Feb 19)

### 4. Release Signing Setup
```bash
# Step 1: Generate keystore (do this ONCE, keep safe)
keytool -genkey -v -keystore ~/coop_commerce_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias coop_commerce

# Answer prompts:
# Password: [SECURE_PASSWORD]
# First/Last Name: Your Company
# OU: Mobile Apps
# Organization: Your Organization
# City: Lagos
# State: Lagos
# Country: NG

# Step 2: Update android/app/build.gradle.kts
```

**File:** `android/app/build.gradle.kts`
```kotlin
android {
    // ... other config ...
    
    signingConfigs {
        release {
            keyAlias = "coop_commerce"
            keyPassword = "YOUR_PASSWORD"
            storeFile = file("${System.getProperty("user.home")}/coop_commerce_key.jks")
            storePassword = "YOUR_PASSWORD"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled = true  // Enable ProGuard
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 5. Version Configuration
**File:** `pubspec.yaml`
```yaml
version: 1.0.0+1

# For next release:
# version: 1.0.1+2
# version: 1.1.0+3
```

**Pattern:** `[MAJOR].[MINOR].[PATCH]+[BUILD_NUMBER]`
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes
- BUILD: Incremental for each release

### 6. Firebase Production Project
- [ ] Create separate Firebase project for production
- [ ] Update `google-services.json` in `android/app/`
- [ ] Configure iOS GoogleService-Info.plist
- [ ] Enable:
  - [ ] Firestore Database (production mode rules)
  - [ ] Authentication (Google, Facebook, Email)
  - [ ] Cloud Storage (for product images)
  - [ ] Cloud Messaging (for notifications)
  - [ ] Crashlytics (for crash reporting)

---

## CONTENT CREATION (Complete by Feb 20)

### 7. PlayStore Listing Content

**A. App Title & Description**
```
Title: Coop Commerce - Shop Smart, Save More
(max 50 chars)

Short Description (80 chars):
Buy wholesale. Save together. Shop cooperative.

Full Description (4000 chars):
Coop Commerce connects cooperative members with exclusive
wholesale pricing, loyalty rewards, and bulk purchasing power.

✨ Key Features:
• Exclusive member discounts (up to 20% off)
• Loyalty points on every purchase
• Bulk ordering with wholesale pricing
• Real-time order tracking
• Fast, secure payment (Flutterwave/Paystack)
• Support for multiple user roles
• Push notifications for deals

🎯 Who Should Download:
- Individual shoppers looking for great deals
- Cooperative members wanting exclusive benefits
- Small businesses needing wholesale pricing
- Institutional buyers managing B2B orders

🔒 Privacy & Security:
Your data is encrypted and secure. Read our privacy policy
for details.

💬 Support:
Issues? Email us at support@coopcommerce.ng
```

**B. Screenshots** (need 4-8 per device type)
Take screenshots showing:
1. Home/products screen
2. Product detail with member benefits
3. Shopping cart
4. Checkout confirmation
5. Order tracking
6. Member loyalty card
7. Notifications
8. Account settings

**Required Sizes:**
- Phone: 1080×1920px
- Tablet: 1280×1920px

**C. Feature Graphic** (banner)
- 1024×500px
- Highlight main value proposition
- "Wholesale Pricing. Member Benefits. Delivered."

### 8. Legal Documents

**Privacy Policy**
Create: `assets/legal/privacy_policy.txt` or host online
Include:
- Data collection practices
- User data usage
- Third-party integrations
- GDPR/CCPA compliance (if applicable)
- Contact for privacy questions

**Terms of Service**
Create: `assets/legal/terms_of_service.txt` or host online
Include:
- User responsibilities
- Acceptable use policies
- Limitation of liability
- Payment gateway terms
- Dispute resolution

**Suggested:** Use Termly or iubenda for easy generation

---

## TESTING (Complete by Feb 21-22)

### 9. Functional Testing Checklist

**Authentication**
- [ ] Email/Password login
- [ ] Google sign-in
- [ ] Facebook sign-in
- [ ] Sign up as new user
- [ ] Password reset
- [ ] Role assignment/verification
- [ ] Logout

**Products**
- [ ] Browse products on home
- [ ] Search products
- [ ] Filter by category
- [ ] Filter by price range
- [ ] View product details
- [ ] Add to cart
- [ ] Product images load

**Shopping**
- [ ] Add multiple products to cart
- [ ] Update quantities
- [ ] Remove items
- [ ] Apply discount code (if enabled)
- [ ] View cart total

**Checkout**
- [ ] Add delivery address
- [ ] Select address
- [ ] Choose payment method
- [ ] Process payment (Flutterwave)
- [ ] Process payment (Paystack)
- [ ] Order confirmation
- [ ] Receive order number

**Orders**
- [ ] View order history
- [ ] Track order status
- [ ] Receive notifications
- [ ] Cancel order (if allowed)
- [ ] View invoice

**Member Features** (if logged in as member)
- [ ] View loyalty points
- [ ] See tier benefits
- [ ] Access member deals
- [ ] View member recommendations

**Admin** (if logged in as admin)
- [ ] Access user management
- [ ] View analytics
- [ ] Access audit logs
- [ ] Override prices (if enabled)

### 10. Device Testing

**Minimum:**
- [ ] API 21 (Android 5.0)
- [ ] API 28 (Android 9.0)
- [ ] API 33 (Android 13.0)
- [ ] API 34 (Android 14.0) - latest

**Physical Devices (at least 1 per range):**
- [ ] Budget phone (< ₦20,000)
- [ ] Mid-range phone (₦50,000-100,000)
- [ ] Flagship phone (> ₦150,000)

### 11. Performance Testing

```bash
# Check APK size
flutter build apk --release --analyze-size

# Target: < 100MB

# Profile memory usage
flutter run --profile

# Check startup time
# Should be < 3 seconds

# Load test
# Simulate 100+ products in list
# Check for jank (stuttering)
```

### 12. Network Condition Testing

- [ ] Test on WiFi
- [ ] Test on 4G LTE
- [ ] Test on 3G
- [ ] Test with network throttling
- [ ] Test offline functionality
- [ ] Test payment retry after connection loss

---

## BUILD & DEPLOY (Complete by Feb 23-24)

### 13. Build Release APK/AAB

```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Build APK (backwards compatible)
flutter build apk --release

# Build AAB (preferred for PlayStore)
flutter build appbundle --release

# Find output:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

**Verify Signatures:**
```bash
# Check APK signature
jarsigner -verify -verbose build/app/outputs/flutter-apk/app-release.apk

# Expected: sm - signature was verified
```

### 14. Manual Testing of Release Build

```bash
# Install on device
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Test all critical paths:
# - Launch app
# - Login
# - Browse products
# - Add to cart
# - Checkout
# - Payment
# - Order confirmation
```

### 15. Play Store Setup

**Create Google Play Developer Account:**
1. Go to: https://play.google.com/console
2. Sign in with Google account
3. Complete:
   - [ ] Name
   - [ ] Email
   - [ ] Phone
   - [ ] Store listing info
   - [ ] Payment setup ($25 registration fee)
   - [ ] Merchant account (for payments)

**Create App in Console:**
1. Click "Create app"
2. Fill in:
   - [ ] App name: "Coop Commerce"
   - [ ] Default language: English
   - [ ] App type: Applications
   - [ ] Category: Shopping
   - [ ] Content rating

**Complete Content Rating Questionnaire:**
- [ ] Go to "Content rating"
- [ ] Fill Google Play questionnaire (5-10 min)
- [ ] Get rating certificate

### 16. Upload Build

1. Click "Releases" → "Create new release"
2. Upload AAB:
   - [ ] Select `app-release.aab`
3. Fill release notes:
   ```
   Version 1.0.0 - Initial Release
   
   ✨ Launch Features:
   • Multi-role e-commerce platform
   • Member loyalty & benefits
   • Real-time order tracking
   • Push notifications
   • Secure payments
   • Admin dashboard
   
   🔒 Security:
   • Firebase authentication
   • Encrypted transactions
   • Secure data storage
   ```
4. Review for violations
5. Submit for review

### 17. Pre-Launch Checklist

- [ ] Verify APK/AAB builds without errors
- [ ] Test signed APK on device
- [ ] Play Store listing completed
- [ ] Privacy policy linked
- [ ] Screenshots uploaded (4-8 per device)
- [ ] Feature graphic uploaded
- [ ] Content rating approved
- [ ] Payment setup configured
- [ ] Release notes written
- [ ] Version code incremented
- [ ] No hardcoded debug values
- [ ] No sensitive credentials in code

---

## POST-LAUNCH (Feb 25+)

### 18. Launch Day Monitoring

- [ ] Monitor crash logs (Firebase Crashlytics)
- [ ] Check user feedback in Play Store
- [ ] Monitor payment transaction logs
- [ ] Track installation/uninstall rates
- [ ] Monitor API response times
- [ ] Set up alerts for critical errors

### 19. First Week Follow-up

- [ ] Address any critical bugs (emergency patch)
- [ ] Monitor analytics for funnel drop-offs
- [ ] Respond to user reviews
- [ ] Fix top crashers within 48 hours
- [ ] Plan v1.0.1 for non-critical fixes

### 20. Ongoing Maintenance

**Weekly:**
- [ ] Review crash reports
- [ ] Check user reviews
- [ ] Monitor performance metrics

**Monthly:**
- [ ] Release minor updates (1.0.1, 1.0.2, etc.)
- [ ] Add community-requested features
- [ ] Security patches as needed

**Quarterly:**
- [ ] Plan major feature release (v1.1)
- [ ] User feedback synthesis
- [ ] Competitive analysis

---

## TIMELINE SUMMARY

```
Feb 18: Credentials, App ID, Branding
Feb 19: Signing, Firebase Config
Feb 20: Play Store Content
Feb 21-22: Testing (Functional + Devices + Performance)
Feb 23-24: Build Release APK/AAB + Manual Testing
Feb 24: Submit to Play Store
Feb 25-28: Review process + Launch
```

**Success Criteria:**
- ✅ App launches without crashing
- ✅ All roles function correctly
- ✅ Payment flows work end-to-end
- ✅ Order tracking works
- ✅ Notifications deliver
- ✅ Memory < 200MB during normal use
- ✅ APK size < 100MB
- ✅ Crash rate < 0.1%

---

## CONTACT & RESOURCES

**Flutter Documentation:** https://flutter.dev/docs  
**Play Store Submission:** https://play.google.com/console  
**Flutterwave Docs:** https://developer.flutterwave.com  
**Paystack Docs:** https://paystack.com/docs  
**Firebase Setup:** https://firebase.google.com/docs/flutter/setup  

**Key Contacts:**
- Firebase Support: support@firebase.google.com
- Flutterwave Support: support@flutterwave.com
- Paystack Support: support@paystack.co
- Google Play Support: https://support.google.com/googleplay

---

**Prepared:** February 17, 2026  
**Status:** Ready for Execution  
**Estimated Completion:** February 28, 2026  
