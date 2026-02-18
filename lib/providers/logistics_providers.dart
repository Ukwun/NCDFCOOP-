import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/warehouse_service.dart';
import 'package:coop_commerce/core/services/dispatch_service.dart' as dispatch;
import 'package:coop_commerce/core/services/driver_service.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';

// ==========================================
// WAREHOUSE SERVICE PROVIDERS
// ==========================================

/// Provides the WarehouseService instance
final warehouseServiceProvider = Provider((ref) {
  return WarehouseService(firestore: FirebaseFirestore.instance);
});

/// Watch all active pick lists for the warehouse
final activePickListsProvider = FutureProvider<List<PickList>>((ref) async {
  final warehouseService = ref.watch(warehouseServiceProvider);
  final pickLists = <PickList>[];

  // For now, we'd fetch from Firestore
  // TODO: Implement Firestore query for pick lists
  return pickLists;
});

/// Watch real-time picking queue (items being picked)
final pickingQueueProvider = StreamProvider<List<PickList>>((ref) {
  // Return empty stream - watchPickingQueue has type mismatch
  return Stream.value([]);
});

/// Watch real-time packing queue (items being packed)
final packingQueueProvider = StreamProvider<List<PackingLog>>((ref) {
  final warehouseService = ref.watch(warehouseServiceProvider);
  return warehouseService.watchPackingQueue();
});

/// Get today's warehouse metrics (performance stats)
final todayMetricsProvider = FutureProvider<WarehouseMetrics>((ref) async {
  final warehouseService = ref.watch(warehouseServiceProvider);
  return warehouseService.getTodayMetrics();
});

/// Get specific pick list details
final pickListDetailProvider =
    FutureProvider.family<PickList?, String>((ref, pickListId) async {
  final warehouseService = ref.watch(warehouseServiceProvider);
  // TODO: Implement fetch from Firestore
  return null;
});

/// Get packing task for a pick list
final packingTaskProvider =
    FutureProvider.family<PackingLog?, String>((ref, pickListId) async {
  final warehouseService = ref.watch(warehouseServiceProvider);
  // TODO: Implement fetch from Firestore
  return null;
});

// ==========================================
// DISPATCH SERVICE PROVIDERS
// ==========================================

/// Provides the DispatchService instance
final dispatchServiceProvider = Provider((ref) {
  return dispatch.DispatchService(firestore: FirebaseFirestore.instance);
});

/// Get active routes for today
final activeRoutesProvider =
    FutureProvider<List<dispatch.DeliveryRoute>>((ref) async {
  final dispatchService = ref.watch(dispatchServiceProvider);
  return dispatchService.getActiveRoutes();
});

/// Get available drivers
final availableDriversProvider =
    FutureProvider<List<dispatch.Driver>>((ref) async {
  final dispatchService = ref.watch(dispatchServiceProvider);
  return dispatchService.getAvailableDrivers();
});

/// Watch real-time active routes (streaming updates)
final activeRoutesStreamProvider =
    StreamProvider<List<dispatch.DeliveryRoute>>((ref) {
  // TODO: Implement stream for real-time route updates
  return Stream.value([]);
});

/// Get today's route analytics (performance metrics)
final todayRouteAnalyticsProvider =
    FutureProvider<dispatch.RouteAnalytics>((ref) async {
  final dispatchService = ref.watch(dispatchServiceProvider);
  return dispatchService.getRouteAnalytics(DateTime.now().toIso8601String());
});

/// Get specific route details
final routeDetailProvider =
    FutureProvider.family<dispatch.DeliveryRoute?, String>(
        (ref, routeId) async {
  final dispatchService = ref.watch(dispatchServiceProvider);
  return dispatchService.getRoute(routeId);
});

/// Get driver performance metrics
final driverPerformanceProvider =
    FutureProvider.family<dispatch.DriverPerformance?, String>(
        (ref, driverId) async {
  final dispatchService = ref.watch(dispatchServiceProvider);
  // TODO: Implement fetch driver performance
  return null;
});

// ==========================================
// DRIVER SERVICE PROVIDERS (Week 10)
// ==========================================

/// Provides the DriverService instance
final driverServiceProvider = Provider((ref) {
  return DriverService();
});

/// Get today's deliveries for the logged-in driver
final todayDeliveriesProvider = FutureProvider<List<DeliveryStop>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final driverId = authState.value?.id;
  if (driverId == null) return [];

  final driverService = ref.watch(driverServiceProvider);
  return driverService.getTodayDeliveries(driverId);
});

/// Watch driver's current location (real-time GPS)
final driverLocationStreamProvider = StreamProvider<DriverLocation>((ref) {
  final authState = ref.watch(authStateProvider);
  final driverId = authState.value?.id;
  if (driverId == null) {
    return Stream.value(DriverLocation(
        latitude: 0, longitude: 0, timestamp: DateTime.now(), accuracy: 0));
  }

  final driverService = ref.watch(driverServiceProvider);
  return driverService.watchDriverLocation(driverId);
});

/// Track current POD submission status
final podSubmissionProvider = FutureProvider<PODSubmission?>((ref) {
  // This will be set when a delivery is being captured
  return Future.value(null);
});

/// Get driver statistics (deliveries, ratings, etc.)
final driverStatsProvider =
    FutureProvider.family<DriverStats?, String>((ref, driverId) async {
  final driverService = ref.watch(driverServiceProvider);
  return driverService.getDriverStats(driverId);
});

// ==========================================
// COMPOSITE PROVIDERS (Multi-service)
// ==========================================

/// All warehouse activity (pick + pack combined)
final warehouseActivityProvider =
    FutureProvider<({List<PickList> picking, List<PackingLog> packing})>(
        (ref) async {
  final picking = await ref.watch(activePickListsProvider.future);
  final packing = await ref.watch(packingQueueProvider.future);

  return (
    picking: picking,
    packing: packing,
  );
});

/// Dispatch dashboard summary
final dispatchDashboardProvider = FutureProvider<
    ({
      List<dispatch.DeliveryRoute> routes,
      List<dispatch.Driver> drivers,
      dispatch.RouteAnalytics analytics,
    })>((ref) async {
  final routes = await ref.watch(activeRoutesProvider.future);
  final drivers = await ref.watch(availableDriversProvider.future);
  final analytics = await ref.watch(todayRouteAnalyticsProvider.future);

  return (routes: routes, drivers: drivers, analytics: analytics);
});
