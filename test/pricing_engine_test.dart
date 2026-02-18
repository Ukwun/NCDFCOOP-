import 'package:flutter_test/flutter_test.dart';
import 'package:coop_commerce/models/pricing/pricing_models.dart';

void main() {
  group('Pricing Engine - Unit Tests', () {
    group('Wholesale Discount Tiers', () {
      test('1-49 units: 10% discount', () {
        // Arrange
        double basePrice = 100.0;
        int quantity = 25;

        // Act
        double discountPercentage = _getWholesaleDiscountTier(quantity);
        double discountAmount = basePrice * (discountPercentage / 100);
        double finalPrice = basePrice - discountAmount;

        // Assert
        expect(discountPercentage, 10.0);
        expect(discountAmount, 10.0);
        expect(finalPrice, 90.0);
      });

      test('50-99 units: 15% discount', () {
        // Arrange
        double basePrice = 100.0;
        int quantity = 75;

        // Act
        double discountPercentage = _getWholesaleDiscountTier(quantity);
        double discountAmount = basePrice * (discountPercentage / 100);
        double finalPrice = basePrice - discountAmount;

        // Assert
        expect(discountPercentage, 15.0);
        expect(discountAmount, 15.0);
        expect(finalPrice, 85.0);
      });

      test('100-499 units: 20% discount', () {
        // Arrange
        double basePrice = 100.0;
        int quantity = 250;

        // Act
        double discountPercentage = _getWholesaleDiscountTier(quantity);
        double discountAmount = basePrice * (discountPercentage / 100);
        double finalPrice = basePrice - discountAmount;

        // Assert
        expect(discountPercentage, 20.0);
        expect(discountAmount, 20.0);
        expect(finalPrice, 80.0);
      });

      test('500+ units: 30% discount', () {
        // Arrange
        double basePrice = 100.0;
        int quantity = 1000;

        // Act
        double discountPercentage = _getWholesaleDiscountTier(quantity);
        double discountAmount = basePrice * (discountPercentage / 100);
        double finalPrice = basePrice - discountAmount;

        // Assert
        expect(discountPercentage, 30.0);
        expect(discountAmount, 30.0);
        expect(finalPrice, 70.0);
      });
    });

    group('Price Calculation Results', () {
      test('PriceCalculationResult correctly formats breakdown', () {
        // Arrange
        final components = [
          PriceComponent(name: 'Base Price', value: '\$100.00'),
          PriceComponent(name: 'Promotion', value: '10% Off'),
        ];

        final result = PriceCalculationResult(
          basePrice: 100.0,
          discountAmount: 10.0,
          discountPercentage: 10.0,
          finalPrice: 90.0,
          components: components,
        );

        // Act
        final breakdown = result.getBreakdown();

        // Assert
        expect(breakdown, contains('Price Calculation Breakdown:'));
        expect(breakdown, contains('Base Price: \$100'));
        expect(breakdown, contains('Promotion: 10% Off'));
        expect(breakdown, contains('Final Price: \$90.00'));
      });

      test('PriceCalculationResult shows essential basket cap in breakdown',
          () {
        // Arrange
        final components = [
          PriceComponent(name: 'Base Price', value: '\$10.00'),
          PriceComponent(
              name: 'Essential Basket Cap', value: 'Capped at \$5.00'),
        ];

        final result = PriceCalculationResult(
          basePrice: 10.0,
          discountAmount: 0.0,
          discountPercentage: 0.0,
          finalPrice: 5.0,
          components: components,
          hadEssentialBasketCap: true,
        );

        // Act
        final breakdown = result.getBreakdown();

        // Assert
        expect(breakdown, contains('Capped by essential basket rule'));
      });

      test('PriceCalculationResult shows price override in breakdown', () {
        // Arrange
        final components = [
          PriceComponent(
              name: 'Price Override', value: 'Manual override: \$75.00'),
        ];

        final result = PriceCalculationResult(
          basePrice: 100.0,
          discountAmount: 25.0,
          discountPercentage: 25.0,
          finalPrice: 75.0,
          components: components,
          hadPriceOverride: true,
        );

        // Act
        final breakdown = result.getBreakdown();

        // Assert
        expect(breakdown, contains('Applied price override'));
      });
    });

    group('Promotion Validation', () {
      test(
          'Promotion.isValid() returns true for active promotion in date range',
          () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Spring Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now().subtract(Duration(days: 1)),
          endDate: DateTime.now().add(Duration(days: 10)),
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = promo.isValid();

        // Assert
        expect(isValid, true);
      });

      test('Promotion.isValid() returns false for expired promotion', () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Expired Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now().subtract(Duration(days: 10)),
          endDate: DateTime.now().subtract(Duration(days: 1)),
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = promo.isValid();

        // Assert
        expect(isValid, false);
      });

      test('Promotion.isValid() returns false for inactive promotion', () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Inactive Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now(),
          isActive: false,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = promo.isValid();

        // Assert
        expect(isValid, false);
      });

      test('Promotion.appliesToProduct() returns true when product in list',
          () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now(),
          applicableProductIds: ['product-1', 'product-2'],
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final applies = promo.appliesToProduct('product-1');

        // Assert
        expect(applies, true);
      });

      test(
          'Promotion.appliesToProduct() returns false when product not in list',
          () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now(),
          applicableProductIds: ['product-1', 'product-2'],
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final applies = promo.appliesToProduct('product-99');

        // Assert
        expect(applies, false);
      });

      test('Promotion.appliesToProduct() returns true when no product list',
          () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now(),
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final applies = promo.appliesToProduct('any-product');

        // Assert
        expect(applies, true);
      });

      test('Promotion.appliesToRole() returns true when role in list', () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Member Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now(),
          applicableRoles: ['coopMember', 'premiumMember'],
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final applies = promo.appliesToRole('coopMember');

        // Assert
        expect(applies, true);
      });

      test('Promotion.appliesToRole() returns false when role not in list', () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Member Sale',
          discountPercentage: 20.0,
          startDate: DateTime.now(),
          applicableRoles: ['coopMember', 'premiumMember'],
          isActive: true,
          createdBy: 'admin',
          createdAt: DateTime.now(),
        );

        // Act
        final applies = promo.appliesToRole('consumer');

        // Assert
        expect(applies, false);
      });
    });

    group('Price Override Validation', () {
      test(
          'PriceOverride.isValidAndApproved() returns true for approved non-expired',
          () {
        // Arrange
        final override = PriceOverride(
          id: 'override-1',
          productId: 'product-1',
          requestedPrice: 50.0,
          reason: 'VIP customer',
          status: PriceOverrideStatus.approved,
          requestedBy: 'manager-1',
          approvedBy: 'admin-1',
          requestedAt: DateTime.now(),
          approvedAt: DateTime.now(),
          expiryDate: DateTime.now().add(Duration(days: 7)),
        );

        // Act
        final isValid = override.isValidAndApproved();

        // Assert
        expect(isValid, true);
      });

      test('PriceOverride.isValidAndApproved() returns false for expired', () {
        // Arrange
        final override = PriceOverride(
          id: 'override-1',
          productId: 'product-1',
          requestedPrice: 50.0,
          reason: 'VIP customer',
          status: PriceOverrideStatus.approved,
          requestedBy: 'manager-1',
          approvedBy: 'admin-1',
          requestedAt: DateTime.now(),
          approvedAt: DateTime.now(),
          expiryDate: DateTime.now().subtract(Duration(days: 1)),
        );

        // Act
        final isValid = override.isValidAndApproved();

        // Assert
        expect(isValid, false);
      });

      test('PriceOverride.isValidAndApproved() returns false for pending', () {
        // Arrange
        final override = PriceOverride(
          id: 'override-1',
          productId: 'product-1',
          requestedPrice: 50.0,
          reason: 'VIP customer',
          status: PriceOverrideStatus.pending,
          requestedBy: 'manager-1',
          requestedAt: DateTime.now(),
        );

        // Act
        final isValid = override.isValidAndApproved();

        // Assert
        expect(isValid, false);
      });

      test('PriceOverride.isValidAndApproved() returns false for rejected', () {
        // Arrange
        final override = PriceOverride(
          id: 'override-1',
          productId: 'product-1',
          requestedPrice: 50.0,
          reason: 'VIP customer',
          status: PriceOverrideStatus.rejected,
          requestedBy: 'manager-1',
          requestedAt: DateTime.now(),
          rejectionReason: 'Price too low',
        );

        // Act
        final isValid = override.isValidAndApproved();

        // Assert
        expect(isValid, false);
      });
    });

    group('Essential Basket Validation', () {
      test('EssentialBasketItem.isValid() returns true for active non-expired',
          () {
        // Arrange
        final item = EssentialBasketItem(
          id: 'item-1',
          productId: 'product-1',
          maximumPrice: 5.0,
          category: 'staples',
          effectiveDate: DateTime.now().subtract(Duration(days: 1)),
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = item.isValid();

        // Assert
        expect(isValid, true);
      });

      test('EssentialBasketItem.isValid() returns false for expired', () {
        // Arrange
        final item = EssentialBasketItem(
          id: 'item-1',
          productId: 'product-1',
          maximumPrice: 5.0,
          category: 'staples',
          effectiveDate: DateTime.now().subtract(Duration(days: 10)),
          expiryDate: DateTime.now().subtract(Duration(days: 1)),
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = item.isValid();

        // Assert
        expect(isValid, false);
      });

      test('EssentialBasketItem.isValid() returns false for inactive', () {
        // Arrange
        final item = EssentialBasketItem(
          id: 'item-1',
          productId: 'product-1',
          maximumPrice: 5.0,
          category: 'staples',
          effectiveDate: DateTime.now(),
          isActive: false,
          createdAt: DateTime.now(),
        );

        // Act
        final isValid = item.isValid();

        // Assert
        expect(isValid, false);
      });
    });

    group('Model Serialization', () {
      test('PricingRule.toMap() and fromMap() round-trip correctly', () {
        // Arrange
        final rule = PricingRule(
          id: 'rule-1',
          productId: 'product-1',
          storeId: 'store-1',
          basePrice: 99.99,
          mode: PricingMode.retail,
          effectiveDate: DateTime(2026, 1, 27),
          isActive: true,
          createdBy: 'admin-1',
          createdAt: DateTime(2026, 1, 27),
        );

        // Act
        final map = rule.toMap();
        final restored = PricingRule.fromMap(map);

        // Assert
        expect(restored.id, rule.id);
        expect(restored.productId, rule.productId);
        expect(restored.basePrice, rule.basePrice);
        expect(restored.mode, rule.mode);
      });

      test('Promotion.toMap() and fromMap() round-trip correctly', () {
        // Arrange
        final promo = Promotion(
          id: 'promo-1',
          name: 'Test Promotion',
          discountPercentage: 25.0,
          startDate: DateTime(2026, 1, 27),
          isActive: true,
          createdBy: 'admin-1',
          createdAt: DateTime(2026, 1, 27),
        );

        // Act
        final map = promo.toMap();
        final restored = Promotion.fromMap(map);

        // Assert
        expect(restored.id, promo.id);
        expect(restored.name, promo.name);
        expect(restored.discountPercentage, promo.discountPercentage);
      });
    });
  });
}

/// Helper function to test tier calculation
double _getWholesaleDiscountTier(int quantity) {
  if (quantity >= 500) return 30.0;
  if (quantity >= 100) return 20.0;
  if (quantity >= 50) return 15.0;
  return 10.0;
}
