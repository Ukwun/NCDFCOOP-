import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/franchise_models.dart';
import '../services/franchise_service.dart';
import '../../features/welcome/auth_provider.dart';

// Service providers
final franchiseStoreServiceProvider = Provider((ref) {
  return FranchiseStoreService();
});

final franchiseSalesServiceProvider = Provider((ref) {
  return FranchiseSalesService();
});

final franchiseInventoryServiceProvider = Provider((ref) {
  return FranchiseInventoryService();
});

final franchiseComplianceServiceProvider = Provider((ref) {
  return FranchiseComplianceService();
});

// Store Providers

/// Get current user's franchise stores
final userFranchiseStoresProvider =
    StreamProvider<List<FranchiseStore>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final firestore = FirebaseFirestore.instance;

  final user = authState.value;
  if (user == null) {
    yield [];
    return;
  }

  yield* firestore
      .collection('franchise_stores')
      .where('ownerId', isEqualTo: user.id)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FranchiseStore.fromFirestore(doc))
        .toList();
  });
});

/// Get single store by ID
final franchiseStoreProvider =
    FutureProvider.family<FranchiseStore?, String>((ref, storeId) async {
  final service = ref.watch(franchiseStoreServiceProvider);
  return service.getStore(storeId);
});

/// Get all active franchise stores
final activeFranchiseStoresProvider =
    StreamProvider<List<FranchiseStore>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('franchise_stores')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FranchiseStore.fromFirestore(doc))
        .toList();
  });
});

// Sales Providers

/// Get sales summary for date range
final franchiseSalesSummaryProvider =
    FutureProvider.family<SalesSummary, (String, DateTime, DateTime)>(
        (ref, params) async {
  final (storeId, startDate, endDate) = params;
  final service = ref.watch(franchiseSalesServiceProvider);
  return service.getSalesSummary(storeId, startDate, endDate);
});

/// Get daily sales metrics for period
final franchiseDailySalesProvider =
    StreamProvider.family<List<SalesMetric>, (String, DateTime, DateTime)>(
        (ref, params) {
  final (storeId, startDate, endDate) = params;
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('franchise_sales_metrics')
      .where('storeId', isEqualTo: storeId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => SalesMetric.fromFirestore(doc)).toList();
  });
});

/// Get today's sales metric
final todaysSalesProvider =
    FutureProvider.family<SalesMetric?, String>((ref, storeId) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay
      .add(const Duration(days: 1))
      .subtract(const Duration(seconds: 1));

  final firestore = FirebaseFirestore.instance;
  final query = await firestore
      .collection('franchise_sales_metrics')
      .where('storeId', isEqualTo: storeId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
      .get();

  if (query.docs.isEmpty) return null;
  return SalesMetric.fromFirestore(query.docs.first);
});

// Inventory Providers

/// Get franchise store inventory
final franchiseStoreInventoryProvider =
    StreamProvider.family<List<FranchiseInventoryItem>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('franchise_inventory')
      .where('storeId', isEqualTo: storeId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FranchiseInventoryItem.fromFirestore(doc))
        .toList();
  });
});

/// Get low stock items for store
final lowStockItemsProvider =
    FutureProvider.family<List<FranchiseInventoryItem>, String>(
        (ref, storeId) async {
  final service = ref.watch(franchiseInventoryServiceProvider);
  return service.getLowStockItems(storeId);
});

/// Get items needing reorder
final reorderItemsProvider =
    FutureProvider.family<List<FranchiseInventoryItem>, String>(
        (ref, storeId) async {
  final service = ref.watch(franchiseInventoryServiceProvider);
  return service.getReorderItems(storeId);
});

/// Get total inventory value
final inventoryValueProvider =
    FutureProvider.family<double, String>((ref, storeId) async {
  final service = ref.watch(franchiseInventoryServiceProvider);
  return service.getInventoryValue(storeId);
});

// Compliance Providers

/// Get today's compliance checklist
final todaysComplianceChecklistProvider =
    FutureProvider.family<ComplianceChecklist?, String>((ref, storeId) async {
  final service = ref.watch(franchiseComplianceServiceProvider);
  return service.getChecklistForDate(storeId, DateTime.now());
});

/// Get compliance checklists for date range
final complianceChecklistsProvider = StreamProvider.family<
    List<ComplianceChecklist>, (String, DateTime, DateTime)>((ref, params) {
  final (storeId, startDate, endDate) = params;
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('franchise_compliance')
      .where('storeId', isEqualTo: storeId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ComplianceChecklist.fromFirestore(doc))
        .toList();
  });
});

/// Get compliance score for period
final complianceScoreProvider =
    FutureProvider.family<ComplianceScore, (String, DateTime, DateTime)>(
        (ref, params) async {
  final (storeId, startDate, endDate) = params;
  final service = ref.watch(franchiseComplianceServiceProvider);
  return service.getComplianceScore(storeId, startDate, endDate);
});

// Dashboard Providers

