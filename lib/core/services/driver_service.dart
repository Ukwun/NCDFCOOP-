import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:geolocator/geolocator.dart';

// Export classes for use in providers
export 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;

/// Data model: Latitude/Longitude coordinates
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LatLng.fromMap(Map<String, dynamic> map) {
    return LatLng(
      map['latitude'] as double,
      map['longitude'] as double,
    );
  }
}

/// Driver location update
class DriverLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double? speed;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    this.speed,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
    };
  }

  factory DriverLocation.fromMap(Map<String, dynamic> map) {
    return DriverLocation(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      accuracy: map['accuracy'] as double,
      speed: map['speed'] as double?,
    );
  }
}

/// Proof of Delivery record
class ProofOfDelivery {
  final String id;
  final String deliveryId;
  final String driverId;
  final String orderId;
  final String photoUrl; // URL in Firebase Storage
  final String signatureUrl; // URL in Firebase Storage
  final LatLng coordinates; // GPS location at delivery
  final DateTime timestamp;
  final String customerName;
  final String notes;

  ProofOfDelivery({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    required this.orderId,
    required this.photoUrl,
    required this.signatureUrl,
    required this.coordinates,
    required this.timestamp,
    required this.customerName,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deliveryId': deliveryId,
      'driverId': driverId,
      'orderId': orderId,
      'photoUrl': photoUrl,
      'signatureUrl': signatureUrl,
      'coordinates': coordinates.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'customerName': customerName,
      'notes': notes,
    };
  }

