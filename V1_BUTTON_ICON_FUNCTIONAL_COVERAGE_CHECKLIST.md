# V1 Button/Icon Functional Coverage Checklist

Date: 2026-05-25
Scope: Active routed v1 experiences with strict focus on visible button/icon interactions for member, seller, wholesale, and admin users.

## Audit Method

- Route scope validated from role router flow and active role screens.
- Static pattern scan run against active files for non-functional handlers:
	- `onTap: () {}`
	- `onPressed: () {}`
	- `onTap: null`
	- `onPressed: null`
	- `Coming Soon`
- Result for active role/home/header screens: no remaining no-op/coming-soon handlers detected.

## Shared Navigation and Header (All Roles)

Files:
- lib/features/home/scaffold_with_navbar.dart
- lib/widgets/app_header_utility.dart
- lib/config/router.dart

Coverage:
- [x] Bottom navigation icons switch to real role tabs.
- [x] Header profile entry opens user profile route.
- [x] Header search icon opens search flow.
- [x] Header notifications icon opens notifications route.
- [x] Compact header search submit and close are functional.
- [x] Route-level screen-view telemetry is emitted on navigation changes.
- [x] Header and bottom-nav button tap telemetry is emitted.

## Member Role

Primary route target:
- lib/features/home/role_screens/member_home_screen.dart

Coverage:
- [x] Hero/featured product cards open product detail.
- [x] Category and quick action controls navigate to live routes.
- [x] Cart and purchase-intent actions trigger real add-to-cart/checkout paths.
- [x] Profile and settings-related role actions route to live screens.
- [x] No no-op icon/button handlers found in active member home file.

## Seller Role

Primary route target:
- lib/features/selling/seller_home_screen.dart

Coverage:
- [x] Dashboard quick actions route to seller operational screens.
- [x] Product/catalog actions open real management flows.
- [x] Orders/messages/earnings entries are clickable and routed.
- [x] No no-op icon/button handlers found in active seller home file.

## Wholesale Role

Primary route target:
- lib/features/home/role_screens/wholesale_buyer_home_screen.dart

Coverage:
- [x] Mode tabs are all functional:
	- Discover tab routes to dashboard.
	- Wholesale active tab gives immediate runtime feedback.
	- Orders tab routes to orders screen.
- [x] Search actions are functional.
- [x] Product and category interactions are functional.
- [x] No no-op icon/button handlers found in active wholesale home file.

## Admin Role

Primary route target:
- lib/features/home/role_screens/admin_home_screen_v2.dart

Coverage:
- [x] Admin dashboard quick links route to live admin sections.
- [x] Approvals/compliance/audit/analytics entries are clickable.
- [x] No no-op icon/button handlers found in active admin home file.

## Institutional Role (Included in v1 operational scope)

Primary route target:
- lib/features/home/role_screens/institutional_buyer_home_screen_v2.dart

Coverage:
- [x] PO creation/list/detail actions are clickable and routed.
- [x] Product/category interactions are clickable.
- [x] No no-op icon/button handlers found in active institutional home file.

## Permission and Write-Safety Alignment

File:
- firestore.rules

Coverage:
- [x] Activity collections use owner/admin access patterns.
- [x] Legacy permissive rules were hardened for key user-owned collections in v1 paths.

## Offline and Resilience Coverage for Real-Time UX

Files:
- lib/core/services/local_cache_service.dart
- lib/core/providers/product_providers.dart
- lib/core/providers/home_providers.dart
- lib/core/providers/order_providers.dart

Coverage:
- [x] Products read path includes cache fallback.
- [x] Member home data includes cache fallback.
- [x] User order history includes cache fallback.

## Remaining Non-Blocking Work (Post-v1 Hardening)

1. Device evidence pass for each role home icon/button with screenshots per action.
2. Full backend live-data validation for institutional invoice/budget extensions.
3. Expand button-level telemetry to secondary legacy screens not in active routed v1 paths.
