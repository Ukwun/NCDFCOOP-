import 'package:coop_commerce/core/api/pricing_service.dart';
import 'package:coop_commerce/core/api/visibility_service.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = Product(
    id: 'bulk-rice',
    name: 'Bulk Rice',
    retailPrice: 12000,
    wholesalePrice: 9500,
    contractPrice: 9000,
    description: 'A wholesale product',
    categoryId: 'grains',
    stock: 100,
    minimumOrderQuantity: 10,
    visibleToRetail: false,
    visibleToWholesale: true,
  );

  test('wholesale buyers see wholesale products at wholesale price', () {
    final pricing = PricingService();
    expect(
      pricing.getPriceSync(
        product: product,
        userRole: UserRole.wholesaleBuyer,
      ),
      9500,
    );

    const user = User(
      id: 'buyer-1',
      email: 'buyer@example.com',
      name: 'Buyer',
      roles: [UserRole.wholesaleBuyer],
    );
    expect(
      VisibilityService().canViewProduct(
        product: product,
        user: user,
        role: UserRole.wholesaleBuyer,
      ),
      isTrue,
    );
  });
}
