import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/models/logistics_models.dart';

/// Logistics Service
/// Manages shipment creation, tracking, carrier integrations, and delivery proof
class LogisticsService {
  final FirebaseFirestore _firestore;

  late final CollectionReference<Map<String, dynamic>> _shipmentsCollection;
  late final CollectionReference<Map<String, dynamic>>
      _trackingEventsCollection;
  late final CollectionReference<Map<String, dynamic>>
      _carrierIntegrationsCollection;
  late final CollectionReference<Map<String, dynamic>> _shippingRatesCollection;

  LogisticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _initializeCollections();
  }

  void _initializeCollections() {
    _shipmentsCollection = _firestore.collection('shipments');
    _trackingEventsCollection = _firestore.collection('tracking_events');
    _carrierIntegrationsCollection =
        _firestore.collection('carrier_integrations');
    _shippingRatesCollection = _firestore.collection('shipping_rates');
  }

  // ============ SHIPMENT OPERATIONS ============

  /// Create a new shipment from order items
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
    try {
      final shipmentId = _shipmentsCollection.doc().id;
      final trackingNumber = _generateTrackingNumber(carrier);

      // Calculate totals
      final totalPrice =
          items.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final totalWeight =
          items.fold<double>(0, (sum, item) => sum + item.totalWeight);
      final totalVolume = items.fold<double>(
        0,
        (sum, item) =>
            sum + (item.length * item.width * item.height * item.quantity),
      );

      // Get shipping cost from rates
      final rates = await getShippingRates(
        carrier: carrier,
        totalWeight: totalWeight,
        destination: shippingAddress.city,
      );

      if (rates.isEmpty) {
        throw Exception('No shipping rates available for this carrier');
      }

      final rate = rates.first;
      final estimatedDeliveryDate = DateTime.now().add(
        Duration(hours: rate.estimatedDeliveryHours.toInt()),
      );

      final shipment = Shipment(
        shipmentId: shipmentId,
        orderId: orderId,
        memberId: memberId,
        carrier: carrier,
        trackingNumber: trackingNumber,
        status: ShipmentStatus.pending,
        items: items,
        shippingAddress: shippingAddress,
        originWarehouseId: originWarehouseId,
        totalPrice: totalPrice,
        totalWeight: totalWeight,
        totalVolume: totalVolume,
        shippingCost: rate.rate,
        estimatedDeliveryTime: rate.estimatedDeliveryHours,
        createdAt: DateTime.now(),
        estimatedDeliveryDate: estimatedDeliveryDate,
        isInsured: isInsured,
        insuranceValue: insuranceValue,
      );

      // Save to Firestore
      await _shipmentsCollection.doc(shipmentId).set(shipment.toFirestore());

      // Create initial tracking event
      await _createTrackingEvent(
        shipmentId,
        ShipmentStatus.pending,
        'Shipment created and ready for pickup',
        shippingAddress.city,
        shippingAddress.latitude,
        shippingAddress.longitude,
      );

      // Trigger carrier API call (async)
      _syncWithCarrier(shipment).ignore();

      debugPrint(
          '✅ Shipment created: $shipmentId with tracking $trackingNumber');
      return shipment;
    } catch (e) {
      debugPrint('❌ Error creating shipment: $e');
      rethrow;
    }
  }

  /// Get shipment by ID
  Future<Shipment?> getShipment(String shipmentId) async {
    try {
      final doc = await _shipmentsCollection.doc(shipmentId).get();
      if (!doc.exists) return null;
      return Shipment.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Error fetching shipment: $e');
      return null;
    }
  }

  /// Get shipments for a member
  Future<List<Shipment>> getMemberShipments(String memberId) async {
    try {
      final query = await _shipmentsCollection
          .where('memberId', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Shipment.fromMap(doc.data()))
          .where((s) => s.status != ShipmentStatus.cancelled)
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching member shipments: $e');
      return [];
    }
  }

  /// Get shipments by status
  Future<List<Shipment>> getShipmentsByStatus(ShipmentStatus status) async {
    try {
      final query = await _shipmentsCollection
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return query.docs.map((doc) => Shipment.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('❌ Error fetching shipments by status: $e');
      return [];
    }
  }

  /// Update shipment status
  Future<void> updateShipmentStatus(
    String shipmentId,
    ShipmentStatus newStatus,
  ) async {
    try {
      final shipment = await getShipment(shipmentId);
      if (shipment == null) throw Exception('Shipment not found');

      DateTime? updatedTime;
      switch (newStatus) {
        case ShipmentStatus.picked:
          updatedTime = DateTime.now();
          break;
        case ShipmentStatus.inTransit:
          updatedTime = DateTime.now();
          break;
        case ShipmentStatus.delivered:
          updatedTime = DateTime.now();
          break;
        default:
          break;
      }

      await _shipmentsCollection.doc(shipmentId).update({
        'status': newStatus.name,
        if (newStatus == ShipmentStatus.picked)
          'pickedAt': Timestamp.fromDate(updatedTime!),
        if (newStatus == ShipmentStatus.inTransit)
          'shippedAt': Timestamp.fromDate(updatedTime!),
        if (newStatus == ShipmentStatus.delivered)
          'deliveredAt': Timestamp.fromDate(updatedTime!),
      });

      debugPrint('✅ Shipment $shipmentId status updated to $newStatus');
    } catch (e) {
      debugPrint('❌ Error updating shipment status: $e');
    }
  }

  // ============ TRACKING OPERATIONS ============

  /// Create tracking event for shipment
  Future<void> _createTrackingEvent(
    String shipmentId,
    ShipmentStatus status,
    String message,
    String location,
    double latitude,
    double longitude,
  ) async {
    try {
      final eventId = _trackingEventsCollection.doc().id;
      final trackingEvent = TrackingEvent(
        trackingEventId: eventId,
        status: status,
        message: message,
        timestamp: DateTime.now(),
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      await _trackingEventsCollection.doc(eventId).set(trackingEvent.toMap());

      // Add to shipment's tracking history
      final shipment = await getShipment(shipmentId);
      if (shipment != null) {
        final updatedHistory = [
          ...shipment.trackingHistory,
          trackingEvent,
        ];

        await _shipmentsCollection.doc(shipmentId).update({
          'trackingHistory': updatedHistory.map((e) => e.toMap()).toList(),
        });
      }

      debugPrint('✅ Tracking event created for $shipmentId');
    } catch (e) {
      debugPrint('❌ Error creating tracking event: $e');
    }
  }

  /// Get tracking history for shipment
  Future<List<TrackingEvent>> getTrackingHistory(String shipmentId) async {
    try {
      final shipment = await getShipment(shipmentId);
      return shipment?.trackingHistory ?? [];
    } catch (e) {
      debugPrint('❌ Error fetching tracking history: $e');
      return [];
    }
  }

  /// Stream real-time tracking updates
  Stream<Shipment> watchShipment(String shipmentId) {
    return _shipmentsCollection.doc(shipmentId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Shipment not found');
      return Shipment.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ============ DELIVERY PROOF OPERATIONS ============

  /// Record delivery with proof (photo + signature)
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
    try {
      final proofId = 'proof_${DateTime.now().millisecondsSinceEpoch}';

      final deliveryProof = DeliveryProof(
        proofId: proofId,
        photoUrl: photoUrl,
        signatureUrl: signatureUrl,
        notes: notes,
        timestamp: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        deliveryPersonName: deliveryPersonName,
        deliveryPersonPhone: deliveryPersonPhone,
      );

      await _shipmentsCollection.doc(shipmentId).update({
        'deliveryProof': deliveryProof.toMap(),
        'status': ShipmentStatus.delivered.name,
        'deliveredAt': Timestamp.fromDate(DateTime.now()),
      });

      await _createTrackingEvent(
        shipmentId,
        ShipmentStatus.delivered,
        'Package delivered - Signature: ${deliveryProof.proofId}',
        'Destination',
        latitude,
        longitude,
      );

      debugPrint('✅ Delivery proof recorded for $shipmentId');
    } catch (e) {
      debugPrint('❌ Error recording delivery: $e');
    }
  }

  // ============ SHIPPING RATES OPERATIONS ============

  /// Get available shipping rates
  Future<List<ShippingRate>> getShippingRates({
    required CarrierType carrier,
    required double totalWeight,
    required String destination,
  }) async {
    try {
      final query = await _shippingRatesCollection
          .where('carrier', isEqualTo: carrier.name)
          .where('isAvailable', isEqualTo: true)
          .get();

      final rates = query.docs
          .map((doc) => ShippingRate.fromMap(doc.data()))
          .where((rate) => !rate.isExpired)
          .toList();

      // Sort by price (ascending)
      rates.sort((a, b) => a.rate.compareTo(b.rate));

      return rates;
    } catch (e) {
      debugPrint('❌ Error fetching shipping rates: $e');
      return [];
    }
  }

  /// Get all available carrier options
  Future<List<ShippingRate>> getCarrierQuotes({
    required List<ShipmentItem> items,
    required ShippingAddress destination,
  }) async {
    try {
      final totalWeight =
          items.fold<double>(0, (sum, item) => sum + item.totalWeight);
      final allRates = <ShippingRate>[];

      // Get quotes from all enabled carriers
      for (final carrierType in CarrierType.values) {
        if (carrierType == CarrierType.local) continue;

        final rates = await getShippingRates(
          carrier: carrierType,
          totalWeight: totalWeight,
          destination: destination.city,
        );
        allRates.addAll(rates);
      }

      // Sort by price
      allRates.sort((a, b) => a.rate.compareTo(b.rate));
      return allRates;
    } catch (e) {
      debugPrint('❌ Error getting carrier quotes: $e');
      return [];
    }
  }

  /// Update shipping rates (admin operation)
  Future<void> updateShippingRate(ShippingRate rate) async {
    try {
      await _shippingRatesCollection.doc(rate.rateId).set(rate.toMap());
      debugPrint('✅ Shipping rate updated: ${rate.rateId}');
    } catch (e) {
      debugPrint('❌ Error updating shipping rate: $e');
    }
  }

  // ============ CARRIER INTEGRATION OPERATIONS ============

  /// Get carrier integration configuration
  Future<CarrierIntegration?> getCarrierIntegration(CarrierType carrier) async {
    try {
      final doc = await _carrierIntegrationsCollection
          .where('carrier', isEqualTo: carrier.name)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;
      return CarrierIntegration.fromMap(doc.docs.first.data());
    } catch (e) {
      debugPrint('❌ Error fetching carrier integration: $e');
      return null;
    }
  }

  /// Save carrier integration configuration (admin only)
  Future<void> saveCarrierIntegration(CarrierIntegration integration) async {
    try {
      await _carrierIntegrationsCollection.doc(integration.integrationId).set(
            integration.toMap(),
          );
      debugPrint(
          '✅ Carrier integration saved: ${integration.carrier.toDisplayString()}');
    } catch (e) {
      debugPrint('❌ Error saving carrier integration: $e');
    }
  }

  // ============ INTERNAL HELPERS ============

  /// Generate tracking number based on carrier
  String _generateTrackingNumber(CarrierType carrier) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    final prefix = carrier.name.substring(0, 2).toUpperCase();
    return '$prefix$timestamp$random';
  }

  /// Sync shipment with carrier APIs (external integration)
  Future<void> _syncWithCarrier(Shipment shipment) async {
    try {
      final integration = await getCarrierIntegration(shipment.carrier);
      if (integration == null || !integration.isEnabled) {
        debugPrint(
            '⚠️ Carrier ${shipment.carrier.name} not enabled for syncing');
        return;
      }

      // In production, this would call actual carrier APIs:
      // - Sendyit: POST /send/shipment
      // - Shipyard: POST /orders
      // - FedEx: POST /ship
      // - UPS: POST /carriers/track

      debugPrint(
          '📤 Syncing with ${shipment.carrier.toDisplayString()} API...');

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('✅ Carrier sync successful for ${shipment.shipmentId}');
    } catch (e) {
      debugPrint('⚠️ Carrier sync failed: $e');
      // Don't rethrow - shipment is created locally regardless
    }
  }

  /// Cancel shipment
  Future<void> cancelShipment(String shipmentId,
      {required String reason}) async {
    try {
      await updateShipmentStatus(shipmentId, ShipmentStatus.cancelled);

      final shipment = await getShipment(shipmentId);
      if (shipment != null) {
        await _createTrackingEvent(
          shipmentId,
          ShipmentStatus.cancelled,
          'Shipment cancelled: $reason',
          'N/A',
          0,
          0,
        );
      }

      debugPrint('✅ Shipment $shipmentId cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling shipment: $e');
    }
  }

  /// Get delivery stats (for analytics)
  Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      final allShipments = await _shipmentsCollection.get();
      final docs = allShipments.docs;

      var delivered = 0;
      var inTransit = 0;
      var pending = 0;
      var failed = 0;
      double avgDeliveryTime = 0;

      for (final doc in docs) {
        final shipment = Shipment.fromMap(doc.data());

        switch (shipment.status) {
          case ShipmentStatus.delivered:
            delivered++;
            if (shipment.deliveryDuration != null) {
              avgDeliveryTime += shipment.deliveryDuration!.inHours;
            }
            break;
          case ShipmentStatus.inTransit:
          case ShipmentStatus.outForDelivery:
            inTransit++;
            break;
          case ShipmentStatus.pending:
          case ShipmentStatus.confirmed:
          case ShipmentStatus.picked:
            pending++;
            break;
          case ShipmentStatus.failed:
            failed++;
            break;
          case ShipmentStatus.cancelled:
            break;
        }
      }

      if (delivered > 0) {
        avgDeliveryTime = avgDeliveryTime / delivered;
      }

      return {
        'totalShipments': docs.length,
        'delivered': delivered,
        'inTransit': inTransit,
        'pending': pending,
        'failed': failed,
        'deliveryRate': docs.isEmpty
            ? 0
            : (delivered / docs.length * 100).toStringAsFixed(1),
        'avgDeliveryTimeHours': avgDeliveryTime.toStringAsFixed(1),
      };
    } catch (e) {
      debugPrint('❌ Error calculating delivery stats: $e');
      return {};
    }
  }
}
