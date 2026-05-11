# Three-Role Production Test Script

Date: 2026-05-10
Scope: Member, Wholesale Buyer, Seller only
Environment: Production-like backend, production Firebase project, release build

## Test execution policy

- Run on at least 2 physical Android devices (mid-tier and low-tier) plus 1 emulator.
- Execute with stable network and degraded network (3G simulation).
- Capture evidence for every failed or blocked step: screenshot + log + order/user id.
- If any P0 test fails, stop rollout.

## Shared preconditions

1. Release build installed and signed.
2. Correct production app id and config.
3. Test accounts prepared:
- member_user_01
- wholesale_user_01
- seller_user_01
4. Seed data prepared:
- At least 10 products in stock
- One low-stock product
- One promo product
5. Payments configured for production test merchant.
6. Push notifications enabled in project and device.

## Script 1: Member role

### 1.1 Login and role landing
- Step: Login with member_user_01.
- Expected: Lands on member home, member-specific sections visible (tier, points, voting, transparency).

### 1.2 Loyalty card actions
- Step: Tap Redeem.
- Expected: Rewards screen opens, no route error.

### 1.3 Savings flows
- Step: Tap Deposit Money to Savings, enter valid amount, confirm.
- Expected: backend transaction created, balance updates.
- Verify: transaction exists in savings collection/history.

- Step: Tap Quick Withdraw, enter valid amount, confirm.
- Expected: withdrawal request persisted with status.
- Verify: request visible in user history and backend.

### 1.4 Governance flows
- Step: Tap Vote.
- Expected: Voting dashboard opens and proposals load.

- Step: Tap View All in transparency.
- Expected: Transparency report screen opens.

- Step: Tap a report item card/row.
- Expected: Report detail opens (or anchored view in transparency screen).

### 1.5 Benefits pages
- Step: Open Flash Sales page and tap Enable Notifications.
- Expected: permission/subscription flow executes, result persisted.

- Step: Open Community Dividends and tap Withdraw Now.
- Expected: withdrawal form/process opens and submits.

- Step: Open Bulk Access and tap Contact Wholesale Team.
- Expected: support contact flow opens and sends message/request.

## Script 2: Wholesale Buyer role

### 2.1 Login and home actions
- Step: Login with wholesale_user_01.
- Expected: Lands on wholesale home (consumer home variant), search and categories are interactive.

### 2.2 Browse and cart
- Step: Search product, open product detail, add to cart.
- Expected: cart count updates and item appears in cart.

### 2.3 Checkout and payment
- Step: Proceed through checkout and submit payment using configured method.
- Expected: real payment flow starts and returns definitive status.
- Verify: payment record + order payment status updated to success/failure correctly.

### 2.4 Post-order tracking and seller contact
- Step: Open enhanced tracking, tap Track Delivery.
- Expected: live tracker map/status view opens.

- Step: Tap Contact Seller.
- Expected: messaging/contact thread opens and message can be sent.

## Script 3: Seller role

### 3.1 Login and seller home
- Step: Login with seller_user_01.
- Expected: Seller sees real dashboard (not coming-soon placeholder).

### 3.2 Seller onboarding quick path
- Step: Complete onboarding quick steps and submit.
- Expected: seller profile persisted before navigation.
- Verify: seller profile exists in backend and survives relogin.

### 3.3 Product upload
- Step: Add product with image upload.
- Expected: image picker opens, upload succeeds, product saved with image URL.

### 3.4 Product lifecycle
- Step: Open product from dashboard list.
- Expected: product detail/edit screen opens.

- Step: Confirm pending/approved states are visible and accurate.
- Expected: status badges match backend moderation state.

### 3.5 Seller profile commerce action
- Step: From seller profile listing, tap Buy button.
- Expected: navigates to product detail/add-to-cart flow, not no-op.

## Intelligence and telemetry checks (all 3 roles)

For each role execute at least one event in each category and verify ingestion:

1. Screen viewed event
2. Product viewed event
3. Add-to-cart event
4. Checkout started event
5. Order placed event
6. Role-specific action event:
- Member: vote or transparency open
- Wholesale: bulk/reorder/checkout action
- Seller: product upload or profile completion

Expected:
- Events contain user id, role, timestamp, and object ids.
- Events are queryable in analytics within expected delay window.

## Pass/fail matrix

Mark each line item as PASS, FAIL, or BLOCKED.

- Member critical tests: 1.3, 1.4
- Wholesale critical tests: 2.3
- Seller critical tests: 3.1, 3.2, 3.3
- Telemetry critical tests: all six event categories

Go-live rule:
- Any FAIL in critical tests = no release.
- Any BLOCKED in critical tests = no release.
- Non-critical failures must have approved rollback/mitigation before release.
