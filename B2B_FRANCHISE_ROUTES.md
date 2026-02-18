# Routes Integration Guide - B2B & Franchise

## Adding Routes to `app_routes.dart`

Add these route definitions to your `lib/core/navigation/app_routes.dart`:

### B2B/Institutional Routes

```dart
// INSTITUTIONAL/B2B ROUTES
// Purchase Order Management
GoRoute(
  path: '/institutional',
  name: 'institutional',
  builder: (context, state) => const InstitutionalDashboardScreen(),
),
GoRoute(
  path: '/institutional/purchase-orders',
  name: 'poList',
  builder: (context, state) {
    final institutionId = state.pathParameters['institutionId'] ?? '';
    return PurchaseOrderListScreen(institutionId: institutionId);
  },
),
GoRoute(
  path: '/institutional/purchase-orders/create',
  name: 'poCreate',
  builder: (context, state) {
    final institutionId = state.pathParameters['institutionId'] ?? '';
    return PurchaseOrderCreationScreen(institutionId: institutionId);
  },
),
GoRoute(
  path: '/institutional/purchase-orders/:poId',
  name: 'poDetail',
  builder: (context, state) {
    // TODO: Create PurchaseOrderDetailScreen
    return Container();
  },
),
GoRoute(
  path: '/institutional/invoices',
  name: 'invoices',
  builder: (context, state) {
    // TODO: Create InvoiceListScreen
    return Container();
  },
),
GoRoute(
  path: '/institutional/invoices/:invoiceId',
  name: 'invoiceDetail',
  builder: (context, state) {
    // TODO: Create InvoiceDetailScreen
    return Container();
  },
),
```

### Franchise Routes

```dart
// FRANCHISE ROUTES
GoRoute(
  path: '/franchise',
  name: 'franchise',
  builder: (context, state) {
    final storeId = state.pathParameters['storeId'] ?? '';
    return FranchiseDashboardScreen(storeId: storeId);
  },
),
GoRoute(
  path: '/franchise/inventory',
  name: 'franchiseInventory',
  builder: (context, state) {
    final storeId = state.pathParameters['storeId'] ?? '';
    return FranchiseInventoryScreen(storeId: storeId);
  },
),
GoRoute(
  path: '/franchise/compliance',
  name: 'franchiseCompliance',
  builder: (context, state) {
    final storeId = state.pathParameters['storeId'] ?? '';
    return ComplianceChecklistScreen(storeId: storeId);
  },
),
GoRoute(
  path: '/franchise/reports',
  name: 'franchiseReports',
  builder: (context, state) {
    final storeId = state.pathParameters['storeId'] ?? '';
    return FranchiseReportsScreen(storeId: storeId);
  },
),
```

---

## Navigation Examples

### Navigate to B2B Dashboard

```dart
// From any widget
context.go('/institutional');

// Or with GoRouter
GoRouter.of(context).push('/institutional');
```

### Navigate to Purchase Orders List

```dart
context.go('/institutional/purchase-orders', 
  extra: {'institutionId': 'inst_123'}
);
```

### Navigate to PO Creation

```dart
context.push('/institutional/purchase-orders/create',
  extra: {'institutionId': 'inst_123'}
);
```

### Navigate to Franchise Dashboard

```dart
context.go('/franchise',
  extra: {'storeId': 'store_456'}
);
```

### Navigate to Compliance Checklist

```dart
context.push('/franchise/compliance',
  extra: {'storeId': 'store_456'}
);
```

---

## Role-Based Navigation (Using Phase 0)

If using the Phase 0 `RoleAwareNavigationShell`:

```dart
// In your role-aware navigation
class InstitutionalNavigationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationRail(
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart),
          label: Text('Purchase Orders'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt),
          label: Text('Invoices'),
        ),
      ],
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/institutional');
          case 1:
            context.go('/institutional/purchase-orders');
          case 2:
            context.go('/institutional/invoices');
        }
      },
    );
  }
}
```

---

## Integration with Authentication

Add role checks before navigation:

```dart
// Check if user is institutional buyer
void navigateToB2B(BuildContext context, WidgetRef ref) {
  final userRole = ref.read(userRoleProvider);
  
  if (userRole == 'institutional_buyer') {
    context.go('/institutional');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You do not have access to B2B features')),
    );
  }
}

// Check if user is franchise owner
void navigateToFranchise(BuildContext context, WidgetRef ref) {
  final userRole = ref.read(userRoleProvider);
  
  if (userRole == 'franchise_owner') {
    context.go('/franchise');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You do not have access to franchise features')),
    );
  }
}
```

---

## Screens Still to Create

The following screens are referenced but need to be created:

### B2B Screens Needed
- [ ] `PurchaseOrderDetailScreen` - View single PO, see line items, approval chain
- [ ] `InvoiceListScreen` - View all invoices with filters
- [ ] `InvoiceDetailScreen` - View invoice, record payment
- [ ] `POApprovalScreen` - Approve/reject interface for approvers
- [ ] `ContractPricingManagementScreen` - Admin interface to manage contract prices

### Franchise Screens Needed
- [ ] `StoreManagementScreen` - Admin interface for creating/editing stores
- [ ] `InventoryAdjustmentScreen` - Adjust inventory counts
- [ ] `SalesEntryScreen` - Quick entry for daily sales

---

## Settings Routes

Add admin routes if needed:

```dart
// B2B Admin
GoRoute(
  path: '/admin/contract-pricing',
  name: 'contractPricingAdmin',
  builder: (context, state) {
    // TODO: Create admin pricing management
    return Container();
  },
),

// Franchise Admin
GoRoute(
  path: '/admin/franchises',
  name: 'franchiseAdmin',
  builder: (context, state) {
    // TODO: Create franchise management
    return Container();
  },
),
```

---

## Summary

- ✅ B2B routes: dashboard, PO list, PO create, invoices
- ✅ Franchise routes: dashboard, inventory, compliance, reports
- ⏳ Additional screens needed: detail views, admin interfaces
- 🔧 Integration: Add to `app_routes.dart` and connect to navigation widgets

All screens are ready to be added to your routing system!
