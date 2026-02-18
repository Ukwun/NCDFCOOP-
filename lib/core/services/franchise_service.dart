import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/franchise_models.dart';
import '../utils/error_handler.dart';

/// Service for franchise store management
class FranchiseStoreService {
  final FirebaseFirestore _firestore;

  FranchiseStoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create new franchise store
  Future<String> createFranchiseStore({
    required String name,
    required String ownerId,
    required String ownerName,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    required String email,
    required double salesTarget,
    required bool acceptsUnionCard,
    required List<String> operatingDays,
    required String operatingHours,
  }) async {
    try {
      final store = FranchiseStore(
        id: '', // Firestore will generate
        name: name,
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        phone: phone,
        email: email,
        establishedDate: DateTime.now(),
        salesTarget: salesTarget,
        status: 'active',
        acceptsUnionCard: acceptsUnionCard,
        employeeCount: 0,
        operatingDays: operatingDays,
        operatingHours: operatingHours,
      );

      final docRef = await _firestore
          .collection('franchise_stores')
          .add(store.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseStoreService.createFranchiseStore',
      );
    }
  }

  /// Get store by ID
  Future<FranchiseStore?> getStore(String storeId) async {
    try {
      final doc =
          await _firestore.collection('franchise_stores').doc(storeId).get();
      if (!doc.exists) return null;
      return FranchiseStore.fromFirestore(doc);
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseStoreService.getStore',
      );
    }
  }

  /// Get stores for owner
  Future<List<FranchiseStore>> getOwnerStores(String ownerId) async {
    try {
      final query = await _firestore
          .collection('franchise_stores')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return query.docs
          .map((doc) => FranchiseStore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseStoreService.getOwnerStores',
      );
    }
  }

  /// Get all active stores
  Future<List<FranchiseStore>> getActiveStores() async {
    try {
      final query = await _firestore
          .collection('franchise_stores')
          .where('status', isEqualTo: 'active')
          .get();

      return query.docs
          .map((doc) => FranchiseStore.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseStoreService.getActiveStores',
      );
    }
  }

  /// Update store status
  Future<void> updateStoreStatus(String storeId, String newStatus) async {
    try {
      await _firestore.collection('franchise_stores').doc(storeId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseStoreService.updateStoreStatus',
      );
    }
  }

  /// Update store info
  Future<void> updateStoreInfo(
      String storeId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('franchise_stores')
          .doc(storeId)
          .update(updates);
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseStoreService.updateStoreInfo',
      );
    }
  }
}

/// Service for sales metrics tracking
class FranchiseSalesService {
  final FirebaseFirestore _firestore;

  FranchiseSalesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Record daily sales
  Future<String> recordDailySales({
    required String storeId,
    required double dailySales,
    required int transactionCount,
    required double estimatedCogs,
    required String notes,
  }) async {
    try {
      final avgTransaction =
          transactionCount > 0 ? dailySales / transactionCount : 0;
      final estimatedGrossProfit = dailySales - estimatedCogs;
      final profitMargin =
          dailySales > 0 ? (estimatedGrossProfit / dailySales) * 100 : 0;

      final metric = SalesMetric(
        id: '', // Firestore will generate
        storeId: storeId,
        date: DateTime.now(),
        dailySales: dailySales.toDouble(),
        transactionCount: transactionCount,
        avgTransactionValue: avgTransaction as double,
        estimatedCogs: estimatedCogs.toDouble(),
        estimatedGrossProfit: (estimatedGrossProfit as num).toDouble(),
        profitMargin: profitMargin as double,
        notes: notes,
        recordedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('franchise_sales_metrics')
          .add(metric.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseSalesService.recordDailySales',
      );
    }
  }

  /// Get daily sales for date range
  Future<List<SalesMetric>> getDailySales(
      String storeId, DateTime startDate, DateTime endDate) async {
    try {
      final query = await _firestore
          .collection('franchise_sales_metrics')
          .where('storeId', isEqualTo: storeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return query.docs.map((doc) => SalesMetric.fromFirestore(doc)).toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseSalesService.getDailySales',
      );
    }
  }

  /// Get sales summary for period
  Future<SalesSummary> getSalesSummary(
      String storeId, DateTime startDate, DateTime endDate) async {
    try {
      final metrics = await getDailySales(storeId, startDate, endDate);

      double totalSales = 0;
      double totalCogs = 0;
      double totalGrossProfit = 0;
      int totalTransactions = 0;

      for (final metric in metrics) {
        totalSales += metric.dailySales;
        totalCogs += metric.estimatedCogs;
        totalGrossProfit += metric.estimatedGrossProfit;
        totalTransactions += metric.transactionCount;
      }

      final avgProfitMargin =
          totalSales > 0 ? (totalGrossProfit / totalSales) * 100 : 0;
      final avgTransaction =
          totalTransactions > 0 ? totalSales / totalTransactions : 0;

      return SalesSummary(
        periodStart: startDate,
        periodEnd: endDate,
        totalSales: totalSales.toDouble(),
        totalCogs: totalCogs.toDouble(),
        totalGrossProfit: totalGrossProfit.toDouble(),
        totalTransactions: totalTransactions,
        avgDailySales:
            metrics.isEmpty ? 0 : (totalSales / metrics.length).toDouble(),
        avgTransactionValue: avgTransaction as double,
        avgProfitMargin: avgProfitMargin as double,
        daysWithData: metrics.length,
      );
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseSalesService.getSalesSummary',
      );
    }
  }
}

/// Service for franchise inventory management
class FranchiseInventoryService {
  final FirebaseFirestore _firestore;

  FranchiseInventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get inventory for store
  Future<List<FranchiseInventoryItem>> getStoreInventory(String storeId) async {
    try {
      final query = await _firestore
          .collection('franchise_inventory')
          .where('storeId', isEqualTo: storeId)
          .get();

      return query.docs
          .map((doc) => FranchiseInventoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseInventoryService.getStoreInventory',
      );
    }
  }

  /// Get low stock items
  Future<List<FranchiseInventoryItem>> getLowStockItems(String storeId) async {
    try {
      final inventory = await getStoreInventory(storeId);
      return inventory.where((item) => item.isLowStock()).toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseInventoryService.getLowStockItems',
      );
    }
  }

  /// Get items needing reorder
  Future<List<FranchiseInventoryItem>> getReorderItems(String storeId) async {
    try {
      final inventory = await getStoreInventory(storeId);
      // Items needing reorder when qty < reorder quantity
      return inventory
          .where((item) => item.quantity < item.getReorderQuantity())
          .toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseInventoryService.getReorderItems',
      );
    }
  }

  /// Update inventory item
  Future<void> updateInventoryItem(
    String itemId, {
    required int newQuantity,
    String? notes,
  }) async {
    try {
      await _firestore.collection('franchise_inventory').doc(itemId).update({
        'quantity': newQuantity,
        'lastCountDate': Timestamp.now(),
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseInventoryService.updateInventoryItem',
      );
    }
  }

  /// Get inventory value for store
  Future<double> getInventoryValue(String storeId) async {
    try {
      final inventory = await getStoreInventory(storeId);
      return inventory.fold<double>(
        0,
        (sum, item) => sum + (item.quantity * item.unitCost),
      );
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseInventoryService.getInventoryValue',
      );
    }
  }
}

/// Service for compliance checklist management
class FranchiseComplianceService {
  final FirebaseFirestore _firestore;

  FranchiseComplianceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get checklist for date
  Future<ComplianceChecklist?> getChecklistForDate(
      String storeId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

      final query = await _firestore
          .collection('franchise_compliance')
          .where('storeId', isEqualTo: storeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (query.docs.isEmpty) return null;
      return ComplianceChecklist.fromFirestore(query.docs.first);
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseComplianceService.getChecklistForDate',
      );
    }
  }

  /// Create new checklist
  Future<String> createChecklist({
    required String storeId,
    required DateTime date,
    required List<ComplianceItem> items,
  }) async {
    try {
      final checklist = ComplianceChecklist(
        id: '', // Firestore will generate
        storeId: storeId,
        date: date,
        items: items,
        completedCount: 0,
        totalCount: items.length,
        completionPercentage: 0,
        status: 'pending',
        notes: '',
      );

      final docRef = await _firestore
          .collection('franchise_compliance')
          .add(checklist.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseComplianceService.createChecklist',
      );
    }
  }

  /// Mark item complete
  Future<void> completeItem(
    String checklistId,
    String itemId, {
    String? photoUrl,
    String? notes,
    String? completedBy,
  }) async {
    try {
      final checklist = await _firestore
          .collection('franchise_compliance')
          .doc(checklistId)
          .get();
      if (!checklist.exists) {
        throw BusinessLogicException(
          message: 'Checklist not found',
          code: 'CHECKLIST_NOT_FOUND',
        );
      }

      final data = checklist.data() as Map<String, dynamic>;
      final items =
          (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();

      // Find and update item
      for (final item in items) {
        if (item['id'] == itemId) {
          item['isCompleted'] = true;
          item['photoUrl'] = photoUrl;
          item['notes'] = notes;
          item['completedAt'] = Timestamp.now();
          item['completedBy'] = completedBy;
          break;
        }
      }

      // Calculate completion
      final completedCount =
          items.where((item) => item['isCompleted'] == true).length;
      final completionPercentage =
          items.isEmpty ? 0 : (completedCount / items.length) * 100;

      await _firestore
          .collection('franchise_compliance')
          .doc(checklistId)
          .update({
        'items': items,
        'completedCount': completedCount,
        'completionPercentage': completionPercentage,
        'status': completedCount == items.length ? 'completed' : 'in_progress',
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseComplianceService.completeItem',
      );
    }
  }

  /// Get compliance score for period
  Future<ComplianceScore> getComplianceScore(
    String storeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('franchise_compliance')
          .where('storeId', isEqualTo: storeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int completedChecklists = 0;
      double totalCompletionRate = 0;
      final violations = <String>[];

      for (final doc in query.docs) {
        final checklist = ComplianceChecklist.fromFirestore(doc);
        if (checklist.status == 'completed') {
          completedChecklists++;
        }
        totalCompletionRate += checklist.completionPercentage;

        // Track violations
        for (final item in checklist.items) {
          if (!item.isCompleted) {
            violations.add('${item.title}: ${item.description}');
          }
        }
      }

      final avgCompletionRate = query.docs.isEmpty
          ? 0.0
          : (totalCompletionRate / query.docs.length).toDouble();
      final complianceScore = avgCompletionRate;

      return ComplianceScore(
        id: '', // Will be generated when saved
        storeId: storeId,
        dateStart: startDate,
        dateEnd: endDate,
        period: _getPeriod(startDate, endDate),
        totalChecklistsCompleted: completedChecklists,
        totalChecklistsRequired: query.docs.length,
        completionRate: avgCompletionRate,
        complianceScore: complianceScore,
        violations: violations,
        trend: 'stable', // Can be calculated by comparing to previous period
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'FranchiseComplianceService.getComplianceScore',
      );
    }
  }

  String _getPeriod(DateTime start, DateTime end) {
    final daysDiff = end.difference(start).inDays;
    if (daysDiff <= 1) return 'daily';
    if (daysDiff <= 7) return 'weekly';
    return 'monthly';
  }
}

class SalesSummary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalSales;
  final double totalCogs;
  final double totalGrossProfit;
  final int totalTransactions;
  final double avgDailySales;
  final double avgTransactionValue;
  final double avgProfitMargin;
  final int daysWithData;

  SalesSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSales,
    required this.totalCogs,
    required this.totalGrossProfit,
    required this.totalTransactions,
    required this.avgDailySales,
    required this.avgTransactionValue,
    required this.avgProfitMargin,
    required this.daysWithData,
  });
}
