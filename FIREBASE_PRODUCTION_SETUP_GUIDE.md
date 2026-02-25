# Firebase Production Setup Guide - Coop Commerce

**Date:** February 18, 2026  
**Target:** Production Firebase Configuration for Phase 2 Testing  
**Timeline:** 2-3 hours setup + testing  
**Status:** Ready for Implementation

---

## OVERVIEW

This guide walks you through setting up a production Firebase project for Coop Commerce, separate from your development environment. This is essential before Phase 2 testing on real devices.

### What You'll Do:
1. Create a new production Firebase project
2. Enable required services (Firestore, Auth, Messaging, Storage)
3. Configure Firestore security rules
4. Set up Google & Facebook authentication
5. Get Firebase config file
6. Update Flutter app configuration
7. Test connection

### Time Required: 
- Firebase setup: 45 minutes
- Security rules: 30 minutes
- Auth providers: 30 minutes
- App integration: 15 minutes
- Testing: 15 minutes
- **Total: ~2.5 hours**

---

## STEP 1: CREATE FIREBASE PROJECT

### 1.1 Go to Firebase Console
```
URL: https://console.firebase.google.com/
Action: Sign in with your Google account (use your NCDF/Coop account)
```

### 1.2 Create New Project
```
Click: "Add project" or "Create a project"
Project Name: "Coop Commerce Production" (or "CoopCommerce-Prod")
Project ID: Auto-generated (e.g., "coopcommerce-prod-abc123")
Analytics: Enable Google Analytics (recommended for tracking user behavior)
  - Select or create Google Analytics account
  - Accept terms
```

### 1.3 Wait for Project Creation
- Takes 2-3 minutes
- You'll see: "Your new project is ready"
- Click: "Continue" to proceed

### 1.4 Configure Project Settings
```
Left sidebar → Project Settings (gear icon)
  ├── General tab (current)
  ├── Service accounts
  ├── Cloud Messaging
  └── Integrations
```

---

## STEP 2: ENABLE FIREBASE SERVICES

### 2.1 Firestore Database
```
Left sidebar → Build section → Firestore Database
Click: "Create database"

Configuration:
  ├── Location: Choose closest to Nigeria
  │   Recommended: "europe-west1" (Belgium/Europe - lowest latency from Nigeria)
  │   Alternative: "us-central1" (cheaper, slightly higher latency)
  │
  ├── Security rules: Start in "Test mode" (for now)
  │   ⚠️ You'll secure this in Step 3
  │
  └── Click: "Create"

Wait: 2-3 minutes for Firestore to initialize
Result: Empty Firestore database ready
```

### 2.2 Firebase Authentication
```
Left sidebar → Build section → Authentication
Click: "Get started"

This opens: Authentication Dashboard
Default state: No providers enabled yet
Status: Email/Password is available but not enabled
```

### 2.3 Cloud Messaging (FCM)
```
Left sidebar → Build section → Cloud Messaging
Status: Automatically enabled with Firebase project
Config: Will see your "Server API Key" and "Sender ID"

Don't worry about this yet - it's auto-configured
```

### 2.4 Cloud Storage
```
Left sidebar → Build section → Storage
Click: "Get started" (if not already enabled)

Configuration:
  ├── Location: Choose same as Firestore (europe-west1)
  └── Click: "Done"

Wait: ~1 minute
Result: Storage bucket created (for product images, user uploads, etc.)
```

---

## STEP 3: CONFIGURE FIRESTORE SECURITY RULES

### 3.1 Access Security Rules Editor
```
Firestore Database → "Rules" tab (top of database view)
Current rules: Default test mode (allows all read/write)

⚠️ CRITICAL: These rules are permissive for testing
You'll update them after testing
```

### 3.2 Copy Production Security Rules

