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
  });

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
    );
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
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, retail: ₦$retailPrice)';
}
