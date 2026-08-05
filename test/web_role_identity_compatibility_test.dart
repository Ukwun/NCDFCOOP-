import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shared website and app role identity', () {
    test('recognizes a seller stored in the current marketplace field', () {
      final user = User.fromJson({
        'id': 'seller-1',
        'email': 'seller@example.com',
        'marketplaceRole': 'seller',
        'roleSelectionCompleted': false,
      });

      expect(user.roles, [UserRole.seller]);
      expect(user.roleSelectionCompleted, isTrue);
    });

    test('recognizes legacy website role fields and formatting', () {
      final cases = <Map<String, dynamic>, UserRole>{
        {'role': 'Seller'}: UserRole.seller,
        {'selectedRole': 'cooperative-member'}: UserRole.coopMember,
        {'accountType': 'wholesale_buyer'}: UserRole.wholesaleBuyer,
      };

      for (final entry in cases.entries) {
        final user = User.fromJson({
          'id': 'shared-user',
          'email': 'shared@example.com',
          ...entry.key,
        });
        expect(user.roles, [entry.value]);
        expect(user.roleSelectionCompleted, isTrue);
      }
    });

    test('does not infer a role from an unknown value', () {
      final user = User.fromJson({
        'id': 'unknown',
        'email': 'unknown@example.com',
        'role': 'something-else',
      });

      expect(user.roles, isEmpty);
      expect(user.roleSelectionCompleted, isFalse);
    });
  });
}