Replace all content in the Rules editor with:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // =================================================================
    // USERS COLLECTION
    // =================================================================
    match /users/{userId} {
      // Users can only read/write their own profile
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false; // Prevent accidental deletion
      
      // Member subcollection
      match /member/{memberDoc=**} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId;
      }
      
      // Preferences subcollection
      match /preferences/{prefDoc=**} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId;
      }
    }
    
    // =================================================================
    // PRODUCTS COLLECTION (Public Read, Admin Write)
    // =================================================================
    match /products/{productId} {
      // Everyone can read products
      allow read: if true;
      
      // Only admins can write products
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if isAdmin();
      
      // Reviews subcollection
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update: if request.auth.uid == resource.data.userId;
        allow delete: if request.auth.uid == resource.data.userId || isAdmin();
      }
    }
    
    // =================================================================
    // ORDERS COLLECTION
    // =================================================================
    match /orders/{orderId} {
      // Users can only read/write their own orders
      allow read: if request.auth.uid == resource.data.userId || isAdmin();
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth.uid == resource.data.userId || isAdmin();
      allow delete: if false; // Prevent deletion of order history
      
      // Order items subcollection
      match /items/{itemId=**} {
        allow read: if request.auth.uid == get(/databases/$(database)/documents/orders/$(orderId)).data.userId || isAdmin();
        allow write: if request.auth.uid == get(/databases/$(database)/documents/orders/$(orderId)).data.userId || isAdmin();
      }
    }
    
    // =================================================================
    // CART COLLECTION (Temporary, Auto-Delete after 24h)
    // =================================================================
    match /carts/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
      
      // Cart items subcollection
      match /items/{itemId=**} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId;
      }
    }
    
    // =================================================================
    // NOTIFICATIONS COLLECTION
    // =================================================================
    match /notifications/{notifId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if isAdmin() || request.auth != null;
      allow update: if request.auth.uid == resource.data.userId || isAdmin();
      allow delete: if request.auth.uid == resource.data.userId || isAdmin();
    }
    
    // =================================================================
    // MEMBER BENEFITS COLLECTION (Public Read for Discovery)
    // =================================================================
    match /memberBenefits/{benefitId} {
      // Everyone reads benefits
      allow read: if true;
      // Only admins manage benefits
      allow write: if isAdmin();
    }
    
    // =================================================================
    // FRANCHISE COLLECTION
    // =================================================================
    match /franchises/{franchiseId} {
      // Franchise owner reads their franchise
      allow read: if hasRole('franchise_owner') && userCanAccessFranchise(franchiseId);
      // Only franchise owner + admin can edit
      allow update: if (hasRole('franchise_owner') && userCanAccessFranchise(franchiseId)) || isAdmin();
      // Only admin can create/delete
      allow create: if isAdmin();
      allow delete: if isAdmin();
      
      // Inventory subcollection
      match /inventory/{invItem=**} {
        allow read: if hasRole('franchise_owner') && userCanAccessFranchise(franchiseId);
        allow write: if hasRole('franchise_owner') && userCanAccessFranchise(franchiseId);
      }
      
      // Staff subcollection
      match /staff/{staffId=**} {
        allow read: if hasRole('franchise_owner') && userCanAccessFranchise(franchiseId);
        allow write: if hasRole('franchise_owner') && userCanAccessFranchise(franchiseId);
      }
    }
    
    // =================================================================
    // INSTITUTIONAL BUYERS COLLECTION
    // =================================================================
    match /institutionalBuyers/{buyerId} {
      allow read: if request.auth.uid == buyerId || isAdmin();
      allow update: if request.auth.uid == buyerId || isAdmin();
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow delete: if false;
      
      // Purchase orders subcollection
      match /purchaseOrders/{poId=**} {
        allow read: if request.auth.uid == buyerId || isAdmin();
        allow create: if request.auth.uid == buyerId;
        allow update: if request.auth.uid == buyerId && resource.data.status == 'draft' || isAdmin();
      }
    }
    
    // =================================================================
    // DELIVERY DRIVERS COLLECTION
    // =================================================================
    match /drivers/{driverId} {
      allow read: if request.auth.uid == driverId || isAdmin();
      allow update: if request.auth.uid == driverId || isAdmin();
      allow delete: if false;
      
      // Active deliveries
      match /deliveries/{deliveryId=**} {
        allow read: if request.auth.uid == driverId || isAdmin();
        allow update: if request.auth.uid == driverId;
      }
    }
    
    // =================================================================
    // ADMIN LOGS COLLECTION (Admin Only)
    // =================================================================
    match /auditLogs/{logId=**} {
      allow read: if isAdmin();
      allow create: if isAdmin() || request.auth != null;
      allow write: if isAdmin();
    }
    
    // =================================================================
    // HELPER FUNCTIONS
    // =================================================================
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
             || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    function hasRole(role) {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }
    
    function userCanAccessFranchise(franchiseId) {
      let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return userDoc.franchiseIds != null && franchiseId in userDoc.franchiseIds;
    }
  }
}
```

### 3.3 Publish Rules
```
Click: "Publish" button (top right of Rules editor)
Confirmation: "Security rules have been updated"
Wait: ~30 seconds for rules to deploy
Status: Changes are now live
```

### 3.4 Test Rules
```
In Firestore console:
  1. Click: "Start collection"
  2. Create test collection "test_data"
  3. Try to add document
  4. You should get: "Missing or insufficient permissions"
  5. This is CORRECT - rules are working

