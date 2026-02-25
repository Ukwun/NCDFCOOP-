/// Real product model with membership-aware pricing
class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double regularPrice;
  final double? memberGoldPrice; // Price for Gold members
  final double? memberPlatinumPrice; // Price for Platinum members
  final String? imageUrl;
  final bool isMemberExclusive;
  final double discountPercentage; // Shows the savings

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.regularPrice,
    this.memberGoldPrice,
    this.memberPlatinumPrice,
    this.imageUrl,
    this.isMemberExclusive = false,
    this.discountPercentage = 0,
  });

  /// Get price for the user's membership tier
  double getPriceForTier(String? membershipTier) {
    if (membershipTier == 'platinum' && memberPlatinumPrice != null) {
      return memberPlatinumPrice!;
    }
    if (membershipTier == 'gold' && memberGoldPrice != null) {
      return memberGoldPrice!;
    }
    return regularPrice;
  }

  /// Calculate savings for a membership tier
  double getSavingsForTier(String? membershipTier) {
    if (membershipTier == null) return 0;
    final memberPrice = getPriceForTier(membershipTier);
    return regularPrice - memberPrice;
  }

  /// Check if this price requires membership
  bool isPriceExclusiveToMembers() {
    return memberGoldPrice != null || memberPlatinumPrice != null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'regularPrice': regularPrice,
    'memberGoldPrice': memberGoldPrice,
    'memberPlatinumPrice': memberPlatinumPrice,
    'imageUrl': imageUrl,
    'isMemberExclusive': isMemberExclusive,
    'discountPercentage': discountPercentage,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    regularPrice: (json['regularPrice'] as num).toDouble(),
    memberGoldPrice: json['memberGoldPrice'] != null
        ? (json['memberGoldPrice'] as num).toDouble()
        : null,
    memberPlatinumPrice: json['memberPlatinumPrice'] != null
        ? (json['memberPlatinumPrice'] as num).toDouble()
        : null,
    imageUrl: json['imageUrl'] as String?,
    isMemberExclusive: json['isMemberExclusive'] as bool? ?? false,
    discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
  );
}

/// Real product database with actual member pricing
final realProducts = [
  // Regular products
  Product(
    id: 'prod_001',
    name: 'Premium Rice - 50kg',
    description: 'High-quality long-grain rice perfect for families',
    category: 'Grains',
    regularPrice: 15000,
    memberGoldPrice: 12750, // 15% off
    memberPlatinumPrice: 12000, // 20% off
    imageUrl: 'assets/images/rice.jpg',
    discountPercentage: 15,
  ),
  Product(
    id: 'prod_002',
    name: 'Pure Palm Oil - 25L',
    description: 'Cold-pressed, naturally extracted palm oil',
    category: 'Cooking Oils',
    regularPrice: 8500,
    memberGoldPrice: 7225, // 15% off
    memberPlatinumPrice: 6800, // 20% off
    discountPercentage: 15,
  ),
  Product(
    id: 'prod_003',
    name: 'Black Beans - 20kg',
    description: 'Premium quality black beans for bulk use',
    category: 'Legumes',
    regularPrice: 12000,
    memberGoldPrice: 10200, // 15% off
    memberPlatinumPrice: 9600, // 20% off
    discountPercentage: 15,
  ),
  Product(
    id: 'prod_004',
    name: 'White Sugar - 50kg Bag',
    description: 'Refined white sugar in bulk quantity',
    category: 'Sweeteners',
    regularPrice: 22000,
    memberGoldPrice: 18700, // 15% off
    memberPlatinumPrice: 17600, // 20% off
    discountPercentage: 15,
  ),
  Product(
    id: 'prod_005',
    name: 'Garlic Powder - 2kg',
    description: 'Pure garlic powder, no additives',
    category: 'Spices',
    regularPrice: 8000,
    memberGoldPrice: 6800, // 15% off
    memberPlatinumPrice: 6400, // 20% off
    discountPercentage: 15,
  ),

  // Member-exclusive products (only gold/platinum can see/buy at special price)
  Product(
    id: 'prod_006',
    name: 'Organic Honey - 5kg',
    description: 'Pure raw organic honey - GOLD/PLATINUM EXCLUSIVE',
    category: 'Premium',
    regularPrice: 25000,
    memberGoldPrice: 22000, // Exclusive member pricing
    memberPlatinumPrice: 20000, // Better platinum pricing
    isMemberExclusive: true,
    discountPercentage: 12,
  ),
  Product(
    id: 'prod_007',
    name: 'Specialty Coffee Beans - 3kg',
    description: 'Premium arabica beans - PLATINUM EXCLUSIVE',
    category: 'Premium',
    regularPrice: 35000,
    memberPlatinumPrice: 31500, // Only platinum can access
    isMemberExclusive: true,
    discountPercentage: 10,
  ),
  Product(
    id: 'prod_008',
    name: 'Imported Spice Collection - Premium Bundle',
    description: 'Curated selection of rare imported spices - MEMBER EXCLUSIVE',
    category: 'Premium',
    regularPrice: 18000,
    memberGoldPrice: 15300, // 15% member discount
    memberPlatinumPrice: 14400, // 20% member discount
    isMemberExclusive: true,
    discountPercentage: 15,
  ),
];
