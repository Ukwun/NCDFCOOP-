import 'package:cloud_firestore/cloud_firestore.dart';

/// Logistics System - Models for shipment management, tracking, and delivery
/// Integrates with multiple carriers: Sendyit, Shipyard, FedEx, UPS

/// Enum for shipment status
enum ShipmentStatus {
  pending,
  confirmed,
  picked,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  cancelled;

  String toDisplayString() {
    switch (this) {
      case ShipmentStatus.pending:
        return 'Pending';
      case ShipmentStatus.confirmed:
        return 'Confirmed';
      case ShipmentStatus.picked:
        return 'Picked';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.outForDelivery:
        return 'Out for Delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.failed:
        return 'Delivery Failed';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String toColor() {
    switch (this) {
      case ShipmentStatus.pending:
        return '#FFA500'; // Orange
      case ShipmentStatus.confirmed:
        return '#2196F3'; // Blue
      case ShipmentStatus.picked:
        return '#2196F3'; // Blue
      case ShipmentStatus.inTransit:
        return '#2196F3'; // Blue
      case ShipmentStatus.outForDelivery:
        return '#FF9800'; // Orange
      case ShipmentStatus.delivered:
        return '#4CAF50'; // Green
      case ShipmentStatus.failed:
        return '#F44336'; // Red
      case ShipmentStatus.cancelled:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Enum for carrier types
enum CarrierType {
  sendyit,
  shipyard,
  fedex,
  ups,
  dhl,
  local;

  String toDisplayString() {
    switch (this) {
      case CarrierType.sendyit:
        return 'Sendyit';
      case CarrierType.shipyard:
        return 'Shipyard';
      case CarrierType.fedex:
        return 'FedEx';
      case CarrierType.ups:
        return 'UPS';
      case CarrierType.dhl:
        return 'DHL';
      case CarrierType.local:
        return 'Local Courier';
    }
  }

  String getApiProvider() {
    switch (this) {
      case CarrierType.sendyit:
        return 'sendyit';
      case CarrierType.shipyard:
        return 'shipyard';
      case CarrierType.fedex:
        return 'fedex';
      case CarrierType.ups:
        return 'ups';
      case CarrierType.dhl:
        return 'dhl';
      case CarrierType.local:
        return 'local';
    }
  }
}

/// ShippingAddress - Delivery location details
class ShippingAddress {
  final String recipientName;
  final String phoneNumber;
  final String email;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final String? instructions;

  ShippingAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.email,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'email': email,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions ?? '',
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      instructions: map['instructions'],
    );
  }

  String get fullAddress {
    return '$addressLine1, $addressLine2, $city, $state $postalCode, $country';
  }
}

/// ShipmentItem - Individual item in a shipment
class ShipmentItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String sku;
  final double weight; // kg
  final double length; // cm
  final double width; // cm
  final double height; // cm

  ShipmentItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.sku,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
  });

