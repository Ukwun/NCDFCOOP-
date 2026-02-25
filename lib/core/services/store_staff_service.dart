import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/models/store_staff_models.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';
import 'package:coop_commerce/core/auth/role.dart' as auth_role;

/// Service for Store Staff POS, sales, and inventory operations
class StoreStaffService {
  static final StoreStaffService _instance = StoreStaffService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService = AuditLogService();

  factory StoreStaffService() {
    return _instance;
  }

  StoreStaffService._internal();

  // ==================== POS OPERATIONS ====================

  /// Record a POS transaction for a single item
  Future<String> recordPOSTransaction({
    required String storeId,
    required String staffId,
    required String staffName,
    required String productId,
    required String productName,
    required double unitPrice,
    required int quantity,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final subtotal = unitPrice * quantity;
      final taxAmount = subtotal * 0.075; // 7.5% tax
      final total = subtotal + taxAmount;

      final transaction = POSTransaction(
        id: _firestore.collection('dummy').doc().id,
        storeId: storeId,
        staffId: staffId,
        staffName: staffName,
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity,
        subtotal: subtotal,
        taxAmount: taxAmount,
        total: total,
        paymentMethod: paymentMethod,
        status: 'completed',
        timestamp: DateTime.now(),
        notes: notes,
        receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('pos_transactions')
          .add(transaction.toFirestore());

      // Update daily sales
      await _updateDailySalesSummary(storeId, transaction);

      // Update inventory (decrement)
      await _decrementStoreInventory(storeId, productId, quantity);

      // Audit log
      if (staffId.isNotEmpty) {
        await _auditLogService.logAction(
          staffId,
          auth_role.UserRole.storeStaff.name,
          AuditAction.TRANSACTION_RECORDED,
          'pos_transaction',
          resourceId: docRef.id,
          severity: AuditSeverity.INFO,
          details: {
            'store_id': storeId,
            'product_id': productId,
            'quantity': quantity,
            'total': total,
          },
        );
      }

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get POS transactions for a date range
  Future<List<POSTransaction>> getTransactions(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('pos_transactions');

      if (startDate != null) {
        query =
            query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => POSTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Return mock data on error
      return _getMockTransactions();
    }
  }

  /// Get a single transaction
  Future<POSTransaction?> getTransaction(String storeId, String transactionId) async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('pos_transactions')
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return POSTransaction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== INVENTORY OPERATIONS ====================

  /// Get store inventory (filtered to store only)
  Future<List<StoreInventoryItem>> getStoreInventory(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('inventory')
          .get();

      return snapshot.docs
          .map((doc) => StoreInventoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Return mock inventory
      return _getMockInventory(storeId);
    }
  }

  /// Get low stock items for this store only
  Future<List<StoreInventoryItem>> getLowStockItems(String storeId) async {
    try {
      final inventory = await getStoreInventory(storeId);
      return inventory.where((item) => item.isLowStock).toList();
    } catch (e) {
      return [];
    }
  }

  /// Adjust stock with audit trail
  Future<String> adjustStock({
    required String storeId,
    required String staffId,
    required String staffName,
    required String productId,
    required String productName,
    required int previousQuantity,
    required int newQuantity,
    required String reason,
    String? notes,
  }) async {
    try {
      final adjustmentAmount = newQuantity - previousQuantity;

      final adjustment = StockAdjustment(
        id: _firestore.collection('dummy').doc().id,
        storeId: storeId,
        productId: productId,
        productName: productName,
        staffId: staffId,
        staffName: staffName,
        previousQuantity: previousQuantity,
        newQuantity: newQuantity,
        adjustmentAmount: adjustmentAmount,
        reason: reason,
        notes: notes,
        timestamp: DateTime.now(),
      );

      // Save adjustment log
      final docRef = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('stock_adjustments')
          .add(adjustment.toFirestore());

      // Update inventory
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('inventory')
          .doc(productId)
          .update({'quantity': newQuantity});

      // Audit log
      await _auditLogService.logAction(
        staffId,
        auth_role.UserRole.storeStaff.name,
        AuditAction.INVENTORY_ADJUSTED,
        'stock_adjustment',
        resourceId: docRef.id,
        severity: AuditSeverity.WARNING,
        details: {
          'store_id': storeId,
          'product_id': productId,
          'adjustment': adjustmentAmount,
          'reason': reason,
        },
      );

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get stock adjustment history
  Future<List<StockAdjustment>> getAdjustmentHistory(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('stock_adjustments')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => StockAdjustment.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== DAILY SALES ====================

  /// Get or create daily sales summary
  Future<DailySalesSummary> getDailySalesSummary(String storeId, String storeName) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('daily_sales')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        return DailySalesSummary.fromFirestore(doc);
      }

      // Create new summary
      return DailySalesSummary(
        id: dateKey,
        storeId: storeId,
        storeName: storeName,
        date: today,
        totalTransactions: 0,
        totalRevenue: 0,
        totalCost: 0,
        totalProfit: 0,
        averageTransaction: 0,
        paymentMethodBreakdown: {},
        topProductCount: 0,
        topProducts: [],
        activeStaffCount: 0,
        status: 'open',
      );
    } catch (e) {
      // Return mock summary
      return _getMockDailySummary(storeId, storeName);
    }
  }

  /// Helper: Update daily sales summary after each transaction
  Future<void> _updateDailySalesSummary(
    String storeId,
    POSTransaction transaction,
  ) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final docRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('daily_sales')
          .doc(dateKey);

      await _firestore.runTransaction((txn) async {
        final doc = await txn.get(docRef);

        if (doc.exists) {
          final existing = doc.data() as Map<String, dynamic>;
          final currentTotal = (existing['totalRevenue'] as num?)?.toDouble() ?? 0;
          final currentCount = (existing['totalTransactions'] as int?) ?? 0;
          final paymentBreakdown =
              Map<String, int>.from(existing['paymentMethodBreakdown'] ?? {});

          // Update payment method count
          paymentBreakdown[transaction.paymentMethod] =
              (paymentBreakdown[transaction.paymentMethod] ?? 0) + 1;

          txn.update(docRef, {
            'totalTransactions': currentCount + 1,
            'totalRevenue': currentTotal + transaction.total,
            'averageTransaction':
                (currentTotal + transaction.total) / (currentCount + 1),
            'paymentMethodBreakdown': paymentBreakdown,
          });
        } else {
          // Create new summary
          txn.set(docRef, {
            'storeId': storeId,
            'date': FieldValue.serverTimestamp(),
            'totalTransactions': 1,
            'totalRevenue': transaction.total,
            'totalCost': 0,
            'totalProfit': 0,
            'averageTransaction': transaction.total,
            'paymentMethodBreakdown': {transaction.paymentMethod: 1},
            'topProductCount': 0,
            'topProducts': [],
            'activeStaffCount': 0,
            'status': 'open',
          });
        }
      });
    } catch (e) {
      // Silently fail for now
    }
  }

  /// Helper: Decrement store inventory
  Future<void> _decrementStoreInventory(
    String storeId,
    String productId,
    int quantity,
  ) async {
    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('inventory')
          .doc(productId)
          .update({
        'quantity': FieldValue.increment(-quantity),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // ==================== MOCK DATA ====================

  List<POSTransaction> _getMockTransactions() {
    return [
      POSTransaction(
        id: 'trans_001',
        storeId: 'store_001',
        staffId: 'staff_001',
        staffName: 'John Doe',
        productId: 'prod_001',
        productName: 'Rice 10kg',
        unitPrice: 5000,
        quantity: 2,
        subtotal: 10000,
        taxAmount: 750,
        total: 10750,
        paymentMethod: 'cash',
        status: 'completed',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        receiptNumber: 'RCP-001',
      ),
      POSTransaction(
        id: 'trans_002',
        storeId: 'store_001',
        staffId: 'staff_001',
        staffName: 'John Doe',
        productId: 'prod_002',
        productName: 'Beans 2kg',
        unitPrice: 2000,
        quantity: 3,
        subtotal: 6000,
        taxAmount: 450,
        total: 6450,
        paymentMethod: 'card',
        status: 'completed',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        receiptNumber: 'RCP-002',
      ),
    ];
  }

  List<StoreInventoryItem> _getMockInventory(String storeId) {
    return [
      StoreInventoryItem(
        id: 'inv_001',
        storeId: storeId,
        productId: 'prod_001',
        productName: 'Rice 10kg',
        sku: 'SK-001',
        quantity: 45,
        minimumLevel: 10,
        costPrice: 4500,
        salePrice: 5000,
        lastAdjustment: DateTime.now(),
      ),
      StoreInventoryItem(
        id: 'inv_002',
        storeId: storeId,
        productId: 'prod_002',
        productName: 'Beans 2kg',
        sku: 'SK-002',
        quantity: 8,
        minimumLevel: 10,
        costPrice: 1800,
        salePrice: 2000,
        lastAdjustment: DateTime.now(),
        adjustmentNotes: 'Low stock alert',
      ),
      StoreInventoryItem(
        id: 'inv_003',
        storeId: storeId,
        productId: 'prod_003',
        productName: 'Sugar 1kg',
        sku: 'SK-003',
        quantity: 75,
        minimumLevel: 20,
        costPrice: 800,
        salePrice: 1000,
        lastAdjustment: DateTime.now(),
      ),
    ];
  }

  DailySalesSummary _getMockDailySummary(String storeId, String storeName) {
    return DailySalesSummary(
      id: 'summary_${DateTime.now().toString().split(' ')[0]}',
      storeId: storeId,
      storeName: storeName,
      date: DateTime.now(),
      totalTransactions: 24,
      totalRevenue: 125000,
      totalCost: 75000,
      totalProfit: 50000,
      averageTransaction: 5208.33,
      paymentMethodBreakdown: {'cash': 16, 'card': 6, 'mobile_money': 2},
      topProductCount: 3,
      topProducts: [
        TopProduct(
          productId: 'prod_001',
          productName: 'Rice 10kg',
          unitsSold: 15,
          revenue: 75000,
        ),
        TopProduct(
          productId: 'prod_002',
          productName: 'Beans 2kg',
          unitsSold: 8,
          revenue: 32000,
        ),
      ],
      activeStaffCount: 3,
      status: 'open',
    );
  }
}

final storeStaffServiceProvider = Provider<StoreStaffService>((ref) {
  return StoreStaffService();
});
