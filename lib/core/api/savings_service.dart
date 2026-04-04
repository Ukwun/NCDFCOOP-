import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/savings_models.dart';

/// Savings goal types
enum SavingsGoalType {
  general,
  emergency,
  investment,
  education,
  festival,
  other,
}

/// Savings goal record
class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String description;
  final SavingsGoalType goalType;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.goalType,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.createdAt,
    this.completedAt,
    required this.isActive,
  });

  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoal(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      goalType: SavingsGoalType.values.firstWhere(
        (t) => t.name == data['goalType'],
        orElse: () => SavingsGoalType.general,
      ),
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'description': description,
        'goalType': goalType.name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': Timestamp.fromDate(targetDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'isActive': isActive,
      };

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  bool get isCompleted => currentAmount >= targetAmount;

  SavingsGoal copyWith({
    String? name,
    String? description,
    SavingsGoalType? goalType,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? completedAt,
    bool? isActive,
  }) {
    return SavingsGoal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Savings transaction record
class SavingsTransaction {
  final String id;
  final String userId;
  final String goalId;
  final double amount;
  final String description;
  final DateTime timestamp;
  final bool isDeposit; // true = add, false = withdraw

  SavingsTransaction({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.isDeposit,
  });

  factory SavingsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsTransaction(
      id: doc.id,
      userId: data['userId'] as String,
      goalId: data['goalId'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isDeposit: data['isDeposit'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'goalId': goalId,
        'amount': amount,
        'description': description,
        'timestamp': Timestamp.fromDate(timestamp),
        'isDeposit': isDeposit,
      };
}

/// Savings Service - manages member savings accounts and goals
class SavingsService {
  static final SavingsService _instance = SavingsService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory SavingsService() {
    return _instance;
  }

  SavingsService._internal();

  /// Create a new savings goal
  Future<SavingsGoal> createSavingsGoal({
    required String userId,
    required String name,
    required String description,
    required SavingsGoalType goalType,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    try {
      if (targetAmount <= 0) {
        throw Exception('Target amount must be greater than 0');
      }

      if (targetDate.isBefore(DateTime.now())) {
        throw Exception('Target date must be in the future');
      }

      final goalRef = _firestore.collection('savings_goals').doc();
      final now = DateTime.now();

      final goal = SavingsGoal(
        id: goalRef.id,
        userId: userId,
        name: name,
        description: description,
        goalType: goalType,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        targetDate: targetDate,
        createdAt: now,
        isActive: true,
      );

      await goalRef.set(goal.toFirestore());
      debugPrint('✅ Savings goal created: $name for user: $userId');
      return goal;
    } catch (e) {
      debugPrint('❌ Error creating savings goal: $e');
      rethrow;
    }
  }

  /// Get all savings goals for user
  Future<List<SavingsGoal>> getUserSavingsGoals({
    required String userId,
    bool activeOnly = true,
  }) async {
    try {
      Query query = _firestore
          .collection('savings_goals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => SavingsGoal.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching savings goals: $e');
      rethrow;
    }
  }

  /// Get a specific savings goal
  Future<SavingsGoal?> getSavingsGoal(String goalId) async {
    try {
      final doc =
          await _firestore.collection('savings_goals').doc(goalId).get();
      if (!doc.exists) return null;
      return SavingsGoal.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching savings goal: $e');
      rethrow;
    }
  }

  /// Add money to a savings goal
  Future<SavingsTransaction> addToGoal({
    required String userId,
    required String goalId,
    required double amount,
    required String description,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Get the goal
      final goal = await getSavingsGoal(goalId);
      if (goal == null) {
        throw Exception('Savings goal not found');
      }

      if (goal.userId != userId) {
        throw Exception('Unauthorized: Goal does not belong to user');
      }

      // Create transaction record
      final txRef = _firestore.collection('savings_transactions').doc();
      final transaction = SavingsTransaction(
        id: txRef.id,
        userId: userId,
        goalId: goalId,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        isDeposit: true,
      );

      // Update goal in transaction
      await _firestore.runTransaction((txn) async {
        // Add transaction record
        await txRef.set(transaction.toFirestore());

        // Update goal
        final newAmount =
            (goal.currentAmount + amount).clamp(0, goal.targetAmount);
        txn.update(
          _firestore.collection('savings_goals').doc(goalId),
          {
            'currentAmount': newAmount,
            if (newAmount >= goal.targetAmount && goal.completedAt == null)
              'completedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      debugPrint(
          '✅ Added ₦$amount to savings goal: ${goal.name} for user: $userId');
      return transaction;
    } catch (e) {
      debugPrint('❌ Error adding to savings goal: $e');
      rethrow;
    }
  }

  /// Withdraw from a savings goal
  Future<SavingsTransaction> withdrawFromGoal({
    required String userId,
    required String goalId,
    required double amount,
    required String description,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Get the goal
      final goal = await getSavingsGoal(goalId);
      if (goal == null) {
        throw Exception('Savings goal not found');
      }

      if (goal.userId != userId) {
        throw Exception('Unauthorized: Goal does not belong to user');
      }

      if (goal.currentAmount < amount) {
        throw Exception(
            'Insufficient savings. Available: ₦${goal.currentAmount}');
      }

      // Create transaction record
      final txRef = _firestore.collection('savings_transactions').doc();
      final transaction = SavingsTransaction(
        id: txRef.id,
        userId: userId,
        goalId: goalId,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        isDeposit: false,
      );

      // Update goal in transaction
      await _firestore.runTransaction((txn) async {
        // Add transaction record
        await txRef.set(transaction.toFirestore());

        // Update goal
        txn.update(
          _firestore.collection('savings_goals').doc(goalId),
          {
            'currentAmount': goal.currentAmount - amount,
          },
        );
      });

      debugPrint(
          '✅ Withdrew ₦$amount from savings goal: ${goal.name} for user: $userId');
      return transaction;
    } catch (e) {
      debugPrint('❌ Error withdrawing from savings goal: $e');
      rethrow;
    }
  }

  /// Get savings transactions for a goal
  Future<List<SavingsTransaction>> getGoalTransactions({
    required String goalId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('savings_transactions')
          .where('goalId', isEqualTo: goalId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SavingsTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching goal transactions: $e');
      rethrow;
    }
  }

  /// Get total savings across all goals for user
  Future<double> getTotalSavings(String userId) async {
    try {
      final goals = await getUserSavingsGoals(
        userId: userId,
        activeOnly: false,
      );

      double total = 0.0;
      for (final goal in goals) {
        total += goal.currentAmount;
      }

      return total;
    } catch (e) {
      debugPrint('❌ Error calculating total savings: $e');
      rethrow;
    }
  }

  /// Get savings statistics for user
  Future<Map<String, dynamic>> getSavingsStats(String userId) async {
    try {
      final goals = await getUserSavingsGoals(
        userId: userId,
        activeOnly: false,
      );

      double totalSaved = 0.0;
      double totalTarget = 0.0;
      int activeGoals = 0;
      int completedGoals = 0;

      for (final goal in goals) {
        totalSaved += goal.currentAmount;
        totalTarget += goal.targetAmount;
        if (goal.isActive) {
          activeGoals++;
        }
        if (goal.isCompleted) {
          completedGoals++;
        }
      }

      return {
        'totalSaved': totalSaved,
        'totalTarget': totalTarget,
        'activeGoals': activeGoals,
        'completedGoals': completedGoals,
        'totalGoals': goals.length,
        'savingsRate':
            totalTarget > 0 ? (totalSaved / totalTarget * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('❌ Error fetching savings stats: $e');
      rethrow;
    }
  }

  /// Complete a savings goal
  Future<void> completeGoal(String goalId) async {
    try {
      await _firestore.collection('savings_goals').doc(goalId).update({
        'isActive': false,
        'completedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Savings goal completed: $goalId');
    } catch (e) {
      debugPrint('❌ Error completing savings goal: $e');
      rethrow;
    }
  }

  /// Delete/archive a savings goal
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore.collection('savings_goals').doc(goalId).update({
        'isActive': false,
      });

      debugPrint('✅ Savings goal archived: $goalId');
    } catch (e) {
      debugPrint('❌ Error deleting savings goal: $e');
      rethrow;
    }
  }

  // ============================================
  // SAVINGS ACCOUNT METHODS (Account-based savings)
  // ============================================

  /// Initialize savings account for a member
  Future<SavingsAccount> initializeSavingsAccount(String userId) async {
    try {
      final accountRef = _firestore.collection('savings_accounts').doc(userId);

      // Check if account already exists
      final existingAccount = await accountRef.get();
      if (existingAccount.exists) {
        return SavingsAccount.fromFirestore(existingAccount);
      }

      // Create new savings account
      final now = DateTime.now();
      final account = SavingsAccount(
        id: userId,
        userId: userId,
        balance: 0.0,
        totalSaved: 0.0,
        totalInterestEarned: 0.0,
        monthlyAutoSaveAmount: 0.0,
        autoSaveEnabled: false,
        savingsGoal: '',
        goalAmount: 0.0,
        createdAt: now,
        lastTransactionAt: now,
        isActive: true,
      );

      await accountRef.set(account.toFirestore());
      debugPrint('✅ Savings account initialized for user: $userId');
      return account;
    } catch (e) {
      debugPrint('❌ Error initializing savings account: $e');
      rethrow;
    }
  }

  /// Get user's savings account
  Future<SavingsAccount?> getSavingsAccount(String userId) async {
    try {
      final doc =
          await _firestore.collection('savings_accounts').doc(userId).get();
      if (!doc.exists) return null;
      return SavingsAccount.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching savings account: $e');
      rethrow;
    }
  }

  /// Deposit money to savings account (returns account transaction data)
  Future<Map<String, dynamic>> depositToSavingsAccount({
    required String userId,
    required double amount,
    required String description,
    String? source, // 'wallet', 'direct_deposit', etc.
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Deposit amount must be greater than 0');
      }

      // Get or initialize savings account
      var account = await getSavingsAccount(userId);
      account ??= await initializeSavingsAccount(userId);

      // Create transaction record
      final transactionRef =
          _firestore.collection('savings_account_transactions').doc();
      final timestamp = DateTime.now();

      final transactionData = {
        'userId': userId,
        'type': 'deposit',
        'amount': amount,
        'description': description,
        'status': 'completed',
        'timestamp': Timestamp.fromDate(timestamp),
        'metadata': {'source': source ?? 'manual_deposit'},
      };

      // Update account in transaction
      await _firestore.runTransaction((txn) async {
        // Record transaction
        await transactionRef.set(transactionData);

        // Update account balance and totals
        final newBalance = account!.balance + amount;
        txn.update(
          _firestore.collection('savings_accounts').doc(userId),
          {
            'balance': newBalance,
            'totalSaved': account.totalSaved + amount,
            'lastTransactionAt': FieldValue.serverTimestamp(),
          },
        );
      });

      debugPrint(
        '✅ Deposited ₦$amount to savings account for user: $userId',
      );
      return {
        'id': transactionRef.id,
        'userId': userId,
        'type': 'deposit',
        'amount': amount,
        'description': description,
        'timestamp': timestamp,
        'status': 'completed',
      };
    } catch (e) {
      debugPrint('❌ Error depositing to savings account: $e');
      rethrow;
    }
  }

  /// Withdraw money from savings account (returns account transaction data)
  Future<Map<String, dynamic>> withdrawFromSavingsAccount({
    required String userId,
    required double amount,
    required String description,
    String? accountNumber,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Withdrawal amount must be greater than 0');
      }

      final account = await getSavingsAccount(userId);
      if (account == null) {
        throw Exception('Savings account not found');
      }

      if (account.balance < amount) {
        throw Exception(
          'Insufficient savings balance. Available: ₦${account.balance.toStringAsFixed(2)}',
        );
      }

      final transactionRef =
          _firestore.collection('savings_account_transactions').doc();
      final timestamp = DateTime.now();

      final transactionData = {
        'userId': userId,
        'type': 'withdrawal',
        'amount': amount,
        'description': description,
        'status': 'pending', // Withdrawal needs processing
        'timestamp': Timestamp.fromDate(timestamp),
        'metadata': {'accountNumber': accountNumber},
      };

      // Update account in transaction
      await _firestore.runTransaction((txn) async {
        final accountRef =
            _firestore.collection('savings_accounts').doc(userId);
        final currentSnapshot = await txn.get(accountRef);

        if (!currentSnapshot.exists) {
          throw Exception('Savings account not found');
        }

        final currentBalance =
            (currentSnapshot.get('balance') as num).toDouble();
        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Record transaction
        await transactionRef.set(transactionData);

        // Deduct from balance
        txn.update(accountRef, {
          'balance': currentBalance - amount,
          'lastTransactionAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint(
        '✅ Withdrawal of ₦$amount initiated from savings for user: $userId',
      );
      return {
        'id': transactionRef.id,
        'userId': userId,
        'type': 'withdrawal',
        'amount': amount,
        'description': description,
        'timestamp': timestamp,
        'status': 'pending',
      };
    } catch (e) {
      debugPrint('❌ Error withdrawing from savings account: $e');
      rethrow;
    }
  }

  /// Set up automatic monthly savings
  Future<void> setupAutoSave({
    required String userId,
    required double monthlyAmount,
  }) async {
    try {
      if (monthlyAmount <= 0) {
        throw Exception('Auto-save amount must be greater than 0');
      }

      final account = await getSavingsAccount(userId);
      if (account == null) {
        throw Exception('Savings account not found');
      }

      await _firestore.collection('savings_accounts').doc(userId).update({
        'monthlyAutoSaveAmount': monthlyAmount,
        'autoSaveEnabled': true,
      });

      debugPrint(
        '✅ Auto-save enabled: ₦$monthlyAmount/month for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ Error setting up auto-save: $e');
      rethrow;
    }
  }

  /// Disable automatic savings
  Future<void> disableAutoSave(String userId) async {
    try {
      await _firestore.collection('savings_accounts').doc(userId).update({
        'autoSaveEnabled': false,
        'monthlyAutoSaveAmount': 0.0,
      });

      debugPrint('✅ Auto-save disabled for user: $userId');
    } catch (e) {
      debugPrint('❌ Error disabling auto-save: $e');
      rethrow;
    }
  }

  /// Set savings goal for account
  Future<void> setSavingsGoalForAccount({
    required String userId,
    required double goalAmount,
    required String goalDescription,
  }) async {
    try {
      if (goalAmount <= 0) {
        throw Exception('Goal amount must be greater than 0');
      }

      final account = await getSavingsAccount(userId);
      if (account == null) {
        throw Exception('Savings account not found');
      }

      await _firestore.collection('savings_accounts').doc(userId).update({
        'savingsGoal': goalDescription,
        'goalAmount': goalAmount,
      });

      debugPrint(
        '✅ Savings goal set: ₦$goalAmount for "$goalDescription" (user: $userId)',
      );
    } catch (e) {
      debugPrint('❌ Error setting savings goal: $e');
      rethrow;
    }
  }

  /// Get savings account statistics
  Future<Map<String, dynamic>> getAccountSavingsStats(String userId) async {
    try {
      final account = await getSavingsAccount(userId);
      if (account == null) {
        return {
          'balance': 0.0,
          'totalSaved': 0.0,
          'totalInterestEarned': 0.0,
          'monthlyAutoSaveAmount': 0.0,
          'autoSaveEnabled': false,
          'savingsGoal': null,
          'goalAmount': 0.0,
          'goalProgress': 0.0,
        };
      }

      final goalProgress = account.goalAmount > 0
          ? (account.balance / account.goalAmount * 100).clamp(0, 100)
          : 0.0;

      return {
        'balance': account.balance,
        'totalSaved': account.totalSaved,
        'totalInterestEarned': account.totalInterestEarned,
        'monthlyAutoSaveAmount': account.monthlyAutoSaveAmount,
        'autoSaveEnabled': account.autoSaveEnabled,
        'savingsGoal': account.savingsGoal,
        'goalAmount': account.goalAmount,
        'goalProgress': goalProgress,
        'createdAt': account.createdAt,
      };
    } catch (e) {
      debugPrint('❌ Error getting account savings stats: $e');
      rethrow;
    }
  }
}
