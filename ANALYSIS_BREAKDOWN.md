# NCDFCOOP Project - What We Have vs What We Need

## 🎯 The Brief Translated

You gave me 9 sections. Here's what each means for development:

### 1. **Project Summary** - The Goal
- **What it says:** One platform, multiple roles, one catalogue
- **What we built:** UI screens + payment system
- **What's missing:** Role enforcement + data filtering

### 2. **Reference Model (Costco)** - The Design Inspiration
- **What it says:** Copy UX, not structure
- **What we did:** ✅ Clean UI, search, product cards, pricing display
- **What's incomplete:** ❌ Multi-pricing by role

### 3. **Product Vision** - It's Not Just E-Commerce
- **What it says:** Digitized cooperative + operating enterprise
- **What we have:** Basic shopping cart
- **What's missing:**
  - Cooperative membership layer
  - Franchise operations
  - Institutional B2B
  - Logistics network

### 4. **User Roles** - Critical Infrastructure
- **What it requires:** 11 distinct roles with RBAC
- **What we have:** `User { id, email, name }`
- **What's missing:**
  ```dart
  // NEEDED:
  User {
    id, email, name,
    roles: List<UserRole>,  // ← MISSING
    permissions: Map<...>,  // ← MISSING
    context: UserContext,   // ← MISSING
  }
  ```

### 5. **Functional System** - End-to-End Workflows

#### A. Identity & Membership
- ✅ Basic auth (email/password, OAuth)
- ❌ Membership tiers not enforced
- ❌ Digital membership card logic
- ❌ Voting/governance features

#### B. Catalogue System
- ✅ Product list, search, filtering
- ❌ Role-based visibility
- ❌ Institution-specific catalogues
- ❌ Wholesale MOQ indicators

#### C. Pricing Engine (CORE)
- ✅ Payment processing works
- ❌ **Retail vs Wholesale pricing not differentiated**
- ❌ Contract pricing not implemented
- ❌ Price ceilings not enforced
- ❌ Approval workflows missing

#### D. Retail Commerce (B2C)
- ✅ Browse/search/cart/checkout (basic)
- ❌ Delivery slots not managed
- ❌ Order tracking minimal
- ⚠️ Payment methods work, but no delivery integration

#### E. Wholesale & Institutional (B2B)
- ❌ 0% implemented
- ❌ No MOQ enforcement
- ❌ No case packs
- ❌ No PO references
- ❌ No approval chains
- ❌ No credit terms

#### F. Franchise Store OS
- ❌ 0% implemented
- ❌ No inventory dashboard
- ❌ No reorder logic
- ❌ No compliance tracking
- ❌ No evidence upload

#### G. Distribution & Logistics
- ❌ 0% implemented
- ❌ No warehouse workflows
- ❌ No route management
- ❌ No driver app
- ❌ No POD capture

#### H. Admin Control Tower
- ❌ Skeleton only (~5% done)
- ❌ No user management
- ❌ No pricing oversight
- ❌ No compliance scoring
- ❌ No audit logs

### 6. **UX Strategy** - Role-Aware Screens
- ❌ **0% done**
- Every user sees same home screen
- Should be: 6 distinct dashboards per role

### 7. **Technical Architecture** - Tech Stack
- ✅ Flutter (mobile) - correctly chosen
- ⏳ Next.js (web) - not started
- ⏳ Node.js/NestJS (backend) - not started
- ⏳ PostgreSQL - not started
- ❌ No backend API deployed
- ❌ Currently using mock data

### 8. **Delivery Strategy** - Milestones
- Currently: Foundation phase
- Should be executing: Retail Commerce → Wholesale → Franchise → Logistics
- Reality: Building UI without backend integration

### 9. **Why This Matters** - Business Value
- You're not selling an app
- You're selling **digital infrastructure**
- Current approach: ❌ Looks like an app
- Needed approach: ✅ Acts like an enterprise system

---

## 📊 DETAILED COMPONENT ANALYSIS

### LAYER 1: Authentication & Authorization

**Current State:**
```dart
class User {
  String id, email, name;
  String? token;
  // Missing: roles, permissions, organization
}
```

