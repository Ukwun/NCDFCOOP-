class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final int quantity;
  final Map<String, String>? selectedVariants; // Size, color, etc.
  final DateTime addedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.selectedVariants,
    required this.addedAt,
  });

  double get totalPrice => price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      selectedVariants:
          (map['selectedVariants'] as Map?)?.cast<String, String>(),
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'selectedVariants': selectedVariants,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    double? price,
    String? imageUrl,
    int? quantity,
    Map<String, String>? selectedVariants,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      selectedVariants: selectedVariants ?? this.selectedVariants,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() =>
      'CartItemModel(id: $id, productId: $productId, quantity: $quantity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
