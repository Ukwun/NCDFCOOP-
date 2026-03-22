# Wallet Feature - Quick Reference Guide

## 🚀 Quick Start

### Access Wallet Feature
```dart
import 'package:coop_commerce/features/wallet/wallet_export.dart';

// Navigate to wallet
context.push('/wallet');
```

## 🛣️ Route Reference

| Route | Screen | Purpose |
|-------|--------|---------|
| `/wallet` | WalletScreen | Main wallet dashboard |
| `/wallet/add-money` | AddMoneyScreen | Fund wallet |
| `/wallet/withdraw` | WithdrawMoneyScreen | Withdraw to bank |
| `/wallet/transactions` | TransactionHistoryScreen | View transaction history |
| `/wallet/dashboard` | WalletDashboardScreen | Analytics dashboard |

## 📚 Common Tasks

### Get User's Wallet Balance
```dart
final balance = await ref.read(walletServiceProvider).getWallet(userId);
print('Balance: ₦${balance?.balance}');
```

### Watch Wallet Updates
```dart
ref.watch(walletBalanceProvider(userId)).when(
  data: (balance) => Text('₦$balance'),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
);
```

### Deposit Money Programmatically
```dart
await ref.read(walletServiceProvider).depositMoney(
  userId: user.id,
  amount: 5000,
  description: 'Manual deposit',
  paymentMethod: 'card',
);

// Refresh UI
ref.invalidate(walletBalanceProvider);
```

### Withdraw Money Programmatically
```dart
await ref.read(walletServiceProvider).withdrawMoney(
  userId: user.id,
  amount: 2000,
  description: 'Bank withdrawal',
  accountNumber: '1234567890',
  bankName: 'GTBank',
);

// Refresh UI
ref.invalidate(walletBalanceProvider);
```

### Get Transaction History
```dart
final transactions = await ref
  .read(walletServiceProvider)
  .getTransactionHistory(userId: user.id, limit: 50);

transactions.forEach((tx) {
  print('${tx.description}: ₦${tx.amount}');
});
```

## 🎨 UI Components

### Wallet Balance Card
Located in: `lib/features/wallet/widgets/wallet_card.dart`

### Transaction List
Located in: `lib/features/wallet/widgets/transaction_list.dart`

## 📱 Screen Navigation

### From Home Screen
```dart
// Add FAB to home that navigates to wallet
FloatingActionButton(
  onPressed: () => context.push('/wallet'),
  child: Icon(Icons.wallet),
);
```

### From User Profile
```dart
// Add wallet option to profile menu
ListTile(
  leading: Icon(Icons.account_balance_wallet),
  title: Text('My Wallet'),
  onTap: () => context.push('/wallet'),
);
```

## 🔍 Debugging Tips

### Check Wallet Existence
```dart
final wallet = await ref.read(walletServiceProvider).getWallet(userId);
if (wallet == null) print('Wallet not found for user: $userId');
```

### Monitor Transaction Status
```dart
final transactions = await ref.read(walletServiceProvider)
  .getTransactionHistory(userId: userId, limit: 100);

final pending = transactions.where((tx) => tx.status == 'pending').toList();
print('Pending transactions: ${pending.length}');
```

### Validate Amount
```dart
const double MIN_DEPOSIT = 100;
const double MAX_DEPOSIT = 500000;

bool isValidAmount(double amount) => 
  amount >= MIN_DEPOSIT && amount <= MAX_DEPOSIT;
```

## 🧪 Testing

### Test Deposit Flow
```dart
// Arrange
final userId = 'test-user-123';
final amount = 5000.0;

// Act
await walletService.depositMoney(
  userId: userId,
  amount: amount,
  description: 'Test deposit',
);

// Assert
final wallet = await walletService.getWallet(userId);
expect(wallet?.balance, amount);
```

### Test Withdrawal Validation
```dart
// Should fail with insufficient balance
expect(
  () => walletService.withdrawMoney(
    userId: userId,
    amount: 100000,
    description: 'Test',
    accountNumber: '1234567890',
    bankName: 'TestBank',
  ),
  throwsException,
);
```

## 📊 Firestore Structure

### Wallets Collection
```
/wallets/{userId}
├── userId: string
├── balance: double
├── totalAdded: double
├── totalSpent: double
├── createdAt: timestamp
├── lastTransactionAt: timestamp
└── isActive: boolean
```

### Transactions Collection
```
/wallet_transactions/{transactionId}
├── userId: string
├── type: string (deposit|withdrawal|purchase|refund|savings|savingsWithdrawal)
├── amount: double
├── description: string
├── status: string (pending|completed|failed)
├── timestamp: timestamp
├── paymentMethod: string (optional)
└── metadata: map (optional)
```

## ⚙️ Configuration

### Amount Limits (from WalletService)
```dart
static const double minDepositAmount = 100.0;
static const double maxDepositAmount = 500000.0;
```

### Collection Names
```dart
static const String walletsCollection = 'wallets';
static const String transactionsCollection = 'wallet_transactions';
```

## 🐛 Common Issues & Solutions

### Issue: Balance not updating
```
Solution: Call ref.invalidate(walletBalanceProvider) after transaction
```

### Issue: Withdrawal stays pending
```
Solution: Check Firestore for withdrawal document, verify bank details
```

### Issue: Transaction type icon not showing
```
Solution: Ensure TransactionType enum matches in transaction record
```

### Issue: Can't access wallet screens
```
Solution: Verify user is authenticated before accessing wallet routes
```

## 📝 Code Examples

### Add Wallet to Drawer Menu
```dart
ListTile(
  leading: Icon(Icons.account_balance_wallet),
  title: Text('Wallet'),
  onTap: () {
    Navigator.of(context).pop(); // Close drawer
    context.push('/wallet');
  },
),
```

### Display Balance in Home Header
```dart
AppBar(
  title: Text('Home'),
  actions: [
    Consumer(
      builder: (context, ref, child) {
        return ref.watch(walletBalanceProvider(userId)).when(
          data: (balance) => Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('₦${balance.toStringAsFixed(2)}'),
            ),
          ),
          loading: () => SizedBox.shrink(),
          error: (_, __) => SizedBox.shrink(),
        );
      },
    ),
  ],
);
```

### Custom Transaction Filter Widget
```dart
Widget buildTransactionFilter(
  String selectedType,
  Function(String) onChanged,
) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: ['All', 'Credit', 'Debit', 'Pending']
        .map((type) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: FilterChip(
            label: Text(type),
            selected: selectedType == type,
            onSelected: (_) => onChanged(type),
          ),
        ))
        .toList(),
    ),
  );
}
```

## 🔗 Related Files

- Service: `lib/core/api/wallet_service.dart`
- Models: `lib/models/wallet_models.dart`
- Providers: `lib/providers/wallet_provider.dart`
- Router: `lib/core/navigation/app_router.dart`
- Theme: `lib/theme/app_theme.dart`

## 📚 Full Documentation

See `WALLET_FEATURE_GUIDE.md` for comprehensive documentation.

---

**Last Updated:** 2026
**Version:** 1.0
**Status:** Production Ready ✅
