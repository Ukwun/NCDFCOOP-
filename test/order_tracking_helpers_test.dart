import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/checkout/order_tracking_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('order tracking helpers', () {
    test('returns the correct role label for each supported role', () {
      expect(roleDisplayLabel(UserRole.seller), 'Seller');
      expect(roleDisplayLabel(UserRole.wholesaleBuyer), 'Wholesale buyer');
      expect(roleDisplayLabel(UserRole.coopMember), 'Member');
    });

    test('validates payout details before submission', () {
      expect(
        validatePayoutDetails(
          bankName: 'First Bank',
          bankCode: '011',
          accountNumber: '0123456789',
          accountName: 'Ada Okafor',
        ),
        isNull,
      );

      expect(
        validatePayoutDetails(
          bankName: '',
          bankCode: '011',
          accountNumber: '0123456789',
          accountName: 'Ada Okafor',
        ),
        'Enter the bank name',
      );

      expect(
        validatePayoutDetails(
          bankName: 'First Bank',
          bankCode: '011',
          accountNumber: '1234',
          accountName: 'Ada Okafor',
        ),
        'Enter a valid 10-digit account number',
      );
    });
  });
}
