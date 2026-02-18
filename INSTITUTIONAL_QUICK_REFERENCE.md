# Institutional Procurement - Quick Reference

**Status:** ✅ COMPLETE (Feature #7) | **Date:** Jan 30, 2026 | **Errors:** 0

---

## Navigation Routes

```
/institutional                      Home Dashboard
/institutional/purchase-orders/create
                                   Create New PO
/institutional/purchase-orders/:poId
                                   Approval Workflow
/institutional/invoices             Invoice List
/institutional/invoices/:invoiceId  Invoice Details
```

---

## Screen Quick Links

| Screen | File | Features |
|--------|------|----------|
| Home Dashboard | `institutional_procurement_home_screen.dart` | KPI cards, recent POs, active contracts, quick actions |
| PO Creation | `institutional_po_creation_screen.dart` | Contract selection, line item management, delivery details |
| Invoice List | `institutional_invoice_screen.dart` | Filter by status, payment progress visualization |
| Invoice Detail | `institutional_invoice_screen.dart` | Line items, payment breakdown, download/print options |
| Approval Timeline | `institutional_approval_workflow_screen.dart` | 3-step approval flow, action buttons |

---

## Key Features

### Dashboard
- **KPI Cards**: Total POs Pending, Outstanding Invoices, Total Spend YTD, Contracts Active
- **Quick Actions**: Create New PO, View Contracts, Pending Approvals, Invoices & Payments
- **Recent POs**: Latest orders with status badges
- **Active Contracts**: Contract summary cards

### PO Creation
1. Select contract from dropdown
2. Add line items (product, quantity, price)
3. Set delivery address and date
4. Enter special instructions
5. Submit (calculates subtotal + 15% tax = total)

### Invoice Management
- **Filters**: All | Outstanding | Paid | Overdue
- **Payment Progress**: Visual bar showing % paid
- **Actions**: Download PDF, Print, Submit Payment

### Approval Workflow
- **3-Step Timeline**:
  1. Department Approval (Finance)
  2. Budget Verification (Budget Office)
  3. Final Authorization (Director)
- **PO Details**: Items, subtotal, tax, total
- **Actions**: Approve or Reject (for assigned approvers only)

---

## Data Models

### Invoice
```dart
Invoice {
  String id,
  String invoiceNumber,
  String poId,
  double totalAmount,
  double amountPaid,
  DateTime invoiceDate,
  DateTime dueDate,
  String status, // Outstanding | Paid | Overdue | Partial
}
```

### PurchaseOrder
```dart
PurchaseOrder {
  String id,
  String poNumber,
  String contractId,
  List<POLineItem> lineItems,
  String deliveryAddress,
  DateTime deliveryDate,
  String status, // Pending | Approved | Completed
}
```

### POLineItem
```dart
POLineItem {
  String id,
  String productId,
  String productName,
  double unitPrice,
  int quantity,
  double lineTotal,
}
```

---

## Providers (Watch in Screens)

```dart
// Dashboard metrics
ref.watch(b2bMetricsProvider('institution_id'))

// Pending approvals
ref.watch(pendingApprovalsProvider('institution_id'))

// All invoices
ref.watch(institutionalInvoicesProvider('institution_id'))

// Specific PO details
ref.watch(purchaseOrderProvider(poId))

// Specific invoice details
ref.watch(invoiceDetailProvider(invoiceId))
```

---

## Common Tasks

### Add New Line Item to PO
1. Click "+ Add Line Item" button
2. Fill dialog: Product name, Qty, Unit Price
3. Click "Add" → Item appears in list
4. Summary updates automatically

### Filter Invoices
1. Select filter chip: All | Outstanding | Paid | Overdue
2. List updates instantly
3. Payment progress bars update by filter

### Approve PO
1. Navigate to PO detail (/institutional/purchase-orders/:poId)
2. If you're the next approver, see "Approve" button
3. Click "Approve" → Enter notes (optional)
4. Workflow advances to next step

### Submit Payment for Invoice
1. Open invoice detail
2. Click "Submit Payment"
3. Enter payment amount
4. Confirm → Invoice status updates

---

## State Management Pattern

All screens use **ConsumerWidget** or **ConsumerStatefulWidget**:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(myProvider);
    
    return dataAsync.when(
      data: (data) => Text('Data: $data'),
      loading: () => CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
```

---

## Widget Patterns

### KPI Card
```dart
_KPICard(
  title: 'Total POs Pending',
  value: '12',
  color: Colors.orange,
)
```

### Filter Chip
```dart
_FilterChip(
  label: 'Outstanding',
  isSelected: selectedFilter == InvoiceFilter.outstanding,
  onTap: () => setState(() => selectedFilter = InvoiceFilter.outstanding),
)
```

### Quick Action Button
```dart
_ActionButton(
  icon: Icons.add_circle,
  label: 'Create New PO',
  onTap: () => context.pushNamed('institutional-po-create'),
)
```

---

## RBAC Integration

All routes require `institutional_buyer` role:

```dart
redirect: (context, state) {
  if (!_hasRole(context, 'institutional_buyer')) {
    return '/login';
  }
  return null;
}
```

**Allowed Roles:** `institutional_buyer`, `admin`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Contract dropdown empty | Check that contracts exist in backend for this institution |
| Line items not calculating | Ensure quantity and unit price are valid numbers |
| Invoice filter not working | Check invoice status field matches filter enum (Outstanding, Paid, Overdue, Partial) |
| Approval buttons missing | Verify current user is next approver in workflow |
| Navigation failing | Ensure pathParameters/queryParameters match route definition |

---

## File Locations

```
lib/
├── config/
│   └── router.dart (routes defined, lines 754-800)
├── features/
│   └── institutional/
│       ├── institutional_procurement_home_screen.dart (420 LOC)
│       ├── institutional_po_creation_screen.dart (520 LOC)
│       ├── institutional_invoice_screen.dart (620 LOC)
│       └── institutional_approval_workflow_screen.dart (396 LOC)
└── core/
    ├── providers/
    │   └── b2b_providers.dart (provider definitions)
    └── services/
        └── b2b_service.dart (backend integration)
```

---

## Integration Checklist

- ✅ All 4 screens created
- ✅ Router.dart updated with 5 routes
- ✅ RBAC checks in place
- ✅ Riverpod providers integrated
- ✅ 0 compilation errors
- ✅ Navigation functional
- ✅ Data models complete
- ✅ Service layer ready

---

**Feature #7: Institutional Procurement → 100% Complete**
