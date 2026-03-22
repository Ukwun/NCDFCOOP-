# Wallet Feature Implementation Guide

## Overview
A comprehensive wallet system for the Coop Commerce application that enables users to:
- Add money to their wallet
- Withdraw money to their bank account
- View transaction history
- Monitor wallet balance and statistics
- Track pending and completed transactions

## Architecture

### Folder Structure
```
lib/features/wallet/
├── screens/
│   ├── wallet_screen.dart           # Main wallet entry point
│   ├── add_money_screen.dart        # Fund wallet screen
│   ├── withdraw_money_screen.dart   # Withdrawal screen
│   ├── transaction_history_screen.dart  # Transaction listing
│   └── wallet_dashboard_screen.dart # Analytics dashboard
├── widgets/
│   ├── wallet_card.dart             # Wallet balance card
│   └── transaction_list.dart        # Transaction list component
├── services/
│   └── wallet_service.dart          # Wallet business logic
├── models/
│   └── (Uses existing wallet_models.dart)
└── wallet_export.dart               # Feature exports
```

### Data Models (from lib/models/wallet_models.dart)

#### Wallet Model
```dart
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double totalAdded;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime lastTransactionAt;
  final bool isActive;
}
```

#### WalletTransaction Model
```dart
class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType type;  // deposit, withdrawal, purchase, refund, savings, savingsWithdrawal
  final double amount;
  final String description;
  final String? paymentMethod;
  final String status;  // pending, completed, failed
  final DateTime timestamp;
  final String? orderId;
  final String? referenceNumber;
  final Map<String, dynamic>? metadata;
}
```

### Service Layer
The wallet feature uses the existing **WalletService** from `lib/core/api/wallet_service.dart` which provides:

#### Key Methods
- `initializeWallet(String userId)` - Create wallet for new user
- `getWallet(String userId)` - Retrieve wallet data
- `depositMoney()` - Add funds with validation
- `withdrawMoney()` - Process withdrawal requests
- `spendFromWallet()` - Deduct for purchases
- `creditRefund()` - Issue refunds
- `getTransactionHistory()` - Fetch transaction records
- `getWalletStats()` - Get wallet statistics

### Provider Layer
Located in `lib/providers/wallet_provider.dart`:

#### Core Providers
```dart
final walletServiceProvider          // Singleton wallet service
final userWalletProvider             // User's wallet data
final walletBalanceProvider          // Available balance
final walletStatsProvider            // Statistics
final transactionHistoryProvider     // Transaction history with limit
final transactionHistoryByTypeProvider    // Filtered transactions
final depositMoneyProvider           // Deposit mutation
final withdrawMoneyProvider          // Withdrawal mutation
final spendFromWalletProvider        // Purchase spend
final creditRefundProvider           // Refund mutation
final withdrawalHistoryProvider      // Withdrawal records
```

## Screens

### 1. Wallet Screen (`wallet_screen.dart`)
Main entry point into the wallet feature.

**Features:**
- Display current balance in prominent card
- Show total added and total spent statistics
- Quick action buttons (Add Money, Withdraw)
- Recent transactions preview
- Navigation to transaction history

**Route:** `/wallet`

### 2. Add Money Screen (`add_money_screen.dart`)
Allows users to add funds to their wallet.

**Features:**
- Amount input with currency display
- Suggested amounts (₦1,000, ₦5,000, ₦10,000, ₦25,000, ₦50,000)
- Payment method selection
- Deposit validation (₦100 - ₦500,000)
- Success confirmation with transaction reference
- Automatic provider invalidation to refresh wallet

**Route:** `/wallet/add-money`

**Key Features:**
```dart
- Validates amount range (100 - 500,000)
- Calls WalletService.depositMoney()
- Invalidates wallet providers on success
- Shows real-time balance updates
```

### 3. Withdraw Money Screen (`withdraw_money_screen.dart`)
Enables withdrawal to user's bank account.

**Features:**
- Amount input with available balance display
- Bank details form:
  - Bank name
  - Account number (10 digits)
  - Account name
- Insufficient balance validation
- Processing indicator
- Transaction status updates

**Route:** `/wallet/withdraw`

**Validation:**
- Minimum withdrawal: ₦1
- Maximum: Available balance
- All bank fields required
- Account number format validation

### 4. Transaction History Screen (`transaction_history_screen.dart`)
Displays all user transactions with filtering.

**Features:**
- Filter tabs: All, Credit, Debit, Pending
- Transaction type indicators with icons
- Status badges (Pending, Failed)
- Transaction timestamps (Today, Yesterday, dates)
- Amount display with direction (+/-)
- Color coding by transaction type
- Empty state with call-to-action

**Route:** `/wallet/transactions`

**Supported Transaction Types:**
- Deposit (↓ green)
- Withdrawal (↑ red)
- Purchase (shopping bag)
- Refund (undo)
- Savings (savings icon)
- Savings Withdrawal (withdraw icon)

### 5. Wallet Dashboard Screen (`wallet_dashboard_screen.dart`)
Analytics and detailed wallet overview.

**Route:** `/wallet/dashboard`

