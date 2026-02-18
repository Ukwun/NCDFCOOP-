# NCDFCOOP Architecture - Current State vs. Required State

## CURRENT ARCHITECTURE (What We Have)

```
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND LAYER                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Consumer      Franchise      Institutional     Driver      │
│  Home Screen   Dashboard      PO Screen         App         │
│  ✅ 80%        ⚠️ 60%         ⚠️ 40%            ✅ 80%      │
│                                                             │
│  Cart          Orders         Approval          Warehouse   │
│  ✅ 80%        ⚠️ 70%         ⚠️ 50%            ⚠️ 70%      │
│                                                             │
│  Notifications  Admin Home     Tracking          Compliance │
│  ✅ 80%        ⚠️ 40%         ⚠️ 60%            ❌ 20%      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                 HTTP/REST API (No Auth Checks!)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND SERVICES                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  AuthService          CatalogueService      OrderService    │
│  ✅ 70%               ✅ 70%                ⚠️ 70%         │
│  (No RBAC!)           (Variants exist)      (No approval)   │
│                                                             │
│  PricingService       CartService           PaymentService  │
│  ⚠️ 40%               ✅ 80%                ✅ 90%         │
│  (Basic calc)         (Good math)           (Excellent)     │
│                                                             │
│  NotificationService  WarehouseService      InventoryService│
│  ✅ 70%               ⚠️ 70%                ⚠️ 50%         │
│  (No real-time)       (Workflows exist)     (No sync)       │
│                                                             │
│  ❌ MembershipService ❌ PriceOverrideService              │
│  (Missing)            (Missing)                             │
│                                                             │
│  ❌ WholesalePricingService  ❌ ContractPricingService      │
│  (Missing)                   (Missing)                      │
│                                                             │
│  ❌ ApprovalWorkflowService  ❌ AuditLogService            │
│  (Missing)                   (Partial)                      │
│                                                             │
│  ❌ RealTimeService          ❌ AdminDashboardService       │
│  (Missing - CRITICAL!)       (Missing - CRITICAL!)         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
         ┌──────────────────┼──────────────────┐
         ↓                  ↓                  ↓
    Firebase          PostgreSQL          Redis
    Firestore         (Users, Orders)     (Cache only)
    (Inventory,       ✅ Connected        ❌ Not synced
     Payments)        ⚠️ No RBAC          for real-time
     ✅ Working        enforcement
```

---

## REQUIRED ARCHITECTURE (What We Need)

```
┌─────────────────────────────────────────────────────────────┐
│                   REAL-TIME LAYER                           │
├─────────────────────────────────────────────────────────────┤
│                   WebSocket / Socket.IO                     │
│              (Order updates, location, inventory)           │
│                     ❌ MISSING - BUILD NOW                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND LAYER                          │
├─────────────────────────────────────────────────────────────┤
│   [All role-aware screens]                                  │
│   Connected to WebSocket for real-time updates              │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌──────────────── API GATEWAY ───────────────┐
        │   Authentication Middleware                │
        │   ┌─ Token Validation                      │
        │   ├─ Role Extraction                       │
        │   └─ RBAC Check BEFORE route handler       │
        └─────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│               AUTHORIZATION LAYER (NEW!)                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   PermissionService                   ResourceOwnershipService
│   ├─ canCreateOrder()                 ├─ ownsOrder()
│   ├─ canApproveOrder()                ├─ ownsFranchise()
│   ├─ canChangePricing()               ├─ ownsInstitution()
│   ├─ canAccessAuditLog()              └─ ownsDelivery()
│   └─ canViewOtherUserData()
│                                                             │
│   AuditLogService (NEW!)                                   │
│   ├─ logAction()                                          │
│   ├─ logPriceChange()                                     │
│   ├─ logApproval()                                        │
│   └─ logDataAccess()                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   BUSINESS LOGIC LAYER                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PRICING ENGINE (UPGRADE!)                                │
│  ├─ RetailPricingService       (current)                 │
│  ├─ WholesalePricingService    (NEW!)                    │
│  ├─ ContractPricingService     (NEW!)                    │
│  ├─ PriceOverrideService       (NEW!)                    │
│  ├─ EssentialBasketService     (NEW!)                    │
│  └─ PromotionService           (current)                 │
│                                                             │
│  MEMBERSHIP ENGINE (NEW!)                                 │
│  ├─ MembershipTierService                                │
│  ├─ BenefitsCalculator                                   │
│  ├─ DividendCalculator                                   │
│  └─ GovernanceService                                    │
│                                                             │
│  WORKFLOW ENGINE (UPGRADE!)                              │
│  ├─ OrderService              (upgrade)                  │
│  ├─ ApprovalWorkflowService   (NEW!)                    │
│  ├─ InstitutionalPOService    (NEW!)                    │
│  └─ EscalationService         (NEW!)                    │
│                                                             │
│  OPERATIONS ENGINE (UPGRADE!)                            │
│  ├─ WarehouseQueueService     (add real-time)          │
│  ├─ PickPackService           (current)                 │
│  ├─ DispatchService           (NEW!)                    │
│  └─ DeliveryTrackingService   (add real-time)          │
│                                                             │
│  [All existing services with RBAC checks added]           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  REAL-TIME DATA LAYER                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Redis Cache (NEW USAGE!)                                 │
│  ├─ Inventory sync (stock by store)                       │
│  ├─ Order status (live updates)                           │
│  ├─ Driver location (real-time)                           │
│  ├─ Warehouse queue (active orders)                       │
│  └─ Price cache (for fast lookup)                         │
│                                                             │
│  Event Bus (NEW!)                                          │
│  ├─ OrderCreated → broadcast to driver, warehouse, admin  │
│  ├─ InventoryUpdated → broadcast to all clients           │
│  ├─ PriceChanged → broadcast to all connected clients     │
│  └─ DeliveryCompleted → update order, inventory           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
         ┌──────────────────┼──────────────────┐
         ↓                  ↓                  ↓
    Firebase          PostgreSQL          MongoDB
    Firestore         (Primary DB)         (Audit Logs -
    (Documents)       ├─ Users             immutable)
    ✅ For files      ├─ Orders
                      ├─ Inventory
                      ├─ Pricing
                      ├─ Approvals
                      └─ Contracts
```

