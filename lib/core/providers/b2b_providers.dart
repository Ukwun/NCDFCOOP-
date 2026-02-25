import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/b2b_models.dart';
import '../services/b2b_service.dart';
import '../../features/welcome/auth_provider.dart';

// Service providers
final purchaseOrderServiceProvider = Provider((ref) {
  return PurchaseOrderService();
});

final contractPricingServiceProvider = Provider((ref) {
  return ContractPricingService();
});

final invoiceServiceProvider = Provider((ref) {
  return InvoiceService();
});

// Purchase Order Providers

/// Get all POs for current institution
final institutionPurchaseOrdersProvider =
    StreamProvider.family<List<PurchaseOrder>, String>((ref, institutionId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('purchase_orders')
      .where('institutionId', isEqualTo: institutionId)
      .orderBy('createdDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => PurchaseOrder.fromFirestore(doc))
        .toList();
  });
});

/// Get single PO by ID
final purchaseOrderProvider =
    FutureProvider.family<PurchaseOrder?, String>((ref, poId) async {
  final service = ref.watch(purchaseOrderServiceProvider);
  return service.getPurchaseOrder(poId);
});

/// Get POs pending approval for current user
final pendingApprovalsProvider =
    StreamProvider<List<PurchaseOrder>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final firestore = FirebaseFirestore.instance;

  final user = authState.value;
  if (user == null) {
    yield [];
    return;
  }

  yield* firestore
      .collection('purchase_orders')
      .where('status', isEqualTo: 'pending')
      .where('approvalChain', arrayContains: user.id)
      .orderBy('createdDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => PurchaseOrder.fromFirestore(doc))
        .toList();
  });
});

/// Get POs by status
final purchaseOrdersByStatusProvider =
    StreamProvider.family<List<PurchaseOrder>, (String, String)>((ref, params) {
  final (institutionId, status) = params;
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('purchase_orders')
      .where('institutionId', isEqualTo: institutionId)
      .where('status', isEqualTo: status)
      .orderBy('createdDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => PurchaseOrder.fromFirestore(doc))
        .toList();
  });
});

/// Watch approval status for a specific PO
final poApprovalStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, poId) async {
  final service = ref.watch(purchaseOrderServiceProvider);
  final po = await service.getPurchaseOrder(poId);
  return po?.approvalStatus ?? {};
});

// Contract Pricing Providers

/// Get contract price for product
final contractPriceProvider =
    FutureProvider.family<ContractPrice?, (String, String)>(
        (ref, params) async {
  final (institutionId, productId) = params;
  final service = ref.watch(contractPricingServiceProvider);
  return service.getContractPrice(institutionId, productId);
});

/// Get all contract prices for institution
final institutionContractPricesProvider =
    StreamProvider.family<List<ContractPrice>, String>((ref, institutionId) {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();

  return firestore
      .collection('contract_prices')
      .where('institutionId', isEqualTo: institutionId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    final prices = snapshot.docs
        .map((doc) => ContractPrice.fromFirestore(doc))
        .where((cp) => now.isAfter(cp.startDate) && now.isBefore(cp.endDate))
        .toList();
    return prices;
  });
});

// Invoice Providers

/// Get all invoices for institution
final institutionInvoicesProvider =
    StreamProvider.family<List<Invoice>, String>((ref, institutionId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('invoices')
      .where('institutionId', isEqualTo: institutionId)
      .orderBy('issuedDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  });
});

/// Get single invoice by ID
final invoiceProvider =
    FutureProvider.family<Invoice?, String>((ref, invoiceId) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getInvoice(invoiceId);
});

/// Get overdue invoices for institution
final overdueInvoicesProvider =
    StreamProvider.family<List<Invoice>, String>((ref, institutionId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('invoices')
      .where('institutionId', isEqualTo: institutionId)
      .where('status', isNotEqualTo: 'paid')
      .snapshots()
      .map((snapshot) {
    final invoices = snapshot.docs
        .map((doc) => Invoice.fromFirestore(doc))
        .where((inv) => inv.isOverdue())
        .toList();
    return invoices;
  });
});

/// Get invoices by status
final invoicesByStatusProvider =
    StreamProvider.family<List<Invoice>, (String, String)>((ref, params) {
  final (institutionId, status) = params;
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('invoices')
      .where('institutionId', isEqualTo: institutionId)
      .where('status', isEqualTo: status)
      .orderBy('issuedDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();
  });
});

// Dashboard Metrics

/// Get B2B summary for institution (total orders, revenue, pending approvals)
final b2bMetricsProvider =
    FutureProvider.family<B2BMetrics, String>((ref, institutionId) async {
  final poService = ref.watch(purchaseOrderServiceProvider);
  final invoiceService = ref.watch(invoiceServiceProvider);

  final pos = await poService.getInstitutionPurchaseOrders(institutionId);
  final invoices = await invoiceService.getInstitutionInvoices(institutionId);
  final overdue = await invoiceService.getOverdueInvoices(institutionId);

  final totalOrders = pos.length;
  final totalRevenue =
      invoices.fold<double>(0, (sum, inv) => sum + inv.totalAmount);
  final paidAmount =
      invoices.fold<double>(0, (sum, inv) => sum + inv.amountPaid);
  final overdueAmount =
      overdue.fold<double>(0, (sum, inv) => sum + inv.getOutstandingBalance());

  return B2BMetrics(
    totalOrders: totalOrders,
    totalRevenue: totalRevenue,
    totalPaid: paidAmount,
    totalOutstanding: invoices.fold<double>(
        0, (sum, inv) => sum + inv.getOutstandingBalance()),
    overdueAmount: overdueAmount,
    pendingApprovals: pos.where((po) => po.status == 'pending').length,
  );
});

/// Get approval pending count for user
final approvalPendingCountProvider = StreamProvider<int>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final firestore = FirebaseFirestore.instance;

  final user = authState.value;
  if (user == null) {
    yield 0;
    return;
  }

  yield* firestore
      .collection('purchase_orders')
      .where('status', isEqualTo: 'pending')
      .where('approvalChain', arrayContains: user.id)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

class B2BMetrics {
  final int totalOrders;
  final double totalRevenue;
  final double totalPaid;
  final double totalOutstanding;
  final double overdueAmount;
  final int pendingApprovals;

  B2BMetrics({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.overdueAmount,
    required this.pendingApprovals,
  });
}
