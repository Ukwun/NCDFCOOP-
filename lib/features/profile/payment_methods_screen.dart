import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class PaymentMethod {
  final String id;
  final String type;
  final String lastFourDigits;
  final String cardName;
  final bool _isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.lastFourDigits,
    required this.cardName,
    required bool isDefault,
  }) : _isDefault = isDefault;

  bool get isDefault => _isDefault;

  /// Create a copy with modified properties
  PaymentMethod copyWith({
    String? id,
    String? type,
    String? lastFourDigits,
    String? cardName,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardName: cardName ?? this.cardName,
      isDefault: isDefault ?? _isDefault,
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late List<PaymentMethod> paymentMethods;

  @override
  void initState() {
    super.initState();
    _initializePaymentMethods();
  }

  void _initializePaymentMethods() {
    paymentMethods = [
      PaymentMethod(
        id: '1',
        type: 'Card',
        lastFourDigits: '4242',
        cardName: 'Visa - Personal',
        isDefault: true,
      ),
      PaymentMethod(
        id: '2',
        type: 'Card',
        lastFourDigits: '5555',
        cardName: 'Mastercard - Work',
        isDefault: false,
      ),
      PaymentMethod(
        id: '3',
        type: 'Wallet',
        lastFourDigits: 'Balance',
        cardName: 'Cooperative Wallet',
        isDefault: false,
      ),
    ];
  }

  void _setAsDefault(String id) {
    setState(() {
      paymentMethods = paymentMethods.map((method) {
        if (method.id == id) {
          return method.copyWith(isDefault: true);
        } else if (method.isDefault) {
          return method.copyWith(isDefault: false);
        }
        return method;
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default payment method updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removePaymentMethod(String id) {
    setState(() {
      paymentMethods.removeWhere((m) => m.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment method removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addPaymentMethod() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add payment method - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildPaymentMethods(),
            _buildAddButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:45',
                style: AppTextStyles.h4.copyWith(color: AppColors.surface),
              ),
              Row(
                spacing: 6,
                children: [
                  _buildStatusIcon('assets/icons/signal.png'),
                  _buildStatusIcon('assets/icons/wifi.png'),
                  _buildStatusIcon('assets/icons/battery.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Methods',
                style: AppTextStyles.h2.copyWith(color: AppColors.surface),
              ),
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted, width: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: paymentMethods.map((method) {
          return _buildPaymentCard(method);
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentMethod method) {
    final isCard = method.type == 'Card';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: method.isDefault
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: method.isDefault ? AppColors.primary : AppColors.border,
          width: method.isDefault ? 2 : 1,
        ),
        boxShadow: AppShadows.smList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isCard ? Icons.credit_card : Icons.account_balance_wallet,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.cardName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCard
                          ? '••••••••${method.lastFourDigits}'
                          : method.lastFourDigits,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Default',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Actions
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _setAsDefault(method.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: method.isDefault
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      'Set as Default',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: method.isDefault
                            ? AppColors.surface
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removePaymentMethod(method.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _addPaymentMethod,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              Text(
                'Add Payment Method',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