Why? Because you're not authenticated as a user
In the app, users are logged in, so they'll have proper access
```

---

## STEP 4: SETUP AUTHENTICATION PROVIDERS

### 4.1 Enable Email/Password
```
Authentication → Sign-in method tab
Click: "Email/Password"
  ├── Enable: Toggle ON
  ├── Email enumeration protection: Enable (prevents account enumeration attacks)
  └── Click: "Save"
```

### 4.2 Set Up Google Sign-In

#### A. Create OAuth Consent Screen
```
Google Cloud Console: https://console.cloud.google.com/
  1. Select your Firebase project
  2. Left sidebar → APIs & Services → OAuth consent screen
  3. User type: Select "External"
  4. Click: "Create"

Consent Screen Details:
  ├── App name: "Coop Commerce"
  ├── User support email: support@coopcommerce.ng
  ├── App logo: Upload Coop Commerce logo (optional, can skip)
  ├── Add scopes: 
  │   ├── email (already included)
  │   ├── profile (already included)
  │   └── openid (already included)
  ├── Developer contact: your-email@ncdf.ng
  └── Click: "Save and Continue"

Scopes: Click "Add or Remove Scopes"
  ├── Select: openid, email, profile
  └── Click: "Update"

Summary: Review all info
  └── Click: "Back to Dashboard"
```

#### B. Create OAuth Credentials
```
APIs & Services → Credentials
  1. Click: "Create Credentials"
  2. Type: "OAuth 2.0 Client ID"
  3. Application type: "Web application"
  
Name: "Coop Commerce Web"

Authorized redirect URIs: Add these:
  ├── https://coopcommerce-prod-abc123.firebaseapp.com/__/auth/handler
  ├── https://coopcommerce-prod-abc123.firebaseapp.com/
  └── http://localhost:7124/
  
  (Replace abc123 with your actual Firebase project ID)

Click: "Create"

