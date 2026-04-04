import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Demand Forecast Screen
/// Shows predicted demand for commonly ordered products based on historical data
class DemandForecastScreen extends StatefulWidget {
  const DemandForecastScreen({Key? key}) : super(key: key);

  @override
  State<DemandForecastScreen> createState() => _DemandForecastScreenState();
}

class _DemandForecastScreenState extends State<DemandForecastScreen> {
  String _selectedPeriod = '30days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Demand Forecast',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.trending_up_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Predicted Product Demand',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your order history and market trends.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Period selector
              Text(
                'Forecast Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PeriodButton(
                    label: 'Next 30 Days',
                    value: '30days',
                    selected: _selectedPeriod == '30days',
                    onTap: () => setState(() => _selectedPeriod = '30days'),
                  ),
                  const SizedBox(width: 12),
                  _PeriodButton(
                    label: 'Next 90 Days',
                    value: '90days',
                    selected: _selectedPeriod == '90days',
                    onTap: () => setState(() => _selectedPeriod = '90days'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Top forecast items
              Text(
                'Top Predicted Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Product forecast card 1
              _ForecastCard(
                productName: 'Premium Rice (50kg)',
                category: 'Grains',
                currentMonthly: 50,
                forecastedQuantity: 75,
                confidenceScore: 92,
                trend: 'up',
              ),

              const SizedBox(height: 12),

              // Product forecast card 2
              _ForecastCard(
                productName: 'Palm Oil (Bulk)',
                category: 'Oils & Fats',
                currentMonthly: 30,
                forecastedQuantity: 45,
                confidenceScore: 85,
                trend: 'up',
              ),

              const SizedBox(height: 12),

              // Product forecast card 3
              _ForecastCard(
                productName: 'Tomato Paste (Cases)',
                category: 'Processed Foods',
                currentMonthly: 20,
                forecastedQuantity: 25,
                confidenceScore: 78,
                trend: 'stable',
              ),

              const SizedBox(height: 12),

              // Product forecast card 4
              _ForecastCard(
                productName: 'Wheat Flour (25kg)',
                category: 'Grains',
                currentMonthly: 15,
                forecastedQuantity: 18,
                confidenceScore: 81,
                trend: 'up',
              ),

              const SizedBox(height: 12),

              // Product forecast card 5
              _ForecastCard(
                productName: 'Sugar (Refined)',
                category: 'Sweeteners',
                currentMonthly: 25,
                forecastedQuantity: 20,
                confidenceScore: 76,
                trend: 'down',
              ),

              const SizedBox(height: 32),

              // Insights section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Your demand for grains is increasing 15% month-over-month\n'
                      '• Best time to order is Tuesday-Thursday for faster delivery\n'
                      '• Consider bulk discounts for rice - you\'re ordering frequently',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createOrderFromForecast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create Order from Forecast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createOrderFromForecast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening pre-populated order form...'),
        duration: Duration(seconds: 2),
      ),
    );

    // In a real app, this would navigate to create order with pre-filled quantities
    // context.push('/checkout', extra: forecastData);
  }
}

/// Period selector button
class _PeriodButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey[300]!,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color:
                  selected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.primary : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Forecast card widget
class _ForecastCard extends StatelessWidget {
  final String productName;
  final String category;
  final int currentMonthly;
  final int forecastedQuantity;
  final int confidenceScore;
  final String trend; // 'up', 'down', 'stable'

  const _ForecastCard({
    required this.productName,
    required this.category,
    required this.currentMonthly,
    required this.forecastedQuantity,
    required this.confidenceScore,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final percentageChange =
        ((forecastedQuantity - currentMonthly) / currentMonthly * 100).toInt();
    final trendColor = trend == 'up'
        ? Colors.green
        : trend == 'down'
            ? Colors.red
            : Colors.orange;
    final trendIcon = trend == 'up'
        ? Icons.trending_up
        : trend == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$percentageChange%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Current Monthly',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentMonthly units',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Forecasted',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$forecastedQuantity units',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Confidence',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$confidenceScore%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
