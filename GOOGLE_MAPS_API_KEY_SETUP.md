# Complete Guide: Getting & Configuring Google Maps API Key

**Date:** January 30, 2026  
**Purpose:** Step-by-step instructions for obtaining and configuring Google Maps API key  
**Applies To:** Android & iOS configuration

---

## Table of Contents

1. [Create Google Cloud Project](#create-google-cloud-project)
2. [Enable Google Maps API](#enable-google-maps-api)
3. [Create API Key](#create-api-key)
4. [Android Configuration](#android-configuration)
5. [iOS Configuration](#ios-configuration)
6. [Testing & Verification](#testing--verification)
7. [Troubleshooting](#troubleshooting)

---

## Create Google Cloud Project

### Step 1: Go to Google Cloud Console

**URL:** [https://console.cloud.google.com](https://console.cloud.google.com)

### Step 2: Create New Project

1. Click on **Project Selector** (top-left dropdown showing current project)
2. Click **NEW PROJECT**
3. Enter Project Name:
   ```
   Coop Commerce Maps
   ```
4. Select Organization (if applicable)
5. Click **CREATE**

**Wait 1-2 minutes for project creation**

### Step 3: Select the Project

1. Go back to Project Selector
2. Find and click **Coop Commerce Maps**
3. Wait for it to load (you'll see the project name in top-left)

---

## Enable Google Maps API

### Step 4: Enable Google Maps Platform APIs

1. In the Google Cloud Console, go to **APIs & Services** → **Library**
2. Search for **Google Maps Platform**
3. You'll see several options, enable these THREE:

   **Required:**
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Google Maps API** (general)

4. For each one:
   - Click on the API name
   - Click **ENABLE**
   - Wait for confirmation (green checkmark)

**Status Check:**
- Go to **APIs & Services** → **Enabled APIs & Services**
- You should see all three enabled

---

## Create API Key

### Step 5: Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** (top button)
3. Select **API Key**
4. You'll see a dialog with your API key:
   ```
   AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
5. Copy and save this key somewhere safe (Notepad, password manager)

### Step 6: Restrict API Key (Important for Security)

1. Back in **Credentials** page, find your newly created API key
2. Click on it to open details
3. Under **Key restriction**, select **Android apps** AND/OR **iOS apps** depending on your needs
4. Add your app's restrictions:

**For Android:**
- Click **Add an Android app**
- Enter your app's **Package Name** and **SHA-1 fingerprint**
- See [Get Android Fingerprint](#get-android-app-fingerprint) below

**For iOS:**
- Click **Add an iOS app**
- Enter your app's **Bundle ID** and **Team ID**
- See [Get iOS Bundle ID](#get-ios-bundle-id) below

5. Click **SAVE**

---

## Android Configuration

### Get Android App Fingerprint

Your Android SHA-1 fingerprint is needed to restrict the API key.

#### Option 1: Using Flutter (Recommended)

```bash
cd c:\development\coop_commerce
flutter doctor -v | grep -i "certificate"
```

Or run:

```bash
cd android
./gradlew signingReport
```

Look for output like:
```
SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90
```

#### Option 2: Using Java Keytool

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Find the **SHA1** line.

### Configure AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

Add this meta-data tag inside `<application>`:

```xml
<application
    android:label="@string/app_name"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Google Maps API Key -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
    
    <!-- Your other activities... -->
    <activity
        android:name=".MainActivity"
        ...
    </activity>
</application>
```

**Replace:** `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

**Location:** Between `<application>` opening tag and first `<activity>`

### Update build.gradle.kts (Android)

**File:** `android/build.gradle.kts` (Project level)

Ensure Google Services plugin is available:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}
```

**File:** `android/app/build.gradle.kts` (App level)

Ensure compileSdk is at least 34:

```kotlin
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 21  // Google Maps requires minimum SDK 21
    }
    
    // rest of config...
}
```

### Add Location Permissions

**File:** `android/app/src/main/AndroidManifest.xml`

Add permissions before `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<application>
    <!-- ... -->
</application>
```

---

## iOS Configuration

### Get iOS Bundle ID & Team ID

**Bundle ID:**
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select **Runner** project
3. Go to **Build Settings** tab
4. Search for **Bundle Identifier**
5. You'll see something like: `com.example.coopCommerce`

**Team ID:**
1. Go to **Signing & Capabilities** tab
2. Under **Team**, you'll see your Team ID (e.g., `ABCDEF1234`)

### Update Info.plist

**File:** `ios/Runner/Info.plist`

Add these keys inside the root `<dict>`:

```xml
<dict>
    <!-- Existing keys... -->
    
    <!-- Google Maps API Key -->
    <key>GoogleMapsApiKey</key>
    <string>YOUR_GOOGLE_MAPS_API_KEY_HERE</string>
    
    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to show delivery tracking on the map</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We need your location for delivery tracking and notifications</string>
    
    <!-- Background Modes for Push Notifications -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
        <string>location</string>
    </array>
    
    <!-- Existing keys continue... -->
</dict>
```

**Replace:** `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

### Update Podfile

**File:** `ios/Podfile`

Ensure Google Maps pod is included (should be auto-added by flutter):

```ruby
target 'Runner' do
  flutter_root = File.expand_path(File.join(packages_dir, '.symlinks', 'flutter'))
  load File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper.rb')

  flutter_ios_podfile_setup

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### Update Deployment Target

**File:** `ios/Podfile`

Ensure deployment target is iOS 11.0 or higher:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
      ]
    end
  end
end
```

---

## Testing & Verification

### Step 1: Rebuild Flutter App

```bash
cd c:\development\coop_commerce

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# For Android
flutter run -d android

# For iOS (from ios/ directory)
cd ios
pod install --repo-update
cd ..
flutter run -d ios
```

### Step 2: Open Order Tracking Screen

1. Login to the app
2. View any existing order or create new one
3. Navigate to **Order Tracking** screen
4. You should see:
   - Interactive Google Map
   - Warehouse marker (Lagos)
   - Delivery location marker
   - Blue route line
   - Delivery address card at bottom

### Step 3: Verify Map Features

✅ **Markers appear correctly**
- Warehouse marker at top of map
- Delivery marker at bottom
- Both have info windows

✅ **Route displays**
- Blue polyline connects warehouse → delivery
- Shows full delivery path

✅ **Camera animation works**
- Map smoothly zooms to delivery location
- Takes ~1 second

✅ **Delivery card shows data**
- Displays delivery address
- Shows estimated delivery time
- Updates with order changes

### Step 4: Test Push Notifications

1. Open **Firebase Console** → **Cloud Messaging**
2. Send test message with this payload:
```json
{
  "notification": {
    "title": "Test Order Update",
    "body": "This is a test notification"
  },
  "data": {
    "orderId": "test_order_123",
    "orderStatus": "dispatched",
    "previousStatus": "processing",
    "title": "Order Dispatched 🚚",
    "message": "Your order is on the way!",
    "timestamp": "2026-01-30T10:30:00Z"
  }
}
```
3. Select your device → **Send**
4. You should see:
   - **Foreground:** Toast notification appears
   - **Background:** System notification in drawer

---

## Troubleshooting

### Issue 1: Map Shows Blank/Gray Screen

**Cause:** API key not configured or invalid

**Solution:**
```bash
# Verify API key in AndroidManifest.xml
cat android/app/src/main/AndroidManifest.xml | grep -A2 "API_KEY"

# Verify API key in Info.plist
cat ios/Runner/Info.plist | grep -A1 "GoogleMapsApiKey"

# Verify API is enabled
# - Go to Google Cloud Console
# - APIs & Services → Enabled APIs & Services
# - Look for "Google Maps" related APIs
```

### Issue 2: Map Shows Tiles But No Markers

**Cause:** Delivery location coordinates missing or invalid

**Solution:**
- Order must have `latitude` and `longitude` in address
- Coordinates must be valid:
  - Latitude: -90 to 90
  - Longitude: -180 to 180
- Check order data in Firestore

### Issue 3: "Unauthorized MapsInitializationException"

**Cause:** API key restrictions don't match app

**Solution:**
1. Go to **Google Cloud Console** → **Credentials**
2. Click your API key
3. Under **Application restrictions**, select **None** (temporarily for testing)
4. Click **SAVE**
5. Rebuild and test
6. Once working, add proper restrictions back:
   - Select **Android apps**
   - Add your app package name + SHA-1
   - Select **iOS apps**
   - Add your bundle ID + team ID

### Issue 4: "PERMISSION_DENIED" Error

**Cause:** Location permissions not granted

**Solution:**
1. Go to **Settings** → **Apps** → **Coop Commerce**
2. Select **Permissions**
3. Grant **Location** permission
4. Set to **Allow all the time** (for background tracking)

### Issue 5: FCM Token is Null

**Cause:** Firebase not initialized

**Solution:**
1. Ensure `google-services.json` in `android/app/`
2. Ensure `GoogleService-Info.plist` in `ios/Runner/`
3. Rebuild: `flutter clean && flutter pub get && flutter run`
4. Check console for: "FCM Token: eIz4e..."

### Issue 6: Notifications Not Received

**Cause:** Multiple possible issues

**Solution Checklist:**
- [ ] FCM token exists (check console logs)
- [ ] App has notification permission (Settings → Permissions)
- [ ] Device has internet connection
- [ ] Message sent to correct FCM token
- [ ] Message payload is valid JSON
- [ ] Device is connected to Firebase project

---

## API Key Cost & Quotas

### Pricing

**Google Maps:** 
- First 28,000 map loads per month FREE
- After that: $7 per 1,000 loads

**Recommendations:**
- Use map only on order tracking screen
- Cache map tiles when possible
- Monitor usage in Google Cloud Console

### Set Up Billing Alerts

1. Go to **Billing** in Google Cloud Console
2. Create budget alert for ~$100/month
3. Get notified before overspending

---

## Production Checklist

Before deploying to production:

- [ ] API key created and restricted to your app
- [ ] AndroidManifest.xml has API key
- [ ] Info.plist has API key
- [ ] Both Android & iOS minimum SDK/deployment targets met
- [ ] Location permissions in manifest/plist
- [ ] Maps SDK enabled in Google Cloud
- [ ] Tested on real Android device
- [ ] Tested on real iOS device
- [ ] Billing configured with alerts
- [ ] API key rotation plan established

---

## Useful Links

- **Google Cloud Console:** https://console.cloud.google.com
- **Google Maps Documentation:** https://developers.google.com/maps/documentation
- **Flutter Maps Package:** https://pub.dev/packages/google_maps_flutter
- **Android Configuration:** https://developers.google.com/maps/documentation/android-sdk/start
- **iOS Configuration:** https://developers.google.com/maps/documentation/ios-sdk/start

---

## Support

### If You're Still Having Issues:

1. **Check Console Logs**
   ```bash
   flutter run -v  # Verbose output
   ```
   Look for messages mentioning Maps or API

2. **Visit Flutter Maps GitHub**
   https://github.com/google/maps-sdk-for-android/issues

3. **Google Cloud Support**
   https://cloud.google.com/support

---

**Status:** ✅ Complete Guide  
**Last Updated:** January 30, 2026  
**Version:** 1.0

Remember: Never commit your actual API key to version control! Use environment variables for production deployment.
