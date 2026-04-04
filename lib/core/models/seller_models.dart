import 'package:cloud_firestore/cloud_firestore.dart';

/// Target customer type for sellers
enum TargetCustomer {
  individual('Individual Customers'),
  bulk('Bulk Buyers');

  final String displayName;
  const TargetCustomer(this.displayName);
}

/// Product approval status
enum ProductApprovalStatus {
  pending('Pending Approval'),
  approved('Approved'),
  rejected('Rejected');

  final String displayName;
  const ProductApprovalStatus(this.displayName);
}

/// Seller profile information
class SellerProfile {
  final String? id;
  final String userId;
  final String businessName;
  final String sellerType; // 'individual', 'business', 'cooperative'
  final String sellingPath; // 'member' or 'wholesale' - seller onboarding path
  final String country;
  final String category;
  final TargetCustomer targetCustomer;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? approvedAt;

  SellerProfile({
    this.id,
    required this.userId,
    required this.businessName,
    required this.sellerType,
    this.sellingPath = 'member',
    required this.country,
    required this.category,
    required this.targetCustomer,
    this.isVerified = false,
    required this.createdAt,
    this.approvedAt,
  });

  factory SellerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessName: data['businessName'] ?? '',
      sellerType: data['sellerType'] ?? 'individual',
      sellingPath: data['sellingPath'] ?? 'member',
      country: data['country'] ?? '',
      category: data['category'] ?? '',
      targetCustomer: TargetCustomer.values.firstWhere(
        (e) => e.name == (data['targetCustomer'] ?? 'individual'),
        orElse: () => TargetCustomer.individual,
      ),
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'businessName': businessName,
      'sellerType': sellerType,
      'sellingPath': sellingPath,
      'country': country,
      'category': category,
      'targetCustomer': targetCustomer.name,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }
}

/// Product listing for seller
class SellerProduct {
  final String? id;
  final String sellerId;
  final String productName;
  final String category;
  final double price;
  final int quantity;
  final int moq; // Minimum Order Quantity
  final String imageUrl;
  final String description;
  final ProductApprovalStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  SellerProduct({
    this.id,
    required this.sellerId,
    required this.productName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.moq,
    required this.imageUrl,
    required this.description,
    this.status = ProductApprovalStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
  });

  factory SellerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerProduct(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      moq: data['moq'] ?? 1,
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      status: ProductApprovalStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => ProductApprovalStatus.pending,
      ),
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'productName': productName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'moq': moq,
      'imageUrl': imageUrl,
      'description': description,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
    };
  }
}

/// Product approval/moderation request
class ProductModerationRequest {
  final String? id;
  final String productId;
  final String sellerId;
  final String productName;
  final DateTime submittedAt;
  final ProductApprovalStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  ProductModerationRequest({
    this.id,
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.submittedAt,
    this.status = ProductApprovalStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
  });

  factory ProductModerationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModerationRequest(
      id: doc.id,
      productId: data['productId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productName: data['productName'] ?? '',
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ProductApprovalStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => ProductApprovalStatus.pending,
      ),
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewNotes: data['reviewNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'productName': productName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNotes': reviewNotes,
    };
  }
}
