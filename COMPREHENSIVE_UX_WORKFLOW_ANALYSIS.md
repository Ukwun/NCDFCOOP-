# COMPREHENSIVE UX WORKFLOW ANALYSIS
## NCDF COOP Commerce - Flutter Mobile App
**For Website Implementation Team**

**Document Date:** April 5, 2026  
**App Version:** Production Ready  
**Architecture:** Riverpod + GoRouter + Firebase  

---

## EXECUTIVE SUMMARY

The NCDF COOP Commerce app implements a sophisticated, role-based user experience that evolves based on the user's identity and role selection. The entire user journey is carefully orchestrated through:

1. **Splash Screen (2-3 seconds)** - Initial app load with branding
2. **Welcome & Onboarding (3 screens)** - Educational introduction to the platform
3. **Authentication (Sign In / Sign Up)** - Email/password or social authentication
4. **Role Selection** - Critical decision point determining user experience
5. **Role-Aware Home Screen** - Customized dashboard based on selected role

Each phase has specific UX goals, visual design patterns, and backend interactions. The website version should mirror this journey while adapting to web-native interactions.

---

## PART 1: USER JOURNEY PHASES

### Phase 1: SPLASH SCREEN (2-3 seconds)

**Purpose:** Brand introduction and initialization  
**Duration:** 2 seconds minimum (allows user to perceive the brand)  
**Technical Function:** Background initialization of app systems

#### Visual Design
```
┌─────────────────────────────────────┐
│                                     │
│   Background Color: #1A472A         │
│   (Deep Cooperative Green)          │
│                                     │
│         ◯ 150x150px                │
│         Shopping Cart Icon          │
│         (White, semi-transparent)   │
│                                     │
│   CoopCommerce                      │
│   (32pt, Bold, White)               │
│                                     │
│   Quality Products, Fair Prices     │
│   (14pt, Gray-white, Italic)        │
│                                     │
│         ⟳ Loading Indicator        │
│                                     │
└─────────────────────────────────────┘
```

#### User Experience
- User sees brand identity (CoopCommerce) immediately
- Visual consistency with cooperative values
- While splash is displayed (2 seconds), app initializes:
  - Firebase connectivity checks
  - FCM (Firebase Cloud Messaging) for notifications
  - Service locator for dependency injection
  - Theme configuration (light/dark mode)
  - Persisted user check (auto-login if previously logged in)

#### Technical Flow
```
[App Launch]
    ↓
[SplashScreen Displayed - 2 seconds]
    │
    ├─→ Firebase.initializeApp()
    ├─→ FCMService.initialize()
    ├─→ ServiceLocator.initialize()
    ├─→ Check Persisted User
    │
[After 2 seconds + init complete]
    ↓
[Navigate to Welcome]
```

#### Implementation Notes (for Website)
- Use a progressive fade-in animation for branding
- Load Firebase SDK in background
- Detect if user has active session (localStorage)
- If session exists, proceed; if not, go to welcome
- Mobile: 2 second minimum, Website: 1.5 seconds (users expect faster web experience)

---

### Phase 2: WELCOME & ONBOARDING (3 Educational Screens)

**Purpose:** Educate new users about platform capabilities  
**Typical Duration:** 1-2 minutes to complete  
**User Action:** "Get Started" button at end

#### Screen 1: Welcome Screen

**Headline:** "Welcome to NCDFCOOP Fairmarket"

**Content Structure:**
```
┌─────────────────────────────────────┐
│  [NCDF COOP Logo]                   │
│                                     │
│  Welcome to NCDFCOOP Fairmarket     │
│                                     │
│  [Illustration: Diverse users       │
│   buying/selling together]          │
│                                     │
│  Choose your role and start         │
│  shopping or selling today          │
│                                     │
│  [Next Button] →                    │
└─────────────────────────────────────┘
```

**Purpose:**
- Establish the cooperative, community-focused mission
- Show diversity and inclusion (diverse user illustrations)
- Simple, inviting introduction
- No decision required on this screen

#### Screen 2: Onboarding Screen (Features Overview)

**Content Components:**

1. **Consumer Benefits (Buying)**
   - Icon: Shopping Bag
   - "Shop Fair Prices"
   - "Access quality products from verified sellers"
   - Sub-features: Member discounts, loyalty rewards, bulk purchasing

2. **Seller Benefits (Selling)**
   - Icon: Store
   - "Start Selling"
   - "Reach verified buyers in our cooperative"
   - Sub-features: Product approval workflow, analytics, support

3. **Community Benefits**
   - Icon: People
   - "Be Part of a Cooperative"
   - "Trust, transparency, and community dividends"
   - Sub-features: Member voting, profit sharing, cooperative governance

**Visual Pattern:**
```
┌────────────────────────────────────┐
│  [Icon]  Shop Fair Prices          │
│  Access quality products...        │
│  • Member discounts               │
│  • Loyalty rewards                │
│  • Bulk purchasing                │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│  [Icon]  Start Selling             │
│  Reach verified buyers...          │
│  • Product approval                │
│  • Sales analytics                 │
│  • Seller support                  │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│  [Icon]  Be Part of Cooperative    │
│  Trust & transparency...           │
│  • Member voting                   │
│  • Profit sharing                  │
│  • Cooperative governance          │
└────────────────────────────────────┘

[Get Started Button]
```

**Purpose:**
- Showcase three main value propositions
- Educate users about what's possible
- Build excitement for the platform
- No authentication yet (educational only)

#### Screen 3: Cooperative Values/Features Deep Dive

**Key Messaging:**
- "Why Choose NCDFCOOP?"
- Transparency in pricing
- Direct seller-to-buyer relationships
- No hidden fees
- Cooperative dividend model
- Community-driven governance