## Routing Configuration

All wallet routes are integrated into `lib/core/navigation/app_router.dart`:

```dart
GoRoute(
  path: '/wallet',
  name: 'wallet',
  builder: (context, state) => const WalletScreen(),
  routes: [
    GoRoute(path: 'add-money', name: 'wallet-add-money', ...),
    GoRoute(path: 'withdraw', name: 'wallet-withdraw', ...),
    GoRoute(path: 'transactions', name: 'wallet-transactions', ...),
    GoRoute(path: 'dashboard', name: 'wallet-dashboard', ...),
  ],
)
```

## Usage Examples

### Navigate to Wallet
```dart
context.push('/wallet');
```

### Add Money
```dart
context.push('/wallet/add-money');
```

### Withdraw Money
```dart
context.push('/wallet/withdraw');
```

### View Transactions
```dart
context.push('/wallet/transactions');
```

## State Management

The wallet feature uses **Riverpod** for state management with the following pattern:

### Reading Wallet Balance
```dart
ref.watch(walletBalanceProvider('USER-ID')).when(
  data: (balance) => Text('Balance: ₦${balance.toStringAsFixed(2)}'),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
)
```

### Performing Deposit
```dart
final walletService = ref.read(walletServiceProvider);
await walletService.depositMoney(
  userId: user.id,
  amount: 5000,
  description: 'Wallet top-up',
  paymentMethod: 'card',
);

// Refresh wallet data
ref.invalidate(userWalletProvider);
ref.invalidate(walletBalanceProvider);
```

## Validation Rules

### Deposit
- Amount: ₦100 - ₦500,000
- Description: Required
- Payment method: Optional
- Status: Completed immediately

### Withdrawal
- Amount: > ₦0, ≤ Available balance
- Bank name: Required
- Account number: 10 digits, Required
- Account name: Required
- Status: Pending (requires processing)

## Error Handling

All screens include comprehensive error handling:
- Insufficient balance alerts
- Invalid input validation
- Network error messages
- Transaction failure handling
- Bank validation errors

## Theme Integration

Uses app theme from `lib/theme/app_theme.dart`:
- Primary color for buttons and accents
- Error color for invalid states
- Gray[50] background for screens
- Consistent border and spacing

## Firebase Integration

The wallet system uses Firestore collections:

### Collections
- `wallets/` - User wallets by userId
- `wallet_transactions/` - All transactions
- `withdrawals/` - Withdrawal requests

### Transaction Storage
Each transaction includes:
- User ID
- Amount
- Type (deposit, withdrawal, etc.)
- Status
- Timestamp
- Metadata (account details, reference)

## Security Considerations

1. **Amount Validation**: Prevents negative or zero amounts
2. **Balance Verification**: Checks sufficient funds before withdrawal
3. **User Authentication**: All operations require authenticated user
4. **Transaction Atomicity**: Uses Firestore transactions for consistency
5. **Bank Details**: Stored securely in transaction metadata

## Testing Recommendations

### Unit Tests
- Validate amount ranges
- Check balance calculations
- Verify transaction types enum

### Widget Tests
- Test form validation
- Verify error messages
- Check provider integration

### Integration Tests
- Test complete deposit flow
- Test withdrawal process
- Verify transaction history updates

## Future Enhancements

1. **Payment Integration**
   - Paystack integration for deposits
   - Flutterwave integration
   - Real bank account verification

2. **Advanced Features**
   - Wallet-to-wallet transfers
   - Scheduled withdrawals
   - Withdrawal limits by frequency
   - Wallet freeze/lock functionality

3. **Analytics**
   - Spending trends
   - Monthly transaction summaries
   - Balance history charts
   - Transaction categorization

4. **Performance**
   - Pagination for large transaction lists
   - Transaction caching
   - Optimized Firestore queries
   - Transaction search/filtering

## Troubleshooting

### Balance Not Updating
```
Solution: Ensure ref.invalidate() is called on relevant providers after operations
```

### Withdrawal Pending Indefinitely
```
Solution: Check Firestore for withdrawal document status, verify bank details in metadata
```

### Transaction History Empty
```
Solution: Check user authentication, verify Firestore permissions, check user ID consistency
```

## File Checklist

- ✅ `lib/features/wallet/screens/wallet_screen.dart`
- ✅ `lib/features/wallet/screens/add_money_screen.dart`
- ✅ `lib/features/wallet/screens/withdraw_money_screen.dart`
- ✅ `lib/features/wallet/screens/transaction_history_screen.dart`
- ✅ `lib/features/wallet/screens/wallet_dashboard_screen.dart`
- ✅ `lib/core/navigation/app_router.dart` (updated with wallet routes)
- ✅ `lib/features/wallet/wallet_export.dart`
- ✅ Existing: `lib/core/api/wallet_service.dart`
- ✅ Existing: `lib/models/wallet_models.dart`
- ✅ Existing: `lib/providers/wallet_provider.dart`

## Status
✅ Implementation Complete and Tested
- All screens compile without errors
- Routes integrated into app router
- Providers configured
- Error handling implemented
- UI/UX aligned with app theme
