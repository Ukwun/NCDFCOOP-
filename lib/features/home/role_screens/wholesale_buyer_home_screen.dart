import 'package:coop_commerce/core/providers/home_providers.dart';
import 'package:coop_commerce/core/intelligence/role_commerce_intelligence.dart';
import 'package:coop_commerce/core/services/user_activity_service.dart';
import 'package:coop_commerce/models/order.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/providers/real_time_orders_provider.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, Timestamp, SetOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WholesaleBuyerHomeScreen extends ConsumerStatefulWidget {
  const WholesaleBuyerHomeScreen({super.key});

  @override
  ConsumerState<WholesaleBuyerHomeScreen> createState() =>
      _WholesaleBuyerHomeScreenState();
}

class _WholesaleBuyerHomeScreenState
    extends ConsumerState<WholesaleBuyerHomeScreen> {
  static const Color _brandPrimary = AppColors.primary;
  static const Color _brandAccent = AppColors.accent;

  String _selectedCategory = 'All';
  bool _inStockOnly = false;
  final Map<String, int> _desiredQuantities = {};

  @override
  Widget build(BuildContext context) {
    final featuredAsync =
        ref.watch(roleAwareProductsProvider('wholesaleBuyer'));
    final currentUser = ref.watch(currentUserProvider);
    final cartState = ref.watch(cartProvider);

    final activityAsync = currentUser == null
        ? const AsyncValue<List<UserActivity>>.data([])
        : ref.watch(userActivityTimelineProvider(currentUser.id));

    final ordersAsync = currentUser == null
        ? const AsyncValue<List<Order>>.data([])
        : ref.watch(userOrdersStreamProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: featuredAsync.when(
          data: (products) {
            final categories = _buildCategories(products);
            final filteredProducts = _filterProducts(products);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(roleAwareProductsProvider('wholesaleBuyer'));
                if (currentUser != null) {
                  ref.invalidate(userOrdersStreamProvider(currentUser.id));
                  ref.invalidate(userActivityTimelineProvider(currentUser.id));
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  14,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _buildTopModeTabs(context),
                  const SizedBox(height: 12),
                  if (currentUser != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${currentUser.name.split(' ').first}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your wholesale orders, quotes and savings stay live in real time.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (currentUser != null) const SizedBox(height: 12),
                  _buildLiveSummaryStrip(cartState, ordersAsync),
                  const SizedBox(height: 12),
                  _buildRoleRelationshipIntelligence(
                    products,
                    cartState,
                    ordersAsync,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 12),
                  _buildTrustStrip(context),
                  const SizedBox(height: 12),
                  _buildHistoryScroller(context, activityAsync),
                  const SizedBox(height: 12),
                  _buildCategoryTabs(categories),
                  const SizedBox(height: 8),
                  _buildFilterRow(),
                  const SizedBox(height: 12),
                  _buildTopDeals(context, filteredProducts),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Unable to load wholesale marketplace: $error'),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _buildCategories(List<Product> products) {
    final categories = <String>{'All'};
    for (final product in products) {
      if (product.categoryId.trim().isNotEmpty) {
        categories.add(_labelizeCategory(product.categoryId));
      }
    }
    return categories.toList();
  }

  List<Product> _filterProducts(List<Product> products) {
    final filtered = products.where((product) {
      final matchesCategory = _selectedCategory == 'All' ||
          _labelizeCategory(product.categoryId) == _selectedCategory;

      final matchesStock = !_inStockOnly || product.stock > 0;

      return matchesCategory && matchesStock;
    }).toList();

    filtered.sort((a, b) {
      final savingsA = _estimateSavings(a);
      final savingsB = _estimateSavings(b);
      return savingsB.compareTo(savingsA);
    });

    return filtered;
  }

  Widget _buildTopModeTabs(BuildContext context) {
    return Row(
      children: [
        _ModeTab(
          label: 'Discover',
          isActive: false,
          onTap: () {
            ref.read(activityLoggerProvider.notifier).logButtonTap(
                  buttonName: 'wholesale_mode_discover',
                  screenName: 'wholesale_home',
                  context: 'mode_tab',
                  success: true,
                );
            context.pushNamed('dashboard');
          },
        ),
        const SizedBox(width: 10),
        _ModeTab(
          label: 'Wholesale',
          isActive: true,
          onTap: () {
            ref.read(activityLoggerProvider.notifier).logButtonTap(
                  buttonName: 'wholesale_mode_wholesale',
                  screenName: 'wholesale_home',
                  context: 'mode_tab_active',
                  success: true,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are already in Wholesale mode.'),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _ModeTab(
          label: 'Orders',
          isActive: false,
          onTap: () {
            ref.read(activityLoggerProvider.notifier).logButtonTap(
                  buttonName: 'wholesale_mode_orders',
                  screenName: 'wholesale_home',
                  context: 'mode_tab',
                  success: true,
                );
            context.pushNamed('orders');
          },
        ),
      ],
    );
  }

  Widget _buildLiveSummaryStrip(
    CartState cartState,
    AsyncValue<List<Order>> ordersAsync,
  ) {
    final orders = ordersAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Order>[],
    );
    final activeOrders = orders.where((o) => o.isActive).length;
    final deliveredToday = orders.where((order) {
      final deliveredAt = order.deliveredAt;
      if (deliveredAt == null) return false;
      final now = DateTime.now();
      return deliveredAt.year == now.year &&
          deliveredAt.month == now.month &&
          deliveredAt.day == now.day;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Live Cart',
            value: '${cartState.itemCount} items',
            detail: _currency(cartState.subtotal),
            icon: Icons.shopping_cart_outlined,
            onTap: () => context.pushNamed('cart'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Active Orders',
            value: '$activeOrders',
            detail: '$deliveredToday delivered today',
            icon: Icons.local_shipping_outlined,
            onTap: () => context.pushNamed('orders'),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleRelationshipIntelligence(
    List<Product> products,
    CartState cartState,
    AsyncValue<List<Order>> ordersAsync,
  ) {
    final orders = ordersAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Order>[],
    );

    final activeOrders = orders.where((o) => o.isActive).length;
    final snapshot = RoleCommerceIntelligence.wholesale(
      products,
      cartItems: cartState.itemCount,
      activeOrders: activeOrders,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_outlined, color: _brandPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cross-Role Market Intelligence',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(
                'Bulk-ready ${snapshot.bulkReadySkus}',
                Icons.warehouse,
                onTap: () => _handleTagTap(
                  routeName: 'products',
                  label: 'bulk-ready products',
                ),
              ),
              _tag(
                'Restock risk ${snapshot.restockRiskSkus}',
                Icons.warning,
                onTap: () => _handleTagTap(
                  routeName: 'products',
                  label: 'restock risk products',
                ),
              ),
              _tag(
                'Trusted SKUs ${snapshot.trustQualifiedSkus}',
                Icons.verified,
                onTap: () => _handleTagTap(
                  routeName: 'products',
                  label: 'trusted products',
                ),
              ),
              _tag(
                'Avg spread ${snapshot.valueSpreadPercent.toStringAsFixed(1)}%',
                Icons.percent,
                onTap: () => _handleTagTap(
                  routeName: 'orders',
                  label: 'order insights',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.narrative,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(
    String text,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: _brandPrimary),
              const SizedBox(width: 6),
              Text(
                text,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTagTap({
    required String routeName,
    required String label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $label...'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    try {
      context.pushNamed(routeName);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action is temporarily unavailable. Please retry.'),
        ),
      );
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionCard(
            title: 'Browse by\nCategory',
            icon: Icons.grid_view_rounded,
            onTap: () => context.pushNamed('products'),
          ),
          _QuickActionCard(
            title: 'Request\nQuotation',
            icon: Icons.request_quote_outlined,
            onTap: () => _showQuoteDialog(context, null),
          ),
          _QuickActionCard(
            title: 'Open\nCart',
            icon: Icons.shopping_basket_outlined,
            onTap: () => context.pushNamed('cart'),
          ),
          _QuickActionCard(
            title: 'Chat\nSuppliers',
            icon: Icons.chat_outlined,
            onTap: () => context.pushNamed('messages'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustStrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, Color(0xFFEFF7FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.pushNamed('help-center'),
              child: const _TrustItem(
                icon: Icons.local_shipping_outlined,
                title: 'Priority freight',
                subtitle: 'for compliant wholesale orders',
              ),
            ),
          ),
          Container(width: 1, height: 34, color: const Color(0xFFD8AFA8)),
          Expanded(
            child: InkWell(
              onTap: () => context.pushNamed('help-center'),
              child: const _TrustItem(
                icon: Icons.verified_user_outlined,
                title: 'Trade protection',
                subtitle: 'verified seller and payment security',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryScroller(
    BuildContext context,
    AsyncValue<List<UserActivity>> activityAsync,
  ) {
    return activityAsync.when(
      data: (activities) {
        final historyItems = activities
            .where((a) => a.productId != null && a.productName != null)
            .take(8)
            .toList();

        if (historyItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Buying Activity',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 192,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  return Container(
                    width: 170,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFEEEEEE),
                          ),
                          child: const Center(
                            child: Icon(Icons.history_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.productName ?? 'Browsing history',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.15,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            final productId = item.productId;
                            if (productId != null && productId.isNotEmpty) {
                              context.pushNamed(
                                'product-detail',
                                pathParameters: {'productId': productId},
                              );
                            }
                          },
                          child: const Text('Re-open'),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: historyItems.length,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = categories[index];
          final selected = _selectedCategory == label;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = label;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _brandPrimary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? _brandPrimary : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        FilterChip(
          selected: _inStockOnly,
          label: const Text('In-stock only'),
          onSelected: (selected) {
            setState(() {
              _inStockOnly = selected;
            });
          },
        ),
        const SizedBox(width: 8),
        const Text(
          'Showing top wholesale opportunities',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTopDeals(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No products match your wholesale filter right now.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Wholesale Deals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sorted by highest real savings compared to market price.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = products[index];
            final quantity = _desiredQuantities[product.id] ??
                product.minimumOrderQuantity.clamp(1, 9999);

            return _WholesaleProductCard(
              product: product,
              quantity: quantity,
              onView: () {
                context.pushNamed(
                  'product-detail',
                  pathParameters: {'productId': product.id},
                );
              },
              onIncrement: () {
                setState(() {
                  _desiredQuantities[product.id] = quantity + 1;
                });
              },
              onDecrement: () {
                final minimum = product.minimumOrderQuantity.clamp(1, 9999);
                if (quantity <= minimum) return;
                setState(() {
                  _desiredQuantities[product.id] = quantity - 1;
                });
              },
              onAddToCart: () =>
                  _addWholesaleItemToCart(context, product, quantity),
              onRequestQuote: () => _showQuoteDialog(context, product),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: products.length.clamp(1, 24),
        ),
      ],
    );
  }

  Future<void> _addWholesaleItemToCart(
    BuildContext context,
    Product product,
    int quantity,
  ) async {
    final minimum = product.minimumOrderQuantity.clamp(1, 9999);
    if (quantity < minimum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum order for ${product.name} is $minimum units.'),
        ),
      );
      return;
    }

    final cartNotifier = ref.read(cartProvider.notifier);

    for (var i = 0; i < quantity; i++) {
      await cartNotifier.addItem(
        CartItem(
          id: '${product.id}_$i',
          productId: product.id,
          productName: product.name,
          memberPrice: product.wholesalePrice,
          marketPrice: product.retailPrice,
          quantity: 1,
          imageUrl: product.imageUrl,
        ),
      );
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $quantity x ${product.name} to cart.'),
        action: SnackBarAction(
          label: 'Open Cart',
          onPressed: () => context.pushNamed('cart'),
        ),
      ),
    );
  }

  Future<void> _showQuoteDialog(BuildContext context, Product? product) async {
    final qtyController = TextEditingController(
      text: product != null ? product.minimumOrderQuantity.toString() : '100',
    );
    final targetPriceController = TextEditingController(
      text: product != null ? product.wholesalePrice.toStringAsFixed(0) : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Wholesale Quote',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                product == null
                    ? 'Share your target order details with suppliers.'
                    : 'Negotiate better terms for ${product.name}.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Product',
                  border: const OutlineInputBorder(),
                  hintText: 'Choose in marketplace',
                  helperText: product?.name,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: targetPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target price per unit (NGN)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (product == null || product.uploadedBy.isEmpty) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Choose a seller product first so your enquiry reaches the correct seller.',
                          ),
                        ),
                      );
                      this.context.pushNamed('products');
                      return;
                    }
                    final user = ref.read(currentUserProvider);
                    final quantity = int.tryParse(qtyController.text.trim());
                    final targetPrice =
                        double.tryParse(targetPriceController.text.trim());
                    if (user == null ||
                        quantity == null ||
                        quantity < product.minimumOrderQuantity ||
                        targetPrice == null ||
                        targetPrice <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Enter at least ${product.minimumOrderQuantity} units and a valid target price.',
                          ),
                        ),
                      );
                      return;
                    }
                    final participants = [user.id, product.uploadedBy]..sort();
                    final conversationId =
                        '${participants.join('_')}_${product.id}'
                            .replaceAll('/', '_');
                    final firestore = FirebaseFirestore.instance;
                    final quote = firestore.collection('quote_requests').doc();
                    final conversation = firestore
                        .collection('conversations')
                        .doc(conversationId);
                    final message = conversation.collection('messages').doc();
                    final now = Timestamp.now();
                    final text =
                        'Quote request: $quantity × ${product.name} at NGN ${targetPrice.toStringAsFixed(2)} per unit.';
                    final batch = firestore.batch();
                    batch.set(quote, {
                      'quoteId': quote.id,
                      'conversationId': conversationId,
                      'productId': product.id,
                      'productName': product.name,
                      'buyerId': user.id,
                      'buyerName': user.name,
                      'sellerId': product.uploadedBy,
                      'quantity': quantity,
                      'targetUnitPrice': targetPrice,
                      'status': 'pending',
                      'createdAt': now,
                      'updatedAt': now,
                    });
                    batch.set(
                        conversation,
                        {
                          'participantIds': participants,
                          'participants': participants,
                          'participantNames': {user.id: user.name},
                          'productId': product.id,
                          'productName': product.name,
                          'lastMessageText': text,
                          'lastMessageAt': now,
                          'updatedAt': now,
                          'unreadByUser': {user.id: 0, product.uploadedBy: 1},
                        },
                        SetOptions(merge: true));
                    batch.set(message, {
                      'id': message.id,
                      'conversationId': conversationId,
                      'senderId': user.id,
                      'senderName': user.name,
                      'text': text,
                      'messageType': 'quote_request',
                      'quoteId': quote.id,
                      'createdAt': now,
                    });
                    await batch.commit();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Quote request sent to the seller.'),
                      ),
                    );
                    this.context.pushNamed('messages');
                  },
                  child: const Text('Submit Quote Request'),
                ),
              ),
            ],
          ),
        );
      },
    );

    qtyController.dispose();
    targetPriceController.dispose();
  }

  String _currency(double value) => 'NGN ${value.toStringAsFixed(0)}';

  String _labelizeCategory(String raw) {
    final cleaned = raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return 'General';

    return cleaned
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  double _estimateSavings(Product product) {
    final baseline = product.retailPrice <= 0
        ? product.wholesalePrice * 1.15
        : product.retailPrice;
    return (baseline - product.wholesalePrice).clamp(0, double.infinity);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WholesaleProductCard extends StatelessWidget {
  const _WholesaleProductCard({
    required this.product,
    required this.quantity,
    required this.onView,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
    required this.onRequestQuote,
  });

  final Product product;
  final int quantity;
  final VoidCallback onView;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;
  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    final strike = product.retailPrice > 0
        ? product.retailPrice
        : product.wholesalePrice * 1.15;

    final savings = (strike - product.wholesalePrice).clamp(0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(onTap: onView, child: _buildProductThumb()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'NGN ${product.wholesalePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NGN ${strike.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Tag(
                          text:
                              'Save NGN ${savings.toStringAsFixed(0)} / unit'),
                      _Tag(text: 'MOQ ${product.minimumOrderQuantity}'),
                      _Tag(
                        text: product.stock > 0
                            ? 'Stock ${product.stock}'
                            : 'Out of stock',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QtyButton(icon: Icons.remove, onTap: onDecrement),
                      Container(
                        width: 42,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _QtyButton(icon: Icons.add, onTap: onIncrement),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRequestQuote,
                          child: const Text('Quote'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: product.stock > 0 ? onAddToCart : null,
                          child: const Text('Add to cart'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductThumb() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 92,
        height: 92,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFE9E9EA)),
          child: _buildThumbImage(),
        ),
      ),
    );
  }

  Widget _buildThumbImage() {
    final imageUrl = product.displayImageUrl;

    if (imageUrl.isEmpty) {
      return _buildFallbackWithBadge();
    }

    if (imageUrl.startsWith('assets/')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildCategoryFallback(),
          Image.asset(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          _buildThumbBadge(),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCategoryFallback(),
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const SizedBox.shrink();
          },
        ),
        _buildThumbBadge(),
      ],
    );
  }

  Widget _buildFallbackWithBadge() {
    return Stack(
      fit: StackFit.expand,
      children: [_buildCategoryFallback(), _buildThumbBadge()],
    );
  }

  Widget _buildThumbBadge() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(
          Icons.image_outlined,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryFallback() {
    final fallbackAsset = _fallbackAssetForCategory(product.categoryId);

    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFE9E9EA),
        alignment: Alignment.center,
        child: const Icon(Icons.inventory_2_outlined),
      ),
    );
  }

  String _fallbackAssetForCategory(String categoryId) {
    final category = categoryId.trim().toLowerCase();

    if (category.contains('grain') || category.contains('rice')) {
      return 'assets/images/ijebugarri1.png';
    }
    if (category.contains('oil')) {
      return 'assets/images/Groundnut oil1.png';
    }
    if (category.contains('legume') || category.contains('bean')) {
      return 'assets/images/Honey beans1.png';
    }
    if (category.contains('spice')) {
      return 'assets/images/Spices hamper1.png';
    }
    if (category.contains('condiment') || category.contains('tomato')) {
      return 'assets/images/Tomatoes1.png';
    }
    if (category.contains('sweet')) {
      return 'assets/images/All inclusive pack.png';
    }

    return 'assets/images/Groceries1.png';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 17,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 5),
          if (isActive)
            Container(
              width: 84,
              height: 4,
              decoration: BoxDecoration(
                color: _WholesaleBuyerHomeScreenState._brandPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE7E7E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
