import 'package:cloud_firestore/cloud_firestore.dart';

/// Wallet transaction types
enum TransactionType {
  deposit, // Adding money to account
  withdrawal, // Withdrawing money
  purchase, // Purchase from wallet
  refund, // Refund to wallet
  savings, // Transfer to savings
  savingsWithdrawal, // Withdraw from savings
}

/// Wallet transaction record
class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String description;
  final String? paymentMethod; // 'credit_card', 'bank_transfer', etc.
  final String status; // 'pending', 'completed', 'failed'
  final DateTime timestamp;
  final String? orderId;
  final String? referenceNumber;
  final Map<String, dynamic>? metadata;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.paymentMethod,
    this.status = 'completed',
    required this.timestamp,
    this.orderId,
    this.referenceNumber,
    this.metadata,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => TransactionType.deposit,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      paymentMethod: data['paymentMethod'],
      status: data['status'] ?? 'completed',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderId: data['orderId'],
      referenceNumber: data['referenceNumber'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'orderId': orderId,
      'referenceNumber': referenceNumber,
      'metadata': metadata,
    };
  }

  WalletTransaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? description,
    String? paymentMethod,
    String? status,
    DateTime? timestamp,
    String? orderId,
    String? referenceNumber,
    Map<String, dynamic>? metadata,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      orderId: orderId ?? this.orderId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// User's wallet account
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double totalAdded; // Total money added (cumulative)
  final double totalSpent; // Total spent from wallet
  final DateTime createdAt;
  final DateTime lastTransactionAt;
  final bool isActive;

  Wallet({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.totalAdded = 0.0,
    this.totalSpent = 0.0,
    required this.createdAt,
    required this.lastTransactionAt,
    this.isActive = true,
  });

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wallet(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalAdded: (data['totalAdded'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
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
      'totalAdded': totalAdded,
      'totalSpent': totalSpent,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTransactionAt': Timestamp.fromDate(lastTransactionAt),
      'isActive': isActive,
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    double? totalAdded,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? lastTransactionAt,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalAdded: totalAdded ?? this.totalAdded,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
