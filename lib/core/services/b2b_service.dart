import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/b2b_models.dart';
import '../utils/error_handler.dart';

/// Service for Purchase Order management
class PurchaseOrderService {
  final FirebaseFirestore _firestore;

  PurchaseOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new PO
  Future<String> createPurchaseOrder({
    required String institutionId,
    required String institutionName,
    required List<PurchaseOrderLineItem> lineItems,
    required DateTime expectedDeliveryDate,
    required String deliveryAddress,
    required String specialInstructions,
    required String createdBy,
    required List<String> approvalChain,
    required String paymentTerms,
  }) async {
    try {
      // Validate MOQ for all line items
      for (var item in lineItems) {
        if (!item.meetsMinimumOrderQuantity()) {
          throw BusinessLogicException(
            message:
                '${item.productName} has minimum order quantity of ${item.minimumOrderQuantity}',
            code: 'MINIMUM_ORDER_QUANTITY',
          );
        }
      }

      // Calculate totals
      final subtotal = lineItems.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final taxAmount = subtotal * 0.1; // 10% tax
      final totalAmount = subtotal + taxAmount;

      // Create PO
      final po = PurchaseOrder(
        id: '', // Firestore will generate
        institutionId: institutionId,
        institutionName: institutionName,
        status: 'draft',
        lineItems: lineItems,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentTerms: paymentTerms,
        creditLimit: 50000, // Default, can be customized
        creditUsed: totalAmount,
        createdDate: DateTime.now(),
        expectedDeliveryDate: expectedDeliveryDate,
        deliveryAddress: deliveryAddress,
        specialInstructions: specialInstructions,
        createdBy: createdBy,
        approvalChain: approvalChain,
        approvalStatus: {},
        notes: null,
      );

      final docRef =
          await _firestore.collection('purchase_orders').add(po.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.createPurchaseOrder',
      );
    }
  }

  /// Get PO by ID
  Future<PurchaseOrder?> getPurchaseOrder(String poId) async {
    try {
      final doc =
          await _firestore.collection('purchase_orders').doc(poId).get();
      if (!doc.exists) return null;
      return PurchaseOrder.fromFirestore(doc);
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.getPurchaseOrder',
      );
    }
  }

  /// Get all POs for institution
  Future<List<PurchaseOrder>> getInstitutionPurchaseOrders(
      String institutionId) async {
    try {
      final query = await _firestore
          .collection('purchase_orders')
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('createdDate', descending: true)
          .get();

      return query.docs.map((doc) => PurchaseOrder.fromFirestore(doc)).toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.getInstitutionPurchaseOrders',
      );
    }
  }

  /// Get POs pending approval for user
  Future<List<PurchaseOrder>> getPendingApprovals(String userId) async {
    try {
      final query = await _firestore
          .collection('purchase_orders')
          .where('status', isEqualTo: 'pending')
          .where('approvalChain', arrayContains: userId)
          .orderBy('createdDate', descending: true)
          .get();

      return query.docs.map((doc) => PurchaseOrder.fromFirestore(doc)).toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.getPendingApprovals',
      );
    }
  }

  /// Update PO status
  Future<void> updatePurchaseOrderStatus(String poId, String newStatus) async {
    try {
      await _firestore.collection('purchase_orders').doc(poId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.updatePurchaseOrderStatus',
      );
    }
  }

  /// Submit PO for approval
  Future<void> submitForApproval(
      String poId, List<String> approvalChain) async {
    try {
      final po = await getPurchaseOrder(poId);
      if (po == null) {
        throw BusinessLogicException(
          message: 'Purchase order not found',
          code: 'PO_NOT_FOUND',
        );
      }

      if (po.status != 'draft') {
        throw BusinessLogicException(
          message: 'Only draft POs can be submitted for approval',
          code: 'INVALID_PO_STATUS',
        );
      }

      await _firestore.collection('purchase_orders').doc(poId).update({
        'status': 'pending',
        'approvalChain': approvalChain,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.submitForApproval',
      );
    }
  }

  /// Approve PO
  Future<void> approvePurchaseOrder(
      String poId, String userId, String notes) async {
    try {
      final po = await getPurchaseOrder(poId);
      if (po == null) {
        throw BusinessLogicException(
          message: 'Purchase order not found',
          code: 'PO_NOT_FOUND',
        );
      }

      // Update approval status
      final updatedApprovalStatus =
          Map<String, dynamic>.from(po.approvalStatus);
      updatedApprovalStatus[userId] = {
        'approved': true,
        'timestamp': Timestamp.now(),
        'notes': notes,
      };

      // Check if all approvals done
      bool allApproved = true;
      for (final approverId in po.approvalChain) {
        if (!updatedApprovalStatus.containsKey(approverId) ||
            updatedApprovalStatus[approverId]['approved'] != true) {
          allApproved = false;
          break;
        }
      }

      final newStatus = allApproved ? 'approved' : 'pending';

      await _firestore.collection('purchase_orders').doc(poId).update({
        'approvalStatus': updatedApprovalStatus,
        'status': newStatus,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.approvePurchaseOrder',
      );
    }
  }

  /// Reject PO
  Future<void> rejectPurchaseOrder(
      String poId, String userId, String reason) async {
    try {
      await _firestore.collection('purchase_orders').doc(poId).update({
        'status': 'rejected',
        'approvalStatus.$userId': {
          'approved': false,
          'timestamp': Timestamp.now(),
          'reason': reason,
        },
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.rejectPurchaseOrder',
      );
    }
  }

  /// Delete PO (only draft)
  Future<void> deletePurchaseOrder(String poId) async {
    try {
      final po = await getPurchaseOrder(poId);
      if (po == null) {
        throw BusinessLogicException(
          message: 'Purchase order not found',
          code: 'PO_NOT_FOUND',
        );
      }

      if (po.status != 'draft') {
        throw BusinessLogicException(
          message: 'Can only delete draft purchase orders',
          code: 'CANNOT_DELETE_PO',
        );
      }

      await _firestore.collection('purchase_orders').doc(poId).delete();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'PurchaseOrderService.deletePurchaseOrder',
      );
    }
  }
}

/// Service for contract pricing
class ContractPricingService {
  final FirebaseFirestore _firestore;

  ContractPricingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get contract price for institution + product
  Future<ContractPrice?> getContractPrice(
      String institutionId, String productId) async {
    try {
      final query = await _firestore
          .collection('contract_prices')
          .where('institutionId', isEqualTo: institutionId)
          .where('productId', isEqualTo: productId)
          .where('isActive', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final contractPrice = ContractPrice.fromFirestore(doc);

      // Check if still valid date range
      final now = DateTime.now();
      if (now.isBefore(contractPrice.startDate) ||
          now.isAfter(contractPrice.endDate)) {
        return null;
      }

      return contractPrice;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'ContractPricingService.getContractPrice',
      );
    }
  }

  /// Get all contract prices for institution
  Future<List<ContractPrice>> getInstitutionContractPrices(
      String institutionId) async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection('contract_prices')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      final prices = query.docs
          .map((doc) => ContractPrice.fromFirestore(doc))
          .where((cp) => now.isAfter(cp.startDate) && now.isBefore(cp.endDate))
          .toList();

      return prices;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'ContractPricingService.getInstitutionContractPrices',
      );
    }
  }

  /// Create contract price
  Future<String> createContractPrice({
    required String institutionId,
    required String productId,
    required String productName,
    required String sku,
    required double contractPrice,
    required double retailPrice,
    required int minimumOrderQuantity,
    required int casePack,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final price = ContractPrice(
        id: '', // Firestore will generate
        institutionId: institutionId,
        productId: productId,
        productName: productName,
        sku: sku,
        contractPrice: contractPrice,
        retailPrice: retailPrice,
        minimumOrderQuantity: minimumOrderQuantity,
        casePack: casePack,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        discountType: 'fixed',
        discountValue: retailPrice - contractPrice,
      );

      final docRef = await _firestore
          .collection('contract_prices')
          .add(price.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'ContractPricingService.createContractPrice',
      );
    }
  }

  /// Deactivate contract price
  Future<void> deactivateContractPrice(String priceId) async {
    try {
      await _firestore.collection('contract_prices').doc(priceId).update({
        'isActive': false,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'ContractPricingService.deactivateContractPrice',
      );
    }
  }
}

