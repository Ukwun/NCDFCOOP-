import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

/// Service for managing location tracking and GPS operations
class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      // ignore: avoid_print
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      // ignore: avoid_print
      print('Error checking location service: $e');
      return false;
    }
  }

  /// Get current position
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Check if location service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      // Request permission if not already granted
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      // Note: Different geolocator versions use different APIs
      // This version uses the old API without locationSettings
      // ignore: deprecated_member_use
      final position = await Geolocator.getCurrentPosition();

      return position;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Start tracking location updates
  /// Returns a stream of Position updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 10, // meters
    Duration updateInterval = const Duration(seconds: 5),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: updateInterval,
      ),
    );
  }

  /// Calculate distance between two coordinates
  static double getDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two coordinates
  static double getBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      // ignore: avoid_print
      print('Error opening location settings: $e');
      return false;
    }
  }

  /// Open device app settings
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      // ignore: avoid_print
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      // ignore: avoid_print
      print('Error getting last known position: $e');
      return null;
    }
  }
}
