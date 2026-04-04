import 'package:flutter/material.dart';
import '../../models/seller_models.dart';

/// Seller onboarding context shared across all screens
class SellerOnboardingContext {
  String sellerType; // 'member' or 'wholesale'
  TargetCustomer? targetCustomer;
  SellerProfile? sellerProfile;
  SellerProduct? draftProduct;
  int currentStep = 1; // 1-5

  SellerOnboardingContext({
    this.sellerType = 'member',
    this.targetCustomer,
    this.sellerProfile,
    this.draftProduct,
    this.currentStep = 1,
  });

  void reset() {
    targetCustomer = null;
    sellerProfile = null;
    draftProduct = null;
    currentStep = 1;
  }
}