**Required State:**
```dart
class User {
  String id, email, name;
  String token;
  List<UserRole> roles;  // [Consumer, CoopMember, FranchiseOwner]
  Map<UserRole, UserContext> contexts;
  Map<UserRole, Set<Permission>> permissions;
}

enum UserRole {
  consumer,
  coopMember,
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

class UserContext {
  String? franchiseId;
  String? storeId;
  String? institutionId;
  String? warehouseId;
}
```

**Impact on API:**
```dart
// CURRENT (INSECURE):
Future<List<Product>> getProducts() {
  return api.get('/products');  // Returns ALL products to EVERYONE
}

// REQUIRED (SECURE):
Future<List<Product>> getProducts() {
  return api.get('/products', params: {
    'userId': currentUser.id,
    'roles': currentUser.roles.map((r) => r.name),
    'context': currentUser.context,
  });
  // API filters based on role and returns only visible products with appropriate pricing
}
```

---

### LAYER 2: Pricing Engine

**Current State:**
```dart
class Product {
  String id, name;
  double price;  // Single price shown to everyone
  String image;
}
```

**Required State:**
```dart
class Product {
  String id, name;
  String image;
  
  // Pricing by role:
  double retailPrice;           // For consumers
  double wholesalePrice;        // For franchises
  double contractPrice;         // For institutions
  int minimumOrderQuantity;     // For wholesale
  
  // Role-specific visibility:
  bool visibleToRetail;
  bool visibleToWholesale;
  bool visibleToInstitutions;
  
  // Dynamic pricing:
  List<PriceRule> priceRules;   // Promotions, ceilings, etc
}

class PriceRule {
  String id;
  List<UserRole> applicableRoles;
  double? discount;
  int? minQuantity;
  DateTime? validFrom, validTo;
}

// When displaying:
double getPrice(User user) {
  if (user.roles.contains(UserRole.franchiseOwner)) {
    return this.wholesalePrice;
  } else if (user.roles.contains(UserRole.institutionalBuyer)) {
    return this.contractPrice;
  } else {
    return this.retailPrice;
  }
}
```

**Impact on Shopping Flow:**
```
Consumer sees:     Price: ₦5,000 | Save 30%
Franchise sees:    Wholesale: ₦3,000 | MOQ: 100 units
Institution sees:  Contract: ₦2,500 (negotiated)
```

---

### LAYER 3: Data Isolation

**Current State:**
```dart
// ProductService returns ALL products
List<Product> products = await productService.getAll();
// Franchise owner sees retail products (wrong!)
// Institution sees consumer-only products (wrong!)
```

**Required State:**
```dart
// ProductService filters by user role + context
List<Product> products = await productService.getByRole(
  user: currentUser,
  context: currentUser.getContext(selectedRole),
);

// Franchise owner:
// ├─ Sees wholesale products
// ├─ With wholesale pricing
// ├─ With MOQ requirements
// └─ In their store context

// Institution:
// ├─ Sees institutional products
// ├─ With contract pricing
// ├─ In their account context
// └─ With approval workflows
```

**Where filtering happens:**
```
User opens app
    ↓
Selects role (if multi-role)
    ↓
App loads UserContext with that role
    ↓
API request includes: userId + roleId + contextId
    ↓
Backend filters products:
  - Hide products not for this role
  - Apply role-appropriate pricing
  - Apply role-specific availability
    ↓
Return filtered product list
    ↓
UI renders only visible, affordable products
```

---

### LAYER 4: Role-Specific Workflows

**Consumer Home Screen:**
```
┌─ Welcome: "Browse essentials"
├─ Search bar
├─ Deal carousel
├─ Recommended products
├─ Cart button
└─ Order history
```

**Co-op Member Home Screen:**
```
┌─ Welcome: "Your member benefits"
├─ Savings summary
├─ Loyalty points
├─ Voting opportunities
├─ Reports & transparency
├─ Exclusive deals
└─ Shop with member pricing
```

**Franchise Owner Home Screen:**
```
┌─ Store dashboard
│  ├─ Sales today/week
│  ├─ Inventory levels
│  └─ Days of cover alerts
├─ Reorder products (wholesale)
├─ Compliance checklist
├─ Incident reporting
└─ Support chat
```

