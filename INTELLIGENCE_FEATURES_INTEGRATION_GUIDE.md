/// INTELLIGENCE FEATURES INTEGRATION GUIDE
/// ============================================================================
///
/// This guide explains how to integrate the 4 new intelligence systems
/// into your existing screens and services.
///
/// FEATURES ADDED:
/// 1. User Activity Tracking - Comprehensive event logging
/// 2. Order Intelligence - Churn prediction, delivery forecasting, demand analysis
/// 3. Dynamic Pricing - Segment & demand-based pricing
/// 4. Personalization - Smart recommendations & churn recovery
///
/// ============================================================================
/// QUICK START
/// ============================================================================
///
/// All services are singleton instances - use them like this:
///
///   // In any screen or service:
///   import 'package:coop_commerce/providers/intelligence_providers.dart';
///
///   // Track an event (needs context with WidgetRef)
///   ref.read(trackProductViewedProvider((productId, productName, category, price)));
///
///   // Get recommendations
///   final recs = await ref.read(personalizedRecommendationsProvider.future);
///
/// ============================================================================
/// FILE INTEGRATION CHECKLIST
/// ============================================================================
///
/// ADD TRACKING TO THESE EXISTING FILES:
///
/// [ ] lib/features/products/product_detail_screen.dart
///     - Add: trackProductViewed when screen loads
///     - Add: show similarProducts recommendations
///     - Add: show dynamicPrice widget
///
/// [ ] lib/features/cart/cart_screen.dart
///     - Add: trackAddedToCart when user taps add
///     - Add: show abandonedCartRecovery products
///
/// [ ] lib/features/checkout/checkout_screen_v2.dart
///     - Add: trackCheckoutStarted at beginning
///     - Add: show recommend_drivers for order
///
/// [ ] lib/features/orders/order_detail_screen.dart
///     - Add: trackOrderViewed when opened
///     - Add: show deliveryPrediction
///
/// [ ] lib/features/home/home_screen_v2.dart
///     - Add: show personalizedRecommendations
///     - Add: show churnRecoveryProducts if at risk
///     - Add: trackScreenViewed on load
///
/// [ ] lib/core/api/checkout_service.dart
///     - Add: trackOrderPlaced after successful order
///
/// [ ] lib/admin/admin_dashboard.dart
///     - Add: show demandForecasts for inventory planning
///     - Add: show churnRiskAnalysis
///
/// ============================================================================
/// DETAILED INTEGRATION EXAMPLES
/// ============================================================================
///
/// EXAMPLE 1: Track Product View (Product Detail Screen)
/// ─────────────────────────────────────────────────────────────────────────
///
/// class ProductDetailScreen extends ConsumerWidget {
///   final Product product;
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     // Track product view when screen first loads
///     ref.read(trackProductViewedProvider((
///       productId: product.id,
///       productName: product.name,
///       category: product.category,
///       price: product.price,
///     )).asStream();
///
///     // Reset in effect if needed
///     useEffect(() {
///       Future.microtask(() {
///         ref.read(trackProductViewedProvider((
///           productId: product.id,
///           productName: product.name,
///           category: product.category,
///           price: product.price,
///         )));
///       });
///       return null;
///     }, [product.id]);
///
///     // Show similar products
///     return Column(
///       children: [
///         // ... product details ...
///
///         // Add recommendations section
///         Padding(
///           padding: const EdgeInsets.all(16),
///           child: Text('Similar Products',
///               style: Theme.of(context).textTheme.headlineSmall),
///         ),
///         SimilarProductsSection(productId: product.id),
///       ],
///     );
///   }
/// }
///
/// // Helper widget for similar products
/// class SimilarProductsSection extends ConsumerWidget {
///   final String productId;
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final similarsAsync = ref.watch(similarProductsProvider(productId));
///
///     return similarsAsync.when(
///       data: (similars) {
///         if (similars.isEmpty) return const SizedBox.shrink();
///         return SizedBox(
///           height: 200,
///           child: ListView.builder(
///             scrollDirection: Axis.horizontal,
///             itemCount: similars.length,
///             itemBuilder: (context, index) {
///               final rec = similars[index];
///               return ProductCard(
///                 product: rec.product,
///                 reason: rec.reason,
///               );
///             },
///           ),
///         );
///       },
///       loading: () => const CircularProgressIndicator(),
///       error: (err, st) => const SizedBox.shrink(),
///     );
///   }
/// }
///
/// ─────────────────────────────────────────────────────────────────────────
///
/// EXAMPLE 2: Show Dynamic Pricing (Product Card)
/// ─────────────────────────────────────────────────────────────────────────
///
/// class ProductCard extends ConsumerWidget {
///   final Product product;
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final dynamicPriceAsync = ref.watch(dynamicPriceProvider((
///       productId: product.id,
///       basePrice: product.price,
///       currentStock: product.stock,
///       userId: null, // Will get current user in real impl
///     )));
///
///     return Card(
///       child: Column(
///         children: [
///           Image.network(product.imageUrl, height: 120),
///           Text(product.name),
///           dynamicPriceAsync.when(
///             data: (dynamicPrice) {
///               final hasDiscount = dynamicPrice.totalDiscountPercent > 0;
///               return Column(
///                 children: [
///                   if (hasDiscount)
///                     Text(
///                       '₦${dynamicPrice.basePrice.toStringAsFixed(0)}',
///                       style: TextStyle(
///                         decoration: TextDecoration.lineThrough,
///                         color: Colors.grey,
///                       ),
///                     ),
///                   Text(
///                     '₦${dynamicPrice.finalPrice.toStringAsFixed(0)}',
///                     style: const TextStyle(
///                       fontWeight: FontWeight.bold,
///                       fontSize: 16,
///                     ),
///                   ),
///                   if (hasDiscount)
///                     Text(
///                       'Save ${dynamicPrice.totalDiscountPercent.toStringAsFixed(1)}%',
///                       style: TextStyle(color: Colors.green),
///                     ),
///                   // Show pricing reason on hover/tap
///                   Text(
///                     dynamicPrice.reason,
///                     style: TextStyle(fontSize: 10, color: Colors.grey),
///                   ),
///                 ],
///               );
///             },
///             loading: () => Text('₦${product.price.toStringAsFixed(0)}'),
///             error: (_, __) => Text('₦${product.price.toStringAsFixed(0)}'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
///
/// ─────────────────────────────────────────────────────────────────────────
///
/// EXAMPLE 3: Track Checkout Flow
/// ─────────────────────────────────────────────────────────────────────────
///
/// class CheckoutScreenV2 extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     // Track checkout started when screen loads
///     ref.read(trackCheckoutStartedProvider((
///       cartTotal: cartService.getTotalPrice(),
///       itemCount: cartService.getItemCount(),
///     ))).asStream();
///
///     return Scaffold(
///       body: Column(
///         children: [
///           // Step 1: Address
///           // Step 2: Delivery
///           // Step 3: Payment
///           // Step 4: Review
///           ElevatedButton(
///             onPressed: () async {
///               // Track order placed on successful checkout
///               final orderId = await checkoutService.completeOrder();
///               ref.read(trackOrderPlacedProvider((
///                 orderId: orderId,
///                 orderValue: cartService.getTotalPrice(),
///                 productIds: cartService.getProductIds(),
///               )));
///             },
///             child: const Text('Complete Order'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
///
/// ─────────────────────────────────────────────────────────────────────────
///
/// EXAMPLE 4: Show Personalized Recommendations (Home Screen)
/// ─────────────────────────────────────────────────────────────────────────
///
/// class HomeScreenV2 extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final recsAsync = ref.watch(personalizedRecommendationsProvider);
///
///     return ListView(
///       children: [
///         // ... existing home content ...
///
///         // Add recommendations section
///         Padding(
///           padding: const EdgeInsets.all(16),
///           child: Text(
///             'Recommended For You',
///             style: Theme.of(context).textTheme.headlineSmall,
///           ),
///         ),
///         recsAsync.when(
///           data: (recommendations) {
///             if (recommendations.isEmpty) {
///               return const SizedBox.shrink();
///             }
///             return SizedBox(
///               height: 250,
///               child: ListView.builder(
///                 scrollDirection: Axis.horizontal,
///                 itemCount: recommendations.length,
///                 itemBuilder: (context, index) {
///                   final rec = recommendations[index];
///                   return Column(
///                     children: [
///                       if (rec.isMustSee)
///                         Chip(label: Text('🎯 Must See')),
///                       ProductCard(product: rec.product),
///                       Text(
///                         rec.reason,
///                         maxLines: 2,
///                         overflow: TextOverflow.ellipsis,
///                         style: TextStyle(fontSize: 12),
///                       ),
///                     ],
///                   );
///                 },
///               ),
///             );
///           },
///           loading: () => const Center(child: CircularProgressIndicator()),
///           error: (e, st) => const SizedBox.shrink(),
///         ),
///       ],
///     );
///   }
/// }
///
/// ─────────────────────────────────────────────────────────────────────────
///
/// EXAMPLE 5: Show Churn Risk Alert (Admin Dashboard)
/// ─────────────────────────────────────────────────────────────────────────
///
/// class AdminUserList extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ListView.builder(
///       itemBuilder: (context, index) {
///         final user = users[index];
///         final churnAsync = ref.watch(userChurnAnalysisProvider(user.id));
///
///         return churnAsync.when(
///           data: (churnAnalysis) {
///             final riskColor = _getRiskColor(churnAnalysis.riskLevel);
///             return ListTile(
///               title: Text(user.name),
///               subtitle: Text(churnAnalysis.riskLevel.displayName),
///               trailing: Container(
///                 padding: EdgeInsets.all(8),
///                 decoration: BoxDecoration(
///                   color: riskColor.withOpacity(0.2),
///                   borderRadius: BorderRadius.circular(8),
///                 ),
///                 child: Text(
///                   'Days inactive: ${churnAnalysis.daysSinceLastActivity}',
///                   style: TextStyle(color: riskColor),
///                 ),
///               ),
///             );
///           },
///           loading: () => ListTile(
///             title: Text(user.name),
///             subtitle: const CircularProgressIndicator(),
///           ),
///           error: (e, st) => ListTile(title: Text(user.name)),
///         );
///       },
///     );
///   }
///
///   Color _getRiskColor(ChurnRiskLevel level) {
///     switch (level) {
///       case ChurnRiskLevel.low:
///         return Colors.green;
///       case ChurnRiskLevel.medium:
///         return Colors.yellow;
///       case ChurnRiskLevel.high:
///         return Colors.orange;
///       case ChurnRiskLevel.critical:
///         return Colors.red;
///     }
///   }
/// }
///
/// ============================================================================
/// KEY THINGS TO REMEMBER
/// ============================================================================
///
/// 1. EVENT TRACKING
///    - Always track important user actions (views, clicks, purchases)
///    - Use FutureProvider with .asStream() in build methods
///    - Or use useEffect in functional widgets
///    - DON'T block on tracking - do it async without awaiting
///
/// 2. RECOMMENDATIONS
///    - Load early so cacheable - not on every build
///    - Show top 3-5 recommendations for UI clarity
///    - Mark "must-see" recommendations prominently
///    - Fallback gracefully if loading fails
///
/// 3. DYNAMIC PRICING
///    - Show base price crossed out
///    - Show final price prominently
///    - Show discount % and reason in small text
///    - Calculate once per product per session
///
/// 4. CHURN DETECTION
///    - Only show alerts if daysSinceLastActivity > 14 days
///    - Send email/push notification before showing UI alert
///    - Offer recovery discount automatically
///    - Track if recovery attempt was successful
///
/// 5. PERFORMANCE
///    - Cache recommendations for 1-2 hours
///    - Don't recalculate dynamic prices on every render
///    - Use pagination for large lists
///    - Monitor Firestore read counts
///
/// ============================================================================
/// TESTING
/// ============================================================================
///
/// To test locally without backend:
///   1. The services gracefully degrade if Firestore is unavailable
///   2. Mock data will be used automatically
///   3. Check logs for errors (grep for '❌')
///   4. Run: flutter analyze → should show 0 errors
///
/// ============================================================================
/// NEXT STEPS (Post-Launch)
/// ============================================================================
///
/// Phase 1 (Week 1): Activity Tracking Integration
///   - [ ] Add trackProductViewed to all product screens
///   - [ ] Add trackAddedToCart to cart
///   - [ ] Add trackOrderPlaced to checkout
///   - [ ] Monitor Firestore event collection growth
///
/// Phase 2 (Week 2): Enable Recommendations
///   - [ ] Add personalizedRecommendations to home screen
///   - [ ] Add similarProducts to product details
///   - [ ] Test recommendation quality
///   - [ ] Adjust recommendation weights if needed
///
/// Phase 3 (Week 3): Activate Churn Prevention
///   - [ ] Set up daily churn analysis job (Cloud Function)
///   - [ ] Send recovery emails to at-risk users
///   - [ ] Show recovery discount UI
///   - [ ] Track recovery campaign effectiveness
///
/// Phase 4 (Week 4): Dynamic Pricing Rollout
///   - [ ] Start with 10% of traffic on dynamic pricing
///   - [ ] Monitor conversion impact
///   - [ ] Gradually roll out to 100%
///   - [ ] Analyze revenue impact
///
/// ============================================================================
