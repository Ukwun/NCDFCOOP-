import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/products/products_listing_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seller role hides buyer-facing product actions', () {
    expect(shouldShowBuyerActionsForRole(UserRole.seller), isFalse);
  });

  test('member role keeps buyer-facing product actions visible', () {
    expect(shouldShowBuyerActionsForRole(UserRole.coopMember), isTrue);
  });
}
