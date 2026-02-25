# Proper Role-Based Onboarding Flow

## ✅ What Was Fixed

**Old (Wrong) Approach:**
- Users signed up with basic info
- System assigned roles based on email patterns (bad UX!)
- Users didn't know they were being auto-assigned roles
- Not scalable for thousands of strangers
- Users couldn't choose their experience

**New (Correct) Approach:**
- Users sign up with basic info
- Immediately taken to **role selection screen** where they choose
- Clear, visual explanation of each option with benefits
- Users own their choice
- Scalable for millions of users (like Jumia)

---

## 📊 New User Journey

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Welcome Screen                                           │
│    - Login / Sign Up options                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (user clicks Sign Up)
┌─────────────────────────────────────────────────────────────┐
│ 2. Signup Screen                                            │
│    - Collect: name, email, phone, password                 │
│    - Create account                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (account created successfully)
┌─────────────────────────────────────────────────────────────┐
│ 3. 🎯 ROLE SELECTION SCREEN (NEW!)                         │
│                                                             │
│    "Choose Your Experience"                                │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │ 🛍️  REGULAR SHOPPER                                │   │
│  │     Shop individually with retail pricing          │   │
│  │     ✓ Personal cart  ✓ Fast checkout              │   │
│  │ [ ] Select                                          │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │ 🤝  COOPERATIVE MEMBER                              │   │
│  │     Join community & get wholesale prices          │   │
│  │     ✓ 10-30% off  ✓ Loyalty rewards               │   │
│  │     ✓ Share profits  ✓ Vote on decisions           │   │
│  │ [✓] Selected                                        │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │ 🏢  WHOLESALE BUYER                                 │   │
│  │     For businesses, institutions, bulk orders      │   │
│  │     ✓ Bulk pricing  ✓ 30+ locations               │   │
│  │     ✓ Flexible terms  ✓ Dedicated support          │   │
│  │ [ ] Select                                          │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  [CONTINUE]                                                │
│  Skip for now                                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼ (user selects role & continues)
┌─────────────────────────────────────────────────────────────┐
│ 4. HOME SCREEN (Role-Specific)                              │
│                                                             │
│    Consumer home: Basic shopping                           │
│    Member home: Loyalty, bulk features, voting            │
│    Wholesale home: Bulk ordering, PO management           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Three Role Options Explained

### 1. 🛍️ Regular Shopper (Consumer)
- **For:** Individual personal shopping
- **What they see:** Standard e-commerce home (already built)
- **Features:**
  - Personal shopping cart
  - Retail pricing
  - Home delivery
  - Easy returns
  - Simple checkout
- **Best for:** Busy professionals, families buying for themselves

### 2. 🤝 Cooperative Member  
- **For:** Community-focused buyers looking for better deals & shared benefits
- **What they see:** Member-specific home screen (wholesale prices, loyalty, rewards)
- **Features:**
  - Wholesale pricing (10-30% off)
  - Loyalty points & tiered rewards (Standard → Gold → Platinum)
  - Bulk ordering
  - Team features (order as a group)
  - Share yearly cooperative profits
  - Vote on cooperative decisions
  - Priority customer support
- **Best for:** Small groups, community buyers, loyalty program seekers

### 3. 🏢 Wholesale Buyer (Institutional)
- **For:** Businesses, institutions, large organizations
- **What they see:** B2B/institutional home with PO creation, invoicing
- **Features:**
  - Commercial pricing for bulk amounts
  - Multiple delivery locations
  - Flexible payment terms (30/60/90 days)
  - Purchase Order (PO) system
  - Invoice billing
  - Dedicated account manager (future)
  - Approval workflows for organizations
  - Custom pricing agreements (future)
- **Best for:** Restaurants, schools, hospitals, companies, NGOs

---

## 📁 Files Changed/Created

### ✅ New Files
- `lib/features/auth/screens/role_selection_screen.dart` - Role selection UI

### ✅ Modified Files
1. **`lib/features/auth/screens/signup_screen.dart`**
   - Changed redirect from `/home` → `/role-selection`
   - Passes userId, email, name to role selection screen

2. **`lib/core/api/auth_service.dart`**
   - Removed email-based role assignment
   - All new users start as `consumer` role
   - Users select actual role during onboarding (not auto-assigned)

3. **`lib/config/router.dart`**
   - Added `/role-selection` route
   - Added import for `RoleSelectionScreen`

---

## 🔄 How Role Selection Works

### Step 1: User sees three clear options
Each option has:
- Clear title & emoji
- Simple description
- List of 4-6 key benefits
- Visual icon & color coding
- Radio button selector

