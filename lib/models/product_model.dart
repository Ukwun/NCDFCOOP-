import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double costPrice;
  final String category;
  final List<String> images;
  final String imageUrl;
  final int stock;
  final double rating;
  final int reviews;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.costPrice,
    required this.category,
    required this.images,
    required this.imageUrl,
    required this.stock,
    required this.rating,
    required this.reviews,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      stock: data['stock'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: data['reviews'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'category': category,
      'images': images,
      'imageUrl': imageUrl,
      'stock': stock,
      'rating': rating,
      'reviews': reviews,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    String? category,
    List<String>? images,
    String? imageUrl,
    int? stock,
    double? rating,
    int? reviews,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      category: category ?? this.category,
      images: images ?? this.images,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isInStock => stock > 0;
  double get profitMargin => price - costPrice;
  double get profitMarginPercent => (profitMargin / price * 100);

  // Extension properties for UI
  double? get originalPrice => null; // Can be calculated from costPrice
  bool get isFavorite => false;
  int? get discount => ((price - costPrice) / price * 100).toInt();

  // Utility methods
  bool isOnSale() => costPrice > 0;
  bool isNewProduct({required Duration withinDays}) {
    return DateTime.now().difference(createdAt).inDays < withinDays.inDays;
  }
}

// Alias for compatibility
typedef ProductModel = Product;
