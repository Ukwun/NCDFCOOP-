import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Latitude/Longitude coordinates
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

/// Driver information
class Driver {
  final String driverId;
  final String name;
  final String phone;
  final String licenseNumber;
  final String vehiclePlate;
  final bool available;
  final LatLng? currentLocation;
  final String? activeRouteId;
  final DriverPerformance performance;

  Driver({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.vehiclePlate,
    required this.available,
    this.currentLocation,
    this.activeRouteId,
    required this.performance,
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['current_location'];
    return Driver(
      driverId: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      licenseNumber: data['license_number'] ?? '',
      vehiclePlate: data['vehicle_plate'] ?? '',
      available: data['available'] ?? false,
      currentLocation: location != null
          ? LatLng(location['lat'] ?? 0.0, location['lng'] ?? 0.0)
          : null,
      activeRouteId: data['active_route_id'],
      performance: DriverPerformance.fromMap(
        data['performance'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'license_number': licenseNumber,
        'vehicle_plate': vehiclePlate,
        'available': available,
        'current_location': currentLocation != null
            ? {
                'lat': currentLocation!.latitude,
                'lng': currentLocation!.longitude
              }
            : null,
        'active_route_id': activeRouteId,
        'performance': performance.toMap(),
      };
}

/// Driver performance metrics
class DriverPerformance {
  final int deliveriesCount;
  final double onTimeRate; // percentage 0-100
  final double rating; // 0-5.0

  DriverPerformance({
    required this.deliveriesCount,
    required this.onTimeRate,
    required this.rating,
  });

  factory DriverPerformance.fromMap(Map<String, dynamic> data) {
    return DriverPerformance(
      deliveriesCount: data['deliveries_count'] ?? 0,
      onTimeRate: (data['on_time_rate'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'deliveries_count': deliveriesCount,
        'on_time_rate': onTimeRate,
        'rating': rating,
      };
}

/// Single delivery stop in a route
class DeliveryStop {
  final int stopNumber;
  final String orderId;
  final String customerId;
  final String address;
  final LatLng coordinates;
  final String deliveryWindow; // "09:00-12:00"
  final int? estimatedArrivalMinutes; // relative to start
  final int? actualArrivalMinutes;
  final String
      status; // 'pending' | 'arrived' | 'in_progress' | 'completed' | 'failed'

  DeliveryStop({
    required this.stopNumber,
    required this.orderId,
    required this.customerId,
    required this.address,
    required this.coordinates,
    required this.deliveryWindow,
    this.estimatedArrivalMinutes,
    this.actualArrivalMinutes,
    required this.status,
  });

  factory DeliveryStop.fromMap(Map<String, dynamic> data) {
    final coords = data['coordinates'];
    return DeliveryStop(
      stopNumber: data['stopNumber'] ?? 0,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      address: data['address'] ?? '',
      coordinates: LatLng(
        coords['lat'] ?? 0.0,
        coords['lng'] ?? 0.0,
      ),
      deliveryWindow: data['deliveryWindow'] ?? '',
      estimatedArrivalMinutes: data['estimatedArrival'],
      actualArrivalMinutes: data['actualArrival'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'stopNumber': stopNumber,
        'orderId': orderId,
        'customerId': customerId,
        'address': address,
        'coordinates': {
          'lat': coordinates.latitude,
          'lng': coordinates.longitude,
        },
        'deliveryWindow': deliveryWindow,
        'estimatedArrival': estimatedArrivalMinutes,
        'actualArrival': actualArrivalMinutes,
        'status': status,
      };
}

/// Complete delivery route for a driver
class DeliveryRoute {
  final String routeId;
  final String? driverId;
  final String date; // "2026-01-27"
  final String shift; // "morning" | "afternoon"
  final List<DeliveryStop> stops;
  final double totalDistance; // km
  final String status; // 'created' | 'assigned' | 'in_progress' | 'completed'
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  DeliveryRoute({
    required this.routeId,
    this.driverId,
    required this.date,
    required this.shift,
    required this.stops,
    required this.totalDistance,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory DeliveryRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryRoute(
      routeId: doc.id,
      driverId: data['driverId'],
      date: data['date'] ?? '',
      shift: data['shift'] ?? 'morning',
      stops: List<DeliveryStop>.from(
        (data['stops'] ?? []).map((stop) => DeliveryStop.fromMap(stop)),
      ),
      totalDistance: (data['totalDistance'] ?? 0).toDouble(),
      status: data['status'] ?? 'created',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      startedAt: data['started_at'] != null
          ? (data['started_at'] as Timestamp).toDate()
          : null,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'driverId': driverId,
        'date': date,
        'shift': shift,
        'stops': stops.map((stop) => stop.toMap()).toList(),
        'totalDistance': totalDistance,
        'status': status,
        'created_at': createdAt,
        'started_at': startedAt,
        'completed_at': completedAt,
      };
}

/// Dispatch log (when route is dispatched)
class DispatchLog {
  final String logId;
  final String routeId;
  final String driverId;
  final DateTime dispatchTime;
  final String? dispatchNotes;
  final String? dispatchConfirmedBy;
  final VehicleInspection? vehicleInspection;

  DispatchLog({
    required this.logId,
    required this.routeId,
    required this.driverId,
    required this.dispatchTime,
    this.dispatchNotes,
    this.dispatchConfirmedBy,
    this.vehicleInspection,
  });

  factory DispatchLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final inspection = data['vehicle_inspection'];
    return DispatchLog(
      logId: doc.id,
      routeId: data['routeId'] ?? '',
      driverId: data['driverId'] ?? '',
      dispatchTime: (data['dispatch_time'] as Timestamp).toDate(),
      dispatchNotes: data['dispatch_notes'],
      dispatchConfirmedBy: data['dispatch_confirmed_by'],
      vehicleInspection:
          inspection != null ? VehicleInspection.fromMap(inspection) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'routeId': routeId,
        'driverId': driverId,
        'dispatch_time': dispatchTime,
        'dispatch_notes': dispatchNotes,
        'dispatch_confirmed_by': dispatchConfirmedBy,
        'vehicle_inspection': vehicleInspection?.toMap(),
      };
}

/// Vehicle inspection before dispatch
class VehicleInspection {
  final String condition; // 'good' | 'fair' | 'needs_repair'
  final int odometer; // km
  final String? notes;

  VehicleInspection({
    required this.condition,
    required this.odometer,
    this.notes,
  });

  factory VehicleInspection.fromMap(Map<String, dynamic> data) {
    return VehicleInspection(
      condition: data['condition'] ?? 'good',
      odometer: data['odometer'] ?? 0,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'condition': condition,
        'odometer': odometer,
        'notes': notes,
      };
}

/// Route analytics
class RouteAnalytics {
  final String date;
  final int routesPlanned;
  final int routesCompleted;
  final int totalDeliveries;
  final int successfulDeliveries;
  final int failedDeliveries;
  final double avgDeliveryTimeMinutes;
  final double onTimeRate; // percentage

  RouteAnalytics({
    required this.date,
    required this.routesPlanned,
    required this.routesCompleted,
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.avgDeliveryTimeMinutes,
    required this.onTimeRate,
  });

  factory RouteAnalytics.fromMap(Map<String, dynamic> data) {
    return RouteAnalytics(
      date: data['date'] ?? '',
      routesPlanned: data['routes_planned'] ?? 0,
      routesCompleted: data['routes_completed'] ?? 0,
      totalDeliveries: data['total_deliveries'] ?? 0,
      successfulDeliveries: data['successful_deliveries'] ?? 0,
      failedDeliveries: data['failed_deliveries'] ?? 0,
      avgDeliveryTimeMinutes:
          (data['avg_delivery_time_minutes'] ?? 0).toDouble(),
      onTimeRate: (data['on_time_rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'routes_planned': routesPlanned,
        'routes_completed': routesCompleted,
        'total_deliveries': totalDeliveries,
        'successful_deliveries': successfulDeliveries,
        'failed_deliveries': failedDeliveries,
        'avg_delivery_time_minutes': avgDeliveryTimeMinutes,
        'on_time_rate': onTimeRate,
      };
}

/// Dispatch service for route planning and driver management
class DispatchService {
  final FirebaseFirestore _firestore;

  DispatchService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Plan daily routes from orders ready for dispatch
  /// Groups orders into efficient routes with 10-15 stops each
  Future<List<DeliveryRoute>> planDailyRoutes({
    required String date,
    required List<String> orderIds,
    int ordersPerRoute = 10,
  }) async {
    try {
      if (orderIds.isEmpty) {
        return [];
      }

      // Fetch orders
      final orders = <Map<String, dynamic>>[];
      for (final orderId in orderIds) {
        final doc = await _firestore.collection('orders').doc(orderId).get();
        if (doc.exists) {
          orders.add(doc.data() as Map<String, dynamic>);
        }
      }

      // Group orders into routes
      final routes = <DeliveryRoute>[];
      for (int i = 0; i < orders.length; i += ordersPerRoute) {
        final end = (i + ordersPerRoute > orders.length)
            ? orders.length
            : i + ordersPerRoute;
        final routeOrders = orders.sublist(i, end);

        // Create stops from orders
        final stops = <DeliveryStop>[];
        for (int j = 0; j < routeOrders.length; j++) {
          final order = routeOrders[j];
          final shippingData = order['shippingAddress'] ?? {};

          stops.add(
            DeliveryStop(
              stopNumber: j + 1,
              orderId: order['orderId'] ?? '',
              customerId: order['customerId'] ?? '',
              address: shippingData is String
                  ? shippingData
                  : shippingData['address'] ?? 'Unknown Address',
              coordinates: LatLng(6.5244, 3.3792), // Mock - would use geocoding
              deliveryWindow: order['deliverySlot'] ?? '09:00-12:00',
              estimatedArrivalMinutes: (j + 1) * 12, // ~12 min per stop
              status: 'pending',
            ),
          );
        }

        // Create route
        final routeNumber = (i ~/ ordersPerRoute) + 1;
        final routeId = 'RT_${date}_${routeNumber.toString().padLeft(3, '0')}';
        final route = DeliveryRoute(
          routeId: routeId,
          date: date,
          shift: _getShiftFromTime(routeNumber),
          stops: stops,
          totalDistance: stops.length * 2.5, // Mock distance
          status: 'created',
          createdAt: DateTime.now(),
        );

        // Save route
        await _firestore
            .collection('delivery_routes')
            .doc(routeId)
            .set(route.toFirestore());

        routes.add(route);
      }

      return routes;
    } catch (e) {
      // Error planning daily routes
      rethrow;
    }
  }

  /// Get available drivers
  Future<List<Driver>> getAvailableDrivers() async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('available', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Driver.fromFirestore(doc)).toList();
    } catch (e) {
      // Error fetching available drivers
      rethrow;
    }
  }

  /// Assign driver to route
  Future<void> assignDriverToRoute(String routeId, String driverId) async {
    try {
      // Update route
      await _firestore.collection('delivery_routes').doc(routeId).update({
        'driverId': driverId,
        'status': 'assigned',
      });

      // Update driver
      await _firestore.collection('drivers').doc(driverId).update({
        'active_route_id': routeId,
        'available': false,
      });
    } catch (e) {
      // Error assigning driver to route
      rethrow;
    }
  }

  /// Get route (driver sees this)
  Future<DeliveryRoute> getRoute(String routeId) async {
    try {
      final doc =
          await _firestore.collection('delivery_routes').doc(routeId).get();

      if (!doc.exists) {
        throw Exception('Route not found: $routeId');
      }

      return DeliveryRoute.fromFirestore(doc);
    } catch (e) {
      // Error getting route
      rethrow;
    }
  }

  /// Start route (driver confirms ready to start)
  Future<void> startRoute(String routeId, DispatchLog dispatchLog) async {
    try {
      // Create dispatch log
      await _firestore
          .collection('dispatch_logs')
          .doc(dispatchLog.logId)
          .set(dispatchLog.toFirestore());

      // Update route status
      await _firestore.collection('delivery_routes').doc(routeId).update({
        'status': 'in_progress',
        'started_at': DateTime.now(),
      });
    } catch (e) {
      // Error starting route
      rethrow;
    }
  }

  /// Update stop status
  Future<void> updateStopStatus(
    String routeId,
    int stopNumber,
    String status,
  ) async {
    try {
      final route = await getRoute(routeId);
      final updatedStops = route.stops.map((stop) {
        if (stop.stopNumber == stopNumber) {
          // Create new DeliveryStop with updated status
          return DeliveryStop(
            stopNumber: stop.stopNumber,
            orderId: stop.orderId,
            customerId: stop.customerId,
            address: stop.address,
            coordinates: stop.coordinates,
            deliveryWindow: stop.deliveryWindow,
            estimatedArrivalMinutes: stop.estimatedArrivalMinutes,
            actualArrivalMinutes: stop.actualArrivalMinutes,
            status: status,
          );
        }
        return stop;
      }).toList();

      // Update route
      await _firestore.collection('delivery_routes').doc(routeId).update({
        'stops': updatedStops.map((stop) => stop.toMap()).toList(),
      });
    } catch (e) {
      // Error updating stop status
      rethrow;
    }
  }

  /// Calculate ETA from current position to next stop
  Future<int> calculateETA(LatLng current, LatLng next) async {
    try {
      // Mock implementation - would use Google Maps API
      // Calculate rough distance using Haversine formula
      const earthRadiusKm = 6371;
      final lat1 = current.latitude * pi / 180;
      final lat2 = next.latitude * pi / 180;
      final deltaLat = (next.latitude - current.latitude) * pi / 180;
      final deltaLng = (next.longitude - current.longitude) * pi / 180;

      final a = pow(sin(deltaLat / 2), 2) +
          cos(lat1) * cos(lat2) * pow(sin(deltaLng / 2), 2);
      final c = 2 * atan2(sqrt(a.toDouble()), sqrt((1 - a).toDouble()));
      final distanceKm = earthRadiusKm * c;

      // Assume 30 km/h average speed in city
      return (distanceKm / 0.5).toInt(); // minutes
    } catch (e) {
      // Error calculating ETA
      return 15; // Default estimate
    }
  }

  /// Get all active routes
  Future<List<DeliveryRoute>> getActiveRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('delivery_routes')
          .where('status', whereIn: ['assigned', 'in_progress']).get();

      return snapshot.docs
          .map((doc) => DeliveryRoute.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Error fetching active routes
      rethrow;
    }
  }

  /// Complete route
  Future<void> completeRoute(String routeId) async {
    try {
      final route = await getRoute(routeId);

      await _firestore.collection('delivery_routes').doc(routeId).update({
        'status': 'completed',
        'completed_at': DateTime.now(),
      });

      // Free up driver
      if (route.driverId != null) {
        await _firestore.collection('drivers').doc(route.driverId!).update({
          'available': true,
          'active_route_id': null,
        });
      }
    } catch (e) {
      // Error completing route
      rethrow;
    }
  }

  /// Get route analytics
  Future<RouteAnalytics> getRouteAnalytics(String date) async {
    try {
      // Mock implementation
      return RouteAnalytics(
        date: date,
        routesPlanned: 4,
        routesCompleted: 3,
        totalDeliveries: 40,
        successfulDeliveries: 39,
        failedDeliveries: 1,
        avgDeliveryTimeMinutes: 12.5,
        onTimeRate: 95.0,
      );
    } catch (e) {
      // Error getting route analytics
      rethrow;
    }
  }

  /// Helper: Determine shift from route number
  String _getShiftFromTime(int routeNumber) {
    if (routeNumber <= 2) return 'morning'; // Morning: routes 1-2
    return 'afternoon'; // Afternoon: routes 3+
  }
}