/// Service for invoice management
class InvoiceService {
  final FirebaseFirestore _firestore;

  InvoiceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create invoice from PO
  Future<String> createInvoiceFromPO({
    required String poId,
    required String institutionId,
    required String institutionName,
    required List<InvoiceLineItem> lineItems,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    required String paymentTerms,
    required String deliveryAddress,
  }) async {
    try {
      // Calculate due date based on payment terms
      final dueDate = _calculateDueDate(DateTime.now(), paymentTerms);

      final invoice = Invoice(
        id: '', // Firestore will generate
        poId: poId,
        institutionId: institutionId,
        institutionName: institutionName,
        status: 'issued',
        lineItems: lineItems,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        amountPaid: 0,
        paymentTerms: paymentTerms,
        issuedDate: DateTime.now(),
        dueDate: dueDate,
        deliveryAddress: deliveryAddress,
        notes: '',
      );

      final docRef =
          await _firestore.collection('invoices').add(invoice.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'InvoiceService.createInvoiceFromPO',
      );
    }
  }

  /// Get invoice by ID
  Future<Invoice?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (!doc.exists) return null;
      return Invoice.fromFirestore(doc);
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'InvoiceService.getInvoice',
      );
    }
  }

  /// Get invoices for institution
  Future<List<Invoice>> getInstitutionInvoices(String institutionId) async {
    try {
      final query = await _firestore
          .collection('invoices')
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('issuedDate', descending: true)
          .get();

      return query.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'InvoiceService.getInstitutionInvoices',
      );
    }
  }

  /// Record payment
  Future<void> recordPayment(String invoiceId, double amount) async {
    try {
      final invoice = await getInvoice(invoiceId);
      if (invoice == null) {
        throw BusinessLogicException(
          message: 'Invoice not found',
          code: 'INVOICE_NOT_FOUND',
        );
      }

      final newAmountPaid = invoice.amountPaid + amount;
      final newStatus =
          newAmountPaid >= invoice.totalAmount ? 'paid' : 'issued';

      await _firestore.collection('invoices').doc(invoiceId).update({
        'amountPaid': newAmountPaid,
        'status': newStatus,
      });
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'InvoiceService.recordPayment',
      );
    }
  }

  /// Get overdue invoices
  Future<List<Invoice>> getOverdueInvoices(String institutionId) async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection('invoices')
          .where('institutionId', isEqualTo: institutionId)
          .where('status', isNotEqualTo: 'paid')
          .get();

      final invoices = query.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .where((inv) => inv.isOverdue())
          .toList();

      return invoices;
    } catch (e) {
      throw ErrorHandler.logError(
        e,
        context: 'InvoiceService.getOverdueInvoices',
      );
    }
  }

  DateTime _calculateDueDate(DateTime issueDate, String paymentTerms) {
    // Parse payment terms (e.g., "Net 30", "Net 60")
    final days = int.tryParse(paymentTerms.replaceAll('Net ', '')) ?? 30;
    return issueDate.add(Duration(days: days));
  }
}
