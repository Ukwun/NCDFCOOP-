import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/wallet_models.dart';

/// Wallet Service - manages user account balances and transactions
class WalletService {
  static final WalletService _instance = WalletService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constants
  static const double minDepositAmount = 100.0;
  static const double maxDepositAmount = 500000.0;
  static const String walletsCollection = 'wallets';
  static const String transactionsCollection = 'wallet_transactions';

  factory WalletService() {
    return _instance;
  }

  WalletService._internal();

  /// Initialize wallet for a new user
  Future<Wallet> initializeWallet(String userId) async {
    try {
      final walletRef = _firestore.collection(walletsCollection).doc(userId);

      // Check if wallet already exists
      final existingWallet = await walletRef.get();
      if (existingWallet.exists) {
        return Wallet.fromFirestore(existingWallet);
      }

      // Create new wallet
      final now = DateTime.now();
      final wallet = Wallet(
        id: userId,
        userId: userId,
        balance: 0.0,
        totalAdded: 0.0,
        totalSpent: 0.0,
        createdAt: now,
        lastTransactionAt: now,
        isActive: true,
      );

      await walletRef.set(wallet.toFirestore());
      debugPrint('✅ Wallet initialized for user: $userId');
      return wallet;
    } catch (e) {
      debugPrint('❌ Error initializing wallet: $e');
      rethrow;
    }
  }

  /// Get user's wallet
  Future<Wallet?> getWallet(String userId) async {
    try {
      final doc =
          await _firestore.collection(walletsCollection).doc(userId).get();
      if (!doc.exists) return null;
      return Wallet.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching wallet: $e');
      rethrow;
    }
  }

  /// Add money to wallet (deposit)
  Future<WalletTransaction> depositMoney({
    required String userId,
    required double amount,
    required String description,
    String? paymentMethod,
    String? referenceNumber,
  }) async {
    try {
      if (amount < minDepositAmount || amount > maxDepositAmount) {
        throw Exception(
          'Deposit amount must be between ₦$minDepositAmount and ₦$maxDepositAmount',
        );
      }

      // Get or initialize wallet
      var wallet = await getWallet(userId);
      if (wallet == null) {
        wallet = await initializeWallet(userId);
      }

      // Create transaction record
      final transactionRef =
          _firestore.collection(transactionsCollection).doc();
      final timestamp = DateTime.now();
      final transaction = WalletTransaction(
        id: transactionRef.id,
        userId: userId,
        type: TransactionType.deposit,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        status: 'completed',
        timestamp: timestamp,
        referenceNumber: referenceNumber,
        metadata: {
          'source': 'deposit',
          'paymentMethod': paymentMethod,
        },
      );

      // Update wallet in transaction
      await _firestore.runTransaction((txn) async {
        // Add transaction record
        await transactionRef.set(transaction.toFirestore());

        // Update wallet balance
        final newBalance = wallet!.balance + amount;
        await txn.update(
          _firestore.collection(walletsCollection).doc(userId),
          {
            'balance': newBalance,
            'totalAdded': wallet.totalAdded + amount,
            'lastTransactionAt': FieldValue.serverTimestamp(),
          },
        );
      });

      debugPrint('✅ Deposited ₦$amount to wallet for user: $userId');
      return transaction;
    } catch (e) {
      debugPrint('❌ Error depositing money: $e');
      rethrow;
    }
  }