/// Get franchise dashboard metrics
final franchiseDashboardMetricsProvider =
    FutureProvider.family<FranchiseDashboardMetrics, String>(
        (ref, storeId) async {
  final salesService = ref.watch(franchiseSalesServiceProvider);
  final inventoryService = ref.watch(franchiseInventoryServiceProvider);
  final complianceService = ref.watch(franchiseComplianceServiceProvider);

  // Get today's sales
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final todaysSummary = await salesService.getSalesSummary(
    storeId,
    startOfDay,
    now.add(const Duration(days: 1)),
  );

  // Get this week's sales
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final weeksSummary = await salesService.getSalesSummary(
    storeId,
    startOfWeek,
    now.add(const Duration(days: 1)),
  );

  // Get inventory metrics
  final inventory = await inventoryService.getStoreInventory(storeId);
  final lowStockCount = inventory.where((item) => item.isLowStock()).length;
  final reorderCount = inventory
      .where((item) => item.quantity < item.getReorderQuantity())
      .length;
  final inventoryValue = await inventoryService.getInventoryValue(storeId);

  // Get compliance score
  final startOfMonth = DateTime(now.year, now.month, 1);
  final complianceScore = await complianceService.getComplianceScore(
    storeId,
    startOfMonth,
    now.add(const Duration(days: 1)),
  );

  return FranchiseDashboardMetrics(
    todaysSales: todaysSummary.totalSales,
    todaysTransactions: todaysSummary.totalTransactions,
    weeksSales: weeksSummary.totalSales,
    weeksAvgDailySales: weeksSummary.avgDailySales,
    inventoryValue: inventoryValue,
    lowStockItems: lowStockCount,
    reorderItems: reorderCount,
    complianceScore: complianceScore.complianceScore,
    complianceGrade: complianceScore.getGrade(),
    violations: complianceScore.violations,
  );
});

class FranchiseDashboardMetrics {
  final double todaysSales;
  final int todaysTransactions;
  final double weeksSales;
  final double weeksAvgDailySales;
  final double inventoryValue;
  final int lowStockItems;
  final int reorderItems;
  final double complianceScore;
  final String complianceGrade;
  final List<String> violations;

  FranchiseDashboardMetrics({
    required this.todaysSales,
    required this.todaysTransactions,
    required this.weeksSales,
    required this.weeksAvgDailySales,
    required this.inventoryValue,
    required this.lowStockItems,
    required this.reorderItems,
    required this.complianceScore,
    required this.complianceGrade,
    required this.violations,
  });
}

/// Get franchise analytics data
final franchiseAnalyticsProvider =
    FutureProvider.family<FranchiseAnalyticsData, String>((ref, storeId) async {
  final dailySalesAsync = await ref.watch(franchiseDailySalesProvider((
    storeId,
    DateTime.now().subtract(const Duration(days: 30)),
    DateTime.now()
  )).future);

  final totalMonthlyRevenue =
      dailySalesAsync.fold<double>(0, (sum, metric) => sum + metric.dailySales);
  final dailyOrders =
      dailySalesAsync.map((metric) => metric.transactionCount).toList();
  final monthlyGrowth = dailySalesAsync.isNotEmpty
      ? ((dailySalesAsync.last.dailySales - dailySalesAsync.first.dailySales) /
          (dailySalesAsync.first.dailySales == 0
              ? 1
              : dailySalesAsync.first.dailySales) *
          100)
      : 0.0;

  // Mock category data for now
  final categories = ['Electronics', 'Groceries', 'Textiles', 'Home Goods'];
  final categoryRevenue = [
    totalMonthlyRevenue * 0.4,
    totalMonthlyRevenue * 0.3,
    totalMonthlyRevenue * 0.2,
    totalMonthlyRevenue * 0.1
  ];

  return FranchiseAnalyticsData(
    totalMonthlyRevenue: totalMonthlyRevenue,
    dailyOrders: dailyOrders,
    monthlyGrowth: monthlyGrowth,
    categories: categories,
    categoryRevenue: categoryRevenue,
  );
});

/// Get franchise inventory sync status
final franchiseInventorySyncProvider =
    StreamProvider.family<List<FranchiseInventoryItem>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('franchise_inventory')
      .where('storeId', isEqualTo: storeId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FranchiseInventoryItem.fromFirestore(doc))
        .toList();
  });
});

/// Get count of items needing reorder
final franchiseReorderCountProvider =
    FutureProvider.family<int, String>((ref, storeId) async {
  final service = ref.watch(franchiseInventoryServiceProvider);
  final reorderItems = await service.getReorderItems(storeId);
  return reorderItems.length;
});

/// Get franchise store inventory (alternative to franchiseStoreInventoryProvider)
final franchiseInventoryProvider =
    StreamProvider.family<List<FranchiseInventoryItem>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('franchise_inventory')
      .where('storeId', isEqualTo: storeId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => FranchiseInventoryItem.fromFirestore(doc))
        .toList();
  });
});

/// Get low stock items (alternative name for lowStockItemsProvider)
final franchiseLowStockProvider =
    FutureProvider.family<List<FranchiseInventoryItem>, String>(
        (ref, storeId) async {
  final service = ref.watch(franchiseInventoryServiceProvider);
  return service.getLowStockItems(storeId);
});

/// Get franchise staff members
final franchiseStaffProvider =
    StreamProvider.family<List<StaffMember>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('franchise_staff')
      .where('storeId', isEqualTo: storeId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => StaffMember.fromFirestore(doc)).toList();
  });
});

/// Analytics data for franchise dashboard
class FranchiseAnalyticsData {
  final double totalMonthlyRevenue;
  final List<int> dailyOrders;
  final double monthlyGrowth;
  final List<String> categories;
  final List<double> categoryRevenue;

  FranchiseAnalyticsData({
    required this.totalMonthlyRevenue,
    required this.dailyOrders,
    required this.monthlyGrowth,
    required this.categories,
    required this.categoryRevenue,
  });
}
