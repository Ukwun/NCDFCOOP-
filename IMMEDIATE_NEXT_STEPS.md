# NEXT IMMEDIATE ACTIONS - Start Here 👇

## 🎯 WHAT TO DO RIGHT NOW

You have a **complete backend** with a **65% finished project**. Now it's time to build the **UI screens** using your Figma/design files.

---

## ✅ STEP 1: Organize Your Design Assets (30 min)

### Do This First:
1. **Gather all Figma designs/mockups** for:
   - Product Detail screen
   - Cart screen
   - Checkout screens
   - Payment forms
   - Order confirmation
   - User profile screens

2. **Extract Design Tokens:**
   ```dart
   // Already done in lib/theme/app_theme.dart:
   ✅ Colors: Green, Gold, Orange
   ✅ Typography: 12 text styles
   ✅ Spacing: 8px base unit
   ✅ Radius: Border radiuses
   ✅ Shadows: Elevations
   
   // Check if you need additions:
   - Component-specific colors?
   - Additional text styles?
   - Custom animations?
   ```

3. **Document Design Specifications:**
   - Button styles
   - Card styles
   - Input field styles
   - Dialog styles
   - Loading indicators

---

## 🚀 STEP 2: Start with ProductDetailScreen (2-3 hours)

### Create the file:
```bash
touch lib/features/products/product_detail_screen.dart
```

### Basic structure to build:
```dart
class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  
  // 1. Create ViewModel with Riverpod
  // Watch: productProvider (fetch from API)
  // Watch: cartProvider (for add to cart)
  
  // 2. Handle states:
  // - Loading: Show skeleton/shimmer
  // - Error: Show error message with retry
  // - Data: Show full product UI
  
  // 3. Build widgets from your design:
  // - Product image with PageView
  // - Member vs Market pricing
  // - Ratings and reviews
  // - "Add to Cart" button
  // - Related products carousel
}
```

### Integration points with your backend:
```dart
// 1. Get product data
final productAsync = ref.watch(productProvider(productId));

// 2. Add to cart
ref.read(cartProvider.notifier).addItem(product);

// 3. Handle product images
// Use cached_network_image for performance

// 4. Show member savings
// Use PriceTag widget from existing widgets
```

---

## 🛒 STEP 3: Build CartDisplayScreen (1-2 hours)

```dart
class CartDisplayScreen extends ConsumerWidget {
  // 1. Watch cart state
  final cartState = ref.watch(cartProvider);
  
  // 2. Build cart items list
  // - Product image + name
  // - Quantity controls (+/-)
  // - Remove button
  // - Item total price
  
  // 3. Show summary
  // - Subtotal
  // - Total savings
  // - Final total
  
  // 4. Checkout button
  // - Navigate to CheckoutScreen
}
```

---

## 💳 STEP 4: Build CheckoutScreen (2-3 hours)

```dart
class CheckoutScreen extends ConsumerWidget {
  // 1. Shipping address form
  // - Street, city, state, zip
  // - Form validation
  
  // 2. Delivery method selection
  // - Standard vs Express
  // - Different pricing
  
  // 3. Promo code input
  // - Input field
  // - Apply button
  // - Show discount
  
  // 4. Order summary
  // - Items recap
  // - Totals with fees
  
  // 5. Proceed to payment button
  // - Navigate to PaymentFormScreen
  // - Pass order data
}
```

---

## 💰 STEP 5: Build PaymentFormScreen (2-3 hours)

```dart
class PaymentFormScreen extends ConsumerWidget {
  // 1. Payment method selector
  // - Card
  // - Bank Transfer
  // - USSD/Mobile Wallet
  
  // 2. Show appropriate form based on method
  // - Card: card number, expiry, CVV
  // - Bank: bank code, account number
  // - USSD: phone number
  
  // 3. Validate inputs
  // - Use PaymentHelper validation
  // - Show error messages
  
  // 4. Process payment button
  // - Call paymentController.processPayment()
  // - Show loading
  // - Handle success/error
  // - Navigate to confirmation or retry
}
```

