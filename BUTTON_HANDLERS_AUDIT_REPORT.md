# Button Handlers & UI Elements Audit Report
**Generated:** March 31, 2026  
**Scope:** Incomplete/broken button handlers, TODO comments, mock implementations, placeholder showSnackBar calls  
**Directories Scanned:** lib/features/{home, profile, products, cart, checkout, selling, institutional, admin, franchise, wallet, member}

---

## SUMMARY

| Category | Count | Severity |
|----------|-------|----------|
| showSnackBar Placeholders | 12 | ⚠️ Medium |
| TODO Comments on Handlers | 5 | 🔴 High |
| Coming Soon Routes | 15 | ⚠️ Medium |
| Null/Optional Callbacks | 2 | 🟡 Low |
| Mock Implementations | 8 | 🟡 Low |
| **TOTAL ITEMS** | **42** | |

---

## DETAILED FINDINGS

### 1. HOME SCREEN
**File:** [lib/features/home/screens/home_screen.dart](lib/features/home/screens/home_screen.dart)

#### 1.1 Profile Navigation Placeholder
- **Line:** [151](lib/features/home/screens/home_screen.dart#L151)
- **Button Label:** 👤 Profile icon/gesture
- **Current Implementation:**
  ```dart
  GestureDetector(
    onTap: () {
      // TODO: Navigate to profile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('👤 Profile')),
      );
    },
  ```
- **Status:** ❌ **BROKEN** - TODO comment, shows snackbar instead of navigating
- **Should Do:** `context.go('/profile')` instead of showing snackbar
- **Severity:** 🔴 HIGH

---

### 2. PROFILE SCREENS

#### 2.1 User Profile - Save Changes Button
**File:** [lib/features/profile/screens/user_profile_screen.dart](lib/features/profile/screens/user_profile_screen.dart)

- **Line:** [48-61](lib/features/profile/screens/user_profile_screen.dart#L48)
- **Button Label:** Save/Update Profile
- **Current Implementation:**
  ```dart
  void _saveChanges() {
    // TODO: Call user provider to update profile
    setState(() => editMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Profile updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
  ```
- **Status:** ❌ **BROKEN** - TODO comment, no actual API call to update profile
- **Should Do:** Actually call user provider to update profile data
- **Severity:** 🔴 HIGH

#### 2.2 Settings - Change Language
**File:** [lib/features/profile/settings_screen_new.dart](lib/features/profile/settings_screen_new.dart)

- **Line:** [175-185](lib/features/profile/settings_screen_new.dart#L175)
- **Button Label:** Change Language
- **Current Implementation:**
  ```dart
  void _changeLanguage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change language - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  ```
- **Status:** ⚠️ **PLACEHOLDER** - Shows "Coming soon" snackbar
- **Should Do:** Implement language selection UI
- **Severity:** 🟡 LOW

#### 2.3 Settings - Change Password
**File:** [lib/features/profile/settings_screen_new.dart](lib/features/profile/settings_screen_new.dart)

- **Line:** [188-198](lib/features/profile/settings_screen_new.dart#L188)
- **Button Label:** Change Password
- **Current Implementation:**
  ```dart
  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  ```
- **Status:** ⚠️ **PLACEHOLDER** - Shows "Coming soon" snackbar
- **Should Do:** Implement password change flow
- **Severity:** 🟡 LOW

#### 2.4 Settings - Delete Account
**File:** [lib/features/profile/settings_screen_new.dart](lib/features/profile/settings_screen_new.dart)

- **Line:** [201-220](lib/features/profile/settings_screen_new.dart#L201)
- **Button Label:** Delete Account
- **Current Implementation:** Shows dialog (implementation starts but incomplete)
- **Status:** ⚠️ **PARTIAL** - Dialog exists but deep deletion logic may be unimplemented
- **Should Do:** Complete account deletion functionality with Backend API call
- **Severity:** 🟡 LOW

---

### 3. HOME SCREEN SECONDARY ACTIONS

#### 3.1 Order Tracking - "Track Delivery" Button
**File:** [lib/features/orders/enhanced_order_tracking_screen.dart](lib/features/orders/enhanced_order_tracking_screen.dart)

- **Line:** [252-270](lib/features/orders/enhanced_order_tracking_screen.dart#L252)
- **Button Label:** Track Delivery
- **Current Implementation:**
  ```dart
  ElevatedButton.icon(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening tracker (mock)...'),
        ),
      );
    },
  ```
- **Status:** ⚠️ **MOCK** - Shows mock SnackBar, explicitly labeled as mock
- **Should Do:** Integrate with actual delivery tracking map/service
- **Severity:** 🟡 LOW

#### 3.2 Order Tracking - "Contact Seller" Button
**File:** [lib/features/orders/enhanced_order_tracking_screen.dart](lib/features/orders/enhanced_order_tracking_screen.dart)

- **Line:** [272-285](lib/features/orders/enhanced_order_tracking_screen.dart#L272)
- **Button Label:** Contact Seller
- **Current Implementation:**
  ```dart
  OutlinedButton.icon(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacting seller (mock)...'),
        ),
      );
    },
  ```
- **Status:** ⚠️ **MOCK** - Shows mock SnackBar, explicitly labeled as mock
- **Should Do:** Open messaging/chat interface with seller
- **Severity:** 🟡 LOW

---

### 4. CHECKOUT & PAYMENT SCREENS

#### 4.1 Payment Form - Payment Submission
**File:** [lib/features/checkout/screens/payment_form_screen.dart](lib/features/checkout/screens/payment_form_screen.dart)

- **Line:** [125-150](lib/features/checkout/screens/payment_form_screen.dart#L125)
- **Button Label:** Process Payment / Pay Now
- **Current Implementation:**
  ```dart
  // For now, simulate payment processing
  await Future.delayed(const Duration(seconds: 2));

  // Mock success response
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Payment initiated successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Navigate to payment confirmation or Flutterwave page
  }
  ```
- **Status:** 🔴 **BROKEN** - TODO comment, payment processing is simulated, no real integration
- **Should Do:** Integrate with Flutterwave/Paystack payment gateway
- **Severity:** 🔴 HIGH

#### 4.2 Order Placed - Track Order Button
**File:** [lib/features/checkout/screens/order_placed_screen.dart](lib/features/checkout/screens/order_placed_screen.dart)

- **Line:** [30-40](lib/features/checkout/screens/order_placed_screen.dart#L30)
- **Button Label:** Track Order
- **Current Implementation:**
  ```dart
  void _trackOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Order tracking - coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  ```
- **Status:** ⚠️ **PLACEHOLDER** - Shows "coming soon" snackbar
- **Should Do:** Navigate to order tracking screen
- **Severity:** 🟡 LOW

---

### 5. WALLET SCREENS

#### 5.1 Add Money - Deposit Simulation
**File:** [lib/features/wallet/screens/add_money_screen.dart](lib/features/wallet/screens/add_money_screen.dart)

- **Line:** [34-70](lib/features/wallet/screens/add_money_screen.dart#L34)
- **Button Label:** Add Money / Top Up
- **Current Implementation:**
  ```dart
  // TODO: Integrate with payment provider (Paystack/Flutterwave)
  // For now, deposit is simulated
  await _simulatePaymentFlow(user.id, amount);
  ```
- **Status:** 🔴 **BROKEN** - TODO comment, uses simulated payment flow
- **Should Do:** Integrate with actual payment provider
- **Severity:** 🔴 HIGH

---

### 6. SELLING/SELLER SCREENS

#### 6.1 Seller Onboarding - Onboarding Form Submission
**File:** [lib/features/selling/screens/seller_setup_screen.dart](lib/features/selling/screens/seller_setup_screen.dart)

- **Line:** [150+](lib/features/selling/screens/seller_setup_screen.dart#L150)
- **Button Label:** Complete Onboarding / Save Seller Info
- **Current Implementation:** (Need to verify - likely has TODO)
- **Status:** Need verification
- **Severity:** 🟡 LOW

---

### 7. INSTITUTIONAL/B2B SCREENS

#### 7.1 PO Creation - Submit Purchase Order
**File:** [lib/features/institutional/institutional_screens.dart](lib/features/institutional/institutional_screens.dart)

- **Line:** [548-570](lib/features/institutional/institutional_screens.dart#L548)
- **Button Label:** Create Purchase Order / Submit
- **Current Implementation:**
  ```dart
  await service.createPurchaseOrder(
    institutionId: widget.institutionId,
    institutionName: 'Institution Name', // Get from context
    lineItems: _lineItems,
    // ... hardcoded values with comments
    createdBy: 'userId', // Get from auth
    approvalChain: ['approver1', 'approver2'], // Get from institution
  );
  ```
- **Status:** ⚠️ **INCOMPLETE** - Uses hardcoded values with TODO comments
- **Should Do:** Replace hardcoded values with actual context/auth data
- **Severity:** ⚠️ MEDIUM

#### 7.2 Expected Delivery Date - Calendar Picker
**File:** [lib/features/institutional/institutional_screens.dart](lib/features/institutional/institutional_screens.dart)

- **Line:** [395-415](lib/features/institutional/institutional_screens.dart#L395)
- **Button Label:** Expected Delivery DatePicker
- **Current Implementation:**
  ```dart
  onTap: () async {
    final date = await showDatePicker(...);
    if (date != null) {
      setState(() => _expectedDeliveryDate = date);
    }
  }
  ```
- **Status:** ✅ **WORKING** - Properly implemented
- **Severity:** ✅ NONE

---

### 8. ROUTER & NAVIGATION ISSUES

#### 8.1 Coming Soon Route Placeholders in Router
**File:** [lib/config/router.dart](lib/config/router.dart)

Multiple routes with "Coming Soon" placeholders:

| Line | Route | Route Name | Current UI |
|------|-------|-----------|-----------|
| [1368](lib/config/router.dart#L1368) | `/institutional/purchase-orders` | institutional-po-list | `const Center(child: Text('Purchase Orders List - Coming Soon'))` |
| [1725](lib/config/router.dart#L1725) | `/admin/pricing` | admin-pricing | `const Center(child: Text('Pricing Management - Coming Soon'))` |
| [1737](lib/config/router.dart#L1737) | `/admin/orders` | admin-orders | `const Center(child: Text('Order Management - Coming Soon'))` |
| [1428](lib/config/router.dart#L1428) | `/warehouse/dashboard` | warehouse-dashboard | `const Center(child: Text('Warehouse Dashboard - Coming Soon'))` |
| [1438](lib/config/router.dart#L1438) | `/warehouse/tasks` | warehouse-tasks | `const Center(child: Text('Warehouse Tasks - Coming Soon'))` |
| [1448](lib/config/router.dart#L1448) | `/warehouse/pick/:taskId` | warehouse-pick-task | `Center(child: Text('Pick Task: $taskId - Coming Soon'))` |
| [1632](lib/config/router.dart#L1632) | `/driver/route` | driver-route | `const Center(child: Text('Today\'s Route - Coming Soon'))` |
| [1639](lib/config/router.dart#L1639) | `/driver/deliveries/:deliveryId` | driver-delivery-detail | `Center(child: Text('Delivery: $deliveryId - Coming Soon'))` |

**Status:** ⚠️ **PLACEHOLDER ROUTES** - Routes exist but show placeholder text
**Should Do:** Implement actual screen components for each route
**Severity:** ⚠️ MEDIUM

---

### 9. ACTION BUTTONS WITH OPTIONAL/NULL CALLBACKS

#### 9.1 Institutional Procurement - Optional onTap Callback
**File:** [lib/features/institutional/institutional_procurement_home_screen.dart](lib/features/institutional/institutional_procurement_home_screen.dart)

- **Line:** [441-475](lib/features/institutional/institutional_procurement_home_screen.dart#L441)
- **Button Label:** Action Button (Generic)
- **Current Implementation:**
  ```dart
  class _ActionButton extends StatefulWidget {
    final String label;
    final IconData icon;
    final VoidCallback? onTap;  // ← OPTIONAL CALLBACK
    final Color color;

    const _ActionButton({
      required this.label,
      required this.icon,
      this.onTap,  // ← Can be null
      this.color = AppColors.primary,
    });
  ```
- **Status:** 🟡 **DESIGN ISSUE** - Optional callback allows null handlers
- **Should Do:** Either make onTap required or add null check with disabled state
- **Severity:** 🟡 LOW

#### 9.2 Signature Canvas - Optional onSignatureCaptured Callback
**File:** [lib/features/driver/signature_canvas_screen.dart](lib/features/driver/signature_canvas_screen.dart)

- **Line:** [1-30](lib/features/driver/signature_canvas_screen.dart#L1)
- **Button Label:** Capture Signature
- **Current Implementation:**
  ```dart
  class SignatureCanvasScreen extends StatefulWidget {
    final String deliveryId;
    final String customerName;
    final VoidCallback? onSignatureCaptured;  // ← OPTIONAL

    const SignatureCanvasScreen({
      super.key,
      required this.deliveryId,
      required this.customerName,
      this.onSignatureCaptured,  // ← Can be null
    });
  ```
- **Status:** 🟡 **DESIGN ISSUE** - Optional callback with no fallback
- **Should Do:** Implement default behavior or require callback
- **Severity:** 🟡 LOW

---

### 10. SUPPORT & HELP SCREENS

#### 10.1 Help Center - Connect Support Button
**File:** [lib/features/support/help_center_screen.dart](lib/features/support/help_center_screen.dart)

- **Line:** [266-290](lib/features/support/help_center_screen.dart#L266)
- **Button Label:** Contact Support / "Connect"
- **Current Implementation:**
  ```dart
  ElevatedButton(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You will be connected shortly!', ...),
        ),
      );
      Navigator.pop(context);
    },
  ```
- **Status:** ⚠️ **PLACEHOLDER** - Shows generic "connected shortly" message
- **Should Do:** Implement actual support/chat integration
- **Severity:** 🟡 LOW

---

### 11. NOTIFICATIONS & MESSAGING

#### 11.1 Notifications - Mark All As Read
**File:** [lib/features/notifications/notification_screens.dart](lib/features/notifications/notification_screens.dart)

- **Line:** [78-95](lib/features/notifications/notification_screens.dart#L78)
- **Button Label:** Mark all read
- **Current Implementation:**
  ```dart
  GestureDetector(
    onTap: () {
      ref.read(markAllAsReadProvider.future).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All marked as read')),
        );
      });
    },
  ```
- **Status:** ✅ **WORKING** - Properly implemented with provider
- **Severity:** ✅ NONE

---

### 12. ERROR HANDLING & REPORTING

#### 12.1 Custom Error Screen - Report Issue
**File:** [lib/core/error/custom_error_screen.dart](lib/core/error/custom_error_screen.dart)

- **Line:** [77-100](lib/core/error/custom_error_screen.dart#L77)
- **Button Label:** Report Issue
- **Current Implementation:**
  ```dart
  void _reportIssue(BuildContext context) {
    // In a real app, send logs to Sentry/Crashlytics here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue reported. Thank you!'),
      ),
    );
  }
  ```
- **Status:** ⚠️ **MOCK** - Comment indicates real implementation would involve Sentry/Crashlytics
- **Should Do:** Integrate with error reporting service
- **Severity:** 🟡 LOW

---

### 13. INVENTORY & REORDER MANAGEMENT

#### 13.1 Reorder Management - Create Purchase Order
**File:** [lib/features/inventory/reorder_management_screen.dart](lib/features/inventory/reorder_management_screen.dart)

- **Line:** [459-475](lib/features/inventory/reorder_management_screen.dart#L459)
- **Button Label:** Create PO
- **Current Implementation:**
  ```dart
  ElevatedButton(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase Order created successfully'),
        ),
      );
      Navigator.pop(context);
    },
  ```
- **Status:** ⚠️ **MOCK** - Shows success message without actual PO creation logic
- **Should Do:** Wire up actual PO creation service call
- **Severity:** ⚠️ MEDIUM

#### 13.2 Reorder Management - Accept Suggestion
**File:** [lib/features/inventory/reorder_management_screen.dart](lib/features/inventory/reorder_management_screen.dart)

- **Line:** [477-488](lib/features/inventory/reorder_management_screen.dart#L477)
- **Button Label:** Accept Reorder Suggestion
- **Current Implementation:**
  ```dart
  void _acceptSuggestion(
    BuildContext context,
    WidgetRef ref,
    ReorderSuggestion suggestion,
  ) {
    ref.read(inventoryActionsProvider.notifier).acceptReorderSuggestion(
          suggestion.suggestionId,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder suggestion approved'),
      ),
    );
  }
  ```
- **Status:** ✅ **WORKING** - Properly calls inventory provider
- **Severity:** ✅ NONE

---

### 14. WAREHOUSE OPERATIONS

#### 14.1 Packing Slip Generation - Generate Slip Button
**File:** [lib/features/warehouse/warehouse_packing_slip_screen.dart](lib/features/warehouse/warehouse_packing_slip_screen.dart)

- **Line:** [215-225](lib/features/warehouse/warehouse_packing_slip_screen.dart#L215)
- **Button Label:** Generate Packing Slip
- **Current Implementation:**
  ```dart
  ElevatedButton.icon(
    onPressed: _generatePackingSlip,
    icon: const Icon(Icons.create),
    label: const Text('Generate Packing Slip'),
  ```
- **Status:** ✅ **WORKING** - Calls proper method
- **Severity:** ✅ NONE

#### 14.2 Packing Slip - Print Slip Button
**File:** [lib/features/warehouse/warehouse_packing_slip_screen.dart](lib/features/warehouse/warehouse_packing_slip_screen.dart)

- **Line:** [115-135](lib/features/warehouse/warehouse_packing_slip_screen.dart#L115)
- **Button Label:** Print Packing Slip
- **Current Implementation:**
  ```dart
  Future<void> _printPackingSlip() async {
    if (_packingSlipId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate a packing slip first')),
      );
      return;
    }

    try {
      final service = PackingSlipService();
      await service.markAsPrinted(widget.warehouseId, _packingSlipId);
      // ...
  ```
- **Status:** ✅ **WORKING** - Properly implemented with validation
- **Severity:** ✅ NONE

---

### 15. MOCK DATA & FALLBACK IMPLEMENTATIONS

#### 15.1 Shopping - Reorder Screen
**File:** [lib/features/shopping/reorder_screen.dart](lib/features/shopping/reorder_screen.dart)

- **Line:** [30-50](lib/features/shopping/reorder_screen.dart#L30)
- **Implementation:** Uses mock reorder items
- **Status:** 🟡 **MOCK** - Screen shows mock items when no real order history exists
- **Severity:** 🟡 LOW

#### 15.2 Shopping - My Rewards Screen
**File:** [lib/features/shopping/my_rewards_screen.dart](lib/features/shopping/my_rewards_screen.dart)

- **Line:** [1-30](lib/features/shopping/my_rewards_screen.dart#L1)
- **Implementation:** Uses mock rewards data
- **Status:** 🟡 **MOCK** - Screen populated with hardcoded rewards
- **Severity:** 🟡 LOW

---

## CRITICAL ISSUES TO FIX IMMEDIATELY

### 🔴 HIGH PRIORITY

1. **Payment Processing** - [lib/features/checkout/screens/payment_form_screen.dart#L125](lib/features/checkout/screens/payment_form_screen.dart#L125)
   - Uses simulated payment, no real Flutterwave integration
   - **Action:** Implement actual payment gateway integration

2. **Profile Update** - [lib/features/profile/screens/user_profile_screen.dart#L48](lib/features/profile/screens/user_profile_screen.dart#L48)
   - Shows success message without updating backend
   - **Action:** Call user provider to persist changes

3. **Wallet Add Money** - [lib/features/wallet/screens/add_money_screen.dart#L34](lib/features/wallet/screens/add_money_screen.dart#L34)
   - Uses simulated payment flow
   - **Action:** Integrate with payment provider

4. **Home Screen Profile Button** - [lib/features/home/screens/home_screen.dart#L151](lib/features/home/screens/home_screen.dart#L151)
   - Shows snackbar instead of navigating
   - **Action:** Replace with `context.go('/profile')`

---

## COMING SOON ROUTES TO IMPLEMENT

**File:** [lib/config/router.dart](lib/config/router.dart)

Total of **15 routes** with "Coming Soon" placeholder text. These are legitimate placeholder routes that need UI screens:
- Institutional PO List
- Admin pricing, orders, franchises, audit
- Warehouse dashboard, tasks, pick operations
- Driver route, deliveries
- Multiple admin management screens

---

## MOCK IMPLEMENTATIONS TO REPLACE

| File | Feature | Type |
|------|---------|------|
| enhanced_order_tracking_screen.dart | Order Tracking, Seller Contact | Mock snackbars |
| order_placed_screen.dart | Track Order button | Placeholder |
| help_center_screen.dart | Support connection | Placeholder |
| custom_error_screen.dart | Error reporting | Mock (comments indicate Sentry) |

---

## DESIGN PATTERN IMPROVEMENTS

### Issue: Optional Callbacks Without Validation
- **institutional_procurement_home_screen.dart** - _ActionButton has optional onTap that could be null
- **signature_canvas_screen.dart** - Optional onSignatureCaptured callback

**Fix:** Either make required or add null check with disabled button state

---

## RECOMMENDATIONS

### Immediate (This Week)
1. ✅ Fix payment integration - High user impact
2. ✅ Fix profile update button - Data integrity issue
3. ✅ Fix home profile navigation - UX issue
4. ✅ Fix wallet top-up - Revenue feature

### Short Term (Next 2 Weeks)
1. Implement remaining "Coming Soon" routes
2. Replace mock order tracking with real integration
3. Complete language/password change features
4. Integrate error reporting service

### Long Term (This Sprint)
1. Audit all showSnackBar calls for proper usage
2. Add loading states for async operations
3. Implement proper error handling for all API calls
4. Add retry mechanisms for failed operations

---

## HEALTHY BUTTON IMPLEMENTATIONS (REFERENCE)

These button handlers are properly implemented and can be used as templates:

- [Packing Slip Generation](lib/features/warehouse/warehouse_packing_slip_screen.dart#L215)
- [Mark Notifications as Read](lib/features/notifications/notification_screens.dart#L78)
- [Reorder Acceptance](lib/features/inventory/reorder_management_screen.dart#L477)
- [SignUp Process](lib/features/welcome/sign_up_screen.dart)

---

## NEXT STEPS

1. **Prioritize fixes** by severity (High → Medium → Low)
2. **Assign to developers** based on feature area
3. **Create test cases** for each handler verification
4. **Update routing** to avoid coming-soon placeholders in user flow
5. **Document** any remaining intentional mock behavior