  double get totalPrice => unitPrice * quantity;
  double get totalWeight => weight * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'sku': sku,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
    };
  }

  factory ShipmentItem.fromMap(Map<String, dynamic> map) {
    return ShipmentItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      sku: map['sku'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      length: (map['length'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// DeliveryProof - Photo/signature proof of delivery
class DeliveryProof {
  final String proofId;
  final String photoUrl;
  final String? signatureUrl;
  final String? notes;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String deliveryPersonName;
  final String deliveryPersonPhone;

  DeliveryProof({
    required this.proofId,
    required this.photoUrl,
    this.signatureUrl,
    this.notes,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.deliveryPersonName,
    required this.deliveryPersonPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'proofId': proofId,
      'photoUrl': photoUrl,
      'signatureUrl': signatureUrl ?? '',
      'notes': notes ?? '',
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'deliveryPersonName': deliveryPersonName,
      'deliveryPersonPhone': deliveryPersonPhone,
    };
  }

  factory DeliveryProof.fromMap(Map<String, dynamic> map) {
    return DeliveryProof(
      proofId: map['proofId'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      signatureUrl: map['signatureUrl'],
      notes: map['notes'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      deliveryPersonName: map['deliveryPersonName'] ?? '',
      deliveryPersonPhone: map['deliveryPersonPhone'] ?? '',
    );
  }
}

/// TrackingEvent - Real-time shipment status update
class TrackingEvent {
  final String trackingEventId;
  final ShipmentStatus status;
  final String message;
  final DateTime timestamp;
  final String location;
  final double latitude;
  final double longitude;
  final String? photo;
  final Map<String, dynamic> metadata;

  TrackingEvent({
    required this.trackingEventId,
    required this.status,
    required this.message,
    required this.timestamp,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.photo,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toMap() {
    return {
      'trackingEventId': trackingEventId,
      'status': status.name,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'photo': photo ?? '',
      'metadata': metadata,
    };
  }

  factory TrackingEvent.fromMap(Map<String, dynamic> map) {
    return TrackingEvent(
      trackingEventId: map['trackingEventId'] ?? '',
      status: ShipmentStatus.values.byName(map['status'] ?? 'pending'),
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      photo: map['photo'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Shipment - Core shipment entity
class Shipment {
  final String shipmentId;
  final String orderId;
  final String memberId;
  final CarrierType carrier;
  final String trackingNumber;
  final String? carrierReferenceId;
  final ShipmentStatus status;
  final List<ShipmentItem> items;
  final ShippingAddress shippingAddress;
  final String? originWarehouseId;
  final double totalPrice;
  final double totalWeight;
  final double totalVolume; // cm³
  final double shippingCost;
  final double estimatedDeliveryTime; // hours
  final DateTime createdAt;
  final DateTime? pickedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedDeliveryDate;
  final List<TrackingEvent> trackingHistory;
  final DeliveryProof? deliveryProof;
  final bool isInsured;
  final double? insuranceValue;
  final String? insuranceProvider;
  final Map<String, dynamic> carrierDetails;

  Shipment({
    required this.shipmentId,
    required this.orderId,
    required this.memberId,
    required this.carrier,
    required this.trackingNumber,
    this.carrierReferenceId,
    required this.status,
    required this.items,
    required this.shippingAddress,
    this.originWarehouseId,
    required this.totalPrice,
    required this.totalWeight,
    required this.totalVolume,
    required this.shippingCost,
    required this.estimatedDeliveryTime,
    required this.createdAt,
    this.pickedAt,
    this.shippedAt,
    this.deliveredAt,
    this.estimatedDeliveryDate,
    List<TrackingEvent>? trackingHistory,
    this.deliveryProof,
    required this.isInsured,
    this.insuranceValue,
    this.insuranceProvider,
    Map<String, dynamic>? carrierDetails,
  })  : trackingHistory = trackingHistory ?? [],
        carrierDetails = carrierDetails ?? {};

  Map<String, dynamic> toMap() {
    return {
      'shipmentId': shipmentId,
      'orderId': orderId,
      'memberId': memberId,
      'carrier': carrier.name,
      'trackingNumber': trackingNumber,
      'carrierReferenceId': carrierReferenceId ?? '',
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'originWarehouseId': originWarehouseId ?? '',
      'totalPrice': totalPrice,
      'totalWeight': totalWeight,
      'totalVolume': totalVolume,
      'shippingCost': shippingCost,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'pickedAt': pickedAt != null ? Timestamp.fromDate(pickedAt!) : null,
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'estimatedDeliveryDate': estimatedDeliveryDate != null
          ? Timestamp.fromDate(estimatedDeliveryDate!)
          : null,
      'trackingHistory': trackingHistory.map((e) => e.toMap()).toList(),
      'deliveryProof': deliveryProof?.toMap(),
      'isInsured': isInsured,
      'insuranceValue': insuranceValue ?? 0,
      'insuranceProvider': insuranceProvider ?? '',
      'carrierDetails': carrierDetails,
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map) {
    return Shipment(
      shipmentId: map['shipmentId'] ?? '',
      orderId: map['orderId'] ?? '',
      memberId: map['memberId'] ?? '',
      carrier: CarrierType.values.byName(map['carrier'] ?? 'local'),
      trackingNumber: map['trackingNumber'] ?? '',
      carrierReferenceId: map['carrierReferenceId'],
      status: ShipmentStatus.values.byName(map['status'] ?? 'pending'),
      items: (map['items'] as List?)
              ?.map(
                  (item) => ShipmentItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      shippingAddress: ShippingAddress.fromMap(
        map['shippingAddress'] as Map<String, dynamic>? ?? {},
      ),
      originWarehouseId: map['originWarehouseId'],
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      totalWeight: (map['totalWeight'] as num?)?.toDouble() ?? 0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0,
      shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 0,
      estimatedDeliveryTime:
          (map['estimatedDeliveryTime'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickedAt: (map['pickedAt'] as Timestamp?)?.toDate(),
      shippedAt: (map['shippedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
      estimatedDeliveryDate:
          (map['estimatedDeliveryDate'] as Timestamp?)?.toDate(),
      trackingHistory: (map['trackingHistory'] as List?)
              ?.map((event) =>
                  TrackingEvent.fromMap(event as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryProof: map['deliveryProof'] != null
          ? DeliveryProof.fromMap(map['deliveryProof'] as Map<String, dynamic>)
          : null,
      isInsured: map['isInsured'] ?? false,
      insuranceValue: (map['insuranceValue'] as num?)?.toDouble(),
      insuranceProvider: map['insuranceProvider'],
      carrierDetails: Map<String, dynamic>.from(map['carrierDetails'] ?? {}),
    );
  }

  factory Shipment.fromFirestore(DocumentSnapshot doc) {
    return Shipment.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toFirestore() => toMap();

  bool get isDelivered => status == ShipmentStatus.delivered;
  bool get isInTransit =>
      status == ShipmentStatus.inTransit ||
      status == ShipmentStatus.outForDelivery;
  Duration? get deliveryDuration {
    if (deliveredAt == null) return null;
    return deliveredAt!.difference(createdAt);
  }

  String get carrierDisplayName => carrier.toDisplayString();
  String get statusDisplayName => status.toDisplayString();
}

/// ShippingRate - Carrier quote for shipping
class ShippingRate {
  final String rateId;
  final CarrierType carrier;
  final String serviceType; // standard, express, overnight
  final double rate;
  final double estimatedDeliveryHours;
  final bool isAvailable;
  final String? restrictions;
  final DateTime quoteExpiresAt;

  ShippingRate({
    required this.rateId,
    required this.carrier,
    required this.serviceType,
    required this.rate,
    required this.estimatedDeliveryHours,
    required this.isAvailable,
    this.restrictions,
    required this.quoteExpiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(quoteExpiresAt);

  Map<String, dynamic> toMap() {
    return {
      'rateId': rateId,
      'carrier': carrier.name,
      'serviceType': serviceType,
      'rate': rate,
      'estimatedDeliveryHours': estimatedDeliveryHours,
      'isAvailable': isAvailable,
      'restrictions': restrictions ?? '',
      'quoteExpiresAt': Timestamp.fromDate(quoteExpiresAt),
    };
  }

  factory ShippingRate.fromMap(Map<String, dynamic> map) {
    return ShippingRate(
      rateId: map['rateId'] ?? '',
      carrier: CarrierType.values.byName(map['carrier'] ?? 'local'),
      serviceType: map['serviceType'] ?? 'standard',
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      estimatedDeliveryHours:
          (map['estimatedDeliveryHours'] as num?)?.toDouble() ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      restrictions: map['restrictions'],
      quoteExpiresAt:
          (map['quoteExpiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// CarrierIntegration - Configuration for carrier APIs
class CarrierIntegration {
  final String integrationId;
  final CarrierType carrier;
  final bool isEnabled;
  final String apiKey;
  final String? accountId;
  final String? merchantId;
  final bool isProductionEnv;
  final Map<String, dynamic> configuration;

  CarrierIntegration({
    required this.integrationId,
    required this.carrier,
    required this.isEnabled,
    required this.apiKey,
    this.accountId,
    this.merchantId,
    required this.isProductionEnv,
    Map<String, dynamic>? configuration,
  }) : configuration = configuration ?? {};

  Map<String, dynamic> toMap() {
    return {
      'integrationId': integrationId,
      'carrier': carrier.name,
      'isEnabled': isEnabled,
      'apiKey': apiKey,
      'accountId': accountId ?? '',
      'merchantId': merchantId ?? '',
      'isProductionEnv': isProductionEnv,
      'configuration': configuration,
    };
  }

  factory CarrierIntegration.fromMap(Map<String, dynamic> map) {
    return CarrierIntegration(
      integrationId: map['integrationId'] ?? '',
      carrier: CarrierType.values.byName(map['carrier'] ?? 'local'),
      isEnabled: map['isEnabled'] ?? false,
      apiKey: map['apiKey'] ?? '',
      accountId: map['accountId'],
      merchantId: map['merchantId'],
      isProductionEnv: map['isProductionEnv'] ?? false,
      configuration: Map<String, dynamic>.from(map['configuration'] ?? {}),
    );
  }
}
