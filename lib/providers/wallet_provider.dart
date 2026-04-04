import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallet_models.dart';
import '../../core/api/wallet_service.dart';

// ============================================
// WALLET SERVICE PROVIDER (Singleton)
// ============================================

/// Provider for WalletService singleton
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

// ============================================
// WALLET STATE PROVIDERS
// ============================================

/// Provider for user's wallet data
final userWalletProvider =
    FutureProvider.family<Wallet?, String>((ref, userId) async {
  final walletService = ref.watch(walletServiceProvider);
  return walletService.getWallet(userId);
});

/// Provider for wallet balance
final walletBalanceProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final walletService = ref.watch(walletServiceProvider);
  final balance = await walletService.getAvailableBalance(userId);
  return balance;
});

/// Provider for wallet statistics
final walletStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final walletService = ref.watch(walletServiceProvider);
  return walletService.getWalletStats(userId);
});

/// Provider for wallet transaction history
final transactionHistoryProvider =
    FutureProvider.family<List<WalletTransaction>, (String, int)>(
        (ref, params) async {
  final (userId, limit) = params;
  final walletService = ref.watch(walletServiceProvider);
  return walletService.getTransactionHistory(userId: userId, limit: limit);
});

/// Provider for wallet transaction history with type filter
final transactionHistoryByTypeProvider = FutureProvider.family<
    List<WalletTransaction>, (String, TransactionType, int)>(
  (ref, params) async {
    final (userId, type, limit) = params;
    final walletService = ref.watch(walletServiceProvider);
    return walletService.getTransactionHistory(
      userId: userId,
      type: type,
      limit: limit,
    );
  },
);

// ============================================
// WALLET MUTATION PROVIDERS
// ============================================

/// State notifier provider for deposit mutation
final depositMoneyProvider = FutureProvider.family<
    WalletTransaction,
    ({
      String userId,
      double amount,
      String description,
      String? paymentMethod,
      String? referenceNumber,
    })>((ref, params) async {
  final walletService = ref.watch(walletServiceProvider);
  final transaction = await walletService.depositMoney(
    userId: params.userId,
    amount: params.amount,
    description: params.description,
    paymentMethod: params.paymentMethod,
    referenceNumber: params.referenceNumber,
  );

  // Invalidate related providers to refresh UI
  ref.invalidate(userWalletProvider);
  ref.invalidate(walletBalanceProvider);
  ref.invalidate(walletStatsProvider);

  return transaction;
});

/// State notifier provider for withdrawal mutation
final withdrawMoneyProvider = FutureProvider.family<
    WalletTransaction,
    ({
      String userId,
      double amount,
      String description,
      String? accountNumber,
      String? bankName,
    })>((ref, params) async {
  final walletService = ref.watch(walletServiceProvider);
  final transaction = await walletService.withdrawMoney(
    userId: params.userId,
    amount: params.amount,
    description: params.description,
    accountNumber: params.accountNumber,
    bankName: params.bankName,
  );

  // Invalidate related providers
  ref.invalidate(userWalletProvider);
  ref.invalidate(walletBalanceProvider);
  ref.invalidate(walletStatsProvider);

  return transaction;
});

/// State notifier provider for spend mutation
final spendFromWalletProvider = FutureProvider.family<
    WalletTransaction,
    ({
      String userId,
      double amount,
      String orderId,
      String? description,
    })>((ref, params) async {
  final walletService = ref.watch(walletServiceProvider);
  final transaction = await walletService.spendFromWallet(
    userId: params.userId,
    amount: params.amount,
    orderId: params.orderId,
    description: params.description,
  );

  // Invalidate related providers
  ref.invalidate(userWalletProvider);
  ref.invalidate(walletBalanceProvider);
  ref.invalidate(walletStatsProvider);

  return transaction;
});

/// State notifier provider for refund mutation
final creditRefundProvider = FutureProvider.family<
    WalletTransaction,
    ({
      String userId,
      double amount,
      String orderId,
      String? reason,
    })>((ref, params) async {
  final walletService = ref.watch(walletServiceProvider);
  final transaction = await walletService.creditRefund(
    userId: params.userId,
    amount: params.amount,
    orderId: params.orderId,
    reason: params.reason,
  );

  // Invalidate related providers
  ref.invalidate(userWalletProvider);
  ref.invalidate(walletBalanceProvider);
  ref.invalidate(walletStatsProvider);

  return transaction;
});

/// State notifier provider for transfer to savings mutation
final transferToSavingsProvider = FutureProvider.family<
    WalletTransaction,
    ({
      String userId,
      double amount,
      String? description,
    })>((ref, params) async {
  final walletService = ref.watch(walletServiceProvider);
  final transaction = await walletService.transferToSavings(
    userId: params.userId,
    amount: params.amount,
    description: params.description,
  );

  // Invalidate related providers
  ref.invalidate(userWalletProvider);
  ref.invalidate(walletBalanceProvider);
  ref.invalidate(walletStatsProvider);

  return transaction;
});

// ============================================
// WALLET INITIALIZATION
// ============================================

/// Provider for initializing wallet
final initializeWalletProvider =
    FutureProvider.family<Wallet, String>((ref, userId) async {
  final walletService = ref.watch(walletServiceProvider);
  return walletService.initializeWallet(userId);
});
