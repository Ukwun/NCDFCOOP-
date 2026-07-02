import 'package:coop_commerce/core/auth/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User role support', () {
    test('only the three marketplace roles are exposed in the onboarding flow',
        () {
      final visibleRoles = UserRoleX.visibleRoles;

      expect(visibleRoles, contains(UserRole.seller));
      expect(visibleRoles, contains(UserRole.coopMember));
      expect(visibleRoles, contains(UserRole.wholesaleBuyer));
      expect(visibleRoles, hasLength(3));
      expect(visibleRoles.toSet(), equals(UserRoleX.supportedRoles));
    });
  });
}
