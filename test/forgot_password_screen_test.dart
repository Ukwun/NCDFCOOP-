import 'package:coop_commerce/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('forgot password email validation', () {
    test('accepts standard and plus-addressed emails', () {
      expect(isValidEmailAddress('member@coopcommerce.com'), isTrue);
      expect(isValidEmailAddress('seller+wholesale@co-op.ng'), isTrue);
    });

    test('rejects empty or malformed emails', () {
      expect(isValidEmailAddress(''), isFalse);
      expect(isValidEmailAddress('not-an-email'), isFalse);
      expect(isValidEmailAddress('name@'), isFalse);
    });
  });
}