Result: Copy your OAuth Client ID (you'll need it)
```

#### C. Enable in Firebase
```
Firebase Console → Authentication → Sign-in method
  Click: "Google"
    ├── Enable: Toggle ON
    ├── Project support email: support@coopcommerce.ng
    ├── Click: "Save"
    
Result: Google Sign-In now enabled
```

### 4.3 Set Up Facebook Sign-In

#### A. Create Facebook Developer Account
```
URL: https://developers.facebook.com/
  1. Sign in or create account
  2. Create App: My Apps → Create App
  3. App type: Consumer
  4. App name: "Coop Commerce"
  5. App purpose: Choose appropriate category
  6. Click: "Create App"
```

#### B. Get Facebook App Credentials
```
Facebook App Dashboard:
  1. Settings → Basic
  2. Copy:
     ├── App ID: (e.g., 123456789)
     └── App Secret: (keep this SECRET, don't share)
  
  3. Add Platform: iOS
     ├── Bundle ID: com.cooperativenicorp.coopcommerce
     └── Save
     
  4. Add Platform: Android
     ├── Package name: com.cooperativenicorp.coopcommerce
     ├── Class name: com.cooperativenicorp.coopcommerce.MainActivity
     └── Get Key Hash (see section below)
```

#### C. Get Android Key Hash
```
Run in terminal (Windows PowerShell):

# First, find your Android SDK keystore location
$keystorePath = "$env:USERPROFILE\.android\debug.keystore"

# Get the key hash

keytool -exportcert -alias androiddebugkey -keystore $keystorePath -storepass android -keypass android | ^
certutil -encode -f - debug.txt

# Or on Mac/Linux:
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | \
openssl sha1 -binary | openssl base64

Result: You'll get a hash like: "rEKwtMHHYeNxSoFUyS4XEK4="

Add to Facebook App:
  Android → Key Hashes
  Paste your hash
  Save
```

#### D. Enable in Firebase
```
Firebase Console → Authentication → Sign-in method
  Click: "Facebook"
    ├── Enable: Toggle ON
    ├── App ID: Paste Facebook App ID
    ├── App Secret: Paste Facebook App Secret
    ├── Click: "Save"
    
Result: Facebook Sign-In now enabled
```

---

## STEP 5: GET FIREBASE CONFIG FILE

### 5.1 Download google-services.json
```
Firebase Console:
  Project Settings (gear icon) → Your apps section
  
Find: "Android" app
  If not listed: Click "Add app" → Select Android
    ├── Package name: com.cooperativenicorp.coopcommerce
    ├── SHA-1 certificate (optional for development)
    └── Click: "Register app"

Download: Click "Download google-services.json"
  This file contains all Firebase credentials
```

### 5.2 Place File in Project
```
File Path: android/app/google-services.json

Actions:
  1. Move downloaded google-services.json to android/app/
  2. File should be recognized automatically by gradle
  3. Verify: android/app/build.gradle.kts has:
     
     plugins {
       id 'com.google.gms.google-services'
     }
```

### 5.3 Verify Configuration in pubspec.yaml
```
Check: pubspec.yaml includes Firebase packages

dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  firebase_firestore: ^4.14.0
  firebase_messaging: ^14.7.0
  firebase_storage: ^11.5.0
```

---

## STEP 6: UPDATE FLUTTER APP CONFIGURATION

### 6.1 Update Firebase Initialization
```
File: lib/main.dart

Current code (if using default):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

This automatically uses google-services.json (no changes needed!)

### 6.2 Verify Service Locator Configuration
```
File: lib/core/api/service_locator.dart

Check that Firebase is initialized BEFORE services:
```dart
Future<void> setupServiceLocator() async {
  // Initialize Firebase first
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp();
  }
  
  // Then register services
  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  // Register your services...
  getIt.registerSingleton<FirebaseAuth>(firebaseAuth);
  getIt.registerSingleton<FirebaseFirestore>(firestore);
}
```
```

### 6.3 Update Auth Service for Production
```
File: lib/core/api/auth_service.dart

Verify Google/Facebook sign-in methods are enabled:

```dart
Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    
    final GoogleSignInAuthentication googleAuth = 
      await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    return await _auth.signInWithCredential(credential);
  } catch (e) {
    print('Google sign-in error: $e');
    return null;
  }
}

Future<UserCredential?> signInWithFacebook() async {
  try {
    final LoginResult result = await FacebookAuth.instance.login();
    
    if (result.status == LoginStatus.success) {
      final AccessToken? token = result.accessToken;
      final credential = FacebookAuthProvider.credential(token!.token);
      return await _auth.signInWithCredential(credential);
    }
    return null;
  } catch (e) {
    print('Facebook sign-in error: $e');
    return null;
  }
}
```
```

---

## STEP 7: TEST FIREBASE CONNECTION

### 7.1 Build and Run
```
Terminal:
cd c:\development\coop_commerce

flutter clean
flutter pub get
flutter run -d emulator-5554

(Or on real device)
```

