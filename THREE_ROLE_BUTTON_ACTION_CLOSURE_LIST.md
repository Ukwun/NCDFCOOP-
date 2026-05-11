# Three-Role Strict Button-to-Action Closure List

Date: 2026-05-10
Scope: Member, Wholesale Buyer, Seller only
Goal: No clickable element in production paths should be unresolved.

## Scope lock actions (must do first)

1. Keep only three user-facing role journeys in release navigation: member, wholesale buyer, seller.
2. Remove or hide non-scope role entry points from role selection and home routing before launch.
3. Consolidate to one active router map and delete or archive conflicting route maps.

## Closure rules

- Rule 1: Every onTap/onPressed must do one of: navigate to a real screen, execute a real service call, or be explicitly disabled with a reason text.
- Rule 2: No mock snackbar as final behavior for commerce-critical actions.
- Rule 3: No route call to a name/path missing from the active router.
- Rule 4: "Click to ..." text requires a real handler.

## File-by-file open items

### A) Member flow

1. File: lib/features/home/role_screens/member_home_screen.dart:986
- Element: _ReportItem row tap
- Current behavior: onTap is empty.
- Required closure: Route to report detail screen (or to member-transparency with report id).
- Priority: P0
- Owner: Mobile
- Done when: tap opens report content, analytics event logged, back navigation works.

2. File: lib/features/home/role_screens/member_home_screen.dart:440
- Element: Confirm Deposit button in _showDepositDialog
- Current behavior: TODO note and success snackbar only, no committed transaction.
- Required closure: Call savings deposit service/provider and persist transaction.
- Priority: P0
- Owner: Mobile + Backend
- Done when: balance and transaction history update from backend source of truth.

3. File: lib/features/home/role_screens/member_home_screen.dart:489
- Element: Confirm Withdrawal button in _showWithdrawDialog
- Current behavior: snackbar only, no withdrawal workflow.
- Required closure: Implement withdrawal request API call with status tracking.
- Priority: P0
- Owner: Mobile + Backend
- Done when: withdrawal record created and status visible to member.

4. File: lib/features/home/role_screens/member_home_screen.dart:722
- Element: Vote action (context.pushNamed('member-voting'))
- Current behavior: route name exists only in a non-active router map.
- Required closure: Add member-voting route to active router (lib/config/router.dart) or change button to existing active route.
- Priority: P0
- Owner: Mobile
- Done when: button opens voting screen in production build.

5. File: lib/features/home/role_screens/member_home_screen.dart:749
- Element: View All transparency action (context.pushNamed('member-transparency'))
- Current behavior: route name exists only in a non-active router map.
- Required closure: Add member-transparency route to active router (lib/config/router.dart) or change button to existing active route.
- Priority: P0
- Owner: Mobile
- Done when: button opens transparency screen in production build.

6. File: lib/features/member/member_loyalty_screen.dart:243
- Element: Redemption option tap
- Current behavior: mock handler comment only.
- Required closure: invoke redemption flow with points validation, confirmation, and ledger update.
- Priority: P1
- Owner: Mobile + Backend
- Done when: points decrement and redemption record created.

7. File: lib/features/benefits/flash_sales_page.dart:162
- Element: Enable Notifications button
- Current behavior: empty onPressed.
- Required closure: trigger push-notification permission + subscription workflow.
- Priority: P1
- Owner: Mobile
- Done when: permission result handled and topic/device subscription persisted.

8. File: lib/features/benefits/community_dividends_page.dart:162
- Element: Withdraw Now button
- Current behavior: empty onPressed.
- Required closure: open dividend withdrawal form and submit request.
- Priority: P1
- Owner: Mobile + Backend
- Done when: request created and status is trackable.

9. File: lib/features/benefits/bulk_access_page.dart:134
- Element: Contact Wholesale Team button
- Current behavior: empty onPressed.
- Required closure: open support channel (chat/call/email form) with prefilled context.
- Priority: P1
- Owner: Mobile + Ops
- Done when: contact ticket/message is created.

### B) Wholesale buyer flow

10. File: lib/features/checkout/screens/payment_form_screen.dart:106
- Element: Process payment action
- Current behavior: TODO + simulated delay + mock success snackbar.
- Required closure: call real payment gateway flow and navigate to payment status callback result.
- Priority: P0
- Owner: Mobile + Payments + Backend
- Done when: successful real transaction updates order payment state.

11. File: lib/features/orders/enhanced_order_tracking_screen.dart:252
- Element: Track Delivery button
- Current behavior: mock snackbar.
- Required closure: open live delivery tracker map/status.
- Priority: P1
- Owner: Mobile + Logistics
- Done when: user can see live/last-known delivery status details.

12. File: lib/features/orders/enhanced_order_tracking_screen.dart:272
- Element: Contact Seller button
- Current behavior: mock snackbar.
- Required closure: open real seller communication flow.
- Priority: P1
- Owner: Mobile + Messaging
- Done when: conversation/request reaches seller inbox.

### C) Seller flow

13. File: lib/features/selling/seller_home_screen.dart:13
- Element: Seller home entry
- Current behavior: placeholder "Coming soon" scaffold.
- Required closure: replace with real seller dashboard container bound to seller providers.
- Priority: P0
- Owner: Mobile
- Done when: seller can view products, statuses, and perform seller actions from home.

14. File: lib/features/selling/seller_onboarding_screen.dart:66
- Element: Seller dashboard product tap callback
- Current behavior: callback passed as no-op.
- Required closure: route to seller product detail/edit screen.
- Priority: P1
- Owner: Mobile
- Done when: tapping product opens actionable detail screen.

15. File: lib/features/selling/screens/product_upload_screen.dart:211
- Element: Image upload CTA area
- Current behavior: text says "Click to upload" but no tap handler/file picker.
- Required closure: wire file picker/camera and upload to storage.
- Priority: P1
- Owner: Mobile + Backend
- Done when: image URL persists and preview renders.

16. File: lib/features/selling/seller_onboarding_quick_screen.dart:282
- Element: Complete Setup action
- Current behavior: snackbar + go home; no persisted seller onboarding write in this quick flow.
- Required closure: save seller profile in backend before success navigation.
- Priority: P0
- Owner: Mobile + Backend
- Done when: seller profile exists and is retrievable after app restart/login.

17. File: lib/features/seller/seller_profile_screen.dart:517
- Element: Buy button in seller profile product list
- Current behavior: empty onPressed.
- Required closure: add to cart or go to product detail/checkout.
- Priority: P1
- Owner: Mobile
- Done when: button causes real commerce action.

## Cross-cutting closure blockers

18. File: lib/main.dart:3 and lib/config/router.dart:1
- Issue: app boots with lib/config/router.dart while member-voting and member-transparency are defined in lib/core/navigation/app_router.dart.
- Required closure: unify route ownership and remove route drift.
- Priority: P0
- Owner: Mobile
- Done when: all pushNamed/goNamed targets resolve in one active router.

## Release gate for this list

- Gate A: 0 empty handlers in in-scope files.
- Gate B: 0 mock/coming-soon actions in in-scope user paths.
- Gate C: 100% route resolution for all in-scope navigation calls.
- Gate D: each closed item has one passing device test and one backend verification proof.
