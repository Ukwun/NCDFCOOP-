import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:coop_commerce/models/notification_models.dart' hide LatLng;

/// Service for handling Google Maps operations and route calculations
class MapService {
  // Warehouse/Hub location (default: Lagos, Nigeria)
  static const gmaps.LatLng warehouseLocation = gmaps.LatLng(6.5244, 3.3792);

  /// Get warehouse location
  static gmaps.LatLng getWarehouseLocation() {
    return warehouseLocation;
  }

  /// Calculate distance between two points (Haversine formula)
  static double calculateDistance(
    gmaps.LatLng start,
    gmaps.LatLng end,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLon = _toRadians(end.longitude - start.longitude);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(start.latitude)) *
            math.cos(_toRadians(end.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get appropriate zoom level for route
  static double getZoomLevelForRoute(double distanceKm) {
    if (distanceKm < 1) return 17;
    if (distanceKm < 5) return 15;
    if (distanceKm < 10) return 14;
    if (distanceKm < 50) return 12;
    return 10;
  }

  /// Create a circle marker for a location
  static gmaps.Circle createLocationCircle({
    required String circleId,
    required gmaps.LatLng center,
    required double radiusMeters,
    required Color fillColor,
    double strokeWidth = 2,
    required Color strokeColor,
  }) {
    return gmaps.Circle(
      circleId: gmaps.CircleId(circleId),
      center: center,
      radius: radiusMeters,
      fillColor: fillColor,
      strokeWidth: strokeWidth.toInt(),
      strokeColor: strokeColor,
    );
  }

  /// Create a polyline for a route
  static gmaps.Polyline createRoutePolyline({
    required String polylineId,
    required List<gmaps.LatLng> points,
    required Color color,
    int width = 5,
  }) {
    return gmaps.Polyline(
      polylineId: gmaps.PolylineId(polylineId),
      points: points,
      color: color,
      width: width,
      geodesic: true,
    );
  }

  /// Create a marker for a location
  static gmaps.Marker createLocationMarker({
    required String markerId,
    required gmaps.LatLng position,
    String? title,
    String? snippet,
    required gmaps.BitmapDescriptor icon,
  }) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(markerId),
      position: position,
      infoWindow: gmaps.InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon,
    );
  }

  /// Get camera update for showing multiple locations
  static gmaps.CameraPosition getCameraPositionForLocations(
    List<gmaps.LatLng> locations,
  ) {
    if (locations.isEmpty) {
      return const gmaps.CameraPosition(
        target: warehouseLocation,
        zoom: 14,
      );
    }

    if (locations.length == 1) {
      return gmaps.CameraPosition(
        target: locations[0],
        zoom: 15,
      );
    }

    // Calculate center and appropriate zoom for multiple locations
    double minLat = locations[0].latitude;
    double maxLat = locations[0].latitude;
    double minLng = locations[0].longitude;
    double maxLng = locations[0].longitude;

    for (final location in locations) {
      minLat = math.min(minLat, location.latitude);
      maxLat = math.max(maxLat, location.latitude);
      minLng = math.min(minLng, location.longitude);
      maxLng = math.max(maxLng, location.longitude);
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final distance = calculateDistance(
      gmaps.LatLng(minLat, minLng),
      gmaps.LatLng(maxLat, maxLng),
    );

    return gmaps.CameraPosition(
      target: gmaps.LatLng(centerLat, centerLng),
      zoom: getZoomLevelForRoute(distance),
    );
  }
}