**Institutional Buyer Home Screen:**
```
┌─ Purchase orders
│  ├─ Draft
│  ├─ Pending approval
│  └─ Approved
├─ Invoices
├─ Contract pricing
├─ Bulk order templates
└─ Approval chain status
```

**Delivery Driver Home Screen:**
```
┌─ Today's routes
├─ Pickup locations
├─ Delivery stops
├─ Customer contact
├─ GPS navigation
└─ Proof of delivery
```

**Admin Home Screen:**
```
┌─ KPI dashboard
├─ Active alerts
├─ User management
├─ Pricing oversight
├─ Compliance score
├─ Audit log viewer
└─ Exception handling
```

---

### LAYER 5: Audit Logging

**Current State:**
```
// No logging of who did what
User logs in → no record
Order created → no record
Price accessed → no record
❌ Non-compliant for enterprise
```

**Required State:**
```dart
class AuditLog {
  String id;
  String userId;
  List<UserRole> userRoles;
  String action;              // "viewed_product", "created_order"
  String resource;            // "product:123", "order:456"
  Map<String, dynamic> details;
  String? result;             // "success", "denied", "error"
  String? denialReason;       // "insufficient_permission"
  DateTime timestamp;
}

// Every significant action logs:
await auditService.log(
  userId: user.id,
  userRoles: user.roles,
  action: 'view_institutional_pricing',
  resource: 'product:${product.id}',
  result: user.roles.contains(UserRole.institutionalBuyer) ? 'success' : 'denied',
);
```

**Usage:**
```
Admin opens audit log
    ↓
Sees: "2026-01-26 10:45 User#123 (Franchise Owner) viewed institutional pricing on product#456 → DENIED"
    ↓
Can investigate: Why is this franchise owner trying to see institutional pricing?
```

---

### LAYER 6: Permissions System

**Current State:**
```
// No permission checking anywhere
Anyone can view any endpoint
Anyone can perform any action
❌ Completely open
```

**Required State:**
```dart
enum Permission {
  // Retail
  viewRetailPrices,
  createRetailOrder,
  trackOrder,
  viewSavings,
  
  // Member
  viewMemberBenefits,
  viewVoting,
  participateInVoting,
  
  // Wholesale
  viewWholesalePrices,
  createWholesaleOrder,
  viewInventory,
  updateInventory,
  
  // Institutional
  viewContractPricing,
  createPurchaseOrder,
  approvePurchaseOrder,
  viewInvoices,
  
  // Franchise
  manageFranchiseStore,
  viewFranchiseSales,
  submitComplianceEvidence,
  createIncidentReport,
  
  // Logistics
  assignDeliveryRoute,
  updateDeliveryStatus,
  captureProofOfDelivery,
  
  // Admin
  manageUsers,
  assignRoles,
  overridePricing,
  viewAuditLog,
  viewKPIs,
  handleExceptions,
}

// In API:
@POST('/orders/create')
Future<Order> createOrder(OrderRequest request, User user) {
  if (!user.hasPermission(Permission.createRetailOrder)) {
    throw PermissionDeniedException('User cannot create retail orders');
  }
  // ... process order
}
```

---

## 🔄 How This Flows Together

### Example: Consumer buys product

```
1. Consumer opens app
   ├─ Loads with role: Consumer
   └─ Context: personal shopping
   
2. Views home screen
   └─ Riverpod calls productProvider
   
3. productProvider calls productService.getByRole()
   ├─ Service adds to request: userId + roleId
   └─ Sends to backend API
   
4. Backend API checks permission
   ├─ Can user (Consumer role) view retail products? YES
   └─ Returns filtered products with retail pricing
   
5. App displays products
   ├─ Shows retail prices only
   ├─ Hides wholesale/contract pricing
   └─ Logs: "User#123 viewed retail catalog"
   
6. Consumer adds to cart
   └─ Payment system (already built) processes payment
   
7. Order created
   ├─ Logs: "User#123 created retail order for ₦15,000"
   ├─ Visible in order history
   └─ Can track delivery
```

### Example: Franchise owner reorders stock

