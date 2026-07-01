import 'package:coop_commerce/core/models/seller_models.dart';
import 'package:coop_commerce/models/product.dart';

class RoleRelationshipSnapshot {
  final int actionableSkus;
  final int restockRiskSkus;
  final int bulkReadySkus;
  final int trustQualifiedSkus;
  final double valueSpreadPercent;
  final String narrative;

  const RoleRelationshipSnapshot({
    required this.actionableSkus,
    required this.restockRiskSkus,
    required this.bulkReadySkus,
    required this.trustQualifiedSkus,
    required this.valueSpreadPercent,
    required this.narrative,
  });
}

class RoleCommerceIntelligence {
  static RoleRelationshipSnapshot member(List<Product> products) {
    final catalog = products.where((p) => p.id.trim().isNotEmpty).toList();
    if (catalog.isEmpty) {
      return const RoleRelationshipSnapshot(
        actionableSkus: 0,
        restockRiskSkus: 0,
        bulkReadySkus: 0,
        trustQualifiedSkus: 0,
        valueSpreadPercent: 0,
        narrative:
            'No products yet. As sellers list inventory, member savings and trust-ranked picks will appear here.',
      );
    }

    final restockRisk =
        catalog.where((p) => p.stock > 0 && p.stock <= 10).length;
    final bulkReady = catalog
        .where((p) =>
            p.minimumOrderQuantity >= 5 && p.stock >= p.minimumOrderQuantity)
        .length;
    final trustQualified = catalog.where((p) => p.rating >= 4.0).length;

    final spreads = catalog
        .where((p) => p.retailPrice > 0 && p.wholesalePrice > 0)
        .map((p) => ((p.retailPrice - p.wholesalePrice) / p.retailPrice) * 100)
        .where((v) => v.isFinite)
        .toList();
    final spreadAvg = spreads.isEmpty
        ? 0.0
        : spreads.reduce((a, b) => a + b) / spreads.length;

    return RoleRelationshipSnapshot(
      actionableSkus: catalog.length,
      restockRiskSkus: restockRisk,
      bulkReadySkus: bulkReady,
      trustQualifiedSkus: trustQualified,
      valueSpreadPercent: spreadAvg.clamp(0, 100),
      narrative:
          'Member demand is strongest on trust-qualified products. $restockRisk SKUs may tighten soon as wholesale carts absorb supply.',
    );
  }

  static RoleRelationshipSnapshot wholesale(
    List<Product> products, {
    required int cartItems,
    required int activeOrders,
  }) {
    final catalog = products.where((p) => p.id.trim().isNotEmpty).toList();
    if (catalog.isEmpty) {
      return const RoleRelationshipSnapshot(
        actionableSkus: 0,
        restockRiskSkus: 0,
        bulkReadySkus: 0,
        trustQualifiedSkus: 0,
        valueSpreadPercent: 0,
        narrative:
            'No wholesale inventory yet. Seller listings and member trends will populate operational guidance here.',
      );
    }

    final restockRisk =
        catalog.where((p) => p.stock > 0 && p.stock <= 15).length;
    final bulkReady = catalog
        .where((p) =>
            p.minimumOrderQuantity >= 5 && p.stock >= p.minimumOrderQuantity)
        .length;
    final trustQualified = catalog.where((p) => p.rating >= 4.2).length;

    final spreads = catalog
        .where((p) => p.retailPrice > 0 && p.wholesalePrice > 0)
        .map((p) => ((p.retailPrice - p.wholesalePrice) / p.retailPrice) * 100)
        .where((v) => v.isFinite)
        .toList();
    final spreadAvg = spreads.isEmpty
        ? 0.0
        : spreads.reduce((a, b) => a + b) / spreads.length;

    return RoleRelationshipSnapshot(
      actionableSkus: catalog.length,
      restockRiskSkus: restockRisk,
      bulkReadySkus: bulkReady,
      trustQualifiedSkus: trustQualified,
      valueSpreadPercent: spreadAvg.clamp(0, 100),
      narrative:
          'Your $cartItems cart items and $activeOrders active orders are prioritized against seller fulfillment reliability and member-driven demand shifts.',
    );
  }

  static RoleRelationshipSnapshot seller(List<SellerProduct> products) {
    if (products.isEmpty) {
      return const RoleRelationshipSnapshot(
        actionableSkus: 0,
        restockRiskSkus: 0,
        bulkReadySkus: 0,
        trustQualifiedSkus: 0,
        valueSpreadPercent: 0,
        narrative:
            'Add products to activate buyer-intent intelligence for member and wholesale channels.',
      );
    }

    final approved =
        products.where((p) => p.status.name == 'approved').toList();
    final restockRisk =
        approved.where((p) => p.quantity > 0 && p.quantity <= 12).length;
    final bulkReady =
        approved.where((p) => p.moq >= 5 && p.quantity >= p.moq).length;
    final trustQualified = approved.length;

    final blendedValueSpread = approved
        .where((p) => p.price > 0)
        .map((p) => p.moq >= 5 ? 14.0 : 8.0)
        .toList();
    final spreadAvg = blendedValueSpread.isEmpty
        ? 0.0
        : blendedValueSpread.reduce((a, b) => a + b) /
            blendedValueSpread.length;

    return RoleRelationshipSnapshot(
      actionableSkus: products.length,
      restockRiskSkus: restockRisk,
      bulkReadySkus: bulkReady,
      trustQualifiedSkus: trustQualified,
      valueSpreadPercent: spreadAvg.clamp(0, 100),
      narrative:
          'Buyer behavior favors approved, fast-fulfill SKUs. Keep low-stock items replenished to protect both member conversion and wholesale repeat orders.',
    );
  }
}
