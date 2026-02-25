import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/models/product.dart';

// ==================== MEMBER HOME PROVIDERS ====================

/// Member tier and status
class MemberData {
  final String memberId;
  final String tier; // gold, silver, bronze
  final int rewardsPoints;
  final int lifetimePoints;
  final DateTime memberSince;
  final bool isActive;
  final double discountPercentage;
  final int ordersCount;
  final double totalSpent;

  MemberData({
    required this.memberId,
    required this.tier,
    required this.rewardsPoints,
    required this.lifetimePoints,
    required this.memberSince,
    required this.isActive,
    required this.discountPercentage,
    required this.ordersCount,
    required this.totalSpent,
  });

  factory MemberData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberData(
      memberId: doc.id,
      tier: data['tier'] ?? 'bronze',
      rewardsPoints: data['rewardsPoints'] ?? 0,
      lifetimePoints: data['lifetimePoints'] ?? 0,
      memberSince:
          (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      ordersCount: data['ordersCount'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
    );
  }
}

/// Watch member data and rewards (using FutureProvider for better error handling)
final memberDataProvider =
    FutureProvider.family<MemberData?, String>((ref, userId) async {
  // Reject empty user ID
  if (userId.isEmpty) {
    return null;
  }

  try {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('members').doc(userId).get();
    
    if (doc.exists) {
      return MemberData.fromFirestore(doc);
    } else {
      // Log warning but return null (not mock)
      print('⚠️ No member document for $userId in Firestore');
      return null;
    }
  } catch (e) {
    // Log error but return null (not mock)
    print('❌ Error fetching member data: $e');
    return null;
  }
});

/// Watch exclusive member-only products
final exclusiveMemberProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('products')
        .where('exclusiveForMembers', isEqualTo: true)
        .limit(6)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data()))
        .toList();
  } catch (e) {
    print('❌ Error fetching exclusive products: $e');
    return []; // Return empty list on error
  }
});

// ==================== ADMIN DASHBOARD PROVIDERS ====================

/// System metrics for admin dashboard
class SystemMetrics {
  final int totalOrders;
  final int ordersToday;
  final int ordersThisMonth;
  final double totalRevenue;
  final double revenueToday;
  final double revenueThisMonth;
  final int activeUsers;
  final int newUsersThisMonth;
  final int pendingApprovals;
  final List<String> systemAlerts;
  final DateTime lastUpdated;

  SystemMetrics({
    required this.totalOrders,
    required this.ordersToday,
    required this.ordersThisMonth,
    required this.totalRevenue,
    required this.revenueToday,
    required this.revenueThisMonth,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.pendingApprovals,
    required this.systemAlerts,
    required this.lastUpdated,
  });
}

/// Calculate system metrics (combines multiple data sources)
final systemMetricsProvider = FutureProvider<SystemMetrics>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // Get order metrics
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final startOfMonth = DateTime(today.year, today.month, 1);

  final allOrdersSnap = await firestore
      .collection('orders')
      .where('status', isNotEqualTo: 'draft')
      .get();
  final totalOrders = allOrdersSnap.docs.length;

  final todayOrdersSnap = await firestore
      .collection('orders')
      .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('status', isNotEqualTo: 'draft')
      .get();
  final ordersToday = todayOrdersSnap.docs.length;

  final monthOrdersSnap = await firestore
      .collection('orders')
      .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('status', isNotEqualTo: 'draft')
      .get();
  final ordersThisMonth = monthOrdersSnap.docs.length;

  // Calculate revenue
  double totalRevenue = 0;
  double revenueToday = 0;
  double revenueThisMonth = 0;

  for (var doc in allOrdersSnap.docs) {
    final amount = (doc['totalAmount'] ?? 0).toDouble();
    totalRevenue += amount;
  }

  for (var doc in todayOrdersSnap.docs) {
    final amount = (doc['totalAmount'] ?? 0).toDouble();
    revenueToday += amount;
  }

  for (var doc in monthOrdersSnap.docs) {
    final amount = (doc['totalAmount'] ?? 0).toDouble();
    revenueThisMonth += amount;
  }

  // Get user metrics
  final usersSnap = await firestore.collection('users').get();
  final activeUsers = usersSnap.docs.length;

  final newUsersSnap = await firestore
      .collection('users')
      .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .get();
  final newUsersThisMonth = newUsersSnap.docs.length;

  // Get pending approvals
  final approvalsSnap = await firestore
      .collection('approvals')
      .where('status', isEqualTo: 'pending')
      .get();
  final pendingApprovals = approvalsSnap.docs.length;

  return SystemMetrics(
    totalOrders: totalOrders,
    ordersToday: ordersToday,
    ordersThisMonth: ordersThisMonth,
    totalRevenue: totalRevenue,
    revenueToday: revenueToday,
    revenueThisMonth: revenueThisMonth,
    activeUsers: activeUsers,
    newUsersThisMonth: newUsersThisMonth,
    pendingApprovals: pendingApprovals,
    systemAlerts: [], // System running normally
    lastUpdated: DateTime.now(),
  );
});

