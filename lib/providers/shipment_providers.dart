import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/services/logistics_service.dart';
import 'package:coop_commerce/models/logistics_models.dart';

// ============ SERVICE PROVIDER ============

/// Logistics service provider
final logisticsServiceProvider = Provider<LogisticsService>((ref) {
  return LogisticsService();
});

// ============ DATA PROVIDERS ============

/// Get single shipment by ID
final shipmentProvider =
    FutureProvider.family<Shipment?, String>((ref, shipmentId) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getShipment(shipmentId);
});

/// Watch shipment real-time updates
final watchShipmentProvider =
    StreamProvider.family<Shipment, String>((ref, shipmentId) {
  final service = ref.watch(logisticsServiceProvider);
  return service.watchShipment(shipmentId);
});

/// Get all shipments for a member
final memberShipmentsProvider = FutureProvider.family<List<Shipment>, String>(
  (ref, memberId) async {
    final service = ref.watch(logisticsServiceProvider);
    return service.getMemberShipments(memberId);
  },
);

/// Get shipments by status
final shipmentsByStatusProvider =
    FutureProvider.family<List<Shipment>, ShipmentStatus>((ref, status) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getShipmentsByStatus(status);
});

/// Get tracking history for shipment
final trackingHistoryProvider =
    FutureProvider.family<List<TrackingEvent>, String>((ref, shipmentId) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getTrackingHistory(shipmentId);
});

/// Get available shipping rates for carrier
final shippingRatesProvider =
    FutureProvider.family<List<ShippingRate>, CarrierType>(
  (ref, carrier) async {
    final service = ref.watch(logisticsServiceProvider);
    // Default parameters - in real app these would come from cart context
    return service.getShippingRates(
      carrier: carrier,
      totalWeight: 5.0,
      destination: 'Nairobi',
    );
  },
);

/// Get all carrier quotes for comparison
final carrierQuotesProvider =
    FutureProvider.family<List<ShippingRate>, List<ShipmentItem>>(
  (ref, items) async {
    final service = ref.watch(logisticsServiceProvider);
    // Default shipping address - in real app this would come from user context
    final address = ShippingAddress(
      recipientName: 'Recipient',
      phoneNumber: '+254700000000',
      email: 'recipient@example.com',
      addressLine1: 'Address Line 1',
      addressLine2: 'Address Line 2',
      city: 'Nairobi',
      state: 'NA',
      postalCode: '00100',
      country: 'Kenya',
      latitude: -1.2865,
      longitude: 36.8172,
    );

    return service.getCarrierQuotes(items: items, destination: address);
  },
);

/// Get carrier integration configuration
final carrierIntegrationProvider =
    FutureProvider.family<CarrierIntegration?, CarrierType>(
        (ref, carrier) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getCarrierIntegration(carrier);
});

/// Get delivery statistics
final deliveryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getDeliveryStats();
});

/// Get all pending shipments
final pendingShipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getShipmentsByStatus(ShipmentStatus.pending);
});

/// Get all in-transit shipments
final inTransitShipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  final service = ref.watch(logisticsServiceProvider);
  final inTransit =
      await service.getShipmentsByStatus(ShipmentStatus.inTransit);
  final outForDelivery =
      await service.getShipmentsByStatus(ShipmentStatus.outForDelivery);
  return [...inTransit, ...outForDelivery];
});

/// Get all delivered shipments
final deliveredShipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  final service = ref.watch(logisticsServiceProvider);
  return service.getShipmentsByStatus(ShipmentStatus.delivered);
});

// ============ ACTION PROVIDERS ============

/// Notifier for logistics actions
class LogisticsActionsNotifier extends Notifier<void> {
  late LogisticsService _service;

  @override
  void build() {
    _service = ref.watch(logisticsServiceProvider);
  }

  /// Create new shipment
  Future<Shipment> createShipment({
    required String orderId,
    required String memberId,
    required CarrierType carrier,
    required List<ShipmentItem> items,
    required ShippingAddress shippingAddress,
    String? originWarehouseId,
    bool isInsured = false,
    double? insuranceValue,
  }) async {
    final shipment = await _service.createShipment(
      orderId: orderId,
      memberId: memberId,
      carrier: carrier,
      items: items,
      shippingAddress: shippingAddress,
      originWarehouseId: originWarehouseId,
      isInsured: isInsured,
      insuranceValue: insuranceValue,
    );

    // Refresh related providers
    ref.invalidate(memberShipmentsProvider);
    ref.invalidate(pendingShipmentsProvider);

    return shipment;
  }

  /// Update shipment status
  Future<void> updateShipmentStatus(
    String shipmentId,
    ShipmentStatus newStatus,
  ) async {
    await _service.updateShipmentStatus(shipmentId, newStatus);

    // Refresh related providers
    ref.invalidate(shipmentProvider(shipmentId));
    ref.invalidate(shipmentsByStatusProvider);
    ref.invalidate(memberShipmentsProvider);
    ref.invalidate(inTransitShipmentsProvider);
    ref.invalidate(deliveredShipmentsProvider);
  }

