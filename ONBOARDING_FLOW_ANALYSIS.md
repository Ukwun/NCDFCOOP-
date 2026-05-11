# Complete Onboarding Flow Analysis
## NCDFCOOP Coop Commerce App

**Analysis Date:** April 5, 2026  
**Project:** coop_commerce (Flutter)

---

## 📋 Table of Contents
1. [Flow Overview](#flow-overview)
2. [Splash Screen Implementation](#splash-screen-implementation)
3. [Onboarding Screens](#onboarding-screens)
4. [Authentication Screens](#authentication-screens)
5. [Role Selection](#role-selection)
6. [Design System & Theming](#design-system--theming)
7. [Animation Configurations](#animation-configurations)
8. [Complete Navigation Routes](#complete-navigation-routes)

---

## 🎯 Flow Overview

### User Journey Path
```
App Launch
    ↓
Splash Screen (2 sec)
    ↓
    ├─ [Unauthenticated] → Welcome Screen
    │   ↓
    │   Select Membership Type (Member/Wholesale/Cooperative)
    │   ↓
    │   Sign Up Screen
    │   ↓
    │   Role Selection Screen
    │   ↓
    │   Home (with selected role)
    │
    └─ [Authenticated, Role Not Selected] → Role Selection Screen → Home
```

### Router Initial Location
- **Initial Route:** `/splash`
- **Redirect Logic:** Authentication and role-based routing in [lib/config/router.dart](lib/config/router.dart#L259-L319)

---

## 🎨 Splash Screen Implementation

### 1. **Primary Splash Screen**
**File:** [lib/features/welcome/splash_screen.dart](lib/features/welcome/splash_screen.dart)

**Key Features:**
- **Entry Point:** After app startup (2-second display)
- **Navigation Logic:** Routes based on authentication status
  - If user NOT authenticated → `/onboarding`
  - If authenticated but role not selected → `/role-selection`
  - If fully authenticated → `/` (home)
- **Animation:** Fade-in animation (1500ms duration)
- **Background:** Dark gradient (`Color(0xFF12202F)`)
- **State Management:** Uses `auth_provider` for checking `isAuthenticatedProvider` and `currentUserProvider`

**Code Structure:**
```dart
- ConsumerStatefulWidget with SingleTickerProviderStateMixin
- AnimationController: 1500ms fade animation
- Timer: Navigates after 2 seconds
- _navigateBasedOnAuthStatus(): Routes based on auth state
```

### 2. **Alternative Splash Screen**
**File:** [lib/features/splash/splash_screen.dart](lib/features/splash/splash_screen.dart)

**Key Features:**
- More comprehensive initialization
- Always routes to `/welcome` after 2 seconds
- Fade-in animation (1000ms duration)
- Background: CoopCommerce green (`Color(0xFF1A472A)`)
- Better error handling for app initialization

---

## 🎬 Onboarding Screens

### **Screen 1 - Introduction**
**File:** [lib/features/welcome/onboarding_screen.dart](lib/features/welcome/onboarding_screen.dart)

**Configuration:**
- **Background Image:** `assets/images/onboardimg1.jpg`
- **Title:** "Welcome to NCDFCOOP"
- **Subtitle:** "Nigeria's controlled trade infrastructure for reliable buying and selling"
- **Design:** Glass morphism overlay (bottom 50% of screen)
- **Color Scheme:**
  - Background: Light gray (`Color(0xFFD9D9D9)`)
  - Overlay: Frosted glass effect with alpha transparency
  - Title: White (`Color(0xFFFAFAFA)`)
  - Accent: Gold/Orange (`Color(0xFFF3951A)`)
  - Subtitle: Light gray (`Color(0xFFCCCCCC)`)

**Widget Structure:**
- Positioned background image (full screen)
- Positioned glass overlay container (bottom half, 50% height)
- RichText for title with accent color on "NCDFCOOP"
- Rounded corners: `BorderRadius.circular(25)` (top corners)
- Border: Frosted glass border with light color
- Box shadow for depth

---

### **Screen 2 - Membership Benefits**
**File:** [lib/features/welcome/onboarding_screen_2.dart](lib/features/welcome/onboarding_screen_2.dart)

**Configuration:**
- **Background Image:** `assets/images/onboardimg2.jpg`
- **Content:** Membership tier display with badges
- **Membership Tiers Shown:**
  - Each tier displays: Name, discount percentage, color-coded badge
  - Circular badge containers with border styling
  - Font sizes: 16px (discount), 12px (name)

**Components:**
- `_MembershipTierBadge` widget for displaying membership levels
- Same glass morphism design as Screen 1
- Color-coded tier system with distinct UI identity

---

### **Screen 3 - Unlock Wholesale Power**
**File:** [lib/features/welcome/onboarding_screen_3.dart](lib/features/welcome/onboarding_screen_3.dart)

**Configuration:**
- **Background Image:** `assets/images/lastonboardimg.png`
- **Title:** "Unlock Wholesale Power"
- **Height:** 55% of screen (slightly taller than screens 1 & 2)
- **ScrollView:** SingleChildScrollView for content that might overflow
- **Design:** Same glass morphism as other onboarding screens

**Typography:**
- Title: Libre Baskerville, 32px, bold
- Accent color on "Power"
- Rich text formatting for emphasis

---

### **Navigation Through Onboarding**
Routes defined in [lib/config/router.dart](lib/config/router.dart#L360-L395):
- `/onboarding` → OnboardingScreen
- `/onboarding2` → OnboardingScreen2
- `/onboarding3` → OnboardingScreen3
- Transition: FadeTransition (300ms duration)

---

## 🔐 Authentication Screens

### **1. Welcome Screen**
**File:** [lib/features/welcome/welcome_screen.dart](lib/features/welcome/welcome_screen.dart)

**Purpose:** Initial choice screen for membership type

**Key Features:**
- **Membership Types Available:**
  - Member (default shopping experience)
  - Wholesale (bulk buying)
  - Cooperative (cooperative membership)
- **Animation:** Fade-in animation (1200ms duration)
- **Navigation:** Routes to sign-up with membership type parameter
  - Example: `/signup/member`, `/signup/wholesale`, `/signup/cooperative`

**Widget Structure:**
- StatefulWidget with SingleTickerProviderStateMixin
- AnimationController for fade effect
- Member type selection handling
- Responsive layout for small screens (<800px height)

---

### **2. Sign In Screen**
**File:** [lib/features/welcome/sign_in_screen.dart](lib/features/welcome/sign_in_screen.dart)

**Route:** `/signin`

**Features:**
- Email/password authentication
- "Remember Me" checkbox
- Error handling with SnackBar notifications
- Uses `authControllerProvider` from Riverpod
- Listens for auth state changes
- On success: Navigates to `/` (home)

**Form Elements:**
- Email input field
- Password input field
- Remember me toggle
- Sign in button with loading state

---

### **3. Sign Up Screen**
**File:** [lib/features/welcome/sign_up_screen.dart](lib/features/welcome/sign_up_screen.dart)

**Routes:**
- `/signup` (default to member)
- `/signup/:type` (with membership type parameter)

**Features:**
- **Membership Type Parameter:** Passed from welcome screen
- **Form Validation:** Uses FormState for validation
- **Fields:**
  - Email
  - Password (with obscure toggle)
  - Password confirmation
- **Navigation:** On success → `/role-selection`
- **State Management:** Riverpod `authControllerProvider`

**Sign-Up Flow:**
```dart
ref.read(authControllerProvider.notifier).signUpWithMembership(
  email,
  password,
  membershipType: membershipType,
  rememberMe: rememberMe,
)
```

---

### **4. Login Form Screen**
**File:** [lib/features/welcome/login_form_screen.dart](lib/features/welcome/login_form_screen.dart)

**Route:** `/login-form`

**Purpose:** Alternative login interface (variant of sign-in)

---

### **5. Forgot Password Screen**
**File:** [lib/features/welcome/forgot_password_screen.dart](lib/features/welcome/forgot_password_screen.dart)

**Route:** `/forgot-password`

**Features:**
- Email recovery flow
- Links to password reset via email

---

### **6. Create New Password Screen**
**File:** [lib/features/welcome/create_new_password_screen.dart](lib/features/welcome/create_new_password_screen.dart)

**Route:** `/create-new-password?token={token}`

**Features:**
- Token-based password reset
- Query parameter: `token` from reset email link
- Sets new password after verification

---

## 👥 Role Selection Screen

**File:** [lib/features/auth/screens/role_selection_screen.dart](lib/features/auth/screens/role_selection_screen.dart)

**Route:** `/role-selection`

**Purpose:** Critical onboarding step determining user experience, features, and pricing

**Available Roles:**
1. **Member** (👤)
   - Color: Brown (`Color(0xFF8B6F47)`)
   - Benefits:
     - Member pricing
     - Add money to account
     - Save money in account
     - Upgrade to Premium Member
     - Loyalty rewards
     - Priority support

2. **Wholesale Buyer** (🛒)
   - Color: Dark Blue (`Color(0xFF2E5090)`)
   - Benefits:
     - Wholesale bulk pricing
     - Add money to account
     - Multiple delivery locations
     - Flexible payment terms
     - Dedicated account manager
     - Invoice billing

3. **Start Selling** (🚀)
   - Color: Dark Green (`Color(0xFF1A4E00)`)
   - Benefits:
     - Sell to Members
     - Sell to Wholesale Buyers
     - Inventory management
     - Sales analytics
     - Marketing tools
     - Seller support

**Role Selection Model:**
```dart
_RoleOptionModel {
  role: UserRole
  title: String
  subtitle: String
  description: String
  benefits: List<String>
  color: Color
  icon: IconData
}
```

**State Management:**
- ConsumerStatefulWidget with Riverpod
- Stores selected role in local state
- Validates before proceeding
- Shows error SnackBar if no role selected
- Error color: `AppColors.error`

---

## 🎨 Design System & Theming

### **Theme Files**

#### **Main Theme File**
**File:** [lib/theme/app_theme.dart](lib/theme/app_theme.dart)

**Contents:**
- `AppSpacing` class: Consistent spacing units (xs, sm, md, lg, xl, xxl, xxxl, huge)
  - Base unit: 4px
  - Range: 4px to 40px
- `AppRadius` class: Consistent border radius values
  - xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 20px, full: 100px
- `AppShadows` class: Predefined shadow configurations
  - subtle, sm, md, lg, xl shadows with corresponding lists
- `AppTheme.lightTheme` configuration
- Button theme styles (elevated, outlined, text)
- Input decoration theme

#### **Color Palette**
**File:** [lib/theme/app_colors.dart](lib/theme/app_colors.dart)

**Primary Colors:**
- Primary (Indigo): `#4F46E5`
  - Light: `#6366F1`
  - Dark: `#4338CA`
  - Container: `#F0F0FF`
- Secondary (Emerald): `#10B981`
  - Light: `#34D399`
  - Dark: `#059669`
  - Container: `#D1FAE5`
- Accent (Gold/Orange): `#F3951A`
- Gold (Premium): `#C9A227`
- Tertiary (Amber): `#F59E0B`

**Background & Surface:**
- Background: `#FAFAFA` (off-white)
- Surface: `#FFFFFF` (white)
- Variant: `#F5F5F5` (light gray)

**Text Colors:**
- Primary text: `#1F2937` (dark gray)
- Light text: `#6B7280` (medium gray)
- Secondary: `#6B7280`
- Tertiary: `#9CA3AF`
- Disabled: `#D1D5DB`

**Status Colors:**
- Error: `#EF4444` (red)
- Success: `#22C55E` (green)
- Warning: `#EAB308` (yellow)
- Info: `#3B82F6` (blue)

**Border & Divider:**
- Border: `#E0E0E0`
- Divider: `#E5E7EB`

#### **Text Styles**
**File:** [lib/theme/app_text_styles.dart](lib/theme/app_text_styles.dart)

**Heading Styles:**
- `h1`: 32px, bold, 1.2 height, -0.5 letter spacing
- `h2`: 28px, bold, 1.3 height, -0.3 letter spacing
- `h3`: 24px, bold, 1.4 height, -0.2 letter spacing
- `h4`: 20px, bold, 1.5 height
- `h5`: 18px, bold, 1.5 height
- `h6`: 16px, bold, 1.5 height

**Body Styles:**
- `bodyLarge`: 16px, normal weight, 1.5 height
- `bodyMedium`: 14px, normal weight
- `bodySmall`: 12px, normal weight

**Label Styles:**
- `labelLarge`, `labelMedium`, `labelSmall` variants

#### **Theme Extension**
**File:** [lib/theme/theme_extension.dart](lib/theme/theme_extension.dart)

**Purpose:** Dynamic color theming capabilities for screens

---

### **Color Role Mapping (User Roles)**
**File:** [lib/core/auth/role.dart](lib/core/auth/role.dart)

**Color Codes by Role:**
- Wholesale Buyer: `#1E7F4E` (green)
- Coop Member: `#C9A227` (gold)
- Premium Member: `#FFD700` (bright gold)
- Seller: `#0B6B3A` (dark green)
- Franchise Owner: `#F3951A` (orange)
- Store Manager: `#F3951A` (orange)
- Store Staff: `#F3951A` (orange)
- Institutional Buyer: `#8B5CF6` (purple)
- Institutional Approver: `#8B5CF6` (purple)
- Warehouse Staff: `#EC4899` (pink)
- Delivery Driver: `#06B6D4` (cyan)
- Admin: `#EF4444` (red)
- Super Admin: `#DC2626` (dark red)

---

## 🎭 Animation Configurations

### **Animation Library**
**File:** [lib/core/animations/app_animations.dart](lib/core/animations/app_animations.dart)

### **Haptic Feedback**
```dart
AppAnimations.lightTap()    // Light vibration
AppAnimations.mediumTap()   // Medium vibration
AppAnimations.heavyTap()    // Heavy vibration
AppAnimations.selection()   // Selection click
```

### **Page Transition Animations**

#### **1. Slide Up Page Route**
**Class:** `SlideUpPageRoute`
- **Duration:** 450ms (customizable)
- **Transition:** Slide from bottom (0, 0.1) to center
- **Curve:** `Curves.easeOutCubic`
- **Additional:** Combined with FadeTransition
- **Opacity:** true (uses opacity animation)

**Code:**
```dart
SlideUpPageRoute(
  builder: (context) => YourScreen(),
  duration: Duration(milliseconds: 450),
)
```

#### **2. Fade Page Route**
**Class:** `FadePageRoute`
- **Duration:** 300ms (default, customizable)
- **Transition:** Pure opacity fade-in
- **Opacity:** true (only opacity animation)

**Code:**
```dart
FadePageRoute(
  builder: (context) => YourScreen(),
  duration: Duration(milliseconds: 300),
)
```

### **Splash Screen Animations**
- **Fade Animation:** Tween<double>(0.0 → 1.0)
- **Curve:** `Curves.easeIn`
- **Duration:** 1500ms (primary splash) or 1000ms (alternative splash)
- **Controller:** AnimationController with `SingleTickerProviderStateMixin`

### **Welcome Screen Animation**
- **Fade Animation:** Tween<double>(0.0 → 1.0)
- **Curve:** `Curves.easeIn`
- **Duration:** 1200ms

### **Onboarding Screen Transitions (Router)**
- **Transition Type:** FadeTransition
- **Duration:** 300ms
- **Applied in GoRouter:** CustomTransitionPage with transitionsBuilder

---

## 📍 Complete Navigation Routes

### **Auth Flow Routes** [lib/config/router.dart](lib/config/router.dart)

| Route | Screen | Purpose | Params |
|-------|--------|---------|--------|
| `/splash` | SplashScreen | Initial app load | - |
| `/welcome` | WelcomeScreen | Membership selection | - |
| `/onboarding` | OnboardingScreen | Intro to NCDFCOOP | - |
| `/onboarding2` | OnboardingScreen2 | Membership benefits | - |
| `/onboarding3` | OnboardingScreen3 | Wholesale features | - |
| `/feature-discovery` | FeatureDiscoveryScreen | Feature overview | - |
| `/signin` | SignInScreen | Sign in existing user | - |
| `/login-form` | LoginFormScreen | Alternative login | - |
| `/signup` | SignUpScreen | Sign up (default: member) | `type` query param |
| `/signup/:type` | SignUpScreen | Sign up with type | `type` path param |
| `/role-selection` | RoleSelectionScreen | Select primary role | `userId`, `userEmail`, `userName` (extra) |
| `/forgot-password` | ForgotPasswordScreen | Password recovery | - |
| `/create-new-password` | CreateNewPasswordScreen | Set new password | `token` query param |
| `/membership` | MembershipScreen | Membership details | - |

### **Redirect Logic** [lib/config/router.dart](lib/config/router.dart#L259-L319)

**Public Routes (Accessible without authentication):**
```
/welcome, /signin, /signup/*, /splash, /onboarding*,
/forgot-password, /create-new-password, /about-cooperatives,
/features-guide, /app-tour, /help-center, /role-selection
```

**Redirect Rules:**
1. **While Auth Loading:**
   - Stay on `/splash` for non-public routes
   - Allow public routes to proceed

2. **Auth Error:**
   - Redirect to `/splash` for non-public routes

3. **Unauthenticated Users:**
   - Can access public routes
   - Redirect to `/splash` for protected routes

4. **Authenticated, Role Not Selected:**
   - Redirect to `/role-selection`

5. **Authenticated, Role Selected:**
   - Check permission for protected routes
   - Redirect to `/` (home) if no permission

---

## 🔄 Role System

**File:** [lib/core/auth/role.dart](lib/core/auth/role.dart)

### **Defined Roles (Enum: UserRole)**
```dart
enum UserRole {
  wholesaleBuyer,
  coopMember,
  premiumMember,
  seller,
  franchiseOwner,
  storeManager,
  storeStaff,
  institutionalBuyer,
  institutionalApprover,
  warehouseStaff,
  deliveryDriver,
  admin,
  superAdmin,
}
```

### **Role Properties**
Each role has:
- `displayName`: User-facing label
- `colorCode`: Hex color for UI badges
- `requiresApproval`: Boolean for approval workflows
- `isWholesale`: Boolean for wholesale-related roles
- `isInstitutional`: Boolean for institutional roles
- `isLogistics`: Boolean for logistics roles

---

## 🔑 Constants & Configuration

**File:** [lib/utils/app_constants.dart](lib/utils/app_constants.dart)

### **Key Configuration:**
- **API Base URL:** `https://api.coopcommerce.com/v1`
- **API Timeout:** 30 seconds
- **Max Retries:** 3
- **Firebase Region:** `us-central1`

### **Firestore Collections:**
- `users`, `products`, `orders`, `reviews`, `categories`, `carts`, `addresses`, `favorites`

### **Text Field Constraints:**
- Min password: 8 chars, Max: 128 chars
- Min username: 3 chars, Max: 20 chars
- Min name: 2 chars, Max: 50 chars

### **Validation Patterns:**
- Email regex, phone regex, username regex, URL regex

---

## 🛠️ State Management

### **Auth Provider**
**File:** [lib/features/welcome/auth_provider.dart](lib/features/welcome/auth_provider.dart)

**Key Providers:**
- `authServiceProvider`: Provides AuthService instance
- `authStateProvider`: StreamProvider for auth state changes
- `onboardingCompletedProvider`: Checks onboarding completion from SharedPreferences
- `authControllerProvider`: AsyncNotifier for auth UI logic
- `isAuthenticatedProvider`: Boolean - is user authenticated
- `currentUserProvider`: Current authenticated user

### **Auth Service**
**File:** [lib/core/api/auth_service.dart](lib/core/api/auth_service.dart)

**Methods:**
- `login()`: Email/password authentication
- `signUp()`: Create new account
- `logout()`: User logout
- `authStateChanges`: Stream for real-time auth updates

---

## 📦 Dependencies for Onboarding

**From pubspec.yaml:**
- `flutter_riverpod: ^3.2.0`: State management
- `riverpod_annotation: 3.0.0-dev.0`: Riverpod annotations
- `go_router: ^14.0.0`: Navigation/routing
- `firebase_auth: ^4.15.0`: Authentication
- `google_sign_in: ^6.2.1`: Google auth
- `flutter_facebook_auth: ^7.0.1`: Facebook auth
- `sign_in_with_apple: ^7.0.1`: Apple auth
- `shared_preferences: ^2.2.2`: Local storage for onboarding flag

---

## ✅ Summary

### **Key Files:**
1. **Entry:** [lib/main.dart](lib/main.dart) - App initialization
2. **Routing:** [lib/config/router.dart](lib/config/router.dart) - All routes
3. **Splash:** [lib/features/welcome/splash_screen.dart](lib/features/welcome/splash_screen.dart) & [lib/features/splash/splash_screen.dart](lib/features/splash/splash_screen.dart)
4. **Onboarding:** [lib/features/welcome/onboarding_screen.dart](lib/features/welcome/onboarding_screen.dart), [onboarding_screen_2.dart](lib/features/welcome/onboarding_screen_2.dart), [onboarding_screen_3.dart](lib/features/welcome/onboarding_screen_3.dart)
5. **Auth:** [lib/features/welcome/sign_in_screen.dart](lib/features/welcome/sign_in_screen.dart), [sign_up_screen.dart](lib/features/welcome/sign_up_screen.dart), [auth_provider.dart](lib/features/welcome/auth_provider.dart)
6. **Role:** [lib/features/auth/screens/role_selection_screen.dart](lib/features/auth/screens/role_selection_screen.dart), [lib/core/auth/role.dart](lib/core/auth/role.dart)
7. **Design:** [lib/theme/app_theme.dart](lib/theme/app_theme.dart), [app_colors.dart](lib/theme/app_colors.dart), [app_text_styles.dart](lib/theme/app_text_styles.dart)
8. **Animations:** [lib/core/animations/app_animations.dart](lib/core/animations/app_animations.dart)

### **Flow Summary:**
```
App Launch
  ↓ (2 sec)
Splash Screen (auth check)
  ↓
Welcome Screen (membership selection)
  ↓
Sign Up Screen (with membership type)
  ↓
Role Selection Screen (choose primary role)
  ↓
Home Screen (authenticated with role)
```

### **Design Highlights:**
- **Modern Color Scheme:** Indigo primary, emerald secondary, gold accents
- **Glass Morphism:** Used in onboarding overlays
- **Smooth Transitions:** Fade and slide animations (300-450ms)
- **Responsive Design:** Adapts to screen size
- **Role-Based UI:** Different colors and experiences per role
- **Comprehensive Theming:** Centralized color, spacing, shadow definitions