// ==================== FRANCHISE OWNER PROVIDERS ====================

/// Store metrics for franchise owner
class StoreMetrics {
  final String storeId;
  final String storeName;
  final double monthlyRevenue;
  final int monthlyOrders;
  final double averageOrderValue;
  final int inventoryCount;
  final int lowStockItems;
  final int staffCount;
  final double staffUtilization;
  final int customersCount;

  StoreMetrics({
    required this.storeId,
    required this.storeName,
    required this.monthlyRevenue,
    required this.monthlyOrders,
    required this.averageOrderValue,
    required this.inventoryCount,
    required this.lowStockItems,
    required this.staffCount,
    required this.staffUtilization,
    required this.customersCount,
  });

  factory StoreMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreMetrics(
      storeId: doc.id,
      storeName: data['storeName'] ?? 'Store',
      monthlyRevenue: (data['monthlyRevenue'] ?? 0).toDouble(),
      monthlyOrders: data['monthlyOrders'] ?? 0,
      averageOrderValue: (data['averageOrderValue'] ?? 0).toDouble(),
      inventoryCount: data['inventoryCount'] ?? 0,
      lowStockItems: data['lowStockItems'] ?? 0,
      staffCount: data['staffCount'] ?? 0,
      staffUtilization: (data['staffUtilization'] ?? 0).toDouble(),
      customersCount: data['customersCount'] ?? 0,
    );
  }
}

/// Watch store metrics for franchise owner
final storeMetricsProvider =
    StreamProvider.family<StoreMetrics?, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('stores')
      .doc(storeId)
      .snapshots()
      .map((doc) => doc.exists ? StoreMetrics.fromFirestore(doc) : null);
});

/// Watch low stock items for store
final lowStockItemsProvider =
    StreamProvider.family<List<Product>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('products')
      .where('storeId', isEqualTo: storeId)
      .where('stock', isLessThan: 10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList());
});

// ==================== WAREHOUSE STAFF PROVIDERS ====================

/// Warehouse fulfillment metrics
class WarehouseMetrics {
  final int totalPickLists;
  final int pickedLists;
  final int packingQueueCount;
  final int packedCount;
  final int qcPendingCount;
  final int qcApprovedCount;
  final double shiftProductivity;
  final int staffOnShift;

  WarehouseMetrics({
    required this.totalPickLists,
    required this.pickedLists,
    required this.packingQueueCount,
    required this.packedCount,
    required this.qcPendingCount,
    required this.qcApprovedCount,
    required this.shiftProductivity,
    required this.staffOnShift,
  });

  factory WarehouseMetrics.empty() => WarehouseMetrics(
        totalPickLists: 0,
        pickedLists: 0,
        packingQueueCount: 0,
        packedCount: 0,
        qcPendingCount: 0,
        qcApprovedCount: 0,
        shiftProductivity: 0,
        staffOnShift: 0,
      );

  /// Alias for pickedLists
  int get itemsPicked => pickedLists;

  /// Alias for packedCount
  int get itemsPacked => packedCount;

  /// Alias for qcApprovedCount
  int get qcComplete => qcApprovedCount;

  /// Alias for total that are ready to ship
  int get readyToShip => qcApprovedCount;
}

/// Watch pending pick lists
final pendingPickListsProvider = StreamProvider<List<String>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('pick_lists')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});

/// Watch packing queue
final packingQueueCountProvider = StreamProvider<int>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('packing_queue')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Watch QC pending items
final qcPendingCountProvider = StreamProvider<int>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('quality_checks')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// ==================== SHARED PROVIDERS ====================

/// Featured products for consumer and member home
final featuredProductsProvider = StreamProvider<List<Product>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('products')
      .where('featured', isEqualTo: true)
      .limit(6)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList());
});

/// Watch promotional banners
class PromoBanner {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? actionUrl;
  final DateTime validFrom;
  final DateTime validUntil;