**Call-to-Action:**
"Get Started" button that marks onboarding as complete and navigates to authentication

#### Technical Implementation

```dart
// Onboarding flow is tracked with a SharedPreferences flag
// onboarding_completed = true/false

// After "Get Started" is clicked:
await prefs.setBool('onboarding_completed', true);
// User is then navigated to authentication selection
```

#### Navigation Logic
```
[Splash]
    ↓
[Welcome Screen 1]
    ↓ [Next]
[Welcome Screen 2] 
    ↓ [Next]
[Welcome Screen 3]
    ↓ [Get Started]
    
[Mark onboarding_completed = true]
    ↓
[Navigate to Authentication]
```

#### Design Guidance (for Website)
- Use same color scheme: Deep green (#1A472A primary), gold/amber accents
- Keep text clear and scannable (bullet points, short paragraphs)
- Use illustrations to break up text and build emotional connection
- Consider 3-5 second animations between screens for mobile
- On website: longer form content is acceptable (users scroll), mobile: card-based stacking

---

### Phase 3: AUTHENTICATION SYSTEM

**Purpose:** Verify user identity and create/retrieve account  
**Two Flows:** Sign In (existing users) + Sign Up (new users)  
**Methods Supported:** Email/Password, Google Sign-In, Facebook, Apple Sign-In

#### 3.1 AUTHENTICATION SELECTION SCREEN

**Display Logic:**
```
User arrives at /signin route
    ↓
Show authentication method options:
  1. Email & Password
  2. Google Sign-In
  3. Facebook
  4. Apple Sign-In
    ↓
User selects method
```

**UI Layout:**
```
┌──────────────────────────────────────┐
│  Sign In to Your Account             │
│                                      │
│  [ Email & Password Button ]         │
│  [ Google Sign-In Button ]           │
│  [ Facebook Sign-In Button ]         │
│  [ Apple Sign-In Button ]            │
│                                      │
│  ─────────────────────────────       │
│                                      │
│  Don't have an account? Sign Up →    │
└──────────────────────────────────────┘
```

#### 3.2A SIGN UP FLOW (New Users)

**Screen 1: Create Account**

```
Input Fields:
┌──────────────────────────────────────┐
│  Full Name:                          │
│  [________________]                  │
│                                      │
│  Email Address:                      │
│  [________________]                  │
│                                      │
│  Password (min 8 chars):             │
│  [________________]    [👁 Show]    │
│                                      │
│  Confirm Password:                   │
│  [________________]    [👁 Show]    │
│                                      │
│  [ ] I agree to Terms & Conditions  │
│  [ ] I want to receive updates      │
│                                      │
│  [Sign Up] [Cancel]                 │
└──────────────────────────────────────┘
```

**Validation Rules:**
- Email: Valid format, not already registered
- Password: Minimum 8 characters, complexity recommendations
- Name: Non-empty, reasonable length
- Terms: Must be accepted to proceed

**API Call:**
```
POST /api/auth/signup
Body: {
  name: string,
  email: string,
  password: string
}

Response: {
  token: string,
  refreshToken: string,
  user: {
    id: string,
    email: string,
    name: string,
    roles: [] (empty array initially)
  }
}
```

**Backend Processing:**
1. Validate input data
2. Check if email already exists
3. Hash password (bcrypt or similar)
4. Create user record in database
5. Generate JWT tokens (access + refresh)
6. Return user object WITH EMPTY ROLES ARRAY

**Critical Point:** User is created with NO ROLES initially. Roles are assigned after role selection screen.

#### 3.2B SIGN IN FLOW (Existing Users)

**Screen: Login Form**

```
┌──────────────────────────────────────┐
│  Sign In to Your Account             │
│                                      │
│  Email Address:                      │
│  [________________]                  │
│                                      │
│  Password:                           │
│  [________________]    [👁 Show]    │
│                                      │
│  [ ] Remember me                    │
│                                      │
│  [Sign In] [Cancel]                 │
│                                      │
│  Forgot Password? → [Link]           │
└──────────────────────────────────────┘
```

**API Call:**
```
POST /api/auth/login
Body: {
  email: string,
  password: string
}

Response: {
  token: string,
  refreshToken: string,
  user: {
    id: string,
    email: string,
    name: string,
    roles: [array of existing roles],
    selectedRole: string (primary role),
    roleSelectionComplete: boolean
  }
}
```

**Post-Login Logic:**
1. Validate credentials
2. Check if password correct
3. Generate JWT tokens
4. Return user WITH existing roles
5. **Decision Point:**
   - If `roleSelectionComplete = false`: Navigate to Role Selection Screen
   - If `roleSelectionComplete = true`: Navigate to Home Screen

#### 3.3 PASSWORD RECOVERY

**Flow: Forgot Password**
```
[User clicks "Forgot Password"]
    ↓
[Enter Email Screen]
    ↓
[Validation: Account exists?]
    ├─ Yes: Send password reset email
    └─ No: Show error
    ↓
[Check Email Screen]
    - User receives email with reset link
    - Email contains time-limited token (usually 24 hours)
    ↓
[User clicks link in email]
    ↓
[Create New Password Screen]
    - Input: New password + confirmation
    - Validate password strength
    - Submit to backend
    ↓
[Success: Redirect to Sign In]
```

#### 3.4 SOCIAL AUTHENTICATION

**Google Sign-In Flow:**
```
[User taps "Google Sign-In"]
    ↓
[System opens Google OAuth consent]
    ↓
[User selects Google account]
    ↓
[Google returns: email, name, profile picture]
    ↓
[Backend checks if user exists]
    ├─ Exists: Retrieve user + roles
    └─ Doesn't exist: Create new user (no roles yet)
    ↓
[Same post-auth logic as email/password]
```

**Facebook / Apple similar patterns**

#### 3.5 TOKEN MANAGEMENT

**Token Storage:**
```
Access Token (Short-lived: 15 minutes)
├─ Stored in memory (valid for current session)
├─ Included in API headers: Authorization: Bearer {token}
└─ Automatically refreshed when <5% time remains

Refresh Token (Long-lived: 7-30 days)
├─ Stored in FlutterSecureStorage (encrypted on device)
├─ Used to obtain new access tokens
└─ Sent server-side to revoke on logout
```

**Auto-Login on App Restart:**
```
[App starts]
    ↓
[Check FlutterSecureStorage for refresh token]
    ├─ Found: Use refresh token to get new access token
    │        Restore user data
    │        Skip authentication
    ├─ Not found: Proceed to Sign In
    └─ Invalid: Clear storage, proceed to Sign In
    ↓
[User state restored or authentication required]
```

#### 3.6 ERROR SCENARIOS

| Scenario | UI Response |
|----------|------------|
| Invalid email format | "Please enter a valid email address" |
| Email already exists | "Email is already registered. Try signing in." |
| Weak password | "Password must be at least 8 characters with numbers and symbols" |
| Account not found | "No account found with this email" |
| Wrong password | "Incorrect password. Try again or reset your password." |
| Network error | "Connection failed. Check your internet and try again." |
| Server error | "Something went wrong. Please try again later." |

---

### Phase 4: ROLE SELECTION (Critical UX Moment)

**Purpose:** Determine user's primary experience path  
**Timing:** Immediately after signup OR first login after signup  
**Importance:** This single decision affects:
- Navigation menus
- Available features
- Pricing tiers
- Dashboard layout
- Feature access

#### 4.1 ROLE SELECTION SCREEN DESIGN

**Visual Layout:**
```
┌─────────────────────────────────────────┐
│  Choose Your Primary Role               │
│  ───────────────────────────────────── │
│  What's your main purpose on NCDFCOOP? │
│                                         │
│ ┌───────────────────────────────────┐ │
│ │  👤 MEMBER                        │ │
│ │  Shop and save with benefits      │ │
│ │                                   │ │
│ │  Become a member and enjoy        │ │
│ │  exclusive benefits. Upgrade to   │ │
│ │  Premium Member for more rewards. │ │
│ │                                   │ │
│ │  ✓ Member pricing          │ ◯ │ │
│ │  ✓ Add money to account          │   │
│ │  ✓ Save money on platform         │   │
│ │  ✓ Upgrade to Premium             │   │
│ │  ✓ Loyalty rewards                │   │
│ │  ✓ Priority support              │   │
│ └───────────────────────────────────┘ │
│                                         │
│ ┌───────────────────────────────────┐ │
│ │  🛒 WHOLESALE BUYER               │ │
│ │  Buy in bulk with wholesale price │ │
│ │                                   │ │
│ │  For businesses, resellers, and   │ │
│ │  bulk buyers. Get wholesale       │ │
│ │  pricing and dedicated support.   │ │
│ │                                   │ │
│ │  ✓ Bulk pricing              │ ◯ │ │
│ │  ✓ Add money to account          │   │
│ │  ✓ Multiple delivery locations    │   │
│ │  ✓ Flexible payment terms         │   │
│ │  ✓ Account manager               │   │
│ │  ✓ Invoice billing available     │   │
│ └───────────────────────────────────┘ │
│                                         │
│ ┌───────────────────────────────────┐ │
│ │  🚀 START SELLING NOW             │ │
│ │  Sell & reach customers here      │ │
│ │                                   │ │
│ │  Start your selling journey. List │ │
│ │  products, manage inventory, and  │ │
│ │  sell to our members and buyers.  │ │
│ │                                   │ │
│ │  ✓ Sell to Members            │ ◯ │ │
│ │  ✓ Sell to Wholesale Buyers      │   │
│ │  ✓ Inventory management          │   │
│ │  ✓ Sales analytics               │   │
│ │  ✓ Marketing tools               │   │
│ │  ✓ Seller support                │   │
│ └───────────────────────────────────┘ │
│                                         │
│  [Continue →] [Skip for Now]           │
└─────────────────────────────────────────┘
```

#### 4.2 ROLE DESCRIPTIONS & COLORS

| Role | Color Code | Display Name | Primary Features |
|------|-----------|--------------|------------------|
| **Member** | #C9A227 (Gold) | Member | Personal shopping, member discounts, loyalty rewards, account wallet |
| **Wholesale Buyer** | #2E5090 (Dark Blue) | Wholesale Buyer | Bulk pricing, commercial orders, delivery locations, account management |
| **Seller** | #0B6B3A (Deep Green) | Start Selling Now | List products, manage inventory, seller dashboard, order fulfillment |

#### 4.3 ROLE SELECTION LOGIC & UX FLOWS

**User Selection Process:**

```
[Role Selection Screen displayed]
    ↓
[User taps on a role card]
    ├─ Visual feedback: Card is highlighted
    └─ Radio button selected
    ↓
[User taps "Continue" button]
    ├─ Loading indicator shown
    ├─ API call: POST /api/users/{userId}/roles
    │    Body: { selectedRole: "coopMember" }
    │
    ├─ Backend: Add role to user.roles array
    ├─ Backend: Set roleSelectionComplete = true
    ├─ Backend: Save settings to database
    │
    └─ Response: Updated user object
        {
          id: "user123",
          roles: ["coopMember"],
          selectedRole: "coopMember",
          roleSelectionComplete: true
        }
    ↓
[Frontend: Update currentUserProvider (Riverpod state)]
[Frontend: Update currentRoleProvider]
    ↓
[Navigate to Home Screen]
```

**Skip Option:**

"Skip for Now" button allows users to defer role selection. However:
- Default role applied: `coopMember` (Member)
- User can still navigate but with limited features
- Role selection reminder shown periodically
- Can be changed anytime from Settings

#### 4.4 ROLE-SPECIFIC FLOWS AFTER SELECTION

**If Role = Member:**
```
[Role selected]
    ↓
[Navigate to /home → MemberHomeScreen]
    ├─ Dashboard: Shopping shortcuts
    ├─ Browse products (all categories)
    ├─ Member-exclusive deals
    ├─ Loyalty points dashboard
    ├─ Account wallet balance
    ├─ Upgrade to Premium option
    └─ Standard navigation: Home, Offers, Cart, Account
```

**If Role = Wholesale Buyer:**
```
[Role selected]
    ↓
[Navigate to /home → InstitutionalBuyerHomeScreen]
    ├─ Dashboard: Bulk order shortcuts
    ├─ Browse by category (bulk quantities)
    ├─ B2B pricing comparison
    ├─ Account management (payment terms)
    ├─ Multiple shipping addresses
    ├─ Order history (business focus)
    └─ Navigation: Home, Offers, Cart, Account
```

**If Role = Seller:**
```
[Role selected]
    ↓
[Redirect to Seller Onboarding Flow]
[Screen 1] Seller onboarding landing
    ↓ [Next]
[Screen 2] Seller setup (business details)
    ↓ [Next]
[Screen 3] Product upload (first product)
    ↓ [Submit]
[Screen 4] Product status (approval pending)
    ├─ Show: "Your product will be reviewed"
    ├─ Educational: "Why approval matters"
    ├─ Options: Edit & Resubmit, Add Product, Go to Dashboard
    └─ [Continue]
    ↓
[Screen 5] Seller Dashboard
    ├─ Store name header
    ├─ Product stats (total, pending, approved)
    ├─ Product list with status badges
    ├─ Add new product CTA
    └─ This becomes their home screen
```

#### 4.5 MULTI-ROLE USERS

**Technical Capability:**
- Backend supports multiple roles per user
- Example: User can be both Member AND Seller
- User has `roles: ["coopMember", "seller"]`

**Current UI Limitation:**
- Mobile shows only `selectedRole` (primary role)
- Can switch roles from Settings/Profile

**For Website Implementation:**
- Consider role switcher UI element
- Show "Switch to Seller View" / "Switch to Member View"
- Add role-aware breadcrumbs or tabs
- Example:
  ```
  [Home] > [Seller Dashboard v]
          └─ Switch to Member View
             or
             Switch to Wholesale View
  ```

---

## PART 5: HOME SCREENS & ROLE-AWARE EXPERIENCES

### 5.1 ROLE ROUTING ARCHITECTURE

After role selection, user is routed to appropriate home screen:

```
RoleAwareHomeScreen
├─ wholesaleBuyer
│  └─ ConsumerHomeScreen
├─ coopMember
│  └─ MemberHomeScreen (enhanced with member-only features)
├─ premiumMember
│  └─ MemberHomeScreen (with premium badge)
├─ seller
│  └─ SellerDashboardScreen
├─ franchiseOwner
│  └─ FranchiseOwnerHomeScreenV2
├─ storeManager
│  └─ FranchiseOwnerHomeScreenV2 (same as franchiseOwner)
├─ storeStaff
│  └─ WarehouseStaffHomeScreen
├─ institutionalBuyer
│  └─ InstitutionalBuyerHomeScreenV2
├─ institutionalApprover
│  └─ InstitutionalBuyerHomeScreenV2 (with approval workflows)
├─ warehouseStaff
│  └─ WarehouseStaffHomeScreen
├─ deliveryDriver
│  └─ WarehouseStaffHomeScreen (logistics view)
├─ admin
│  └─ AdminHomeScreenV2
└─ superAdmin
   └─ AdminHomeScreenV2 (full control)
```

### 5.2 MEMBER HOME SCREEN

**Primary Navigation:**
```
┌──────────────────────────────────────┐
│ [Header: Welcome, {UserName}!]       │
├──────────────────────────────────────┤
│                                      │
│ [Quick Stats Row]                    │
│ ┌──────────┬──────────┬────────────┐ │
│ │ Points:  │ Savings: │ Member     │ │
│ │ 1,250    │ ₦2,500   │ Since Jan  │ │
│ └──────────┴──────────┴────────────┘ │
│                                      │
│ [Motivational Banner]                │
│ "Upgrade to Premium for 10% discount" │
│ [Upgrade Button]                     │
│                                      │
│ [Featured Products Grid]             │
│ ┌──────────┐ ┌──────────┐            │
│ │ Product  │ │ Product  │            │
│ │ Image    │ │ Image    │            │
│ │ ₦500     │ │ ₦750     │            │
│ └──────────┘ └──────────┘            │
│                                      │
│ [Member-Only Deals Banner]           │
│ Exclusive discounts for members      │
│                                      │
│ [Bottom Navigation Bar]              │
│ [Home] [Offers] [Cart] [Account]    │
└──────────────────────────────────────┘
```

**Key Features Unique to Members:**
- Loyalty points tracking
- Member-only deals carousel
- Upgrade to Premium CTA
- Savings calculator
- Exclusive member benefits showcase
- Access to voting/governance features

### 5.3 WHOLESALE BUYER HOME SCREEN

**Primary Navigation:**
```
┌──────────────────────────────────────┐
│ [Header: Business Dashboard]         │
├──────────────────────────────────────┤
│                                      │
│ [Account Info Summary]               │
│ ┌──────────────────────────────────┐ │
│ │ B2B Account Status: Active       │ │
│ │ Credit Limit: ₦100,000           │ │
│ │ Used: ₦45,200                    │ │
│ │ Available: ₦54,800               │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [Quick Order Shortcuts]              │
│ [Recent Orders] [Bulk Pricing]       │
│ [Delivery Addresses] [Invoices]      │
│                                      │
│ [Bulk Category Browse]               │
│ ┌──────────┐ ┌──────────┐            │
│ │ Bulk bag │ │ Case qty │            │
│ │ pricing  │ │ pricing  │            │
│ └──────────┘ └──────────┘            │
│                                      │
│ [Bottom Navigation Bar]              │
│ [Home] [Catalog] [Orders] [Account] │
└──────────────────────────────────────┘
```

**Key Features Unique to Wholesale Buyers:**
- Credit/payment terms display
- Bulk pricing prominent
- Reorder from history
- Multiple delivery addresses
- Invoice download
- Payment terms/conditions
- Account manager contact

### 5.4 SELLER DASHBOARD SCREEN

**Primary Navigation:**
```
┌──────────────────────────────────────┐
│ [Header: My Store - {BusinessName}]  │
├──────────────────────────────────────┤
│                                      │
│ [Store Stats Overview]               │
│ ┌──────────┬──────────┬──────────┐   │
│ │ Products │ Pending  │ Approved │   │
│ │ 12       │ 2        │ 10       │   │
│ └──────────┴──────────┴──────────┘   │
│                                      │
│ [Filter Tabs]                        │
│ [All] [Pending] [Approved] [Rejected]│
│                                      │
│ [Product List]                       │
│ ┌──────────────────────────────────┐ │
│ │ Product Name    ₦500  🟡 Pending │ │
│ │ Last updated: 2 days ago        │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ Product Name    ₦750  🟢 Approved│ │
│ │ Last updated: Today             │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [+ Add New Product Button]           │
│                                      │
│ [Bottom Navigation Bar]              │
│ [Dashboard] [Products] [Orders] [...]│
└──────────────────────────────────────┘
```

**Key Features Unique to Sellers:**
- Product approval status tracking (🟡 Pending, 🟢 Approved, 🔴 Rejected)
- Sales analytics
- Order fulfillment queue
- Inventory management
- Product edit/resubmit for rejected items
- Target customer view (B2C vs B2B)

---

## PART 6: AUTHENTICATION & STATE MANAGEMENT ARCHITECTURE

### 6.1 STATE MANAGEMENT PATTERN (Riverpod)

```
Authentication State Flow:
└─ authStateProvider (Firebase AuthStateChanged stream)
   ├─ Listens to Firebase authentication changes
   └─ Emits: AuthState { user | null }

User State:
└─ currentUserProvider (NotifierProvider<UserNotifier, User?>)
   ├─ Synchronous user object
   ├─ Methods: setUser(), clearUser()
   └─ Updated by: Auth controller notifications

Role State:
┌─ currentRoleProvider
│  ├─ Derives from: currentUserProvider + selectedRole
│  └─ Returns: UserRole (primary role)
│
├─ currentContextProvider
│  ├─ Derives from: currentUserProvider + currentRoleProvider
│  └─ Returns: UserContext? (role-specific context)
│
└─ currentPermissionsProvider
   ├─ Derives from: currentUserProvider + currentRoleProvider
   └─ Returns: Set<Permission> (available permissions)

Permission Checks:
└─ hasPermissionProvider(permission)
   ├─ Query: Does user have specific permission?
   └─ Returns: bool
```

### 6.2 USER PERSISTENCE FLOW

```
[App Starts]
└─ initializePersistedUserProvider FutureProvider runs
   ├─ [1] Check FlutterSecureStorage for refreshToken
   │       ├─ Not found: User is not authenticated
   │       └─ Found: Continue to step 2
   │
   ├─ [2] Use refreshToken to obtain new accessToken
   │       ├─ Failed: Token expired, clear storage
   │       └─ Success: Continue to step 3
   │
   ├─ [3] Fetch full user object from API
   │       GET /api/auth/me
   │       Response: User { id, email, name, roles, selectedRole, ... }
   │
   ├─ [4] Save to FlutterSecureStorage (encrypted)
   │
   ├─ [5] Update currentUserProvider with user object
   │
   └─ [6] User is now authenticated & ready
```

### 6.3 NAVIGATION GUARDS (GoRouter)

```
Navigation Request
    ↓
[Check route protection]
    ├─ Public routes (splash, signin, signup, onboarding)
    │  └─ Allow access
    │
    └─ Protected routes (all others)
       ├─ [1] Is user authenticated?
       │       ├─ No: Redirect to /splash
       │       └─ Yes: Continue to step 2
       │
       ├─ [2] Has user completed role selection?
       │       ├─ No: Redirect to /role-selection
       │       └─ Yes: Continue to step 3
       │
       └─ [3] Does user have required role?
               ├─ No: Show "Access Denied" or redirect
               └─ Yes: Allow access
```

**Role Requirements Map:**
```dart
const Map<String, Set<UserRole>> _routeRoleRequirements = {
  '/franchise': {
    UserRole.franchiseOwner,
    UserRole.storeManager,
    UserRole.storeStaff,
  },
  '/institutional': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },
  '/admin': {
    UserRole.admin,
    UserRole.superAdmin,
  },
  // ... other role-specific routes
};
```

---

## PART 7: USER MODEL & DATA STRUCTURE

### 7.1 USER OBJECT (Firebase/Backend)

```dart
class User {
  final String id;                    // Unique user ID
  final String email;                 // Email address
  final String name;                  // Display name
  final String? profileImage;         // Profile photo
  final List<UserRole> roles;         // All roles [can be multiple]
  final UserRole selectedRole;        // Primary role for UI
  final bool roleSelectionComplete;   // Has user selected a role?
  final UserContext? context;         // Role-specific data
  final Set<Permission> permissions;  // For current role
  final UserMembership membership;    // Membership tier
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}

// Enum: All possible roles
enum UserRole {
  wholesaleBuyer,      // Default buyer role
  coopMember,          // Member with benefits
  premiumMember,       // Upgraded member (10% discount)
  seller,              // Marketplace seller
  franchiseOwner,      // Franchise manager
  storeManager,        // Store operations
  storeStaff,          // Sales/service
  institutionalBuyer,  // B2B bulk buyer
  institutionalApprover, // Approval authority
  warehouseStaff,      // Logistics
  deliveryDriver,      // Last mile
  admin,               // Platform admin
  superAdmin,          // Full system access
}

// Enum: User membership tiers
enum UserMembership {
  free,        // No membership (wholesaleBuyer)
  basic,       // Member (coopMember)
  gold,        // ₦5,000/year - 15% discount
  platinum,    // ₦15,000/year - 20% discount
}
```

### 7.2 ROLE-SPECIFIC CONTEXT

```dart
class UserContext {
  final String userId;
  final UserRole role;
  
  // For sellers
  final SellerProfile? sellerProfile;
  final List<SellerProduct>? products;
  
  // For wholesale buyers
  final B2BAccount? b2bAccount;
  final List<DeliveryAddress>? deliveryAddresses;
  
  // For members
  final MembershipTier? membershipTier;
  final int loyaltyPoints;
  final double accountBalance;  // Wallet balance
  
  // For franchise owners
  final FranchiseProfile? franchiseProfile;
  final List<Store>? stores;
  
  // For admins
  final AdminDashboard? adminData;
}
```

### 7.3 PERMISSIONS SYSTEM

```dart
enum Permission {
  // Buyer permissions
  viewProducts,
  addToCart,
  checkout,
  viewOrderHistory,
  addMoneyToAccount,        // Members & institutional
  saveMoneyOnPlatform,      // Members only
  
  // Seller permissions
  listProducts,
  editProducts,
  viewSalesAnalytics,
  fulfillOrders,
  viewSellerStats,
  
  // Admin permissions
  viewAllUsers,
  modifyUserRoles,
  approveProducts,
  viewAuditLogs,
  modifyPrices,
  accessControlPanel,
  
  // Approval permissions
  approveOrders,
  rejectOrders,
}
```

---

## PART 8: COMPLETE USER JOURNEY DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP STARTUP                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
        ┌────────────────────────────────────┐
        │    SPLASH SCREEN (2 seconds)      │
        │    - Show CoopCommerce branding    │
        │    - Initialize backend            │
        │    - Check for persisted user      │
        └────────────┬───────────────────────┘
                     │
        ┌────────────┴──────────────────────┐
        │                                    │
        ↓                                    ↓
    [Persisted           [No persisted
     user found]         user found]
        │                                    │
        │           ┌───────────────────────┘
        │           │
        │           ↓
        │ ┌─────────────────────────────────┐
        │ │  WELCOME SCREENS (3 screens)   │
        │ │  - Educate about platform      │
        │ │  - Show benefits               │
        │ │  - [Get Started] button        │
        │ └────────────┬────────────────────┘
        │              │
        │              ↓
        │ ┌─────────────────────────────────┐
        │ │  AUTHENTICATION SELECTION       │
        │ │  ├─ Sign In                     │
        │ │  └─ Sign Up                     │
        │ └────────────┬────────────────────┘
        │              │
        │              ↓
        │ ┌─────────────────────────────────┐
        │ │  USER AUTHENTICATION            │
        │ │  POST /api/auth/signin/signup   │
        │ │  Returns: JWT tokens + user     │
        │ │  Stores: JWT in encrypted       │
        │ │          storage                 │
        │ │  Updates: currentUserProvider   │
        │ └────────────┬────────────────────┘
        │              │
        └──────────────┼──────────────────────┐
                       │                       │
       ┌───────────────┴─────────┐             │
       │                         │             │
       ↓                         ↓             ↓
   [First Login]         [Returning User]  [Sign Up]
   [No Roles]            [Has Roles]       [No Roles]
       │                         │             │
       └────────────┬────────────┴─────┬───────┘
                    │                  │
           ┌────────┴──────────────────┴───────┐
           │                                   │
           ↓ (if roleSelectionComplete=false) ↓ (if true)
      ┌────────────────────┐      ┌────────────────────┐
      │  ROLE SELECTION      │      │  DIRECT TO HOME    │
      │  CRITICAL POINT!     │      │  (roles exist)     │
      │                      │      └──────┬─────────────┘
      │  Choose one:         │             │
      │  - Member            │             │
      │  - Wholesale Buyer   │             │
      │  - Start Selling     │             │
      │                      │             │
      │  POST /api/users/    │             │
      │  {userId}/roles      │             │
      │                      │             │
      │  Updates:            │             │
      │  - user.roles array  │             │
      │  - role-             │             │
      │    SelectionComplete │             │
      │  - currentRoleProvider│             │
      └──────────┬───────────┘             │
                     │                      │
                     └──────────┬───────────┘
                                │
                                ↓
                ┌───────────────────────────────────┐
                │  ROLE-AWARE HOME SCREEN           │
                │  Router switches based on role:   │
                │                                   │
                │  Member              → Member     │
                │  → MemberHomeScreen               │
                │                                   │
                │  Wholesale Buyer                  │
                │  → Institutional buyer screen     │
                │                                   │
                │  Seller → Seller Onboarding      │
                │  (5-step flow)                    │
                │  → SellerDashboard                │
                │                                   │
                │  Franchise/Admin                  │
                │  → Role-specific dashboards       │
                └───────────────────────────────────┘
```

---

## PART 9: SELLER ONBOARDING (5-STEP FLOW)

When a user selects "Seller" role, they enter a specialized 5-screen onboarding:

### Screen 1: Seller Landing
**Content:** Value proposition, benefits, call-to-action
**User Action:** Read and click "Start Selling"

### Screen 2: Seller Setup
**Inputs:**
- Business Name (text)
- Seller Type (dropdown: Individual, Business, Cooperative)
- Country/Location (text/select)
- Product Category (dropdown)
- Target Customer (radio: Individual Customers vs Bulk Buyers)

**Validation:** All fields required
**User Action:** Click "Next"

### Screen 3: Product Upload
**Inputs:**
- Product Name
- Category
- Price
- Quantity
- Minimum Order Quantity (MOQ)
- Description
- Product Image

**Critical UX Element:**
Yellow banner: "Your product will be reviewed before it goes live"
Checkbox: "I understand my products will be reviewed"

**User Action:** Click "Submit Product"

### Screen 4: Product Status
**Display:**
- Product status badge (🟡 Pending, 🟢 Approved, 🔴 Rejected)
- Status message
- Educational section: "Why Approval Matters"
  - Quality assurance
  - Buyer trust
  - Fraud prevention
  - Export compliance

**Options:**
- Edit & Resubmit (if rejected)
- Add Another Product
- Go to Dashboard

**User Action:** Click option

### Screen 5: Seller Dashboard
**Display:**
- Store name header
- Overview statistics:
  - Total products
  - Pending count
  - Approved count
- Filter tabs (All, Pending, Approved)
- Product list

**Ongoing:** This becomes their home screen when logged in as Seller

---

## PART 10: KEY DESIGN PRINCIPLES FOR WEBSITE IMPLEMENTATION

### 10.1 VISUAL DESIGN SYSTEM

**Color Palette:**
```
Primary Green: #1A472A (Dark cooperative green)
Secondary Green: #0B6B3A (Deep green for sellers)
Accent Gold: #C9A227 (Member tier)
Accent Blue: #2E5090 (Wholesale buyer)
Success Green: #22C55E (Approved/Active)
Warning Amber: #F59E0B (Pending/Review)
Error Red: #EF4444 (Rejected/Failed)
Gray: #6B7280 (Neutral text)
```

**Typography:**
- Headings: Bold, 18-32pt
- Body: Regular, 14-16pt
- Captions: 12pt
- CTA Buttons: Semi-bold, 14pt

**Card Design:**
- Border radius: 8-12px
- Shadow: Subtle (0 2px 4px rgba)
- Spacing: 16-24px padding
- Hover state: 2px lift, shadow increase

### 10.2 INTERACTION PATTERNS

**Button States:**
- Default: Blue/green background, white text
- Hover: Slightly darker shade, cursor pointer
- Disabled: 50% opacity, cursor not-allowed
- Loading: Show spinner inside button

**Form Interactions:**
- Input focus: Blue border, shadow
- Input error: Red border, error text below
- Validation real-time: Show checkmark on valid field
- Auto-save for multi-step forms

**Modals/Overlays:**
- Dark background overlay (60% opacity)
- Modal appears with scale animation
- Close button (X) in top-right
- Click-outside closes
- Escape key closes

### 10.3 RESPONSIVE DESIGN

**Breakpoints:**
- Mobile: 320px - 639px
- Tablet: 640px - 1023px
- Desktop: 1024px+

**Adaptations:**
- Mobile: Single column, card stacking
- Tablet: 2-column layouts
- Desktop: 3+ column grids
- Navigation: Hamburger menu (mobile), horizontal nav (desktop)

### 10.4 PERFORMANCE CONSIDERATIONS

**For Web:**
- Lazy load role-specific components
- Show loading skeleton while fetching user data
- Cache user role for faster route transitions
- Prefetch common routes (home, cart, account)
- Optimize images: WebP format with fallback

---

## PART 11: TECHNICAL IMPLEMENTATION CHECKLIST FOR WEBSITE

### Authentication System
- [ ] Implement OAuth 2.0 with JWT tokens
- [ ] Secure token storage (httpOnly cookies recommended)
- [ ] Implement refresh token rotation
- [ ] Handle token expiration gracefully
- [ ] Add CSRF protection
- [ ] Implement rate limiting on auth endpoints
- [ ] Add email verification step
- [ ] Add 2FA option

### Role System
- [ ] Implement role-based route guards
- [ ] Cache role permissions in session/local storage
- [ ] Implement permission checks in components
- [ ] Add role switcher UI (if multi-role supported)
- [ ] Show role indicator in header

### User Experience
- [ ] Add loading states for all async operations
- [ ] Implement navigation progress indicators
- [ ] Add error boundaries
- [ ] Show network status indicator
- [ ] Implement session timeout warning
- [ ] Add breadcrumb navigation

### State Management
- [ ] Track auth state
- [ ] Persist user object (cleared on logout)
- [ ] Implement undo/redo for form submissions
- [ ] Cache API responses appropriately

### Seller Onboarding
- [ ] Implement multi-step form with progress indicator
- [ ] Auto-save form data to prevent loss
- [ ] Image upload with preview
- [ ] Product approval status tracking
- [ ] Email notifications for approval/rejection

### Analytics & Monitoring
- [ ] Track user journey completion rates
- [ ] Monitor authentication failures
- [ ] Track role selection distribution
- [ ] Monitor seller onboarding dropout points
- [ ] Track session duration by role

---

## PART 12: COMMON UX FLOWS & EDGE CASES

### 12.1 FORGOTTEN PASSWORD FLOW
```
User clicks "Forgot Password"
↓
Enters email address
↓
[Backend validation]
  ├─ Email not found: Show "No account with this email"
  └─ Email found: Send reset email
↓
User checks email (usually 5-10 minutes)
↓
User clicks link in email
↓
System validates token (24-hour expiry)
  ├─ Expired: Show "Link expired, request new one"
  └─ Valid: Allow password reset
↓
User enters new password + confirmation
↓
[Validation]
  ├─ Passwords don't match: Show error
  ├─ Weak password: Show requirements
  └─ Valid: Reset password
↓
Success message
↓
Redirect to Sign In
```

### 12.2 SESSION TIMEOUT
```
User is inactive for 30 minutes
↓
[Show warning modal]
"Your session is expiring in 5 minutes"
Options: [Continue Session] [Log Out]
↓
User clicks "Continue Session"
  ├─ Backend validates refresh token
  ├─ Issues new access token
  └─ Session extends another 30 minutes
↓
If user doesn't click anything:
  After 5 minutes, automatically log out
  ├─ Clear auth tokens
  ├─ Clear user data
  └─ Redirect to login with message:
      "Session expired. Please log in again."
```

### 12.3 ROLE CHANGE MID-SESSION
```
User logged in as Member
↓
User navigates to Settings > Account
↓
Clicks "Switch Role" or "Change Primary Role"
↓
Shows role selection screen again
↓
User selects different role
↓
POST /api/users/{userId}/roles
  └─ Body: { selectedRole: "seller" }
↓
Backend updates user.selectedRole
↓
Frontend updates currentRoleProvider
↓
If new role requires onboarding:
  Redirect to onboarding flow
Else:
  Redirect to new role's home screen
↓
Toast notification: "Role changed successfully"
```

### 12.4 NETWORK DISCONNECTION
```
User is online, browsing products
↓
Network drops
↓
[Attempt API call]
  └─ Network error detected
↓
[Show inline error]
"Unable to connect. Please check your connection."
↓
[Show retry options]
Options: [Retry] [Offline Mode (if available)]
↓
User fixes connection
↓
Clicks [Retry]
↓
API call succeeds
↓
Clear error message
```

---

## PART 13: FOR THE WEBSITE DEVELOPMENT TEAM

### Summary of Key Decisions

1. **Role Selection is Critical**
   - Happens immediately after signup
   - Determines entire user experience
   - Currently 3 main options: Member, Wholesale Buyer, Seller
   - Can be changed later but should encourage initial selection

2. **Seller Path is Special**
   - Leads to 5-step onboarding
   - Products require approval before going live
   - Emphasizes trust and quality
   - Dashboard becomes their primary home

3. **Multi-Role Support Exists**
   - Backend supports user having multiple roles
   - UI currently shows one "primary" role
   - Can be extended to show role switcher

4. **Membership Tiers Affect Pricing**
   - Free (Wholesale Buyer): Regular pricing
   - Basic (Member): 5% discount
   - Premium Member: 10% discount
   - Gold/Platinum: Higher discount tiers

5. **State Management is Critical**
   - Use a global state solution (Redux, Zustand, MobX, Atom API)
   - Keep one source of truth for user/role/permissions
   - Implement proper loading states
   - Handle token refresh transparent to user

6. **Navigation is Role-Aware**
   - Different roles see different menus
   - Some pages inaccessible to certain roles
   - Use route guards to enforce permissions
   - Show "Access Denied" gracefully

### Questions for Your Team

Before you start website implementation:

1. Do you want to support role switching in the UI, or should it be hidden?
2. Will you implement the seller onboarding the same way, or differently?
3. Do you want to support social authentication (Google, Facebook, Apple)?
4. Will you implement the 5-tier member system (free, basic, gold, platinum)?
5. Do you want real-time notifications for product approval status?
6. Will you auto-fill forms from user profile data?
7. Do you want password strength indicator during signup?

### Files to Reference

From the mobile app codebase, these are key for understanding the implementation:

**Authentication:**
- `lib/core/api/auth_service.dart` - Auth API methods
- `lib/providers/auth_provider.dart` - Auth state management
- `lib/features/welcome/auth_provider.dart` - Auth controller logic

**Roles & Permissions:**
- `lib/core/auth/role.dart` - All role definitions
- `lib/core/auth/permission.dart` - Permission definitions
- `lib/core/rbac/rbac_service.dart` - Role-based access control

**Navigation:**
- `lib/config/router.dart` - GoRouter configuration
- Shows route protection logic
- Shows role-specific routing

**Sellers:**
- `lib/core/services/seller_service.dart` - Seller operations
- `lib/core/models/seller_models.dart` - Data structures

---

## CONCLUSION

The NCDF COOP Commerce experience is carefully designed to serve three distinct user types (Members, Buyers, Sellers) while maintaining a unified, cooperative-focused brand identity. 

The website implementation should:

1. **Mirror the mobile UX flow** - Keep the journey consistent
2. **Adapt for web interactions** - Longer forms acceptable, faster page loads expected
3. **Emphasize role selection** - This is the key differentiator
4. **Support seller onboarding** - The 5-step flow is a critical feature
5. **Implement proper security** - Token handling, CSRF, rate limiting
6. **Show loading states** - Users expect faster web experience
7. **Maintain cooperative branding** - Colors, messaging, values consistent

This analysis should give your website team a complete picture of:
- What the mobile app does
- How users experience it
- What decisions they make
- How the system responds
- What they should implement

Good luck with the website version!

---

**Document Prepared By:** AI Development Copilot  
**Last Updated:** April 5, 2026  
**Version:** 1.0 - Comprehensive Analysis
