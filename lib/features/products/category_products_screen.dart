import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String selectedFilter = 'Popular';
  late List<Map<String, dynamic>> products;

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  void _initializeProducts() {
    products = [
      {
        'name': 'Palm oil',
        'size': '5 ltrs',
        'price': 12000.0,
        'original': 14800.0,
        'company': 'Premium Oils',
        'image':
            'https://images.unsplash.com/photo-1587049352584-5374c67271f1?w=200&h=150&fit=crop',
      },
      {
        'name': 'Golden morn',
        'size': '900g x2',
        'price': 9500.0,
        'original': 12000.0,
        'company': 'Golden Foods',
        'image':
            'https://images.unsplash.com/photo-1599599810694-5c5c3b1c1e2e?w=200&h=150&fit=crop',
      },
      {
        'name': 'Sunflower oil',
        'size': '5 ltrs',
        'price': 25000.0,
        'original': 25800.0,
        'company': 'Oil Processors',
        'image':
            'https://images.unsplash.com/photo-1609780576341-38297e50d90f?w=200&h=150&fit=crop',
      },
      {
        'name': 'Chicken pack',
        'size': '1.5kg',
        'price': 7500.0,
        'original': 8500.0,
        'company': 'Fresh Poultry',
        'image':
            'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=200&h=150&fit=crop',
      },
      {
        'name': 'Full sized chicken',
        'size': '2.5kg',
        'price': 18000.0,
        'original': 27500.0,
        'company': 'Premium Chicken',
        'image':
            'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=200&h=150&fit=crop',
      },
      {
        'name': 'Long grain rice',
        'size': '50kg',
        'price': 53000.0,
        'original': 56000.0,
        'company': 'Rice Masters',
        'image':
            'https://images.unsplash.com/photo-1586080872057-aae4e5baa7d9?w=200&h=150&fit=crop',
      },
      {
        'name': 'Frozen drumsticks',
        'size': '3kg',
        'price': 8500.0,
        'original': 10600.0,
        'company': 'Fresh Poultry',
        'image':
            'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=200&h=150&fit=crop',
      },
      {
        'name': 'Fresh beef',
        'size': '5kg',
        'price': 18000.0,
        'original': 22500.0,
        'company': 'Meat Processors',
        'image':
            'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=200&h=150&fit=crop',
      },
      {
        'name': 'Tomatoes',
        'size': '5kg basket',
        'price': 5000.0,
        'original': 6500.0,
        'company': 'Farm Fresh',
        'image':
            'https://images.unsplash.com/photo-1592924568900-0ff02b6b8225?w=200&h=150&fit=crop',
      },
      {
        'name': 'Onions',
        'size': '10kg bag',
        'price': 8000.0,
        'original': 10000.0,
        'company': 'Veggie Plus',
        'image':
            'https://images.unsplash.com/photo-1587049352584-5374c67271f1?w=200&h=150&fit=crop',
      },
      {
        'name': 'Bell peppers',
        'size': '2kg',
        'price': 3500.0,
        'original': 4500.0,
        'company': 'Fresh Farms',
        'image':
            'https://images.unsplash.com/photo-1599599810694-5c5c3b1c1e2e?w=200&h=150&fit=crop',
      },
      {
        'name': 'Carrots',
        'size': '3kg',
        'price': 2800.0,
        'original': 3500.0,
        'company': 'Veggie Plus',
        'image':
            'https://images.unsplash.com/photo-1605027981618-8b9f88fb8b6b?w=200&h=150&fit=crop',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSavingsBanner(),
            _buildFilterPills(),
            _buildPromoSection(),
            _buildBundleSections(),
            _buildBestDealsSection(),
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
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.surface,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.categoryName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 30,
                    fontFamily: 'Libre Baskerville',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.favorite_outline,
                color: AppColors.surface,
                size: 24,
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

  Widget _buildSavingsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: AppColors.accent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Members save up to 18% in this category',
              style: TextStyle(
                color: const Color(0xFF0A0A0A),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'View savings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFAFAFA),
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      'Popular',
      'Member only',
      'Fast delivery',
      'Bulk',
      'New',
      'Best deals',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 10,
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFFAFAFA),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 2,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF111111),
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF111111),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.44,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.50, 0.32),
          radius: 1.53,
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.primary,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'This week\'s grocery essentials',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0A0A0A),
              fontSize: 32,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Feed a family for less than ',
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 24,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '50K!!',
                  style: TextStyle(
                    color: const Color(0xFFFAFAFA),
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBundleSections() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            spacing: 20,
            children: [
              // Bundle 1
              _buildBundleCard(
                title: 'Kitchen Essentials Bundle',
                totalPrice: 45000.0,
                items: [
                  {'name': 'Palm Oil (5L)', 'price': '₦12,000'},
                  {'name': 'Sunflower Oil (5L)', 'price': '₦25,000'},
                  {'name': 'Seasoning Mix', 'price': '₦8,000'},
                ],
                image:
                    'https://images.unsplash.com/photo-1587049352584-5374c67271f1?w=300&h=200&fit=crop',
              ),
              // Bundle 2
              _buildBundleCard(
                title: 'Meat & Protein Pack',
                totalPrice: 60000.0,
                items: [
                  {'name': 'Fresh Chicken (2.5kg)', 'price': '₦18,000'},
                  {'name': 'Beef (2kg)', 'price': '₦22,000'},
                  {'name': 'Fish Fillets', 'price': '₦15,000'},
                ],
                image:
                    'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=300&h=200&fit=crop',
              ),
              // Bundle 3
              _buildBundleCard(
                title: 'Grains & Staples Bundle',
                totalPrice: 35000.0,
                items: [
                  {'name': 'Rice (10kg)', 'price': '₦15,000'},
                  {'name': 'Beans (5kg)', 'price': '₦12,000'},
                  {'name': 'Flour (2kg)', 'price': '₦8,000'},
                ],
                image:
                    'https://images.unsplash.com/photo-1586080872057-aae4e5baa7d9?w=300&h=200&fit=crop',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBundleCard({
    required String title,
    required double totalPrice,
    required List<Map<String, String>> items,
    required String image,
  }) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bundle Image
          Container(
            width: double.infinity,
            height: 150,
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Column(
                  spacing: 8,
                  children: items
                      .map(
                        (item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['name']!,
                              style: TextStyle(
                                color: const Color(0xFF949494),
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              item['price']!,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
                Divider(
                  color: const Color(0xFFE0E0E0),
                  thickness: 1,
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            color: const Color(0xFF949494),
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          '₦${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pushNamed('cart');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$title added to cart'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Add all',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDealsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best deals today',
                style: TextStyle(
                  color: const Color(0xFF0A0A0A),
                  fontSize: 30,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: const Color(0xFF0A0A0A),
                size: 24,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: products.map((product) {
              return _buildProductCard(product);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final savings = product['original'] - product['price'];

    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFE9E6E6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 140,
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      product['image'] ?? "https://placehold.co/255x200"),
                  fit: BoxFit.cover,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['size'],
                  style: TextStyle(
                    color: const Color(0x99949494),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₦',
                        style: TextStyle(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      TextSpan(
                        text: product['original'].toStringAsFixed(0),
                        style: TextStyle(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₦${product['price'].toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Save ₦${savings.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pushNamed('cart');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} added to cart'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.surface,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