  factory ProofOfDelivery.fromMap(Map<String, dynamic> map) {
    return ProofOfDelivery(
      id: map['id'] as String,
      deliveryId: map['deliveryId'] as String,
      driverId: map['driverId'] as String,
      orderId: map['orderId'] as String,
      photoUrl: map['photoUrl'] as String,
      signatureUrl: map['signatureUrl'] as String,
      coordinates: LatLng.fromMap(map['coordinates'] as Map<String, dynamic>),
      timestamp: DateTime.parse(map['timestamp'] as String),
      customerName: map['customerName'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }
}

/// POD Submission (from app submission)
class PODSubmission {
  final String id;
  final String orderId;
  final String driverId;
  final String? photoPath; // Local file path
  final String? signaturePath; // Local file path
  final LatLng coordinates;
  final DateTime timestamp;
  final String status; // 'pending_upload', 'uploading', 'completed', 'failed'

  PODSubmission({
    required this.id,
    required this.orderId,
    required this.driverId,
    this.photoPath,
    this.signaturePath,
    required this.coordinates,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'driverId': driverId,
      'photoPath': photoPath,
      'signaturePath': signaturePath,
      'coordinates': coordinates.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}

/// Driver statistics for display
class DriverStats {
  final String driverId;
  final int deliveriesToday;
  final int completedToday;
  final int failedToday;
  final double onTimePercentage;
  final double averageRating;

  DriverStats({
    required this.driverId,
    required this.deliveriesToday,
    required this.completedToday,
    required this.failedToday,
    required this.onTimePercentage,
    required this.averageRating,
  });

  factory DriverStats.fromMap(Map<String, dynamic> map) {
    return DriverStats(
      driverId: map['driverId'] as String? ?? '',
      deliveriesToday: map['deliveriesToday'] as int? ?? 0,
      completedToday: map['completedToday'] as int? ?? 0,
      failedToday: map['failedToday'] as int? ?? 0,
      onTimePercentage: (map['onTimePercentage'] as num?)?.toDouble() ?? 0.0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Delivery stop (from route)
class DeliveryStop {
  final String id;
  final String orderId;
  final String customerName;
  final String address;
  final String? notes;
  final LatLng coordinates;
  final String? deliveryWindow; // "10:00-12:00"
  final String status; // 'pending', 'in_progress', 'completed', 'failed'

  DeliveryStop({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.address,
    this.notes,
    required this.coordinates,
    this.deliveryWindow,
    required this.status,
  });

  factory DeliveryStop.fromMap(Map<String, dynamic> map) {
    return DeliveryStop(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String?,
      coordinates: map['coordinates'] != null
          ? LatLng.fromMap(map['coordinates'] as Map<String, dynamic>)
          : LatLng(0, 0),
      deliveryWindow: map['deliveryWindow'] as String?,
      status: map['status'] as String? ?? 'pending',
    );
  }
}

/// Driver location tracking record
class DriverLocationUpdate {
  final String driverId;
  final LatLng coordinates;
  final DateTime timestamp;
  final double accuracy; // in meters
  final double speed; // in m/s

  DriverLocationUpdate({
    required this.driverId,
    required this.coordinates,
    required this.timestamp,
    required this.accuracy,
    required this.speed,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'coordinates': coordinates.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
    };
  }
}

/// Service for driver operations: location tracking, POD capture, and delivery updates
///
/// Responsibilities:
/// - Track driver location in real-time (every 30 seconds)
/// - Capture proof of delivery (photo + signature + GPS)
/// - Upload POD to Firebase Storage
/// - Update delivery status
/// - Handle failed deliveries
/// - Calculate ETA to next stop
class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Initialize location tracking for a driver
  /// Should be called when driver starts their route
  /// Updates location every 30 seconds
  Future<void> startLocationTracking(String driverId) async {
    try {
      print('DEBUG: Location tracking started for driver $driverId');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        recordLocationUpdate(
          driverId,
          LatLng(position.latitude, position.longitude),
          position.accuracy,
          position.speed,
        );
      });
    } catch (e) {
      print('ERROR: Failed to start location tracking: $e');
      rethrow;
    }
  }

  /// Stop location tracking for a driver
  Future<void> stopLocationTracking(String driverId) async {
    try {
      print('DEBUG: Location tracking stopped for driver $driverId');
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    } catch (e) {
      print('ERROR: Failed to stop location tracking: $e');
      rethrow;
    }
  }

  /// Record a single location update
  /// Called periodically (every 30 seconds) by location tracking loop
  Future<void> recordLocationUpdate(
    String driverId,
    LatLng coordinates,
    double accuracy,
    double speed,
  ) async {
    try {
      final locationUpdate = DriverLocationUpdate(
        driverId: driverId,
        coordinates: coordinates,
        timestamp: DateTime.now(),
        accuracy: accuracy,
        speed: speed,
      );

      // Save to Firestore with timestamp (overwrites previous)
      // This creates a location history trail
      await _firestore.collection('drivers').doc(driverId).update({
        'currentLocation': coordinates.toMap(),
        'lastLocationUpdate': DateTime.now().toIso8601String(),
        'accuracy': accuracy,
        'speed': speed,
      });

      // Optionally save to history collection for analytics
      await _firestore
          .collection('driver_location_history')
          .doc('$driverId-${DateTime.now().millisecondsSinceEpoch}')
          .set(locationUpdate.toMap());
    } catch (e) {
      print('ERROR: Failed to record location update: $e');
      // Don't rethrow - location updates are not critical to delivery
    }
  }

  /// Capture and upload proof of delivery
  ///
  /// Workflow:
  /// 1. Driver takes photo of package at delivery location
  /// 2. Driver captures signature (digital or thumbprint)
  /// 3. System captures GPS coordinates
  /// 4. Upload photo and signature to Firebase Storage
  /// 5. Save POD record to Firestore
  /// 6. Mark order as delivered
  ///
  /// Returns: POD ID (for receipt/confirmation)
  Future<String> capturePOD({
    required String deliveryId,
    required String driverId,
    required String orderId,
    required String photoPath, // Local file path to photo
    required String signaturePath, // Local file path to signature
    required LatLng coordinates, // GPS at delivery
    required String customerName,
    required String notes,
  }) async {
    try {
      final timestamp = DateTime.now();
      final podId = 'POD-$orderId-${timestamp.millisecondsSinceEpoch}';

      // Upload photo to Firebase Storage
      final photoRef = _storage.ref(
        'pod/$driverId/$orderId/photo_${timestamp.millisecondsSinceEpoch}.jpg',
      );

      // In real implementation: await photoRef.putFile(File(photoPath));
      // For now, simulate with a dummy URL
      final photoUrl =
          'gs://coop-commerce.appspot.com/pod/$driverId/$orderId/photo.jpg';
      print('DEBUG: Simulated photo upload to $photoUrl');

      // Upload signature to Firebase Storage
      final signatureRef = _storage.ref(
        'pod/$driverId/$orderId/signature_${timestamp.millisecondsSinceEpoch}.png',
      );

      // In real implementation: await signatureRef.putFile(File(signaturePath));
      // For now, simulate with a dummy URL
      final signatureUrl =
          'gs://coop-commerce.appspot.com/pod/$driverId/$orderId/signature.png';
      print('DEBUG: Simulated signature upload to $signatureUrl');

      // Create POD record
      final pod = ProofOfDelivery(
        id: podId,
        deliveryId: deliveryId,
        driverId: driverId,
        orderId: orderId,
        photoUrl: photoUrl,
        signatureUrl: signatureUrl,
        coordinates: coordinates,
        timestamp: timestamp,
        customerName: customerName,
        notes: notes,
      );

      // Save POD to Firestore
      await _firestore
          .collection('proof_of_delivery')
          .doc(podId)
          .set(pod.toMap());

      // Update order status to 'delivered'
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': timestamp.toIso8601String(),
        'deliveredBy': driverId,
        'proofOfDeliveryId': podId,
      });

      // Update delivery stop status in dispatch route
      await _firestore
          .collection('delivery_routes')
          .where('stops', arrayContains: {'orderId': orderId})
          .get()
          .then((routes) {
            for (var route in routes.docs) {
              // Update specific stop in the route
              route.reference.update({
                'lastModified': timestamp.toIso8601String(),
              });
            }
          });

      print('DEBUG: POD captured successfully: $podId');
      return podId;
    } catch (e) {
      print('ERROR: Failed to capture POD: $e');
      rethrow;
    }
  }

  /// Get today's route (list of delivery stops) for a driver
  /// Returns: DeliveryRoute with all stops for today
  Future<Map<String, dynamic>?> getTodayRoute(String driverId) async {
    try {
      // Query for today's routes assigned to this driver
      final querySnapshot = await _firestore
          .collection('delivery_routes')
          .where('assignedDriverId', isEqualTo: driverId)
          .where('date',
              isEqualTo: DateTime.now().toIso8601String().split('T')[0])
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('INFO: No routes assigned for driver $driverId today');
        return null;
      }

      // Return first route (should only be one per driver per day)
      final routeData = querySnapshot.docs.first.data();
      print('DEBUG: Found route for driver $driverId');
      return routeData;
    } catch (e) {
      print('ERROR: Failed to get today route: $e');
      rethrow;
    }
  }

  /// Update delivery stop status
  /// Called when driver reaches a stop, completes delivery, or marks failed
  Future<void> updateStopStatus({
    required String routeId,
    required int stopNumber,
    required String status, // 'pending', 'in_progress', 'completed', 'failed'
    required String notes,
  }) async {
    try {
      final timestamp = DateTime.now();

      await _firestore.collection('delivery_routes').doc(routeId).update({
        'lastModified': timestamp.toIso8601String(),
        'stops.$stopNumber.status': status,
        'stops.$stopNumber.updatedAt': timestamp.toIso8601String(),
        'stops.$stopNumber.notes': notes,
      });

      print('DEBUG: Stop $stopNumber status updated to $status');
    } catch (e) {
      print('ERROR: Failed to update stop status: $e');
      rethrow;
    }
  }

  /// Calculate ETA (Estimated Time of Arrival) to next stop
  /// Uses Haversine formula to calculate distance, then estimates time
  /// Assumes average delivery speed of 30 km/h
  Duration calculateETA(LatLng currentLocation, LatLng nextStopLocation) {
    try {
      // Calculate distance using Haversine formula
      const earthRadiusKm = 6371.0;
      final dLat =
          _toRadians(nextStopLocation.latitude - currentLocation.latitude);
      final dLng =
          _toRadians(nextStopLocation.longitude - currentLocation.longitude);

      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_toRadians(currentLocation.latitude)) *
              math.cos(_toRadians(nextStopLocation.latitude)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);

      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      final distanceKm = earthRadiusKm * c;

      // Estimate time: 30 km/h average delivery speed
      // Plus 5 minutes per stop for delivery
      const avgSpeedKmH = 30.0;
      final travelTimeMinutes = (distanceKm / avgSpeedKmH) * 60;
      final totalMinutes = travelTimeMinutes + 5; // +5 min for delivery

      print(
          'DEBUG: ETA calculation - Distance: ${distanceKm.toStringAsFixed(2)}km, Time: ${totalMinutes.toStringAsFixed(0)}min');
      return Duration(minutes: totalMinutes.toInt());
    } catch (e) {
      print('ERROR: Failed to calculate ETA: $e');
      return const Duration(minutes: 15); // Default fallback
    }
  }

