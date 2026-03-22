import 'package:riverpod/riverpod.dart';
import '../../models/savings_models.dart';
import '../../core/api/savings_service.dart';

// ============================================
// SAVINGS SERVICE PROVIDER (Singleton)
// ============================================

/// Provider for SavingsService singleton
final savingsServiceProvider = Provider<SavingsService>((ref) {
  return SavingsService();
});

// ============================================
// SAVINGS GOAL PROVIDERS
// ============================================

/// Provider for user's savings goals
final userSavingsGoalsProvider =
    FutureProvider.family<List, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getUserSavingsGoals(userId: userId, activeOnly: true);
});

/// Provider for a specific savings goal
final savingsGoalProvider =
    FutureProvider.family<dynamic, String>((ref, goalId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getSavingsGoal(goalId);
});

/// Provider for savings goal transactions
final goalTransactionsProvider =
    FutureProvider.family<List, String>((ref, goalId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getGoalTransactions(goalId: goalId);
});

// ============================================
// SAVINGS ACCOUNT PROVIDERS
// ============================================

/// Provider for user's savings account
final savingsAccountProvider =
    FutureProvider.family<SavingsAccount?, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getSavingsAccount(userId);
});

/// Provider for savings account statistics
final savingsAccountStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getAccountSavingsStats(userId);
});

/// Provider for savings account balance
final savingsBalanceProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  final account = await savingsService.getSavingsAccount(userId);
  return account?.balance ?? 0.0;
});

/// Provider for goal progress
final goalProgressProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  final account = await savingsService.getSavingsAccount(userId);
  if (account == null || account.goalAmount <= 0) {
    return 0.0;
  }
  return (account.balance / account.goalAmount * 100).clamp(0, 100);
});

// ============================================
// SAVINGS ACCOUNT TRANSACTION PROVIDERS
// ============================================

/// Provider for deposit to savings mutation
final depositToSavingsProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({
      String userId,
      double amount,
      String description,
      String? source,
    })>((ref, params) async {
  final savingsService = ref.watch(savingsServiceProvider);
  final transaction = await savingsService.depositToSavingsAccount(
    userId: params.userId,
    amount: params.amount,
    description: params.description,
    source: params.source,
  );

  // Invalidate related providers
  ref.invalidate(savingsAccountProvider);
  ref.invalidate(savingsAccountStatsProvider);
  ref.invalidate(savingsBalanceProvider);
  ref.invalidate(goalProgressProvider);

  return transaction;
});

/// Provider for withdrawal from savings mutation
final withdrawFromSavingsProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({
      String userId,
      double amount,
      String description,
      String? accountNumber,
    })>((ref, params) async {
  final savingsService = ref.watch(savingsServiceProvider);
  final transaction = await savingsService.withdrawFromSavingsAccount(
    userId: params.userId,
    amount: params.amount,
    description: params.description,
    accountNumber: params.accountNumber,
  );

  // Invalidate related providers
  ref.invalidate(savingsAccountProvider);
  ref.invalidate(savingsAccountStatsProvider);
  ref.invalidate(savingsBalanceProvider);
  ref.invalidate(goalProgressProvider);

  return transaction;
});

// ============================================
// AUTO-SAVE SETUP PROVIDERS
// ============================================

/// Provider for setting up auto-save
final setupAutoSaveProvider = FutureProvider.family<
    void,
    ({
      String userId,
      double monthlyAmount,
    })>((ref, params) async {
  final savingsService = ref.watch(savingsServiceProvider);
  await savingsService.setupAutoSave(
    userId: params.userId,
    monthlyAmount: params.monthlyAmount,
  );

  // Invalidate related providers
  ref.invalidate(savingsAccountProvider);
  ref.invalidate(savingsAccountStatsProvider);
});

/// Provider for disabling auto-save
final disableAutoSaveProvider =
    FutureProvider.family<void, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  await savingsService.disableAutoSave(userId);

  // Invalidate related providers
  ref.invalidate(savingsAccountProvider);
  ref.invalidate(savingsAccountStatsProvider);
});

// ============================================
// SAVINGS GOAL MUTATION PROVIDERS
// ============================================

/// Provider for adding to savings goal
final addToGoalProvider = FutureProvider.family<
    dynamic,
    ({
      String userId,
      String goalId,
      double amount,
      String description,
    })>((ref, params) async {
  final savingsService = ref.watch(savingsServiceProvider);
  final transaction = await savingsService.addToGoal(
    userId: params.userId,
    goalId: params.goalId,
    amount: params.amount,
    description: params.description,
  );

  // Invalidate related providers
  ref.invalidate(userSavingsGoalsProvider);
  ref.invalidate(savingsGoalProvider);
  ref.invalidate(goalTransactionsProvider);

  return transaction;
});

/// Provider for withdrawing from savings goal
final withdrawFromGoalProvider = FutureProvider.family<
    dynamic,
    ({
      String userId,
      String goalId,
      double amount,
      String description,
    })>((ref, params) async {
  final savingsService = ref.watch(savingsServiceProvider);
  final transaction = await savingsService.withdrawFromGoal(
    userId: params.userId,
    goalId: params.goalId,
    amount: params.amount,
    description: params.description,
  );

  // Invalidate related providers
  ref.invalidate(userSavingsGoalsProvider);
  ref.invalidate(savingsGoalProvider);
  ref.invalidate(goalTransactionsProvider);

  return transaction;
});

// ============================================
// SAVINGS STATISTICS PROVIDERS
// ============================================

/// Provider for overall savings statistics
final overallSavingsStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getSavingsStats(userId);
});

/// Provider for total savings across all goals
final totalSavingsProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getTotalSavings(userId);
});

// ============================================
// SAVINGS ACCOUNT INITIALIZATION
// ============================================

/// Provider for initializing savings account
final initializeSavingsAccountProvider =
    FutureProvider.family<SavingsAccount, String>((ref, userId) async {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.initializeSavingsAccount(userId);
});