---

## CRITICAL GAPS VISUALIZATION

```
FEATURE                    STATUS          IMPACT          EFFORT
─────────────────────────────────────────────────────────────────
RBAC Enforcement          ❌ 20%          CRITICAL        3-4d
  - API-level checks      ❌ 0%           (SECURITY)       
  - Resource ownership    ❌ 0%
  - Permission validation ❌ 0%

Real-Time Sync           ❌ 5%           HIGH             2-3d
  - WebSocket layer      ❌ 0%           (USER EXP)
  - Inventory sync       ❌ 0%
  - Driver location      ❌ 10%
  - Order updates        ❌ 5%
  - Admin dashboards     ❌ 0%

Pricing Engine           ⚠️  40%         CRITICAL        4-5d
  - Retail pricing       ✅ 70%          (REVENUE)
  - Wholesale pricing    ❌ 0%
  - Contract pricing     ❌ 0%
  - Price overrides      ❌ 0%
  - Essential basket     ❌ 0%

Approval Workflows       ⚠️  50%         HIGH             3-4d
  - Institutional POs    ⚠️  60%         (B2B OPS)
  - Price approvals      ❌ 0%
  - Compliance checks    ⚠️  30%

Audit Logging           ⚠️  30%         HIGH             2d
  - Central log store    ⚠️  30%         (COMPLIANCE)
  - Audit browser        ❌ 0%
  - Compliance exports   ❌ 0%

Membership System       ❌ 10%          MEDIUM           3d
  - Tiers & benefits     ❌ 0%           (COOPERATIVE)
  - Member visibility    ❌ 10%
  - Dividend reporting   ❌ 0%

Admin Control Tower    ❌ 20%          HIGH             3-4d
  - KPI dashboard        ❌ 0%           (OPERATIONS)
  - User management      ⚠️  40%
  - Pricing oversight    ❌ 0%
  - Compliance scoring   ❌ 0%

Warehouse Real-Time    ⚠️  60%         MEDIUM           2d
  - Queue visibility     ⚠️  60%         (EFFICIENCY)
  - Staff assignments    ⚠️  50%
  - Live KPIs           ❌ 0%

Driver Tracking        ⚠️  70%         MEDIUM           1-2d
  - Location streaming   ⚠️  70%         (DELIVERY)
  - Customer visibility  ❌ 0%
  - POD capture         ✅ 80%

─────────────────────────────────────────────────────────────────
TOTAL PRODUCTION READINESS: ~50-55% (Missing ~10-15 days work)
```

---

## DATA FLOW - CONSUMER PURCHASE (CURRENT vs. REQUIRED)

### CURRENT FLOW (Stale Data Issues)
```
Consumer              Frontend            Backend              Database
  │                     │                  │                      │
  ├─ Open app ──────────→ Get products ────→ Query catalogue ────→│
  │                     │                  │                      │
  │                     │←─── Product data (2 hours old) ────────┤
  │                     │                  │                      │
  ├─ Add to cart ───────→ Check inventory ─→ Redis? No, Firestore │
  │                     │                  │                      │
  │                     │←─── Stock info (potentially stale) ────┤
  │                     │                  │                      │
  ├─ Checkout ──────────→ Create order ────→ Add to database ────│
  │                     │                  │    (no real-time)    │
  │                     │                  │                      │
  ├─ Track order ───────→ Poll status ─────→ Query every 5s ────┤
  │ (every 5 seconds)   │                  │ (inefficient!)       │
  │                     │←─── Status (possibly still processing)─┤
  │                     │                  │                      │
  └─────────────────────┴─────────────────┴──────────────────────┘

PROBLEM: Multiple sources of truth, no real-time sync, stale inventory
```