---

## 📋 CHECKLIST FOR EACH SCREEN

When building any screen, follow this checklist:

### Design Integration
- [ ] Colors from AppTheme
- [ ] Fonts from AppTextStyles
- [ ] Spacing from AppSpacing
- [ ] Radius from AppRadius
- [ ] Shadows from AppShadows

### State Management
- [ ] Create/use Riverpod provider
- [ ] Handle loading state with skeleton/spinner
- [ ] Handle error state with error message
- [ ] Handle data state with UI
- [ ] Watch provider in widget

### Data Integration
- [ ] Call appropriate service method
- [ ] Map response to model
- [ ] Handle null/empty cases
- [ ] Show user-friendly errors

### User Interactions
- [ ] Button onPressed handlers
- [ ] Form validation
- [ ] Loading indicators during async
- [ ] Success/error feedback
- [ ] Navigation to next screen

### Performance
- [ ] Use const widgets
- [ ] Lazy load images
- [ ] Cache data appropriately
- [ ] Avoid unnecessary rebuilds

### Testing
- [ ] Test with mock data
- [ ] Test error scenarios
- [ ] Test empty states
- [ ] Test form validation

---

## 🔗 YOUR EXISTING COMPONENTS TO USE

### Already Built:
```dart
// 1. PriceTag Widget
// Shows member price, market price (strikethrough), savings
import 'package:coop_commerce/widgets/price_tag.dart';

// 2. App Theme
import 'package:coop_commerce/theme/app_theme.dart';
AppColors.primary        // Green
AppColors.accent         // Gold
AppColors.secondary      // Orange
AppTextStyles.headline1   // etc.

// 3. Router
import 'package:coop_commerce/config/router.dart';
context.go('/product/123');

// 4. Cart Provider
import 'package:coop_commerce/providers/cart_provider.dart';
ref.watch(cartProvider);
ref.watch(cartTotalPriceProvider);
ref.watch(cartSavingsPercentageProvider);

// 5. Payment System
import 'package:coop_commerce/core/payments/payment_provider.dart';
import 'package:coop_commerce/core/payments/payment_helper.dart';
```

---

## 🎨 RECOMMENDED COMPONENT LIBRARY TO CREATE

Before building screens, create reusable components:

```dart
// lib/shared/widgets/buttons/
- primary_button.dart       // Green button
- secondary_button.dart     // Outline button
- tertiary_button.dart      // Text button

// lib/shared/widgets/cards/
- product_card.dart         // Product in grid
- order_card.dart           // Order item
- summary_card.dart         // Price summary

// lib/shared/widgets/forms/
- text_input.dart           // Text field
- card_form.dart            // Card number, expiry, CVV
- address_form.dart         // Address fields

// lib/shared/widgets/loaders/
- loading_skeleton.dart     // Shimmer effect
- error_widget.dart         // Error display
- empty_widget.dart         // Empty state
```

### Example Primary Button:
```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : Text(text),
    );
  }
}
```

---

## 🏃 ACTION PLAN FOR THIS WEEK

### Monday (TODAY) - 2 hours
- [ ] Gather all design files
- [ ] Extract design tokens
- [ ] Create component library skeleton
- [ ] Start ProductDetailScreen

### Tuesday - 3 hours
- [ ] Complete ProductDetailScreen
- [ ] Test with mock data
- [ ] Style according to design
- [ ] Integrate with productService

### Wednesday - 3 hours
- [ ] Build CartDisplayScreen
- [ ] Implement quantity controls
- [ ] Show savings calculations
- [ ] Test cart provider integration

### Thursday - 3 hours
- [ ] Build CheckoutScreen
- [ ] Create address form
- [ ] Implement delivery selection
- [ ] Show order summary

### Friday - 3 hours
- [ ] Build PaymentFormScreen
- [ ] Integrate with paymentProvider
- [ ] Test payment flows
- [ ] Fix any bugs

**Total: ~14 hours → 3 complete screens**

---