```
1. Franchise owner opens app
   ├─ Loads with roles: Consumer + FranchiseOwner
   └─ Selects: Switch to Franchise mode
   
2. Context changes
   ├─ franchise_id set to "franchise_ng_001"
   └─ store_id set to "store_ng_001"
   
3. Views franchise home screen
   ├─ Shows sales dashboard
   ├─ Shows inventory levels
   └─ Shows reorder button
   
4. Clicks reorder
   ├─ productService.getByRole() called
   ├─ Role: FranchiseOwner
   ├─ Context: franchise_ng_001
   └─ Backend returns: wholesale products only
   
5. Sees wholesale catalog
   ├─ Product A: ₦3,000/unit (wholesale)
   ├─ MOQ: 100 units
   ├─ Cart allows: bulk ordering only
   └─ Hides: retail pricing, contract terms
   
6. Creates wholesale order
   ├─ Order marked: type = "wholesale"
   ├─ Logs: "User#456 (FranchiseOwner for franchise_ng_001) created wholesale order"
   ├─ Requires: delivery to franchise address
   └─ Triggers: warehouse picking workflow
```

### Example: Admin views pricing

```
1. Admin opens app
   ├─ Loads with role: Admin
   └─ Can see ALL data
   
2. Navigates to pricing oversight
   ├─ productService.getByRole(includeAll: true)
   └─ Backend returns: ALL products with ALL pricing
   
3. Sees dashboard:
   ├─ Product A:
   │  ├─ Retail: ₦5,000
   │  ├─ Wholesale: ₦3,000
   │  ├─ Contract (Institution X): ₦2,500
   │  └─ Last approved by: Admin#789 on 2026-01-20
   ├─ Product B: ...
   └─ Price modification history (audit log)
   
4. Override price
   ├─ Sets contract pricing for new institution
   ├─ Logs: "Admin#123 set contract price for product#A to ₦2,400 for institution#X"
   └─ Change takes effect immediately
```

---

## 🏗️ Architecture Changes Needed

### Current Architecture:
```
UI Layer
  ↓
Riverpod Providers
  ↓
Services (ProductService, OrderService, etc)
  ↓
API Client (Dio)
  ↓
Mock Backend
```

### Required Architecture:
```
UI Layer
  ├─ Role-specific screens
  └─ Permission guards
  
  ↓
  
Riverpod Providers
  ├─ roleProvider (current user role)
  ├─ permissionProvider (current user permissions)
  ├─ contextProvider (current user organization context)
  └─ Existing providers
  
  ↓
  
Services
  ├─ Inject current user/role/permissions
  ├─ Filter data by role
  ├─ Add audit logging
  └─ Enforce business rules
  
  ↓
  
Middleware/Guards
  ├─ Permission checking
  ├─ Audit logging
  └─ Error handling
  
  ↓
  
Real Backend (Node.js / NestJS)
  ├─ RBAC enforcement (final check)
  ├─ Database queries filtered by role
  └─ Audit trail stored in DB
```

---

## 📋 What Needs to Happen (Prioritized)

### CRITICAL (Do First - 1-2 days)
1. Define UserRole enum
2. Define Permission enum
3. Update User model with roles
4. Create role provider
5. Create permission provider
6. Add permission guards to routes

### HIGH (Do Second - 3-5 days)
7. Create role-aware home screen
8. Filter products by role in services
9. Implement role-aware pricing
10. Add audit logging to services

### MEDIUM (Do Third - 1-2 weeks)
11. Build role-specific screens
12. Implement franchise workflows
13. Implement institutional workflows
14. Implement logistics workflows

### LOW (Do Later)
15. Build admin control tower
16. Implement compliance tracking
17. Implement governance features
18. Mobile app polish

---

## ⚡ Quick Impact Assessment

If you implement RBAC foundation TODAY:
- ✅ App becomes secure
- ✅ Each user sees only appropriate screens
- ✅ Prices protected by role
- ✅ Data isolated per organization
- ✅ Audit trail established
- ✅ Ready for real backend

If you don't:
- ❌ Shipping insecure product
- ❌ All users see everything
- ❌ Franchisee sees retail-only, misses wholesale
- ❌ Institutional buyer sees wrong pricing
- ❌ No compliance trail
- ❌ Complete redesign needed before production

---

**Start with CRITICAL items. Then proceed to HIGH priority. App will go from demo → enterprise-ready.**