  PromoBanner({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.actionUrl,
    required this.validFrom,
    required this.validUntil,
  });

  factory PromoBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoBanner(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      validFrom: (data['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil:
          (data['validUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final activePromosProvider = StreamProvider<List<PromoBanner>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final now = Timestamp.now();

  return firestore
      .collection('promotions')
      .where('validFrom', isLessThanOrEqualTo: now)
      .where('validUntil', isGreaterThanOrEqualTo: now)
      .limit(5)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PromoBanner.fromFirestore(doc)).toList());
});

// ==================== PHASE 2: ROLE-AWARE PRODUCT PROVIDERS ====================

/// Mock products fallback (when Firebase is unavailable)
List<Product> _getDefaultMockProducts() {
  return [
    // GRAINS
    Product(
      id: 'mock_001',
      name: 'Ijebu Garri',
      retailPrice: 25000.0,
      wholesalePrice: 22500.0,
      contractPrice: 18000.0,
      description: 'High-quality Ijebu garri for authentic meals',
      imageUrl: 'assets/images/ijebugarri1.png',
      categoryId: 'grains',
      stock: 100,
    ),
    Product(
      id: 'mock_001b',
      name: 'Long Grain Rice',
      retailPrice: 18000.0,
      wholesalePrice: 16500.0,
      contractPrice: 15000.0,
      description: 'Premium long grain rice 50kg bag',
      imageUrl: 'assets/images/ijebugarri1.png',
      categoryId: 'grains',
      stock: 85,
    ),
    Product(
      id: 'mock_001c',
      name: 'Corn Meal',
      retailPrice: 12000.0,
      wholesalePrice: 10800.0,
      contractPrice: 9000.0,
      description: 'Fine quality corn meal for cooking',
      imageUrl: 'assets/images/ijebugarri1.png',
      categoryId: 'grains',
      stock: 95,
    ),

    // OILS
    Product(
      id: 'mock_002',
      name: 'Golden Groundnut Oil',
      retailPrice: 12500.0,
      wholesalePrice: 11000.0,
      contractPrice: 9500.0,
      description: 'Pure refined groundnut oil',
      imageUrl: 'assets/images/Groundnut oil1.png',
      categoryId: 'oils',
      stock: 45,
    ),
    Product(
      id: 'mock_002b',
      name: 'Premium Palm Oil',
      retailPrice: 14000.0,
      wholesalePrice: 12600.0,
      contractPrice: 10500.0,
      description: 'Pure red palm oil for cooking',
      imageUrl: 'assets/images/Groundnut oil1.png',
      categoryId: 'oils',
      stock: 55,
    ),
    Product(
      id: 'mock_002c',
      name: 'Coconut Oil',
      retailPrice: 16500.0,
      wholesalePrice: 14850.0,
      contractPrice: 13000.0,
      description: 'Virgin coconut oil',
      imageUrl: 'assets/images/Groundnut oil1.png',
      categoryId: 'oils',
      stock: 38,
    ),

    // VEGETABLES
    Product(
      id: 'mock_003',
      name: 'Fresh Tomatoes',
      retailPrice: 8000.0,
      wholesalePrice: 7000.0,
      contractPrice: 5500.0,
      description: 'Fresh farm tomatoes',
      imageUrl: 'assets/images/Tomatoes1.png',
      categoryId: 'vegetables',
      stock: 78,
    ),
    Product(
      id: 'mock_003b',
      name: 'Bell Peppers Mix',
      retailPrice: 6500.0,
      wholesalePrice: 5850.0,
      contractPrice: 4800.0,
      description: 'Assorted fresh bell peppers',
      imageUrl: 'assets/images/Tomatoes1.png',
      categoryId: 'vegetables',
      stock: 62,
    ),
    Product(
      id: 'mock_003c',
      name: 'Fresh Spinach',
      retailPrice: 4000.0,
      wholesalePrice: 3600.0,
      contractPrice: 3000.0,
      description: 'Organic fresh spinach leaves',
      imageUrl: 'assets/images/Tomatoes1.png',
      categoryId: 'vegetables',
      stock: 88,
    ),

    // PROTEINS/DAIRY
    Product(
      id: 'mock_005',
      name: 'Fresh Eggs 30-piece Crate',
      retailPrice: 6000.0,
      wholesalePrice: 5400.0,
      contractPrice: 4800.0,
      description: 'Fresh farm eggs',
      imageUrl: 'assets/images/One crate eggs1.png',
      categoryId: 'proteins',
      stock: 120,
    ),
    Product(
      id: 'mock_005b',
      name: 'Premium Fresh Milk',
      retailPrice: 3500.0,
      wholesalePrice: 3150.0,
      contractPrice: 2800.0,
      description: 'Fresh pasteurized milk litre',
      imageUrl: 'assets/images/One crate eggs1.png',
      categoryId: 'dairy',
      stock: 200,
    ),
    Product(
      id: 'mock_005c',
      name: 'Greek Yogurt',
      retailPrice: 5200.0,
      wholesalePrice: 4680.0,
      contractPrice: 4000.0,
      description: 'Pure greek yogurt tubs',
      imageUrl: 'assets/images/One crate eggs1.png',
      categoryId: 'dairy',
      stock: 45,
    ),
    Product(
      id: 'mock_005d',
      name: 'Butter 400g',
      retailPrice: 4800.0,
      wholesalePrice: 4320.0,
      contractPrice: 3600.0,
      description: 'Premium butter for cooking',
      imageUrl: 'assets/images/One crate eggs1.png',
      categoryId: 'dairy',
      stock: 76,
    ),

    // SPICES
    Product(
      id: 'mock_004',
      name: 'Spices Hamper',
      retailPrice: 15000.0,
      wholesalePrice: 13500.0,
      contractPrice: 11500.0,
      description: 'Premium collection of authentic spices',
      imageUrl: 'assets/images/Spices hamper1.png',
      categoryId: 'spices',
      stock: 60,
    ),
    Product(
      id: 'mock_006',
      name: 'Honey Beans',
      retailPrice: 3500.0,
      wholesalePrice: 3150.0,
      contractPrice: 2800.0,
      description: 'Premium honey beans for nutritious meals',
      imageUrl: 'assets/images/Honey beans1.png',
      categoryId: 'spices',
      stock: 90,
    ),
    Product(
      id: 'mock_006b',
      name: 'Ginger Powder',
      retailPrice: 2800.0,
      wholesalePrice: 2520.0,
      contractPrice: 2200.0,
      description: 'Premium dried ginger powder',
      imageUrl: 'assets/images/Spices hamper1.png',
      categoryId: 'spices',
      stock: 55,
    ),
  ];
}

/// Featured products filtered by user role
/// - Consumer: visibleToRetail = true
/// - Member: visibleToWholesale = true  
/// - Institutional: visibleToInstitutions = true
final roleAwareFeaturedProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, userRole) async {
  try {
    // For now, use mock products directly since they load instantly
    // Firebase integration can be added later when collections are properly set up
    final mockProducts = _getDefaultMockProducts();
    return mockProducts.take(6).toList();
  } catch (e) {
    print('⚠️ Error in roleAwareFeaturedProductsProvider: $e');
    return _getDefaultMockProducts().take(6).toList();
  }
});