## 🧪 HOW TO TEST

### Test ProductDetailScreen:
```dart
// 1. Hard-code product ID
const productId = '123';

// 2. Watch the mock data load
// Check home_viewmodel.dart for mock structure

// 3. Tap "Add to Cart"
// Check cartProvider state updates

// 4. Verify pricing calculations
```

### Test CartScreen:
```dart
// 1. Add multiple items to cart
// 2. Adjust quantities
// 3. Verify totals match calculations
// 4. Remove items
// 5. See empty cart state
```

### Test CheckoutScreen:
```dart
// 1. Fill in fake address
// 2. Select delivery method
// 3. Apply promo code (mock response)
// 4. See total update
// 5. Proceed to payment
```

### Test PaymentForm:
```dart
// Use test cards:
// Paystack: 4111 1111 1111 1111
// Flutterwave: 5399 8343 1234 5678

// Test validation:
// - Invalid card number → Show error
// - Missing CVV → Show error
// - Valid card → Show success
```

---

## 🐛 DEBUGGING TIPS

### Check if provider is working:
```dart
// Add debug print
ref.listen(cartProvider, (previous, next) {
  print('Cart updated: $next');
});
```

### Check API call:
```dart
// Look at Dio interceptor logs
// Check network tab in DevTools
// Verify service method called
```

### Check payment state:
```dart
// Watch payment provider
ref.watch(paymentControllerProvider(PaymentProvider.paystack))
```

---

## 📞 COMMON ISSUES & SOLUTIONS

### Issue: "Provider not found"
**Solution:** Check import path, ensure file exists

### Issue: "Build failed with widgets"
**Solution:** Wrap in Scaffold, check Consumer/ConsumerWidget

### Issue: "API returns null"
**Solution:** Check mock data in service, verify model mapping

### Issue: "Form validation not working"
**Solution:** Check PaymentHelper.validateCardNumber() return value

### Issue: "Button not responding"
**Solution:** Check ref.read() vs ref.watch(), ensure notifier method called

---

## 🎯 SUCCESS CRITERIA FOR EACH SCREEN

### ProductDetailScreen ✅
- [ ] Loads product data from API
- [ ] Displays member and market prices
- [ ] Shows savings percentage
- [ ] "Add to Cart" updates cartProvider
- [ ] Looks like your design mockup

### CartDisplayScreen ✅
- [ ] Lists all cart items
- [ ] Quantity +/- buttons work
- [ ] Remove button works
- [ ] Totals update correctly
- [ ] Checkout button navigates

### CheckoutScreen ✅
- [ ] Address form validates
- [ ] Delivery method selection works
- [ ] Promo code applies (if implemented)
- [ ] Order summary accurate
- [ ] Pay button navigates to payment

---

## 🚀 AFTER THIS WEEK

If you complete these 3 screens:

**Week 2:**
- CategoryScreen
- OrderConfirmationScreen
- OrderTrackingScreen

**Week 3:**
- ProfileScreen
- OrderHistoryScreen
- SavingsHistoryScreen

**Week 4:**
- LoginScreen
- RegisterScreen
- Email Verification

---

## 📚 DOCUMENTATION TO REFERENCE

```
READ THESE WHILE BUILDING:

1. lib/core/payments/README.md
   → Quick reference for payment system

2. lib/core/payments/INTEGRATION_GUIDE.md
   → How to use payment system in UI

3. lib/core/payments/payment_system_example.dart
   → 12 usage examples

4. PROJECT_ANALYSIS_AND_ROADMAP.md
   → Full project context (this document!)

5. PROJECT_VISUAL_STATUS.md
   → Visual diagrams and flows
```

---

## ✨ YOU'RE READY!

You have:
✅ Complete backend infrastructure  
✅ All API services configured  
✅ Payment system fully integrated  
✅ State management setup  
✅ Design system ready  

**Now just build the screens!**

Start with: **ProductDetailScreen** using your Figma design

Questions? Check the documentation files or look at existing code patterns.

**Let's go! 🚀**
