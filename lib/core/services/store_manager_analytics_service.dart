import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/store_manager_analytics_models.dart';

/// Service for managing store manager analytics
class StoreManagerAnalyticsService {
  final FirebaseFirestore _firestore;

  static StoreManagerAnalyticsService? _instance;

  factory StoreManagerAnalyticsService({FirebaseFirestore? firestore}) {
    _instance ??= StoreManagerAnalyticsService._(firestore: firestore);
    return _instance!;
  }

  StoreManagerAnalyticsService._({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get store analytics summary
  Future<StoreAnalyticsSummary> getStoreAnalyticsSummary(
      String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();

      if (!doc.exists) {
        return _getMockAnalyticsSummary(storeId);
      }

      final data = doc.data() as Map<String, dynamic>;

      // Calculate metrics from data
      final totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      final transactionCount =
          (data['transactionCount'] as num?)?.toInt() ?? 0;
      final profitMargin = (data['profitMargin'] as num?)?.toDouble() ?? 0.0;
      final customersServed =
          (data['customersServed'] as num?)?.toInt() ?? 0;
      final topProductCount = (data['topProductCount'] as num?)?.toInt() ?? 0;
      final staffCount = (data['staffCount'] as num?)?.toInt() ?? 0;
      final averageStaffPerformance =
          (data['averageStaffPerformance'] as num?)?.toDouble() ?? 0.0;
      final inventoryStatus = data['inventoryStatus'] ?? 'Healthy';

      return StoreAnalyticsSummary(
        storeId: storeId,
        storeName: data['storeName'] ?? 'Store',
        totalRevenue: totalRevenue,
        transactionCount: transactionCount,
        profitMargin: profitMargin,
        customersServed: customersServed,
        topProductCount: topProductCount,
        staffCount: staffCount,
        averageStaffPerformance: averageStaffPerformance,
        inventoryStatus: inventoryStatus,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching analytics summary: $e');
      return _getMockAnalyticsSummary(storeId);
    }
  }

  /// Get daily sales dashboard data
  Future<StoreSalesMetrics> getDailySalesMetrics(String storeId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay =
          DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('daily_sales')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double totalRevenue = 0;
      int transactionCount = snapshot.docs.length;
      Set<String> uniqueCustomers = {};
      Map<String, double> paymentBreakdown = {};
      Map<String, int> topProductsMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] as num?)?.toDouble() ?? 0.0;

        // Track customers
        if (data['customerId'] != null) {
          uniqueCustomers.add(data['customerId']);
        }

        // Payment method breakdown
        final paymentMethod = data['paymentMethod'] ?? 'Other';
        paymentBreakdown[paymentMethod] =
            (paymentBreakdown[paymentMethod] ?? 0.0) +
                ((data['total'] as num?)?.toDouble() ?? 0.0);

        // Top products
        if (data['productId'] != null) {
          topProductsMap[data['productId']] =
              (topProductsMap[data['productId']] ?? 0) + 1;
        }
      }

      // Get top 5 products
      final topProducts = topProductsMap.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      final topProductIds =
          topProducts.take(5).map((e) => e.key).toList();

      double profitMargin = 0;
      if (totalRevenue > 0) {
        // Assume 30% profit margin for calculation
        profitMargin = totalRevenue * 0.30;
      }