### 7.2 Test Login Flow
```
App opens → Welcome screen

Test 1: Email/Password
  1. Go to Sign Up
  2. Enter: test@coopcommerce.ng / TestPass123!
  3. Create account
  4. Expected: Success, redirected to home
  5. Check Firebase Console → Authentication → Users
     Should see your test user listed

Test 2: Google Sign-In
  1. Tap "Sign in with Google"
  2. Select a Google account
  3. Expected: Success, redirected to home
  4. Check Firebase Console → Users
     Should see Google-authenticated user

Test 3: Facebook Sign-In
  1. Tap "Sign in with Facebook"
  2. Login with Facebook account
  3. Expected: Success, redirected to home
  4. Check Firebase Console → Users
     Should see Facebook-authenticated user
```

### 7.3 Test Firestore Connection
```
After login:

Test 4: Create Product in Cart
  1. Browse products
  2. Add item to cart
  3. Check Firebase Console → Firestore
     Navigate to: carts → [userId] → items
     Expected: Item document created with correct data

Test 5: Create Order
  1. Complete checkout
  2. Check Firestore Database:
     Navigate to: orders → [orderId]
     Expected: Order document with all details

Test 6: Check User Profile Update
  1. Go to Profile → Settings
  2. Update email or preferences
  3. Check Firestore:
     Navigate to: users → [userId]
     Expected: User document updated
```

### 7.4 Verify No Errors in Logs
```
Terminal output should show:
  ✓ Firebase app initialized
  ✓ Firestore connected
  ✓ Auth providers configured
  ✓ No permission errors

If you see permission errors:
  → Check Firestore security rules
  → Verify user is authenticated
  → Check rule syntax
```

---

## STEP 8: CONFIGURE NOTIFICATIONS (FCM)

### 8.1 Get Server Key
```
Firebase Console → Project Settings → Cloud Messaging tab

You should see:
  ├── Server API Key
  ├── Sender ID
  └── Web API Key

Copy: Server API Key (you might need this for backend)
```

### 8.2 Test Notification Delivery
```
Firebase Console → Engage → Cloud Messaging

Click: "New campaign"

Select: "Send a test notification"
  ├── Title: "Test Notification"
  ├── Body: "Is Firebase working?"
  └── Send to test device

On app (must have app open):
  Expected: Notification appears in-app as banner
  
On app (background/closed):
  Expected: System notification appears
```

---

## STEP 9: VERIFY PRODUCTION CONFIG

### Checklist ✅

```
Firebase Project:
  [ ] Production Firebase project created
  [ ] Project ID confirmed: coopcommerce-prod-xxx
  [ ] Location set to europe-west1

Firestore:
  [ ] Database created and initialized
  [ ] Security rules deployed (not test mode)
  [ ] Rules tested (permission denied without auth)

Authentication:
  [ ] Email/Password enabled
  [ ] Google Sign-In configured
  [ ] Facebook Sign-In configured
  [ ] OAuth consent screen set up

Config Files:
  [ ] google-services.json downloaded and in android/app/
  [ ] firebase_core initialized in main.dart
  [ ] Service locator has Firebase instances

Testing:
  [ ] App builds successfully with production Firebase
  [ ] Email/Password login works
  [ ] Google Sign-In works
  [ ] Facebook Sign-In works
  [ ] Test documents visible in Firestore
  [ ] No permission errors in logs
  [ ] FCM test notification received

Production Readiness:
  [ ] Firestore in "Production mode" (not test mode)
  [ ] Security rules reviewed and tested
  [ ] Auth providers have proper redirect URIs
  [ ] All services have >= 99% uptime SLA
```

---

## STEP 10: SECURITY CONSIDERATIONS

### Important ⚠️

```
DO:
  ✓ Keep google-services.json private (add to .gitignore)
  ✓ Use environment-specific firebase configs (dev vs prod)
  ✓ Enable 2FA on Firebase console account
  ✓ Use strong authentication for admin accounts
  ✓ Monitor Firestore usage in Firebase Console
  ✓ Set up billing alerts (Firebase Console → Billing)
  ✓ Regularly review security rules for vulnerabilities
  ✓ Keep Firebase SDK versions updated

DON'T:
  ✗ Commit google-services.json to GitHub
  ✗ Share Firebase API keys publicly
  ✗ Use test mode rules in production
  ✗ Allow unlimited Firestore reads/writes
  ✗ Skip authentication on sensitive operations
  ✗ Use same Firebase project for dev + production
  ✗ Ignore Firebase security notifications/warnings
```

