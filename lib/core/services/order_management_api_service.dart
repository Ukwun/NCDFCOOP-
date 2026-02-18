import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/services/order_fulfillment_service.dart';

/// Service for order management API operations
class OrderManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';

  // CRUD Operations

  /// Get all orders with pagination and filtering
  Future<OrderPage> getAllOrders({
    String? status,
    String? buyerId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdAt',
    bool ascending = false,
  }) async {
    try {
      Query query = _firestore.collection(_ordersCollection);

      // Apply filters
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (buyerId != null) {
        query = query.where('buyerId', isEqualTo: buyerId);
      }

      if (dateFrom != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: dateFrom);
      }

      if (dateTo != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: dateTo);
      }

      // Get total count
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // Apply sorting and pagination
      final sortQuery = query.orderBy(sortBy, descending: !ascending);

      final snapshot = await sortQuery.get();

      final offset = (page - 1) * pageSize;
      final paginatedDocs = snapshot.docs.skip(offset).take(pageSize).toList();

      final orders =
          paginatedDocs.map((doc) => OrderData.fromFirestore(doc)).toList();

      return OrderPage(
        orders: orders,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        totalPages: (totalCount / pageSize).ceil(),
      );
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Search orders by order ID, buyer name, or product
  Future<List<OrderData>> searchOrders({
    required String query,
    int limit = 20,
  }) async {
    try {
      // Search by order ID (exact match)
      final orderIdSnapshot = await _firestore
          .collection(_ordersCollection)
          .where('orderId', isEqualTo: query)
          .limit(limit)
          .get();

      if (orderIdSnapshot.docs.isNotEmpty) {
        return orderIdSnapshot.docs
            .map((doc) => OrderData.fromFirestore(doc))
            .toList();
      }

      // Search by buyer ID
      final buyerSnapshot = await _firestore
          .collection(_ordersCollection)
          .where('buyerId', isEqualTo: query)
          .limit(limit)
          .get();

      return buyerSnapshot.docs
          .map((doc) => OrderData.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  /// Get order by ID
  Future<OrderData?> getOrderById(String orderId) async {
    try {
      final doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) return null;

      return OrderData.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Update order shipping address
  Future<void> updateShippingAddress({
    required String orderId,
    required String newAddress,
  }) async {
    try {
      final doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) {
        throw Exception('Order not found');
      }

      final orderData = doc.data() as Map<String, dynamic>;
      final status = orderData['status'] as String;

      // Can only update if order is still in draft or approved status
      if (status != 'draft' && status != 'approved') {
        throw Exception(
            'Cannot update shipping address for order in $status status');
      }

      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'shippingAddress': newAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update shipping address: $e');
    }
  }

  /// Update order notes
  Future<void> updateOrderNotes({
    required String orderId,
    required String notes,
  }) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order notes: $e');
    }
  }

  // Analytics & Reporting

  /// Get order statistics for a date range
  Future<OrderStatistics> getOrderStatistics({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? buyerId,
  }) async {
    try {
      Query query = _firestore
          .collection(_ordersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: dateFrom)
          .where('createdAt', isLessThanOrEqualTo: dateTo);

      if (buyerId != null) {
        query = query.where('buyerId', isEqualTo: buyerId);
      }

      final snapshot = await query.get();

      double totalAmount = 0;
      double totalTax = 0;
      double totalShipping = 0;
      int totalOrders = snapshot.docs.length;
      Map<String, int> statusCounts = {};
      List<double> amounts = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['totalAmount'] as num).toDouble();
        final tax = (data['tax'] as num).toDouble();
        final shipping = (data['shippingCost'] as num).toDouble();
        final status = data['status'] as String;

        totalAmount += amount;
        totalTax += tax;
        totalShipping += shipping;
        amounts.add(amount);

        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      amounts.sort();
      final avgAmount = totalOrders > 0 ? totalAmount / totalOrders : 0.0;
      final medianAmount =
          amounts.isNotEmpty ? amounts[amounts.length ~/ 2].toDouble() : 0.0;
      final maxAmount = amounts.isNotEmpty ? amounts.last.toDouble() : 0.0;
      final minAmount = amounts.isNotEmpty ? amounts.first.toDouble() : 0.0;

      return OrderStatistics(
        totalOrders: totalOrders,
        totalAmount: totalAmount,
        totalTax: totalTax,
        totalShipping: totalShipping,
        averageOrderValue: avgAmount,
        medianOrderValue: medianAmount,
        maxOrderValue: maxAmount,
        minOrderValue: minAmount,
        statusCounts: statusCounts,
      );
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  /// Get top buyers
  Future<List<BuyerStatistics>> getTopBuyers({
    required DateTime dateFrom,
    required DateTime dateTo,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: dateFrom)
          .where('createdAt', isLessThanOrEqualTo: dateTo)
          .get();

      Map<String, BuyerStats> buyerStats = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final buyerId = data['buyerId'] as String;
        final amount = (data['totalAmount'] as num).toDouble();

        if (buyerStats.containsKey(buyerId)) {
          buyerStats[buyerId]!.totalSpent += amount;
          buyerStats[buyerId]!.orderCount += 1;
        } else {
          buyerStats[buyerId] = BuyerStats(
            buyerId: buyerId,
            totalSpent: amount,
            orderCount: 1,
          );
        }
      }

      final sortedBuyers = buyerStats.values.toList()
        ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      return sortedBuyers
          .take(limit)
          .map((stat) => BuyerStatistics(
                buyerId: stat.buyerId,
                totalSpent: stat.totalSpent,
                orderCount: stat.orderCount,
                averageOrderValue: stat.totalSpent / stat.orderCount,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get top buyers: $e');
    }
  }

  /// Get order fulfillment status summary
  Future<FulfillmentStatusSummary> getFulfillmentStatusSummary({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: dateFrom)
          .where('createdAt', isLessThanOrEqualTo: dateTo)
          .get();

      Map<String, int> statusCounts = {};
      int totalOrders = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return FulfillmentStatusSummary(
        totalOrders: totalOrders,
        statusCounts: statusCounts,
        deliveredCount: statusCounts['delivered'] ?? 0,
        shippedCount: statusCounts['shipped'] ?? 0,
        packedCount: statusCounts['packed'] ?? 0,
        processingCount: statusCounts['processing'] ?? 0,
        pendingCount: statusCounts['approved'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to get fulfillment status summary: $e');
    }
  }

  /// Export orders to list format
  Future<List<OrderExport>> exportOrders({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? status,
    String? buyerId,
  }) async {
    try {
      Query query = _firestore
          .collection(_ordersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: dateFrom)
          .where('createdAt', isLessThanOrEqualTo: dateTo);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (buyerId != null) {
        query = query.where('buyerId', isEqualTo: buyerId);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return OrderExport(
          orderId: data['orderId'] as String,
          buyerId: data['buyerId'] as String,
          totalAmount: (data['totalAmount'] as num).toDouble(),
          status: data['status'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          itemCount: (data['items'] as List).length,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to export orders: $e');
    }
  }
}

// Data models for API responses

class OrderPage {
  final List<OrderData> orders;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  OrderPage({
    required this.orders,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}

class OrderStatistics {
  final int totalOrders;
  final double totalAmount;
  final double totalTax;
  final double totalShipping;
  final double averageOrderValue;
  final double medianOrderValue;
  final double maxOrderValue;
  final double minOrderValue;
  final Map<String, int> statusCounts;

  OrderStatistics({
    required this.totalOrders,
    required this.totalAmount,
    required this.totalTax,
    required this.totalShipping,
    required this.averageOrderValue,
    required this.medianOrderValue,
    required this.maxOrderValue,
    required this.minOrderValue,
    required this.statusCounts,
  });
}

class BuyerStatistics {
  final String buyerId;
  final double totalSpent;
  final int orderCount;
  final double averageOrderValue;

  BuyerStatistics({
    required this.buyerId,
    required this.totalSpent,
    required this.orderCount,
    required this.averageOrderValue,
  });
}

class BuyerStats {
  String buyerId;
  double totalSpent;
  int orderCount;

  BuyerStats({
    required this.buyerId,
    required this.totalSpent,
    required this.orderCount,
  });
}

class FulfillmentStatusSummary {
  final int totalOrders;
  final Map<String, int> statusCounts;
  final int deliveredCount;
  final int shippedCount;
  final int packedCount;
  final int processingCount;
  final int pendingCount;

  FulfillmentStatusSummary({
    required this.totalOrders,
    required this.statusCounts,
    required this.deliveredCount,
    required this.shippedCount,
    required this.packedCount,
    required this.processingCount,
    required this.pendingCount,
  });
}

class OrderExport {
  final String orderId;
  final String buyerId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final int itemCount;

  OrderExport({
    required this.orderId,
    required this.buyerId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.itemCount,
  });
}
