import 'package:coop_commerce/features/products/products_listing_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('products availability state', () {
    test(
        'shows unavailable state when there are no products or the catalog errored',
        () {
      expect(
        shouldShowProductsUnavailableState(
          visibleProductCount: 0,
          isLoading: false,
          hasError: false,
        ),
        isTrue,
      );

      expect(
        shouldShowProductsUnavailableState(
          visibleProductCount: 3,
          isLoading: false,
          hasError: false,
        ),
        isFalse,
      );

      expect(
        shouldShowProductsUnavailableState(
          visibleProductCount: 0,
          isLoading: false,
          hasError: true,
        ),
        isTrue,
      );
    });
  });
}
