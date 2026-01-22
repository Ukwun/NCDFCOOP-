import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home screen data model
class HomeData {
  final double totalMemberSavings;
  final int itemsSavedCount;
  final List<CategoryData> featuredCategories;
  final List<ProductData> exclusiveProducts;
  final List<ProductData> trendingProducts;

  const HomeData({
    required this.totalMemberSavings,
    required this.itemsSavedCount,
    required this.featuredCategories,
    required this.exclusiveProducts,
    required this.trendingProducts,
  });
}

/// Category data model
class CategoryData {
  final String id;
  final String name;
  final String iconUrl;
  final int productCount;

  const CategoryData({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.productCount,
  });
}

/// Product data model
class ProductData {
  final String id;
  final String name;
  final double memberPrice;
  final double marketPrice;
  final String imageUrl;
  final double rating;
  final bool isExclusive;
  final int savingsPercentage;

  const ProductData({
    required this.id,
    required this.name,
    required this.memberPrice,
    required this.marketPrice,
    required this.imageUrl,
    this.rating = 0.0,
    this.isExclusive = false,
    required this.savingsPercentage,
  });
}

/// Home ViewModel
class HomeViewModel extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    return _fetchHomeData();
  }

  Future<HomeData> _fetchHomeData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    return HomeData(
      totalMemberSavings: 2450.50,
      itemsSavedCount: 156,
      featuredCategories: [
        const CategoryData(
          id: '1',
          name: 'Groceries',
          iconUrl: 'assets/icons/groceries.png',
          productCount: 1240,
        ),
        const CategoryData(
          id: '2',
          name: 'Electronics',
          iconUrl: 'assets/icons/electronics.png',
          productCount: 856,
        ),
        const CategoryData(
          id: '3',
          name: 'Home & Garden',
          iconUrl: 'assets/icons/home.png',
          productCount: 2340,
        ),
        const CategoryData(
          id: '4',
          name: 'Health & Beauty',
          iconUrl: 'assets/icons/health.png',
          productCount: 945,
        ),
        const CategoryData(
          id: '5',
          name: 'Sports',
          iconUrl: 'assets/icons/sports.png',
          productCount: 567,
        ),
        const CategoryData(
          id: '6',
          name: 'Books & Media',
          iconUrl: 'assets/icons/books.png',
          productCount: 423,
        ),
      ],
      exclusiveProducts: [
        const ProductData(
          id: '101',
          name: 'Premium Coffee Beans',
          memberPrice: 12.99,
          marketPrice: 18.99,
          imageUrl: 'assets/products/coffee.jpg',
          isExclusive: true,
          savingsPercentage: 32,
        ),
        const ProductData(
          id: '102',
          name: 'Organic Olive Oil',
          memberPrice: 8.49,
          marketPrice: 12.99,
          imageUrl: 'assets/products/olive_oil.jpg',
          isExclusive: true,
          savingsPercentage: 35,
        ),
        const ProductData(
          id: '103',
          name: 'Wireless Earbuds',
          memberPrice: 79.99,
          marketPrice: 129.99,
          imageUrl: 'assets/products/earbuds.jpg',
          isExclusive: true,
          savingsPercentage: 38,
        ),
        const ProductData(
          id: '104',
          name: 'Yoga Mat Set',
          memberPrice: 24.99,
          marketPrice: 39.99,
          imageUrl: 'assets/products/yoga.jpg',
          isExclusive: true,
          savingsPercentage: 37,
        ),
      ],
      trendingProducts: [
        const ProductData(
          id: '201',
          name: 'Stainless Steel Water Bottle',
          memberPrice: 16.99,
          marketPrice: 24.99,
          imageUrl: 'assets/products/water_bottle.jpg',
          rating: 4.8,
          savingsPercentage: 32,
        ),
        const ProductData(
          id: '202',
          name: 'Air Purifier',
          memberPrice: 89.99,
          marketPrice: 149.99,
          imageUrl: 'assets/products/air_purifier.jpg',
          rating: 4.6,
          savingsPercentage: 40,
        ),
        const ProductData(
          id: '203',
          name: 'LED Desk Lamp',
          memberPrice: 22.50,
          marketPrice: 34.99,
          imageUrl: 'assets/products/lamp.jpg',
          rating: 4.7,
          savingsPercentage: 36,
        ),
        const ProductData(
          id: '204',
          name: 'Ergonomic Keyboard',
          memberPrice: 45.99,
          marketPrice: 79.99,
          imageUrl: 'assets/products/keyboard.jpg',
          rating: 4.5,
          savingsPercentage: 42,
        ),
      ],
    );
  }

  /// Refresh home data
  Future<void> refreshHomeData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHomeData());
  }
}

/// Riverpod provider for home view model
final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeData>(
  HomeViewModel.new,
);

/// Provider to get total member savings
final totalMemberSavingsProvider = Provider<double>((ref) {
  return ref
          .watch(homeViewModelProvider)
          .whenData((data) => data.totalMemberSavings)
          .value ??
      0.0;
});

/// Provider to get items saved count
final itemsSavedCountProvider = Provider<int>((ref) {
  return ref
          .watch(homeViewModelProvider)
          .whenData((data) => data.itemsSavedCount)
          .value ??
      0;
});
