import 'package:flutter/material.dart';
import '../../models/seller_models.dart';
import '../../services/seller_service.dart';
import 'seller_onboarding_context.dart';
import 'screens/seller_onboarding_landing_screen.dart';
import 'screens/seller_setup_screen.dart';
import 'screens/product_upload_screen.dart';
import 'screens/product_status_screen.dart';
import 'screens/seller_dashboard_screen.dart';

/// SELLER ONBOARDING ORCHESTRATOR
/// Manages the complete 5-screen seller onboarding flow
/// sellerType: 'member' or 'wholesale'
class SellerOnboardingScreen extends StatefulWidget {
  final String userId;
  final String sellerType; // 'member' or 'wholesale'

  const SellerOnboardingScreen({
    super.key,
    required this.userId,
    this.sellerType = 'member',
  });

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  late SellerOnboardingContext _context;
  late SellerService _sellerService;
  List<SellerProduct> _products = [];

  int _currentStep = 1; // 1-5

  @override
  void initState() {
    super.initState();
    _context = SellerOnboardingContext(sellerType: widget.sellerType);
    _sellerService = SellerService();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return SellerOnboardingLandingScreen(
          onStartSelling: _handleStartSelling,
        );
      case 2:
        return SellerSetupScreen(
          onContinue: _handleSellerSetup,
          onBack: () => _goToStep(1),
          sellingPath: _context.sellerType,
        );
      case 3:
        return ProductUploadScreen(
          targetCustomer: _context.targetCustomer!,
          onProductAdded: _handleProductAdded,
          onBack: () => _goToStep(2),
        );
      case 4:
        return ProductStatusScreen(
          productName: _context.draftProduct?.productName ?? 'Product',
          status:
              _context.draftProduct?.status ?? ProductApprovalStatus.pending,
          rejectionReason: _context.draftProduct?.rejectionReason,
          onEditProduct: () => _goToStep(3),
          onAddAnotherProduct: _handleAddAnotherProduct,
          onGoToDashboard: () => _goToStep(5),
        );
      case 5:
        return SellerDashboardScreen(
          businessName: _context.sellerProfile?.businessName ?? 'My Store',
          products: _products,
          onAddNewProduct: _handleAddNewProduct,
          onProductTap: () {
            // Product details navigation
          },
        );
      default:
        return const Scaffold(
          body: Center(child: Text('Invalid step')),
        );
    }
  }

  void _handleStartSelling() {
    _goToStep(2);
  }

  void _handleSellerSetup(
    String businessName,
    String sellerType,
    String country,
    String category,
    TargetCustomer targetCustomer,
  ) {
    // Create seller profile with the selected selling path (member or wholesale)
    final profile = SellerProfile(
      userId: widget.userId,
      businessName: businessName,
      sellerType: sellerType,
      sellingPath: _context.sellerType, // 'member' or 'wholesale'
      country: country,
      category: category,
      targetCustomer: targetCustomer,
      createdAt: DateTime.now(),
    );

    _context.sellerProfile = profile;
    _context.targetCustomer = targetCustomer;

    // Save to Firebase
    _sellerService.createSellerProfile(profile).then((savedProfile) {
      _context.sellerProfile = savedProfile;
      _goToStep(3);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile: $e')),
      );
    });
  }

  void _handleProductAdded(
    String name,
    String category,
    double price,
    int quantity,
    int moq,
    String imageUrl,
    String description,
  ) {
    if (_context.sellerProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller profile not found')),
      );
      return;
    }

    // Create product
    final product = SellerProduct(
      sellerId: _context.sellerProfile!.id ?? '',
      productName: name,
      category: category,
      price: price,
      quantity: quantity,
      moq: moq,
      imageUrl: imageUrl,
      description: description,
      status: ProductApprovalStatus.pending,
      createdAt: DateTime.now(),
    );

    _context.draftProduct = product;

    // Save to Firebase
    _sellerService.addProduct(product).then((savedProduct) {
      _context.draftProduct = savedProduct;
      _products.add(savedProduct);

      // Show success toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product submitted for review'),
          duration: Duration(seconds: 2),
        ),
      );

      _goToStep(4);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    });
  }

  void _handleAddAnotherProduct() {
    _goToStep(3);
  }

  void _handleAddNewProduct() {
    _goToStep(3);
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }
}