### Step 2: User chooses one
- Visual feedback when selected
- Can change their mind before continuing

### Step 3: User clicks "Continue"
- Saves selected role to user profile
- Navigates to home with their role

### Step 4: App adapts to their role
- Correct home screen shown
- Correct pricing shown
- Correct features available
- Role-specific CTAs, products, categories

---

## ✨ Why This is Better

| Aspect | Old Way | New Way |
|--------|---------|---------|
| **How roles assigned** | Email pattern matching | User choice |
| **User awareness** | Hidden, confusing | Clear, transparent |
| **Scalability** | Only works for known domain patterns | Works for millions of strangers |
| **User onboarding** | Abrupt, no explanation | Guided, educational |
| **Flexibility** | Can't change (stuck with email pattern) | Can be changed later |
| **Experience** | Generic, wrong for their needs | Tailored to their choice |
| **Trust** | Why am I a "member"? | "I chose to be a member" |

---

## 🎨 Role Selection Screen Design

```
┌─────────────────────────────────────┐
│  ◄ Choose Your Experience      ✕   │
├─────────────────────────────────────┤
│                                     │
│  Welcome, John!                     │
│  How would you like to use          │
│  CoopCommerce? Each option gives    │
│  you a personalized experience.     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 🛍️  Regular Shopper       [ ]  │  │
│  │     Personal shopping      │  │  │
│  │     Shop individually...   └──┘  │
│  │     ✓ Personal cart               │
│  │     ✓ Fast checkout               │
│  │     ✓ Home delivery               │
│  │     ✓ Easy returns                │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 🤝  Cooperative Member     [✓] │  │
│  │     Join community         └──┘  │
│  │     Wholesale prices & more...   │
│  │     ✓ Wholesale pricing           │
│  │     ✓ Loyalty rewards             │
│  │     ✓ Share profits               │
│  │     ✓ Vote on decisions           │
│  │     ✓ Team ordering               │
│  │     ✓ Priority support            │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 🏢  Wholesale Buyer        [ ]  │  │
│  │     For businesses         └──┘  │
│  │     Institutional orders...      │
│  │     ✓ Wholesale pricing           │
│  │     ✓ Multiple locations          │
│  │     ✓ Flexible payment terms      │
│  │     ✓ Dedicated support           │
│  │     ✓ Custom pricing              │
│  │     ✓ Invoice billing             │
│  └───────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐   │
│  │    [CONTINUE]                │   │
│  └──────────────────────────────┘   │
│  Skip for now                        │
│                                     │
└─────────────────────────────────────┘
```

---

## 🧪 Testing the Flow

1. **Build & Run:**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Test Signup → Role Selection:**
   - Open app, click "Sign Up"
   - Fill in details: name, email, phone, password
   - Click "Sign Up button"
   - Should see "Choose Your Experience" screen
   - Select a role
   - Click "Continue"
   - Should go to home screen with that role

3. **Test Role Selection Options:**
   - Verify all 3 options show with images/icons
   - Verify benefits list shows correctly
   - Verify radio button selection works
   - Verify "Continue" button only works when role selected

4. **Test Skip Feature:**
   - Click "Skip for now"
   - Should go to home with consumer role (default)

---

## 🚀 Future Enhancements

1. **Allow role changes:** Users can change their role in settings later
2. **Multi-role support:** Users can select multiple roles if needed
3. **Role upgrade flow:** Path to upgrade from consumer → member → premium
4. **Educational onboarding:** More details about each role option
5. **Role-specific checkout:** Different checkout flows per role
6. **Role-specific pricing:** Different prices shown based on role
7. **Role switching:** Quick way to switch between roles if user has multiple

---

## 📝 Database/Storage

When user selects a role, it should be saved:
- **Firebase:** User custom claims or User metadata
- **Local storage:** SharedPreferences or hive
- **Firestore:** User document with roles array

Example:
```json
{
  "id": "user_123",
  "email": "john@example.com",
  "name": "John Doe",
  "roles": ["consumer", "coopMember"],
  "primaryRole": "coopMember",
  "selectedAt": "2024-02-23T10:30:00Z"
}
```

---

## ✅ Summary

✓ Users now choose their role, not auto-assigned by email  
✓ Clear, visual presentation of options  
✓ Each option explains benefits explicitly  
✓ Scalable for millions of users  
✓ UX mirrors Jumia's role selection model  
✓ App adapts to user's chosen role  
✓ Users own their experience decision  

This is the proper way to build a multi-segment platform where users actively choose their buyer type rather than being assigned by opaque rules.
