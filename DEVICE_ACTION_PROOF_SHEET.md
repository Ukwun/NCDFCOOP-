# Device Action Proof Sheet (V1)

Date: 2026-05-25
Build Scope: Realistic button/icon behavior verification for active role flows
Status: Compiled from existing on-device screenshot artifacts in workspace

## Runtime Note

- ADB live capture attempt during this pass returned no connected devices.
- This proof sheet maps validated artifacts already generated in the workspace.
- Reproducible live recapture script added at scripts/capture_device_evidence.ps1.

## Shared Navigation Evidence

| Action | Expected Real Behavior | Evidence |
|---|---|---|
| Bottom nav Categories tap | Moves to categories tab content in real time | [coop_nav_categories_live.png](coop_nav_categories_live.png) |
| Bottom nav Messenger tap | Moves to messenger tab content in real time | [coop_nav_messenger_live.png](coop_nav_messenger_live.png) |
| Bottom nav Cart tap | Moves to cart tab content in real time | [coop_nav_cart_live.png](coop_nav_cart_live.png) |
| Bottom nav Profile/My Coop tap | Moves to profile tab content in real time | [coop_tab_profile.png](coop_tab_profile.png) |

## Member Flow Evidence

| Action | Expected Real Behavior | Evidence |
|---|---|---|
| Home loads products immediately | Product cards and sections render (no blank frames) | [final_home_products.png](final_home_products.png) |
| Product card tap | Opens product detail screen | [product_detail.png](product_detail.png) |
| Category chips/taps | Filters and category views update | [vegetables_category.png](vegetables_category.png), [grains_category.png](grains_category.png), [dairy_category.png](dairy_category.png) |
| Price sort/filter action | Product ordering/filter state changes | [price_sorted.png](price_sorted.png), [ui_perfect_filters_work.png](ui_perfect_filters_work.png) |
| Profile utility navigation | Profile screen opens and remains interactive | [profile_screen.png](profile_screen.png), [profile_scrolled.png](profile_scrolled.png) |
| Settings navigation and toggles | Settings screen opens and toggleable states are visible | [settings_screen.png](settings_screen.png), [settings_dark.png](settings_dark.png) |

## Messaging and Cart Evidence

| Action | Expected Real Behavior | Evidence |
|---|---|---|
| Messenger entry from nav | Conversation/messaging view opens | [coop_test_messenger.png](coop_test_messenger.png), [coop_tab_messenger.png](coop_tab_messenger.png) |
| Cart entry from nav | Cart page opens from nav icon | [coop_tab_cart.png](coop_tab_cart.png), [cart_dark.png](cart_dark.png) |

## Visual State Reliability Evidence

| Action | Expected Real Behavior | Evidence |
|---|---|---|
| App wake/reopen | App resumes and UI remains functional | [coop_after_wake.png](coop_after_wake.png), [coop_recheck.png](coop_recheck.png) |
| Theme switch behavior | Dark and light states render correctly | [dark_mode_on.png](dark_mode_on.png), [light_mode_restored.png](light_mode_restored.png), [home_light_restored.png](home_light_restored.png) |
| Final quality check screen | Stable home after fixes | [real_home_final.png](real_home_final.png), [app_final_screenshot.png](app_final_screenshot.png) |

## Route/Interaction Logging Coverage (Code-Backed)

- Route-level screen-view events enabled in [lib/config/router.dart](lib/config/router.dart).
- Header icon taps and search interactions instrumented in [lib/widgets/app_header_utility.dart](lib/widgets/app_header_utility.dart).
- Bottom-nav interaction telemetry instrumented in [lib/features/home/scaffold_with_navbar.dart](lib/features/home/scaffold_with_navbar.dart).

## Remaining Step To Complete Live Proof Run

1. Connect device and verify with adb devices.
2. Run scripts/capture_device_evidence.ps1 to capture fresh screenshots into /evidence.
3. Update this sheet with fresh dated captures for each role session.