      return StoreSalesMetrics(
        storeId: storeId,
        totalRevenue: totalRevenue,
        transactionCount: transactionCount,
        averageTransactionValue: transactionCount > 0
            ? totalRevenue / transactionCount
            : 0,
        profitMargin: profitMargin,
        customersServed: uniqueCustomers.length,
        paymentMethodBreakdown: paymentBreakdown,
        topProducts: topProductIds,
        periodStart: startOfDay,
        periodEnd: endOfDay,
      );
    } catch (e) {
      print('Error fetching daily sales metrics: $e');
      return _getMockDailySalesMetrics(storeId);
    }
  }

  /// Get product performance metrics
  Future<List<ProductPerformance>> getProductPerformanceMetrics(
      String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .get();

      final products = <ProductPerformance>[];

      for (var doc in snapshot.docs) {
        final perf = ProductPerformance.fromFirestore(doc);
        products.add(perf);
      }

      // Sort by revenue
      products.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      return products;
    } catch (e) {
      print('Error fetching product performance: $e');
      return _getMockProductPerformance();
    }
  }

  /// Get staff performance metrics
  Future<List<StaffPerformance>> getStaffPerformanceMetrics(
      String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('staff')
          .get();

      final staff = <StaffPerformance>[];

      for (var doc in snapshot.docs) {
        final perf = StaffPerformance.fromFirestore(doc);
        staff.add(perf);
      }

      // Sort by performance score
      staff.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

      return staff;
    } catch (e) {
      print('Error fetching staff performance: $e');
      return _getMockStaffPerformance();
    }
  }

  /// Get inventory health status
  Future<InventoryHealth> getInventoryHealth(String storeId) async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('inventory')
          .doc('health')
          .get();

      if (!doc.exists) {
        return _getMockInventoryHealth(storeId);
      }

      return InventoryHealth.fromFirestore(doc);
    } catch (e) {
      print('Error fetching inventory health: $e');
      return _getMockInventoryHealth(storeId);
    }
  }

  /// Get low stock alerts
  Future<List<ProductPerformance>> getLowStockAlerts(String storeId) async {
    try {
      final products = await getProductPerformanceMetrics(storeId);
      final lowStock =
          products.where((p) => p.isLowStock).toList();

      return lowStock;
    } catch (e) {
      print('Error fetching low stock alerts: $e');
      return [];
    }
  }

  /// Get period-based sales comparison (read-only analytics)
  Future<Map<String, dynamic>> getSalesComparison(
    String storeId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('daily_sales')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalRevenue = 0;
      int transactionCount = snapshot.docs.length;
      Map<String, double> dailyRevenue = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['total'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;

        // Organize by date
        final date = (data['timestamp'] as Timestamp?)?.toDate();
        if (date != null) {
          final dateKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          dailyRevenue[dateKey] =
              (dailyRevenue[dateKey] ?? 0.0) + amount;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'transactionCount': transactionCount,
        'averageDaily': transactionCount > 0
            ? totalRevenue /
                ((endDate.difference(startDate).inDays) + 1)
            : 0,
        'dailyBreakdown': dailyRevenue,
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      print('Error fetching sales comparison: $e');
      return _getMockSalesComparison();
    }
  }

  // NOTE: Price modifications are READ-ONLY for Store Managers
  // Only Franchise Owner or Admin can modify prices
  // This method enforces that restriction
  Future<bool> canModifyPrices(String userId, String userRole) async {
    // Store Managers cannot modify prices
    if (userRole.toLowerCase().contains('store_manager')) {
      print('Store Managers cannot modify prices');
      return false;
    }

    // Only Franchise Owner or Admin can modify
    return userRole.toLowerCase().contains('franchise_owner') ||
        userRole.toLowerCase().contains('admin');
  }

  /// Attempt to modify price - will fail for Store Managers
  Future<bool> modifyProductPrice({
    required String storeId,
    required String productId,
    required double newPrice,
    required String userRole,
  }) async {
    if (!await canModifyPrices('user_id', userRole)) {
      throw Exception('Store Managers do not have permission to modify prices');
    }

    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId)
          .update({'price': newPrice});
      return true;
    } catch (e) {
      print('Error modifying price: $e');
      return false;
    }
  }

  // Mock data methods
  StoreAnalyticsSummary _getMockAnalyticsSummary(String storeId) {
    return StoreAnalyticsSummary(
      storeId: storeId,
      storeName: 'Store $storeId',
      totalRevenue: 1850000.0,
      transactionCount: 245,
      profitMargin: 22.5,
      customersServed: 189,
      topProductCount: 5,
      staffCount: 12,
      averageStaffPerformance: 82.0,
      inventoryStatus: 'Healthy',
      generatedAt: DateTime.now(),
    );
  }

  StoreSalesMetrics _getMockDailySalesMetrics(String storeId) {
    return StoreSalesMetrics(
      storeId: storeId,
      totalRevenue: 285000.0,
      transactionCount: 42,
      averageTransactionValue: 6785.71,
      profitMargin: 85500.0,
      customersServed: 38,
      paymentMethodBreakdown: {
        'cash': 142500.0,
        'card': 95000.0,
        'transfer': 47500.0,
      },
      topProducts: ['PROD-001', 'PROD-002', 'PROD-003'],
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
    );
  }

  List<ProductPerformance> _getMockProductPerformance() {
    return [
      ProductPerformance(
        productId: 'PROD-001',
        productName: 'Premium Rice 10kg',
        sku: 'RIC-001',
        quantitySold: 245,
        totalRevenue: 612500.0,
        averagePrice: 2500.0,
        stockLevel: 150,
        minimumStock: 50,
        turnoverRate: 3.2,
        profitMargin: 18.5,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
      ProductPerformance(
        productId: 'PROD-002',
        productName: 'Cooking Oil 5L',
        sku: 'OIL-001',
        quantitySold: 189,
        totalRevenue: 527500.0,
        averagePrice: 2790.0,
        stockLevel: 80,
        minimumStock: 30,
        turnoverRate: 2.8,
        profitMargin: 22.0,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
      ProductPerformance(
        productId: 'PROD-003',
        productName: 'Tomato Paste 400g',
        sku: 'TOM-001',
        quantitySold: 312,
        totalRevenue: 374400.0,
        averagePrice: 1200.0,
        stockLevel: 25,
        minimumStock: 40,
        turnoverRate: 4.1,
        profitMargin: 28.0,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
    ];
  }

  List<StaffPerformance> _getMockStaffPerformance() {
    return [
      StaffPerformance(
        staffId: 'STAFF-001',
        staffName: 'Chioma Okafor',
        role: 'POS Operator',
        transactionsProcessed: 145,
        totalSalesGenerated: 520000.0,
        averageTransactionValue: 3586.0,
        customersSaved: 0,
        performanceScore: 92.5,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
      StaffPerformance(
        staffId: 'STAFF-002',
        staffName: 'Adeyemi Okafor',
        role: 'Sales Assistant',
        transactionsProcessed: 128,
        totalSalesGenerated: 445000.0,
        averageTransactionValue: 3477.0,
        customersSaved: 12,
        performanceScore: 87.0,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
      StaffPerformance(
        staffId: 'STAFF-003',
        staffName: 'Fatima Hassan',
        role: 'Inventory Manager',
        transactionsProcessed: 98,
        totalSalesGenerated: 325000.0,
        averageTransactionValue: 3316.0,
        customersSaved: 5,
        performanceScore: 78.0,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      ),
    ];
  }

  InventoryHealth _getMockInventoryHealth(String storeId) {
    return InventoryHealth(
      warehouseId: storeId,
      totalItems: 2450,
      lowStockItems: 12,
      overstockedItems: 3,
      averageTurnoverRate: 3.4,
      deadStockPercentage: 5.2,
      inventoryValue: 8950000.0,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> _getMockSalesComparison() {
    return {
      'totalRevenue': 2100000.0,
      'transactionCount': 312,
      'averageDaily': 300000.0,
      'dailyBreakdown': {
        '2024-01-01': 285000.0,
        '2024-01-02': 320000.0,
        '2024-01-03': 298000.0,
        '2024-01-04': 315000.0,
        '2024-01-05': 310000.0,
        '2024-01-06': 292000.0,
        '2024-01-07': 280000.0,
      },
    };
  }
}

/// Provider for Store Manager Analytics Service
final storeManagerAnalyticsServiceProvider =
    Provider((ref) => StoreManagerAnalyticsService());
