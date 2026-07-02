import 'package:coop_commerce/core/models/seller_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SellerProduct marketplace mapping', () {
    test('maps wholesale products to marketplace-ready fields', () {
      final product = SellerProduct(
        id: 'seller-product-1',
        sellerId: 'seller-1',
        sellerUserId: 'user-123',
        sellerProfileId: 'profile-1',
        productName: 'Fresh Corn',
        category: 'agriculture',
        price: 900,
        retailPrice: 1000,
        wholesalePrice: 900,
        audience: ProductAudience.wholesale,
        quantity: 15,
        moq: 5,
        imageUrl: 'https://example.com/corn.jpg',
        description: 'Fresh corn for bulk buyers',
        createdAt: DateTime(2024, 1, 1),
      );

      final payload =
          product.toMarketplaceProductMap(productId: 'seller-product-1');

      expect(payload['id'], 'seller-product-1');
      expect(payload['name'], 'Fresh Corn');
      expect(payload['retailPrice'], 1000.0);
      expect(payload['wholesalePrice'], 900.0);
      expect(payload['stock'], 15);
      expect(payload['minimumOrderQuantity'], 5);
      expect(payload['uploadedBy'], 'user-123');
      expect(payload['visibleToRetail'], isFalse);
      expect(payload['visibleToWholesale'], isTrue);
      expect(payload['status'], 'pending');
      expect(payload['is_active'], isFalse);
    });
  });
}
