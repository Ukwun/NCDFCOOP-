# Admin Control Tower - Quick Reference

**Status:** ✅ COMPLETE (Feature #18) | **Date:** Jan 30, 2026 | **Errors:** 0

---

## Navigation Routes

```
/admin                      Home Dashboard (KPIs, quick actions, system health)
/admin/users                User Management (create, edit, activate/deactivate)
/admin/approvals            Price Override Approvals (approve/reject price changes)
/admin/compliance           Compliance Dashboard (scores, issues, monitoring)
/admin/audit-logs           Audit Log Browser (search, filter all activities)
```

---

## Quick Actions from Dashboard

| Button | Route | Purpose |
|--------|-------|---------|
| User Management | `/admin/users` | Create, edit, manage user accounts and roles |
| Approvals | `/admin/approvals` | Review and approve/reject price overrides |
| Compliance | `/admin/compliance` | Monitor compliance scores and issues |
| Audit Logs | `/admin/audit-logs` | Search and filter system activity |

---

## Dashboard KPI Cards

| Metric | Sample Value | Purpose |
|--------|--------------|---------|
| Total Users | 2,543 | Shows system user count + active users |
| Pending Approvals | 12 | Price overrides awaiting review |
| Compliance Issues | 3 | Issues requiring admin attention |
| Audit Logs This Month | 5,832 | Activity tracking |

---

## System Health Indicators

| Indicator | Status | Meaning |
|-----------|--------|---------|
| Database Status | Healthy | Firestore operations normal |
| API Response Time | Excellent (125ms) | Performance metric |
| Uptime | 99.8% | System availability |
| Firestore Quota | 28% Used | Storage/operations usage |

---

## User Management Features

### Search & Filter
- **Search by:** Name, Email (real-time)
- **Filter by:** All Roles, Consumer, Member, Franchisee, Institutional Buyer, Warehouse Staff, Driver, Admin
- **Show:** Active users or Include inactive

### User Actions
- **Create:** Add new user with email, phone, and role assignment
- **Edit:** Modify name, email, phone, and roles
- **Activate:** Re-enable deactivated account
- **Deactivate:** Disable user login access

### User Status
- **Active:** User can login and access platform
- **Inactive:** User cannot login until reactivated
- **Roles:** Multiple roles per user (e.g., member AND franchisee)

---

## Price Override Approval Workflow

### Tabs
1. **Pending Approvals:** Price changes awaiting admin decision
2. **Price History:** Complete audit trail of all changes
3. **Analytics:** Stats and trends

### Actions
- **Approve:** Accept price override (applies immediately)
- **Reject:** Deny price override with reason

### Metrics
- Current Price → Requested Price comparison
- Percentage change indicator
- Requested by (user who submitted)
- For Customer (specific buyer if applicable)

---

## Compliance Dashboard

### Overall Score (0-100)
- **Green:** 85-100 (Excellent)
- **Orange:** 70-85 (Good)
- **Red:** <70 (Needs Improvement)

### Category Breakdown
| Category | Sample Score | Measures |
|----------|--------------|----------|
| Pricing Compliance | 92% | Price rule violations |
| Inventory Accuracy | 85% | Stock discrepancies |
| Delivery Performance | 88.5% | SLA compliance |
| Fraud Detection | 80% | Suspicious activities |

### Issue Severity Levels
- **Critical:** Red - Requires immediate action
- **Warning:** Orange - Should be addressed soon
- **Info:** Blue - Informational

### Issue Tracking
- **Open Issues:** Active problems requiring attention
- **Resolved Issues:** Recently closed issues
- **Mark Resolved:** Button to close open issue

---

## Audit Log Browser

### Search Capabilities
- **By User ID:** Find all actions from specific user
- **By Resource ID:** Track changes to specific item (SKU-1234, ORD-5821)
- **By IP Address:** Identify location/device of action

### Filters
| Filter | Options | Purpose |
|--------|---------|---------|
| Action | All, Create, Update, Delete, Approve, Reject | Type of operation |
| Resource Type | All, User, Order, Product, Price, Franchise | What was changed |
| Status | All, Success, Failed | Operation outcome |
| Date Range | Custom date selection | Time period |

### Log Entry Details
- **Action:** What was done (CREATE, UPDATE, DELETE, APPROVE, REJECT)
- **Resource:** What was affected (Order ORD-5821, Product SKU-2451)
- **Status:** Success (green) or Failed (red)
- **Details:** Description of change
- **User:** Who performed action + their role
- **IP Address:** Source IP address
- **Timestamp:** Date and time of action

---

## User Role Definitions

| Role | Description | Permissions |
|------|-------------|-------------|
| admin | Platform administrator | Full access to control tower |
| superAdmin | Super administrator | Full system access (optional) |
| franchisee | Franchise store owner | Manage store, inventory, staff |
| institutionalBuyer | B2B institutional buyer | Create POs, manage contracts |
| warehouseStaff | Warehouse employee | Pick, pack, QC operations |
| driver | Delivery driver | Route, delivery tracking, POD |
| member | Member buyer | Enhanced retail pricing |
| consumer | Regular customer | Standard retail shopping |

---

## Common Admin Tasks

### Create New User
1. Go to `/admin/users`
2. Click FAB "+" button
3. Enter: Name, Email, Phone
4. Select roles (checkboxes)
5. Click "Create"
6. See green snackbar confirmation

### Edit User Account
1. Find user in list (search/filter)
2. Click "Edit" button on user card
3. Update fields as needed
4. Change roles if needed
5. Click "Update"

### Deactivate User
1. Find user in list
2. Click "Deactivate" button
3. Confirm in dialog
4. User status changes to "Inactive"

### Approve Price Override
1. Go to `/admin/approvals`
2. Review pending overrides
3. Check price change (current → requested)
4. Click "Approve"
5. Change applied immediately

### Search Audit Logs
1. Go to `/admin/audit-logs`
2. Enter search term (user ID, resource ID, or IP)
3. Apply filters as needed (action, type, status, date)
4. Results update in real-time
5. View complete context for each action

### Monitor Compliance
1. Go to `/admin/compliance`
2. Check overall score
3. Review category breakdowns
4. Click issue to see details
5. Click "Mark Resolved" when fixed

---

## Data Models Quick Reference

### AdminMetrics
```dart
totalUsers: 2543
activeUsers: 1847
priceOverridesPending: 12
complianceIssues: 3
auditLogsThisMonth: 5832
averageResponseTime: "Excellent"
```

### UserAccount
```dart
id: "user-001"
name: "John Doe"
email: "john@coop.com"
phone: "08012345678"
roles: [UserRole.consumer, UserRole.member]
isActive: true
createdAt: DateTime(2025, 6, 15)
lastLogin: DateTime.now().subtract(Duration(days: 2))
```

### ComplianceIssue
```dart
id: "issue-001"
type: "pricing"  // or inventory, delivery, fraud
severity: "warning"  // or critical, info
title: "Unusual Price Adjustment"
description: "Product SKU-2451 price increased 15% without override approval"
affectedEntity: "SKU-2451"
detectedAt: DateTime.now().subtract(Duration(hours: 2))
status: "open"  // or acknowledged, resolved
```

### AuditLogEntry
```dart
id: "audit-001"
userId: "admin-001"
userRole: "admin"
action: "approve"  // or create, update, delete, reject
resourceType: "price"  // or user, order, product, franchise
resourceId: "override-001"
details: "Approved price override for SKU-2451: ₦50,000 → ₦45,000"
timestamp: DateTime.now().subtract(Duration(hours: 2))
status: "success"  // or failed
ipAddress: "192.168.1.100"
```

---

## RBAC Protection

All admin routes require:
- **Role:** `admin` OR `superAdmin`
- **Redirect:** Non-admins redirected to `/login`
- **Implementation:** Checked in route redirect callback

```dart
redirect: (context, state) {
  if (!_hasRole(context, UserRole.admin) &&
      !_hasRole(context, UserRole.superAdmin)) {
    return '/login';
  }
  return null;
}
```

---

## Color Coding Reference

### Status Colors
- **Green:** Active, Success, Healthy
- **Red:** Critical, Failed, Error, Deactivate
- **Orange:** Warning, Pending, Caution
- **Grey:** Inactive, Unknown, Neutral

### Compliance Score Colors
- **Green:** Score ≥ 85 (Excellent)
- **Orange:** Score 70-85 (Good)
- **Red:** Score < 70 (Needs work)

---

## File Locations

```
lib/features/admin/
├── admin_control_tower_home_screen.dart (350 LOC)
├── admin_user_management_screen.dart (380 LOC)
├── admin_compliance_dashboard_screen.dart (420 LOC)
├── admin_audit_log_browser_screen.dart (420 LOC)
└── price_override_admin_dashboard.dart (742 LOC)

lib/config/
└── router.dart (admin routes: lines ~820-870)
```

---

## Integration Checklist

- ✅ 5 screens created
- ✅ All screens compile (0 errors)
- ✅ Router.dart updated with 5 routes
- ✅ RBAC checks in place
- ✅ Navigation functional
- ✅ Data models complete
- ✅ State management with Riverpod
- ✅ Documentation complete

---

## Next Steps

1. **Backend Integration**
   - Replace mock data providers with actual service calls
   - Implement userService, complianceService, auditService

2. **Admin Home Screen Integration**
   - Add Admin Control Tower to admin home screen
   - Create persistent admin navigation menu

3. **Additional Features** (Future)
   - System configuration management
   - Advanced reporting and analytics
   - Bulk user import/export
   - Automated compliance alerts

---

**Feature #18: Admin Control Tower → 100% Complete**