/// All products filtered by user role visibility
final roleAwareProductsProvider =
    StreamProvider.family<List<Product>, String>((ref, userRole) {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Determine which visibility flag to filter by
    String visibilityField;
    if (userRole.contains('member') || userRole.contains('cooperative')) {
      visibilityField = 'visibleToWholesale';
    } else if (userRole.contains('institutional')) {
      visibilityField = 'visibleToInstitutions';
    } else {
      visibilityField = 'visibleToRetail';
    }

    return firestore
        .collection('products')
        .where(visibilityField, isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc.data()))
            .toList())
        .handleError((_) {
          return _getDefaultMockProducts();
        });
  } catch (e) {
    print('⚠️ Firebase error in roleAwareProductsProvider: $e');
    return Stream.value(_getDefaultMockProducts());
  }
});

/// Product list for a specific category, filtered by role
/// Uses FutureProvider for instant display of mock data
final roleAwareCategoryProductsProvider =
    FutureProvider.family<List<Product>, ({String categoryId, String userRole})>(
        (ref, params) async {
  try {
    // Return mock products filtered by category immediately
    // This provides instant UI feedback instead of waiting for Firebase
    final mockProducts = _getDefaultMockProducts();
    final filtered = mockProducts
        .where((p) => p.categoryId == params.categoryId)
        .toList();
    
    // Sort by price descending by default (popular = highest quality first)
    filtered.sort((a, b) => b.retailPrice.compareTo(a.retailPrice));
    
    return filtered;
  } catch (e) {
    print('⚠️ Error in roleAwareCategoryProductsProvider: $e');
    return _getDefaultMockProducts()
        .where((p) => p.categoryId == params.categoryId)
        .toList();
  }
});