### Cost Management
```
Monitor:
  Firebase Console → Billing → Usage

Watch for:
  - Excessive Firestore reads (optimize queries)
  - Large file uploads (optimize images)
  - High FCM message volume
  - Storage quota usage

Alerts:
  Firebase Console → Budgets & alerts
  Set: Budget of $100/month (adjust as needed)
  Alert: Email when 50%, 90%, 100% spent
```

---

## TROUBLESHOOTING

### Issue: "Permission denied" on Firestore read
```
Cause: Security rules blocking access
Solution: 
  1. Check user is logged in (request.auth != null check)
  2. Verify correct collection structure in rules
  3. Check user role/permissions in rules
  4. Test with temporary permissive rules:
     allow read, write: if true;  // TESTING ONLY!
```

### Issue: Google Sign-In fails
```
Cause: OAuth redirect URI mismatch
Solution:
  1. Get exact OAuth URI from Firebase Auth → Google
  2. Add to Google Cloud Console → OAuth consent
  3. Use exact string - must match character-for-character
```

### Issue: "google-services.json not found"
```
Cause: File not in correct location
Solution:
  File must be at: android/app/google-services.json
  Not: android/app/src/main/google-services.json
  (Gradle handles this automatically)
```

### Issue: Firestore queries returning empty
```
Cause: Data not actually in database or wrong path
Solution:
  1. Check Firebase Console → Firestore → collection exists
  2. Verify collection name matches code
  3. Check security rules allow read
  4. Verify user is authenticated
```

### Issue: FCM notifications not arriving
```
Cause: Multiple possible causes
Solution:
  1. Check app has notification permissions (Android 13+)
  2. Verify FCM token is being sent to server
  3. Check Firebase Console → Cloud Messaging → test
  4. Ensure app is installed from Play Store or properly signed
```

---

## NEXT STEPS

Once Production Firebase is confirmed working:

1. **Create Test Data** (manually or via scripts)
   - Add 10-20 test products
   - Create test user accounts with different roles
   - Create sample orders

2. **Start Phase 2 Testing**
   - Test on emulator (API 21+)
   - Test on real device
   - Use TESTING_SCENARIOS_PLAYSTORE_VALIDATION.md

3. **Monitor Firebase Console**
   - Check usage metrics daily
   - Monitor error logs
   - Track auth provider success rates

4. **Set Up Backup Strategy**
   - Enable automatic backups in Firestore (under Settings)
   - Schedule regular exports
   - Test restore procedure

---

## REFERENCE: FIREBASE PROJECT IDS

Keep these secure and documented:

```
Development Project:
  - Project ID: [YOUR_DEV_PROJECT_ID]
  - Purpose: Testing, development, debugging
  - Data: Can be wiped/reset freely
  - Access: More permissive rules

Production Project:
  - Project ID: coopcommerce-prod-abc123
  - Purpose: Real user data, testing, Phase 2+
  - Data: Real test data, must be protected
  - Access: Strict security rules

When to use:
  - Development: During feature development, before Phase 2
  - Production: From Phase 2 (testing) onward
```

---

## COMMANDS REFERENCE

### Firebase CLI (if installed)
```bash
# Login to Firebase
firebase login

# Deploy rules
firebase deploy --only firestore:rules

# Initialize project locally
firebase init firestore

# Serve emulator locally (for development)
firebase emulators:start
```

### Flutter Commands for Production
```bash
# Build with production Firebase config
flutter build apk --release

# Check what Firebase is initialized
flutter run --verbose | grep firebase

# Test specific config
flutter run --dart-define=ENV=production
```

---

**Status:** Ready for Implementation  
**Difficulty Level:** Medium (follow steps carefully)  
**Support:** Contact Firebase Support if issues: https://firebase.google.com/support  
**Timeline:** Complete by end of Day 2 (Feb 18) for Phase 2 start (Feb 19)

---

**NEXT: Once production Firebase is set up, proceed to Phase 2 Testing using TESTING_SCENARIOS_PLAYSTORE_VALIDATION.md**
