import 'package:cloud_firestore/cloud_firestore.dart';

/// Savings transfer types
enum SavingsTransferType {
  deposit, // Transfer money to savings
  withdrawal, // Withdraw from savings
  monthlyAutoSave, // Automatic monthly savings
  interestCredit, // Interest earned
}

/// Savings transaction record
class SavingsTransaction {
  final String id;
  final String userId;
  final SavingsTransferType type;
  final double amount;
  final String description;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime timestamp;
  final String? reason;
  final Map<String, dynamic>? metadata;

  SavingsTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.status = 'completed',
    required this.timestamp,
    this.reason,
    this.metadata,
  });

  factory SavingsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SavingsTransferType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => SavingsTransferType.deposit,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      status: data['status'] ?? 'completed',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'reason': reason,
      'metadata': metadata,
    };
  }

  SavingsTransaction copyWith({
    String? id,
    String? userId,
    SavingsTransferType? type,
    double? amount,
    String? description,
    String? status,
    DateTime? timestamp,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    return SavingsTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// User's savings account (member-only)
class SavingsAccount {
  final String id;
  final String userId;
  final double balance;
  final double totalSaved; // Total money saved (cumulative)
  final double totalInterestEarned; // Interest accrued
  final double monthlyAutoSaveAmount; // Auto-save target per month
  final bool autoSaveEnabled;
  final String savingsGoal; // User's savings goal description
  final double goalAmount;
  final DateTime createdAt;
  final DateTime lastTransactionAt;
  final bool isActive;

  SavingsAccount({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.totalSaved = 0.0,
    this.totalInterestEarned = 0.0,
    this.monthlyAutoSaveAmount = 0.0,
    this.autoSaveEnabled = false,
    this.savingsGoal = '',
    this.goalAmount = 0.0,
    required this.createdAt,
    required this.lastTransactionAt,
    this.isActive = true,
  });

  factory SavingsAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsAccount(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalSaved: (data['totalSaved'] as num?)?.toDouble() ?? 0.0,
      totalInterestEarned:
          (data['totalInterestEarned'] as num?)?.toDouble() ?? 0.0,
      monthlyAutoSaveAmount:
          (data['monthlyAutoSaveAmount'] as num?)?.toDouble() ?? 0.0,
      autoSaveEnabled: data['autoSaveEnabled'] ?? false,
      savingsGoal: data['savingsGoal'] ?? '',
      goalAmount: (data['goalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastTransactionAt:
          (data['lastTransactionAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balance': balance,
      'totalSaved': totalSaved,
      'totalInterestEarned': totalInterestEarned,
      'monthlyAutoSaveAmount': monthlyAutoSaveAmount,
      'autoSaveEnabled': autoSaveEnabled,
      'savingsGoal': savingsGoal,
      'goalAmount': goalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTransactionAt': Timestamp.fromDate(lastTransactionAt),
      'isActive': isActive,
    };
  }

  /// Calculate progress toward goal
  double get goalProgress {
    if (goalAmount == 0) return 0.0;
    return (balance / goalAmount).clamp(0.0, 1.0);
  }

  /// Calculate remaining amount to reach goal
  double get remainingToGoal {
    if (balance >= goalAmount) return 0.0;
    return goalAmount - balance;
  }

  SavingsAccount copyWith({
    String? id,
    String? userId,
    double? balance,
    double? totalSaved,
    double? totalInterestEarned,
    double? monthlyAutoSaveAmount,
    bool? autoSaveEnabled,
    String? savingsGoal,
    double? goalAmount,
    DateTime? createdAt,
    DateTime? lastTransactionAt,
    bool? isActive,
  }) {
    return SavingsAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalSaved: totalSaved ?? this.totalSaved,
      totalInterestEarned: totalInterestEarned ?? this.totalInterestEarned,
      monthlyAutoSaveAmount:
          monthlyAutoSaveAmount ?? this.monthlyAutoSaveAmount,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      goalAmount: goalAmount ?? this.goalAmount,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