### REQUIRED FLOW (Real-Time & Reliable)
```
Consumer              Frontend            Backend              Database
  │                     │                  │                      │
  ├─ Open app ──────────→ Connect WebSocket ─→ Subscribe to updates│
  │                     │  (persistent)    │                      │
  │                     │←─ Real-time data ────────────────────────│
  │                     │                  │                      │
  ├─ Search "rice" ─────→ Query with sync ─→ Check Redis (fast)  │
  │                     │                  │ + Firestore cache   │
  │                     │←─ Instant results ────────────────────┤
  │                     │  (✅ current stock, ✅ my role pricing)│
  │                     │                  │                      │
  ├─ Add to cart ───────→ Validate ────────→ Reserve in Redis   │
  │                     │  (real-time)     │ (transactional)     │
  │                     │←─ Confirmed ────────────────────────┤
  │                     │                  │                      │
  ├─ Checkout ──────────→ Create order ────→ Transaction:       │
  │                     │                  │ 1. Update inventory │
  │                     │                  │ 2. Create order     │
  │                     │                  │ 3. Emit event       │
  │                     │                  │ 4. Write to audit   │
  │                     │                  │                      │
  │                     │←─ Immediate confirmation ────────────┤
  │                     │                  │                      │
  ├─ Watch tracking ────→ WebSocket listens ─→ Receive updates    │
  │ (no polling!)       │ to order_updated │ from event bus      │
  │                     │ events           │                      │
  │                     │←─ Real-time status ──────────────────┤
  │                     │  (warehouse, driver, estimated time)  │
  │                     │                  │                      │
  └─────────────────────┴─────────────────┴──────────────────────┘

BENEFIT: Single source of truth, real-time, efficient, reliable
```

---

## RBAC ENFORCEMENT FLOW

### CURRENT (UI-Only - INSECURE)
```
Client Request               Frontend                Backend
      │                         │                       │
      ├─ "Approve order"        │                       │
      │                    Check role                   │
      │                   (UI only)                    │
      │                    If role == APPROVER ✅      │
      │                         │                       │
      │                    Send request ────────────────→
      │                         │                       │
      │                         │                    Execute
      │                         │                    (no checks!)
      │                         │                       │
      │←──────────────── Approved ─────────────────────┤
      │

PROBLEM: Anyone can modify the API call to approve ANY order
```

### REQUIRED (API-Level - SECURE)
```
Client Request               Frontend                Backend
      │                         │                       │
      ├─ "Approve order"        │                       │
      │                    Check role                   │
      │                   (for UX only)                │
      │                         │                       │
      │                    Send request ────────────────→
      │                         │   Authorization Middleware
      │                         │   1. Verify JWT token ✓
      │                         │   2. Extract user_id ✓
      │                         │   3. Query user role ✓
      │                         │   4. Check permission:
      │                         │      can(user, 'approve_order')? 
      │                         │      - NOT_ADMIN? ❌ DENY
      │                         │      - ADMIN? ✓ Continue
      │                         │
      │                         │   Business Logic Layer
      │                         │   5. Get order details
      │                         │   6. Verify ownership:
      │                         │      order.institution_id == 
      │                         │      user.institution_id?
      │                         │      - NO? ❌ DENY
      │                         │      - YES? ✓ Continue
      │                         │
      │                         │   Execute & Audit
      │                         │   7. Update order status
      │                         │   8. Log action:
      │                         │      {
      │                         │        action: 'ORDER_APPROVED'
      │                         │        user_id: '123'
      │                         │        order_id: 'ORD456'
      │                         │        timestamp: now()
      │                         │        ip_address: '192.x.x.x'
      │                         │      }
      │                         │
      │←──────────────── Approved ─────────────────────┤
      │

BENEFIT: Impenetrable - attempts to bypass are logged
```

---

## IMPLEMENTATION PRIORITY MATRIX

```
IMPACT
  │
  │ CRITICAL
  │     RBAC ★ Real-Time ★ Pricing ★ Audit Logging
  │     (Security) (UX)  (Revenue) (Compliance)
  │
  │ HIGH      │ Approval Workflows ★ Admin Control ★
  │           │ (B2B Ops)           (Operations)
  │
  │ MEDIUM    │ Membership ★ Warehouse Queue ★ Driver Real-Time
  │           │ (Cooperative) (Efficiency)   (Delivery)
  │
  │ LOW       │
  └───────────┴──────────────────────────────────────────→ EFFORT
              QUICK (1-2d)  MEDIUM (3-4d)  LONG (5+ days)

URGENCY: Do RBAC & Real-Time & Audit first (security blocker)
THEN: Pricing & Approval workflows (business logic)
THEN: Membership, Admin, Warehouse (nice-to-have but important)
```

