import 'package:coop_commerce/core/auth/role.dart';

String roleDisplayLabel(UserRole role) {
  return switch (role) {
    UserRole.seller => 'Seller',
    UserRole.wholesaleBuyer => 'Wholesale buyer',
    UserRole.coopMember || UserRole.premiumMember => 'Member',
    _ => 'Member',
  };
}

String roleFocusText(UserRole role) {
  return switch (role) {
    UserRole.seller =>
      'Keep fulfillment moving and keep buyers informed with live updates.',
    UserRole.wholesaleBuyer =>
      'Monitor your wholesale order, status, and next actions in one place.',
    UserRole.coopMember ||
    UserRole.premiumMember =>
      'Your order is updated live so you always know what happens next.',
    _ => 'Your order is updated live so you always know what happens next.',
  };
}

String roleSummaryLabel(UserRole role) {
  return switch (role) {
    UserRole.seller => 'Seller control center',
    UserRole.wholesaleBuyer => 'Wholesale purchasing view',
    UserRole.coopMember || UserRole.premiumMember => 'Member experience view',
    _ => 'Live order view',
  };
}

String orderReferenceLabel(String orderId) {
  if (orderId.isEmpty) return 'ORDER';
  return orderId.length > 8
      ? orderId.substring(0, 8).toUpperCase()
      : orderId.toUpperCase();
}

String? validatePayoutDetails({
  required String bankName,
  required String bankCode,
  required String accountNumber,
  required String accountName,
}) {
  if (bankName.trim().isEmpty) {
    return 'Enter the bank name';
  }
  if (bankCode.trim().isEmpty) {
    return 'Enter the bank code';
  }
  if (!RegExp(r'^\d{10}$').hasMatch(accountNumber.trim())) {
    return 'Enter a valid 10-digit account number';
  }
  if (accountName.trim().isEmpty) {
    return 'Enter the account name';
  }
  return null;
}
