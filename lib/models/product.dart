class Product {
  final String id;
  final String name;
  final String description;
  final double retailPrice;
  final double wholesalePrice;
  final double contractPrice;
  final String categoryId;
  final String? imageUrl;
  final int stock;
  final int minimumOrderQuantity;
  final double rating;
  final bool visibleToRetail;
  final bool visibleToWholesale;
  final bool visibleToInstitutions;
  final String franchiseId;
  final String uploadedBy;
  final List<String> colors;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.contractPrice,
    required this.categoryId,
    this.imageUrl,
    required this.stock,
    this.minimumOrderQuantity = 1,
    this.rating = 0.0,
    this.visibleToRetail = true,
    this.visibleToWholesale = false,
    this.visibleToInstitutions = false,
    this.franchiseId = '',
    this.uploadedBy = '',
    this.colors = const [],
  });

  /// Get the default display price (retail price for consumers)
  double get price => retailPrice;

  /// Get the price appropriate for a specific user role
  /// Consumer → Retail price
  /// Member → Wholesale price
  /// Institutional → Contract price
  double getPriceForRole(String userRole) {
    if (userRole.contains('consumer') || userRole == 'consumer') {
      return retailPrice;
    } else if (userRole.contains('member') ||
        userRole.contains('cooperative') ||
        userRole == 'coopMember') {
      return wholesalePrice > 0 ? wholesalePrice : retailPrice;
    } else if (userRole.contains('institutional') ||
        userRole.contains('buyer') ||
        userRole == 'institutionalBuyer' ||
        userRole == 'institutionalApprover') {
      return contractPrice > 0 ? contractPrice : wholesalePrice;
    }
    return retailPrice; // Default to retail
  }

  /// Check if product is visible to a specific role
  bool isVisibleToRole(String userRole) {
    if (userRole.contains('consumer') || userRole == 'consumer') {
      return visibleToRetail;
    } else if (userRole.contains('member') ||
        userRole.contains('cooperative') ||
        userRole == 'coopMember') {
      return visibleToWholesale;
    } else if (userRole.contains('institutional') ||
        userRole.contains('buyer') ||
        userRole == 'institutionalBuyer' ||
        userRole == 'institutionalApprover') {
      return visibleToInstitutions;
    }
    return visibleToRetail; // Default to retail visibility
  }

  /// Get minimum order quantity for a specific role
  /// Override minimumOrderQuantity if needed per role
  int getMinimumOrderQtyForRole(String userRole) {
    // Could be extended in future to have role-specific min quantities
    // For now, use the standard minimumOrderQuantity
    return minimumOrderQuantity;
  }

  /// Calculate savings percentage for member vs retail price
  double getMemberSavingsPercent() {
    if (retailPrice <= 0) return 0;
    return ((retailPrice - wholesalePrice) / retailPrice * 100).clamp(0, 100);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      retailPrice: (json['retailPrice'] ?? json['marketPrice'] ?? 0).toDouble(),
      wholesalePrice: (json['wholesalePrice'] ?? 0).toDouble(),
      contractPrice: (json['contractPrice'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      imageUrl: json['imageUrl'],
      stock: json['stock'] ?? 0,
      minimumOrderQuantity: json['minimumOrderQuantity'] ?? 1,
      rating: (json['rating'] ?? 0).toDouble(),
      visibleToRetail: json['visibleToRetail'] ?? true,
      visibleToWholesale: json['visibleToWholesale'] ?? false,
      visibleToInstitutions: json['visibleToInstitutions'] ?? false,
      franchiseId: json['franchiseId'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      colors: (json['colors'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  /// Create Product from Firestore document
  factory Product.fromFirestore(Map<String, dynamic> data) {
    return Product.fromJson(data);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'retailPrice': retailPrice,
        'wholesalePrice': wholesalePrice,
        'contractPrice': contractPrice,
        'categoryId': categoryId,
        'imageUrl': imageUrl,
        'stock': stock,
        'minimumOrderQuantity': minimumOrderQuantity,
        'rating': rating,
        'visibleToRetail': visibleToRetail,
        'visibleToWholesale': visibleToWholesale,
        'visibleToInstitutions': visibleToInstitutions,
        'franchiseId': franchiseId,
        'uploadedBy': uploadedBy,
        'colors': colors,
      };

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? retailPrice,
    double? wholesalePrice,
    double? contractPrice,
    String? categoryId,
    String? imageUrl,
    int? stock,
    int? minimumOrderQuantity,
    double? rating,
    bool? visibleToRetail,
    bool? visibleToWholesale,
    bool? visibleToInstitutions,
    String? franchiseId,
    String? uploadedBy,
    List<String>? colors,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      contractPrice: contractPrice ?? this.contractPrice,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      rating: rating ?? this.rating,
      visibleToRetail: visibleToRetail ?? this.visibleToRetail,
      visibleToWholesale: visibleToWholesale ?? this.visibleToWholesale,
      visibleToInstitutions:
          visibleToInstitutions ?? this.visibleToInstitutions,
      franchiseId: franchiseId ?? this.franchiseId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      colors: colors ?? this.colors,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, retail: ₦$retailPrice)';
}