  /// Convert degrees to radians (helper for ETA calculation)
  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Report a failed delivery
  /// Called when customer is not home, address is wrong, etc.
  Future<void> reportFailedDelivery({
    required String orderId,
    required String driverId,
    required String
        reason, // 'customer_not_home', 'wrong_address', 'damaged', 'refused'
    required String notes,
    LatLng? coordinates,
  }) async {
    try {
      final timestamp = DateTime.now();
      final failureId = 'FAIL-$orderId-${timestamp.millisecondsSinceEpoch}';

      // Create failure record
      await _firestore.collection('failed_deliveries').doc(failureId).set({
        'id': failureId,
        'orderId': orderId,
        'driverId': driverId,
        'reason': reason,
        'notes': notes,
        'coordinates': coordinates?.toMap(),
        'timestamp': timestamp.toIso8601String(),
        'status': 'pending_action', // awaiting rescheduling or return
      });

      // Update order status to 'failed'
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'failed_delivery',
        'failureReason': reason,
        'failedAt': timestamp.toIso8601String(),
        'failureId': failureId,
      });

      print('DEBUG: Failed delivery reported: $failureId');
    } catch (e) {
      print('ERROR: Failed to report failed delivery: $e');
      rethrow;
    }
  }

  /// Get driver's current performance metrics
  /// Used for assignment and routing optimization
  Future<Map<String, dynamic>?> getDriverMetrics(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();

      if (!doc.exists) {
        print('WARNING: Driver $driverId not found');
        return null;
      }

      final data = doc.data();
      print('DEBUG: Retrieved metrics for driver $driverId');
      return data;
    } catch (e) {
      print('ERROR: Failed to get driver metrics: $e');
      rethrow;
    }
  }

  /// Mark driver as available/on-duty
  Future<void> setDriverStatus(String driverId, String status) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'status': status, // 'available', 'on_route', 'break', 'off_duty'
        'lastStatusChange': DateTime.now().toIso8601String(),
      });

      print('DEBUG: Driver $driverId status set to $status');
    } catch (e) {
      print('ERROR: Failed to set driver status: $e');
      rethrow;
    }
  }

  /// Get today's deliveries for a driver
  Future<List<DeliveryStop>> getTodayDeliveries(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('delivery_routes')
          .where('assignedDriverId', isEqualTo: driverId)
          .where('date',
              isEqualTo: DateTime.now().toIso8601String().split('T')[0])
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('INFO: No deliveries for driver $driverId today');
        return [];
      }

      // Extract stops from first route
      final routeData = querySnapshot.docs.first.data();
      final stops = (routeData['stops'] as List?)
              ?.map(
                  (stop) => DeliveryStop.fromMap(stop as Map<String, dynamic>))
              .toList() ??
          [];

      print('DEBUG: Found ${stops.length} deliveries for driver $driverId');
      return stops;
    } catch (e) {
      print('ERROR: Failed to get today deliveries: $e');
      return [];
    }
  }

  /// Watch driver location in real-time
  Stream<DriverLocation> watchDriverLocation(String driverId) {
    try {
      return _firestore
          .collection('driver_locations')
          .doc(driverId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          return DriverLocation(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0,
          );
        }
        return DriverLocation.fromMap(doc.data() as Map<String, dynamic>);
      });
    } catch (e) {
      print('ERROR: Failed to watch driver location: $e');
      return Stream.value(DriverLocation(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
      ));
    }
  }

  /// Get driver statistics
  Future<DriverStats?> getDriverStats(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();

      if (!doc.exists) {
        print('WARNING: Driver $driverId not found');
        return null;
      }

      final data = doc.data();
      return DriverStats(
        driverId: driverId,
        deliveriesToday: data?['deliveriesToday'] as int? ?? 0,
        completedToday: data?['completedToday'] as int? ?? 0,
        failedToday: data?['failedToday'] as int? ?? 0,
        onTimePercentage:
            (data?['onTimePercentage'] as num?)?.toDouble() ?? 0.0,
        averageRating: (data?['averageRating'] as num?)?.toDouble() ?? 4.5,
      );
    } catch (e) {
      print('ERROR: Failed to get driver stats: $e');
      return null;
    }
  }

  /// Complete entire route
}
