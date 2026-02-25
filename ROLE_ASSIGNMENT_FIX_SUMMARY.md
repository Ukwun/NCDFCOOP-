# Role Assignment Fix Summary

## Issue
When users signed up, the system wasn't consistently applying email-based role assignment. The registration process would accept a role parameter but didn't have a fallback mechanism to assign roles based on email patterns.

## Solution Implemented
Updated the `_registerWithMock` method in [lib/core/api/auth_service.dart](lib/core/api/auth_service.dart#L354) to implement a hierarchical role assignment logic:

### Role Assignment Priority (during signup):
1. **Explicit Role** (if provided and not 'consumer') → Use the role provided during signup
2. **Email-Based Role** (fallback) → Check email pattern and assign appropriate role
3. **Default** → Assign 'consumer' role

### Email Pattern Detection
The `_assignRolesByEmail` function checks for keywords in the email address and assigns roles accordingly:

| Email Keyword | Assigned Role(s) |
|---------------|-----------------|
| `admin` | Admin (overrides others) |
| `superadmin` | Super Admin (overrides everything) |
| `member` | Consumer + CoopMember |
| `franchise` | Consumer + FranchiseOwner |
| `store` | Consumer + StoreManager |
| `institution`, `buyer` | Consumer + InstitutionalBuyer |
| `approver` | Consumer + InstitutionalApprover |
| `warehouse` | Consumer + WarehouseStaff |
| `driver` | Consumer + DeliveryDriver |
| (none) | Consumer (default) |

## Consistency
- **Mock/Offline Mode**: ✅ Now uses email-based role assignment as fallback
- **Login** (`_loginWithMock`): ✅ Already uses `_assignRolesByEmail` 
- **Production** (`signInWithGoogle`, etc.): Uses backend response, but falls back to mock on failure

## Examples

### Signup with Email Pattern
```
Email: member@company.com
No explicit role provided
Result: consumer + coopMember roles assigned
```

### Signup with Explicit Role
```
Email: plain@example.com
Explicit role: 'franchiseOwner'
Result: franchiseOwner role assigned (email pattern ignored)
```

### Signup Admin Email (Explicit Role Ignored)
```
Email: admin@example.com
Explicit role: 'member' (provided)
Result: Still gets admin role because admin@example.com matches admin pattern
```

## Test Cases
To verify the fix is working:

1. **Test Email Patterns**
   - Sign up with `admin@test.com` → Should get admin role
   - Sign up with `member@test.com` → Should get coopMember role
   - Sign up with `plain@test.com` → Should get consumer role

2. **Test Explicit Role Priority**
   - Sign up with `franchise@test.com` + explicit role 'storeManager' → Should get storeManager role
   - Sign up with `plain@test.com` + explicit role 'franchiseOwner' → Should get franchiseOwner role

3. **Test Admin Override**
   - Sign up with `admin@test.com` + explicit role 'member' → Should still get admin role (admin overrides)

## Files Modified
- [lib/core/api/auth_service.dart](lib/core/api/auth_service.dart) - Updated `_registerWithMock` method

## Status
✅ Complete - Role assignment now properly applies email-based patterns during signup with proper fallback hierarchy.