  /// Record delivery with proof
  Future<void> recordDelivery({
    required String shipmentId,
    required String photoUrl,
    String? signatureUrl,
    required String deliveryPersonName,
    required String deliveryPersonPhone,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    await _service.recordDelivery(
      shipmentId: shipmentId,
      photoUrl: photoUrl,
      signatureUrl: signatureUrl,
      deliveryPersonName: deliveryPersonName,
      deliveryPersonPhone: deliveryPersonPhone,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );

    // Refresh related providers
    ref.invalidate(shipmentProvider(shipmentId));
    ref.invalidate(trackingHistoryProvider(shipmentId));
    ref.invalidate(deliveredShipmentsProvider);
    ref.invalidate(deliveryStatsProvider);
  }

  /// Cancel shipment
  Future<void> cancelShipment(
    String shipmentId, {
    required String reason,
  }) async {
    await _service.cancelShipment(shipmentId, reason: reason);

    // Refresh related providers
    ref.invalidate(shipmentProvider(shipmentId));
    ref.invalidate(shipmentsByStatusProvider);
    ref.invalidate(memberShipmentsProvider);
    ref.invalidate(pendingShipmentsProvider);
    ref.invalidate(inTransitShipmentsProvider);
  }

  /// Save carrier integration
  Future<void> saveCarrierIntegration(CarrierIntegration integration) async {
    await _service.saveCarrierIntegration(integration);
    ref.invalidate(carrierIntegrationProvider);
  }

  /// Update shipping rates
  Future<void> updateShippingRate(ShippingRate rate) async {
    await _service.updateShippingRate(rate);
    ref.invalidate(shippingRatesProvider);
  }
}

/// Actions provider for logistics operations
final logisticsActionsProvider =
    NotifierProvider<LogisticsActionsNotifier, void>(
  LogisticsActionsNotifier.new,
);

// ============ COMPUTED/FILTERED PROVIDERS ============

/// Get shipment statistics by status
final shipmentStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final pending = await ref.watch(pendingShipmentsProvider.future);
  final inTransit = await ref.watch(inTransitShipmentsProvider.future);
  final delivered = await ref.watch(deliveredShipmentsProvider.future);

  return {
    'pending': pending.length,
    'inTransit': inTransit.length,
    'delivered': delivered.length,
  };
});

/// Get shipments with delayed delivery (> estimated delivery time)
final delayedShipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  final inTransit = await ref.watch(inTransitShipmentsProvider.future);

  final delayed = inTransit.where((shipment) {
    if (shipment.estimatedDeliveryDate == null) return false;
    return DateTime.now().isAfter(shipment.estimatedDeliveryDate!);
  }).toList();

  return delayed;
});

/// Get carrier performance metrics
final carrierPerformanceProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final allShipments = <Shipment>[];
  for (final status in ShipmentStatus.values) {
    if (status != ShipmentStatus.cancelled) {
      final shipments =
          await ref.watch(shipmentsByStatusProvider(status).future);
      allShipments.addAll(shipments);
    }
  }

  final carrierMetrics = <String, Map<String, dynamic>>{};

  for (final shipment in allShipments) {
    final carrierName = shipment.carrier.toDisplayString();
    if (!carrierMetrics.containsKey(carrierName)) {
      carrierMetrics[carrierName] = {
        'total': 0,
        'delivered': 0,
        'avgDeliveryTime': 0.0,
        'onTimeDeliveries': 0,
      };
    }

    final metrics = carrierMetrics[carrierName]!;
    metrics['total'] = (metrics['total'] as int) + 1;

    if (shipment.isDelivered) {
      metrics['delivered'] = (metrics['delivered'] as int) + 1;

      if (shipment.deliveryDuration != null) {
        final current = metrics['avgDeliveryTime'] as double;
        metrics['avgDeliveryTime'] =
            (current + shipment.deliveryDuration!.inHours) / 2;
      }

      if (shipment.estimatedDeliveryDate != null &&
          shipment.deliveredAt != null &&
          shipment.deliveredAt!.isBefore(shipment.estimatedDeliveryDate!)) {
        metrics['onTimeDeliveries'] = (metrics['onTimeDeliveries'] as int) + 1;
      }
    }
  }

  return {
    'carrierMetrics': carrierMetrics,
    'bestCarrier': _findBestCarrier(carrierMetrics),
  };
});

String _findBestCarrier(Map<String, Map<String, dynamic>> metrics) {
  if (metrics.isEmpty) return 'N/A';

  String best = metrics.keys.first;
  double bestScore = 0;

  for (final entry in metrics.entries) {
    final data = entry.value;
    final deliveries = data['delivered'] as int;
    final total = data['total'] as int;
    final onTime = data['onTimeDeliveries'] as int;

    if (total == 0) continue;

    final deliveryRate = (deliveries / total);
    final onTimeRate = (onTime / total);
    final score = (deliveryRate * 0.7) + (onTimeRate * 0.3);

    if (score > bestScore) {
      bestScore = score;
      best = entry.key;
    }
  }

  return best;
}