  /// Withdraw money from wallet
  Future<WalletTransaction> withdrawMoney({
    required String userId,
    required double amount,
    required String description,
    String? accountNumber,
    String? bankName,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Withdrawal amount must be greater than 0');
      }

      // Get current wallet
      final wallet = await getWallet(userId);
      if (wallet == null) {
        throw Exception('Wallet not found for user');
      }

      if (wallet.balance < amount) {
        throw Exception(
          'Insufficient balance. Available: ₦${wallet.balance.toStringAsFixed(2)}',
        );
      }

      // Create transaction record
      final transactionRef =
          _firestore.collection(transactionsCollection).doc();
      final timestamp = DateTime.now();
      final transaction = WalletTransaction(
        id: transactionRef.id,
        userId: userId,
        type: TransactionType.withdrawal,
        amount: amount,
        description: description,
        status: 'pending', // Withdrawal needs processing
        timestamp: timestamp,
        metadata: {
          'accountNumber': accountNumber,
          'bankName': bankName,
        },
      );

      // Update wallet in transaction
      await _firestore.runTransaction((txn) async {
        // Add transaction record
        final walletRef = _firestore.collection(walletsCollection).doc(userId);
        final currentWalletSnapshot = await txn.get(walletRef);

        if (!currentWalletSnapshot.exists) {
          throw Exception('Wallet not found');
        }

        final currentBalance =
            (currentWalletSnapshot.get('balance') as num).toDouble();
        if (currentBalance < amount) {
          throw Exception('Insufficient funds');
        }

        // Record transaction
        await transactionRef.set(transaction.toFirestore());

        // Deduct from balance
        final newBalance = currentBalance - amount;
        await txn.update(walletRef, {
          'balance': newBalance,
          'lastTransactionAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('✅ Withdrawal of ₦$amount initiated for user: $userId');
      return transaction;
    } catch (e) {
      debugPrint('❌ Error withdrawing money: $e');
      rethrow;
    }
  }

  /// Spend from wallet (for purchases)
  Future<WalletTransaction> spendFromWallet({
    required String userId,
    required double amount,
    required String orderId,
    String? description,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Spend amount must be greater than 0');
      }

      final wallet = await getWallet(userId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      if (wallet.balance < amount) {
        throw Exception('Insufficient wallet balance for purchase');
      }

      final transactionRef =
          _firestore.collection(transactionsCollection).doc();
      final timestamp = DateTime.now();

      await _firestore.runTransaction((txn) async {
        final walletRef = _firestore.collection(walletsCollection).doc(userId);
        final walletSnapshot = await txn.get(walletRef);

        if (!walletSnapshot.exists) {
          throw Exception('Wallet not found');
        }

        final currentBalance =
            (walletSnapshot.get('balance') as num).toDouble();
        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Record transaction
        await transactionRef.set({
          'userId': userId,
          'type': TransactionType.purchase.name,
          'amount': amount,
          'description': description ?? 'Purchase payment',
          'status': 'completed',
          'timestamp': Timestamp.fromDate(timestamp),
          'orderId': orderId,
          'metadata': {'source': 'purchase'},
        });

        // Deduct from wallet
        await txn.update(walletRef, {
          'balance': FieldValue.increment(-amount),
          'totalSpent': FieldValue.increment(amount),
          'lastTransactionAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint(
        '✅ Spent ₦$amount from wallet for order: $orderId (user: $userId)',
      );

      return WalletTransaction(
        id: transactionRef.id,
        userId: userId,
        type: TransactionType.purchase,
        amount: amount,
        description: description ?? 'Purchase payment',
        status: 'completed',
        timestamp: timestamp,
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('❌ Error spending from wallet: $e');
      rethrow;
    }
  }

  /// Credit refund to wallet
  Future<WalletTransaction> creditRefund({
    required String userId,
    required double amount,
    required String orderId,
    String? reason,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Refund amount must be greater than 0');
      }

      final wallet = await getWallet(userId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      final transactionRef =
          _firestore.collection(transactionsCollection).doc();
      final timestamp = DateTime.now();

      await _firestore.runTransaction((txn) async {
        // Record refund transaction
        await transactionRef.set({
          'userId': userId,
          'type': TransactionType.refund.name,
          'amount': amount,
          'description': reason ?? 'Order refund',
          'status': 'completed',
          'timestamp': Timestamp.fromDate(timestamp),
          'orderId': orderId,
          'metadata': {'reason': reason},
        });

        // Credit to balance
        await txn.update(
          _firestore.collection(walletsCollection).doc(userId),
          {
            'balance': FieldValue.increment(amount),
            'lastTransactionAt': FieldValue.serverTimestamp(),
          },
        );
      });

      debugPrint('✅ Refunded ₦$amount to wallet for order: $orderId');

      return WalletTransaction(
        id: transactionRef.id,
        userId: userId,
        type: TransactionType.refund,
        amount: amount,
        description: reason ?? 'Order refund',
        status: 'completed',
        timestamp: timestamp,
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('❌ Error crediting refund: $e');
      rethrow;
    }
  }

  /// Transfer money to savings account
  Future<WalletTransaction> transferToSavings({
    required String userId,
    required double amount,
    String? description,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Transfer amount must be greater than 0');
      }

      final wallet = await getWallet(userId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      if (wallet.balance < amount) {
        throw Exception('Insufficient wallet balance');
      }

      final transactionRef =
          _firestore.collection(transactionsCollection).doc();
      final timestamp = DateTime.now();

      await _firestore.runTransaction((txn) async {
        // Record transfer transaction
        await transactionRef.set({
          'userId': userId,
          'type': TransactionType.savings.name,
          'amount': amount,
          'description': description ?? 'Transfer to savings',
          'status': 'completed',
          'timestamp': Timestamp.fromDate(timestamp),
          'metadata': {'source': 'wallet_transfer'},
        });

        // Deduct from wallet
        await txn.update(
          _firestore.collection(walletsCollection).doc(userId),
          {
            'balance': FieldValue.increment(-amount),
            'lastTransactionAt': FieldValue.serverTimestamp(),
          },
        );
      });

      debugPrint('✅ Transferred ₦$amount to savings for user: $userId');

      return WalletTransaction(
        id: transactionRef.id,
        userId: userId,
        type: TransactionType.savings,
        amount: amount,
        description: description ?? 'Transfer to savings',
        status: 'completed',
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('❌ Error transferring to savings: $e');
      rethrow;
    }
  }

  /// Get transaction history for a user
  Future<List<WalletTransaction>> getTransactionHistory({
    required String userId,
    int limit = 50,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(transactionsCollection)
          .where('userId', isEqualTo: userId);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching transaction history: $e');
      rethrow;
    }
  }

  /// Get wallet balance available for spending
  Future<double> getAvailableBalance(String userId) async {
    try {
      final wallet = await getWallet(userId);
      return wallet?.balance ?? 0.0;
    } catch (e) {
      debugPrint('❌ Error getting available balance: $e');
      return 0.0;
    }
  }

  /// Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final wallet = await getWallet(userId);
      if (wallet == null) {
        return {
          'balance': 0.0,
          'totalAdded': 0.0,
          'totalSpent': 0.0,
        };
      }

      return {
        'balance': wallet.balance,
        'totalAdded': wallet.totalAdded,
        'totalSpent': wallet.totalSpent,
        'createdAt': wallet.createdAt,
        'transactions': await getTransactionHistory(userId: userId, limit: 100),
      };
    } catch (e) {
      debugPrint('❌ Error getting wallet stats: $e');
      rethrow;
    }
  }
}
